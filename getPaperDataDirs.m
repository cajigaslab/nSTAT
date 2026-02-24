function [dataDir,mEPSCDir,explicitStimulusDir,psthDir,placeCellDataDir] = getPaperDataDirs()
%GETPAPERDATADIRS Resolve local nSTAT paper data directories.
%   [dataDir,mEPSCDir,explicitStimulusDir,psthDir,placeCellDataDir] = ...
%       getPaperDataDirs()
%   returns absolute paths to the nSTAT data folders used by paper
%   examples, independent of the current working directory.

candidateRoots = {};

thisFile = mfilename('fullpath');
if ~isempty(thisFile)
    candidateRoots = appendCandidateRoot(candidateRoots, fileparts(thisFile));
end

paperPath = which('nSTATPaperExamples');
if ~isempty(paperPath)
    candidateRoots = appendCandidateRoot(candidateRoots, fileparts(fileparts(paperPath)));
end

installPath = which('nSTAT_Install');
if ~isempty(installPath)
    candidateRoots = appendCandidateRoot(candidateRoots, fileparts(installPath));
end

try
    activeFile = matlab.desktop.editor.getActiveFilename;
catch
    activeFile = '';
end
if ~isempty(activeFile)
    candidateRoots = appendCandidateRoot(candidateRoots, fileparts(fileparts(activeFile)));
end

candidateRoots = appendCandidateRoot(candidateRoots, pwd);

nSTATDir = '';
for iRoot = 1:numel(candidateRoots)
    candidateDataDir = fullfile(candidateRoots{iRoot}, 'data');
    if exist(candidateDataDir, 'dir') == 7
        nSTATDir = candidateRoots{iRoot};
        break;
    end
end

if isempty(nSTATDir)
    error('getPaperDataDirs:MissingInstallPath', ...
        ['Could not resolve the nSTAT root path. Checked roots derived from ', ...
         'mfilename, which(''nSTATPaperExamples''), which(''nSTAT_Install''), ', ...
         'the active editor file, and pwd.']);
end

dataDir = fullfile(nSTATDir,'data');
mEPSCDir = fullfile(dataDir,'mEPSCs');
explicitStimulusDir = fullfile(dataDir,'Explicit Stimulus');
psthDir = fullfile(dataDir,'PSTH');
placeCellDataDir = fullfile(dataDir,'Place Cells');

if exist(dataDir,'dir') ~= 7
    error('getPaperDataDirs:MissingDataDir', ...
        'Could not find local nSTAT data folder at %s', dataDir);
end
end

function roots = appendCandidateRoot(roots, startDir)
if isempty(startDir)
    return;
end

thisDir = startDir;
while true
    if ~any(strcmp(roots, thisDir))
        roots{end+1} = thisDir; %#ok<AGROW>
    end
    parentDir = fileparts(thisDir);
    if strcmp(parentDir, thisDir)
        break;
    end
    thisDir = parentDir;
end
end
