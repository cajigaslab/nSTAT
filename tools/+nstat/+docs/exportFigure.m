function fileInfo = exportFigure(figHandle, outputBase, varargin)
%EXPORTFIGURE Export a figure with deterministic size and rendering options.
%
% Syntax:
%   fileInfo = nstat.docs.exportFigure(figHandle, outputBase)
%   fileInfo = nstat.docs.exportFigure(..., 'Resolution', 300, 'ExportSvg', true)
%
% Inputs:
%   figHandle  - Figure handle to export.
%   outputBase - Output path without extension.
%
% Name-Value Options:
%   Resolution - PNG export DPI (default: 250).
%   WidthPx    - Figure width in pixels (default: 1400).
%   HeightPx   - Figure height in pixels (default: 900).
%   ExportSvg  - Also export SVG vector output (default: false).
%
% Output:
%   fileInfo - Struct with exported file paths.

parser = inputParser;
parser.FunctionName = 'nstat.docs.exportFigure';
addParameter(parser, 'Resolution', 250, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'WidthPx', 1400, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'HeightPx', 900, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'ExportSvg', false, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
parse(parser, varargin{:});
opts = parser.Results;
opts.ExportSvg = logical(opts.ExportSvg);

if ~ishghandle(figHandle, 'figure')
    error('nstat:docs:InvalidFigureHandle', 'figHandle must be a valid figure handle.');
end

outDir = fileparts(outputBase);
if ~isempty(outDir) && exist(outDir, 'dir') ~= 7
    mkdir(outDir);
end

set(figHandle, 'Color', 'w', 'InvertHardcopy', 'off');
set(figHandle, 'Units', 'pixels');
set(figHandle, 'Position', [100 100 opts.WidthPx opts.HeightPx]);

axesHandles = findall(figHandle, 'Type', 'axes');
for iAx = 1:numel(axesHandles)
    try
        axesHandles(iAx).Toolbar.Visible = 'off';
    catch
        % Older graphics objects may not expose a Toolbar property.
    end
end

drawnow;

pngPath = [outputBase '.png'];
exportgraphics(figHandle, pngPath, 'Resolution', opts.Resolution, 'BackgroundColor', 'white');

fileInfo = struct();
fileInfo.png = pngPath;
fileInfo.svg = '';

if opts.ExportSvg
    svgPath = [outputBase '.svg'];
    exportgraphics(figHandle, svgPath, 'BackgroundColor', 'white', 'ContentType', 'vector');
    fileInfo.svg = svgPath;
end
end
