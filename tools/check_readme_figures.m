function report = check_readme_figures(varargin)
%CHECK_README_FIGURES Verify docs/figures/ matches current code output.
%
% Syntax:
%   report = check_readme_figures
%   report = check_readme_figures('FailOnDrift', false, ...
%                                 'TinyThreshold', 0.5, ...
%                                 'Seed', 0)
%
% Description:
%   Regenerates the README paper-example gallery via build_paper_examples
%   into a temp directory, then pixel-diffs every produced PNG against the
%   corresponding committed file under docs/figures/. Classifies each
%   figure as IDENTICAL / TINY / SUBSTANTIVE / SHAPE_DIFFER / MISSING.
%
%   IDENTICAL   : byte-equal images.
%   TINY        : mean(|Delta|) < TinyThreshold (in [0,255] space).
%                 Captures anti-aliasing / font-rasterizer rounding.
%   SUBSTANTIVE : mean(|Delta|) >= TinyThreshold. Figure actually moved.
%
%   Errors with identifier nstat:readmeFigures:drift on SUBSTANTIVE drift
%   when FailOnDrift=true (default).
%
% Name-Value Options:
%   FailOnDrift          - Throw error on SUBSTANTIVE drift (default: true).
%                          NONDETERMINISTIC verdicts are always ignored by
%                          the gate even when FailOnDrift=true.
%   TinyThreshold        - mean |Delta| cutoff between TINY and SUBSTANTIVE
%                          (default: 0.5, matching the V3.1 MVP harness).
%   Seed                 - RNG seed passed to build_paper_examples
%                          (default: 0).
%   SandboxDir           - Use a pre-existing regen directory instead of
%                          running build_paper_examples again
%                          (default: '', i.e. regen).
%   NondeterministicFiles - Cellstr of <example>/<filename.png> entries
%                          whose SUBSTANTIVE drift is reclassified as
%                          NONDETERMINISTIC (informational, not a gate
%                          failure). Default is the empirically-determined
%                          set for Example 03 (multi-threaded BLAS in
%                          SSGLM EM iterations produces non-deterministic
%                          floating-point accumulation order).
%
% Output:
%   report - struct with fields:
%     .rows                  Nx1 struct array (example, filename, verdict,
%                            meanAbsDelta, note).
%     .numIdentical,         Per-verdict counts.
%     .numTiny,
%     .numSubstantive,
%     .numShapeDiffer,
%     .numMissingInSandbox,
%     .numMissingInTree
%     .sandboxDir            Where the regen lives (caller may inspect).
%     .passed                true iff zero SUBSTANTIVE / SHAPE_DIFFER /
%                            MISSING_IN_SANDBOX entries.
%
% See also: build_paper_examples
%
% Plan: docs/superpowers/plans/2026-05-20-readme-figure-parity.md

opts = parseOpts(varargin{:});
nondetSet = normalizeAllowlist(opts.NondeterministicFiles);

repoRoot = nstat.docs.getRepoRoot();
treeRoot = fullfile(repoRoot, 'docs', 'figures');
assertDirExists(treeRoot);

if isempty(opts.SandboxDir)
    sandboxDir = fullfile(tempdir, ...
        sprintf('nstat_readme_regen_%s', char(java.util.UUID.randomUUID)));
    if exist(sandboxDir, 'dir') == 7
        rmdir(sandboxDir, 's');
    end
    cleanup = onCleanup(@() rmdirIfExists(sandboxDir)); %#ok<NASGU>
    addpath(genpath(repoRoot));
    fprintf('check_readme_figures: regenerating gallery into %s\n', sandboxDir);
    build_paper_examples('FigureRoot', sandboxDir, 'Seed', opts.Seed, 'Visible', 'off');
else
    sandboxDir = opts.SandboxDir;
    assertDirExists(sandboxDir);
    fprintf('check_readme_figures: comparing against existing sandbox %s\n', sandboxDir);
end

