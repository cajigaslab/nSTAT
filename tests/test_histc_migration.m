function results = test_histc_migration()
%TEST_HISTC_MIGRATION  Verify histc -> histcounts migration in nstColl.
%
%   Compares the old histc-based binning logic against the new histcounts
%   logic to confirm identical spike counts and correct dimensions.
%   Also exercises nstColl.getPSTH (first variant) end-to-end.

fprintf('\n=== histc -> histcounts Migration Test ===\n\n');
results = struct('passed',0,'failed',0,'errors',{{}});

%% Load GLM test data
rootDir = fileparts(fileparts(mfilename('fullpath')));
glmDataPath = fullfile(rootDir, 'data', 'glm_data.mat');
assert(isfile(glmDataPath), 'Cannot find glm_data.mat at %s', glmDataPath);

d = load(glmDataPath);
spiketimes = d.spiketimes;
fprintf('Loaded %d spike times from glm_data.mat\n', numel(spiketimes));

%% Build nstColl from GLM data
nst = nspikeTrain(spiketimes);
spikeColl = nstColl({nst});
minTime = spikeColl.minTime;
maxTime = spikeColl.maxTime;
binwidth = 0.100; % 100 ms

fprintf('Time range: [%.4f, %.4f], binwidth=%.3f s\n\n', minTime, maxTime, binwidth);

%% ---- Test 1: Raw binning equivalence (psthBars path) ----
fprintf('--- Test 1: psthBars binning logic ---\n');
edges = minTime:binwidth:maxTime;

% OLD: histc-based (original code, no trim variant)
psthOld = zeros(1, length(edges));
st = nst.getSpikeTimes;
if ~isempty(st)
    psthOld = psthOld + histc(st, edges); %#ok<HISTC>
end

% NEW: histcounts-based
psthNew = zeros(1, length(edges)-1);
if ~isempty(st)
    psthNew = psthNew + histcounts(st, edges);
end

% The old code had length(edges) elements; new has length(edges)-1.
% histc's last element counted spikes == last edge.
% histcounts folds those into the last bin automatically.
% So: psthOld(1:end-1) should match psthNew, plus any spikes exactly
%     at the last edge should appear in psthNew(end).
lastEdgeCount = psthOld(end);  % histc's trailing element
psthOldTrimmed = psthOld(1:end-1);
psthOldTrimmed(end) = psthOldTrimmed(end) + lastEdgeCount;

results = checkEqual(results, 'psthBars: bin counts match', psthOldTrimmed, psthNew);
results = checkEqual(results, 'psthBars: total spike count preserved', sum(psthOld), sum(psthNew));

% Dimension checks
timeNew = (edges(1:end-1) + edges(2:end)) / 2;
results = checkTrue(results, 'psthBars: time length matches psthData', ...
    length(timeNew) == length(psthNew));
fprintf('  Old psthData size: [%s], New psthData size: [%s], time size: [%s]\n', ...
    num2str(size(psthOld)), num2str(size(psthNew)), num2str(size(timeNew)));

%% ---- Test 2: getPSTH (first variant) end-to-end ----
fprintf('\n--- Test 2: getPSTH end-to-end ---\n');
try
    psthSignal = spikeColl.psth(binwidth);
    fprintf('  getPSTH returned SignalObj with %d time points, %d data columns\n', ...
        length(psthSignal.time), size(psthSignal.data, 2));

    % Verify dimensions are consistent
    results = checkTrue(results, 'psth: time and data same length', ...
        length(psthSignal.time) == size(psthSignal.data, 1));

    % Verify non-negative firing rates
    results = checkTrue(results, 'psth: firing rates non-negative', ...
        all(psthSignal.data >= 0));

    % Verify time is within expected range
    results = checkTrue(results, 'psth: time within [minTime, maxTime]', ...
        psthSignal.time(1) >= minTime && psthSignal.time(end) <= maxTime);

    % Cross-check: manually compute with histcounts and compare
    wt = minTime:binwidth:maxTime;
    if ~any(wt == maxTime)
        wt = [wt, maxTime];
    end
    manualCounts = histcounts(st, wt);
    manualRate = manualCounts ./ binwidth ./ 1;  % 1 neuron
    manualTime = (wt(2:end) + wt(1:end-1)) / 2;

    results = checkEqual(results, 'psth: manual rate matches method output', ...
        manualRate(:), psthSignal.data(:));
    results = checkEqual(results, 'psth: manual time matches method output', ...
        manualTime(:), psthSignal.time(:));

catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('psth: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
end

%% ---- Test 3: Edge case — empty spike train ----
fprintf('\n--- Test 3: Empty spike train ---\n');
emptyNST = nspikeTrain([]);
emptyColl = nstColl({emptyNST});
try
    psthEmpty = emptyColl.psth(binwidth);
    results = checkTrue(results, 'Empty spikes: returns valid SignalObj', ...
        isa(psthEmpty, 'SignalObj'));
    results = checkTrue(results, 'Empty spikes: all zeros', ...
        all(psthEmpty.data == 0));
    fprintf('  Empty spike train handled correctly\n');
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('Empty spikes: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
end

%% ---- Test 4: Multiple spike trains ----
fprintf('\n--- Test 4: Multi-neuron collection ---\n');
% Create 3 spike trains with known spike times
st1 = [0.1, 0.25, 0.5, 0.75];
st2 = [0.2, 0.3, 0.6];
st3 = [0.15, 0.45, 0.9];
multiColl = nstColl({nspikeTrain(st1), nspikeTrain(st2), nspikeTrain(st3)});
bw = 0.25;
try
    psthMulti = multiColl.psth(bw);

    % Manual calculation
    allSpikes = {st1, st2, st3};
    mEdges = multiColl.minTime:bw:multiColl.maxTime;
    if ~any(mEdges == multiColl.maxTime)
        mEdges = [mEdges, multiColl.maxTime];
    end
    mPsth = zeros(1, length(mEdges)-1);
    for k = 1:3
        mPsth = mPsth + histcounts(allSpikes{k}, mEdges);
    end
    mPsth = mPsth ./ bw ./ 3;  % normalize
    mTime = (mEdges(2:end) + mEdges(1:end-1)) / 2;

    results = checkEqual(results, 'Multi-neuron: rates match manual', ...
        mPsth(:), psthMulti.data(:));
    results = checkEqual(results, 'Multi-neuron: times match manual', ...
        mTime(:), psthMulti.time(:));
    fprintf('  Multi-neuron PSTH: %d bins, mean rate=%.2f Hz\n', ...
        length(mPsth), mean(mPsth));
catch ME
    results.failed = results.failed + 1;
    results.errors{end+1} = sprintf('Multi-neuron: %s', ME.message);
    fprintf('  FAIL: %s\n', ME.message);
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
function results = checkEqual(results, name, expected, actual)
    tol = 1e-10;
    if isequal(size(expected), size(actual)) && all(abs(expected(:) - actual(:)) < tol)
        results.passed = results.passed + 1;
        fprintf('  PASS: %s\n', name);
    else
        results.failed = results.failed + 1;
        results.errors{end+1} = name;
        if ~isequal(size(expected), size(actual))
            fprintf('  FAIL: %s (size mismatch: expected [%s], got [%s])\n', ...
                name, num2str(size(expected)), num2str(size(actual)));
        else
            maxDiff = max(abs(expected(:) - actual(:)));
            fprintf('  FAIL: %s (max diff = %g)\n', name, maxDiff);
        end
    end
end

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
