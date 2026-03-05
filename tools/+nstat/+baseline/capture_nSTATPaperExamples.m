function capture = capture_nSTATPaperExamples(varargin)
%CAPTURE_NSTATPAPEREXAMPLES Execute nSTATPaperExamples and collect fixtures.
%
% Syntax:
%   capture = nstat.baseline.capture_nSTATPaperExamples(...)
%
% Name-value options:
%   'RootDir'          - nSTAT repository root (default autodetected)
%   'Seed'             - RNG seed (default 0)
%   'Style'            - Plot style tag recorded in metadata (default 'legacy')
%   'ExportFigures'    - Export figures to FigureDir (default true)
%   'FigureDir'        - Figure export folder
%   'ExecuteLiveScript'- Execute .mlx before captures (default true)
%   'PublishHtml'      - Export HTML from .mlx (default true)
%   'PublishHtmlPath'  - HTML output path
%
% Output:
%   capture struct with fields:
%     .runInfo, .numeric, .plotStructure, .console

opts = parseOptions(varargin{:});

rootDir = opts.RootDir;
helpDir = fullfile(rootDir, 'helpfiles');
mlxPath = fullfile(helpDir, 'nSTATPaperExamples.mlx');
mPath = fullfile(helpDir, 'nSTATPaperExamples.m');

if exist(mlxPath, 'file') ~= 2
    error('nstat:baseline:MissingMlx', 'Could not find %s', mlxPath);
end
if exist(mPath, 'file') ~= 2
    error('nstat:baseline:MissingMFile', 'Could not find %s', mPath);
end

setupRuntime(rootDir, opts.Seed, opts.Style);

