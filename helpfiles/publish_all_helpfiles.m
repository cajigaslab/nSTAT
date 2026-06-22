function publish_all_helpfiles(varargin)
% publish_all_helpfiles Deterministically republish all nSTAT help HTML.
%
% This script stages help source files to avoid .mlx shadowing during
% publish, regenerates HTML with evalCode enabled, and refreshes MATLAB help
% search metadata for the toolbox.

opts = parseOptions(varargin{:});

helpDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(helpDir);
stagingDir = tempname;
outputDir = tempname;
mkdir(stagingDir);
mkdir(outputDir);
cleanupObj = onCleanup(@()cleanupTempDirs(stagingDir, outputDir));
startDir = pwd;
restoreDir = onCleanup(@()cd(startDir)); %#ok<NASGU>

copyfile(fullfile(helpDir, '*'), stagingDir);
removeStagedArtifacts(stagingDir);

restoredefaultpath;
addpath(rootDir, '-begin');
nSTAT_Install('RebuildDocSearch', false, 'CleanUserPathPrefs', false);
addpath(stagingDir, '-begin');
cd(stagingDir);

% Force visible figures during publish. publish() in R2025b silently
% snapshots zero figures from invisible windows, producing helpfile HTML
% with 0–25% of the expected figures (smoke test 2026-06-19 showed
% AnalysisExamples 4→0, HybridFilterExample 2→0, PPSimExample 4→1).
% Save and restore so this does not leak to the caller.
priorFigureVisibility = get(groot, 'defaultFigureVisible');
set(groot, 'defaultFigureVisible', 'on');
restoreVisibility = onCleanup(@() set(groot, 'defaultFigureVisible', priorFigureVisibility)); %#ok<NASGU>

publishOptions = struct('outputDir', outputDir, 'format', 'html', 'evalCode', opts.EvalCode);
referencePublishOptions = struct('outputDir', outputDir, 'format', 'html', 'evalCode', false);

stageFiles = dir(fullfile(stagingDir, '*.m'));
% Filter out publish_all_helpfiles.m itself
keepMask = ~strcmpi({stageFiles.name}, 'publish_all_helpfiles.m');
stageFiles = stageFiles(keepMask);
nFiles = numel(stageFiles);

% Phase C parallelism: each helpfile publish is independent (each reads
% its own .m from a shared read-only staging dir; each writes
% baseName.html + baseName_NN.png to outputDir with non-overlapping
% names). Use parfor over the 36+ helpfiles when PCT is licensed.
% Sequential fallback if no pool is available. PCT-licensed users see
% ~75-80% wall-clock reduction (19 min -> 3-5 min on 8-core).
useParallel = opts.UseParallel && license('test', 'Distrib_Computing_Toolbox') == 1;
if useParallel
    poolObj = gcp('nocreate');
    if isempty(poolObj)
        poolObj = parpool('local'); %#ok<NASGU>
    end
    nWorkers = poolObj.NumWorkers;
    fprintf('publish_all_helpfiles: parallel publish across %d worker(s)\n', nWorkers);
else
    nWorkers = 0;
end

% Per-file timing collected via cell-then-cat pattern (parfor-safe).
% timings{iFile} = struct(name, wallSec, figCount, sectionCount, error)
timingsCell = cell(nFiles, 1);

if useParallel
    parfor iFile = 1:nFiles
        timingsCell{iFile} = publishOneStaged(stageFiles(iFile), stagingDir, ...
            outputDir, rootDir, publishOptions);
    end
else
    for iFile = 1:nFiles
        timingsCell{iFile} = publishOneStaged(stageFiles(iFile), stagingDir, ...
            outputDir, rootDir, publishOptions);
    end
end

% Class references (3 root files) run serially -- not worth a pool round
% trip for 3 calls each taking ~5 seconds.
rootReferenceFiles = {'Analysis.m', 'SignalObj.m', 'FitResult.m'};
refTimings = cell(numel(rootReferenceFiles), 1);
for iFile = 1:numel(rootReferenceFiles)
    refTimings{iFile} = publishOneReference(rootReferenceFiles{iFile}, rootDir, ...
        outputDir, referencePublishOptions);
end

% Collect failures and timings
allTimings = [timingsCell; refTimings];
allTimings = allTimings(~cellfun(@isempty, allTimings));
allTimings = vertcat(allTimings{:});
failures = {};
for k = 1:numel(allTimings)
    if ~isempty(allTimings(k).error)
        failures{end+1} = allTimings(k).error; %#ok<AGROW>
    end
end

if ~isempty(failures)
    fprintf(2, 'Publish failures (%d):\n', numel(failures));
    for i = 1:numel(failures)
        fprintf(2, '  - %s\n', failures{i});
    end
    error('nSTAT:PublishAllFailures', 'One or more help pages failed to publish.');
end

copyfile(fullfile(outputDir, '*'), helpDir, 'f');

builddocsearchdb(helpDir);
rehash toolboxcache;

