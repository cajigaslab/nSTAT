function removedEntries = cleanup_user_path_prefs(rootDir)
% cleanup_user_path_prefs Remove stale nSTAT path entries from MATLAB path.
%
% Usage:
%   cleanup_user_path_prefs
%   cleanup_user_path_prefs(rootDir)
%   removedEntries = cleanup_user_path_prefs(...)
%
% This utility removes stale path entries under the current nSTAT repository.
% It targets deleted Python-port maintenance trees and missing repo-local
% folders that can trigger startup warnings such as:
%   "Name is nonexistent or not a directory: .../tools/matlab"

if nargin < 1 || isempty(rootDir)
    installPath = which('nSTAT_Install');
    if isempty(installPath)
        error('nSTAT:InstallPathNotFound', ...
            'Could not resolve rootDir; provide rootDir explicitly.');
    end
    rootDir = fileparts(installPath);
end

pathEntries = strsplit(path, pathsep);
if isempty(pathEntries)
    removedEntries = {};
    return;
end

staleRoots = {
    fullfile(rootDir, 'python', 'matlab_port')
    fullfile(rootDir, 'python', 'notebooks')
    fullfile(rootDir, 'python', 'reports')
    fullfile(rootDir, 'python', 'tools')
};

toRemoveMask = false(size(pathEntries));
for iEntry = 1:numel(pathEntries)
    entry = pathEntries{iEntry};
    if isempty(entry)
        continue;
    end
    for iRoot = 1:numel(staleRoots)
        if startsWith(entry, staleRoots{iRoot})
            toRemoveMask(iEntry) = true;
            break;
        end
    end
    if startsWith(entry, fullfile(rootDir, 'python')) && contains(entry, '__pycache__')
        toRemoveMask(iEntry) = true;
    end
    if startsWith(entry, rootDir) && ~isfolder(entry)
        toRemoveMask(iEntry) = true;
    end
end

removedEntries = unique(pathEntries(toRemoveMask), 'stable');
removedEntries = removedEntries(cellfun(@(p)~isempty(p), removedEntries));

if ~isempty(removedEntries)
    keepMask = true(size(pathEntries));
    for i = 1:numel(pathEntries)
        if any(strcmp(pathEntries{i}, removedEntries))
            keepMask(i) = false;
        end
    end
    filteredPath = strjoin(pathEntries(keepMask), pathsep);
    path(filteredPath);
    savepath;
    fprintf('Removed %d stale MATLAB path entries.\n', numel(removedEntries));
else
    fprintf('No stale MATLAB path entries found for cleanup.\n');
end
end
