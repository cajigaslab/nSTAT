function result = example04_place_cells_continuous_stimulus(varargin)
%EXAMPLE04_PLACE_CELLS_CONTINUOUS_STIMULUS Place-field estimation with Gaussian and Zernike bases.
%
% What this example demonstrates:
%   1) Visualization of hippocampal place-cell spiking along animal paths.
%   2) Comparison of Gaussian vs Zernike receptive-field models.
%   3) Population-level model comparison using KS, AIC, and BIC summaries.
%
% Inputs/data provenance:
%   Uses bundled place-cell datasets and precomputed model fits:
%   - data/Place Cells/PlaceCellDataAnimal1.mat
%   - data/Place Cells/PlaceCellDataAnimal2.mat
%   - data/PlaceCellAnimal1Results.mat
%   - data/PlaceCellAnimal2Results.mat
%
% Expected outputs:
%   - Figure 1: Example spike locations over path for selected cells.
%   - Figure 2: Population delta-KS, delta-AIC, delta-BIC summaries.
%   - Figures 3-6: Full Gaussian and Zernike place-field maps for both animals.
%   - Figure 7: Mesh comparison for an example cell (Gaussian vs Zernike).
%
% How it maps to the paper:
%   Paper Section 2.3.5 (place-cell receptive fields), with outputs aligned
%   to paper Figs. 7 and 13.
%
% Syntax:
%   result = example04_place_cells_continuous_stimulus
%   result = example04_place_cells_continuous_stimulus('ExportFigures',true,...)

opts = parseOptions(varargin{:});

rng(opts.Seed, 'twister');
originalFigureVisibility = get(groot, 'defaultFigureVisible');
set(groot, 'defaultFigureVisible', opts.Visible);
restoreVisibility = onCleanup(@() set(groot, 'defaultFigureVisible', originalFigureVisibility)); %#ok<NASGU>

[dataDir, ~, ~, ~, placeCellDataDir] = getPaperDataDirs();
repoRoot = fileparts(dataDir);
originalDir = pwd;
if exist(repoRoot, 'dir') == 7 && ~strcmp(originalDir, repoRoot)
    cd(repoRoot);
end
restoreDir = onCleanup(@() cd(originalDir)); %#ok<NASGU>

close all;
figureFiles = {};

