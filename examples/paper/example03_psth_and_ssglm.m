function result = example03_psth_and_ssglm(varargin)
%EXAMPLE03_PSTH_AND_SSGLM PSTH and state-space GLM examples from nSTAT paper.
%
% What this example demonstrates:
%   1) PSTH estimation on simulated and real spike-train collections.
%   2) Comparison of histogram PSTH and GLM-based PSTH estimates.
%   3) Between-trial/within-trial dynamics with SSGLM diagnostics.
%
% Inputs/data provenance:
%   - Simulated CIF data generated in-script (deterministic via RNG seed).
%   - Bundled experimental PSTH dataset: data/PSTH/Results.mat.
%   - Bundled SSGLM reference fit: data/SSGLMExampleData.mat.
%
% Expected outputs:
%   - Figure 1: Simulated CIF + simulated/real raster examples.
%   - Figure 2: PSTH and PSTH-GLM comparisons.
%   - Figure 3: SSGLM simulation summary (stimulus, gain, raster, CIF).
%   - Figure 4: SSGLM vs PSTH model diagnostics.
%   - Figure 5: True/PSTH/SSGLM stimulus effect surfaces.
%   - Figure 6: Learning-trial comparison and significance matrix.
%
% How it maps to the paper:
%   Paper Section 2.3.3 (PSTH) and Section 2.3.4 (SSGLM), corresponding to
%   paper Figs. 5, 6, and 12.
%
% Syntax:
%   result = example03_psth_and_ssglm
%   result = example03_psth_and_ssglm('ExportFigures',true,...)

opts = parseOptions(varargin{:});

rng(opts.Seed, 'twister');
originalFigureVisibility = get(groot, 'defaultFigureVisible');
set(groot, 'defaultFigureVisible', opts.Visible);
restoreVisibility = onCleanup(@() set(groot, 'defaultFigureVisible', originalFigureVisibility)); %#ok<NASGU>

[dataDir, ~, ~, psthDir, ~] = getPaperDataDirs();
repoRoot = fileparts(dataDir);
originalDir = pwd;
if exist(repoRoot, 'dir') == 7 && ~strcmp(originalDir, repoRoot)
    cd(repoRoot);
end
restoreDir = onCleanup(@() cd(originalDir)); %#ok<NASGU>

close all;
figureFiles = {};

%% Example 3: PSTH data
% Simulated CIF and simulated sample paths.
delta = 0.001;
tmax = 1;
time = 0:delta:tmax;
f = 2;
mu = -3;

lambdaRaw = sin(2 * pi * f * time) + mu;
lambdaData = exp(lambdaRaw) ./ (1 + exp(lambdaRaw)) .* (1 / delta);
lambda = Covariate(time, lambdaData, '\lambda(t)', 'time', 's', 'spikes/sec', ...
    {'\lambda_{1}'}, {{' ''b'', ''LineWidth'' ,2'}});
numRealizations = 20;
spikeCollSim = CIF.simulateCIFByThinningFromLambda(lambda, numRealizations);

% Real PSTH data.
psthData = load(fullfile(psthDir, 'Results.mat'));
numTrials = psthData.Results.Data.Spike_times_STC.balanced_SUA.Nr_trials;

cellNum = 6;
clear nst;
for iTrial = 1:numTrials
    spikeTimes{iTrial} = psthData.Results.Data.Spike_times_STC.balanced_SUA.spike_times{1, iTrial, cellNum}; %#ok<AGROW>
    nst{iTrial} = nspikeTrain(spikeTimes{iTrial}); %#ok<AGROW>
    nst{iTrial}.setName(num2str(cellNum));
end
spikeCollReal1 = nstColl(nst);
spikeCollReal1.setMinTime(0);
spikeCollReal1.setMaxTime(2);

cellNum = 1;
clear nst spikeTimes;
for iTrial = 1:numTrials
    spikeTimes{iTrial} = psthData.Results.Data.Spike_times_STC.balanced_SUA.spike_times{1, iTrial, cellNum}; %#ok<AGROW>
    nst{iTrial} = nspikeTrain(spikeTimes{iTrial}); %#ok<AGROW>
    nst{iTrial}.setName(num2str(cellNum));
