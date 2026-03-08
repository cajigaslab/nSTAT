function [pe, pythonRepo] = setup_python_for_nstat_tests(varargin)
%SETUP_PYTHON_FOR_NSTAT_TESTS Configure MATLAB to import the Python nSTAT port.

pythonVersion = '';
if nargin >= 1 && ~isempty(varargin{1})
    pythonVersion = char(string(varargin{1}));
end

thisFile = mfilename('fullpath');
rootDir = fileparts(fileparts(fileparts(thisFile)));
pythonRepo = fullfile(fileparts(rootDir), 'nSTAT-python');
if exist(pythonRepo, 'dir') ~= 7
    error('setup_python_for_nstat_tests:MissingPythonRepo', ...
        'Expected Python port repository at %s', pythonRepo);
end

addpath(rootDir);
addpath(fullfile(rootDir, 'helpfiles'));

selectedPython = pythonVersion;
if isempty(selectedPython)
    selectedPython = localDiscoverPython();
end

pe = pyenv;
if strlength(string(pe.Status)) == 0 || strcmpi(string(pe.Status), "NotLoaded")
    if ~isempty(selectedPython)
        pe = pyenv('Version', selectedPython);
    else
        pe = pyenv;
    end
end

if isempty(selectedPython)
    selectedPython = char(string(pe.Version));
end

escapedRepo = strrep(pythonRepo, '\', '\\');
code = strjoin({ ...
    'import importlib', ...
    'import sys', ...
    sprintf('repo = r''%s''', escapedRepo), ...
    'if repo not in sys.path:', ...
    '    sys.path.insert(0, repo)', ...
    'importlib.import_module(''sympy'')', ...
    'importlib.import_module(''nstat'')' ...
    }, newline);
try
    pyrun(code);
catch err
    if ~isempty(selectedPython) && ~(strlength(string(pe.Status)) == 0 || strcmpi(string(pe.Status), "NotLoaded"))
        error('setup_python_for_nstat_tests:PythonAlreadyLoaded', ...
            ['MATLAB is already bound to a Python runtime that cannot import the ' ...
             'nSTAT Python port dependencies. Restart MATLAB and call pyenv(''Version'', ''%s'') ' ...
             'before loading Python, or rerun setup_python_for_nstat_tests(''%s'').'], ...
            selectedPython, selectedPython);
    end
    rethrow(err);
end
pe = pyenv;
end

function pythonVersion = localDiscoverPython()
pythonVersion = '';

envPython = getenv('NSTAT_PYTHON');
if ~isempty(envPython)
    pythonVersion = char(string(envPython));
    return;
end

[status, output] = system("python -c ""import sys, sympy; print(sys.executable)""");
if status == 0
    pythonVersion = strtrim(output);
end
end
