function assert_no_data_symlinks(repoRoot)
%ASSERT_NO_DATA_SYMLINKS Refuse to proceed if data/ contains symlinks.
%
% Usage:
%   assert_no_data_symlinks(repoRoot)
%
% The first v1.6.0 .mltbx build was ~500 MB because data/ (or something
% under it) was a symlink and matlab.addons.toolbox.ToolboxOptions's
% constructor -- which recursively walks the whole repo tree to seed
% ToolboxFiles -- followed it. toolboxOptions.m already excludes data/
% from the shipped files list, but that filtering happens AFTER the
% constructor's tree walk, so a symlinked data/ can balloon that walk (and
% thus the build) well before the exclusion ever has a chance to apply.
% Call this BEFORE constructing ToolboxOptions.
%
% Checks both: data/ itself being a symlink, and any symlink nested
% anywhere underneath it. Uses java.nio.file.Files.walk, which (unlike
% MATLAB's dir()) does NOT follow symlinks by default, so this is safe to
% run even if a symlink points somewhere enormous or circular.
%
% Introduced for the v1.6.0 release-gate hardening (package sanity check).

import java.nio.file.Files

dataDir = fullfile(repoRoot, 'data');
if exist(dataDir, 'dir') ~= 7 && exist(dataDir, 'file') ~= 2
    % Nothing at data/ at all (including as a dangling symlink target) --
    % nothing to check.
    return;
end

% java.nio.file.Paths.get(char) is ambiguous against its varargs overload
% through MATLAB's Java bridge; java.io.File(...).toPath() is unambiguous.
dataPath = java.io.File(dataDir).toPath();

if Files.isSymbolicLink(dataPath)
    error('nstat:package:DataIsSymlink', ...
        ['data/ itself is a symlink (%s) -- refusing to package. This is ', ...
         'exactly the v1.6.0 500 MB regression (symlinked data was followed ', ...
         'into the .mltbx). Remove the symlink and use a real data/ ', ...
         'directory (or none) before packaging.'], dataDir);
end

% Manual recursion (not Files.walk -- its varargs FileVisitOption... is
% ambiguous through MATLAB's Java bridge). Never descends into a symlinked
% directory, so this is safe even if a link points somewhere enormous or
% circular; it only ever walks REAL directories under data/.
badLinks = findSymlinks(java.io.File(dataDir));

if ~isempty(badLinks)
    previewCount = min(3, numel(badLinks));
    error('nstat:package:DataContainsSymlinks', ...
        ['data/ contains %d symlink(s) -- refusing to package, e.g.:\n  %s\n', ...
         'Replace with real files/directories (or remove them) before packaging.'], ...
        numel(badLinks), strjoin(badLinks(1:previewCount), '\n  '));
end
end

function badLinks = findSymlinks(javaDir)
import java.nio.file.Files
badLinks = {};
children = javaDir.listFiles();
if isempty(children)
    return;
end
for i = 1:numel(children)
    child = children(i);
    childPath = child.toPath();
    if Files.isSymbolicLink(childPath)
        badLinks{end+1} = char(child.getAbsolutePath()); %#ok<AGROW>
    elseif child.isDirectory()
        badLinks = [badLinks, findSymlinks(child)]; %#ok<AGROW>
    end
end
end
