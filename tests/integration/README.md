# nSTAT integration tests

This directory holds heavier integration / empirical-validation tests that are
**not** run on every pull request. Per Phase 3.8 of the 2026-05-19 nSTAT
review action plan, the CI workflow (`.github/workflows/`) runs only
`tests/unit/`. The tests in this directory:

- Take longer than is reasonable for a per-PR gate (minutes, not seconds).
- Exist to lock empirical numerical claims (e.g., published reference's chapter
 references, Monte-Carlo bounds) against regressions.
- Should be re-run on-demand when the underlying numerical claim is
 questioned, when the relevant production code path changes, or as a
 pre-release quality check.

## Running

From the repository root in MATLAB:

```matlab
addpath(genpath(pwd));
results = runtests('tests/integration');
disp(results);
```

Or run a single test:

```matlab
runtests('tests/integration/testKsAgainstReferenceZoo')
```

From the shell:

```bash
/Applications/MATLAB_R2026a.app/bin/matlab -batch \
 "addpath(genpath(pwd)); results = runtests('tests/integration'); disp(results); assert(~any([results.Failed]))"
```

## Current tests

### `testPointProcessEMIntegration.m`

Slow end-to-end EM regression tests for `nstat.decoding.PointProcessEM.PP_EM`
and `nstat.decoding.PPLFP.PPLFP_EM` (fix/pp-em), moved out of `tests/unit` so
the per-push gate stays fast. Each test runs several complete EM fits:

- `testPPEMRunsAndConverges` -- all 8 fitType x MstepMethod x history
  combinations converge (finite outputs, non-decreasing log-likelihood,
  best iterate returned, NewtonRaphson recovers the generating parameters).
- `testDefaultHistoryWindowsPP` / `...PPLFP` -- with `windowTimes = []` the
  default windows are `0:delta:W*delta` (W = size(gamma,1)) and a shared
  gamma column is expanded per cell.
- `testTimeBaseEquivalencePP` / `...PPLFP`, `testGLMTimeBaseEquivalencePPLFP`
  -- the same data at delta = 2 ms with windows [0 4 10 20] ms equals the
  1 ms analysis with [0 2 5 10] ms.

Helpers live in the unit classes `testPointProcessEMRuns`,
`testPointProcessEMCorrectness` and `testPPLFPEMCorrectness`, so run with
`addpath(genpath(pwd))` (as `tools/run_unit_tests.sh --integration` does).
Runtime ~1 minute.

### `testKsAgainstReferenceZoo.m`

Locks the `the published reference` chapter-04 §4.C.1 Cor. 2 numerical claim:

> Oracle pass rate matches nominal 0.95 to within 0.5 percentage points at
> lambda*delta <= 0.4 with up to 6.5% multi-spike bins.

Simulates Bernoulli spike trains at known constant rate `pk = lambda*delta`,
runs the Haslinger-Pipa-Brown 2010 discrete-time rescaling algorithm via the
`Analysis.ksdiscrete` static-wrapper entry point (exposed for testing in
`Analysis.m`), sweeps `lambda*delta` across `{0.005, 0.05, 0.1, 0.2, 0.4}`
with 200 Monte Carlo trials per regime, and asserts the empirical pass rate
is within 0.05 of 0.95 in every regime. Total runtime: ~30-60 seconds.

The test calls the algorithm directly via `Analysis.ksdiscrete` rather than
through `Analysis.computeKSStats(...)`. The static wrapper was added
explicitly for unit/integration testing of the DT correction in isolation
from the surrounding `nspikeTrain` / `Covariate` marshalling logic; this is
what the discrete-time KS validity bound refers to algorithmically.

If this test fails, either the Haslinger-Pipa-Brown 2010 DT correction in
`Analysis.m`'s local `ksdiscrete` has regressed, or the 
empirical claim does not hold and the chapter prose must be revisited.

Reference: `the Haslinger-Pipa-Brown 2010 DT-correction reference` in the `the published reference`
repository (the original 14-model Python zoo); Haslinger, Pipa & Brown 2010
(*Neural Comput.* 22:2477-2506).
