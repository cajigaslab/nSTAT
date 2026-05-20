function inspect_thinning_only()
%INSPECT_THINNING_ONLY  Walk PointProcessSimulationThinning.mdl and export each
% subsystem level to PNG with a structure dump.

repoRoot = '/Users/iahncajigas/projects/nstat';
cd(repoRoot);
outDir = fullfile(repoRoot,'docs','figures','simulink','PointProcessSimulationThinning');
if ~exist(outDir,'dir'); mkdir(outDir); end

w = warning('off','all'); cleanW = onCleanup(@() warning(w)); %#ok<NASGU>

modelFile = fullfile(repoRoot,'PointProcessSimulationThinning.mdl');
fprintf('Loading: %s\n', modelFile);
mdl = load_system(modelFile);
name = get_param(mdl,'Name');
fprintf('Model name: %s\n', name);

systems = find_system(name,'LookUnderMasks','all','FollowLinks','on','BlockType','SubSystem');
levels = [{name}; systems(:)];
fprintf('Levels: %d\n', numel(levels));

fid = fopen(fullfile(outDir,'structure.txt'),'w');
fprintf(fid,'Model: PointProcessSimulationThinning.mdl\nLevels: %d\n', numel(levels));

for i=1:numel(levels)
    sp = levels{i};
    safe = regexprep(sp,'[/\\:?"<>|]','_');
    safe = regexprep(safe,'\s+','_');
    if length(safe)>120, safe = safe(1:120); end
    png = fullfile(outDir,sprintf('level%02d_%s.png',i,safe));
    ch = find_system(sp,'SearchDepth',1,'LookUnderMasks','all','FollowLinks','on');
    ch(strcmp(ch,sp)) = [];
    fprintf(fid,'\n[Level %d] %s\n  %d immediate children:\n', i, sp, numel(ch));
    for c=1:numel(ch)
        try
            fprintf(fid,'    - %s [%s]\n', get_param(ch{c},'Name'), get_param(ch{c},'BlockType'));
        catch
            fprintf(fid,'    - %s\n', ch{c});
        end
    end
    try
        print(['-s' sp], '-dpng','-r150', png);
        fprintf('  [%2d] %s -> %s\n', i, sp, png);
    catch ME
        fprintf('  [%2d] %s PRINT FAILED: %s\n', i, sp, ME.message);
    end
end
fclose(fid);
try; close_system(mdl,0); catch; end
fprintf('Done.\n');
end