end
spikeCollReal2 = nstColl(nst);
spikeCollReal2.setMinTime(0);
spikeCollReal2.setMaxTime(2);

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(2,2,1);
lambda.plot;
title('Simulated Conditional Intensity Function (CIF)', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
set(get(gca, 'YLabel'), 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');

subplot(2,2,3);
spikeCollSim.plot;
set(gca, 'YTick', 0:5:numRealizations, 'YTickLabel', 0:5:numRealizations);
title(sprintf('%d Simulated Point Process Sample Paths', numRealizations), 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Trial [k]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

subplot(2,2,2);
spikeCollReal1.plot;
set(gca, 'YTick', 0:2:numTrials, 'YTickLabel', 0:2:numTrials);
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Trial [k]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title('Response to Moving Visual Stimulus (Neuron 6)', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

subplot(2,2,4);
spikeCollReal2.plot;
set(gca, 'YTick', 0:2:numTrials, 'YTickLabel', 0:2:numTrials);
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Trial [k]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title('Response to Moving Visual Stimulus (Neuron 1)', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig01_simulated_and_real_rasters');

% PSTH estimation comparison.
fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
binsize = 0.05;
psth = spikeCollSim.psth(binsize);
psthGLM = spikeCollSim.psthGLM(binsize);

subplot(2,3,1);
spikeCollSim.plot;
set(gca, 'YTick', 0:2:spikeCollSim.numSpikeTrains, 'YTickLabel', 0:2:spikeCollSim.numSpikeTrains);
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Trial [k]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

subplot(2,3,4);
h1 = lambda.plot([], {{' ''b'', ''Linewidth'',4'}});
h3 = psthGLM.plot([], {{' ''k'', ''Linewidth'',4'}});
h2 = psth.plot([], {{' ''rx'', ''Linewidth'',4'}});
legend([h1(1) h2(1) h3(1)], 'true', 'PSTH', 'PSTH_{glm}');
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('[spikes/sec]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

subplot(2,3,2);
spikeCollReal1.plot;
set(gca, 'YTick', 0:2:spikeCollReal1.numSpikeTrains, 'YTickLabel', 0:2:spikeCollReal1.numSpikeTrains);
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Trial [k]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

subplot(2,3,5);
psthReal1 = spikeCollReal1.psth(binsize);
psthGLMReal1 = spikeCollReal1.psthGLM(binsize);
h3 = psthGLMReal1.plot([], {{' ''k'', ''Linewidth'',4'}});
h2 = psthReal1.plot([], {{' ''rx'', ''Linewidth'',4'}});
legend([h2(1) h3(1)], 'PSTH', 'PSTH_{glm}');
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('[spikes/sec]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

subplot(2,3,3);
spikeCollReal2.plot;
set(gca, 'YTick', 0:2:spikeCollReal2.numSpikeTrains, 'YTickLabel', 0:2:spikeCollReal2.numSpikeTrains);
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Trial [k]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

subplot(2,3,6);
psthReal2 = spikeCollReal2.psth(binsize);
psthGLMReal2 = spikeCollReal2.psthGLM(binsize);
h3 = psthGLMReal2.plot([], {{' ''k'', ''Linewidth'',4'}});
h2 = psthReal2.plot([], {{' ''rx'', ''Linewidth'',4'}});
legend([h2(1) h3(1)], 'PSTH', 'PSTH_{glm}');
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('[spikes/sec]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig02_psth_comparison');

%% Example 3b: SSGLM
close all;
delta = 0.001;
tmax = 1;
time = 0:delta:tmax;
ts = 0.001;
numRealizations = 50;

clear nst b1;
for iTrial = 1:numRealizations
    f = 2;
    b1(iTrial) = 3 * (iTrial / numRealizations); %#ok<AGROW>
    b0 = -3;
    u = sin(2 * pi * f * time);
    e = zeros(length(time), 1);

    stim = Covariate(time', u', 'Stimulus', 'time', 's', 'Voltage', {'sin'});
    ens = Covariate(time', e, 'Ensemble', 'time', 's', 'Spikes', {'n1'});

    histCoeffs = [-4 -1 -0.5];
    htf = tf(histCoeffs, [1], ts, 'Variable', 'z^-1');
    stf = tf([b1(iTrial)], 1, ts, 'Variable', 'z^-1');
    etf = tf([0], 1, ts, 'Variable', 'z^-1');
    simTypeSelect = 'binomial';

    [sC, lambdaTemp] = CIF.simulateCIF(b0, htf, stf, etf, stim, ens, 1, simTypeSelect);
    if iTrial == 1
        lambdaSS = lambdaTemp;
    else
        lambdaSS = lambdaSS.merge(lambdaTemp);
    end

    nst{iTrial} = sC.getNST(1); %#ok<AGROW>
    nst{iTrial} = nst{iTrial}.resample(1 / delta);
end

spikeColl = nstColl(nst);

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(3,2,[3 4]);
spikeColl.plot;
set(gca, 'YTick', 0:10:numRealizations, 'YTickLabel', 0:10:numRealizations, 'XTick', 0:0.1:tmax, 'XTickLabel', 0:0.1:tmax);
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Trial [k]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title('Simulated Neural Raster', 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');

stimData = exp(-3 + u' * b1);
stimData = stimData ./ (1 + stimData);

subplot(3,2,1);
plot(time, u, 'k', 'LineWidth', 3);
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Stimulus', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title('Within Trial Stimulus', 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');

subplot(3,2,2);
plot(1:length(b1), b1, 'k', 'LineWidth', 3);
xlabel('Trial [k]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Stimulus Gain', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title('Across Trial Stimulus Gain', 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');

subplot(3,2,[5 6]);
imagesc(stimData' ./ delta);
set(gca, 'YDir', 'normal', 'XTick', 0:100:tmax / delta, 'XTickLabel', 0:0.1:tmax, 'YTick', 0:10:numRealizations, 'YTickLabel', 0:10:numRealizations);
xlabel('time [s]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Trial [k]', 'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title('True Conditional Intensity Function', 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');
axis tight;

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig03_ssglm_simulation_summary');

% Create covariates and design matrices for SSGLM section.
stim = Covariate(time, sin(2 * pi * f * time), 'Stimulus', 'time', 's', 'V', {'stim'});
baseline = Covariate(time, ones(length(time), 1), 'Baseline', 'time', 's', '', {'constant'}); %#ok<NASGU>
windowTimes = 0:0.001:0.003;
numBasis = 25;

spikeColl.resample(1 / delta);
spikeColl.setMaxTime(tmax);
dN = spikeColl.dataToMatrix';
dN(dN > 1) = 1;

basisWidth = (spikeColl.maxTime - spikeColl.minTime) / numBasis;

if simTypeSelect == 0
    fitType = 'binomial';
else
    fitType = 'poisson';
end

[psthSig, ~, psthResult] = spikeColl.psthGLM(basisWidth, windowTimes, fitType);
gamma0 = psthResult.getHistCoeffs';
gamma0(isnan(gamma0)) = -5;
x0 = psthResult.getCoeffs; %#ok<NASGU>
numVarEstIter = 10;
Q0 = spikeColl.estimateVarianceAcrossTrials(numBasis, windowTimes, numVarEstIter, fitType); %#ok<NASGU>
A = eye(numBasis, numBasis); %#ok<NASGU>

% Load precomputed SSGLM fit for deterministic, fast execution.
ssglm = load(fullfile(dataDir, 'SSGLMExampleData.mat'));
fitResults = FitResult.fromStructure(ssglm.fR);
psthResult = FitResult.fromStructure(ssglm.psthR);
xK = ssglm.xK;
WkuFinal = ssglm.WkuFinal;
stimulus = ssglm.stimulus;
stimCIs = ssglm.stimCIs;

tCompare = psthResult.mergeResults(fitResults);
tCompare.lambda.setDataLabels({'\lambda_{PSTH}', '\lambda_{SSGLM}'});
fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(2,2,1);
tCompare.KSPlot;
subplot(2,2,2);
tCompare.plotResidual;
subplot(2,2,3);
tCompare.plotInvGausTrans;
subplot(2,2,4);
tCompare.plotSeqCorr;

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig04_ssglm_fit_diagnostics');

% Compare true, PSTH, and SSGLM stimulus effects.
minTime = 0;
maxTime = tmax;
stimDataEst = stim.data * b1;
if strcmp(fitType, 'poisson')
    actStimEffect = exp(stimDataEst - 3) ./ delta;
else
    actStimEffect = exp(stimDataEst - 3) ./ (1 + exp(stimDataEst - 3)) ./ delta;
end

basisWidth = (maxTime - minTime) / numBasis;
sampleRate = 1 / delta;
unitPulseBasis = nstColl.generateUnitImpulseBasis(basisWidth, minTime, maxTime, sampleRate);
basisMat = unitPulseBasis.data;

if strcmp(fitType, 'poisson')
    estStimEffect = exp(basisMat * xK) ./ delta;
else
    estStimEffect = exp(basisMat * xK) ./ (1 + exp(basisMat * xK)) ./ delta;
end

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(3,1,1);
mesh((1:length(b1))', stim.time, actStimEffect);
title('True Stimulus Effect', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');
view(gca, [90 -90]);
set(gca, 'XTick', [], 'YTick', []);

subplot(3,1,2);
mesh((1:length(b1))', stim.time, repmat(psthSig.data, [1 numRealizations]));
title('PSTH Estimated Stimulus Effect', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');
view(gca, [90 -90]);
set(gca, 'XTick', [], 'YTick', []);

subplot(3,1,3);
mesh((1:length(b1))', stim.time, estStimEffect);
title('SSGLM Estimated Stimulus Effect', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');
view(gca, [90 -90]);
set(gca, 'XTick', [], 'YTick', []);

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig05_stimulus_effect_surfaces');

% Compare differences across trials.
[tRate, probMat, sigMat] = DecodingAlgorithms.computeSpikeRateCIs(xK, WkuFinal, dN, 0, tmax, fitType, delta, ssglm.gammahat, windowTimes);
lt = find(sigMat(1, :) == 1, 1, 'first');
if isempty(lt)
    lt = 2;
end

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(2,3,1);
tRate.setName(sprintf('(%g-0)^-1*\\Lambda(0,%g)', tmax, tmax));
tRate.plot([], {{' ''k'', ''Linewidth'',4'}});
v = axis;
plot(lt * [1; 1], v(3:4), 'r', 'LineWidth', 2);
xlabel('Trial [k]', 'Interpreter', 'none');
ylabel('Average Firing Rate [spikes/sec]', 'Interpreter', 'none');
title(sprintf('Learning Trial:%d', lt), 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

ax = subplot(2,3,[2 3 5 6]);
imagesc(probMat);
colormap(ax, flipud(gray));
hold on;
kTrials = size(dN, 1);
for k = 1:kTrials
    for m = (k + 1):kTrials
        if sigMat(k, m) == 1
            plot3(m, k, 1, 'r*');
        end
    end
end
set(ax, 'XAxisLocation', 'top', 'YAxisLocation', 'right');
xlabel('Trial Number', 'Interpreter', 'none');
ylabel('Trial Number', 'Interpreter', 'none');

subplot(2,3,4);
stim1 = Covariate(time, basisMat * stimulus(:,1), 'Trial1', 'time', 's', 'spikes/sec');
ci1 = ConfidenceInterval(time, basisMat * squeeze(stimCIs(:,1,:)));
stim1.setConfInterval(ci1);

stimlt = Covariate(time, basisMat * stimulus(:,lt), 'TrialLT', 'time', 's', 'spikes/sec');
ciLt = ConfidenceInterval(time, basisMat * squeeze(stimCIs(:,lt,:)));
ciLt.setColor('r');
stimlt.setConfInterval(ciLt);

h1 = stim1.plot([], {{' ''k'', ''Linewidth'',4'}});
h2 = stimlt.plot([], {{' ''r'', ''Linewidth'',4'}});
legend([h1(1) h2(1)], '\lambda_{1}(t)', sprintf('\\lambda_{%d}(t)', lt));
xlabel('time [s]', 'Interpreter', 'none');
ylabel('Firing Rate [spikes/sec]', 'Interpreter', 'none');
title({'Learning Trial Vs. Baseline Trial'; 'with 95% CIs'}, 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig06_learning_trial_comparison');

if opts.CloseFigures
    close all;
end

result = struct();
result.example_id = 'example03';
result.title = 'PSTH and SSGLM Dynamics Example';
result.source_script = mfilename('fullpath');
result.description = [ ...
    'Generates simulated/real PSTH analyses and SSGLM between-trial dynamics ', ...
    'diagnostics using bundled deterministic example data.'];
result.figure_files = figureFiles;
result.paper_mapping = 'Sections 2.3.3-2.3.4; Figs. 5, 6, and 12 (nSTAT paper, 2012).';

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'example03_psth_and_ssglm';
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
    error('example03:MissingExportDir', 'ExportDir must be provided when ExportFigures=true.');
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
