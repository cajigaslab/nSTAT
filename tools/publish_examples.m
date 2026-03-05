function report = publish_examples(varargin)
%PUBLISH_EXAMPLES Publish nSTAT paper examples and export generated figures.
%
% Syntax:
%   report = publish_examples
%   report = publish_examples('Style','legacy')
%
% Name-Value options:
%   'Style'      - Plot style tag: 'modern' (default) or 'legacy'.
%   'Seed'       - RNG seed for deterministic execution (default 0).
%   'PublishDir' - Output root for docs artifacts (default docs/figures).
%   'ExecuteLiveScript' - Execute/save .mlx before export (default false).
%
% Output:
%   report - Struct with paths to exported figures and HTML.

opts = parseOptions(varargin{:});

rootDir = detectRootDir();
publishRoot = fullfile(rootDir, opts.PublishDir);
figureDir = fullfile(publishRoot, sprintf('paper_examples_%s', opts.Style));
htmlDir = fullfile(publishRoot, 'published_html');
htmlPath = fullfile(htmlDir, sprintf('nSTATPaperExamples_%s.html', opts.Style));
reportPath = fullfile(publishRoot, sprintf('publish_report_%s.json', opts.Style));

ensureDir(publishRoot);
ensureDir(figureDir);
ensureDir(htmlDir);

addpath(fullfile(rootDir, 'tools'));
capture = nstat.baseline.capture_nSTATPaperExamples( ...
    'RootDir', rootDir, ...
    'Seed', opts.Seed, ...
    'Style', opts.Style, ...
    'ExportFigures', true, ...
    'FigureDir', figureDir, ...
    'ExecuteLiveScript', opts.ExecuteLiveScript, ...
    'PublishHtml', true, ...
    'PublishHtmlPath', htmlPath);

report = struct();
report.generatedAt = char(datetime('now','TimeZone','local','Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
report.style = opts.Style;
report.seed = opts.Seed;
report.figureCount = capture.plotStructure.figureCount;
report.figureDir = figureDir;
report.publishHtmlPath = capture.runInfo.publishHtmlPath;
report.plotStructurePath = fullfile(publishRoot, sprintf('plot_structure_%s.json', opts.Style));

writeJson(reportPath, report);
writeJson(report.plotStructurePath, capture.plotStructure);

fprintf('\npublish_examples complete.\n');
fprintf('  Style       : %s\n', opts.Style);
fprintf('  Figure dir  : %s\n', report.figureDir);
fprintf('  Published   : %s\n', report.publishHtmlPath);
fprintf('  Report JSON : %s\n', reportPath);
end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'publish_examples';
addParameter(parser, 'Style', 'modern', @(x)ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'Seed', 0, @(x)isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(parser, 'PublishDir', fullfile('docs','figures'), @(x)ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'ExecuteLiveScript', false, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
parse(parser, varargin{:});
opts = parser.Results;
opts.Style = validateStyle(opts.Style);
opts.PublishDir = char(string(opts.PublishDir));
opts.ExecuteLiveScript = logical(opts.ExecuteLiveScript);
end

function style = validateStyle(style)
style = lower(char(string(style)));
valid = {'legacy', 'modern'};
if ~any(strcmp(style, valid))
    error('nstat:docs:InvalidStyle', ...
        'Invalid style "%s". Valid styles are: legacy, modern.', style);
end
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
    error('nstat:docs:WriteJsonFailed', 'Could not open %s for writing.', pathStr);
end
cleanupObj = onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s\n', jsonencode(data, 'PrettyPrint', true));
end
