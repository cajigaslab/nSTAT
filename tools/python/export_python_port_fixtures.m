function export_python_port_fixtures(varargin)
%EXPORT_PYTHON_PORT_FIXTURES Export MATLAB-derived fixtures into nSTAT-python.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
pythonRepo = fullfile(fileparts(rootDir), 'nSTAT-python');
matlabRepo = rootDir;

if nargin >= 1 && ~isempty(varargin{1})
    pythonRepo = char(string(varargin{1}));
end
if nargin >= 2 && ~isempty(varargin{2})
    matlabRepo = char(string(varargin{2}));
end

if exist(pythonRepo, 'dir') ~= 7
    error('export_python_port_fixtures:MissingPythonRepo', ...
        'Expected Python port repository at %s', pythonRepo);
end

helperDir = fullfile(pythonRepo, 'tools', 'parity', 'matlab');
if exist(helperDir, 'dir') ~= 7
    error('export_python_port_fixtures:MissingHelperDir', ...
        'Expected MATLAB fixture helper directory at %s', helperDir);
end

addpath(helperDir);
export_matlab_gold_fixtures(pythonRepo, matlabRepo);
end

