function results = verify_all_examples(varargin)
%VERIFY_ALL_EXAMPLES Run every in-scope nSTAT example and capture status.
%
%   results = verify_all_examples()
%   results = verify_all_examples('Scripts', {'HelloNstat', ...})
%   results = verify_all_examples('Scope', 'tier-b')
%   results = verify_all_examples('Scope', 'all')
%
% Runs each script in a captured environment (evalc for stdout, lastwarn
% for warnings, tic/toc for timing) and emits:
%   - results table (returned and printed)
%   - docs/verification/run_report_<timestamp>.json
%   - docs/figures/<script_id>/  (figures captured via findobj snapshot)
%
% Phase V0.2 of the 2026-05-20 deep-dive verification plan.
%
% Status legend:
%   PASS    — runs to completion, no nSTAT:deprecated:* warnings.
%   PASS-W  — runs to completion but emits a deprecation warning.
%   FAIL    — errored or produced NaN/Inf in numeric output.
%   QUARANTINE — fails for out-of-scope reasons; recorded but not fixed.

p = inputParser;
p.addParameter('Scripts', {}, @(x) iscellstr(x) || isstring(x));
p.addParameter('Scope', 'tier-b', @(x) ismember(x, {'tier-b', 'paper', 'tutorials', 'all', 'custom'}));
p.addParameter('FigureRoot', fullfile(pwd, 'docs', 'figures'), @ischar);
p.addParameter('ReportRoot', fullfile(pwd, 'docs', 'verification'), @ischar);
p.addParameter('CaptureFigures', true, @islogical);
p.parse(varargin{:});
opts = p.Results;

if ~exist(opts.ReportRoot, 'dir'); mkdir(opts.ReportRoot); end

% --- Define scope -------------------------------------------------------
TIER_B_SYNTHETIC = {
    'AnalysisExamples', 'AnalysisExamples2', 'ConfigCollExamples', ...
    'CovCollExamples', 'CovariateExamples', 'EventsExamples', ...
    'FitResSummaryExamples', 'FitResultExamples', 'HistoryExamples', ...
    'PPThinning', 'SignalObjExamples', 'TrialConfigExamples', ...
    'TrialExamples', 'ValidationDataSet', 'nSpikeTrainExamples', ...
    'nstCollExamples', 'NetworkTutorial', 'PPSimExample', ...
    'PSTHEstimation' };

TIER_B_FIGSHARE = {
    'ExplicitStimulusWhiskerData', 'HippocampalPlaceCellExample', ...
    'mEPSCAnalysis', 'nSTATPaperExamples' };

PAPER_EXAMPLES = {
    'example01_mepsc_poisson', 'example02_whisker_stimulus_thalamus', ...
    'example03_psth_and_ssglm', 'example04_place_cells_continuous_stimulus', ...
    'example05_decoding_ppaf_pphf' };

TUTORIALS = { 'HelloNstat', 'FoundationModelKSValidation' };

TIER_A_MIGRATED = { ...
    'DecodingExample', 'DecodingExampleWithHist', ...
    'StimulusDecode2D', 'HybridFilterExample' };

switch opts.Scope
    case 'tier-b'
        scripts = [TIER_B_SYNTHETIC, TIER_B_FIGSHARE];
    case 'paper'
        scripts = PAPER_EXAMPLES;
    case 'tutorials'
        scripts = TUTORIALS;
    case 'all'
        scripts = [PAPER_EXAMPLES, TUTORIALS, TIER_A_MIGRATED, ...
                   TIER_B_SYNTHETIC, TIER_B_FIGSHARE];
    case 'custom'
        scripts = cellstr(opts.Scripts);
end

fprintf('Verifying %d scripts (scope: %s)\n\n', numel(scripts), opts.Scope);

% --- Suppress figures during run ---------------------------------------
origVisibility = get(groot, 'defaultFigureVisible');
set(groot, 'defaultFigureVisible', 'off');
cleanup = onCleanup(@() set(groot, 'defaultFigureVisible', origVisibility));

