function result = example05_decoding_ppaf_pphf(varargin)
%EXAMPLE05_DECODING_PPAF_PPHF Stimulus decoding with adaptive and hybrid point-process filters.
%
% What this example demonstrates:
%   1) Univariate stimulus decoding from a neural population (PPAF).
%   2) Goal-directed and free-movement reach decoding with point-process
%      adaptive filters (PPAF with/without goal state information).
%   3) Hybrid discrete/continuous movement-state decoding (PPHF).
%
% Inputs/data provenance:
%   - Simulated data generated deterministically from paper model structure.
%   - Bundled hybrid-filter trajectory fixture:
%     helpfiles/paperHybridFilterExample.mat
%
% Expected outputs:
%   - Figure 1: Univariate decoding setup (stimulus, CIFs, raster).
%   - Figure 2: Decoded univariate stimulus with 95%% CIs.
%   - Figure 3: Arm reach simulation with neural population summary.
%   - Figure 4: PPAF/PPAF+Goal decoding summary over repeated simulations.
%   - Figure 5: Hybrid-filter state/path setup with simulated neural firing.
%   - Figure 6: Hybrid-filter decoding summary across repeated simulations.
%
% How it maps to the paper:
%   Paper Sections 2.3.6-2.3.7 (decoding), aligned to Figs. 8, 9, 14, and
%   the hybrid-filter extension shown in the canonical nSTAT example file.
%
% Syntax:
%   result = example05_decoding_ppaf_pphf
%   result = example05_decoding_ppaf_pphf('ExportFigures',true,...)

opts = parseOptions(varargin{:});

rng(opts.Seed, 'twister');
originalFigureVisibility = get(groot, 'defaultFigureVisible');
set(groot, 'defaultFigureVisible', opts.Visible);
restoreVisibility = onCleanup(@() set(groot, 'defaultFigureVisible', originalFigureVisibility)); %#ok<NASGU>

[dataDir, ~, ~, ~, ~] = getPaperDataDirs();
repoRoot = fileparts(dataDir);
originalDir = pwd;
if exist(repoRoot, 'dir') == 7 && ~strcmp(originalDir, repoRoot)
    cd(repoRoot);
end
restoreDir = onCleanup(@() cd(originalDir)); %#ok<NASGU>

close all;
figureFiles = {};

%% Example 5: Univariate stimulus decoding

delta = 0.001;
tmax = 1;
time = 0:delta:tmax;
numRealizations = 20;
f = 2;
b1 = randn(numRealizations, 1);
b0 = log(10 * delta) + randn(numRealizations, 1);
stimSignal = sin(2 * pi * f * time);

clear nst lambda;
for iCell = 1:numRealizations
    expData = exp(b1(iCell) * stimSignal + b0(iCell));
    lambdaData = expData ./ (1 + expData);
    tempLambda = Covariate(time, lambdaData ./ delta, '\Lambda(t)', 'time', 's', 'spikes/sec', ...
        {'\lambda_{1}'}, {{' ''b'', ''LineWidth'' ,2'}});
    if iCell == 1
        lambda = tempLambda;
    else
        lambda = lambda.merge(tempLambda);
    end
    tempSpikeColl = CIF.simulateCIFByThinningFromLambda(lambda.getSubSignal(iCell), 1);
    nst{iCell} = tempSpikeColl.getNST(1); %#ok<AGROW>
