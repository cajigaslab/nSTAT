function report = check_helpfile_drift(varargin)
%CHECK_HELPFILE_DRIFT Pixel-diff two helpfile directories.
%
% Usage:
%   % Default: compare current helpfiles/ against HEAD's committed PNGs
%   % via a temp checkout. Both ends rendered under whatever MATLAB you have.
%   tools.check_helpfile_drift
%
%   % Compare current helpfiles/ against a known good directory
%   % (e.g., a checkout of an earlier commit you've already published into).
%   tools.check_helpfile_drift('Other', '/path/to/older/helpfiles')
%
% When `Other` is supplied, the two directories should have been
% generated under the same MATLAB version -- otherwise the comparison is
% dominated by rendering-environment noise (DIM_DIFF verdicts) instead of
% real source-side drift. See the PR #109 investigation for context: the
% 2017 source under R2026a comparison was created exactly this way after
% the naive 2017-committed-PNGs comparison turned out to be unusable.
%
% Verdict classes (mirrors tools/check_readme_figures.m):
%   IDENTICAL    byte-equal
%   TINY         mean abs delta < TinyThreshold (default 0.5)
%   SUBSTANTIVE  mean abs delta >= TinyThreshold
%   DIM_DIFF     pixel dimensions differ (rendering env mismatch)
%   ONLY_NOW     in helpDir but not Other (new since baseline)
%   ONLY_OTHER   in Other but not helpDir (lost relative to baseline)
%   READ_ERROR   imread failed
%
% Output: per-PNG struct array with name/kind/mad/sizes/helpfile.
%
% Introduced after PR #109 to make the "current vs older-source"
% comparison reproducible without recreating the harness in /tmp.

p = inputParser;
p.FunctionName = 'tools.check_helpfile_drift';
addParameter(p, 'HelpDir', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'Other', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'TinyThreshold', 0.5, @(x) isnumeric(x) && isscalar(x) && x >= 0);
parse(p, varargin{:});
opts = p.Results;

repoRoot = fileparts(fileparts(mfilename('fullpath')));
if isempty(opts.HelpDir)
    helpDir = fullfile(repoRoot, 'helpfiles');
else
    helpDir = char(string(opts.HelpDir));
end
if isempty(opts.Other)
    % Default: stage HEAD-committed helpfiles to a temp directory for comparison.
    fprintf('Other not supplied; staging HEAD helpfiles to a temp directory...\n');
    otherDir = stageHeadHelpfiles(repoRoot);
    cleanupOther = onCleanup(@() tryRmdir(otherDir)); %#ok<NASGU>
else
    otherDir = char(string(opts.Other));
end

nowSet = listPngsAsMap(helpDir);
oldSet = listPngsAsMap(otherDir);
allNames = unique([keys(nowSet), keys(oldSet)]);
fprintf('Comparing %d unique PNG names (helpDir=%s, other=%s)...\n', ...
    numel(allNames), helpDir, otherDir);

rows = struct('name',{},'kind',{},'mad',{},'now_bytes',{},'other_bytes',{},'helpfile',{});
for k = 1:numel(allNames)
    nm = allNames{k};
    inNow = nowSet.isKey(nm);
    inOld = oldSet.isKey(nm);
    helpfilePrefix = regexprep(nm, '_\d+\.png$|\.png$', '');
    if inOld && ~inNow
        rows(end+1,1) = struct('name',nm,'kind','ONLY_OTHER','mad',NaN, ...
            'now_bytes',0,'other_bytes',oldSet(nm).bytes,'helpfile',helpfilePrefix); %#ok<AGROW>
    elseif inNow && ~inOld
        rows(end+1,1) = struct('name',nm,'kind','ONLY_NOW','mad',NaN, ...
            'now_bytes',nowSet(nm).bytes,'other_bytes',0,'helpfile',helpfilePrefix); %#ok<AGROW>
    else
        nowP = fullfile(helpDir, nm);
        oldP = fullfile(otherDir, nm);
        try; a = imread(nowP); catch; a = []; end
        try; b = imread(oldP); catch; b = []; end
        if isempty(a) || isempty(b)
            kind = 'READ_ERROR'; mad = NaN;
        elseif ~isequal(size(a), size(b))
            kind = 'DIM_DIFF'; mad = NaN;
        else
            mad = mean(abs(double(a(:)) - double(b(:))));
            if mad == 0
                kind = 'IDENTICAL';
            elseif mad < opts.TinyThreshold
                kind = 'TINY';
            else
                kind = 'SUBSTANTIVE';
            end
        end
        rows(end+1,1) = struct('name',nm,'kind',kind,'mad',mad, ...
            'now_bytes',nowSet(nm).bytes,'other_bytes',oldSet(nm).bytes,'helpfile',helpfilePrefix); %#ok<AGROW>
    end
end

% Tally
kinds = {rows.kind};
fprintf('\n=== Verdict tally ===\n');
uk = unique(kinds);
for k = 1:numel(uk)
    fprintf('  %-15s %4d\n', uk{k}, sum(strcmp(kinds, uk{k})));
end

% SUBSTANTIVE detail
subIdx = find(strcmp(kinds, 'SUBSTANTIVE'));
if ~isempty(subIdx)
    fprintf('\n=== SUBSTANTIVE drifts (mean abs delta >= %.2f) ===\n', opts.TinyThreshold);
    [~, sortIdx] = sort([rows(subIdx).mad], 'descend');
    for k = sortIdx
        r = rows(subIdx(k));
        fprintf('  %-50s mad=%6.2f  now=%d  other=%d\n', ...
            r.name, r.mad, r.now_bytes, r.other_bytes);
    end
end

% ONLY_OTHER: regressions
onlyOldIdx = find(strcmp(kinds, 'ONLY_OTHER'));
if ~isempty(onlyOldIdx)
    fprintf('\n=== ONLY_OTHER (figure present in baseline but not now) ===\n');
    for k = onlyOldIdx'
        fprintf('  %s (was %d B)\n', rows(k).name, rows(k).other_bytes);
    end
end

% Per-helpfile rollup
helpfiles = unique({rows.helpfile});
fprintf('\n=== Per-helpfile rollup (showing rows with non-zero SUBST / NEW / LOST) ===\n');
fprintf('  %-40s %-6s %-6s %-6s %-6s %-6s\n', 'helpfile', 'IDENT', 'TINY', 'SUBST', 'NEW', 'LOST');
for h = 1:numel(helpfiles)
    hf = helpfiles{h};
    hRows = rows(strcmp({rows.helpfile}, hf));
    c = countKinds(hRows);
    if c.sub > 0 || c.lost > 0 || c.new > 0
        fprintf('  %-40s %-6d %-6d %-6d %-6d %-6d\n', hf, c.ident, c.tiny, c.sub, c.new, c.lost);
    end
end

report = rows;
end

function c = countKinds(hRows)
kinds = {hRows.kind};
c.ident = sum(strcmp(kinds, 'IDENTICAL'));
c.tiny  = sum(strcmp(kinds, 'TINY'));
c.sub   = sum(strcmp(kinds, 'SUBSTANTIVE'));
c.new   = sum(strcmp(kinds, 'ONLY_NOW'));
c.lost  = sum(strcmp(kinds, 'ONLY_OTHER'));
end

function m = listPngsAsMap(d)
m = containers.Map('KeyType','char','ValueType','any');
if ~isfolder(d); return; end
pngs = dir(fullfile(d, '*.png'));
for k = 1:numel(pngs)
    m(pngs(k).name) = pngs(k);
end
end

function dst = stageHeadHelpfiles(repoRoot)
dst = tempname;
mkdir(dst);
[stat, list] = system(sprintf('cd %s && git ls-tree -r --name-only HEAD helpfiles/ | grep -E "\\.png$"', repoRoot));
if stat ~= 0
    error('check_helpfile_drift:GitListFailed', 'git ls-tree failed for %s', repoRoot);
end
files = strsplit(strtrim(list), newline);
for k = 1:numel(files)
    if isempty(files{k}); continue; end
    [~, name, ext] = fileparts(files{k});
    src = fullfile(repoRoot, files{k});
    if isfile(src)
        copyfile(src, fullfile(dst, [name ext]));
    end
end
end

function tryRmdir(d)
if isfolder(d)
    try; rmdir(d, 's'); catch; end
end
end
