# 2026-05-20 — README Figure Parity & Drift-Detection Plan

**Owner:** Iahn Cajigas
**Status:** PROPOSED
**Companion docs:**
- [README.md](../../../README.md) — the consumer of the figures
- [docs/figures/manifest.json](../../figures/manifest.json) — current baseline (2026-03-05)
- [tools/build_paper_examples.m](../../../tools/build_paper_examples.m) — figure generator
- [docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md](2026-05-19-nstat-review-action-plan.md) — Phase 0–4 modernization that drove the suspected drift

## 1. Problem statement

The repository's `README.md` advertises five paper-example thumbnails, each pointed at a committed PNG in `docs/figures/exampleN/`:

```
docs/figures/example01/fig01_constant_mg_summary.png
docs/figures/example02/fig01_data_overview.png
docs/figures/example03/fig01_simulated_and_real_rasters.png
docs/figures/example04/fig01_example_cells_path_overlay.png
docs/figures/example05/fig01_univariate_setup.png
```

These PNGs (plus their ~22 sibling figures in the same directories) are produced by `tools/build_paper_examples.m`, which calls each `examples/paper/exampleNN_*.m` with `ExportFigures=true`. The manifest records `generated_at = 2026-03-05T17:05:39-05:00`, MATLAB R2025b Update 3, RNG seed 0.

Two coupled problems:

1. **Staleness (acute):** Between 2026-03-05 and 2026-05-20, Phase 0–4 modernization landed ≥10 bug-fix commits that touch the math the figures depend on — Bernoulli LL wrapping (`acd57c7`, `d1e96cf`), KS U-clamp removal (`ef01a82`), DT-correction branch reachability (`f460aa8`), multi-result λ indexing (`1520034`), PPAF/PPHF time-indexing (`3ffebd5`, `bc5f879`, `1bcb63e`, `ba7069a`), invGaus overflow guards (`f5b5734`). The committed PNGs therefore encode pre-fix outputs — they are visual representations of bugs the codebase has since corrected.
2. **Drift detection (chronic):** Figure-PNG drift is invisible to text diff review and to `tools/run_unit_tests.sh`. A future bug fix or refactor that alters `computeLL`, `computeKSStats`, or any plotting helper passes unit tests cleanly while silently invalidating the README headline images. There is currently no automated check for this category of drift on the modern README gallery (the legacy `.mlx` path has `tools/check_parity_against_baseline.m`, but that is for the `nSTATPaperExamples.mlx` fixture, not the `build_paper_examples` gallery).

The user's intent is to fix both: first verify the in-tree PNGs reflect current code, then codify a policy and a check that prevents recurrence.

## 2. Pre-flight diagnosis (without running anything)

Evidence the in-tree PNGs are stale vs. current code:

| Code path | Last touched | Affects |
|---|---|---|
| `FitResult.computeLL` Bernoulli branch | `acd57c7`, `d1e96cf` (May 2026) | LL/AIC/BIC in **Example 01–04** wherever a binomial fit appears |
| `Analysis.computeKSStats` U-clamp & DT branch | `ef01a82`, `f460aa8` (May 2026) | KS plots & invGaus transforms in **Example 01–04** |
| `FitResult` multi-result λ indexing | `1520034` (May 2026) | **Example 03** SSGLM multi-trial λ display |
| `FitResult.plotSeqCorr` non-finite guard | `f5b5734` (post-2026-03-05) | invGausTrans subplots in **Examples 01–03** |
| `PPDecodeFilter` goal-directed time-index | `3ffebd5`, `1bcb63e`, `ba7069a` (post-2026-03-05) | **Example 05** fig04 (goal-vs-free) |
| `PPHybridFilter(Linear)` A/Q time-index, x0/Pi0 fusion | `bc5f879`, `1bcb63e` | **Example 05** fig05–fig06 |
| `containsChars`, `sampeRate`, `logLL` undefined vars | `6f6eb13` | Broad — any binomial code path |

**Predicted verification outcome:** essentially every PNG in `docs/figures/` will differ at the pixel level. Most differences are *correctness improvements*; a small subset may be cosmetic (axis-tick rounding from plot-style migration). Treat "pixel-identical" as the failure mode (would imply the bug fixes had no observable effect, which is itself worth investigating).

## 3. Phase A — Baseline verification

**Gate:** Phase B (policy) does not land until Phase A produces a clean baseline. The committed figures must reflect the current code before we lock in "current code must reproduce committed figures" as policy.

### A.1 — Regenerate figures into a sandbox

Run `build_paper_examples` into a temp directory so the in-tree PNGs remain untouched for diffing:

```matlab
addpath(genpath(pwd));
buildOut = fullfile(tempdir, 'nstat_readme_regen');
if exist(buildOut,'dir'); rmdir(buildOut,'s'); end
manifest = build_paper_examples('FigureRoot', buildOut, 'Seed', 0);
```