examples = {'example01', 'example02', 'example03', 'example04', 'example05'};
rows = struct('example', {}, 'filename', {}, 'verdict', {}, ...
              'meanAbsDelta', {}, 'note', {});

for iExample = 1:numel(examples)
    example = examples{iExample};
    treeDir = fullfile(treeRoot, example);
    sandboxExDir = fullfile(sandboxDir, example);

    treePngs = listPngs(treeDir);
    sandboxPngs = listPngs(sandboxExDir);

    for iFile = 1:numel(treePngs)
        treeName = treePngs(iFile).name;
        treeAbs = fullfile(treeDir, treeName);
        sandboxAbs = fullfile(sandboxExDir, treeName);
        [verdict, meanAbsDelta, note] = classifyPair(treeAbs, sandboxAbs, opts.TinyThreshold);
        key = [example '/' treeName];
        if strcmp(verdict, 'SUBSTANTIVE') && isKey(nondetSet, key)
            verdict = 'NONDETERMINISTIC';
            if isempty(note)
                note = 'allowlisted as non-deterministic (multi-threaded BLAS)';
            else
                note = [note '; nondet-allowlisted'];
            end
        end
        rows(end+1,1) = struct('example', example, 'filename', treeName, ...
            'verdict', verdict, 'meanAbsDelta', meanAbsDelta, 'note', note); %#ok<AGROW>
    end

    treeNames = {treePngs.name};
    sandboxNames = {sandboxPngs.name};
    orphans = setdiff(sandboxNames, treeNames);
    for iOrphan = 1:numel(orphans)
        rows(end+1,1) = struct('example', example, 'filename', orphans{iOrphan}, ...
            'verdict', 'NEW_IN_SANDBOX', 'meanAbsDelta', NaN, ...
            'note', 'figure produced by current code but not in tree'); %#ok<AGROW>
    end
end

report = struct();
report.rows = rows;
report.numIdentical          = sum(strcmp({rows.verdict}, 'IDENTICAL'));
report.numTiny               = sum(strcmp({rows.verdict}, 'TINY'));
report.numSubstantive        = sum(strcmp({rows.verdict}, 'SUBSTANTIVE'));
report.numNondeterministic   = sum(strcmp({rows.verdict}, 'NONDETERMINISTIC'));
report.numShapeDiffer        = sum(strcmp({rows.verdict}, 'SHAPE_DIFFER'));
report.numMissingInSandbox   = sum(strcmp({rows.verdict}, 'MISSING_IN_SANDBOX'));
report.numMissingInTree      = sum(strcmp({rows.verdict}, 'MISSING_IN_TREE'));
report.numNewInSandbox       = sum(strcmp({rows.verdict}, 'NEW_IN_SANDBOX'));
report.sandboxDir            = sandboxDir;
report.passed = (report.numSubstantive == 0) && (report.numShapeDiffer == 0) && ...
                (report.numMissingInSandbox == 0);

printReport(report);

if opts.FailOnDrift && ~report.passed
    error('nstat:readmeFigures:drift', ...
        'check_readme_figures: %d SUBSTANTIVE, %d SHAPE_DIFFER, %d MISSING_IN_SANDBOX (see report).', ...
        report.numSubstantive, report.numShapeDiffer, report.numMissingInSandbox);
end
end

