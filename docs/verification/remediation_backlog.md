# Remediation Backlog — Surfaced by 2026-05-20 Verification

> **Source:** Phase V4 of [`docs/superpowers/plans/2026-05-20-deep-dive-verification.md`](../superpowers/plans/2026-05-20-deep-dive-verification.md).
> **Companion:** [`REPORT.md`](REPORT.md), [`v1_4_triage_report.md`](v1_4_triage_report.md).
> **Status:** items below are tracked for follow-up PRs; verification does not fix them per the plan's verification-vs-remediation separation.

## Tier 1 — Confirmed broken (or about to be); ship as soon as possible

### B1 — Delete `helpfiles/nSTATPaperExamples.mlx`

**Confirmed broken:** the `.mlx` shadows the migrated `.m` and emits `nSTAT:deprecated:DecodingAlgorithms`. Trap-via-`warning('error', ...)` verification traced the warning to inside `.mlx` execution.

**Fix:** `git rm helpfiles/nSTATPaperExamples.mlx`. Same pattern as PR #39 for the 4 already-deleted stale `.mlx` files.

**Effort:** 5 minutes. Single-file change. **High priority.**

**Acceptance:** post-deletion, re-run V1.4 — `nSTATPaperExamples` should report PASS (clean), bringing the suite to 34/34 PASS clean.

---

## Tier 2 — Latent but real risks

### B2 — Delete the 11 other stale `.mlx` helpfiles

11 `.mlx` files are stale by git-log timestamp (their `.m` siblings have newer commits) but currently execute cleanly. They're a maintenance bomb — any future `.m` edit that breaks the API will not be reflected in the `.mlx`, repeating the `nSTATPaperExamples` pattern.

| File | `.m` newer by |
|---|---|
| `helpfiles/AnalysisExamples2.mlx` | 2.7 days |
| `helpfiles/CovCollExamples.mlx` | 14.7 days |
| `helpfiles/Examples.mlx` | 2.7 days |
| `helpfiles/ExplicitStimulusWhiskerData.mlx` | 9.5 hours |
| `helpfiles/FitResSummaryExamples.mlx` | 14.7 days |
| `helpfiles/FitResultExamples.mlx` | 14.7 days |
| `helpfiles/HippocampalPlaceCellExample.mlx` | 2.7 days |
| `helpfiles/NetworkTutorial.mlx` | 12.4 days |
| `helpfiles/SignalObjExamples.mlx` | 15.4 hours |
| `helpfiles/TrialExamples.mlx` | 14.7 days |
| `helpfiles/mEPSCAnalysis.mlx` | 9.5 hours |

**Fix shape:** `git rm` all 11. Apply the `CONTRIBUTING.md` policy ("when `.mlx` drifts, prefer deletion") uniformly.

**Trade-off:** users who relied on `.mlx` for the embedded-output Live Script experience lose it (they can regenerate from `.m` via Live Editor). The current state is *worse* — embedded outputs may be from a pre-migration code path with deprecated API calls baked in.

**Effort:** 15 minutes. Single PR. **Medium priority.**

**Acceptance:** post-deletion, no `helpfiles/*.mlx` exists for any `.m` that has been edited post-Feb-2026. Run V1.4 to confirm 23/23 PASS clean.

### B3 — Pre-existing `Analysis.m:609` defect (empty-`b` from glmfit)

When `Analysis.GLMFit` calls `glmfit` on a design matrix that produces empty coefficient vector (zero-column or rank-zero design), the variable `data` on line 609 is undefined when the subsequent `Covariate(lambdaTime, data, ...)` call references it. Surfaces only when a `TrialConfig` resolves to no design-matrix columns.

**Fix shape:** initialize `data` before the `if(length(b)>=1)` block, or wrap the Covariate construction in an `isempty(b)` guard.

**Effort:** 30 minutes (small surgical fix + unit test for the empty-`b` case).

**Acceptance:** new unit test exercises the empty-`b` path; `Analysis.GLMFit` either returns a clear error or a sensible empty `lambda` Covariate.

---

## Tier 3 — Numerical concern (out of scope without paper PDF)

