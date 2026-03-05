function result = example01_mepsc_poisson(varargin)
%EXAMPLE01_MEPSC_POISSON mEPSC Poisson modeling under constant and varying magnesium.
%
% What this example demonstrates:
%   1) Homogeneous Poisson modeling for constant Mg2+ conditions.
%   2) Piecewise baseline modeling under Mg2+ washout conditions.
%   3) Model comparison using KS plots, time-rescaling diagnostics, and
%      estimated conditional intensity functions.
%
% Inputs/data provenance:
%   Uses installer-downloaded nSTAT example data from `data/mEPSCs`:
%   - epsc2.txt
%   - washout1.txt
%   - washout2.txt
%
% Expected outputs:
%   - Figure 1: Constant Mg2+ raster + diagnostics + lambda estimate.
%   - Figure 2: Constant vs decreasing Mg2+ raster overview.
%   - Figure 3: Piecewise model diagnostics and lambda comparison.
%
% How it maps to the paper:
%   Paper Section 2.3.1 (mEPSC analysis), with outputs aligned to the
%   mEPSC model-comparison workflow (paper Figs. 3 and 10 discussion).
%
% Syntax:
%   result = example01_mepsc_poisson
%   result = example01_mepsc_poisson('ExportFigures', true, ...)
%
% Name-Value options:
%   Seed          - RNG seed (default 0).
%   ExportFigures - Export generated figures (default false).
%   ExportDir     - Figure output directory when exporting.
%   ExportSvg     - Export SVG in addition to PNG (default false).
%   Visible       - Figure visibility: 'off' (default) or 'on'.
%   CloseFigures  - Close all figures before return (default true).
%   Resolution    - PNG resolution in DPI (default 250).
%   WidthPx       - Export width in pixels (default 1400).
%   HeightPx      - Export height in pixels (default 900).
%
% Output:
%   result - Struct with metadata and exported file paths.

opts = parseOptions(varargin{:});

rng(opts.Seed, 'twister');
originalFigureVisibility = get(groot, 'defaultFigureVisible');
set(groot, 'defaultFigureVisible', opts.Visible);
restoreVisibility = onCleanup(@() set(groot, 'defaultFigureVisible', originalFigureVisibility)); %#ok<NASGU>

[dataDir, mEPSCDir, ~, ~, ~] = getPaperDataDirs();
repoRoot = fileparts(dataDir);
originalDir = pwd;
if exist(repoRoot, 'dir') == 7 && ~strcmp(originalDir, repoRoot)
    cd(repoRoot);
end
restoreDir = onCleanup(@() cd(originalDir)); %#ok<NASGU>

figureFiles = {};

close all;

% Constant magnesium concentration: homogeneous Poisson model.
epsc2 = importdata(fullfile(mEPSCDir, 'epsc2.txt'));
sampleRate = 1000;
spikeTimesConst = epsc2.data(:,2) ./ sampleRate;
nstConst = nspikeTrain(spikeTimesConst);
timeConst = 0:(1 / sampleRate):nstConst.maxTime;

baseline = Covariate(timeConst, ones(length(timeConst), 1), 'Baseline', 'time', 's', '', {'\mu'});
covarColl = CovColl({baseline});
spikeCollConst = nstColl(nstConst);
trialConst = Trial(spikeCollConst, covarColl);

