function results = test_eval_removal()
%TEST_EVAL_REMOVAL  Verify eval-free plot path in SignalObj.
%
%   Exercises all three plot branches (plotPropsIn, plotPropsSet, default)
%   and the parsePlotProps helper to confirm identical behavior after
%   replacing eval-based string construction with direct plot() calls.
%
%   Signature reminder: h = plot(sObj, selectorArray, plotPropsIn, handle)

fprintf('\n=== eval Removal Test (SignalObj.plot) ===\n\n');
results = struct('passed',0,'failed',0,'errors',{{}});

%% ---- Test 1: parsePlotProps logic ----
% parsePlotProps is a file-local function in SignalObj.m, so we test
% the same logic via a local copy here; integration is tested via plot().
fprintf('--- Test 1: parsePlotProps logic ---\n');

% Standard case: color + name-value pair
args = localParsePlotProps(' ''r'', ''LineWidth'' ,3');
results = checkTrue(results, 'parsePlotProps: returns cell', iscell(args));
results = checkTrue(results, 'parsePlotProps: correct length', length(args)==3);
results = checkTrue(results, 'parsePlotProps: color is ''r''', strcmp(args{1},'r'));
results = checkTrue(results, 'parsePlotProps: name is LineWidth', strcmp(args{2},'LineWidth'));
results = checkTrue(results, 'parsePlotProps: value is 3', args{3}==3);

% Simple dot-color string
args2 = localParsePlotProps('''.b''');
results = checkTrue(results, 'parsePlotProps: dot-color', strcmp(args2{1},'.b'));

% Empty string
args3 = localParsePlotProps('');
results = checkTrue(results, 'parsePlotProps: empty returns {}', isempty(args3) && iscell(args3));

%% ---- Test 2: Branch 1 — plot with explicit plotPropsIn ----
fprintf('\n--- Test 2: Plot with plotPropsIn argument (Branch 1) ---\n');
t = (0:0.01:1)';
data = [sin(2*pi*t), cos(2*pi*t)];
sig = SignalObj(t, data, 'TestSig', 'time', 's', 'V', {'sin','cos'});

