function opts = nSTAT_Install(varargin)
% nSTAT_Install Configure nSTAT MATLAB runtime paths and help integration.
%
% Usage:
%   nSTAT_Install
%   nSTAT_Install('RebuildDocSearch',true,'CleanUserPathPrefs',false)
%   nSTAT_Install('DownloadExampleData','prompt')
%   opts = nSTAT_Install(...)
%
% Name-value options:
%   RebuildDocSearch   (default true)  Rebuild help search DB in helpfiles/.
%   CleanUserPathPrefs (default false) Remove stale user MATLAB path entries.
%   DownloadExampleData (default 'prompt') Prompt, download, or skip the
%                     external figshare paper-example data package. Accepts
%                     true/'always', false/'never', or 'prompt'.
%
% This installer excludes non-runtime trees (python, cache folders, hidden
% folders) from the MATLAB path to avoid shadowing.

%
% nSTAT v1 Copyright (C) 2012 Masschusetts Institute of Technology
% Cajigas, I, Malik, WQ, Brown, EN
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License as published
% by the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software Foundation,
% Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

opts = parseInstallOptions(varargin{:});

fileLocation = mfilename('fullpath');
rootDir = fileparts(fileLocation);
helpDir = fullfile(rootDir, 'helpfiles');

display('Configuring nSTAT MATLAB runtime search path');
removeExistingRootPaths(rootDir);
maybeInstallExampleData(rootDir, opts.DownloadExampleData);
runtimePaths = collectRuntimePaths(rootDir);
if isempty(runtimePaths)
    warning('nSTAT:EmptyRuntimePath', ...
        'No runtime MATLAB paths were discovered under %s', rootDir);
else
    addpath(runtimePaths{:}, '-begin');
end

if opts.RebuildDocSearch
    if isfolder(helpDir)
        display('Building nSTAT help search database');
        builddocsearchdb(helpDir);
    else
        warning('nSTAT:MissingHelpFolder', ...
            'Help folder was not found at: %s', helpDir);
    end
end

if opts.CleanUserPathPrefs
    cleanupFcn = 'cleanup_user_path_prefs';
    cleanupFile = fullfile(rootDir, 'tools', 'matlab', [cleanupFcn '.m']);
    if exist(cleanupFcn, 'file') == 2
        feval(cleanupFcn, rootDir);
    elseif isfile(cleanupFile)
        addpath(fileparts(cleanupFile), '-begin');
        if exist(cleanupFcn, 'file') == 2
            feval(cleanupFcn, rootDir);
        else
            warning('nSTAT:CleanupFunctionUnavailable', ...
                'Could not invoke %s after running %s', cleanupFcn, cleanupFile);
        end
    else
        warning('nSTAT:MissingCleanupScript', ...
            'Cleanup script not found: %s', cleanupFile);
    end
end

display('Refreshing MATLAB toolbox cache');
rehash toolboxcache;

display('Saving path');
savepath;
end

function opts = parseInstallOptions(varargin)
parser = inputParser;
parser.FunctionName = 'nSTAT_Install';
addParameter(parser, 'RebuildDocSearch', true, @(x)islogical(x) || isnumeric(x));
addParameter(parser, 'CleanUserPathPrefs', false, @(x)islogical(x) || isnumeric(x));
addParameter(parser, 'DownloadExampleData', 'prompt', ...
    @(x)islogical(x) || isnumeric(x) || ischar(x) || (isstring(x) && isscalar(x)));
parse(parser, varargin{:});

opts.RebuildDocSearch = logical(parser.Results.RebuildDocSearch);
opts.CleanUserPathPrefs = logical(parser.Results.CleanUserPathPrefs);
opts.DownloadExampleData = normalizeDownloadMode(parser.Results.DownloadExampleData);
end

function mode = normalizeDownloadMode(rawMode)
if islogical(rawMode) || (isnumeric(rawMode) && isscalar(rawMode))
    if logical(rawMode)
        mode = 'always';
    else
        mode = 'never';
    end
    return;
end

mode = lower(char(string(rawMode)));
switch mode
    case {'always', 'prompt', 'never'}
        return;
    otherwise
        error('nSTAT:InvalidDownloadMode', ...
            'DownloadExampleData must be true/false or one of: always, prompt, never.');
