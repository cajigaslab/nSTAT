function result = example02_whisker_stimulus_thalamus(varargin)
%EXAMPLE02_WHISKER_STIMULUS_THALAMUS Explicit-stimulus GLM on whisker/thalamus data.
%
% What this example demonstrates:
%   1) Building a point-process GLM with a known whisker stimulus covariate.
%   2) Estimating stimulus-response lag using residual cross-covariance.
%   3) Comparing baseline, baseline+stimulus, and baseline+stimulus+history
%      models using KS statistics, AIC, and BIC.
%
% Inputs/data provenance:
%   Uses bundled external-stimulus recordings from:
%   data/Explicit Stimulus/Dir3/Neuron1/Stim2/trngdataBis.mat
%
% Expected outputs:
%   - Figure 1: Neural raster, stimulus displacement, and velocity traces.
%   - Figure 2: Lag selection, model-order diagnostics, KS plot, and
%     coefficient comparison across fitted models.
%
% How it maps to the paper:
%   Paper Section 2.3.2 (explicit stimulus effects, thalamic spike trains),
%   aligned to discussion around Figs. 4 and 11.
%
% Syntax:
%   result = example02_whisker_stimulus_thalamus
%   result = example02_whisker_stimulus_thalamus('ExportFigures',true,...)

opts = parseOptions(varargin{:});

rng(opts.Seed, 'twister');
originalFigureVisibility = get(groot, 'defaultFigureVisible');
set(groot, 'defaultFigureVisible', opts.Visible);
restoreVisibility = onCleanup(@() set(groot, 'defaultFigureVisible', originalFigureVisibility)); %#ok<NASGU>

[dataDir, ~, explicitStimulusDir, ~, ~] = getPaperDataDirs();
repoRoot = fileparts(dataDir);
originalDir = pwd;
if exist(repoRoot, 'dir') == 7 && ~strcmp(originalDir, repoRoot)
    cd(repoRoot);
end
restoreDir = onCleanup(@() cd(originalDir)); %#ok<NASGU>

close all;
figureFiles = {};

% Load canonical whisker data used in nSTATPaperExamples.
direction = 3;
neuronIdx = 1;
stimIdx = 2;
dataPath = fullfile(explicitStimulusDir, ['Dir' num2str(direction)], ...
    ['Neuron' num2str(neuronIdx)], ['Stim' num2str(stimIdx)]);
data = load(fullfile(dataPath, 'trngdataBis.mat'));

time = 0:0.001:(length(data.t) - 1) * 0.001;
stimData = data.t;
spikeTimes = time(data.y == 1);

stim = Covariate(time, stimData ./ 10, 'Stimulus', 'time', 's', 'mm', {'stim'});
baseline = Covariate(time, ones(length(time), 1), 'Baseline', 'time', 's', '', {'constant'});
nst = nspikeTrain(spikeTimes);
spikeColl = nstColl(nst);
trial = Trial(spikeColl, CovColl({stim, baseline}));

