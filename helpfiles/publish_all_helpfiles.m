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

% Phase D: incremental publish via per-file cache. Skip helpfiles whose
% source .m AND toolbox class sources AND MATLAB version are unchanged
% since the last successful publish. Cache lives at
% helpfiles/.publish-cache.json (gitignored). predeploy.sh passes
% Force=true so a release run never trusts the cache.
%
% Skip logic: a file is skipped IFF
%   1. globalHash (toolbox .m hashes + MATLAB version + publish opts) matches
%   2. fileHash (staged .m source) matches
%   3. every cached output file still exists in helpDir
% Cached outputs are pre-seeded into outputDir so the existing
% "copyfile outputDir -> helpDir" round-trips them through unchanged.
matlabVersionStr = sprintf('%s', version);
globalHash = computeGlobalHash(rootDir, helpDir, matlabVersionStr, opts);
[cacheData, cacheValid] = loadCache(opts.CacheFile, globalHash, opts.Force);

dirtyMask = true(nFiles, 1);
fileHashes = cell(nFiles, 1);
skippedNames = {};
skippedOutputs = {};
for iFile = 1:nFiles
    sName = stageFiles(iFile).name;
    fileHashes{iFile} = sha256File(fullfile(stagingDir, sName));
    if ~cacheValid
        continue
    end
    if ~isfield(cacheData.files, matlab.lang.makeValidName(sName))
        continue
    end
    entry = cacheData.files.(matlab.lang.makeValidName(sName));
    if ~strcmp(entry.fileHash, fileHashes{iFile})
        continue
    end
    if ~allOutputsPresent(helpDir, entry.outputs)
        continue
    end
    dirtyMask(iFile) = false;
    skippedNames{end+1} = sName; %#ok<AGROW>
    skippedOutputs{end+1} = entry.outputs; %#ok<AGROW>
    % Pre-seed outputDir so the final round-trip preserves these files.
    for kOut = 1:numel(entry.outputs)
        src = fullfile(helpDir, entry.outputs{kOut});
        dst = fullfile(outputDir, entry.outputs{kOut});
        copyfile(src, dst, 'f');
    end
end
nSkipped = sum(~dirtyMask);
nDirty   = sum(dirtyMask);
fprintf('publish_all_helpfiles: cache %s. %d/%d helpfile(s) cached, %d to publish.\n', ...
    ternary(cacheValid, 'HIT', 'MISS (rebuild all)'), nSkipped, nFiles, nDirty);

stageFilesAll = stageFiles;
fileHashesAll = fileHashes;
stageFiles    = stageFilesAll(dirtyMask);
nFiles        = numel(stageFiles);

useParallel = opts.UseParallel && nFiles > 1 && license('test', 'Distrib_Computing_Toolbox') == 1;
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

% Synthesize timings for cache-skipped files (wallSec=0, kind='cached')
skippedTimingsCell = cell(numel(skippedNames), 1);
for k = 1:numel(skippedNames)
    skippedTimingsCell{k} = struct('name', skippedNames{k}, ...
        'wallSec', 0, 'figCount', countFigOutputs(skippedOutputs{k}), ...
        'sectionCount', 0, 'kind', 'cached', 'error', '', ...
        'outputs', {skippedOutputs{k}});
end

% Collect failures and timings
allTimings = [skippedTimingsCell; timingsCell; refTimings];
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

% Skip the doc-search-index rebuild on a full cache HIT: every helpfile's
% HTML is byte-identical to the prior run (cache HIT implies content-hash
% match), so the existing helpsearch-v4_en/ index is still current. Saves
% ~10-15s on warm runs. Class references re-publish deterministically
% from the same source so they don't drift either.
fullCacheHit = cacheValid && sum(dirtyMask) == 0;
if ~fullCacheHit
    builddocsearchdb(helpDir);
end
rehash toolboxcache;

validateHelpTargets(helpDir);
validateHtmlGeneratorMetadata(helpDir, opts.ExpectedGenerator);
validateNoBlankFigures(helpDir, opts.BlankPngThresholdBytes);

% Phase A: per-file timing report. Written to
% docs/verification/publish_timing_latest.md so PR reviewers can see
% if a change disproportionately slowed one helpfile.
writeTimingReport(allTimings, rootDir);

% Phase D: persist cache only after a fully-successful run (validators
% passed). Cache entries include every helpfile that has good outputs on
% disk -- skipped (reuse cached entry) and newly-published (use fresh
% hash + outputs). Class references are NOT cached because they are
% serial, fast, and would require their own hash machinery.
writeCache(opts.CacheFile, globalHash, matlabVersionStr, opts, ...
    stageFilesAll, fileHashesAll, dirtyMask, skippedOutputs, allTimings);

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
addParameter(parser, 'Force', false, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'CacheFile', '', @(x)ischar(x) || isstring(x));
parse(parser, varargin{:});

