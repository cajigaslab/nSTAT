function pagePath = nstatOpenHelpPage(pageName, openBrowser)
% nstatOpenHelpPage Open an nSTAT help page in the system browser.
%
%   nstatOpenHelpPage('Examples')
%   nstatOpenHelpPage('SignalObjExamples.html')
%   pagePath = nstatOpenHelpPage('Examples', false)
%
%   The .html extension is appended automatically when omitted, so both
%   nstatOpenHelpPage('Examples') and nstatOpenHelpPage('Examples.html')
%   are equivalent.
%
%   This helper resolves the nSTAT helpfiles folder path so that links
%   work regardless of the current working directory.
%
%   See also nSTAT_Install, Contents

if nargin < 1 || isempty(pageName)
    error('nstatOpenHelpPage:MissingPage', ...
        'Provide a help page name such as ''Examples'' or ''Examples.html''.');
end

if nargin < 2
    openBrowser = true;
end

% Append .html if no extension provided
[~, ~, ext] = fileparts(pageName);
if isempty(ext)
    pageName = [pageName '.html'];
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
