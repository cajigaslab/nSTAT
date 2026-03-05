function manifest = build_paper_examples(varargin)
%BUILD_PAPER_EXAMPLES Build all nSTAT paper example scripts and figures.
%
% Syntax:
%   manifest = build_paper_examples
%   manifest = build_paper_examples('Seed', 0, 'ExportSvg', true)
%
% Description:
%   Runs every standalone paper example under `examples/paper`, exports all
%   generated figures into `docs/figures/<example_id>/`, and writes a JSON
%   manifest at `docs/figures/manifest.json`.
%
% Name-Value Options:
%   Seed       - RNG seed used for deterministic examples (default: 0).
%   FigureRoot - Output root relative to repo root (default: docs/figures).
%   ExportSvg  - Also export SVG alongside PNG files (default: false).
%   Visible    - Figure visibility during batch run: 'off' or 'on' (default: 'off').
%
% Output:
%   manifest - Struct describing all generated outputs.

opts = parseOptions(varargin{:});
repoRoot = nstat.docs.getRepoRoot();
addpath(genpath(repoRoot));

rng(opts.Seed, 'twister');
figureRoot = fullfile(repoRoot, opts.FigureRoot);
if exist(figureRoot, 'dir') ~= 7
    mkdir(figureRoot);
end

exampleSpecs = getExampleSpecs();
entries = repmat(struct( ...
    'example_id', '', ...
    'title', '', ...
    'source_script', '', ...
    'description', '', ...
    'figure_files', {{}}, ...
    'paper_mapping', ''), 0, 1);

for iExample = 1:numel(exampleSpecs)
    spec = exampleSpecs(iExample);
    exampleDir = fullfile(figureRoot, spec.id);
    if exist(exampleDir, 'dir') ~= 7
        mkdir(exampleDir);
    else
        deleteIfExists(fullfile(exampleDir, '*.png'));
        deleteIfExists(fullfile(exampleDir, '*.svg'));
    end

    result = feval(spec.functionName, ...
        'Seed', opts.Seed, ...
        'ExportFigures', true, ...
        'ExportDir', exampleDir, ...
        'ExportSvg', opts.ExportSvg, ...
        'Visible', opts.Visible, ...
        'CloseFigures', true);

    entry = struct();
    entry.example_id = result.example_id;
    entry.title = result.title;
    entry.source_script = toRepoRelative(repoRoot, result.source_script);
    entry.description = result.description;
    entry.figure_files = cellfun(@(p) toRepoRelative(repoRoot, p), result.figure_files, ...
        'UniformOutput', false);
    entry.paper_mapping = result.paper_mapping;
    entries(end+1,1) = entry; %#ok<AGROW>
end

manifest = struct();
manifest.generated_at = char(datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd''T''HH:mm:ssXXX'));
manifest.matlab_version = version;
manifest.seed = opts.Seed;
manifest.figure_root = toRepoRelative(repoRoot, figureRoot);
manifest.examples = entries;

manifestPath = fullfile(figureRoot, 'manifest.json');
nstat.docs.writeJson(manifestPath, manifest);

fprintf('\nbuild_paper_examples complete.\n');
fprintf('  Examples run : %d\n', numel(entries));
fprintf('  Figure root  : %s\n', figureRoot);
fprintf('  Manifest     : %s\n', manifestPath);
end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'build_paper_examples';
addParameter(parser, 'Seed', 0, @(x) isnumeric(x) && isscalar(x));
addParameter(parser, 'FigureRoot', fullfile('docs', 'figures'), @(x) ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'ExportSvg', false, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'Visible', 'off', @(x) ischar(x) || (isstring(x) && isscalar(x)));
parse(parser, varargin{:});

opts = parser.Results;
opts.FigureRoot = char(string(opts.FigureRoot));
opts.ExportSvg = logical(opts.ExportSvg);
opts.Visible = validatestring(char(string(opts.Visible)), {'off', 'on'});
end

function specs = getExampleSpecs()
specs = [ ...
    struct('id', 'example01', 'functionName', 'example01_mepsc_poisson'); ...
    struct('id', 'example02', 'functionName', 'example02_whisker_stimulus_thalamus'); ...
    struct('id', 'example03', 'functionName', 'example03_psth_and_ssglm'); ...
    struct('id', 'example04', 'functionName', 'example04_place_cells_continuous_stimulus'); ...
    struct('id', 'example05', 'functionName', 'example05_decoding_ppaf_pphf') ...
    ];
end

function relPath = toRepoRelative(repoRoot, absPath)
if isempty(absPath)
    relPath = '';
    return;
end
repoRoot = char(string(repoRoot));
absPath = char(string(absPath));

if startsWith(absPath, [repoRoot filesep])
    relPath = absPath((numel(repoRoot) + 2):end);
else
    relPath = absPath;
end

relPath = strrep(relPath, '\\', '/');
end

function deleteIfExists(globExpr)
files = dir(globExpr);
for iFile = 1:numel(files)
    delete(fullfile(files(iFile).folder, files(iFile).name));
end
end