opts.EvalCode = logical(parser.Results.EvalCode);
opts.ExpectedGenerator = char(parser.Results.ExpectedGenerator);
opts.BlankPngThresholdBytes = double(parser.Results.BlankPngThresholdBytes);
opts.UseParallel = logical(parser.Results.UseParallel);
opts.Force = logical(parser.Results.Force);
opts.CacheFile = char(parser.Results.CacheFile);
if isempty(opts.CacheFile)
    helpDir = fileparts(mfilename('fullpath'));
    opts.CacheFile = fullfile(helpDir, '.publish-cache.json');
end
end

function timing = publishOneStaged(stageFile, stagingDir, outputDir, rootDir, publishOptions)
% Publish one staged helpfile in a parfor-safe way.
% Worker setup is idempotent and cheap when already established.
addpath(rootDir, '-begin');
addpath(stagingDir, '-begin');
cd(stagingDir);
set(groot, 'defaultFigureVisible', 'on');

% Close any figures left open by a prior parfor iteration on this
% worker. publish() does not close figures it opened, and the
% section-end snapshot in the NEXT iteration captures every open
% figure -- so stale figures from the previous helpfile get re-
% snapshotted into this helpfile's outputs, named with this helpfile's
% baseName and re-numbered into its sequence. That's the mechanism
% behind the 18-21 figure variance observed for SignalObjExamples
% across runs of publish_all_helpfiles (smoke_helpfile, which is
% sequential and starts in a clean MATLAB instance, produces 17
% deterministically). Clearing here makes every parfor iteration
% start from a clean visual state.
close all force;

[~, baseName] = fileparts(stageFile.name);
tStart = tic;
timing = struct('name', stageFile.name, 'wallSec', 0, 'figCount', 0, ...
    'sectionCount', 0, 'kind', 'helpfile', 'error', '', 'outputs', {{}});
try
    publish(baseName, publishOptions);
    timing.wallSec = toc(tStart);
    % Discover outputs by pattern. The literal '_' in baseName_*.png and
    % '.' in baseName.html prevents prefix collisions (e.g., baseName
    % 'DecodingExample' will not match 'DecodingExampleWithHist_01.png').
    htmls = dir(fullfile(outputDir, [baseName '.html']));
    figs  = dir(fullfile(outputDir, [baseName '_*.png']));
    timing.outputs = [{htmls.name}, {figs.name}];
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
    'sectionCount', 0, 'kind', 'reference', 'error', '', 'outputs', {{}});
try
    publish(sourceFile, refOpts);
    timing.wallSec = toc(tStart);
    htmls = dir(fullfile(outputDir, [baseName '.html']));
    figs  = dir(fullfile(outputDir, [baseName '_*.png']));
    timing.outputs = [{htmls.name}, {figs.name}];
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

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end

function n = countFigOutputs(outputs)
% Count real figure snapshots (exclude main thumbnail + equation PNGs).
n = 0;
for i = 1:numel(outputs)
    [~, base, ext] = fileparts(outputs{i});
    if ~strcmpi(ext, '.png'), continue; end
    if isempty(regexp(base, '_\d+$', 'once')), continue; end  % thumbnail
    if contains(base, '_eq'), continue; end                   % equation
    n = n + 1;
end
end

function h = sha256File(filePath)
fid = fopen(filePath, 'r');
if fid < 0
    h = '';
    return
