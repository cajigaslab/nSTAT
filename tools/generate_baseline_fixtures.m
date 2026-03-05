function report = generate_baseline_fixtures(varargin)
%GENERATE_BASELINE_FIXTURES Generate PR0 baseline numeric/plot fixtures.
%
% Syntax:
%   report = generate_baseline_fixtures
%   report = generate_baseline_fixtures('Seed',0,'Style','legacy')
%
% This script executes/publishes helpfiles/nSTATPaperExamples.mlx,
% captures compact numeric goldens, exports legacy figures, and writes
% plot-structure metadata used by parity checks.

opts = parseOptions(varargin{:});

rootDir = detectRootDir();
fixturesRoot = fullfile(rootDir, 'fixtures');
numericDir = fullfile(fixturesRoot, 'baseline_numeric');
figureDir = fullfile(fixturesRoot, 'baseline_figures_legacy');
publishDir = fullfile(fixturesRoot, 'published_help');

ensureDir(fixturesRoot);
ensureDir(numericDir);
ensureDir(figureDir);
ensureDir(publishDir);

capture = nstat.baseline.capture_nSTATPaperExamples( ...
    'RootDir', rootDir, ...
    'Seed', opts.Seed, ...
    'Style', opts.Style, ...
    'ExportFigures', true, ...
    'FigureDir', figureDir, ...
    'PublishHtml', opts.PublishHtml, ...
    'PublishHtmlPath', fullfile(publishDir, 'nSTATPaperExamples_legacy.html'));

numericMatPath = fullfile(numericDir, 'nSTATPaperExamples_numeric_baseline.mat');
numericJsonPath = fullfile(numericDir, 'nSTATPaperExamples_numeric_baseline.json');
plotJsonPath = fullfile(fixturesRoot, 'baseline_plot_structure.json');
runReportPath = fullfile(fixturesRoot, 'baseline_run_report.json');

numericBaseline = struct();
numericBaseline.meta = capture.runInfo;
numericBaseline.numeric = capture.numeric;

plotBaseline = struct();
plotBaseline.meta = capture.runInfo;
plotBaseline.plot = capture.plotStructure;

save(numericMatPath, 'numericBaseline');
writeJson(numericJsonPath, numericBaseline);
writeJson(plotJsonPath, plotBaseline);

report = struct();
report.generatedAt = char(datetime('now','TimeZone','local','Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
report.numericMatPath = numericMatPath;
report.numericJsonPath = numericJsonPath;
report.plotJsonPath = plotJsonPath;
report.figureDir = figureDir;
report.publishPath = capture.runInfo.publishHtmlPath;
report.figureCount = capture.plotStructure.figureCount;
report.numericVarCount = capture.numeric.numericVarCount;
report.keyMetricCount = capture.numeric.keyMetricCount;
report.console = capture.console;

writeJson(runReportPath, report);

fprintf('\nBaseline fixture generation complete.\n');
fprintf('  Numeric MAT : %s\n', numericMatPath);
fprintf('  Numeric JSON: %s\n', numericJsonPath);
fprintf('  Plot JSON   : %s\n', plotJsonPath);
fprintf('  Figures     : %s\n', figureDir);
fprintf('  Published   : %s\n', capture.runInfo.publishHtmlPath);

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'generate_baseline_fixtures';
addParameter(parser, 'Seed', 0, @(x)isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(parser, 'Style', 'legacy', @(x)ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'PublishHtml', true, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
parse(parser, varargin{:});
opts = parser.Results;
opts.Style = char(string(opts.Style));
opts.PublishHtml = logical(opts.PublishHtml);
end

function rootDir = detectRootDir()
rootDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(rootDir);
end

function ensureDir(pathStr)
if exist(pathStr, 'dir') ~= 7
    mkdir(pathStr);
end
end

function writeJson(pathStr, data)
fid = fopen(pathStr, 'w');
if fid < 0
    error('nstat:baseline:WriteJsonFailed', 'Could not open %s for writing.', pathStr);
end
cleanupObj = onCleanup(@()fclose(fid)); %#ok<NASGU>
jsonTxt = jsonencode(data, 'PrettyPrint', true);
fprintf(fid, '%s\n', jsonTxt);
end
