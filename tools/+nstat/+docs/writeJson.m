function writeJson(pathStr, data)
%WRITEJSON Write a MATLAB value to JSON with pretty formatting.
%
% Syntax:
%   nstat.docs.writeJson(pathStr, data)
%
% Inputs:
%   pathStr - Output file path.
%   data    - MATLAB value encodable by `jsonencode`.

arguments
    pathStr (1,:) char
    data
end

parentDir = fileparts(pathStr);
if ~isempty(parentDir) && exist(parentDir, 'dir') ~= 7
    mkdir(parentDir);
end

fid = fopen(pathStr, 'w');
if fid < 0
    error('nstat:docs:WriteJsonFailed', 'Could not open %s for writing.', pathStr);
end
cleanObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s\n', jsonencode(data, 'PrettyPrint', true));
end
