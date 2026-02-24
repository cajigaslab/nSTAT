function pagePath = nstatOpenHelpPage(pageName, openBrowser)
% nstatOpenHelpPage Open an nSTAT help page from command-window hyperlinks.
%
% Usage:
%   nstatOpenHelpPage('SignalObjExamples.html')
%   pagePath = nstatOpenHelpPage('SignalObjExamples.html', false)
%
% This helper resolves the nSTAT help folder path so links work regardless
% of the current working directory.

if nargin < 1 || isempty(pageName)
    error('nstatOpenHelpPage:MissingPage', ...
        'Provide a help page name such as ''SignalObjExamples.html''.');
end

if nargin < 2
    openBrowser = true;
end

rootDir = fileparts(which('nSTAT_Install'));
if isempty(rootDir)
    rootDir = fileparts(which('SignalObj'));
end

if isempty(rootDir)
    error('nstatOpenHelpPage:RootNotFound', ...
        'Could not resolve the nSTAT installation path.');
end

pagePath = fullfile(rootDir, 'helpfiles', pageName);
if ~isfile(pagePath)
    error('nstatOpenHelpPage:PageMissing', ...
        'Help page not found: %s', pagePath);
end

if openBrowser
    web(pagePath, '-browser');
end

end
