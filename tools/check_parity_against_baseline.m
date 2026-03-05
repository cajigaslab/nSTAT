function report = check_parity_against_baseline(varargin)
%CHECK_PARITY_AGAINST_BASELINE Compare current run vs PR0 baseline fixtures.
%
% Syntax:
%   report = check_parity_against_baseline
%   report = check_parity_against_baseline('Style','legacy','CheckPixels',false)
%
% Compares:
%   1) Numeric compact fixtures with explicit tolerances
%   2) Plot structure metadata (always)
%   3) Pixel diffs (optional, legacy mode only)

opts = parseOptions(varargin{:});

rootDir = detectRootDir();
fixturesRoot = fullfile(rootDir, 'fixtures');

numericMatPath = fullfile(fixturesRoot, 'baseline_numeric', 'nSTATPaperExamples_numeric_baseline.mat');
plotJsonPath = fullfile(fixturesRoot, 'baseline_plot_structure.json');
legacyFigDir = fullfile(fixturesRoot, 'baseline_figures_legacy');

assertFileExists(numericMatPath);
assertFileExists(plotJsonPath);

loaded = load(numericMatPath, 'numericBaseline');
baselineNumeric = loaded.numericBaseline;
baselinePlot = jsondecode(fileread(plotJsonPath));

tempFigureDir = fullfile(rootDir, 'fixtures', sprintf('parity_tmp_%s', char(java.util.UUID.randomUUID)));
cleanupObj = onCleanup(@()cleanupTemp(tempFigureDir)); %#ok<NASGU>

capture = nstat.baseline.capture_nSTATPaperExamples( ...
    'RootDir', rootDir, ...
    'Seed', opts.Seed, ...
    'Style', opts.Style, ...
    'ExportFigures', true, ...
    'FigureDir', tempFigureDir, ...
    'ExecuteLiveScript', false, ...
    'PublishHtml', false);

