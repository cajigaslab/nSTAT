# V1.4 Tier-B Triage Report

> **Date:** 2026-05-20
> **Branch:** `verify/phase-v0-v1`
> **Master HEAD:** `4303305`
> **MATLAB:** R2025b
> **Source plan:** [`docs/superpowers/plans/2026-05-20-deep-dive-verification.md`](../superpowers/plans/2026-05-20-deep-dive-verification.md)
> **Run report:** [`run_report_20260520-134941.json`](run_report_20260520-134941.json)

## Headline

**22 PASS / 1 PASS-W / 0 FAIL of 23 Tier-B helpfiles.** Failure rate **0%**, deprecation-warning rate **4.3%** (1 of 23). Total runtime ~12 min.

**Re-scope decision: continue full plan (V2/V3/V4).** Phase 0-4 modernization was thorough; the remaining work is high-quality polish rather than bug-fixing.

## Per-script status

| # | Script | Status | Runtime | Figures captured |
|---|---|---|---|---|
| 1 | AnalysisExamples | ✅ PASS | 2.4s | 4 |
| 2 | AnalysisExamples2 | ✅ PASS | 386.8s | 4 |
| 3 | ConfigCollExamples | ✅ PASS | 0.1s | 0 |
| 4 | CovCollExamples | ✅ PASS | 0.5s | 2 |
| 5 | CovariateExamples | ✅ PASS | 0.4s | 2 |
| 6 | EventsExamples | ✅ PASS | 0.2s | 3 |
| 7 | FitResSummaryExamples | ✅ PASS | 0.0s | 0 |
| 8 | FitResultExamples | ✅ PASS | 0.0s | 0 |
| 9 | HistoryExamples | ✅ PASS | 0.5s | 3 |
| 10 | PPThinning | ✅ PASS | 8.9s | 3 |
| 11 | SignalObjExamples | ✅ PASS | 2.4s | 16 |
| 12 | TrialConfigExamples | ✅ PASS | 0.0s | 0 |
| 13 | TrialExamples | ✅ PASS | 2.5s | 6 |
| 14 | ValidationDataSet | ✅ PASS | 14.2s | 8 |
| 15 | nSpikeTrainExamples | ✅ PASS | 0.4s | 4 |
| 16 | nstCollExamples | ✅ PASS | 1.5s | 3 |
| 17 | NetworkTutorial | ✅ PASS | 45.8s | 4 |
| 18 | PPSimExample | ✅ PASS | 13.5s | 3 |
| 19 | PSTHEstimation | ✅ PASS | 7.0s | 2 |
| 20 | ExplicitStimulusWhiskerData | ✅ PASS | 11.9s | 8 |
| 21 | HippocampalPlaceCellExample | ✅ PASS | 29.6s | 9 |
| 22 | mEPSCAnalysis | ✅ PASS | 37.4s | 4 |
| 23 | nSTATPaperExamples | ⚠️ PASS-W | 137.7s | 4 |

## Failure-category counts

- **A. Stale `.mlx` shadowing `.m`:** 1 (nSTATPaperExamples — the 4.3% PASS-W)
- **B. Removed MATLAB API:** 0
- **C. Missing data:** 0
- **D. Script-level bug:** 0
- **E. Quarantine (out-of-scope):** 0

## Detailed analysis of the single PASS-W

### `nSTATPaperExamples.m` — Category A (stale .mlx)

**Warning emitted:** `nSTAT:deprecated:DecodingAlgorithms`

**Root cause (verified via `warning('error', ...)`-trap):** `helpfiles/nSTATPaperExamples.mlx` (2.4 MB, last touched 2026-02-24, predating the Phase 3.5b migration of `0932b08`) shadows the `.m` file. MATLAB's `run('nSTATPaperExamples')` resolves to the `.mlx`, which still contains pre-migration `DecodingAlgorithms.{PPDecodeFilter*, PPHybridFilter*, PPSS_*}` calls. The `.m` file was migrated to `nstat.decoding.*` in PR #36 commit `0932b08` and emits zero deprecation warnings when run directly.

**Verification:** trap script at `/tmp/trace_deprecation.m` confirmed the deprecation is triggered from inside `nSTATPaperExamples.mlx` execution (file shadowing also reported by MATLAB).

**Proposed fix shape (remediation, OUT OF SCOPE FOR THIS COMMIT):** delete `helpfiles/nSTATPaperExamples.mlx`. The `.m` runs cleanly. Same pattern as PR #39 for the 4 migrated helpfiles.

## Additional finding: 11 more stale-by-timestamp .mlx files

A timestamp comparison surfaced 12 `.mlx` files (including `nSTATPaperExamples.mlx` above) whose `.m` sibling has a newer last-commit-time:

| File | .m newer by |
|---|---|
| AnalysisExamples2.mlx | 2.7 days |
| CovCollExamples.mlx | 14.7 days |
| Examples.mlx | 2.7 days |
| ExplicitStimulusWhiskerData.mlx | 9.5 hours |
| FitResSummaryExamples.mlx | 14.7 days |
| FitResultExamples.mlx | 14.7 days |
| HippocampalPlaceCellExample.mlx | 2.7 days |
| NetworkTutorial.mlx | 12.4 days |
| SignalObjExamples.mlx | 15.4 hours |
| TrialExamples.mlx | 14.7 days |
| mEPSCAnalysis.mlx | 9.5 hours |
| **nSTATPaperExamples.mlx** | **70 days (verified breaking)** |

**Important:** these 11 are stale by *timestamp*, but the V1.4 run shows their `.mlx` versions all execute without errors or deprecation warnings — meaning the corresponding `.m` edits were either cosmetic (comments, docstring fixes) or didn't break the `.mlx` API. The single confirmed breaker is `nSTATPaperExamples.mlx`.

**Proposed fix shape (remediation, OUT OF SCOPE FOR THIS COMMIT):** delete all 12 stale `.mlx` files. This applies the policy documented in `CONTRIBUTING.md` ("If an `.mlx` drifts from its `.m`, prefer deleting it") uniformly. Aggressive but defensible — the `.m` is the source of truth, and a `.mlx` that drifts silently is a packaging bug waiting to happen. Single PR; pure `git rm`; no functional change for users who run the `.m` directly.

## Re-scope check

Plan-defined thresholds:
- **<20% failure rate → continue full plan.** ✅ We're at 0%.
- 20-50% → narrow V2/V3/V4 to Tier A + paper examples.
- \>50% → pause and rescope.

**Decision: continue full plan.** Phase 0-4 modernization was thorough; the toolbox is in genuinely good shape. V2 (numerical accuracy) and V3 (visual inspection) are about confirming that the *passing* scripts produce correct output, not about finding more failures.

## Artifacts

- Machine-readable run report: `docs/verification/run_report_20260520-134941.json`
- Per-script captured figures: `docs/figures/verify_<ScriptName>/fig*.png` (totals: ~95 figures across the 23 scripts)
- Harness used: `tools/verify_all_examples.m`
- Trace-deprecation script: `/tmp/trace_deprecation.m` (not committed; one-off diagnostic tool)

## Next steps in the plan

- **V1.1-V1.3 confirmation pass** (~30 min): re-run paper examples + tutorials + Tier-A migrated helpfiles through the same harness for consistency; verify the prior PR #36/#39 verifications still hold.
- **V2 numerical accuracy** (~4-6 hr): compare paper-example outputs to published 2012 values; check tutorial self-consistency.
- **V3 visual inspection** (~6-8 hr): assemble figure gallery, manual review.
- **V4 report + backlog** (~2-3 hr): synthesize; the 12 stale `.mlx` cleanup goes in the backlog.