try
    fig = figure('Visible','off');
    ax = axes(fig);
    % Call plot(sObj, selectorArray, plotPropsIn, handle) — Branch 1
    plotProps = {' ''r'', ''LineWidth'' ,2', ' ''b--'', ''LineWidth'' ,1'};
    sig.plot([], plotProps, ax);

    children = get(ax,'Children');
    results = checkTrue(results, 'Branch1: plot created lines', ~isempty(children));
    results = checkTrue(results, 'Branch1: correct line count', length(children)==2);

    % Last plotted is first child in axes
    line1 = children(end);  % sin — plotted first
    results = checkTrue(results, 'Branch1: line1 color red', ...
        isequal(get(line1,'Color'),[1 0 0]));
    results = checkTrue(results, 'Branch1: line1 LineWidth 2', ...
        get(line1,'LineWidth')==2);

    line2 = children(1);  % cos — plotted second
    results = checkTrue(results, 'Branch1: line2 LineWidth 1', ...
        get(line2,'LineWidth')==1);
    results = checkTrue(results, 'Branch1: line2 dashed', ...
        strcmp(get(line2,'LineStyle'),'--'));

    fprintf('  Branch 1 plot OK\n');
    close(fig);
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('Branch1: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
    if exist('fig','var'), close(fig); end
end

%% ---- Test 3: Branch 2 — plot with pre-set plotProps ----
fprintf('\n--- Test 3: Plot with pre-set plotProps (Branch 2) ---\n');
sig2 = SignalObj(t, data, 'TestSig2', 'time', 's', 'V', {'sin','cos'});
sig2.setPlotProps({' ''g'', ''LineWidth'' ,4'}, 1);
sig2.setPlotProps({' ''m--'''}, 2);

try
    fig2 = figure('Visible','off');
    set(0, 'CurrentFigure', fig2);
    % Call plot(sObj, []) with nargin=2 so Branch 2 triggers via plotPropsSet
    sig2.plot([]);

    ax2 = gca;
    children2 = get(ax2,'Children');
    results = checkTrue(results, 'Branch2: plot created lines', ~isempty(children2));
    results = checkTrue(results, 'Branch2: correct line count', length(children2)==2);

    % Check green solid line (sin, plotted first = last child)
    line1 = children2(end);
    results = checkTrue(results, 'Branch2: line1 color green', ...
        isequal(get(line1,'Color'),[0 1 0]));
    results = checkTrue(results, 'Branch2: line1 LineWidth 4', ...
        get(line1,'LineWidth')==4);

    % Check magenta dashed line (cos, plotted second = first child)
    line2 = children2(1);
    results = checkTrue(results, 'Branch2: line2 color magenta', ...
        isequal(get(line2,'Color'),[1 0 1]));
    results = checkTrue(results, 'Branch2: line2 dashed', ...
        strcmp(get(line2,'LineStyle'),'--'));

    fprintf('  Branch 2 plot OK\n');
    close(fig2);
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('Branch2: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
    if exist('fig2','var'), close(fig2); end
end

%% ---- Test 4: Branch 3 — default plot (no eval, baseline) ----
fprintf('\n--- Test 4: Plot with defaults (Branch 3, no eval) ---\n');
sig3 = SignalObj(t, sin(2*pi*t), 'DefaultSig', 'time', 's', 'V');

try
    fig3 = figure('Visible','off');
    set(0, 'CurrentFigure', fig3);
    sig3.plot([]);

    ax3 = gca;
    children3 = get(ax3,'Children');
    results = checkTrue(results, 'Branch3: default plot created', ~isempty(children3));
    results = checkTrue(results, 'Branch3: single line', length(children3)==1);

    fprintf('  Branch 3 (default) plot OK\n');
    close(fig3);
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('Branch3: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
    if exist('fig3','var'), close(fig3); end
end

%% ---- Test 5: Analysis.m caller pattern (Branch 2) ----
fprintf('\n--- Test 5: Analysis.m caller pattern ---\n');
% Reproduce the exact pattern from Analysis.m line 781
sig4 = SignalObj(t, [data(:,1) data(:,2)], 'ConfBound', 'dt', 's', '', {'upper','lower'});
sig4.setPlotProps({' ''r'', ''LineWidth'' ,3'},1);
sig4.setPlotProps({' ''r'', ''LineWidth'' ,3'},2);

try
    fig4 = figure('Visible','off');
    set(0, 'CurrentFigure', fig4);
    % No explicit plotPropsIn — triggers Branch 2
    sig4.plot([]);

    ax4 = gca;
    children4 = get(ax4,'Children');
    results = checkTrue(results, 'Analysis pattern: created 2 lines', length(children4)==2);

    % Both lines should be red, LineWidth 3
    for k = 1:length(children4)
        results = checkTrue(results, ...
            sprintf('Analysis pattern: line%d red', k), ...
            isequal(get(children4(k),'Color'),[1 0 0]));
        results = checkTrue(results, ...
            sprintf('Analysis pattern: line%d LW=3', k), ...
            get(children4(k),'LineWidth')==3);
    end

    fprintf('  Analysis caller pattern OK\n');
    close(fig4);
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('Analysis pattern: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
    if exist('fig4','var'), close(fig4); end
end

%% ---- Test 6: Subset sArray index mapping (Branch 1) ----
fprintf('\n--- Test 6: Subset sArray index mapping ---\n');
sig5 = SignalObj(t, [data(:,1) data(:,2) t], 'ThreeCol', 'time', 's', 'V', {'a','b','c'});

try
    fig5 = figure('Visible','off');
    ax5 = axes(fig5);
    % Plot only columns 1 and 3, with plotProps — Branch 1
    plotProps5 = {' ''r''', ' ''b--'''};
    sig5.plot([1 3], plotProps5, ax5);

    children5 = get(ax5,'Children');
    results = checkTrue(results, 'Subset sArray: 2 lines from 3-col data', length(children5)==2);

    % Verify the red line (column 1, plotted first = last child)
    results = checkTrue(results, 'Subset sArray: line1 red', ...
        isequal(get(children5(end),'Color'),[1 0 0]));
    % Verify the blue dashed line (column 3, plotted second = first child)
    results = checkTrue(results, 'Subset sArray: line2 blue dashed', ...
        strcmp(get(children5(1),'LineStyle'),'--'));

    fprintf('  Subset sArray index mapping OK\n');
    close(fig5);
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('Subset sArray: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
    if exist('fig5','var'), close(fig5); end
end

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

%% Helper functions
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

function args = localParsePlotProps(plotStr)
%LOCALPARSEPLTPROPS  Local copy of the parsePlotProps logic from SignalObj.m
%   for unit-testing the string→cell conversion in isolation.
    if isempty(plotStr)
        args = {};
    else
        args = eval(['{' plotStr '}']); %#ok<EVLC>
    end
end
