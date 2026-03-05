function applyPlotStyle(target, varargin)
%APPLYPLOTSTYLE Apply nSTAT plot style to an axes/figure/graphics handle.
%
% Syntax:
%   nstat.applyPlotStyle
%   nstat.applyPlotStyle(gca)
%   nstat.applyPlotStyle(gcf,'Style','legacy')
%
% Name-Value:
%   'Style' - 'legacy' or 'modern'. When omitted, uses nstat.getPlotStyle.

if nargin < 1 || isempty(target)
    if isempty(get(groot, 'CurrentFigure'))
        return;
    end
    target = gca;
end

parser = inputParser;
parser.FunctionName = 'nstat.applyPlotStyle';
addParameter(parser, 'Style', '', @(x)ischar(x) || (isstring(x) && isscalar(x)));
parse(parser, varargin{:});

style = char(string(parser.Results.Style));
if isempty(style)
    style = nstat.getPlotStyle;
else
    style = validateStyle(style);
end

if strcmp(style, 'legacy')
    return;
end

[axList, figList] = resolveTargets(target);
if isempty(axList) && isempty(figList)
    return;
end

for iFig = 1:numel(figList)
    try
        set(figList(iFig), 'Color', 'w');
    catch
    end
end

for iAx = 1:numel(axList)
    ax = axList(iAx);
    if ~isgraphics(ax, 'axes')
        continue;
    end

    try
        set(ax, ...
            'FontName', 'Helvetica', ...
            'FontSize', 10, ...
            'LineWidth', 1, ...
            'TickDir', 'out', ...
            'Layer', 'top');
    catch
    end

    try
        ln = findall(ax, 'Type', 'Line');
        for iLine = 1:numel(ln)
            lw = get(ln(iLine), 'LineWidth');
            if isempty(lw) || ~isnumeric(lw)
                continue;
            end
            if lw < 1.25
                set(ln(iLine), 'LineWidth', 1.25);
            end
            if strcmp(get(ln(iLine), 'Marker'), '.')
                set(ln(iLine), 'MarkerSize', max(get(ln(iLine), 'MarkerSize'), 9));
            end
        end
    catch
    end

    try
        sc = findall(ax, 'Type', 'Scatter');
        for iSc = 1:numel(sc)
            sz = get(sc(iSc), 'SizeData');
            if isempty(sz)
                continue;
            end
            set(sc(iSc), 'SizeData', max(sz, 30));
        end
    catch
    end

end

if ~isempty(figList)
    try
        lgd = findall(figList, 'Type', 'Legend');
        for iL = 1:numel(lgd)
            if isgraphics(lgd(iL), 'legend')
                set(lgd(iL), 'FontSize', 10, 'Box', 'off');
            end
        end
    catch
    end
end
end

function [axList, figList] = resolveTargets(target)
axList = gobjects(0);
figList = gobjects(0);

if isgraphics(target)
    target = target(:);
else
    return;
end

for i = 1:numel(target)
    t = target(i);
    if isgraphics(t, 'figure')
        figList(end+1,1) = t; %#ok<AGROW>
        ax = findall(t, 'Type', 'axes');
        if ~isempty(ax)
            axList = [axList; ax(:)]; %#ok<AGROW>
        end
    elseif isgraphics(t, 'axes')
        axList(end+1,1) = t; %#ok<AGROW>
        fig = ancestor(t, 'figure');
        if ~isempty(fig)
            figList(end+1,1) = fig; %#ok<AGROW>
        end
    else
        ax = ancestor(t, 'axes');
        if ~isempty(ax)
            axList(end+1,1) = ax; %#ok<AGROW>
            fig = ancestor(ax, 'figure');
            if ~isempty(fig)
                figList(end+1,1) = fig; %#ok<AGROW>
            end
        end
    end
end

if ~isempty(axList)
    axList = unique(axList(isgraphics(axList, 'axes')));
end
if ~isempty(figList)
    figList = unique(figList(isgraphics(figList, 'figure')));
end
end

function style = validateStyle(style)
style = lower(char(string(style)));
valid = {'legacy', 'modern'};
if ~any(strcmp(style, valid))
    error('nstat:plot:InvalidStyle', ...
        'Invalid plot style "%s". Valid styles: legacy, modern.', style);
end
end
