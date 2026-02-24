
repo = '/Users/iahncajigas/Library/CloudStorage/Dropbox/Research/Matlab/nSTAT_currentRelease_Local';
inFile = '/Users/iahncajigas/Library/CloudStorage/Dropbox/Research/Matlab/nSTAT_currentRelease_Local/python/reports/matlab_smoke_input.json';
outFile = '/Users/iahncajigas/Library/CloudStorage/Dropbox/Research/Matlab/nSTAT_currentRelease_Local/python/reports/matlab_smoke_output.json';
set(0,'DefaultFigureVisible','off');
cfg = jsondecode(fileread(inFile));
n = numel(cfg);
res = repmat(struct('source','','ok',false,'message',''), n, 1);
for i = 1:n
    src = '';
    kind = '';
    fn = '';
    if isfield(cfg(i), 'source')
        src = char(cfg(i).source);
    end
    if isfield(cfg(i), 'kind')
        kind = char(cfg(i).kind);
    end
    if isfield(cfg(i), 'function_name')
        fn = char(cfg(i).function_name);
    end
    try
        restoredefaultpath;
        cd(repo);
        addpath(genpath(repo),'-begin');
        if strcmp(kind,'script')
            run(fullfile(repo, src));
        else
            feval(fn);
        end
        res(i).ok = true;
        res(i).message = 'ok';
    catch ME
        res(i).ok = false;
        res(i).message = [ME.identifier ' | ' ME.message];
    end
    res(i).source = src;
end
fid = fopen(outFile,'w');
fprintf(fid,'%s',jsonencode(res));
fclose(fid);
exit(0);