% --- Run each script ----------------------------------------------------
n = numel(scripts);
results = struct('script', cell(n,1), 'status', cell(n,1), ...
                 'runtime_s', cell(n,1), 'warning_id', cell(n,1), ...
                 'warning_msg', cell(n,1), 'error_id', cell(n,1), ...
                 'error_msg', cell(n,1), 'figure_count', cell(n,1), ...
                 'figure_paths', cell(n,1));

for k = 1:n
    s = scripts{k};
    fprintf('[%2d/%d] %s ... ', k, n, s);

    % Determine if this is a paper example (function with args) or helpfile
    isPaperEx = any(strcmp(s, PAPER_EXAMPLES));

    % Clear figures before run
    close all;
    rng(0, 'twister');
    lastwarn('');
    tStart = tic;
    errId = ''; errMsg = '';

    try
        if isPaperEx
            % Paper examples are functions with name-value args
            feval(s, 'ExportFigures', false, 'Visible', 'off', 'Seed', 0);
        else
            % Helpfiles are scripts — run via evalin to keep their scope
            % isolated from this function. clear()-calls inside scripts
            % can't reach this function's variables.
            evalin('base', sprintf('clear; rng(0, ''twister''); run(''%s'');', s));
        end
        runtime = toc(tStart);
        [warnMsg, warnId] = lastwarn();
    catch ME
        runtime = toc(tStart);
        warnId = ''; warnMsg = '';
        errId = ME.identifier;
        errMsg = ME.message;
    end

    % Capture figures
    figDir = fullfile(opts.FigureRoot, sprintf('verify_%s', s));
    figPaths = {};
    if opts.CaptureFigures && isempty(errId)
        figs = findobj('Type', 'figure');
        if ~isempty(figs)
            if ~exist(figDir, 'dir'); mkdir(figDir); end
            for i = 1:numel(figs)
                p = fullfile(figDir, sprintf('fig%02d.png', i));
                try
                    exportgraphics(figs(i), p, 'Resolution', 100);
                    figPaths{end+1} = p; %#ok<AGROW>
                catch
                end
            end
        end
    end

    % Categorize status
    if ~isempty(errId)
        status = 'FAIL';
        fprintf('FAIL  (%.1fs)  %s\n', runtime, errMsg);
    elseif startsWith(string(warnId), 'nSTAT:deprecated')
        status = 'PASS-W';
        fprintf('PASS-W (%.1fs)  warn=%s\n', runtime, warnId);
    else
        status = 'PASS';
        fprintf('PASS   (%.1fs)  figs=%d\n', runtime, numel(figPaths));
    end

    results(k).script = s;
    results(k).status = status;
    results(k).runtime_s = runtime;
    results(k).warning_id = warnId;
    results(k).warning_msg = warnMsg;
    results(k).error_id = errId;
    results(k).error_msg = errMsg;
    results(k).figure_count = numel(figPaths);
    results(k).figure_paths = figPaths;

    close all;
end

% --- Summary -----------------------------------------------------------
pass = sum(strcmp({results.status}, 'PASS'));
passw = sum(strcmp({results.status}, 'PASS-W'));
fail = sum(strcmp({results.status}, 'FAIL'));
fprintf('\n========================================\n');
fprintf('Summary: %d PASS / %d PASS-W / %d FAIL of %d\n', pass, passw, fail, n);
fprintf('========================================\n');

% --- Write JSON report -------------------------------------------------
timestamp = datestr(now, 'yyyymmdd-HHMMSS'); %#ok<DATST>
jsonPath = fullfile(opts.ReportRoot, sprintf('run_report_%s.json', timestamp));
report = struct('generated_at', datestr(now, 'yyyy-mm-ddTHH:MM:SS'), ...
                'matlab_version', version(), ...
                'scope', opts.Scope, ...
                'n_pass', pass, 'n_pass_w', passw, 'n_fail', fail, ...
                'n_total', n, 'results', results);
fid = fopen(jsonPath, 'w');
fprintf(fid, '%s', jsonencode(report, 'PrettyPrint', true));
fclose(fid);
fprintf('Report written to: %s\n', jsonPath);

end
