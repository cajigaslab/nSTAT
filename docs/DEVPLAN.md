# nSTAT MATLAB Upgrade Dev Plan (Orchestrated 3-Agent Sequence)

This plan defines a sequential 4-PR strategy with parity gates at each stage.

## Global Principles
- Preserve scientific outputs (numeric results and conclusions) except clear bug fixes.
- Preserve public API surface (classes/methods/properties and file-level entrypoints).
- Keep plotting informational content unchanged; style changes are allowed only with legacy fallback.
- Target MATLAB 2025 compatibility and reduce deprecated usage where feasible.

## PR Sequence

### PR0 — Baseline Harness + Fixture Generation
Scope:
- Add reproducible fixture tooling.
- Add parity checker.
- Add `tools/run_all_checks.m` entrypoint.
- Add this plan document.

Artifacts:
- `fixtures/baseline_numeric/` (numeric baselines MAT/JSON)
- `fixtures/baseline_figures_legacy/` (legacy figure exports)
- `fixtures/baseline_plot_structure.json` (structural metadata)

Acceptance:
- No runtime behavior/API changes to toolbox logic.
- `generate_baseline_fixtures` runs on MATLAB 2025.
- `check_parity_against_baseline` passes immediately after baseline generation.

### PR1 — Robustness/Refactor + Plot Modernization + Legacy Mode
Scope:
- Safe robustness improvements (error guards/validation/helpers).
- Plot readability improvements by default.
- Add global + per-call style override (`legacy`/`modern`).

Parity Gate:
- Numeric parity must pass against PR0 baseline.
- Plot structure parity must pass in both styles.
- Legacy style should reproduce baseline appearance as closely as deterministic rendering allows.

### PR2 — Tests + CI
Scope:
- `matlab.unittest` unit/integration coverage.
- Fixture-backed parity tests.
- GitHub Actions via `matlab-actions`.

Parity Gate:
- `runtests('tests')` passes locally and in CI.
- Parity checker remains green.

### PR3 — README/Docs + Paper Examples Integration
Scope:
- README overhaul (quickstart + workflows + paper mapping).
- `tools/publish_examples.m` for generated docs figures.
- Citation metadata (`CITATION.cff` or BibTeX).

Policy:
- No publication PDF images embedded.
- All README/docs figures generated from repository code.

## Parity Strategy

## Numeric parity
- Deterministic execution with `rng(seed,'twister')`.
- Compare compact numeric summaries from paper example workflows:
  - AIC/BIC/coefficient/KS/lambda/residual summaries
  - dimension and shape checks
- Compare with explicit tolerances (`absTol`, `relTol`) for floating-point robustness.
- Account for known stochastic internals in current release:
  - `Analysis.discreteTimeRescaling` calls `rng('shuffle','twister')`, so
    downstream `MU_est*`, `MuCoeffs`, `coeffs`, and `lambdaData` are
    treated as stochastic parity fields (shape/type checked, value parity skipped).
  - Deterministic fields remain strict tolerance-checked.

## Plot parity
- Always compare **structure** (figure/axes/traces/labels/legend metadata).
- Optional pixel parity for `legacy` style only (determinism-dependent).

## Fixture Update Policy
- Fixtures are versioned and treated as protected golden artifacts.
- Update fixtures only when:
  - intentional scientific bug fix is accepted, or
  - intentional plotting policy update requires baseline refresh.
- Any fixture refresh PR must include:
  - rationale,
  - explicit before/after parity summary,
  - reviewer sign-off note in PR description.

## Local Validation Entry Point
Use:
```matlab
addpath('/absolute/path/to/nSTAT/tools');
run_all_checks('GenerateBaseline',false,'CheckParity',true,'Style','legacy');
```
Typical workflows:
```matlab
% Generate baseline (PR0 bootstrap)
run_all_checks('GenerateBaseline',true,'CheckParity',true,'Style','legacy');

% Routine parity check (post-change)
run_all_checks('GenerateBaseline',false,'CheckParity',true,'Style','legacy');
```
