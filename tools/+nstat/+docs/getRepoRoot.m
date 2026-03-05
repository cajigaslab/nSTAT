function repoRoot = getRepoRoot()
%GETREPOROOT Resolve absolute path to the nSTAT repository root.
%
% Syntax:
%   repoRoot = nstat.docs.getRepoRoot()
%
% Output:
%   repoRoot - Absolute path to the repository root folder.
%
% Notes:
%   The resolver checks `nSTAT_Install.m` first, then falls back to
%   package-relative lookup from this utility's location.

installPath = which('nSTAT_Install');
if ~isempty(installPath)
    repoRoot = fileparts(installPath);
    return;
end

thisFile = mfilename('fullpath');
repoRoot = fileparts(fileparts(fileparts(fileparts(thisFile))));
end