end
spikeColl = nstColl(nst);

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(3,1,1);
plot(time, stimSignal, 'k');
set(gca, 'XTickLabel', []);
ylabel('Stimulus');
title('Driving Stimulus', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

subplot(3,1,2);
lambda.plot([], {{' ''k'', ''Linewidth'',1'}});
legend off;
ylabel('Firing Rate [spikes/sec]', 'Interpreter', 'none');
set(gca, 'XTickLabel', []);
title('Conditional Intensity Functions', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

subplot(3,1,3);
spikeColl.plot;
set(gca, 'YTick', 0:10:numRealizations, 'YTickLabel', 0:10:numRealizations);
xlabel('time [s]', 'Interpreter', 'none');
ylabel('Cell Number', 'Interpreter', 'none');
title('Point Process Sample Paths', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig01_univariate_setup');

stim = Covariate(time, stimSignal, 'Stimulus', 'time', 's', 'V', {'stim'});

spikeColl.resample(1 / delta);
dN = spikeColl.dataToMatrix;
Q = std(stim.data(2:end) - stim.data(1:end-1));
A = 1;

[~, ~, x_u, W_u] = DecodingAlgorithms.PPDecodeFilterLinear(A, Q, dN', b0, b1', 'binomial', delta);

zVal = 1.96;
ciLower = min(x_u(1:end) - zVal * sqrt(squeeze(W_u(1:end)))', x_u(1:end) + zVal * sqrt(squeeze(W_u(1:end))'));
ciUpper = max(x_u(1:end) - zVal * sqrt(squeeze(W_u(1:end)))', x_u(1:end) + zVal * sqrt(squeeze(W_u(1:end))'));

estimatedStimulus = Covariate(time, x_u(1:end), '\hat{x}(t)', 'time', 's', '');
ci = ConfidenceInterval(time, [ciLower', ciUpper'], '\hat{x}(t)', 'time', 's', '');
estimatedStimulus.setConfInterval(ci);

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
hEst = estimatedStimulus.plot([], {{' ''k'', ''Linewidth'',4'}});
hStim = stim.plot([], {{' ''b'', ''Linewidth'',4'}});
legend([hEst(1) hStim], 'Decoded', 'Actual');
title(sprintf('Decoded Stimulus +/- 95%% CIs with %d cells', numRealizations), ...
    'FontWeight', 'bold', 'FontSize', 18, 'FontName', 'Arial');
xlabel('time [s]', 'Interpreter', 'none');
ylabel('Stimulus', 'Interpreter', 'none');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig02_univariate_decoding');

%% Example 5b: Arm reaching simulation and PPAF decoding

q = 1e-4;
Qreach = diag([1e-12 1e-12 q q]);
delta = 0.001;
r = 1e-6;
p = 1e-6;
piT = diag([r r p p]);
pi0 = piT;
T = 2;

x0 = [0; 0; 0; 0];
xT = [-0.35; 0.2; 0; 0];
time = 0:delta:T;

A = [1 0 delta 0; 0 1 0 delta; 0 0 1 0; 0 0 0 1];

xState = zeros(4, length(time));
for k = 1:length(time)
    if k == 1
        xState(:,k) = x0;
    else
        xState(:,k) = A * xState(:,k-1) + delta / 2 * (pi / T)^2 * cos(pi * time(k) / T) * ...
            [0; 0; xT(1) - x0(1); xT(2) - x0(2)];
    end
end
xT = xState(:,end);
yT = xT;

Qreach = diag(var(diff(xState, [], 2), [], 2)) * 100;

gamma = 0;
windowTimes = [0 0.001];
numCells = 20;
bCoeffs = 10 * (rand(numCells, 2) - 0.5);
muCoeffs = log(10 * delta) + randn(numCells, 1);
coeffs = [muCoeffs bCoeffs];
fitType = 'binomial';

dataMat = [ones(length(time), 1), xState(3,:)', xState(4,:)'];
clear nst lambda;

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(4,2,[1 3]);
plot(100 * xState(1,:), 100 * xState(2,:), 'k', 'LineWidth', 2);
xlabel('X Position [cm]');
ylabel('Y Position [cm]');
title('Reach Path', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');
hold on;
plot(100 * xState(1,1), 100 * xState(2,1), 'bo', 'MarkerSize', 14);
plot(100 * xState(1,end), 100 * xState(2,end), 'ro', 'MarkerSize', 14);
legend({'Path', 'Start', 'Finish'}, 'Location', 'NorthEast');

subplot(4,2,5);
h1 = plot(time, 100 * xState(1,:), 'k', 'LineWidth', 2);
hold on;
h2 = plot(time, 100 * xState(2,:), 'k-.', 'LineWidth', 2);
legend([h1 h2], 'x', 'y', 'Location', 'NorthEast');
xlabel('time [s]'); ylabel('Position [cm]');

subplot(4,2,7);
h1 = plot(time, 100 * xState(3,:), 'k', 'LineWidth', 2);
hold on;
h2 = plot(time, 100 * xState(4,:), 'k-.', 'LineWidth', 2);
legend([h1 h2], 'v_x', 'v_y', 'Location', 'NorthEast');
xlabel('time [s]'); ylabel('Velocity [cm/s]');

for iCell = 1:numCells
    tempData = exp(dataMat * coeffs(iCell,:)');
    lambdaData = tempData ./ (1 + tempData);
    lambda{iCell} = Covariate(time, lambdaData ./ delta, '\Lambda(t)', 'time', 's', 'spikes/sec', ...
        {sprintf('\\lambda_{%d}', iCell)}, {{' ''b'' '}});
    lambda{iCell} = lambda{iCell}.resample(1 / delta);
    tempSpikeColl = CIF.simulateCIFByThinningFromLambda(lambda{iCell}, 1);
    nst{iCell} = tempSpikeColl.getNST(1); %#ok<AGROW>
    nst{iCell}.setName(num2str(iCell));

    subplot(4,2,[6 8]);
    lambda{iCell}.plot([], {{' ''k'', ''LineWidth'' ,0.5'}});
    hold on;
end
subplot(4,2,[6 8]);
title('Neural Conditional Intensity Functions', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');
xlabel('time [s]'); ylabel('Firing Rate [spikes/sec]');

spikeColl = nstColl(nst);
subplot(4,2,[2 4]);
spikeColl.plot;
set(gca, 'XTick', [], 'XTickLabel', []);
title('Neural Raster', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');
xlabel('time [s]'); ylabel('Cell Number');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig03_reach_and_population_setup');

% Repeated decoding (goal-aware vs free movement).
numExamples = 20;
fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
for k = 1:numExamples
    bCoeffs = 10 * (rand(numCells, 2) - 0.5);
    muCoeffs = log(10 * delta) + randn(numCells, 1);
    coeffs = [muCoeffs bCoeffs];
    dataMat = [ones(length(time), 1), xState(3,:)', xState(4,:)'];

    clear nst;
    for iCell = 1:numCells
        tempData = exp(dataMat * coeffs(iCell,:)');
        lambdaData = tempData ./ (1 + tempData);
        lambdaTemp = Covariate(time, lambdaData ./ delta, '\Lambda(t)', 'time', 's', 'spikes/sec', ...
            {sprintf('\\lambda_{%d}', iCell)}, {{' ''b'' '}});
        lambdaTemp = lambdaTemp.resample(1 / delta);
        tempSpikeColl = CIF.simulateCIFByThinningFromLambda(lambdaTemp, 1);
        nst{iCell} = tempSpikeColl.getNST(1); %#ok<AGROW>
        nst{iCell}.setName(num2str(iCell));
    end

    spikeCollK = nstColl(nst);
    dN = spikeCollK.dataToMatrix';
    dN(dN > 1) = 1;

    beta = [zeros(2, numCells); bCoeffs'];

    [~, ~, x_u, ~] = DecodingAlgorithms.PPDecodeFilterLinear(A, Qreach, dN, ...
        muCoeffs, beta, fitType, delta, gamma, windowTimes, x0, pi0, yT, piT, 0);

    [~, ~, x_uf, ~] = DecodingAlgorithms.PPDecodeFilterLinear(A, Qreach, dN, ...
        muCoeffs, beta, fitType, delta, gamma, windowTimes, x0);

    if k == 1
        subplot(4,2,1:4);
        plot(100 * xState(1,:), 100 * xState(2,:), 'k', 'LineWidth', 3);
        hold on;
        title('Estimated vs. Actual Reach Paths', 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
    end

    subplot(4,2,1:4);
    plot(100 * x_u(1,:)', 100 * x_u(2,:)', 'b');
    plot(100 * x_uf(1,:)', 100 * x_uf(2,:)', 'g');
    xlabel('x [cm]'); ylabel('y [cm]');

    subplot(4,2,5);
    plot(time, 100 * xState(1,:), 'k', 'LineWidth', 3); hold on;
    plot(time, 100 * x_u(1,:)', 'b');
    plot(time, 100 * x_uf(1,:)', 'g');
    ylabel('x(t) [cm]'); set(gca, 'XTick', [], 'XTickLabel', []);

    subplot(4,2,6);
    hA = plot(time, 100 * xState(2,:), 'k', 'LineWidth', 3); hold on;
    hB = plot(time, 100 * x_u(2,:)', 'b');
    hC = plot(time, 100 * x_uf(2,:)', 'g');
    legend([hA(1) hB(1) hC(1)], 'Actual', 'PPAF+Goal', 'PPAF', 'Location', 'SouthEast');
    ylabel('y(t) [cm]'); set(gca, 'XTick', [], 'XTickLabel', []);

    subplot(4,2,7);
    plot(time, 100 * xState(3,:), 'k', 'LineWidth', 3); hold on;
    plot(time, 100 * x_u(3,:)', 'b');
    plot(time, 100 * x_uf(3,:)', 'g');
    ylabel('v_x(t) [cm/s]'); xlabel('time [s]');

    subplot(4,2,8);
    plot(time, 100 * xState(4,:), 'k', 'LineWidth', 3); hold on;
    plot(time, 100 * x_u(4,:)', 'b');
    plot(time, 100 * x_uf(4,:)', 'g');
    ylabel('v_y(t) [cm/s]'); xlabel('time [s]');
end

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig04_ppaf_goal_vs_free');

%% Experiment 6 block from canonical file: Hybrid filter (PPHF)

hybridFixture = load(fullfile(repoRoot, 'helpfiles', 'paperHybridFilterExample.mat'));
time = hybridFixture.time;
delta = hybridFixture.delta;
X = hybridFixture.X;
mstate = hybridFixture.mstate;
Ahy = hybridFixture.A;
Qhy = hybridFixture.Q;
p_ij = hybridFixture.p_ij;
ind = hybridFixture.ind;
px0 = hybridFixture.Px0;

minCovVal = 1e-12;
Qhy{1} = minCovVal * eye(2,2);

numCells = 40;
muCoeffs = log(10 * delta) + randn(numCells, 1);
coeffs = [muCoeffs, zeros(numCells, 2), 10 * (rand(numCells, 2) - 0.5), zeros(numCells, 2)];
dataMat = [ones(size(X,2), 1), X(:,1:end)'];

clear nst;
for iCell = 1:numCells
    tempData = exp(dataMat * coeffs(iCell,:)');
    lambdaData = tempData ./ (1 + tempData);
    lambdaCell = Covariate(time, lambdaData ./ delta, '\Lambda(t)', 'time', 's', 'spikes/sec', ...
        {sprintf('\\lambda_{%d}', iCell)}, {{' ''b'', ''LineWidth'' ,2'}});
    tempSpikeColl = CIF.simulateCIFByThinningFromLambda(lambdaCell, 1, []);
    nst{iCell} = tempSpikeColl.getNST(1); %#ok<AGROW>
    nst{iCell}.setName(num2str(iCell));
end
spikeColl = nstColl(nst);

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(4,2,[1 3]);
plot(100 * X(1,:), 100 * X(2,:), 'k', 'LineWidth', 2); hold on;
plot(100 * X(1,1), 100 * X(2,1), 'bo', 'MarkerSize', 16);
plot(100 * X(1,end), 100 * X(2,end), 'ro', 'MarkerSize', 16);
xlabel('X [cm]'); ylabel('Y [cm]'); title('Reach Path', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

subplot(4,2,[6 8]);
plot(time, mstate, 'k', 'LineWidth', 2);
axis tight;
v = axis;
axis([v(1) v(2) 0 3]);
set(gca, 'YTick', [1 2], 'YTickLabel', {'N', 'M'});
xlabel('time [s]'); ylabel('state'); title('Discrete Movement State', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

subplot(4,2,5);
h1 = plot(time, 100 * X(1,:), 'k', 'LineWidth', 2); hold on;
h2 = plot(time, 100 * X(2,:), 'k-.', 'LineWidth', 2);
legend([h1 h2], 'x', 'y', 'Location', 'NorthEast');
xlabel('time [s]'); ylabel('Position [cm]');

subplot(4,2,7);
h1 = plot(time, 100 * X(3,:), 'k', 'LineWidth', 2); hold on;
h2 = plot(time, 100 * X(4,:), 'k-.', 'LineWidth', 2);
legend([h1 h2], 'v_x', 'v_y', 'Location', 'NorthEast');
xlabel('time [s]'); ylabel('Velocity [cm/s]');

subplot(4,2,[2 4]);
spikeColl.plot;
set(gca, 'XTick', [], 'XTickLabel', [], 'YTickLabel', []);
title('Neural Raster', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');
xlabel('time [s]'); ylabel('Cell Number');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig05_hybrid_setup');

% Repeated hybrid decoding.
nonMovingInd = intersect(find(X(5,:) == 0), find(X(6,:) == 0));
movingInd = setdiff(1:size(X,2), nonMovingInd);
Qhy{2} = diag(var(diff(X(:,movingInd), [], 2), [], 2));
Qhy{2}(1:4,1:4) = 0;
varNV = diag(var(diff(X(:,nonMovingInd), [], 2), [], 2));
Qhy{1} = varNV(1:2,1:2);

numExamples = 20;
fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
clear X_estAll X_estNTAll S_estAll S_estNTAll MU_estAll MU_estNTAll;

for n = 1:numExamples
    muCoeffs = log(10 * delta) + randn(numCells, 1);
    coeffs = [muCoeffs, zeros(numCells, 2), 10 * (rand(numCells, 2) - 0.5), zeros(numCells, 2)];

    dataMat = [ones(size(X,2), 1), X(:,1:end)'];
    clear nst;
    for iCell = 1:numCells
        tempData = exp(dataMat * coeffs(iCell,:)');
        lambdaData = tempData ./ (1 + tempData);
        lambdaCell = Covariate(time, lambdaData ./ delta, '\Lambda(t)', 'time', 's', 'spikes/sec', ...
            {sprintf('\\lambda_{%d}', iCell)}, {{' ''b'', ''LineWidth'' ,2'}});
        tempSpikeColl = CIF.simulateCIFByThinningFromLambda(lambdaCell, 1, []);
        nst{iCell} = tempSpikeColl.getNST(1); %#ok<AGROW>
        nst{iCell}.setName(num2str(iCell));
    end

    spikeCollN = nstColl(nst);
    spikeCollN.resample(1 / delta);
    dN = spikeCollN.dataToMatrix;
    dN(dN > 1) = 1;

    mu0 = 0.5 * ones(size(p_ij,1), 1);
    clear x0 yT pi0Local piTLocal;
    x0{1} = X(ind{1},1);
    yT{1} = X(ind{1},end);
    pi0Local = px0;
    piTLocal{1} = 1e-9 * eye(size(x0{1},1), size(x0{1},1));

    x0{2} = X(ind{2},1);
    yT{2} = X(ind{2},end);
    piTLocal{2} = 1e-9 * eye(size(x0{2},1), size(x0{2},1));

    [S_est, X_est, ~, MU_est] = DecodingAlgorithms.PPHybridFilterLinear(Ahy, Qhy, p_ij, mu0, dN', ...
        coeffs(:,1), coeffs(:,2:end)', 'binomial', delta, [], [], x0, pi0Local, yT, piTLocal);

    [S_estNT, X_estNT, ~, MU_estNT] = DecodingAlgorithms.PPHybridFilterLinear(Ahy, Qhy, p_ij, mu0, dN', ...
        coeffs(:,1), coeffs(:,2:end)', 'binomial', delta, [], [], x0, pi0Local);

    X_estAll(:,:,n) = X_est; %#ok<AGROW>
    X_estNTAll(:,:,n) = X_estNT; %#ok<AGROW>
    S_estAll(n,:) = S_est; %#ok<AGROW>
    S_estNTAll(n,:) = S_estNT; %#ok<AGROW>
    MU_estAll(:,:,n) = MU_est; %#ok<AGROW>
    MU_estNTAll(:,:,n) = MU_estNT; %#ok<AGROW>
end

subplot(4,3,[1 4]);
plot(time, mstate, 'k', 'LineWidth', 3); hold on;
plot(time, mean(S_estAll), 'b', 'LineWidth', 3);
plot(time, mean(S_estNTAll), 'g', 'LineWidth', 3);
set(gca, 'XTick', [], 'YTick', [1 2.1], 'YTickLabel', {'N', 'M'});
ylabel('state');
title('Estimated vs. Actual State', 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

subplot(4,3,[7 10]);
plot(time, mean(squeeze(MU_estAll(2,:,:)), 2), 'b', 'LineWidth', 3); hold on;
plot(time, mean(squeeze(MU_estNTAll(2,:,:)), 2), 'g', 'LineWidth', 3);
axis([min(time) max(time) 0 1.1]);
xlabel('time [s]'); ylabel('P(s(t)=M | data)');
title('Probability of State', 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

mXestAll = mean(100 * X_estAll, 3);
mXestNTAll = mean(100 * X_estNTAll, 3);

subplot(4,3,[2 3 5 6]);
plot(100 * X(1,:)', 100 * X(2,:)', 'k'); hold on;
plot(mXestAll(1,:), mXestAll(2,:), 'b', 'LineWidth', 3);
plot(mXestNTAll(1,:), mXestNTAll(2,:), 'g', 'LineWidth', 3);
plot(100 * X(1,1), 100 * X(2,1), 'bo', 'MarkerSize', 14);
plot(100 * X(1,end), 100 * X(2,end), 'ro', 'MarkerSize', 14);
xlabel('x [cm]'); ylabel('y [cm]');
title('Estimated vs. Actual Reach Path', 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

subplot(4,3,8);
plot(time, 100 * X(1,:), 'k', 'LineWidth', 3); hold on;
plot(time, mXestAll(1,:), 'b', 'LineWidth', 3);
plot(time, mXestNTAll(1,:), 'g', 'LineWidth', 3);
ylabel('x(t) [cm]'); set(gca, 'XTick', [], 'XTickLabel', []);
title('X Position', 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

subplot(4,3,9);
h1 = plot(time, 100 * X(2,:), 'k', 'LineWidth', 3); hold on;
h2 = plot(time, mXestAll(2,:), 'b', 'LineWidth', 3);
h3 = plot(time, mXestNTAll(2,:), 'g', 'LineWidth', 3);
legend([h1(1) h2(1) h3(1)], 'Actual', 'PPAF+Goal', 'PPAF', 'Location', 'SouthEast');
ylabel('y(t) [cm]'); set(gca, 'XTick', [], 'XTickLabel', []);
title('Y Position', 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

subplot(4,3,11);
plot(time, 100 * X(3,:), 'k', 'LineWidth', 3); hold on;
plot(time, mXestAll(3,:), 'b', 'LineWidth', 3);
plot(time, mXestNTAll(3,:), 'g', 'LineWidth', 3);
ylabel('v_x(t) [cm/s]'); xlabel('time [s]');
title('X Velocity', 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

subplot(4,3,12);
plot(time, 100 * X(4,:), 'k', 'LineWidth', 3); hold on;
plot(time, mXestAll(4,:), 'b', 'LineWidth', 3);
plot(time, mXestNTAll(4,:), 'g', 'LineWidth', 3);
ylabel('v_y(t) [cm/s]'); xlabel('time [s]');
title('Y Velocity', 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig06_hybrid_decoding_summary');

if opts.CloseFigures
    close all;
end

result = struct();
result.example_id = 'example05';
result.title = 'Stimulus Decoding With PPAF and PPHF';
result.source_script = [mfilename('fullpath') '.m'];
result.description = [ ...
    'Runs univariate and movement decoding examples with point-process ', ...
    'adaptive and hybrid filters, including goal-aware comparisons.'];
result.figure_files = figureFiles;
result.paper_mapping = 'Sections 2.3.6-2.3.7; Figs. 8, 9, 14 plus hybrid extension from canonical example.';

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'example05_decoding_ppaf_pphf';
addParameter(parser, 'Seed', 0, @(x) isnumeric(x) && isscalar(x));
addParameter(parser, 'ExportFigures', false, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'ExportDir', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'ExportSvg', false, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'Visible', 'off', @(x) ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'CloseFigures', true, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'Resolution', 250, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'WidthPx', 1400, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'HeightPx', 900, @(x) isnumeric(x) && isscalar(x) && x > 0);
parse(parser, varargin{:});

opts = parser.Results;
opts.ExportFigures = logical(opts.ExportFigures);
opts.ExportSvg = logical(opts.ExportSvg);
opts.Visible = validatestring(char(string(opts.Visible)), {'off', 'on'});
opts.CloseFigures = logical(opts.CloseFigures);
opts.ExportDir = char(string(opts.ExportDir));

if opts.ExportFigures && isempty(opts.ExportDir)
    error('example05:MissingExportDir', 'ExportDir must be provided when ExportFigures=true.');
end
if opts.ExportFigures && exist(opts.ExportDir, 'dir') ~= 7
    mkdir(opts.ExportDir);
end
end

function figureFiles = maybeExportFigure(figHandle, figureFiles, opts, fileStem)
if ~opts.ExportFigures
    return;
end
fileInfo = nstat.docs.exportFigure(figHandle, fullfile(opts.ExportDir, fileStem), ...
    'Resolution', opts.Resolution, ...
    'WidthPx', opts.WidthPx, ...
    'HeightPx', opts.HeightPx, ...
    'ExportSvg', opts.ExportSvg);

figureFiles{end+1} = fileInfo.png; %#ok<AGROW>
if opts.ExportSvg
    figureFiles{end+1} = fileInfo.svg; %#ok<AGROW>
end
end
