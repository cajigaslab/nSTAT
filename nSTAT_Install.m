function opts = nSTAT_Install(varargin)
% nSTAT_Install Configure nSTAT MATLAB runtime paths and help integration.
%
% Usage:
%   nSTAT_Install
%   nSTAT_Install('RebuildDocSearch',true,'CleanUserPathPrefs',false)
%   opts = nSTAT_Install(...)
%
% Name-value options:
%   RebuildDocSearch   (default true)  Rebuild help search DB in helpfiles/.
%   CleanUserPathPrefs (default false) Remove stale user MATLAB path entries.
%
% This installer intentionally excludes non-runtime trees (helpfiles, python,
% cache folders, hidden folders) from the MATLAB path to avoid shadowing.

%
% nSTAT v1 Copyright (C) 2012 Masschusetts Institute of Technology
% Cajigas, I, Malik, WQ, Brown, EN
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License as published
% by the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software Foundation,
% Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

opts = parseInstallOptions(varargin{:});

fileLocation = mfilename('fullpath');
rootDir = fileparts(fileLocation);
helpDir = fullfile(rootDir, 'helpfiles');

display('Configuring nSTAT MATLAB runtime search path');
removeExistingRootPaths(rootDir);
runtimePaths = collectRuntimePaths(rootDir);
if isempty(runtimePaths)
    warning('nSTAT:EmptyRuntimePath', ...
        'No runtime MATLAB paths were discovered under %s', rootDir);
else
    addpath(runtimePaths{:}, '-begin');
end

if opts.RebuildDocSearch
    if isfolder(helpDir)
        display('Building nSTAT help search database');
        builddocsearchdb(helpDir);
    else
        warning('nSTAT:MissingHelpFolder', ...
            'Help folder was not found at: %s', helpDir);
    end
end

if opts.CleanUserPathPrefs
    cleanupFcn = 'cleanup_user_path_prefs';
    cleanupFile = fullfile(rootDir, 'tools', 'matlab', [cleanupFcn '.m']);
    if exist(cleanupFcn, 'file') == 2
        feval(cleanupFcn, rootDir);
    elseif isfile(cleanupFile)
        addpath(fileparts(cleanupFile), '-begin');
        if exist(cleanupFcn, 'file') == 2
            feval(cleanupFcn, rootDir);
        else
            warning('nSTAT:CleanupFunctionUnavailable', ...
                'Could not invoke %s after running %s', cleanupFcn, cleanupFile);
        end
    else
        warning('nSTAT:MissingCleanupScript', ...
            'Cleanup script not found: %s', cleanupFile);
    end
end

display('Refreshing MATLAB toolbox cache');
rehash toolboxcache;

display('Saving path');
savepath;
end

function opts = parseInstallOptions(varargin)
parser = inputParser;
parser.FunctionName = 'nSTAT_Install';
addParameter(parser, 'RebuildDocSearch', true, @(x)islogical(x) || isnumeric(x));
addParameter(parser, 'CleanUserPathPrefs', false, @(x)islogical(x) || isnumeric(x));
parse(parser, varargin{:});

opts.RebuildDocSearch = logical(parser.Results.RebuildDocSearch);
opts.CleanUserPathPrefs = logical(parser.Results.CleanUserPathPrefs);
end

function removeExistingRootPaths(rootDir)
pathEntries = strsplit(path, pathsep);
isRepoPath = startsWith(pathEntries, rootDir);
toRemove = unique(pathEntries(isRepoPath));
toRemove = toRemove(cellfun(@(p)~isempty(p) && isfolder(p), toRemove));
if ~isempty(toRemove)
    rmpath(toRemove{:});
end
end

function runtimePaths = collectRuntimePaths(rootDir)
rawPath = strsplit(genpath(rootDir), pathsep);
runtimePaths = {};
for iDir = 1:numel(rawPath)
    dirPath = rawPath{iDir};
    if isempty(dirPath) || ~isfolder(dirPath)
        continue;
    end
    relPath = strrep(dirPath, [rootDir filesep], '');
    if strcmp(dirPath, rootDir)
        runtimePaths{end+1} = dirPath; %#ok<AGROW>
        continue;
    end
    if shouldExcludePath(relPath)
        continue;
    end
    hasMatlabFiles = ~isempty(dir(fullfile(dirPath, '*.m')));
    hasClassFolders = ~isempty(dir(fullfile(dirPath, '@*')));
    hasPackageFolders = ~isempty(dir(fullfile(dirPath, '+*')));
    if hasMatlabFiles || hasClassFolders || hasPackageFolders
        runtimePaths{end+1} = dirPath; %#ok<AGROW>
    end
end
runtimePaths = unique(runtimePaths, 'stable');
end

function tf = shouldExcludePath(relPath)
if isempty(relPath)
    tf = false;
    return;
end
segments = strsplit(relPath, filesep);
segments = segments(~cellfun(@isempty, segments));
if isempty(segments)
    tf = false;
    return;
end

excludedExact = { ...
    '.git', '.github', 'helpfiles', 'python', 'slprj', 'porting', ...
    '__pycache__', '.pytest_cache', '.mypy_cache', '.vscode', '.idea'};
tf = false;
for iSeg = 1:numel(segments)
    seg = segments{iSeg};
    if startsWith(seg, '.')
        tf = true;
        return;
    end
    if any(strcmpi(seg, excludedExact))
        tf = true;
        return;
    end
end
end