end
end

function removeExistingRootPaths(rootDir)
pathEntries = strsplit(path, pathsep);
isRepoPath = startsWith(pathEntries, rootDir);
toRemove = unique(pathEntries(isRepoPath));
toRemove = toRemove(cellfun(@(p)~isempty(p) && isfolder(p), toRemove));
if ~isempty(toRemove)
    rmpath(toRemove{:});
end
end

function runtimePaths = collectRuntimePaths(rootDir)
rawPath = strsplit(genpath(rootDir), pathsep);
runtimePaths = {};
for iDir = 1:numel(rawPath)
    dirPath = rawPath{iDir};
    if isempty(dirPath) || ~isfolder(dirPath)
        continue;
    end
    relPath = strrep(dirPath, [rootDir filesep], '');
    if strcmp(dirPath, rootDir)
        runtimePaths{end+1} = dirPath; %#ok<AGROW>
        continue;
    end
    if shouldExcludePath(relPath)
        continue;
    end
    hasMatlabFiles = ~isempty(dir(fullfile(dirPath, '*.m')));
    hasDataFiles = ~isempty(dir(fullfile(dirPath, '*.mat')));
    hasClassFolders = ~isempty(dir(fullfile(dirPath, '@*')));
    hasPackageFolders = ~isempty(dir(fullfile(dirPath, '+*')));
    if hasMatlabFiles || hasDataFiles || hasClassFolders || hasPackageFolders
        runtimePaths{end+1} = dirPath; %#ok<AGROW>
    end
end
runtimePaths = unique(runtimePaths, 'stable');
end

function tf = shouldExcludePath(relPath)
if isempty(relPath)
    tf = false;
    return;
end
segments = strsplit(relPath, filesep);
segments = segments(~cellfun(@isempty, segments));
if isempty(segments)
    tf = false;
    return;
end

excludedExact = { ...
    '.git', '.github', 'python', 'slprj', 'porting', ...
    '__pycache__', '.pytest_cache', '.mypy_cache', '.vscode', '.idea'};
tf = false;
for iSeg = 1:numel(segments)
    seg = segments{iSeg};
    if startsWith(seg, '.')
        tf = true;
        return;
    end
    if any(strcmpi(seg, excludedExact))
        tf = true;
        return;
    end
end
end

function maybeInstallExampleData(rootDir, mode)
info = nSTAT_ExampleDataInfo(rootDir);
if info.isInstalled
    display('nSTAT example data already present');
    return;
end

shouldDownload = false;
switch mode
    case 'always'
        shouldDownload = true;
    case 'never'
        warning('nSTAT:ExampleDataMissing', ...
            ['nSTAT example data was not found under %s. ', ...
             'Run nSTAT_Install(''DownloadExampleData'',true) to install it.'], ...
            info.dataDir);
    case 'prompt'
        shouldDownload = shouldPromptForExampleData(info);
    otherwise
        error('nSTAT:InvalidDownloadModeInternal', ...
            'Unsupported download mode: %s', mode);
end

if shouldDownload
    downloadExampleData(rootDir, info);
end
end

function tf = shouldPromptForExampleData(info)
message = sprintf([ ...
    'nSTAT example data was not found.\n\n', ...
    'Download the paper-example dataset from figshare and install it into:\n%s\n\n', ...
    'Dataset DOI: %s'], info.dataDir, info.figshareDoi);

if usejava('desktop') && feature('ShowFigureWindows')
    choice = questdlg(message, 'Install nSTAT Example Data', ...
        'Download', 'Skip', 'Download');
    tf = strcmp(choice, 'Download');
    if ~tf
        warning('nSTAT:ExampleDataSkipped', ...
            ['nSTAT example data is still missing. ', ...
             'Run nSTAT_Install(''DownloadExampleData'',true) to install it later.']);
    end
    return;
end

warning('nSTAT:ExampleDataPromptUnavailable', ...
    ['nSTAT example data is missing, but interactive prompting is unavailable. ', ...
     'Run nSTAT_Install(''DownloadExampleData'',true) to install it.']);
