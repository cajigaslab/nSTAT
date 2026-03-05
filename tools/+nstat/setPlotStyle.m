function style = setPlotStyle(style)
%SETPLOTSTYLE Set global nSTAT plotting style preference.
%
% Syntax:
%   nstat.setPlotStyle
%   nstat.setPlotStyle('legacy')
%   style = nstat.setPlotStyle('modern')
%
% Inputs:
%   style - 'legacy' or 'modern'. Defaults to 'modern'.
%
% Output:
%   style - normalized style value that was saved.

if nargin < 1 || isempty(style)
    style = 'modern';
end

style = validateStyle(style);
setpref('nstat', 'PlotStyle', style);
end

function style = validateStyle(style)
style = lower(char(string(style)));
valid = {'legacy', 'modern'};
if ~any(strcmp(style, valid))
    error('nstat:plot:InvalidStyle', ...
        'Invalid plot style "%s". Valid styles: legacy, modern.', style);
end
end