validateHelpTargets(helpDir);
validateHtmlGeneratorMetadata(helpDir, opts.ExpectedGenerator);
validateNoBlankFigures(helpDir, opts.BlankPngThresholdBytes);

% Phase A: per-file timing report. Written to
% docs/verification/publish_timing_latest.md so PR reviewers can see
% if a change disproportionately slowed one helpfile.
writeTimingReport(allTimings, rootDir);

fprintf('nSTAT help publication completed successfully.\n');
clear cleanupObj;
end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'publish_all_helpfiles';
addParameter(parser, 'EvalCode', true, @(x)islogical(x) || isnumeric(x));
addParameter(parser, 'ExpectedGenerator', 'MATLAB 26.1', @(x)ischar(x) || isstring(x));
addParameter(parser, 'BlankPngThresholdBytes', 5000, @(x)isnumeric(x) && isscalar(x) && x >= 0);
addParameter(parser, 'UseParallel', true, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
parse(parser, varargin{:});

opts.EvalCode = logical(parser.Results.EvalCode);
opts.ExpectedGenerator = char(parser.Results.ExpectedGenerator);
opts.BlankPngThresholdBytes = double(parser.Results.BlankPngThresholdBytes);
opts.UseParallel = logical(parser.Results.UseParallel);
end

function timing = publishOneStaged(stageFile, stagingDir, outputDir, rootDir, publishOptions)
% Publish one staged helpfile in a parfor-safe way.
% Worker setup is idempotent and cheap when already established.
addpath(rootDir, '-begin');
addpath(stagingDir, '-begin');
cd(stagingDir);
set(groot, 'defaultFigureVisible', 'on');

[~, baseName] = fileparts(stageFile.name);
tStart = tic;
timing = struct('name', stageFile.name, 'wallSec', 0, 'figCount', 0, ...
    'sectionCount', 0, 'kind', 'helpfile', 'error', '');
try
    publish(baseName, publishOptions);
    timing.wallSec = toc(tStart);
    figs = dir(fullfile(outputDir, [baseName '_*.png']));
    timing.figCount = sum(~contains({figs.name}, '_eq'));
    src = fileread(fullfile(stagingDir, stageFile.name));
    timing.sectionCount = numel(regexp(src, '^%%', 'lineanchors'));
    fprintf('Published help topic: %s (%.1fs, %d figs)\n', ...
        stageFile.name, timing.wallSec, timing.figCount);
catch ME
    timing.wallSec = toc(tStart);
    timing.error = sprintf('%s :: %s', stageFile.name, ME.message);
end
end

function timing = publishOneReference(refName, rootDir, outputDir, refOpts)
sourceFile = fullfile(rootDir, refName);
[~, baseName] = fileparts(refName);
tStart = tic;
timing = struct('name', refName, 'wallSec', 0, 'figCount', 0, ...
    'sectionCount', 0, 'kind', 'reference', 'error', '');
try
    publish(sourceFile, refOpts);
    timing.wallSec = toc(tStart);
    figs = dir(fullfile(outputDir, [baseName '_*.png']));
    timing.figCount = sum(~contains({figs.name}, '_eq'));
    fprintf('Published class reference: %s (%.1fs)\n', refName, timing.wallSec);
catch ME
    timing.wallSec = toc(tStart);
    timing.error = sprintf('%s :: %s', refName, ME.message);
end
end

function writeTimingReport(timings, rootDir)
verDir = fullfile(rootDir, 'docs', 'verification');
if exist(verDir, 'dir') ~= 7
    mkdir(verDir);
end
reportPath = fullfile(verDir, 'publish_timing_latest.md');
fid = fopen(reportPath, 'w');
restore = onCleanup(@() fclose(fid)); %#ok<NASGU>

[~, idx] = sort([timings.wallSec], 'descend');
totalSec = sum([timings.wallSec]);

fprintf(fid, '# publish_all_helpfiles timing report\n\n');
fprintf(fid, 'Generated %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS')); %#ok<DATST>
fprintf(fid, '- Total wall-clock: **%.1f min** (%.1f s)\n', totalSec/60, totalSec);
fprintf(fid, '- Files published:  %d\n', numel(timings));
fprintf(fid, '- Total figures:    %d\n', sum([timings.figCount]));
fprintf(fid, '\n## Per-file ranked by wall-clock\n\n');
fprintf(fid, '| Rank | File | Wall (s) | Figures | Sections | snapshots/figure |\n');
fprintf(fid, '|---:|---|---:|---:|---:|---:|\n');
for k = 1:numel(idx)
    t = timings(idx(k));
    snapRatio = 0;
    if t.figCount > 0 && t.sectionCount > 0
        % Rough estimate: in publish(), a figure stays open across `%%`
        % sections by default; the snapshot count therefore tracks
        % sectionCount * (figures-still-open). A close-all-clean script
        % yields ratio close to 1; a script that leaves figures open
        % across many sections yields ratio >> 1.
        snapRatio = t.sectionCount / max(t.figCount, 1);
    end
    fprintf(fid, '| %d | %s | %.1f | %d | %d | %.1f |\n', ...
        k, t.name, t.wallSec, t.figCount, t.sectionCount, snapRatio);
