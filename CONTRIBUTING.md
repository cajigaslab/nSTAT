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

The exception and its rationale are tracked in internal remediation notes.

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

### README figure parity

The `README.md` headline gallery (5 thumbnails at
`docs/figures/exampleNN/fig01_*.png`) and the expanded gallery at
[`docs/paper_examples.md`](docs/paper_examples.md) are produced by
[`tools/build_paper_examples.m`](tools/build_paper_examples.m) from the
scripts under `examples/paper/`. **The PNGs are committed; they ARE the
documentation and they ARE what GitHub renders.**

Any change that could alter the rendered output of those examples MUST
either confirm zero pixel drift or commit regenerated figures alongside
the code change. This applies when modifying:

- `examples/paper/exampleNN_*.m` (the scripts themselves)
- `FitResult.m`, `Analysis.m`, `CIF.m`, `Covariate.m`, `SignalObj.m`
  (core toolbox classes consumed by every example)
- `+nstat/+decoding/*` (decoding cluster classes — affects Example 05)
- `+nstat/+plotting/*` and `tools/+nstat/applyPlotStyle.m`
  (plot-style migration affects every figure)
- `helpfiles/nSTATPaperExamples.m` (the 2012-paper artifact)

Workflow:

```bash
tools/check_readme_figures.sh
```

This regenerates the gallery into a temp directory (calling
`build_paper_examples` internally) and pixel-diffs against the
committed PNGs in `docs/figures/`. The check takes ~4–5 minutes (it
actually runs every paper example) and is the canonical drift detector.

Interpreting the report:

- `IDENTICAL` / `TINY` — proceed, no action needed.
- `NONDETERMINISTIC` — informational, allowlisted (Example 03 SSGLM EM
  iterations produce non-deterministic BLAS reduction order; the
  allowlist set lives in `tools/check_readme_figures.m`). Treat as no
  action needed.
- `SUBSTANTIVE` — triage:
  - **Correctness fix or cosmetic update**: regenerate `docs/figures/`
    via `build_paper_examples` and commit the new PNGs + updated
    `manifest.json` alongside the code change. Explain in the commit
    message.
  - **Unexplained**: fix the regression before proceeding. Do NOT
    blindly accept regenerated figures.

Do NOT bypass this for "doc-only" changes — the figures ARE docs.

Background: the figures were ~2.5 months stale at one point in 2026-05,
encoding pre-Phase-4 bug outputs until regenerated. The empirical Phase
A.5 finding that established the NONDETERMINISTIC allowlist is summarized
in the inline comment block of `tools/check_readme_figures.m`.

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

## Release & regeneration

Before tagging any release `vX.Y.Z`, the release engineer runs the
one-command deploy gate:

```bash
tools/predeploy.sh
```

This chains every existing check in canonical order:

1. `tools/run_unit_tests.sh` — 20 unit tests.
2. `tools/run_unit_tests.sh --integration` — + KS oracle integration.
3. `tools/check_readme_figures.sh` — README figure parity (drift detector).
4. `helpfiles/publish_all_helpfiles.m` — re-publishes every `.m` to `.html`,
   validates helptoc target resolution, rebuilds `helpsearch-v4_0/`.
5. `tools/lint_helptoc.py` — independent helptoc.xml validation.
6. `tools/check_bug_patterns.sh` — sibling-bug pattern audit (writes
   an informational report; not a release blocker).

Wall clock: ~30–45 minutes. The publish step is the slow one because it
re-executes every example. Flags `--skip-publish` and `--skip-readme` exist
for iterative debugging but should not be used for final pre-release checks.

After the gate passes, stamp the release inside MATLAB:

```matlab
addpath(fullfile(pwd,'tools'));
tools.stamp_release('vX.Y.Z')   % updates Contents.m + manifest + RELEASE_NOTES.md
```

Then commit and tag:

```bash
git add Contents.m docs/figures/manifest.json RELEASE_NOTES.md
git commit -m "release(vX.Y.Z): stamp version + manifest"
git tag vX.Y.Z
git push origin master --tags
```

### What gets regenerated at release time

| Artifact | How | When |
|---|---|---|
| `docs/figures/exampleNN/*.png` | `build_paper_examples` (auto-invoked by `check_readme_figures.sh`) | Step 3 of `predeploy.sh` |
| `helpfiles/*.html` | `publish()` via `publish_all_helpfiles` | Step 4 of `predeploy.sh` |
| `helpfiles/helpsearch-v4_0/` | `builddocsearchdb` (auto-invoked by `publish_all_helpfiles`) | Step 4 of `predeploy.sh` |
| `Contents.m` version stamp | `tools.stamp_release` | Manual after gate passes |
| `docs/figures/manifest.json` `generated_at` | `tools.stamp_release` | Manual after gate passes |
| `RELEASE_NOTES.md` section | `tools.stamp_release` (template; fill in highlights) | Manual after gate passes |

### What stays manual (NOT regenerated)

- `helpfiles/nSTATPaperExamples.mlx` — paper-reference exception (see "`.m` is canonical" above).
- `AUDIT_REPORT.md` — historical record of the 2026-03-10 audit (banner says so).
- `README.md` body prose (the figure table itself stays current because it embeds PNGs by relative path).

### Why no MATLAB CI revisited

The gate runs locally because GitHub-hosted runners do not have a
MathWorks Service Provider Agreement seat. The decision to keep MATLAB
off CI is documented at "Why no MATLAB CI?" above. The `predeploy.sh`
gate is the local equivalent.

## Branch + PR conventions

Established commit-message style and PR shape: short imperative subject (≤72 chars), body with rationale and "Closes #N" trailers where applicable. Code-side fixes use the inline `% FIX:` audit-comment convention; deprecation-shim renames preserve a forwarding shim with `nSTAT:deprecated:*` warnings. Each phase of the 2026-05-19 review action plan and the 2026-06-12 open-issues remediation followed this template; recent merged PRs are the working reference.
