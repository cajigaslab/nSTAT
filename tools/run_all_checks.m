function status = run_all_checks(varargin)
%RUN_ALL_CHECKS Single local entrypoint for PR validation workflow.
%
% Syntax:
%   run_all_checks
%   run_all_checks('GenerateBaseline',true,'CheckParity',true)
%
% Steps (configurable):
%   1) Example smoke: nSTATPaperExamples capture
%   2) Baseline generation (optional)
%   3) Parity check against baseline (optional)
%   4) matlab.unittest test run if tests/ exists (optional)
%   5) Help/docs publish if helper exists (optional)

opts = parseOptions(varargin{:});

status = struct();
status.generatedAt = char(datetime('now','TimeZone','local','Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
status.generateBaseline = false;
status.parity = false;
status.tests = false;
status.docsPublish = false;

if opts.GenerateBaseline
    generate_baseline_fixtures('Seed', opts.Seed, 'Style', opts.Style, 'PublishHtml', true);
    status.generateBaseline = true;
end

if opts.CheckParity
    check_parity_against_baseline('Seed', opts.Seed, 'Style', opts.Style, ...
        'CheckPixels', opts.CheckPixels, 'NumericAbsTol', opts.NumericAbsTol, ...
        'NumericRelTol', opts.NumericRelTol, 'PixelMeanAbsTol', opts.PixelMeanAbsTol);
    status.parity = true;
end

if opts.RunTests
    if exist(fullfile(detectRootDir(), 'tests'), 'dir') == 7
        results = runtests('tests');
        assert(~any([results.Failed]), 'nstat:checks:TestsFailed', 'Unit tests failed.');
        status.tests = true;
    else
        warning('nstat:checks:NoTests', 'No tests directory found. Skipping tests stage.');
    end
end

if opts.PublishDocs
    rootDir = detectRootDir();
    publishFcn = fullfile(rootDir, 'helpfiles', 'publish_all_helpfiles.m');
    if exist(publishFcn, 'file') == 2
        run(publishFcn);
        status.docsPublish = true;
    else
        warning('nstat:checks:NoPublishScript', 'publish_all_helpfiles.m not found. Skipping docs publish stage.');
    end
end

fprintf('\nrun_all_checks complete.\n');
fprintf('  Generate baseline: %s\n', tf(status.generateBaseline));
fprintf('  Parity check     : %s\n', tf(status.parity));
fprintf('  Tests            : %s\n', tf(status.tests));
fprintf('  Docs publish     : %s\n', tf(status.docsPublish));

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'run_all_checks';
addParameter(parser, 'GenerateBaseline', false, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'CheckParity', true, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'RunTests', true, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'PublishDocs', false, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'CheckPixels', false, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(parser, 'Seed', 0, @(x)isnumeric(x) && isscalar(x));
addParameter(parser, 'Style', 'legacy', @(x)ischar(x) || (isstring(x) && isscalar(x)));
addParameter(parser, 'NumericAbsTol', 1e-8, @(x)isnumeric(x) && isscalar(x) && x >= 0);
addParameter(parser, 'NumericRelTol', 1e-6, @(x)isnumeric(x) && isscalar(x) && x >= 0);
addParameter(parser, 'PixelMeanAbsTol', 0, @(x)isnumeric(x) && isscalar(x) && x >= 0);
parse(parser, varargin{:});
opts = parser.Results;
opts.GenerateBaseline = logical(opts.GenerateBaseline);
opts.CheckParity = logical(opts.CheckParity);
opts.RunTests = logical(opts.RunTests);
opts.PublishDocs = logical(opts.PublishDocs);
opts.CheckPixels = logical(opts.CheckPixels);
opts.Style = char(string(opts.Style));
end

function rootDir = detectRootDir()
rootDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(rootDir);
end

function s = tf(v)
if v
    s = 'done';
else
    s = 'skipped';
end
end
