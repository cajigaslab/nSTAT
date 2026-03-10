function export_python_port_fixtures(varargin)
%EXPORT_PYTHON_PORT_FIXTURES Export MATLAB-derived fixtures into nSTAT-python.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
pythonRepo = fullfile(fileparts(rootDir), 'nSTAT-python');
matlabRepo = rootDir;
fixtureNames = {};

if nargin >= 1 && ~isempty(varargin{1})
    pythonRepo = char(string(varargin{1}));
end
if nargin >= 2 && ~isempty(varargin{2})
    matlabRepo = char(string(varargin{2}));
end
if nargin >= 3 && ~isempty(varargin{3})
    fixtureNames = normalize_fixture_names(varargin{3});
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
export_matlab_gold_fixtures(pythonRepo, matlabRepo, fixtureNames);
end

function names = normalize_fixture_names(value)
if ischar(value) || isstring(value)
    names = cellstr(string(value));
elseif iscell(value)
    names = cellfun(@char, cellstr(string(value)), 'UniformOutput', false);
else
    error('export_python_port_fixtures:InvalidFixtureNames', ...
        'Fixture selector must be a string, string array, or cell array of strings.');
end
end