% =========================================================================
function opts = parseOpts(varargin)
parser = inputParser;
parser.FunctionName = 'check_readme_figures';
addParameter(parser, 'FailOnDrift',   true,  @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'TinyThreshold', 0.5,   @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(parser, 'Seed',          0,     @(x) isnumeric(x) && isscalar(x));
addParameter(parser, 'SandboxDir',    '',    @(x) ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'NondeterministicFiles', defaultNondetFiles(), @iscellstr);
parse(parser, varargin{:});
opts = parser.Results;
opts.FailOnDrift = logical(opts.FailOnDrift);
opts.SandboxDir = char(string(opts.SandboxDir));
end

function files = defaultNondetFiles()
% Empirically determined 2026-05-20: Example 03 SSGLM EM iterations produce
% non-deterministic floating-point accumulation order under multi-threaded
% BLAS, so these three figures drift between same-code same-seed runs by
% mean |Δ| ~2-7. See docs/verification/readme_figure_parity.md.
files = { ...
    'example03/fig03_ssglm_simulation_summary.png', ...
    'example03/fig05_stimulus_effect_surfaces.png', ...
    'example03/fig06_learning_trial_comparison.png' ...
};
end

function set = normalizeAllowlist(files)
% Build a fast-lookup set keyed by 'exampleNN/fig*.png'.
set = containers.Map('KeyType', 'char', 'ValueType', 'logical');
for k = 1:numel(files)
    key = strrep(char(files{k}), '\', '/');
    set(key) = true;
end
end

function entries = listPngs(dirPath)
if exist(dirPath, 'dir') == 7
    entries = dir(fullfile(dirPath, '*.png'));
else
    entries = struct('name', {}, 'folder', {});
end
end

function [verdict, meanAbsDelta, note] = classifyPair(treeAbs, sandboxAbs, tinyThreshold)
note = '';
meanAbsDelta = NaN;
if exist(sandboxAbs, 'file') ~= 2
    verdict = 'MISSING_IN_SANDBOX';
    note = sprintf('sandbox file not produced: %s', sandboxAbs);
    return;
end
if exist(treeAbs, 'file') ~= 2
    verdict = 'MISSING_IN_TREE';
    note = sprintf('tree file does not exist: %s', treeAbs);
    return;
end
try
    a = imread(treeAbs);
    b = imread(sandboxAbs);
catch ME
    verdict = 'READ_ERROR';
    note = ME.message;
    return;
end
if ~isequal(size(a), size(b))
    verdict = 'SHAPE_DIFFER';
    note = sprintf('tree=%s sandbox=%s', mat2str(size(a)), mat2str(size(b)));
    return;
end
meanAbsDelta = mean(abs(double(a(:)) - double(b(:))));
if meanAbsDelta == 0
    verdict = 'IDENTICAL';
elseif meanAbsDelta < tinyThreshold
    verdict = 'TINY';
else
    verdict = 'SUBSTANTIVE';
end
end

function printReport(report)
fprintf('\n=== check_readme_figures report ===\n');
fprintf('  IDENTICAL         : %d\n', report.numIdentical);
fprintf('  TINY              : %d\n', report.numTiny);
fprintf('  NONDETERMINISTIC  : %d  (allowlisted, informational only)\n', report.numNondeterministic);
fprintf('  SUBSTANTIVE       : %d\n', report.numSubstantive);
fprintf('  SHAPE_DIFFER      : %d\n', report.numShapeDiffer);
fprintf('  MISSING_IN_SANDBOX: %d\n', report.numMissingInSandbox);
fprintf('  MISSING_IN_TREE   : %d\n', report.numMissingInTree);
fprintf('  NEW_IN_SANDBOX    : %d\n', report.numNewInSandbox);
fprintf('  PASSED            : %s\n', mat2str(report.passed));
if ~report.passed
    badVerdicts = {'SUBSTANTIVE', 'SHAPE_DIFFER', 'MISSING_IN_SANDBOX'};
    fprintf('\nBad rows:\n');
    for k = 1:numel(report.rows)
        if any(strcmp(report.rows(k).verdict, badVerdicts))
            fprintf('  [%s] %s/%s  meanAbsDelta=%.4f  %s\n', ...
                report.rows(k).verdict, report.rows(k).example, ...
                report.rows(k).filename, report.rows(k).meanAbsDelta, ...
                report.rows(k).note);
        end
    end
end
end

function assertDirExists(dirPath)
if exist(dirPath, 'dir') ~= 7
    error('nstat:readmeFigures:missingDir', 'Directory does not exist: %s', dirPath);
end
end

function rmdirIfExists(dirPath)
if exist(dirPath, 'dir') == 7
    try
        rmdir(dirPath, 's');
    catch
        % best-effort cleanup
    end
end
end