clear tcConst;
tcConst{1} = TrialConfig({{'Baseline', '\mu'}}, sampleRate, []);
tcConst{1}.setName('Constant Baseline');
configConst = ConfigColl(tcConst);
resultConst = Analysis.RunAnalysisForAllNeurons(trialConst, configConst, 0);
resultConst.lambda.setDataLabels({'\lambda_{const}'});

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(2,2,1);
spikeCollConst.plot;
title({'Neural Raster with constant Mg^{2+} Concentration'}, 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
hx = xlabel('time [s]', 'Interpreter', 'none');
hy = ylabel('mEPSCs', 'Interpreter', 'none');
set(gca, 'YTick', [0 1]);
set([hx hy], 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

subplot(2,2,2);
resultConst.plotInvGausTrans;
subplot(2,2,3);
resultConst.KSPlot;
subplot(2,2,4);
resultConst.lambda.plot([], {{' ''b'' ,''Linewidth'',2'}});
hx = xlabel('time [s]', 'Interpreter', 'none');
hy = get(gca, 'YLabel');
set([hx hy], 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
legend('\lambda_{const}', 'Location', 'NorthEast');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig01_constant_mg_summary');

% Varying magnesium concentration: piecewise baseline model.
washout1 = importdata(fullfile(mEPSCDir, 'washout1.txt'));
washout2 = importdata(fullfile(mEPSCDir, 'washout2.txt'));

spikeTimes1 = 260 + washout1.data(:,2) ./ sampleRate;
spikeTimes2 = sort(washout2.data(:,2)) ./ sampleRate + 745;
nstWashout = nspikeTrain([spikeTimes1; spikeTimes2]);
timeWashout = 260:(1 / sampleRate):nstWashout.maxTime;

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(2,1,1);
nstConst.plot;
set(gca, 'YTick', [0 1]);
hy = ylabel('mEPSCs');
title({'Neural Raster with constant Mg^{2+} Concentration'}, 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
hx = get(gca, 'XLabel');
set([hx hy], 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

subplot(2,1,2);
nstWashout.plot;
set(gca, 'YTick', [0 1]);
hy = ylabel('mEPSCs');
title({'Neural Raster with decreasing Mg^{2+} Concentration'}, 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
hx = get(gca, 'XLabel');
set([hx hy], 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig02_washout_raster_overview');

timeInd1 = find(timeWashout < 495, 1, 'last');
timeInd2 = find(timeWashout < 765, 1, 'last');
constantRate = ones(length(timeWashout), 1);
rate1 = zeros(length(timeWashout), 1);
rate2 = zeros(length(timeWashout), 1);
rate3 = zeros(length(timeWashout), 1);
rate1(1:timeInd1) = 1;
rate2((timeInd1 + 1):timeInd2) = 1;
rate3((timeInd2 + 1):end) = 1;

baselineWashout = Covariate(timeWashout, [constantRate, rate1, rate2, rate3], ...
    'Baseline', 'time', 's', '', {'\mu', '\mu_{1}', '\mu_{2}', '\mu_{3}'});

spikeCollWashout = nstColl(nstWashout);
trialWashout = Trial(spikeCollWashout, CovColl({baselineWashout}));

clear tcWashout;
tcWashout{1} = TrialConfig({{'Baseline', '\mu'}}, sampleRate, []);
tcWashout{1}.setName('Constant Baseline');
tcWashout{2} = TrialConfig({{'Baseline', '\mu_{1}', '\mu_{2}', '\mu_{3}'}}, sampleRate, []);
tcWashout{2}.setName('Diff Baseline');
configWashout = ConfigColl(tcWashout);
resultWashout = Analysis.RunAnalysisForAllNeurons(trialWashout, configWashout, 0);
resultWashout.lambda.setDataLabels({'\lambda_{const}', '\lambda_{const-epoch}'});

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
subplot(2,2,1);
spikeCollWashout.plot;
title({'Neural Raster with decreasing Mg^{2+} Concentration'}, 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
hx = xlabel('time [s]', 'Interpreter', 'none');
set(gca, 'YTickLabel', []);
set([hx], 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
hold on;
plot([495; 495], [0, 1], 'r', 'LineWidth', 4);
plot([765; 765], [0, 1], 'r', 'LineWidth', 4);

subplot(2,2,2);
resultWashout.plotInvGausTrans;
subplot(2,2,3);
resultWashout.KSPlot;
subplot(2,2,4);
resultWashout.lambda.getSubSignal(1).plot([], {{' ''b'' ,''Linewidth'',2'}});
resultWashout.lambda.getSubSignal(2).plot([], {{' ''g'' ,''Linewidth'',2'}});
v = axis;
axis([v(1) v(2) 0 5]);
hx = xlabel('time [s]', 'Interpreter', 'none');
hy = get(gca, 'YLabel');
set([hx hy], 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');
legend('\lambda_{const}', '\lambda_{const-epoch}', 'Location', 'NorthEast');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig03_piecewise_baseline_comparison');

if opts.CloseFigures
    close all;
end

result = struct();
result.example_id = 'example01';
result.title = 'mEPSC Poisson Models Under Constant and Washout Magnesium';
result.source_script = [mfilename('fullpath') '.m'];
result.description = [ ...
    'Fits constant and piecewise Poisson GLM baselines to mEPSC spike trains ', ...
    'and visualizes model diagnostics (KS, inverse-Gaussian transform, lambda).'];
result.figure_files = figureFiles;
result.paper_mapping = 'Section 2.3.1; Figs. 3 and 10 (nSTAT paper, 2012).';

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'example01_mepsc_poisson';
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
    error('example01:MissingExportDir', 'ExportDir must be provided when ExportFigures=true.');
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