capture = struct();
capture.runInfo = struct();
capture.runInfo.timestamp = char(datetime('now','TimeZone','local','Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
capture.runInfo.rootDir = rootDir;
capture.runInfo.seed = opts.Seed;
capture.runInfo.style = opts.Style;
capture.runInfo.mlxPath = mlxPath;
capture.runInfo.mPath = mPath;

capture.console = struct('liveScriptExecute', '', 'liveScriptPublish', '', 'mScriptExecute', '');

close all force;

tStart = tic;
if opts.ExecuteLiveScript
    try
        capture.console.liveScriptExecute = evalc('matlab.internal.liveeditor.executeAndSave(mlxPath);');
    catch ME
        capture.console.liveScriptExecute = sprintf('%s\n%s', ME.message, getReport(ME, 'extended', 'hyperlinks', 'off'));
        error('nstat:baseline:LiveScriptExecuteFailed', ...
            'Failed executing %s\n%s', mlxPath, ME.message);
    end
end
capture.runInfo.liveScriptDurationSec = toc(tStart);

if opts.PublishHtml
    try
        ensureParent(opts.PublishHtmlPath);
        capture.console.liveScriptPublish = evalc('matlab.internal.liveeditor.openAndConvert(mlxPath, opts.PublishHtmlPath);');
        capture.runInfo.publishHtmlPath = opts.PublishHtmlPath;
    catch ME
        % Fallback to publishing the .m source if Live Editor conversion fails.
        pubOpts = struct('format', 'html', 'outputDir', fileparts(opts.PublishHtmlPath), 'evalCode', false);
        capture.console.liveScriptPublish = sprintf('%s\n%s', ME.message, getReport(ME, 'extended', 'hyperlinks', 'off'));
        publish(mPath, pubOpts);
        capture.runInfo.publishHtmlPath = fullfile(fileparts(opts.PublishHtmlPath), 'nSTATPaperExamples.html');
    end
end

% Run staged .m source for deterministic numeric variable capture.
[numericSummary, mConsole, runDuration] = runStagedMFile(rootDir, mPath, opts.Seed);
capture.console.mScriptExecute = mConsole;
capture.runInfo.mScriptDurationSec = runDuration;
capture.numeric = numericSummary;

% Capture plot structure from the staged .m run so parity checks do not
% depend on Live Editor execution details.
capture.plotStructure = capturePlotStructureAndExport(opts.ExportFigures, opts.FigureDir, opts.Style);

close all force;

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'nstat.baseline.capture_nSTATPaperExamples';
addParameter(parser, 'RootDir', detectRootDir(), @(x)ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'Seed', 0, @(x)isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(parser, 'Style', 'legacy', @(x)ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'ExportFigures', true, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'FigureDir', '', @(x)ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'ExecuteLiveScript', true, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'PublishHtml', true, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'PublishHtmlPath', '', @(x)ischar(x) || (isstring(x) && isscalar(x)));
parse(parser, varargin{:});
opts = parser.Results;

opts.RootDir = char(string(opts.RootDir));
opts.Style = char(string(opts.Style));
opts.ExportFigures = logical(opts.ExportFigures);
opts.ExecuteLiveScript = logical(opts.ExecuteLiveScript);
opts.PublishHtml = logical(opts.PublishHtml);

if isempty(opts.FigureDir)
    opts.FigureDir = fullfile(opts.RootDir, 'fixtures', 'baseline_figures_legacy');
else
    opts.FigureDir = char(string(opts.FigureDir));
end

if isempty(opts.PublishHtmlPath)
    opts.PublishHtmlPath = fullfile(opts.RootDir, 'fixtures', 'published_help', 'nSTATPaperExamples_legacy.html');
else
    opts.PublishHtmlPath = char(string(opts.PublishHtmlPath));
end
end

function rootDir = detectRootDir()
thisFile = mfilename('fullpath');
rootDir = fileparts(fileparts(fileparts(fileparts(thisFile))));
end

function setupRuntime(rootDir, seed, styleTag)
restoredefaultpath;
addpath(rootDir, '-begin');
addpath(genpath(rootDir), '-begin');
cd(rootDir);
rng(seed, 'twister');

% Style tag is recorded for parity policy. If a global style setter exists,
% call it; otherwise current toolbox defaults are treated as legacy.
if exist('nstat.setPlotStyle', 'file') == 2
    try
        nstat.setPlotStyle(styleTag);
    catch
    end
elseif exist('nstatSetPlotStyle', 'file') == 2
    try
        nstatSetPlotStyle(styleTag);
    catch
    end
end
end

function plotStruct = capturePlotStructureAndExport(exportFigures, figureDir, styleTag)
figs = findall(0, 'Type', 'figure');
if isempty(figs)
    plotStruct = struct('style', styleTag, 'figureCount', 0, 'figures', struct([]));
    return;
end

figs = figs(isgraphics(figs, 'figure'));
if isempty(figs)
    plotStruct = struct('style', styleTag, 'figureCount', 0, 'figures', struct([]));
    return;
end

figNums = nan(numel(figs), 1);
for iNum = 1:numel(figs)
    figNums(iNum) = getFigureNumberSafe(figs(iNum));
end
[~, order] = sort(figNums);
figs = figs(order);

if exportFigures
    ensureDir(figureDir);
end

figMeta = repmat(struct('index', [], 'number', [], 'name', '', 'axesCount', 0, ...
    'lineCount', 0, 'scatterCount', 0, 'barCount', 0, 'imageCount', 0, ...
    'legendEntries', {{}}, 'axes', struct([]), 'exportPath', ''), 1, numel(figs));

nWritten = 0;
for i = 1:numel(figs)
    f = figs(i);
    if ~isgraphics(f, 'figure')
        continue;
    end
    nWritten = nWritten + 1;

    figMeta(nWritten).index = nWritten;
    figMeta(nWritten).number = getFigureNumberSafe(f);
    figMeta(nWritten).name = getFigureNameSafe(f);

    ax = findall(f, 'Type', 'axes');
    ax = ax(isgraphics(ax, 'axes'));
    ax = ax(arrayfun(@(h)~isLegendAxes(h), ax));
    ax = flipud(ax);
    figMeta(nWritten).axesCount = numel(ax);

    figMeta(nWritten).lineCount = numel(findall(f, 'Type', 'line'));
    figMeta(nWritten).scatterCount = numel(findall(f, 'Type', 'scatter'));
    figMeta(nWritten).barCount = numel(findall(f, 'Type', 'bar'));
    figMeta(nWritten).imageCount = numel(findall(f, 'Type', 'image'));
    figMeta(nWritten).legendEntries = getLegendEntries(f);

    axisMeta = repmat(struct('title', '', 'xlabel', '', 'ylabel', '', 'zlabel', '', ...
        'xlim', [], 'ylim', [], 'zlim', [], 'lineCount', 0, 'childrenCount', 0), 1, numel(ax));

    for j = 1:numel(ax)
        a = ax(j);
        axisMeta(j).title = getStringSafe(get(get(a, 'Title'), 'String'));
        axisMeta(j).xlabel = getStringSafe(get(get(a, 'XLabel'), 'String'));
        axisMeta(j).ylabel = getStringSafe(get(get(a, 'YLabel'), 'String'));
        axisMeta(j).zlabel = getStringSafe(get(get(a, 'ZLabel'), 'String'));
        axisMeta(j).xlim = get(a, 'XLim');
        axisMeta(j).ylim = get(a, 'YLim');
        axisMeta(j).zlim = get(a, 'ZLim');
        axisMeta(j).lineCount = numel(findall(a, 'Type', 'line'));
        axisMeta(j).childrenCount = numel(get(a, 'Children'));
    end
    figMeta(nWritten).axes = axisMeta;

    if exportFigures
        exportPath = fullfile(figureDir, sprintf('figure_%03d.png', nWritten));
        try
            exportgraphics(f, exportPath, 'Resolution', 150);
        catch
            saveas(f, exportPath);
        end
        figMeta(nWritten).exportPath = exportPath;
    end
end

figMeta = figMeta(1:nWritten);

plotStruct = struct();
plotStruct.style = styleTag;
plotStruct.figureCount = nWritten;
plotStruct.figures = figMeta;
end

function [numericSummary, consoleText, durationSec] = runStagedMFile(rootDir, mPath, seed)
stagingDir = tempname;
mkdir(stagingDir);
cleanupObj = onCleanup(@()cleanupStaging(stagingDir)); %#ok<NASGU>

stagedPath = fullfile(stagingDir, 'nSTATPaperExamples.m');
copyfile(mPath, stagedPath);

clear functions;
evalin('base', 'clearvars; close all force; clc;');
evalin('base', sprintf('cd(''%s'');', escapeQuotes(rootDir)));
rng(seed, 'twister');

cmd = sprintf('run(''%s'');', escapeQuotes(stagedPath));
tStart = tic;
consoleText = evalc(sprintf('evalin(''base'',''%s'');', escapeQuotes(cmd)));
durationSec = toc(tStart);

numericSummary = collectNumericSummary();
end

function summary = collectNumericSummary()
baseVars = evalin('base', 'whos');

isNum = arrayfun(@(v)isNumericClass(v.class), baseVars);
numVars = baseVars(isNum);

dimensionChecks = repmat(struct('name', '', 'class', '', 'size', [], 'numel', 0), 1, numel(numVars));
for i = 1:numel(numVars)
    dimensionChecks(i).name = numVars(i).name;
    dimensionChecks(i).class = numVars(i).class;
    dimensionChecks(i).size = numVars(i).size;
    dimensionChecks(i).numel = prod(double(numVars(i).size));
end

keyMask = false(1, numel(numVars));
for i = 1:numel(numVars)
    nm = lower(numVars(i).name);
    keyMask(i) = ~isempty(regexp(nm, '(aic|bic|coef|coeff|beta|ks|lambda|resid|dev|mu|gamma)', 'once'));
end
keyVars = numVars(keyMask);

keyMetrics = repmat(struct('name', '', 'class', '', 'size', [], 'numel', 0, ...
    'min', NaN, 'max', NaN, 'mean', NaN, 'std', NaN, 'l1norm', NaN, 'hash', ''), 1, numel(keyVars));

for i = 1:numel(keyVars)
    v = evalin('base', keyVars(i).name);
    d = double(v(:));
    if isempty(d)
        d = NaN;
    end
    keyMetrics(i).name = keyVars(i).name;
    keyMetrics(i).class = class(v);
    keyMetrics(i).size = size(v);
    keyMetrics(i).numel = numel(v);
    keyMetrics(i).min = min(d);
    keyMetrics(i).max = max(d);
    keyMetrics(i).mean = mean(d);
    keyMetrics(i).std = std(d);
    keyMetrics(i).l1norm = sum(abs(d));
    keyMetrics(i).hash = bytesHash(getByteStreamFromArray(v));
end

objectMetrics = collectObjectMetrics(baseVars);

summary = struct();
summary.dimensionChecks = dimensionChecks;
summary.keyMetrics = keyMetrics;
summary.objectMetrics = objectMetrics;
summary.numericVarCount = numel(numVars);
summary.keyMetricCount = numel(keyMetrics);
end

function objectMetrics = collectObjectMetrics(baseVars)
objVars = baseVars(arrayfun(@(v)strcmp(v.class, 'FitResult') || strcmp(v.class, 'FitResSummary'), baseVars));
objectMetrics = repmat(struct('name', '', 'class', '', 'fields', struct()), 1, numel(objVars));

for i = 1:numel(objVars)
    name = objVars(i).name;
    objectMetrics(i).name = name;
    objectMetrics(i).class = objVars(i).class;

    try
        objVal = evalin('base', name);
    catch
        continue;
    end

    fields = struct();
    fieldsSummary = {
        'AIC', 'AIC';
        'BIC', 'BIC';
        'dev', 'dev';
        'b', 'coeffs';
        'ks', 'ks';
        'lambda', 'lambda';
        'residual', 'residual';
        };

    for j = 1:size(fieldsSummary,1)
        propName = fieldsSummary{j,1};
        outName = fieldsSummary{j,2};
        try
            propVal = objVal.(propName);
            fields.(outName) = summarizeValue(propVal);
        catch
            fields.(outName) = struct('available', false);
        end
    end
    objectMetrics(i).fields = fields;
end
end

function s = summarizeValue(v)
s = struct();
s.available = true;
s.class = class(v);

if isnumeric(v) || islogical(v)
    d = double(v(:));
    if isempty(d)
        d = NaN;
    end
    s.size = size(v);
    s.numel = numel(v);
    s.min = min(d);
    s.max = max(d);
    s.mean = mean(d);
    s.std = std(d);
    s.hash = bytesHash(getByteStreamFromArray(v));
elseif iscell(v)
    s.size = size(v);
    s.numel = numel(v);
else
    s.size = size(v);
    s.numel = numel(v);
end
end

function tf = isNumericClass(cls)
tf = strcmp(cls, 'double') || strcmp(cls, 'single') || strcmp(cls, 'logical') || ...
     startsWith(cls, 'int') || startsWith(cls, 'uint');
end

function h = bytesHash(bytes)
md = java.security.MessageDigest.getInstance('MD5');
md.update(uint8(bytes));
d = typecast(md.digest(), 'uint8');
h = lower(reshape(dec2hex(d)', 1, []));
end

function out = getStringSafe(val)
if isstring(val)
    out = char(strjoin(val(:), ' | '));
elseif iscell(val)
    try
        out = char(strjoin(string(val(:)), ' | '));
    catch
        out = '';
    end
elseif ischar(val)
    out = val;
else
    out = '';
end
end

function entries = getLegendEntries(fig)
entries = {};
try
    lgd = findall(fig, 'Type', 'Legend');
    if isempty(lgd)
        return;
    end
    str = lgd(1).String;
    if ischar(str)
        entries = {str};
    elseif isstring(str)
        entries = cellstr(str(:));
    elseif iscell(str)
        entries = str;
    end
catch
    entries = {};
end
end

function tf = isLegendAxes(ax)
tf = false;
try
    tag = get(ax, 'Tag');
    if ischar(tag) && contains(lower(tag), 'legend')
        tf = true;
    end
catch
    tf = false;
end
end

function n = getFigureNumberSafe(fig)
n = NaN;
if ~isgraphics(fig, 'figure')
    return;
end
try
    raw = get(fig, 'Number');
    if isnumeric(raw)
        if isscalar(raw)
            n = double(raw);
        elseif ~isempty(raw)
            n = double(raw(1));
        end
    end
catch
end
end

function out = getFigureNameSafe(fig)
out = '';
if ~isgraphics(fig, 'figure')
    return;
end
try
    out = getStringSafe(get(fig, 'Name'));
catch
end
end

function ensureDir(pathStr)
if exist(pathStr, 'dir') ~= 7
    mkdir(pathStr);
end
end

function ensureParent(filePath)
parent = fileparts(filePath);
if ~isempty(parent)
    ensureDir(parent);
end
end

function out = escapeQuotes(in)
out = strrep(in, '''', '''''');
end

function cleanupStaging(stagingDir)
if exist(stagingDir, 'dir') == 7
    try
        rmdir(stagingDir, 's');
    catch
    end
end
end
