# Contributing to nSTAT

## `.m` is the canonical source for help / example files

The `helpfiles/` directory contains MATLAB script (`.m`) files; many of them also have a `.mlx` Live Script sibling. **The `.m` file is authoritative.**

The `.mlx` files are binary (a zipped XML format) and cannot be diff-reviewed. They drift from their `.m` counterparts whenever the `.m` is edited without manually opening the `.mlx` in the Live Editor and re-saving. We learned this the hard way in May 2026: four `.mlx` files (`DecodingExample`, `DecodingExampleWithHist`, `StimulusDecode2D`, `HybridFilterExample`) were silently broken for ~3 months because the `.m` files were API-migrated but the `.mlx` siblings were not. MATLAB's `run('Foo')` resolves to the `.mlx` when both exist, so users saw the broken Live Scripts.

**Policy:**

- The `.m` file is the canonical source. Edits go there first.
- When a `.mlx` file is genuinely needed (e.g., for rendering embedded outputs in published docs), regenerate it explicitly from the `.m` via `matlab.internal.live.tutorials.convertOpenToLive` or by opening the `.m` in the Live Editor and saving it as `.mlx`.
- If an `.mlx` drifts from its `.m`, prefer **deleting the `.mlx`** over hand-patching it. The `.m` is the source of truth.
- The historical `matlab-repo-integrity.yml` workflow enforced full `.mlx` coverage. That workflow was removed alongside the MATLAB-based CI (May 2026) because it depended on running MATLAB on GitHub-hosted runners. No automated `.mlx` parity check currently exists.

**Explicit exception — `helpfiles/nSTATPaperExamples.mlx`:**

This single `.mlx` is preserved deliberately, despite drifting from its `.m` sibling, because **it is the artifact referenced in Cajigas, Malik, Brown 2012 (*J. Neurosci. Methods* 211(2):245–264, PMID 22981419)**. Its embedded outputs document the figures and numerical results as they appeared in the published paper, and so it functions as a citation-bound historical record rather than a maintained tutorial.

Consequences:
- Running `nSTATPaperExamples` from MATLAB resolves to the `.mlx` (MATLAB prefers `.mlx` over `.m` when both exist) and emits `nSTAT:deprecated:DecodingAlgorithms` warnings from the pre-Phase-3 static-method API baked into its embedded outputs. This is expected.
- For a clean re-run, invoke the canonical `.m` directly via the V3.1 MVP harness pattern: copy `helpfiles/nSTATPaperExamples.m` to a temporary directory (so the `.mlx` does not shadow it on path) and `run` it there.
- This exception applies to *only* this file. All other stale `.mlx` files should still be deleted per the policy above.

The exception and its rationale are tracked as item **B1** in [`docs/verification/remediation_backlog.md`](docs/verification/remediation_backlog.md).

## Local test gate

**CI does not run MATLAB.** The team's MathWorks license does not extend to GitHub-hosted runners, so there is no automated MATLAB-test gate on PRs. The local pass is the only test gate.

Before pushing any branch that touches MATLAB code, run the unit test suite:

```bash
tools/run_unit_tests.sh
```

Expected: `OK: N tests passed` and exit code 0. If anything fails, fix it before pushing.

For larger changes (especially anything that touches `+nstat/+decoding/`, `Analysis.m`, `FitResult.m`, or `CIF.m`), also run the integration tests:

```bash
tools/run_unit_tests.sh --integration
```

The integration tests are slower (~2-4 minutes) but exercise end-to-end empirical claims (e.g., KS oracle pass-rate validation against the curriculum's §4.C.1 Cor. 2).

### Why no MATLAB CI?

Adding `matlab-actions/setup-matlab@v2` to a GitHub Actions workflow requires a MathWorks Service Provider Agreement seat for CI runners — which our license does not cover. We tried this once (PR #36 commit `3fd9b30`, reverted in this commit). The result was a CI workflow that consumed runner time and consistently failed on missing toolboxes. The corrective decision: don't run MATLAB on CI at all; rely on the local pre-push gate.

### Alternative MATLAB versions

Default is `R2025b` at `/Applications/MATLAB_R2025b.app`. Override with either:

```bash
MATLAB_BIN=/Applications/MATLAB_R2024b.app/bin/matlab tools/run_unit_tests.sh
```

or:

```bash
tools/run_unit_tests.sh --matlab-path /Applications/MATLAB_R2024b.app
```

## Pre-push hook (optional)

If you want to enforce the test gate automatically, add this to `.git/hooks/pre-push`:

```bash
#!/usr/bin/env bash
# Run unit tests before allowing push
exec tools/run_unit_tests.sh
```

Then `chmod +x .git/hooks/pre-push`. This is opt-in per developer; it's not checked into the repo so it can't be enforced globally without a tool like Husky (which would require Node, out of scope for a MATLAB toolbox).

## Larger development workflow

See [`tools/run_all_checks.m`](tools/run_all_checks.m) for the full local-CI orchestrator (parity tests + unit tests + doc publish). It's the canonical "run everything" command before significant releases:

```matlab
% from MATLAB, in the repo root
addpath(fullfile(pwd,'tools'));
run_all_checks('GenerateBaseline', false, ...
               'CheckParity',      true, ...
               'RunTests',         true, ...
               'PublishDocs',      false, ...
               'Style',            'legacy');
```

## Branch + PR conventions

See the action plan at [`docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md`](docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md) for the established commit-message style, deprecation-shim pattern, and audit-comment (`% FIX:`) convention. Phase 0 - Phase 4 of the 2026-05-19 review all follow this template.
