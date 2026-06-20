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
failures = {};

stageFiles = dir(fullfile(stagingDir, '*.m'));
for iFile = 1:numel(stageFiles)
    [~, baseName] = fileparts(stageFiles(iFile).name);
    if strcmpi(baseName, 'publish_all_helpfiles')
        continue;
    end
    try
        publish(baseName, publishOptions);
        fprintf('Published help topic: %s\n', stageFiles(iFile).name);
    catch ME
        failures{end+1} = sprintf('%s :: %s', stageFiles(iFile).name, ME.message); %#ok<AGROW>
    end
end

rootReferenceFiles = {'Analysis.m', 'SignalObj.m', 'FitResult.m'};
for iFile = 1:numel(rootReferenceFiles)
    sourceFile = fullfile(rootDir, rootReferenceFiles{iFile});
    try
        publish(sourceFile, referencePublishOptions);
        fprintf('Published class reference: %s\n', rootReferenceFiles{iFile});
    catch ME
        failures{end+1} = sprintf('%s :: %s', rootReferenceFiles{iFile}, ME.message); %#ok<AGROW>
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

fprintf('nSTAT help publication completed successfully.\n');
clear cleanupObj;
end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'publish_all_helpfiles';
addParameter(parser, 'EvalCode', true, @(x)islogical(x) || isnumeric(x));
addParameter(parser, 'ExpectedGenerator', 'MATLAB 26.1', @(x)ischar(x) || isstring(x));
addParameter(parser, 'BlankPngThresholdBytes', 5000, @(x)isnumeric(x) && isscalar(x) && x >= 0);
parse(parser, varargin{:});

opts.EvalCode = logical(parser.Results.EvalCode);
opts.ExpectedGenerator = char(parser.Results.ExpectedGenerator);
opts.BlankPngThresholdBytes = double(parser.Results.BlankPngThresholdBytes);
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