end
fprintf('Wrote timing report: %s\n', reportPath);
end

function removeStagedArtifacts(stagingDir)
removePattern(stagingDir, '*.mlx');
removePattern(stagingDir, '*.asv');
removePattern(stagingDir, '*.bak');
removePattern(stagingDir, 'temp.m');
removePattern(stagingDir, 'publish_all_helpfiles.m');
end

function removePattern(stagingDir, pattern)
files = dir(fullfile(stagingDir, pattern));
for i = 1:numel(files)
    delete(fullfile(stagingDir, files(i).name));
end
end

function validateHelpTargets(helpDir)
helptocPath = fullfile(helpDir, 'helptoc.xml');
if ~isfile(helptocPath)
    error('nSTAT:MissingHelptoc', 'Missing helptoc.xml at %s', helptocPath);
end

raw = fileread(helptocPath);
matches = regexp(raw, 'target="([^"]+)"', 'tokens');
for i = 1:numel(matches)
    target = matches{i}{1};
    if startsWith(target, 'http://') || startsWith(target, 'https://')
        continue;
    end
    fullTarget = fullfile(helpDir, target);
    if ~isfile(fullTarget)
        error('nSTAT:MissingHelpTarget', ...
            'helptoc target is missing after publish: %s', fullTarget);
    end
end
end

function validateHtmlGeneratorMetadata(helpDir, expectedGenerator)
% FIX: skip hand-crafted HTML files that are not MATLAB-published
skipFiles = {'index.html'};
htmlFiles = dir(fullfile(helpDir, '*.html'));
for i = 1:numel(htmlFiles)
    if any(strcmpi(htmlFiles(i).name, skipFiles))
        continue;
    end
    htmlPath = fullfile(helpDir, htmlFiles(i).name);
    raw = fileread(htmlPath);
    if isempty(regexp(raw, ['<meta name="generator" content="' regexptranslate('escape', expectedGenerator) '"'], 'once'))
        error('nSTAT:UnexpectedHtmlGenerator', ...
            'HTML page does not match expected generator (%s): %s', ...
            expectedGenerator, htmlFiles(i).name);
    end
end
end

function validateNoBlankFigures(helpDir, thresholdBytes)
% Catch obviously-blank publish artifacts. publish() snapshots an empty
% axes frame to a small PNG when a bare `figure;` precedes a method that
% opens its own figure (e.g., FitResult.plotResults,
% FitResSummary.plotSummary). DecodingExample_03.png landed at 3506 B by
% this exact mechanism before the PR #106 fix; populated subfigures are
% routinely >5 KB.
%
% Match ONLY real figure snapshots (`Foo_NN.png` with numeric suffix).
% The main thumbnail (no `_NN` suffix) is excluded because it is
% intentionally small. LaTeX-equation snapshots (`Foo_eq<hex>.png`,
% produced by publish from `$...$` math) are also excluded because they
% are correctly small (often 300 B - 5 KB) and not artifacts of the
% orphan-`figure;` antipattern this validator targets.
%
% See CONTRIBUTING.md > "Verifying regenerated .mlx / .html / PNG
% artifacts before commit" for the broader checklist.
pngs = dir(fullfile(helpDir, '*.png'));
suspect = {};
for k = 1:numel(pngs)
    [~, baseNoExt, ~] = fileparts(pngs(k).name);
    if isempty(regexp(baseNoExt, '_\d+$', 'once'))
        continue;
    end
    if pngs(k).bytes < thresholdBytes
        suspect{end+1} = sprintf('%s (%d B)', pngs(k).name, pngs(k).bytes); %#ok<AGROW>
    end
end
if ~isempty(suspect)
    fprintf(2, 'Suspect blank/near-blank publish PNGs (< %d B):\n', thresholdBytes);
    for k = 1:numel(suspect)
        fprintf(2, '  - %s\n', suspect{k});
    end
    error('nSTAT:BlankFigureArtifact', ...
        ['%d publish PNG(s) below the %d-byte blank threshold. Most ' ...
         'common cause: a bare `figure;` immediately before a method ' ...
         'that opens its own figure (FitResult.plotResults, ' ...
         'FitResSummary.plotSummary). See CONTRIBUTING.md \"Verifying ' ...
         'regenerated .mlx / .html / PNG artifacts before commit\".'], ...
        numel(suspect), thresholdBytes);
end
end

function cleanupTempDirs(stagingDir, outputDir)
if isfolder(stagingDir)
    try
        rmdir(stagingDir, 's');
    catch
    end
end
if isfolder(outputDir)
    try
        rmdir(outputDir, 's');
    catch
    end
end
end
