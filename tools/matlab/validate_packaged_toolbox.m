function validate_packaged_toolbox(mltbxPath, varargin)
%VALIDATE_PACKAGED_TOOLBOX Post-package sanity check for a built .mltbx.
%
% Usage:
%   validate_packaged_toolbox(mltbxPath)
%   validate_packaged_toolbox(mltbxPath, 'MaxBytes', 25*1024*1024)
%
% Guards against the v1.6.0 release incident: the first build was ~500 MB
% because packageToolbox followed a symlink into data/ (see also
% assert_no_data_symlinks, the pre-package guard). This is the
% post-package check: even if something upstream changes and the
% pre-package guard doesn't fire, a .mltbx this check would have caught
% must never reach a release.
%
% Checks:
%   1. File size <= MaxBytes.
%   2. No zip entry path contains an absolute user-path marker
%      (fsroot/Users/, fsroot/home/, fsroot/private/) -- ToolboxOptions
%      stores absolute source paths under an "fsroot/" prefix inside the
%      .mltbx archive; one of these surviving into a release means a
%      machine-specific absolute path leaked into the package.
%   3. No zip entry lives under a data/ payload folder (toolboxOptions.m
%      excludes data/ from ToolboxFiles; the figshare paper-example
%      dataset is downloaded post-install, never shipped).
%
% Name-Value Options:
%   MaxBytes (default 25*1024*1024, i.e. 25 MB) -- roughly 2x v1.5.1's
%            13 MB and v1.6.0's 10.2 MB (headroom for organic growth),
%            and more than 20x below the 500 MB v1.6.0 regression this
%            check exists to catch.
%
% Introduced for the v1.6.0 release-gate hardening (package sanity check).

p = inputParser;
p.FunctionName = 'validate_packaged_toolbox';
addParameter(p, 'MaxBytes', 25 * 1024 * 1024, @(x) isnumeric(x) && isscalar(x) && x > 0);
parse(p, varargin{:});
maxBytes = p.Results.MaxBytes;

if exist(mltbxPath, 'file') ~= 2
    error('nstat:package:NotFound', 'Packaged toolbox not found: %s', mltbxPath);
end

info = dir(mltbxPath);
if info.bytes > maxBytes
    error('nstat:package:TooLarge', ...
        ['%s is %.1f MB, which exceeds the %.1f MB sanity bound (v1.5.1 was ', ...
         '13 MB, v1.6.0 10.2 MB; the v1.6.0 500 MB regression was symlinked ', ...
         'data/ being followed into the package).'], ...
        mltbxPath, info.bytes / 1e6, maxBytes / 1e6);
end

entries = listMltbxEntries(mltbxPath);

badAbs = entries(cellfun(@isAbsoluteUserPathEntry, entries));
if ~isempty(badAbs)
    previewCount = min(3, numel(badAbs));
    error('nstat:package:AbsoluteUserPath', ...
        'Packaged toolbox contains %d entr(y/ies) with an absolute user path, e.g.:\n  %s', ...
        numel(badAbs), strjoin(badAbs(1:previewCount), '\n  '));
end

badData = entries(cellfun(@isDataPayloadEntry, entries));
if ~isempty(badData)
    previewCount = min(3, numel(badData));
    error('nstat:package:DataPayload', ...
        'Packaged toolbox contains %d data/ payload entr(y/ies), e.g.:\n  %s', ...
        numel(badData), strjoin(badData(1:previewCount), '\n  '));
end

fprintf('validate_packaged_toolbox: OK (%.1f MB, %d entries, no absolute paths, no data/ payload)\n', ...
    info.bytes / 1e6, numel(entries));
end

function tf = isAbsoluteUserPathEntry(entryName)
tf = contains(entryName, 'fsroot/Users/') || ...
     contains(entryName, 'fsroot/home/') || ...
     contains(entryName, 'fsroot/private/');
end

function tf = isDataPayloadEntry(entryName)
tf = ~isempty(regexp(entryName, '(^|/)data/', 'once'));
end

function entries = listMltbxEntries(mltbxPath)
import java.util.zip.ZipFile
zf = ZipFile(mltbxPath);
cleanupObj = onCleanup(@() zf.close()); %#ok<NASGU>
enumerator = zf.entries();
entries = {};
while enumerator.hasMoreElements()
    entry = enumerator.nextElement();
    entries{end+1} = char(entry.getName()); %#ok<AGROW>
end
end
