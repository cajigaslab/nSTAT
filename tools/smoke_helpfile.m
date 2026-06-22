function smoke_helpfile(helpfileName, varargin)
%SMOKE_HELPFILE Publish one helpfile in an isolated sandbox and report.
%
% Usage:
%   tools.smoke_helpfile('DecodingExample')
%   tools.smoke_helpfile('HybridFilterExample', 'CompareToHead', false)
%
% Stages the named helpfile's .m (plus its siblings, minus any .mlx that
% would shadow it) into a temp directory, runs `publish` with EvalCode=true,
% and reports:
%   - publish OK / FAIL with stack on error
%   - count of figure PNGs produced (numeric-suffix Foo_NN.png only;
%     LaTeX-equation snapshots Foo_eq<hex>.png excluded)
%   - per-PNG size with SUSPECT-BLANK flag for any < BlankThreshold bytes
%   - delta vs HEAD-committed figure count (optional, default on)
%
% Designed to surface the same class of regressions that
% publish_all_helpfiles' built-in validateNoBlankFigures catches, but for
% one helpfile at a time so you can iterate quickly on a single .m without
% paying the ~19-minute cost of the full predeploy publish gate.
%
% See also: publish_all_helpfiles, tools.check_helpfile_drift
%
% Introduced after the PR #105 / #106 / #109 chain made clear that
% one-at-a-time publish smoke testing is essential before any helpfile
% edit ships.

p = inputParser;
p.FunctionName = 'tools.smoke_helpfile';
addRequired(p, 'helpfileName', @(x) ischar(x) || (isstring(x) && isscalar(x)));
addParameter(p, 'CompareToHead', true, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(p, 'BlankThreshold', 5000, @(x) isnumeric(x) && isscalar(x) && x >= 0);
parse(p, helpfileName, varargin{:});
opts = p.Results;
helpfileName = char(string(opts.helpfileName));

repoRoot = fileparts(fileparts(mfilename('fullpath')));
helpDir = fullfile(repoRoot, 'helpfiles');
mPath   = fullfile(helpDir, [helpfileName '.m']);
if ~isfile(mPath)
    fprintf('ERROR: helpfile .m not found: %s\n', mPath);
    return
end

stagingDir = tempname; mkdir(stagingDir);
outputDir  = tempname; mkdir(outputDir);
cleanup = onCleanup(@() tryRmdirs(stagingDir, outputDir)); %#ok<NASGU>

copyfile(fullfile(helpDir, '*'), stagingDir);
mlxFiles = dir(fullfile(stagingDir, '*.mlx'));
for i=1:numel(mlxFiles)
    delete(fullfile(mlxFiles(i).folder, mlxFiles(i).name));
end

startDir = pwd;
restoreDir = onCleanup(@() cd(startDir)); %#ok<NASGU>
addpath(stagingDir, '-begin');
cd(stagingDir);

priorVisibility = get(groot, 'defaultFigureVisible');
set(groot, 'defaultFigureVisible', 'on');
restoreVisibility = onCleanup(@() set(groot, 'defaultFigureVisible', priorVisibility)); %#ok<NASGU>

rng(0, 'twister');
pubOpts = struct('outputDir', outputDir, 'format', 'html', 'evalCode', true);
fprintf('\n=== smoke: %s ===\n', helpfileName);
tStart = tic;
publishOK = false;
try
    publish(helpfileName, pubOpts);
    publishOK = true;
    fprintf('  publish OK (%.1fs)\n', toc(tStart));
catch ME
    fprintf('  publish FAIL (%.1fs): %s\n', toc(tStart), ME.message);
    for i=1:min(4, numel(ME.stack))
        fprintf('    [%d] %s line %d\n', i, ME.stack(i).name, ME.stack(i).line);
    end
end
if ~publishOK; return; end

pngs = dir(fullfile(outputDir, [helpfileName '_*.png']));
realCount = 0;
eqCount = 0;
rows = {};
for k = 1:numel(pngs)
    nm = pngs(k).name;
    [~, base] = fileparts(nm);
    if ~isempty(regexp(base, '_\d+$', 'once'))
        realCount = realCount + 1;
        flag = '';
        if pngs(k).bytes < opts.BlankThreshold
            flag = sprintf(' SUSPECT-BLANK (< %d B)', opts.BlankThreshold);
        end
        rows{end+1} = sprintf('  %s: %d B%s', nm, pngs(k).bytes, flag); %#ok<AGROW>
    elseif contains(base, '_eq')
        eqCount = eqCount + 1;
    end
end
fprintf('  produced %d figure PNGs (+ %d equation PNGs)\n', realCount, eqCount);
for k = 1:numel(rows)
    fprintf('%s\n', rows{k});
end

if opts.CompareToHead
    [stat, gitList] = system(sprintf( ...
        'cd %s && git ls-tree -r --name-only HEAD helpfiles/ | grep -E "^helpfiles/%s_[0-9]{2}\\.png$" | sort', ...
        startDir, helpfileName));
    if stat == 0
        headFiles = strsplit(strtrim(gitList), newline);
        if ~isempty(headFiles{1})
            fprintf('  HEAD baseline: %d  |  Now: %d  |  delta: %+d\n', ...
                numel(headFiles), realCount, realCount - numel(headFiles));
        end
    end
end
end

function tryRmdirs(varargin)
for i = 1:nargin
    d = varargin{i};
    if isfolder(d)
        try
            rmdir(d, 's');
        catch
            % best-effort cleanup
        end
    end
end
end
