function plan = buildfile
%BUILDFILE buildtool task definitions for the nSTAT toolbox.
%
% Run the default tasks from a MATLAB shell at the repo root:
%   >> buildtool
% Run a specific task:
%   >> buildtool test
%   >> buildtool predeploy
%
% The named tasks here CONSOLIDATE what previously lived in the
% tools/*.sh and tools/*.m scripts. The old scripts are RETAINED for
% backward compatibility; think of buildtool as the new IDE-aware
% entry point.
%
% Mapping from old scripts to buildtool tasks:
%   tools/run_unit_tests.sh               ->  buildtool test
%   tools/run_unit_tests.sh --integration ->  buildtool integration
%   tools/check_readme_figures.sh         ->  buildtool figures
%   tools/check_bug_patterns.sh           ->  buildtool patterns
%   tools/lint_helptoc.py                 ->  buildtool helptoc
%   tools/predeploy.sh                    ->  buildtool predeploy
%   tools/build_paper_examples.m          ->  buildtool figuresRegen
%
% Reference: docs/superpowers/plans/2026-06-13-toolbox-modernization.md

plan = buildplan(localfunctions);

% --- Static-analysis check (CodeIssuesTask helper) ---------------------
plan("check") = matlab.buildtool.tasks.CodeIssuesTask( ...
    ["+nstat" "tools" "tests"], ...
    IncludeSubfolders=true);
plan("check").Description = "Run checkcode across the namespace + tools.";

% --- Tests (TestTask helpers) -----------------------------------------
plan("test") = matlab.buildtool.tasks.TestTask( ...
    "tests/unit", ...
    IncludeSubfolders=true);
plan("test").Description = "Run the unit-test suite under tests/unit/.";

plan("integration") = matlab.buildtool.tasks.TestTask( ...
    "tests/integration", ...
    IncludeSubfolders=true);
plan("integration").Description = "Run the integration suite under tests/integration/.";

% --- Cross-task dependencies ------------------------------------------
plan("predeploy").Dependencies = [ ...
    "check" "test" "integration" "figures" "patterns" "helptoc" "package"];

% --- Default sequence (cheap; safe to run on every save) ---------------
plan.DefaultTasks = "test";
end

% =========================================================================
% Task action functions (auto-registered by buildplan(localfunctions))
% =========================================================================

function figuresTask(~)
%FIGURESTASK Verify README paper-example gallery against current code.
% Wraps tools/check_readme_figures.sh. Errors on SUBSTANTIVE drift.
repoRoot = fileparts(mfilename("fullpath"));
script = fullfile(repoRoot, "tools", "check_readme_figures.sh");
status = system("bash """ + script + """");
if status ~= 0
    error("nstat:build:figures", "Figure parity check failed (exit %d).", status);
end
end

function figuresRegenTask(~)
%FIGURESREGENTASK Regenerate the README paper-example gallery in tree.
build_paper_examples("Seed", 0, "Visible", "off");
end

function patternsTask(~)
%PATTERNSTASK Run the sibling-bug pattern audit (informational).
% Wraps tools/check_bug_patterns.sh. Always exits 0; review the report
% under docs/verification/bug_pattern_audit.md for the canonical triage.
repoRoot = fileparts(mfilename("fullpath"));
script = fullfile(repoRoot, "tools", "check_bug_patterns.sh");
report = fullfile(repoRoot, "docs", "verification", "bug_pattern_audit_latest.md");
system("bash """ + script + """ """ + report + """");
fprintf("Bug-pattern report: %s\n", report);
end

function helptocTask(~)
%HELPTOCTASK Validate helptoc.xml -> file targets.
% Wraps tools/lint_helptoc.py. Errors on broken targets.
repoRoot = fileparts(mfilename("fullpath"));
script = fullfile(repoRoot, "tools", "lint_helptoc.py");
status = system("python3 """ + script + """");
if status ~= 0
    error("nstat:build:helptoc", "helptoc.xml validation failed (exit %d).", status);
end
end

function packageTask(~)
%PACKAGETASK Build .mltbx via packageToolbox().
% Phase G2 lands toolboxOptions.m and packageToolbox.m; until then this
% is a no-op stub so 'buildtool predeploy' completes without erroring.
if exist("packageToolbox", "file") == 2
    packageToolbox();
else
    fprintf("packageToolbox.m not present yet; Phase G2 will add it.\n");
    fprintf("Plan: docs/superpowers/plans/2026-06-13-toolbox-modernization.md\n");
end
end

function predeployTask(~)
%PREDEPLOYTASK Pre-tag release gate (chains all check tasks via dependencies).
% Dependencies are wired in the plan above (check + test + integration
% + figures + patterns + helptoc + package). buildtool runs them all
% before invoking this action; this body is a no-op summary.
fprintf("\n=== predeploy gate complete ===\n");
fprintf("If you reached this message with no errors, the toolbox is ready to tag.\n");
end