% Example data visualization for selected cells.
animal1 = load(fullfile(placeCellDataDir, 'PlaceCellDataAnimal1.mat'));
exampleCells = [2 21 25 49];

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
for i = 1:length(exampleCells)
    subplot(2,2,i);
    h1 = plot(animal1.x, animal1.y, 'b', 'LineWidth', 0.5);
    hold on;
    h2 = plot(animal1.neuron{exampleCells(i)}.xN, animal1.neuron{exampleCells(i)}.yN, 'r.', 'MarkerSize', 7);
    xlabel('X Position');
    ylabel('Y Position');
    title(sprintf('Cell#%d', exampleCells(i)), 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
    set(gca, 'XTick', -1:0.5:1, 'YTick', -1:0.5:1);
    axis square;
    if i == 4
        legend([h1 h2], 'Animal Path', 'Location at time of spike');
    end
end
figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig01_example_cells_path_overlay');

% View summary statistics from precomputed fits.
numAnimals = 2;
clear summary;
for n = 1:numAnimals
    resData = load(fullfile(dataDir, sprintf('PlaceCellAnimal%dResults.mat', n)));
    fitResults = FitResult.fromStructure(resData.resStruct);
    summary{n} = FitResSummary(fitResults); %#ok<AGROW>
end

fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
maxLength = max([summary{1}.numNeurons, summary{2}.numNeurons]);

dKS = nan(maxLength, 2);
dKS(1:summary{1}.numNeurons, 1) = summary{1}.KSStats(:,1) - summary{1}.KSStats(:,2);
dKS(1:summary{2}.numNeurons, 2) = summary{2}.KSStats(:,1) - summary{2}.KSStats(:,2);
subplot(1,3,1);
boxplot(dKS, {'Animal 1', 'Animal 2'}, 'labelorientation', 'inline');
title('\Delta KS Statistic', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

dAIC = nan(maxLength, 2);
dAIC(1:summary{1}.numNeurons, 1) = summary{1}.getDiffAIC(1);
dAIC(1:summary{2}.numNeurons, 2) = summary{2}.getDiffAIC(1);
subplot(1,3,2);
boxplot(dAIC, {'Animal 1', 'Animal 2'}, 'labelorientation', 'inline');
title('\Delta AIC', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

dBIC = nan(maxLength, 2);
dBIC(1:summary{1}.numNeurons, 1) = summary{1}.getDiffBIC(1);
dBIC(1:summary{2}.numNeurons, 2) = summary{2}.getDiffBIC(1);
subplot(1,3,3);
boxplot(dBIC, {'Animal 1', 'Animal 2'}, 'labelorientation', 'inline');
title('\Delta BIC', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Arial');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig02_model_summary_statistics');

% Evaluate receptive fields on a regular grid.
[xGrid, yGrid] = meshgrid(-1:0.01:1);
yGrid = flipud(yGrid);
xGrid = fliplr(xGrid);
[thetaGrid, rGrid] = cart2pol(xGrid, yGrid);

newData = cell(1,6);
newData{1} = ones(size(xGrid));
newData{2} = xGrid;
newData{3} = yGrid;
newData{4} = xGrid .^ 2;
newData{5} = yGrid .^ 2;
newData{6} = xGrid .* yGrid;

idx = rGrid <= 1;
zpoly = cell(1,10);
cnt = 0;
for l = 0:3
    for m = -l:l
        if ~any(mod(l - m, 2))
            cnt = cnt + 1;
            temp = nan(size(xGrid));
            temp(idx) = zernfun(l, m, rGrid(idx), thetaGrid(idx), 'norm');
            zpoly{cnt} = temp;
        end
    end
end

figGaussianAnimal = gobjects(1, numAnimals);
figZernikeAnimal = gobjects(1, numAnimals);

for n = 1:numAnimals
    dataset = load(fullfile(placeCellDataDir, sprintf('PlaceCellDataAnimal%d.mat', n)));
    resData = load(fullfile(dataDir, sprintf('PlaceCellAnimal%dResults.mat', n)));
    fitResults = FitResult.fromStructure(resData.resStruct);

    clear lambdaGaussian lambdaZernike;
    for iCell = 1:length(dataset.neuron)
        lambdaGaussian{iCell} = fitResults{iCell}.evalLambda(1, newData); %#ok<AGROW>
        lambdaZernike{iCell} = fitResults{iCell}.evalLambda(2, zpoly); %#ok<AGROW>
    end

    if n == 1
        figGaussianAnimal(n) = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
        tileRows = 7; tileCols = 7;
    else
        figGaussianAnimal(n) = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
        tileRows = 6; tileCols = 7;
    end
    colormap(figGaussianAnimal(n), 'jet');
    for iCell = 1:length(dataset.neuron)
        subplot(tileRows, tileCols, iCell);
        pcolor(xGrid, yGrid, lambdaGaussian{iCell});
        shading interp;
        axis square;
        set(gca, 'XTick', [], 'YTick', [], 'Box', 'off');
    end
    sgtitle(sprintf('Gaussian Place Fields - Animal#%d', n), 'FontSize', 12, 'FontWeight', 'bold');

    if n == 1
        figZernikeAnimal(n) = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
        tileRows = 7; tileCols = 7;
    else
        figZernikeAnimal(n) = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
        tileRows = 6; tileCols = 7;
    end
    colormap(figZernikeAnimal(n), 'jet');
    for iCell = 1:length(dataset.neuron)
        subplot(tileRows, tileCols, iCell);
        pcolor(xGrid, yGrid, lambdaZernike{iCell});
        shading interp;
        axis square;
        set(gca, 'XTick', [], 'YTick', [], 'Box', 'off');
    end
    sgtitle(sprintf('Zernike Place Fields - Animal#%d', n), 'FontSize', 12, 'FontWeight', 'bold');

    if n == 1
        figureFiles = maybeExportFigure(figGaussianAnimal(n), figureFiles, opts, 'fig03_gaussian_place_fields_animal1');
        figureFiles = maybeExportFigure(figZernikeAnimal(n), figureFiles, opts, 'fig04_zernike_place_fields_animal1');
    else
        figureFiles = maybeExportFigure(figGaussianAnimal(n), figureFiles, opts, 'fig05_gaussian_place_fields_animal2');
        figureFiles = maybeExportFigure(figZernikeAnimal(n), figureFiles, opts, 'fig06_zernike_place_fields_animal2');
    end

    if n == 1
        lambdaGaussianAnimal1 = lambdaGaussian; %#ok<NASGU>
        lambdaZernikeAnimal1 = lambdaZernike; %#ok<NASGU>
    end
end

% Example-cell 3D comparison.
resData1 = load(fullfile(dataDir, 'PlaceCellAnimal1Results.mat'));
fitResults1 = FitResult.fromStructure(resData1.resStruct);

clear lambdaGaussianOne lambdaZernikeOne;
for iCell = 1:length(animal1.neuron)
    lambdaGaussianOne{iCell} = fitResults1{iCell}.evalLambda(1, newData); %#ok<AGROW>
    lambdaZernikeOne{iCell} = fitResults1{iCell}.evalLambda(2, zpoly); %#ok<AGROW>
end

exampleCell = 25;
fig = figure('Position', [100 100 opts.WidthPx opts.HeightPx]);
hMesh = mesh(xGrid, yGrid, lambdaGaussianOne{exampleCell});
set(hMesh, 'FaceAlpha', 0.2, 'EdgeAlpha', 0.2, 'EdgeColor', 'b');
hold on;
hMesh = mesh(xGrid, yGrid, lambdaZernikeOne{exampleCell});
set(hMesh, 'FaceAlpha', 0.2, 'EdgeAlpha', 0.2, 'EdgeColor', 'g');
plot3(animal1.x, animal1.y, zeros(size(animal1.x)), 'k');
plot3(animal1.neuron{exampleCell}.xN, animal1.neuron{exampleCell}.yN, zeros(size(animal1.neuron{exampleCell}.xN)), 'r.');
axis tight;
axis square;
xlabel('x position');
ylabel('y position');
title(sprintf('Animal#1, Cell#%d', exampleCell), 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
legend({'\lambda_{Gaussian}', '\lambda_{Zernike}', 'Animal Path', 'Spike Locations'}, 'Location', 'best');

figureFiles = maybeExportFigure(fig, figureFiles, opts, 'fig07_example_cell_mesh_comparison');

if opts.CloseFigures
    close all;
end

result = struct();
result.example_id = 'example04';
result.title = 'Place-Cell Receptive Fields (Gaussian vs Zernike)';
result.source_script = mfilename('fullpath');
result.description = [ ...
    'Loads place-cell datasets and precomputed fit results, compares Gaussian ', ...
    'and Zernike receptive-field models, and visualizes full population maps.'];
result.figure_files = figureFiles;
result.paper_mapping = 'Section 2.3.5; Figs. 7 and 13 (nSTAT paper, 2012).';

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'example04_place_cells_continuous_stimulus';
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
    error('example04:MissingExportDir', 'ExportDir must be provided when ExportFigures=true.');
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
