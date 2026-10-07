function packageToolbox(~)
%PACKAGETOOLBOX Build the .mltbx package for nSTAT.
%
% Reads configuration from toolboxOptions.m and invokes
% matlab.addons.toolbox.packageToolbox to produce a .mltbx file under
% release/.
%
% Invoked from:
%   - 'buildtool package' (the canonical entry point)
%   - 'buildtool predeploy' (as part of the full release gate)
%   - directly:  packageToolbox()
%
% After packaging, the .mltbx is INSTALLABLE via double-click in the
% MATLAB Desktop, which routes through the Add-On Manager.

repoRoot = fileparts(mfilename("fullpath"));
addpath(fullfile(repoRoot, "tools", "matlab"), "-end");

% FIX: refuse BEFORE ToolboxOptions's constructor walks the tree (it
% recursively scans repoRoot to seed ToolboxFiles, and dir()-based walks
% follow symlinks). This is the mechanism that made the first v1.6.0
% .mltbx build ~500 MB -- a symlink under data/ was followed.
assert_no_data_symlinks(repoRoot);

opts = toolboxOptions();
matlab.addons.toolbox.packageToolbox(opts);

% Report what we produced.
[~, name, ext] = fileparts(opts.OutputFile);
info = dir(opts.OutputFile);
if isempty(info)
    error("nstat:package:NotProduced", ...
        "Expected output file not found: %s", opts.OutputFile);
end
fprintf("\n=== Packaged ===\n");
fprintf("  File   : %s%s\n", name, ext);
fprintf("  Path   : %s\n", info.folder);
fprintf("  Size   : %.1f KB\n", info.bytes / 1024);
fprintf("  Version: %s\n", opts.ToolboxVersion);
fprintf("\n");

% FIX: post-package sanity check -- size bound, no absolute user paths,
% no data/ payload. A second line of defense alongside the pre-package
% symlink refusal above, in case the .mltbx grows some other way.
validate_packaged_toolbox(opts.OutputFile);

fprintf("Install via double-click in the MATLAB Desktop, or programmatically:\n");
fprintf("  matlab.addons.toolbox.installToolbox('%s')\n\n", opts.OutputFile);
end
