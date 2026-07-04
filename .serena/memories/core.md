# nSTAT — Core

MATLAB neural Spike Train Analysis Toolbox (Cajigas, Malik & Brown, *J Neurosci Methods* 211:245–264, 2012; PMID 22981419). Repo `cajigaslab/nstat` (public), default branch `master`. Independent Python port lives in the separate repo `cajigaslab/nstat-python` — **keep the two uncoupled**; do not cross-import or sync code between them.

## Source map
- Root `*.m` (26 files) = public toolbox API classes. Core classes: `Analysis`, `CIF`, `LinearCIF`, `SignalObj`, `FitResult`, `FitResSummary`, `nspikeTrain`, `nstColl`, `CovColl`, `Covariate`, `ConfidenceInterval`, `ConfigColl`, `DecodingAlgorithms`, `Trial`, `TrialConfig`, `History`, `Events`.
- `+nstat/+decoding/` = modern decoding namespace package: `PPAF`, `PPHF`, `KalmanFilter`, `KF_EM`, `UKF`, `SSGLM`, `PointProcessEM`, `PPLFP`. Private helpers in `+nstat/+decoding/+internal/` (e.g. `computeGainMatrix`).
- `examples/paper/exampleNN_*.m` = the 5 paper worked examples (regenerate via `regenerate_all_figures.m`).
- `helpfiles/*.m` = **canonical** help source (`.html` under helpfiles are generated — never hand-edit).
- `tools/` = local-CI orchestration, figure-parity, release. Plot styling package: `tools/+nstat/` (`applyPlotStyle`, `getPlotStyle`, `setPlotStyle`) — there is no `+plotting` package.
- `tests/` = `unit/`, `integration/`, `python_port_fidelity/` (discovered by `run_tests.m`).
- `fixtures/baseline_numeric/` = ground-truth numeric parity baseline.
- `data/`, `docs/`, `libraries/`, `porting/`, `release/`, `slprj/` (Simulink build).

## Project-wide invariants
- MATLAB-style class/method names ARE the public API — never rename.
- `.m` is canonical, never `.mlx` (see `mem:conventions`).
- No MATLAB CI exists (license doesn't cover GitHub runners) — the local gate is the only gate. Do NOT add a MATLAB CI workflow.

## Focused memories
- Stack/versions/build: `mem:tech_stack`
- Commands to run (test/parity/release): `mem:suggested_commands`
- Code/style/policy invariants (.m-canonical, figure parity, baseline): `mem:conventions`
- Definition-of-done gate before commit/push: `mem:task_completion`