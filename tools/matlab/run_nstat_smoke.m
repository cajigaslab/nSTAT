%% run_nstat_smoke
% Automated smoke checks for core nSTAT MATLAB classes and path resolution.

scriptPath = mfilename('fullpath');
rootDir = fileparts(fileparts(fileparts(scriptPath)));

restoredefaultpath;
addpath(rootDir, '-begin');
nSTAT_Install('RebuildDocSearch', false, 'CleanUserPathPrefs', false);

failures = {};

runCheck('SignalObj', @() checkSignalObj());
runCheck('Covariate', @() checkCovariate());
runCheck('ConfidenceInterval', @() checkConfidenceInterval());
runCheck('Events', @() checkEvents());
runCheck('History', @() checkHistory());
runCheck('nspikeTrain', @() checknspikeTrain());
runCheck('nstColl', @() checknstColl());
runCheck('CovColl', @() checkCovColl());
runCheck('TrialConfig', @() checkTrialConfig());
runCheck('ConfigColl', @() checkConfigColl());
runCheck('Trial', @() checkTrial());
runCheck('Analysis API', @() checkAnalysisApi());
runCheck('DecodingAlgorithms API', @() checkDecodingApi());
runCheck('FitResult path resolution', @() checkFitResultPath(rootDir));
runCheck('FitResSummary path resolution', @() checkFitResSummaryPath(rootDir));
runCheck('nstatOpenHelpPage path resolution', @() checkOpenHelpPath(rootDir));

if ~isempty(failures)
    fprintf(2, 'nSTAT smoke test failures (%d):\n', numel(failures));
    for i = 1:numel(failures)
        fprintf(2, '  - %s\n', failures{i});
    end
    error('nSTATSmoke:Failures', 'Smoke validation failed.');
end

fprintf('All nSTAT smoke checks passed.\n');

function runCheck(name, fn)
    try
        fn();
        fprintf('PASS %s\n', name);
    catch ME
        failures{end+1} = sprintf('%s :: %s', name, ME.message); %#ok<AGROW>
    end
end

function checkSignalObj()
    t = (0:0.01:1)';
    y = sin(2*pi*t);
    s = SignalObj(t, y, 'sig', 'time', 's', '', {'sig'});
    assert(isa(s, 'SignalObj'));
end

function checkCovariate()
    t = (0:0.01:1)';
    y = sin(2*pi*t);
    c = Covariate(t, y, 'cov', 'time', 's', '', {'cov'});
    assert(isa(c, 'Covariate'));
end

function checkConfidenceInterval()
    t = (0:0.01:1)';
    y = sin(2*pi*t);
    ci = ConfidenceInterval(t, [y-0.1, y+0.1], 'ci', 'time', 's', '', {'low','high'});
    assert(isa(ci, 'ConfidenceInterval'));
end

function checkEvents()
    e = Events([0.1, 0.2], {'start', 'stop'});
    assert(isa(e, 'Events'));
end

function checkHistory()
    h = History([0, 0.01, 0.05]);
    assert(isa(h, 'History'));
end

function checknspikeTrain()
    nst = nspikeTrain([0.1, 0.2, 0.3], '1', 0.01, 0, 1);
    assert(isa(nst, 'nspikeTrain'));
end

function checknstColl()
    nst = nspikeTrain([0.1, 0.2, 0.3], '1', 0.01, 0, 1);
    coll = nstColl(nst);
    assert(isa(coll, 'nstColl'));
end

function checkCovColl()
    t = (0:0.01:1)';
    y = sin(2*pi*t);
    c = Covariate(t, y, 'cov', 'time', 's', '', {'cov'});
    coll = CovColl({c});
    assert(isa(coll, 'CovColl'));
end

function checkTrialConfig()
    tc = TrialConfig();
    assert(isa(tc, 'TrialConfig'));
end

function checkConfigColl()
    tc = TrialConfig();
    cc = ConfigColl({tc});
    assert(isa(cc, 'ConfigColl'));
end

function checkTrial()
    t = (0:0.01:1)';
    y = sin(2*pi*t);
    cov = Covariate(t, y, 'cov', 'time', 's', '', {'cov'});
    covColl = CovColl({cov});
    nst = nspikeTrain([0.1, 0.2, 0.3], '1', 0.01, 0, 1);
    nstCollection = nstColl(nst);
    tr = Trial(nstCollection, covColl);
    assert(isa(tr, 'Trial'));
end

function checkAnalysisApi()
    m = methods('Analysis');
    assert(~isempty(m));
end

function checkDecodingApi()
    m = methods('DecodingAlgorithms');
    assert(~isempty(m));
end

function checkFitResultPath(rootDir)
    allPaths = which('-all', 'FitResult');
    assert(~isempty(allPaths), 'FitResult not found on path');
    expected = fullfile(rootDir, 'FitResult.m');
    assert(strcmp(allPaths{1}, expected), 'Canonical FitResult.m is not first on path');
end

function checkFitResSummaryPath(rootDir)
    resolved = which('FitResSummary');
    expected = fullfile(rootDir, 'FitResSummary.m');
    assert(strcmp(resolved, expected), 'FitResSummary did not resolve to root class file');
end

function checkOpenHelpPath(rootDir)
    target = nstatOpenHelpPage('NeuralSpikeAnalysis_top.html', false);
    expected = fullfile(rootDir, 'helpfiles', 'NeuralSpikeAnalysis_top.html');
    assert(strcmp(target, expected), 'nstatOpenHelpPage resolved unexpected path');
end
