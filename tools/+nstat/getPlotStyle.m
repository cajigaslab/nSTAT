function style = getPlotStyle(varargin)
%GETPLOTSTYLE Get global nSTAT plotting style preference.
%
% Syntax:
%   style = nstat.getPlotStyle
%   style = nstat.getPlotStyle('Default','legacy')
%
% Name-Value:
%   'Default' - fallback style when no preference is set (default 'modern').
%
% Output:
%   style - 'legacy' or 'modern'

parser = inputParser;
parser.FunctionName = 'nstat.getPlotStyle';
addParameter(parser, 'Default', 'modern', @(x)ischar(x) || (isstring(x) && isscalar(x)));
parse(parser, varargin{:});

defaultStyle = validateStyle(parser.Results.Default);
style = defaultStyle;

if ispref('nstat', 'PlotStyle')
    try
        style = validateStyle(getpref('nstat', 'PlotStyle'));
    catch
        style = defaultStyle;
    end
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

