function info = nSTAT_ExampleDataInfo(rootDir)
%NSTAT_EXAMPLEDATAINFO Describe the external nSTAT example data package.
%
% Syntax:
%   info = nSTAT_ExampleDataInfo()
%   info = nSTAT_ExampleDataInfo(rootDir)
%
% Input:
%   rootDir - Absolute path to the nSTAT repository root. If omitted, the
%             function resolves the root from `nSTAT_Install.m`.
%
% Output:
%   info - Struct describing the external figshare dataset and the local
%          files that indicate a complete installation.

if nargin < 1 || isempty(rootDir)
    installPath = which('nSTAT_Install');
    if isempty(installPath)
        error('nSTAT:ExampleData:MissingInstallPath', ...
            'Could not locate nSTAT_Install.m on the MATLAB path.');
    end
    rootDir = fileparts(installPath);
end

info = struct();
info.rootDir = rootDir;
info.dataDir = fullfile(rootDir, 'data');
info.figshareApiUrl = 'https://api.figshare.com/v2/articles/4834640';
info.figshareDoi = 'https://doi.org/10.6084/m9.figshare.4834640.v3';
info.paperDoi = 'https://doi.org/10.1016/j.jneumeth.2012.08.009';
info.requiredFiles = { ...
    fullfile(info.dataDir, 'mEPSCs', 'epsc2.txt')
    fullfile(info.dataDir, 'Explicit Stimulus', 'Dir3', 'Neuron1', 'Stim2', 'trngdataBis.mat')
    fullfile(info.dataDir, 'PSTH', 'Results.mat')
    fullfile(info.dataDir, 'Place Cells', 'PlaceCellDataAnimal1.mat')
    fullfile(info.dataDir, 'PlaceCellAnimal1Results.mat')
    fullfile(info.dataDir, 'SSGLMExampleData.mat')};
info.isInstalled = all(cellfun(@(pathStr) exist(pathStr, 'file') == 2, info.requiredFiles));
end
