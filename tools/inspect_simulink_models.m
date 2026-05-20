function inspect_simulink_models(varargin)
%INSPECT_SIMULINK_MODELS  Walk every Simulink model in nSTAT and export each
% subsystem level to PNG plus a structural text dump. Headless. Idempotent.
%
% Usage:
%   inspect_simulink_models                                    % run from repo root
%   inspect_simulink_models('OutDir','/tmp/simout')

p = inputParser;
p.addParameter('OutDir',fullfile(pwd,'docs','figures','simulink'),@ischar);
p.parse(varargin{:});
outDir = p.Results.OutDir;
if ~exist(outDir,'dir'); mkdir(outDir); end

% Newest variant of each distinct model
models = {
    'PointProcessSimulation.slx', ...
    'PointProcessSimulationCont.slx', ...
    'PointProcessSimulationThinning.mdl.r2011a' ...
};

summary = struct();

for k = 1:numel(models)
    modelFile = models{k};
    if ~exist(modelFile,'file')
        fprintf('SKIP (missing): %s\n', modelFile);
        continue;
    end
    [~,baseName,~] = fileparts(modelFile);
    baseName = regexprep(baseName,'\.mdl$','');
    modelDir = fullfile(outDir, baseName);
    if ~exist(modelDir,'dir'); mkdir(modelDir); end

    fprintf('\n=== %s ===\n', modelFile);
    % Suppress autosave / version mismatch warnings on legacy .mdl loads
    w = warning('off','all'); cleanW = onCleanup(@() warning(w));

    try
        mdl = load_system(modelFile);
    catch ME
        fprintf('  LOAD FAILED: %s\n', ME.message);
        continue;
    end
    mdlName = get_param(mdl,'Name');

    % All subsystems (depth-first), include the root
    systems = find_system(mdlName, 'LookUnderMasks','all', ...
                          'FollowLinks','on', 'BlockType','SubSystem');
    levels = [{mdlName}; systems(:)];

    fprintf('  Levels found: %d\n', numel(levels));
    levelInfo = repmat(struct('path','','blocks',[],'png',''), numel(levels), 1);

    for i = 1:numel(levels)
        sysPath = levels{i};
        safeName = regexprep(sysPath,'[/\\:?"<>|]','_');
        safeName = regexprep(safeName,'\s+','_');
        if length(safeName) > 120; safeName = safeName(1:120); end
        pngPath = fullfile(modelDir, sprintf('level%02d_%s.png', i, safeName));

        % Block inventory at this level (immediate children only)
        children = find_system(sysPath,'SearchDepth',1, ...
                               'LookUnderMasks','all','FollowLinks','on');
        children(strcmp(children,sysPath)) = [];   % drop self
        childTypes = cell(numel(children),1);
        for c = 1:numel(children)
            try
                childTypes{c} = sprintf('%s [%s]', get_param(children{c},'Name'), ...
                                                    get_param(children{c},'BlockType'));
            catch
                childTypes{c} = children{c};
            end
        end

        % Export PNG
        try
            print(['-s' sysPath], '-dpng', '-r150', pngPath);
            fprintf('    [%2d] %s  -> %s\n', i, sysPath, pngPath);
        catch ME
            fprintf('    [%2d] %s  PRINT FAILED: %s\n', i, sysPath, ME.message);
            pngPath = '';
        end

        levelInfo(i).path   = sysPath;
        levelInfo(i).blocks = childTypes;
        levelInfo(i).png    = pngPath;
    end

    % Text dump
    txtPath = fullfile(modelDir, 'structure.txt');
    fid = fopen(txtPath,'w');
    fprintf(fid,'Model: %s\n', modelFile);
    fprintf(fid,'Levels: %d\n\n', numel(levels));
    for i = 1:numel(levels)
        fprintf(fid,'\n[Level %d] %s\n', i, levelInfo(i).path);
        fprintf(fid,'  %d immediate children:\n', numel(levelInfo(i).blocks));
        for c = 1:numel(levelInfo(i).blocks)
            fprintf(fid,'    - %s\n', levelInfo(i).blocks{c});
        end
    end
    fclose(fid);
    fprintf('  Wrote %s\n', txtPath);

    summary.(matlab.lang.makeValidName(baseName)) = levelInfo;

    try
        close_system(mdl, 0);
    catch
    end
end

save(fullfile(outDir,'inspection_summary.mat'),'summary','-v7.3');
fprintf('\nAll done. Outputs in: %s\n', outDir);
end