tf = false;
end

function downloadExampleData(rootDir, info)
display('Querying figshare metadata for nSTAT example data');
article = webread(info.figshareApiUrl, weboptions('Timeout', 60));
fileEntry = selectExampleDataFile(article);

archivePath = fullfile(tempdir, ['nstat_example_data_' char(java.util.UUID.randomUUID) '.zip']);
cleanupObj = onCleanup(@()deleteTempFile(archivePath)); %#ok<NASGU>

display(sprintf('Downloading nSTAT example data archive (%.1f MB)', fileEntry.size / 1e6));
downloadFile(fileEntry.download_url, archivePath);

if isfield(fileEntry, 'supplied_md5') && ~isempty(fileEntry.supplied_md5)
    localMd5 = computeFileMd5(archivePath);
    if ~strcmpi(localMd5, fileEntry.supplied_md5)
        error('nSTAT:ExampleDataChecksumMismatch', ...
            'Downloaded example data MD5 mismatch. Expected %s, got %s.', ...
            fileEntry.supplied_md5, localMd5);
    end
end

if exist(info.dataDir, 'dir') ~= 7
    mkdir(info.dataDir);
end

display('Extracting nSTAT example data archive');
unzip(archivePath, rootDir);

installedInfo = nSTAT_ExampleDataInfo(rootDir);
if ~installedInfo.isInstalled
    error('nSTAT:ExampleDataInstallIncomplete', ...
        ['Example data download completed, but the required files were not found ', ...
         'under %s after extraction.'], installedInfo.dataDir);
end

display(sprintf('Installed nSTAT example data into %s', installedInfo.dataDir));
end

function fileEntry = selectExampleDataFile(article)
if ~isfield(article, 'files') || isempty(article.files)
    error('nSTAT:ExampleDataNoFiles', ...
        'The figshare dataset metadata did not contain any downloadable files.');
end

fileEntry = article.files(1);
for iFile = 1:numel(article.files)
    candidate = article.files(iFile);
    if endsWith(lower(candidate.name), '.zip')
        fileEntry = candidate;
        return;
    end
end
end

function md5Hex = computeFileMd5(filePath)
if ismac
    [status, output] = system(sprintf('md5 -q %s', shellQuote(filePath)));
    if status == 0
        md5Hex = strtrim(lower(output));
        return;
    end
elseif isunix
    [status, output] = system(sprintf('md5sum %s', shellQuote(filePath)));
    if status == 0
        tokens = regexp(strtrim(output), '^(?<hash>[0-9a-fA-F]+)\s+', 'names', 'once');
        if ~isempty(tokens)
            md5Hex = lower(tokens.hash);
            return;
        end
    end
elseif ispc
    [status, output] = system(sprintf('certutil -hashfile "%s" MD5', filePath));
    if status == 0
        tokens = regexp(output, '([0-9A-Fa-f]{32})', 'tokens', 'once');
        if ~isempty(tokens)
            md5Hex = lower(tokens{1});
            return;
        end
    end
end

import java.io.FileInputStream
import java.security.DigestInputStream
import java.security.MessageDigest

digest = MessageDigest.getInstance('MD5');
stream = DigestInputStream(FileInputStream(filePath), digest);
cleanupObj = onCleanup(@()stream.close()); %#ok<NASGU>

while stream.read() ~= -1
end

hashBytes = typecast(int8(digest.digest()), 'uint8');
md5Hex = lower(reshape(dec2hex(hashBytes)', 1, []));
end

function deleteTempFile(pathStr)
if exist(pathStr, 'file') == 2
    delete(pathStr);
end
end

function downloadFile(url, destinationPath)
if isunix || ismac
    [curlStatus, ~] = system('command -v curl');
    if curlStatus == 0
        command = sprintf('curl -L --fail --silent --show-error -o %s %s', ...
            shellQuote(destinationPath), shellQuote(url));
        status = system(command);
        if status == 0
            return;
        end
    end
end

websave(destinationPath, url, weboptions('Timeout', 900));
end

function quoted = shellQuote(pathStr)
quoted = ['''' strrep(pathStr, '''', '''"''"''') ''''];
end
