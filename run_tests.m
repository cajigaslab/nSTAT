function results = run_tests(varargin)
%RUN_TESTS Run nSTAT matlab.unittest suite.
%
% Syntax:
%   run_tests
%   results = run_tests('IncludeParity',true)
%
% Name-Value:
%   IncludeParity - Run fixture-backed parity integration tests (default true)
%   OutputXml     - Path to JUnit XML output file (default test-results/results.xml)
%
% Output:
%   results - matlab.unittest result array

opts = parseOptions(varargin{:});

rootDir = fileparts(mfilename('fullpath'));
addpath(fullfile(rootDir, 'tools'));
cd(rootDir);

if ~opts.IncludeParity
    setenv('NSTAT_SKIP_PARITY_TESTS', '1');
else
    setenv('NSTAT_SKIP_PARITY_TESTS', '0');
end

suite = testsuite(fullfile(rootDir, 'tests'), 'IncludeSubfolders', true);
runner = matlab.unittest.TestRunner.withTextOutput('OutputDetail', matlab.unittest.Verbosity.Detailed);

xmlPath = opts.OutputXml;
xmlDir = fileparts(xmlPath);
if ~isempty(xmlDir) && exist(xmlDir, 'dir') ~= 7
    mkdir(xmlDir);
end
runner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat(xmlPath));

results = runner.run(suite);

if any([results.Failed])
    failed = sum([results.Failed]);
    error('nstat:tests:Failed', 'MATLAB tests failed (%d failing tests).', failed);
end
end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'run_tests';
addParameter(parser, 'IncludeParity', true, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'OutputXml', fullfile('test-results', 'results.xml'), @(x)ischar(x) || (isstring(x) && isscalar(x)));
parse(parser, varargin{:});

opts = parser.Results;
opts.IncludeParity = logical(opts.IncludeParity);
opts.OutputXml = char(string(opts.OutputXml));
end