Acceptance: all five examples complete without error; new manifest written; ~27 PNGs produced.

**Risk:** the `examples/paper/exampleNN_*.m` functions may have undergone signature drift since they were last invoked en masse. Mitigation: smoke-run each individually before the batch.

**Effort:** ~5–10 minutes wall clock (examples 03 and 04 are the slow ones).

### A.2 — Pixel-level diff against tree

Use Python + Pillow + numpy (already available; no MATLAB-only dependency) to compute pixel deltas:

```python
from PIL import Image
import numpy as np
old = np.array(Image.open(tree_path).convert('RGB'))
new = np.array(Image.open(temp_path).convert('RGB'))
if old.shape != new.shape:
    verdict = 'SHAPE_DIFFER'
else:
    delta = np.abs(old.astype(int) - new.astype(int)).mean()
    verdict = 'IDENTICAL' if delta == 0 else ('TINY' if delta < 0.5 else 'SUBSTANTIVE')
```

Three-bucket classification (matches the V3.1 MVP harness pattern from [pre_mod_comparison.md](../../verification/pre_mod_comparison.md)):

- `IDENTICAL`: byte-for-byte (`mean(|Δ|) == 0`). Expected to be rare given the bug fixes.
- `TINY`: `mean(|Δ|) < 0.5/255`. Anti-aliasing, axis-tick rounding, plot-style migration noise.
- `SUBSTANTIVE`: `mean(|Δ|) ≥ 0.5/255`. The figure actually moved.

Output: `docs/verification/readme_figure_parity.md` with a per-figure table (path, verdict, mean-delta, likely cause).

**Effort:** ~30 minutes (write the diff harness, run, tabulate).

### A.3 — Triage drifted figures

For each `SUBSTANTIVE` drift, attribute the cause:

1. Read the underlying MATLAB code that produces the figure (e.g., for `example01/fig01_constant_mg_summary.png`, follow `example01_mepsc_poisson.m` → `Analysis.GLMFit` → `FitResult.plot`).
2. `git log -p --since='2026-03-05' -- <file>` on each dependency to identify the responsible commit(s).
3. Classify each substantive drift as one of:
   - **CORRECTNESS_FIX** — drift attributable to a known bug-fix commit. The new figure is *more correct* than the old. Action: accept new figure as baseline.
   - **COSMETIC** — plot-style migration, axis-tick formatting, font fallback. Action: accept new figure as baseline.
   - **REGRESSION** — drift NOT attributable to a known fix; semantic content differs unexpectedly. Action: investigate, fix or revert before proceeding.

**Acceptance gate for Phase A:** zero `REGRESSION` items. `CORRECTNESS_FIX` and `COSMETIC` items are acceptable and expected.

**Effort:** 1–3 hours depending on regression count (zero expected; budget exists in case the modernization introduced an unintended visual change).

### A.4 — Re-commit corrected baseline

Once triage is clean:

1. `rsync` the temp-dir PNGs over `docs/figures/example0{1..5}/`.
2. The regenerated `manifest.json` updates `generated_at`, `matlab_version`; `seed=0` is unchanged. Commit alongside.
3. Verify [docs/paper_examples.md](../paper_examples.md) (the expanded gallery) still references existing files; update if any filename changed (filenames are stable in the current scripts — verify don't assume).
4. Eyeball the README on GitHub after push to confirm the 5 thumbnails render.

Commit message template:

```
docs(figures): regenerate README paper-example gallery against post-Phase-4 code

The figures committed 2026-03-05 (manifest generated_at) predate the Phase 0–4
modernization bug fixes for Bernoulli LL wrapping (acd57c7, d1e96cf), KS U-clamp
(ef01a82), DT branch reachability (f460aa8), and PPAF/PPHF time-indexing
(3ffebd5, bc5f879, 1bcb63e). The regenerated PNGs reflect the corrected math.
Per-figure triage in docs/verification/readme_figure_parity.md.
```

**Effort:** 15 minutes.

### A.5 — Acceptance gate for Phase A

Before proceeding to Phase B, all of the following must be true:

- [ ] `tools/build_paper_examples('FigureRoot', tempdir, 'Seed', 0)` returns without error.
- [ ] `docs/verification/readme_figure_parity.md` exists with a per-figure verdict for all ~27 PNGs.
- [ ] Zero `REGRESSION` items in the triage.
- [ ] In-tree PNGs match a fresh regen (run `build_paper_examples` a second time after the re-commit; pixel diff against tree should now be `IDENTICAL` for all).
- [ ] README renders correctly on GitHub.

## 4. Phase B — Policy codification (CLAUDE.md)

Add a section to `/Users/iahncajigas/projects/nstat/CLAUDE.md`. The project-level `CLAUDE.md` currently contains only authorial-voice instructions, no project policy — Phase B adds project policy below those.

### B.1 — The policy block

Append the following section to `CLAUDE.md`:

```markdown
## README figure parity (project policy)

The README's headline gallery (`README.md` → 5 thumbnails at
`docs/figures/exampleNN/fig01_*.png`) and the expanded gallery
(`docs/paper_examples.md`) are produced by `tools/build_paper_examples.m`
from the scripts under `examples/paper/`. The PNGs are committed; they ARE
the documentation and they ARE what GitHub renders.

Any change that could alter the rendered output of those examples MUST
either confirm zero pixel drift or commit regenerated figures alongside
the code change. Specifically, this applies when modifying:

- `examples/paper/exampleNN_*.m` (the scripts themselves)
- `FitResult.m`, `Analysis.m`, `CIF.m`, `Covariate.m`, `SignalObj.m`
  (core toolbox classes consumed by every example)
- `+nstat/+decoding/*` (decoding cluster classes — affects Example 05)
- `+nstat/+plotting/*` and `tools/+nstat/applyPlotStyle.m`
  (plot-style migration affects every figure)
- `helpfiles/nSTATPaperExamples.m` (regression vector for the 2012 paper
  artifact)

Workflow:

1. Make the code change.
2. Run `tools/check_readme_figures.sh` (or its MATLAB entry point
   `tools/check_readme_figures.m`). It regenerates the gallery into a
   temp directory and pixel-diffs against `docs/figures/`.
3. If the diff is clean (all `IDENTICAL` or `TINY`), proceed.
4. If `SUBSTANTIVE` drift is reported, triage:
   - Correctness/cosmetic: regenerate `docs/figures/` and commit the
     PNGs alongside the code change. Reference the explanation in the
     commit message.
   - Unexplained: fix the regression before proceeding.

Do NOT bypass this for "doc-only" changes — the figures ARE docs.

Background and history of the original 2026-03→2026-05 drift incident:
[`docs/superpowers/plans/2026-05-20-readme-figure-parity.md`](docs/superpowers/plans/2026-05-20-readme-figure-parity.md).
```

### B.2 — Cross-link from CONTRIBUTING.md

Add to `CONTRIBUTING.md` under "Local test gate":

```markdown
### README figure parity

For changes that touch core fitting/decoding/plotting code, also run:

```bash
tools/check_readme_figures.sh
```

This regenerates the README paper-example gallery into a temp directory and
pixel-diffs against the committed PNGs in `docs/figures/`. See the project
`CLAUDE.md` "README figure parity" section for the full policy.
```

### B.3 — Acceptance gate for Phase B

- [ ] `CLAUDE.md` updated with the policy block (B.1).
- [ ] `CONTRIBUTING.md` updated with the cross-link (B.2).
- [ ] Both files committed in a single docs commit.

**Effort:** 15 minutes.

## 5. Phase C — Mechanization

### C.1 — `tools/check_readme_figures.m`

A MATLAB entry point that:

1. Resolves repo root via `nstat.docs.getRepoRoot()`.
2. Generates a unique temp directory under `tempdir`.
3. Calls `build_paper_examples('FigureRoot', tempDir, 'Seed', 0, 'Visible', 'off')`.
4. Iterates `docs/figures/example0N/*.png`, pixel-diffs against the temp regen.
5. Returns/prints a report with three buckets (`IDENTICAL` / `TINY` / `SUBSTANTIVE`).
6. Exit code zero iff no `SUBSTANTIVE` drift.

Pixel-diff in MATLAB: `imread` + `mean(abs(double(a)-double(b)), 'all') / 255`. Threshold matches the Python harness (mean Δ < 0.5/255 = TINY).

Skeleton (~60 LOC):

```matlab
function report = check_readme_figures(varargin)
  opts = parseOpts(varargin{:});
  repoRoot = nstat.docs.getRepoRoot();
  tempDir = fullfile(tempdir, sprintf('nstat_readme_regen_%s', ...
    char(java.util.UUID.randomUUID)));
  cleanup = onCleanup(@() rmdirIfExists(tempDir));
  build_paper_examples('FigureRoot', tempDir, 'Seed', 0, 'Visible', 'off');
  treeRoot = fullfile(repoRoot, 'docs', 'figures');
  report = compareTrees(treeRoot, tempDir, opts.TinyThreshold);
  printReport(report);
  if report.numSubstantive > 0 && opts.FailOnDrift
    error('nstat:readmeFigures:drift', ...
      '%d substantive figure drifts; see report.', report.numSubstantive);
  end
end
```

**Effort:** 1–2 hours including unit-style smoke test (`tests/unit/testCheckReadmeFigures.m` exercising the no-drift path with the regen-fresh tree).

### C.2 — `tools/check_readme_figures.sh`

Shell wrapper that mirrors `tools/run_unit_tests.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
MATLAB_BIN="${MATLAB_BIN:-/Applications/MATLAB_R2025b.app/bin/matlab}"
"$MATLAB_BIN" -batch "addpath(genpath('$(pwd)')); check_readme_figures();"
```

**Effort:** 10 minutes.

### C.3 — Optional pre-push hook integration

`CONTRIBUTING.md` already documents an opt-in `.git/hooks/pre-push` that runs `tools/run_unit_tests.sh`. Document the option to extend it to also run `tools/check_readme_figures.sh` — but **gated on touched-files heuristic** because a full regen is ~5–10 minutes (much slower than unit tests).

Suggested hook fragment:

```bash
touched=$(git diff --name-only HEAD @{u} 2>/dev/null || git diff --cached --name-only)
if echo "$touched" | grep -qE '^(examples/paper/|FitResult\.m|Analysis\.m|CIF\.m|Covariate\.m|SignalObj\.m|\+nstat/\+decoding/|\+nstat/\+plotting/|tools/\+nstat/applyPlotStyle\.m|helpfiles/nSTATPaperExamples\.m)'; then
  tools/check_readme_figures.sh
fi
```

This is **documented, not enforced** — the hook stays opt-in to match the existing `run_unit_tests.sh` precedent.

### C.4 — Acceptance gate for Phase C

- [ ] `tools/check_readme_figures.m` exists and produces a clean report against current `docs/figures/` (post-Phase-A re-commit).
- [ ] `tools/check_readme_figures.sh` exists and is executable.
- [ ] At least one unit-style smoke test exercises the no-drift path.
- [ ] Pre-push hook fragment documented in CONTRIBUTING.md.

**Effort:** 2–3 hours total for Phase C.

## 6. Sequencing and total effort

```
Phase A (verification)        2026-05-20  →  4–6 hours
  A.1 regenerate                    (10 min)
  A.2 pixel diff                    (30 min)
  A.3 triage                        (1–3 hr depending on regressions)
  A.4 re-commit                     (15 min)
  A.5 gate                          (5 min)

Phase B (policy)              same day    →  15 min
Phase C (mechanization)       same day    →  2–3 hr
                                          ────────
                              TOTAL          7–10 hours
```

Phases B and C can run in parallel after Phase A clears.

## 7. Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Example script signature drift since 2026-03-05 (a Phase-3 refactor broke an example's name-value contract) | LOW | The 2026-05-20 deep-dive plan's V1.4 verified all 5 examples execute cleanly. Re-run V1.4 if A.1 fails. |
| `SUBSTANTIVE` drift attributable to neither a known fix nor cosmetic migration (real regression) | LOW-MED | Triage step A.3 catches this. Budget exists in the 1–3hr triage window. If found, halt Phase B/C until fixed. |
| Pixel-diff threshold (0.5/255) is wrong for this dataset — too sensitive or too permissive | LOW | Empirically calibrated against the V3.1 MVP precedent which used the same threshold and worked. If misfires emerge, tune in C.1. |
| MATLAB R2025b vs R2024b/R2026a produce different anti-aliased text rendering | MED | Threshold tolerance handles this. Document the canonical MATLAB version in the policy. |
| Examples that produce stochastic output (despite `rng(0)`) cause irreducible drift | LOW | Verified in 2026-03-05 generation that seed=0 gives reproducible output. If a script introduces unseeded randomness, that itself is a bug — fix at the source, not the threshold. |

## 8. Rollback / abort criteria

Abort the plan and re-scope if any of the following:

- **>10 `REGRESSION` items in Phase A.3** — implies the modernization has unintended visual side-effects across many examples. Stop, escalate to a dedicated investigation rather than barreling through.
- **Phase A regen wall-clock >30 minutes** — would make the check too slow for routine pre-push use; revisit the mechanization design before locking it in as policy.
- **Pixel-diff false-positives recur after threshold tuning** — implies the diff approach is wrong; switch to perceptual-hash or structural-similarity (SSIM) instead.

## 9. Exit criteria (overall plan)

- [x] Plan written (this doc).
- [ ] Phase A completed; `docs/figures/` reflects current code.
- [ ] Phase B completed; policy is in `CLAUDE.md` and `CONTRIBUTING.md`.
- [ ] Phase C completed; `tools/check_readme_figures.{m,sh}` exist and pass.
- [ ] Single follow-up PR (or sequence of related PRs) merged to `master`.

Upon completion, this plan moves to status `COMPLETED` and the verification report at `docs/verification/readme_figure_parity.md` becomes the durable record.