end
bytes = fread(fid, inf, '*uint8');
fclose(fid);
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(bytes);
digest = typecast(md.digest, 'uint8');
h = lower(reshape(dec2hex(digest, 2).', 1, []));
end

function h = sha256String(s)
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(uint8(s));
digest = typecast(md.digest, 'uint8');
h = lower(reshape(dec2hex(digest, 2).', 1, []));
end

function h = computeGlobalHash(rootDir, helpDir, matlabVersionStr, opts)
% Hash all toolbox sources whose change could affect helpfile output:
%   - every .m at the repo root (toolbox classes)
%   - every .m under +nstat/** recursively (package code)
%   - every .mat under helpfiles/ (input data referenced by helpfiles)
%   - the publish orchestrator itself
%   - MATLAB version
%   - publish options that affect output (EvalCode, ExpectedGenerator)
parts = {};
parts{end+1} = ['MATLAB:' matlabVersionStr];
parts{end+1} = sprintf('evalCode:%d', opts.EvalCode);
parts{end+1} = ['generator:' opts.ExpectedGenerator];

rootMs = dir(fullfile(rootDir, '*.m'));
for i = 1:numel(rootMs)
    parts{end+1} = [rootMs(i).name ':' sha256File(fullfile(rootDir, rootMs(i).name))]; %#ok<AGROW>
end

nstatDir = fullfile(rootDir, '+nstat');
if isfolder(nstatDir)
    pkgMs = dir(fullfile(nstatDir, '**', '*.m'));
    for i = 1:numel(pkgMs)
        relPath = strrep(fullfile(pkgMs(i).folder, pkgMs(i).name), [rootDir filesep], '');
        parts{end+1} = [relPath ':' sha256File(fullfile(pkgMs(i).folder, pkgMs(i).name))]; %#ok<AGROW>
    end
end

mats = dir(fullfile(helpDir, '*.mat'));
for i = 1:numel(mats)
    parts{end+1} = ['helpfiles/' mats(i).name ':' sha256File(fullfile(helpDir, mats(i).name))]; %#ok<AGROW>
end

parts{end+1} = ['publish_all_helpfiles.m:' sha256File(fullfile(helpDir, 'publish_all_helpfiles.m'))];

parts = sort(parts);
h = sha256String(strjoin(parts, char(10)));
end

function [cacheData, cacheValid] = loadCache(cacheFile, globalHash, force)
cacheData = struct('files', struct());
cacheValid = false;
if force
    fprintf('publish_all_helpfiles: Force=true, ignoring cache.\n');
    return
end
if ~isfile(cacheFile)
    return
end
try
    raw = fileread(cacheFile);
    decoded = jsondecode(raw);
catch
    return  % corrupt/unreadable cache -> treat as miss
end
if ~isfield(decoded, 'globalHash') || ~strcmp(decoded.globalHash, globalHash)
    return  % toolbox sources / MATLAB ver / opts changed -> invalidate all
end
if ~isfield(decoded, 'files') || ~isstruct(decoded.files)
    return
end
% Normalize outputs to cellstr -- jsondecode collapses single-element
% arrays to char scalars, which would break numel/iteration logic.
fnames = fieldnames(decoded.files);
for fi = 1:numel(fnames)
    e = decoded.files.(fnames{fi});
    if ~isfield(e, 'outputs')
        continue
    end
    if ischar(e.outputs)
        e.outputs = {e.outputs};
    elseif isstring(e.outputs)
        e.outputs = cellstr(e.outputs);
    end
    decoded.files.(fnames{fi}) = e;
end
cacheData = decoded;
cacheValid = true;
end

function tf = allOutputsPresent(helpDir, outputs)
tf = true;
for i = 1:numel(outputs)
    if ~isfile(fullfile(helpDir, outputs{i}))
        tf = false;
        return
    end
end
end

function writeCache(cacheFile, globalHash, matlabVersionStr, opts, ...
        stageFilesAll, fileHashesAll, dirtyMask, skippedOutputs, allTimings)
% Build a fresh cache from this run's outcome. Skipped files reuse their
% fileHash + outputs (still valid by definition); published files use
% the hash captured pre-publish and the output list discovered in
% publishOneStaged.
cacheData = struct( ...
    'version', 1, ...
    'globalHash', globalHash, ...
    'matlabVersion', matlabVersionStr, ...
    'evalCode', opts.EvalCode, ...
    'expectedGenerator', opts.ExpectedGenerator, ...
    'files', struct());

% Index published timings by name for quick lookup
publishedByName = containers.Map('KeyType', 'char', 'ValueType', 'any');
for k = 1:numel(allTimings)
    t = allTimings(k);
    if strcmp(t.kind, 'helpfile') && isempty(t.error) && ~isempty(t.outputs)
        publishedByName(t.name) = t.outputs;
    end
end

skippedIdx = 0;
for iFile = 1:numel(stageFilesAll)
    sName = stageFilesAll(iFile).name;
    key = matlab.lang.makeValidName(sName);
    if dirtyMask(iFile)
        if ~isKey(publishedByName, sName)
            continue  % publish failed for this file -> exclude from cache
        end
        outs = publishedByName(sName);
    else
        skippedIdx = skippedIdx + 1;
        outs = skippedOutputs{skippedIdx};
    end
    cacheData.files.(key) = struct( ...
        'name', sName, ...
        'fileHash', fileHashesAll{iFile}, ...
        'outputs', {outs});
end

try
    fid = fopen(cacheFile, 'w');
    if fid < 0
        warning('nSTAT:CacheWriteFailed', 'Could not open cache file for write: %s', cacheFile);
        return
    end
    fprintf(fid, '%s\n', jsonencode(cacheData, 'PrettyPrint', true));
    fclose(fid);
    fprintf('Wrote publish cache: %s (%d entries)\n', cacheFile, numel(fieldnames(cacheData.files)));
catch ME
    warning('nSTAT:CacheWriteFailed', 'Cache write failed: %s', ME.message);
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
