# nSTAT integration tests

This directory holds heavier integration / empirical-validation tests that are
**not** run on every pull request. Per Phase 3.8 of the 2026-05-19 nSTAT
review action plan, the CI workflow (`.github/workflows/`) runs only
`tests/unit/`. The tests in this directory:

- Take longer than is reasonable for a per-PR gate (minutes, not seconds).
- Exist to lock empirical numerical claims (e.g., curriculum chapter
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
runtests('tests/integration/testKsAgainstCurriculumZoo')
```

From the shell:

```bash
/Applications/MATLAB_R2025b.app/bin/matlab -batch \
  "addpath(genpath(pwd)); results = runtests('tests/integration'); disp(results); assert(~any([results.Failed]))"
```

## Current tests

### `testKsAgainstCurriculumZoo.m`

Locks the `bci-curriculum` chapter-04 §4.C.1 Cor. 2 numerical claim:

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
what the curriculum's Cor. 2 numerical claim refers to algorithmically.

If this test fails, either the Haslinger-Pipa-Brown 2010 DT correction in
`Analysis.m`'s local `ksdiscrete` has regressed, or the curriculum's
empirical claim does not hold and the chapter prose must be revisited.

Reference: `reviews/ks-transformer-validation/` in the `bci-curriculum`
repository (the original 14-model Python zoo); Haslinger, Pipa & Brown 2010
(*Neural Comput.* 22:2477-2506).
