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

fprintf('nSTAT help publication completed successfully.\n');
clear cleanupObj;
end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'publish_all_helpfiles';
addParameter(parser, 'EvalCode', true, @(x)islogical(x) || isnumeric(x));
addParameter(parser, 'ExpectedGenerator', 'MATLAB 25.2', @(x)ischar(x) || isstring(x));
parse(parser, varargin{:});

opts.EvalCode = logical(parser.Results.EvalCode);
opts.ExpectedGenerator = char(parser.Results.ExpectedGenerator);
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
htmlFiles = dir(fullfile(helpDir, '*.html'));
for i = 1:numel(htmlFiles)
    htmlPath = fullfile(helpDir, htmlFiles(i).name);
    raw = fileread(htmlPath);
    if isempty(regexp(raw, ['<meta name="generator" content="' regexptranslate('escape', expectedGenerator) '"'], 'once'))
        error('nSTAT:UnexpectedHtmlGenerator', ...
            'HTML page does not match expected generator (%s): %s', ...
            expectedGenerator, htmlFiles(i).name);
    end
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