% Figure 1: data overview.
fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(3,1,1);
nstView = nspikeTrain(spikeTimes);
nstView.setMaxTime(21);
nstView.plot;
set(gca, 'YTick', [0 1], 'XTick', 0:1:max(time), 'XTickLabel', [], 'LineWidth', 1);
xlabel('');
hy = ylabel('spikes');
set(hy, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title('Neural Raster', 'FontWeight', 'bold', 'FontSize', 16, 'FontName', 'Arial');

subplot(3,1,2);
stim.getSigInTimeWindow(0, 21).plot([], {{' ''k'' '}});
legend off;
set(gca, 'YTick', 0:0.25:1, 'XTick', 0:1:max(time), 'XTickLabel', [], 'LineWidth', 1);
hy = ylabel('Displacement [mm]', 'Interpreter', 'none');
xlabel('');
set(hy, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title('Stimulus - Whisker Displacement', 'FontWeight', 'bold', 'FontSize', 16, 'FontName', 'Arial');

subplot(3,1,3);
stim.derivative.getSigInTimeWindow(0, 21).plot([], {{' ''k'' '}});
legend off;
set(gca, 'YTick', -80:40:80, 'XTick', 0:1:max(time), 'LineWidth', 1);
axis([0 21 -80 80]);
hy = ylabel('Displacement Velocity [mm/s]', 'Interpreter', 'none');
hx = xlabel('time [s]', 'Interpreter', 'none');
set([hx hy], 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
title('Displacement Velocity', 'FontWeight', 'bold', 'FontSize', 16, 'FontName', 'Arial');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig01_data_overview');

% Fit baseline model and estimate stimulus lag from residual cross-covariance.
selfHist = [];
neighborHist = [];
sampleRate = 1000;
clear cfg;
cfg{1} = TrialConfig({{'Baseline', 'constant'}}, sampleRate, selfHist, neighborHist);
cfg{1}.setName('Baseline');
baselineResults = Analysis.RunAnalysisForAllNeurons(trial, ConfigColl(cfg), 0);

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(7,2,[1 3 5]);
baselineResults.Residual.xcov(stim).windowedSignal([0, 1]).plot;
ylabel('');
[peakVal, ~, shiftTime] = max(baselineResults.Residual.xcov(stim).windowedSignal([0, 1]));
title(sprintf('Cross Correlation Function - Peak at t=%g sec', shiftTime), ...
    'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
hold on;
marker = plot(shiftTime, peakVal, 'ro', 'LineWidth', 3);
set(marker, 'MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', [1 0 0]);
hx = xlabel('Lag [s]', 'Interpreter', 'none');
set(hx, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

% Shift the stimulus to align with best lag (<1 s).
stimShifted = Covariate(time, stimData, 'Stimulus', 'time', 's', 'V', {'stim'});
stimShifted = stimShifted.shift(shiftTime);
baselineMu = Covariate(time, ones(length(time), 1), 'Baseline', 'time', 's', '', {'\mu'});
trialShifted = Trial(nstColl(nspikeTrain(spikeTimes)), CovColl({stimShifted, baselineMu}));

clear cfg;
cfg{1} = TrialConfig({{'Baseline', '\mu'}}, sampleRate, [], []);
cfg{1}.setName('Baseline');
cfg{2} = TrialConfig({{'Baseline', '\mu'}, {'Stimulus', 'stim'}}, sampleRate, [], []);
cfg{2}.setName('Baseline+Stimulus');
Analysis.RunAnalysisForAllNeurons(trialShifted, ConfigColl(cfg), 0); %#ok<NASGU>

% History model-order search.
delta = 1 / sampleRate;
maxWindow = 1;
numWindows = 32;
windowTimes = unique(round([0 logspace(log10(delta), log10(maxWindow), numWindows)] .* sampleRate) ./ sampleRate);
historySweep = Analysis.computeHistLagForAll(trialShifted, windowTimes, ...
    {{'Baseline', '\mu'}, {'Stimulus', 'stim'}}, 'BNLRCG', 0, sampleRate, 0);

aicIdx = find((historySweep{1}.AIC(2:end) - historySweep{1}.AIC(1)) == ...
              min(historySweep{1}.AIC(2:end) - historySweep{1}.AIC(1)), 1, 'first') + 1;
bicIdx = find((historySweep{1}.BIC(2:end) - historySweep{1}.BIC(1)) == ...
              min(historySweep{1}.BIC(2:end) - historySweep{1}.BIC(1)), 1, 'first') + 1;
ksIdx = find(historySweep{1}.KSStats.ks_stat == min(historySweep{1}.KSStats.ks_stat), 1, 'first');

if isempty(aicIdx) || aicIdx == 1
    aicIdx = inf;
end
if isempty(bicIdx) || bicIdx == 1
    bicIdx = inf;
end
windowIndex = min([aicIdx, bicIdx]);
if ~isfinite(windowIndex) || windowIndex > numel(windowTimes)
    windowIndex = ksIdx;
end

x = 0:(length(windowTimes) - 1);
subplot(7,2,2);
plot(x, historySweep{1}.KSStats.ks_stat, '.-');
axis tight;
hold on;
plot(x(windowIndex), historySweep{1}.KSStats.ks_stat(windowIndex), 'r*');
set(gca, 'XTick', 0:5:historySweep{1}.numResults-1, 'XTickLabel', [], 'TickLength', [0.02 0.02], 'XMinorTick', 'on', 'LineWidth', 1);
ylabel('KS Statistic');
title({'Model Selection via change'; 'in KS Statistic, AIC, and BIC'}, 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');

dAIC = historySweep{1}.AIC - historySweep{1}.AIC(1);
subplot(7,2,4);
plot(x, dAIC, '.-');
axis tight;
hold on;
plot(x(windowIndex), dAIC(windowIndex), 'r*');
set(gca, 'XTick', 0:5:historySweep{1}.numResults-1, 'XTickLabel', [], 'TickLength', [0.02 0.02], 'XMinorTick', 'on', 'LineWidth', 1);
ylabel('\Delta AIC');

dBIC = historySweep{1}.BIC - historySweep{1}.BIC(1);
subplot(7,2,6);
plot(x, dBIC, '.-');
axis tight;
hold on;
plot(x(windowIndex), dBIC(windowIndex), 'r*');
hx = xlabel('# History Windows, Q');
hy = ylabel('\Delta BIC');
set([hx hy], 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'TickLength', [0.02 0.02], 'XMinorTick', 'on', 'XTick', 0:5:historySweep{1}.numResults-1, 'LineWidth', 1);

if windowIndex > 1
    selectedHistory = windowTimes(1:windowIndex);
else
    selectedHistory = [];
end

clear cfg;
cfg{1} = TrialConfig({{'Baseline', '\mu'}}, sampleRate, [], []);
cfg{1}.setName('Baseline');
cfg{2} = TrialConfig({{'Baseline', '\mu'}, {'Stimulus', 'stim'}}, sampleRate, [], []);
cfg{2}.setName('Baseline+Stimulus');
cfg{3} = TrialConfig({{'Baseline', '\mu'}, {'Stimulus', 'stim'}}, sampleRate, selectedHistory, []);
cfg{3}.setName('Baseline+Stimulus+Hist');
modelCompare = Analysis.RunAnalysisForAllNeurons(trialShifted, ConfigColl(cfg), 0);
modelCompare.lambda.setDataLabels({'\lambda_{const}', '\lambda_{const+stim}', '\lambda_{const+stim+hist}'});

subplot(7,2,[9 11 13]);
modelCompare.KSPlot;
subplot(7,2,[10 12 14]);
modelCompare.plotCoeffs;
legend off;

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig02_lag_and_model_comparison');

if opts.CloseFigures
    close all;
end

result = struct();
result.example_id = 'example02';
result.title = 'Whisker Stimulus GLM With Lag and History Selection';
result.source_script = mfilename('fullpath');
result.description = [ ...
    'Fits explicit-stimulus point-process GLMs, estimates lag from residual ', ...
    'xcov, and compares baseline/stimulus/history models via AIC/BIC/KS.'];
result.figure_files = figureFiles;
result.paper_mapping = 'Section 2.3.2; Figs. 4 and 11 (nSTAT paper, 2012).';

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'example02_whisker_stimulus_thalamus';
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
    error('example02:MissingExportDir', 'ExportDir must be provided when ExportFigures=true.');
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
