function stamp_release(version, varargin)
%STAMP_RELEASE Stamp Contents.m and the figure manifest for a tagged release.
%
% Syntax:
%   stamp_release('v1.4.0')
%   stamp_release('v1.4.0', 'DryRun', true)
%
% NOTE: despite this help text historically reading `tools.stamp_release`,
% this is a plain function, not a package member -- there is no
% `+tools/` package folder. After `addpath(fullfile(pwd,'tools'))`, call
% it as `stamp_release(...)`, not `tools.stamp_release(...)` (that
% dotted form never resolved). FIX: version consistency hardening.
%
% Description:
%   For a target release `vX.Y.Z`, this function:
%
%     1. Updates Contents.m line 2 (`% Version X.Y dd-Mmm-yyyy`).
%     2. Updates toolboxOptions.m's `ToolboxVersion` to the full `X.Y.Z`.
%        FIX: this did not happen through v1.5.2 -- ToolboxVersion stayed
%        "1.5.1" while Contents.m and RELEASE_NOTES.md moved on, so the
%        shipped .mltbx reported the wrong version.
%     3. Bumps docs/figures/manifest.json `generated_at` field.
%     4. Creates a RELEASE_NOTES.md entry template (idempotent — does
%        nothing if the version's header already exists).
%
%   It does NOT run any tests, does NOT push, and does NOT tag. The
%   caller is expected to have run `tools/predeploy.sh` and reviewed
%   its output before invoking this function.
%
% Inputs:
%   version  - Release version string in form 'vX.Y.Z' (e.g., 'v1.4.0').
%
% Name-Value:
%   'DryRun' - true to print intended changes without writing. Default: false.
%
% See also: tools/predeploy.sh
%
% Introduced for the 2026-05-20 comprehensive codebase audit (Phase D3.2).

parser = inputParser;
parser.FunctionName = 'stamp_release';
addRequired(parser, 'version', @(x) ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'DryRun', false, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
parse(parser, version, varargin{:});
opts = parser.Results;
opts.DryRun = logical(opts.DryRun);
opts.version = char(string(parser.Results.version));

versionPattern = '^v\d+\.\d+\.\d+(-\w+)?$';
if isempty(regexp(opts.version, versionPattern, 'once'))
    error('nstat:stamp_release:InvalidVersion', ...
        'version must match %s; got %s', versionPattern, opts.version);
end

% Strip the leading 'v' for the Contents.m line (which uses bare X.Y form).
bareVersion = opts.version(2:end);
parts = regexp(bareVersion, '\.', 'split');
contentsVersion = sprintf('%s.%s', parts{1}, parts{2});

dateStr = char(datetime('today', 'Format', 'd-MMM-yyyy'));
isoDate = char(datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd''T''HH:mm:ssXXX'));

repoRoot = fileparts(fileparts(mfilename('fullpath')));

% 1) Update Contents.m line 2
contentsPath = fullfile(repoRoot, 'Contents.m');
contentsText = fileread(contentsPath);
newContentsLine = sprintf('%% Version %s %s', contentsVersion, dateStr);
% FIX: MATLAB's regexprep `^` anchors to start-of-STRING by default; the
% `% Version` line is line 2 of Contents.m, not line 1. The `(?m)` inline
% modifier enables multi-line mode so `^` matches start-of-line, which
% is what was intended. Without this the substitution silently no-ops
% and the warning below never fires either (the regex doesn't fail; it
% just doesn't match anything to replace).
contentsNew = regexprep(contentsText, '(?m)^% Version[^\n]*', newContentsLine, 'once');
if strcmp(contentsText, contentsNew)
    warning('nstat:stamp_release:ContentsUnchanged', ...
        'Contents.m line 2 did not match expected pattern; skipped.');
end

% 2) Update toolboxOptions.m's ToolboxVersion (FIX: this was previously
% missing -- ToolboxVersion stayed "1.5.1" through v1.5.2).
toolboxOptionsPath = fullfile(repoRoot, 'toolboxOptions.m');
if exist(toolboxOptionsPath, 'file') == 2
    toolboxOptionsText = fileread(toolboxOptionsPath);
    newToolboxVersionLine = sprintf('opts.ToolboxVersion  = "%s";', bareVersion);
    toolboxOptionsNew = regexprep(toolboxOptionsText, ...
        'opts\.ToolboxVersion\s*=\s*"[^"]*";', newToolboxVersionLine, 'once');
    if strcmp(toolboxOptionsText, toolboxOptionsNew)
        warning('nstat:stamp_release:ToolboxOptionsUnchanged', ...
            'toolboxOptions.m ToolboxVersion assignment did not match expected pattern; skipped.');
    end
else
    toolboxOptionsNew = '';
    warning('nstat:stamp_release:ToolboxOptionsMissing', ...
        'toolboxOptions.m not found at %s; ToolboxVersion not stamped.', toolboxOptionsPath);
end

% 3) Update docs/figures/manifest.json generated_at
manifestPath = fullfile(repoRoot, 'docs', 'figures', 'manifest.json');
if exist(manifestPath, 'file') == 2
    manifestText = fileread(manifestPath);
    manifestNew = regexprep(manifestText, ...
        '"generated_at":\s*"[^"]*"', ...
        sprintf('"generated_at": "%s"', isoDate), 'once');
