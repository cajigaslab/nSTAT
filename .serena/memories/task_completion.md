# nSTAT — Definition of Done

No MATLAB CI exists — the local gate is the ONLY gate. Before declaring a coding task done / before pushing:

1. `tools/run_unit_tests.sh` must pass (add `--integration` when touching decoding/KS-oracle paths).
2. If the change touches `examples/paper/exampleNN_*.m`, any core class, `+nstat/+decoding/*`, or `tools/+nstat/applyPlotStyle.m` → run `tools/check_readme_figures.sh`. `SUBSTANTIVE` diff means regenerate `docs/figures/` (commit PNGs + `manifest.json`) or fix the regression before done.
3. If numeric behavior changed, confirm `tests/TestParityAgainstBaseline.m` still passes (baseline in `fixtures/baseline_numeric/`). Do not regenerate the baseline to make a test pass unless the change to ground truth is intended.

Release path (only when cutting a version): `tools/predeploy.sh` (full ~30–45 min gate) → in MATLAB `tools.stamp_release('vX.Y.Z')` → commit + tag → `git push origin master --tags`.

If MATLAB is unavailable in the current shell, report that and route the actual test run to the user — do not claim the gate passed without running it.