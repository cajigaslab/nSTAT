# nSTAT — Suggested Commands

Run from repo root. Shell gates (macOS/Darwin, zsh):

- `tools/run_unit_tests.sh` — local test gate, ~20 unit tests. Run before every push.
- `tools/run_unit_tests.sh --integration` — adds slower KS-oracle integration tests (~2–4 min).
- `tools/check_readme_figures.sh` — README/paper-example figure-parity drift detector (~4–5 min).
- `tools/check_bug_patterns.sh` — bug-pattern lint.
- `tools/predeploy.sh` — full pre-release gate, ~30–45 min (6 chained steps).

Inside MATLAB:
- `run_tests` — `matlab.unittest` suite over `tests/` (recursive).
- `addpath(fullfile(pwd,'tools')); run_all_checks(...)` — full local-CI orchestrator.
- `addpath(fullfile(pwd,'tools')); tools.stamp_release('vX.Y.Z')` — stamp version AFTER predeploy passes.
- `build_paper_examples` / `publish_all_helpfiles` — regenerate example figures / helpfiles.
- `tools/generate_baseline_fixtures.m` — regenerate numeric parity baseline (only when deliberately changing ground truth).

MATLAB override: `MATLAB_BIN=<path>/bin/matlab tools/run_unit_tests.sh` or `--matlab-path <...>`.

Darwin note: BSD userland (`ls`, `grep`, `sed` differ from GNU); `mdfind` for spotlight search. Git over `https://github.com/cajigaslab/nstat`, branch `master`.