else
    manifestNew = '';
end

% 4) RELEASE_NOTES.md (create or prepend section)
notesPath = fullfile(repoRoot, 'RELEASE_NOTES.md');
sectionHeader = sprintf('## %s — %s', opts.version, dateStr);
if exist(notesPath, 'file') == 2
    notesText = fileread(notesPath);
    if contains(notesText, sectionHeader)
        % already present; do not duplicate
        notesNew = notesText;
    else
        % prepend a new section after any preamble
        preamble = sprintf('# nSTAT Release Notes\n\n');
        newSection = sprintf('%s\n\n_Fill in highlights:_\n\n- (correctness fixes)\n- (new capabilities)\n- (breaking changes / deprecations)\n\n---\n\n', ...
            sectionHeader);
        if startsWith(notesText, '# nSTAT Release Notes')
            % insert after the preamble
            firstBreak = regexp(notesText, '\n##', 'once');
            if isempty(firstBreak)
                notesNew = [notesText newline newSection];
            else
                notesNew = [notesText(1:firstBreak-1) newline newSection notesText(firstBreak+1:end)];
            end
        else
            notesNew = [preamble newSection notesText];
        end
    end
else
    preamble = sprintf('# nSTAT Release Notes\n\n');
    newSection = sprintf('%s\n\n_Fill in highlights:_\n\n- (correctness fixes)\n- (new capabilities)\n- (breaking changes / deprecations)\n\n', ...
        sectionHeader);
    notesNew = [preamble newSection];
end

% Apply or report
fprintf('stamp_release: target = %s\n', opts.version);
fprintf('  Contents.m line: "%s"\n', newContentsLine);
fprintf('  toolboxOptions.m ToolboxVersion: "%s"\n', bareVersion);
fprintf('  manifest generated_at: "%s"\n', isoDate);
fprintf('  release notes header : "%s"\n', sectionHeader);
if opts.DryRun
    fprintf('\n[DryRun] no files written.\n');
    return;
end

fid = fopen(contentsPath, 'w');
if fid < 0
    error('nstat:stamp_release:WriteFailed', 'cannot open %s for writing', contentsPath);
end
fwrite(fid, contentsNew);
fclose(fid);

if ~isempty(toolboxOptionsNew)
    fid = fopen(toolboxOptionsPath, 'w');
    fwrite(fid, toolboxOptionsNew);
    fclose(fid);
end

if ~isempty(manifestNew)
    fid = fopen(manifestPath, 'w');
    fwrite(fid, manifestNew);
    fclose(fid);
end

fid = fopen(notesPath, 'w');
fwrite(fid, notesNew);
fclose(fid);

fprintf('\nWrote:\n  %s\n', contentsPath);
if ~isempty(toolboxOptionsNew); fprintf('  %s\n', toolboxOptionsPath); end
if ~isempty(manifestNew); fprintf('  %s\n', manifestPath); end
fprintf('  %s\n', notesPath);
fprintf('\nNow review the RELEASE_NOTES.md entry, then:\n');
fprintf('  git add Contents.m toolboxOptions.m docs/figures/manifest.json RELEASE_NOTES.md\n');
fprintf('  git commit -m "release(%s): stamp version + manifest"\n', opts.version);
fprintf('  git tag %s\n', opts.version);
fprintf('  git push origin master --tags\n');
end