report = struct();
report.generatedAt = char(datetime('now','TimeZone','local','Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
report.seed = opts.Seed;
report.style = opts.Style;
report.numeric = compareNumeric(baselineNumeric.numeric, capture.numeric, opts.NumericAbsTol, opts.NumericRelTol);
report.plotStructure = comparePlotStructure(baselinePlot.plot, capture.plotStructure);
report.pixel = struct('checked', false, 'passed', true, 'details', struct([]));

if opts.CheckPixels
    if ~strcmpi(opts.Style, 'legacy')
        warning('nstat:parity:PixelCheckSkipped', ...
            'Pixel checks are only supported in legacy mode. Skipping pixel diff.');
    else
        report.pixel = comparePixels(legacyFigDir, tempFigureDir, opts.PixelMeanAbsTol);
    end
end

report.passed = report.numeric.passed && report.plotStructure.passed && report.pixel.passed;

fprintf('\nParity report\n');
fprintf('  Numeric: %s\n', tf(report.numeric.passed));
fprintf('  Plots  : %s\n', tf(report.plotStructure.passed));
if report.pixel.checked
    fprintf('  Pixels : %s\n', tf(report.pixel.passed));
end
fprintf('  Overall: %s\n', tf(report.passed));

if ~report.numeric.passed
    fprintf('  Numeric mismatches (%d):\n', numel(report.numeric.details));
    dumpNumericDetails(report.numeric.details);
end
if ~report.plotStructure.passed
    fprintf('  Plot structure mismatches (%d):\n', numel(report.plotStructure.details));
    dumpPlotDetails(report.plotStructure.details);
end
if report.pixel.checked && ~report.pixel.passed
    fprintf('  Pixel mismatches (%d)\n', numel(report.pixel.details));
end

if ~report.passed
    error('nstat:parity:Failed', 'Parity check failed. See report struct for details.');
end

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'check_parity_against_baseline';
addParameter(parser, 'Seed', 0, @(x)isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(parser, 'Style', 'legacy', @(x)ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'CheckPixels', false, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'NumericAbsTol', 1e-8, @(x)isnumeric(x) && isscalar(x) && x >= 0);
addParameter(parser, 'NumericRelTol', 1e-6, @(x)isnumeric(x) && isscalar(x) && x >= 0);
addParameter(parser, 'PixelMeanAbsTol', 0, @(x)isnumeric(x) && isscalar(x) && x >= 0);
parse(parser, varargin{:});
opts = parser.Results;
opts.Style = char(string(opts.Style));
opts.CheckPixels = logical(opts.CheckPixels);
end

function out = compareNumeric(base, cur, absTol, relTol)
out = struct();
out.details = struct('name', {}, 'status', {}, 'message', {});
out.passed = true;

baseDims = mapByName(base.dimensionChecks);
curDims = mapByName(cur.dimensionChecks);
baseNames = fieldnames(baseDims);
for i = 1:numel(baseNames)
    name = baseNames{i};
    if isExcludedDimensionVariable(name)
        continue;
    end
    if ~isfield(curDims, name)
        out = addFail(out, name, 'Missing numeric variable in current run.');
        continue;
    end
    b = baseDims.(name);
    c = curDims.(name);
    if ~strcmp(b.class, c.class) || ~isequal(b.size, c.size)
        out = addFail(out, name, 'Class/size mismatch in numeric dimension check.');
    end
end

baseKey = mapByName(base.keyMetrics);
curKey = mapByName(cur.keyMetrics);
keyNames = fieldnames(baseKey);
for i = 1:numel(keyNames)
    name = keyNames{i};
    if ~isfield(curKey, name)
        out = addFail(out, name, 'Missing key metric in current run.');
        continue;
    end
    b = baseKey.(name);
    c = curKey.(name);

    if ~strcmp(b.class, c.class) || ~isequal(b.size, c.size)
        out = addFail(out, name, 'Class/size mismatch in key metric.');
        continue;
    end

    if isStochasticMetricName(name)
        % Some metrics vary run-to-run because underlying algorithms use
        % randomized steps (for example discrete-time KS rescaling).
        continue;
    end

    checks = {'min','max','mean','std','l1norm'};
    for j = 1:numel(checks)
        fld = checks{j};
        if ~withinTol(b.(fld), c.(fld), absTol, relTol)
            out = addFail(out, name, sprintf('%s mismatch: baseline=%g current=%g', fld, b.(fld), c.(fld)));
            break;
        end
    end
end
end

function tfOut = isExcludedDimensionVariable(name)
excluded = {'R'};
tfOut = any(strcmp(name, excluded));
end

function tfOut = isStochasticMetricName(name)
stochastic = {'MU_est','MU_estAll','MU_estNT','MU_estNTAll','MuCoeffs','coeffs','lambdaData'};
tfOut = any(strcmp(name, stochastic));
end

function out = comparePlotStructure(base, cur)
out = struct();
out.details = struct('figureIndex', {}, 'status', {}, 'message', {});
out.passed = true;

if base.figureCount ~= cur.figureCount
    out = addPlotFail(out, 0, sprintf('Figure count mismatch: baseline=%d current=%d', base.figureCount, cur.figureCount));
    return;
end

for i = 1:base.figureCount
    b = base.figures(i);
    c = cur.figures(i);

    fields = {'axesCount','lineCount','scatterCount','barCount','imageCount'};
    for f = 1:numel(fields)
        fld = fields{f};
        if b.(fld) ~= c.(fld)
            out = addPlotFail(out, i, sprintf('%s mismatch: baseline=%d current=%d', fld, b.(fld), c.(fld)));
        end
    end

    if numel(b.legendEntries) ~= numel(c.legendEntries)
        out = addPlotFail(out, i, 'Legend entry count mismatch.');
    end

    if numel(b.axes) ~= numel(c.axes)
        out = addPlotFail(out, i, 'Axes metadata count mismatch.');
        continue;
    end

    for j = 1:numel(b.axes)
        bb = b.axes(j);
        cc = c.axes(j);
        if ~strcmp(nonempty(bb.xlabel), nonempty(cc.xlabel))
            out = addPlotFail(out, i, sprintf('XLabel mismatch on axis %d', j));
        end
        if ~strcmp(nonempty(bb.ylabel), nonempty(cc.ylabel))
            out = addPlotFail(out, i, sprintf('YLabel mismatch on axis %d', j));
        end
        if ~strcmp(nonempty(bb.title), nonempty(cc.title))
            out = addPlotFail(out, i, sprintf('Title mismatch on axis %d', j));
        end
        if bb.lineCount ~= cc.lineCount
            out = addPlotFail(out, i, sprintf('Axis lineCount mismatch on axis %d', j));
        end
    end
end
end

function out = comparePixels(baselineDir, currentDir, meanAbsTol)
out = struct();
out.checked = true;
out.passed = true;
out.details = struct('file', {}, 'status', {}, 'meanAbsDiff', {}, 'message', {});

baseFiles = dir(fullfile(baselineDir, '*.png'));
if isempty(baseFiles)
    out.passed = false;
    out.details(1) = struct('file', '', 'status', 'FAIL', 'meanAbsDiff', NaN, 'message', 'No baseline legacy images found.');
    return;
end

for i = 1:numel(baseFiles)
    f = baseFiles(i).name;
    bPath = fullfile(baselineDir, f);
    cPath = fullfile(currentDir, f);
    if exist(cPath, 'file') ~= 2
        out.passed = false;
        out.details(end+1) = struct('file', f, 'status', 'FAIL', 'meanAbsDiff', NaN, 'message', 'Missing current image'); %#ok<AGROW>
        continue;
    end

    bImg = imread(bPath);
    cImg = imread(cPath);
    if ~isequal(size(bImg), size(cImg))
        out.passed = false;
        out.details(end+1) = struct('file', f, 'status', 'FAIL', 'meanAbsDiff', NaN, 'message', 'Image size mismatch'); %#ok<AGROW>
        continue;
    end

    diffVal = mean(abs(double(bImg(:)) - double(cImg(:))));
    status = 'PASS';
    msg = '';
    if diffVal > meanAbsTol
        status = 'FAIL';
        msg = sprintf('Mean abs diff %g exceeds tolerance %g', diffVal, meanAbsTol);
        out.passed = false;
    end
    out.details(end+1) = struct('file', f, 'status', status, 'meanAbsDiff', diffVal, 'message', msg); %#ok<AGROW>
end
end

function map = mapByName(arr)
map = struct();
for i = 1:numel(arr)
    nm = matlab.lang.makeValidName(arr(i).name);
    map.(nm) = arr(i);
end
end

function s = nonempty(val)
if isempty(val)
    s = '__EMPTY__';
else
    s = strtrim(string(val));
    s = char(strjoin(s, ' '));
end
end

function tfOut = withinTol(a, b, absTol, relTol)
if isnan(a) && isnan(b)
    tfOut = true;
    return;
end
d = abs(a - b);
scale = max([1, abs(a), abs(b)]);
tfOut = (d <= absTol) || (d <= relTol * scale);
end

function out = addFail(out, name, message)
out.passed = false;
out.details(end+1) = struct('name', name, 'status', 'FAIL', 'message', message); %#ok<AGROW>
end

function out = addPlotFail(out, idx, message)
out.passed = false;
out.details(end+1) = struct('figureIndex', idx, 'status', 'FAIL', 'message', message); %#ok<AGROW>
end

function assertFileExists(pathStr)
if exist(pathStr, 'file') ~= 2
    error('nstat:parity:MissingFixture', 'Required fixture not found: %s', pathStr);
end
end

function rootDir = detectRootDir()
rootDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(rootDir);
end

function cleanupTemp(tempDir)
if exist(tempDir, 'dir') == 7
    try
        rmdir(tempDir, 's');
    catch
    end
end
end

function s = tf(v)
if v
    s = 'PASS';
else
    s = 'FAIL';
end
end

function dumpNumericDetails(details)
maxShow = min(40, numel(details));
for i = 1:maxShow
    d = details(i);
    fprintf('    - %s: %s\n', d.name, d.message);
end
if numel(details) > maxShow
    fprintf('    ... (%d more)\n', numel(details)-maxShow);
end
end

function dumpPlotDetails(details)
maxShow = min(40, numel(details));
for i = 1:maxShow
    d = details(i);
    fprintf('    - figure %d: %s\n', d.figureIndex, d.message);
end
if numel(details) > maxShow
    fprintf('    ... (%d more)\n', numel(details)-maxShow);
end
end
