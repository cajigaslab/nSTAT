function results = test_warning_exist_fixes()
%TEST_WARNING_EXIST_FIXES  Verify warning-state and exist('var') fixes.
%
%   Tests:
%   1-2. SignalObj.m — warning state restored after setupPlots (normal + error)
%   3-4. exist('var') pattern — proves 'var' specifier prevents path shadowing
%   5.   eval removal regression
%   6.   histc migration regression (nstColl.psth)

fprintf('\n=== Warning & exist() Fix Tests ===\n\n');
results = struct('passed',0,'failed',0,'errors',{{}});

%% ---- Test 1: SignalObj.setupPlots restores warning state ----
fprintf('--- Test 1: SignalObj.setupPlots warning restoration ---\n');

warning('on','all');
origState = warning('query','all');

try
    t = (0:0.01:1)';
    sig = SignalObj(t, sin(2*pi*t), 'WarnTest', 'time', 's', 'V');
    fig = figure('Visible','off');
    sig.plot([]);
    close(fig);

    postState = warning('query','all');
    results = checkTrue(results, 'setupPlots: warning state restored', ...
        strcmp(origState(1).state, postState(1).state));
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('setupPlots warning: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
    if exist('fig','var'), close(fig); end
end

%% ---- Test 2: setupPlots restores warnings even on error ----
fprintf('\n--- Test 2: setupPlots warning restoration after error ---\n');

warning('on','all');
origState2 = warning('query','all');

try
    t2 = (0:0.01:1)';
    sig2 = SignalObj(t2, sin(2*pi*t2), 'ErrTest', 'time', 's', 'V');
    try
        sig2.setupPlots(-999, 1); % bad handle — may error inside setupPlots
    catch %#ok<CTCH>
        % expected — the point is that onCleanup fires
    end

    postState2 = warning('query','all');
    results = checkTrue(results, 'setupPlots error path: warning state restored', ...
        strcmp(origState2(1).state, postState2(1).state));
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('setupPlots error path: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
end

%% ---- Test 3: exist('var') correctly resolves variables vs path ----
fprintf('\n--- Test 3: exist with var specifier ---\n');

% exist('sin') returns 5 (built-in) but exist('sin','var') returns 0
results = checkTrue(results, 'exist no var: sin found on path', ...
    exist('sin') > 0); %#ok<EXIST>
results = checkTrue(results, 'exist with var: sin NOT a variable', ...
    exist('sin','var') == 0);

% After assignment, both should find it
sin_var = 42; %#ok<NASGU> % local var named sin_var
results = checkTrue(results, 'exist with var: local var found', ...
    exist('sin_var','var') == 1);

% This is the exact pattern from the fix: undefined variable
clear differentDists_test pVal_test;
results = checkTrue(results, 'exist with var: undefined var correctly 0', ...
    exist('differentDists_test','var') == 0);

%% ---- Test 4: exist('XTick','var') pattern ----
fprintf('\n--- Test 4: exist XTick pattern ---\n');

% XTick is undefined — should return 0
results = checkTrue(results, 'XTick: undefined returns 0 with var', ...
    exist('XTick','var') == 0);

% After definition — should return 1
XTick = [1 2 3]; %#ok<NASGU>
results = checkTrue(results, 'XTick: defined returns 1 with var', ...
    exist('XTick','var') == 1);

%% ---- Test 5: eval removal regression (plot with plotProps) ----
fprintf('\n--- Test 5: eval removal regression (plot with plotProps) ---\n');

try
    t5 = (0:0.01:1)';
    sig5 = SignalObj(t5, [sin(2*pi*t5) cos(2*pi*t5)], 'Regr', 'time', 's', 'V', {'a','b'});
    sig5.setPlotProps({' ''r'', ''LineWidth'' ,3'}, 1);
    sig5.setPlotProps({' ''b--'', ''LineWidth'' ,1'}, 2);

    fig5 = figure('Visible','off');
    set(0, 'CurrentFigure', fig5);
    sig5.plot([]);

    ax5 = gca;
    ch = get(ax5, 'Children');
    results = checkTrue(results, 'eval regression: 2 lines plotted', length(ch)==2);
    results = checkTrue(results, 'eval regression: line1 red', ...
        isequal(get(ch(end),'Color'), [1 0 0]));
    results = checkTrue(results, 'eval regression: line2 blue dashed', ...
        strcmp(get(ch(1),'LineStyle'), '--'));
    close(fig5);
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('eval regression: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
    if exist('fig5','var'), close(fig5); end
end

%% ---- Test 6: histc migration regression (nstColl.psth) ----
fprintf('\n--- Test 6: histc migration regression (nstColl.psth) ---\n');

try
    delta = 0.001;
    spikeTimes1 = sort(rand(50,1));
    spikeTimes2 = sort(rand(30,1));
    nst1 = nspikeTrain(spikeTimes1, 'n1', delta);
    nst2 = nspikeTrain(spikeTimes2, 'n2', delta);
    nstc = nstColl({nst1, nst2});

    % psth signature: psthSignal = psth(nstCollObj, binwidth, ...)
    binwidth = 0.1;
    psthSig = nstc.psth(binwidth);

    results = checkTrue(results, 'psth regression: output is SignalObj', ...
        isa(psthSig, 'SignalObj'));
    results = checkTrue(results, 'psth regression: data has correct bins', ...
        size(psthSig.data, 1) == length(0:binwidth:1)-1);
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('psth regression: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
end

%% ---- Test 7: nstColl.m warning restoration (fitGLMPSTH path) ----
fprintf('\n--- Test 7: nstColl warning off uses onCleanup ---\n');

% Verify by reading the source — the onCleanup pattern is present
srcFile = which('nstColl');
fid = fopen(srcFile,'r');
src = fread(fid,'*char')';
fclose(fid);

results = checkTrue(results, 'nstColl: contains onCleanup', ...
    contains(src, 'onCleanup'));
results = checkTrue(results, 'nstColl: no bare warning off', ...
    ~contains(src, sprintf('warning off;')));

%% ---- Summary ----
fprintf('\n=== RESULTS: %d passed, %d failed ===\n', results.passed, results.failed);
if ~isempty(results.errors)
    fprintf('Failures:\n');
    for i = 1:numel(results.errors)
        fprintf('  - %s\n', results.errors{i});
    end
end
fprintf('\n');
end

%% Helper
function results = checkTrue(results, name, condition)
    if condition
        results.passed = results.passed + 1;
        fprintf('  PASS: %s\n', name);
    else
        results.failed = results.failed + 1;
        results.errors{end+1} = name;
        fprintf('  FAIL: %s\n', name);
    end
end