### B4 — `example03_psth_and_ssglm` `stats:glmfit:IterationLimit`

The Phase 4.2 verification subagent surfaced this and the V1.4 run confirms it: `glmfit` doesn't converge within its default iteration limit on at least one fit configuration in `example03`. Pre-existing — not introduced by Phase 0-4.

**Investigation needed:** compare un-converged vs converged coefficient estimates against the 2012 paper's published Fig. 5 / 12 values. If un-converged estimates are visually indistinguishable from the paper, the warning is benign (just MATLAB's default cap being conservative). If they diverge significantly, the iteration limit should be raised OR the design matrix should be regularized.

**Effort:** 1-3 hours (paper-value lookup + comparison).

**Acceptance:** either (a) confirm the un-converged values match the paper figures, OR (b) raise the iteration limit / regularize the design and re-verify.

### B5 — V2.1 paper-value comparison (all 5 paper examples)

The verification plan's V2.1 phase calls for comparing 5 paper-example numerical outputs against the published 2012 paper values (KS stats, lag estimates, coefficient comparisons). This requires PDF lookup or PMC HTML scraping.

**Fix shape:** create `docs/verification/paper_accuracy_table.md` with a side-by-side table (paper value, current value, deviation, status) for each example.

**Effort:** 2-4 hours (open paper PDF in parallel; extract key numerics from each figure caption + main text; compare).

**Acceptance:** within 5% on continuous values; exact match on pass/fail KS verdicts; sign and order-of-magnitude on coefficients.

---

## Tier 4 — Polish (low priority)

### B6 — Migration of `tests/python_port_fidelity/` callers to `nstat.decoding.*`

Currently the cross-language parity tests intentionally call `DecodingAlgorithms.PPDecode_predict` via the deprecation shim (verifying that the shim chain works). Either:
- Keep as-is (shim chain testing is a feature).
- Migrate to `nstat.decoding.PPAF.PPDecode_predict` (matches the rest of the migration; cross-language parity tested via the new canonical API).

**Effort:** 1-2 hours coordinated with the Python port.

### B7 — `LinearCIF` γ-coefficient derivatives

PR #34 added `LinearCIF` for closed-form derivatives w.r.t. stimulus state. The Task 3.5 subagent flagged that γ-coefficient derivatives (`evalGradientLDGamma`, `evalJacobianLogLDGamma`) are not implemented in `LinearCIF`. Not called by `PPDecode_update`, but used by the EM M-step. Implementing them would let `Analysis.GLMFit`-via-EM drop the Symbolic Math Toolbox dependency entirely.

**Effort:** 4-6 hours (math derivation + parity tests).

### B8 — Forward-pass `NewtonIters` integration

PR #36's Phase 4.1 added iterated-Laplace PPAF as `PPDecode_updateIterated`. Wiring this into `PPDecodeFilter` / `PPDecodeFilterLinear` as a name-value argument would expose iterated Laplace via the canonical filter entry point.

**Effort:** 1-2 hours (plumbing; math is settled).

### B9 — Relocate 5 shared helpers to `+nstat/+decoding/+internal/`

`prepareEMResults`, `ComputeStimulusCIs`, `estimateInfoMat`, `computeSpikeRateCIs`, `computeSpikeRateDiffCIs` still live on `DecodingAlgorithms`. Phase 3.2 partition design said they'd eventually move to `+nstat/+decoding/+internal/`. Mechanical refactor with established pattern.

**Effort:** 2-3 hours.

---

## Suggested execution order

If you commit to remediation:

1. **B1** (5 min) — ship as a same-day PR. Closes the only confirmed-broken item.
2. **B2** (15 min) — ship in the same or next PR. Closes the broader stale-`.mlx` class of risk.
3. Pause and re-evaluate. The toolbox is now in citation-ready state.
4. If still motivated: **B5** (paper-value comparison) is the next-most-valuable item — it's what makes V2.1 complete and the citation-ready snippet stronger.
5. Defer **B3, B4, B6-B9** unless a specific consumer surfaces them. They're real but low-urgency.
