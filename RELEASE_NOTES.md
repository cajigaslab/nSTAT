# nSTAT Release Notes

## v1.4.0 — 2026-05-20

The first substantive release since the 2012 paper. Roughly two months of work (Phase 0 through Phase 4 of the [2026-05-19 nSTAT review action plan](docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md), the [2026-05-20 deep-dive verification](docs/superpowers/plans/2026-05-20-deep-dive-verification.md), the [2026-05-20 pre-mod ground-truth regression](docs/superpowers/plans/2026-05-20-pre-mod-ground-truth-regression.md), the [2026-05-20 README figure parity](docs/superpowers/plans/2026-05-20-readme-figure-parity.md), and the [2026-05-20 comprehensive codebase audit](docs/superpowers/plans/2026-05-20-comprehensive-codebase-audit.md)) consolidated into a single release.

This is a **drop-in upgrade** from v1.2/v1.3 — every public-API change ships with a deprecation shim that forwards to the new entry point and emits a one-time warning. No user code should break on the v1.4.0 upgrade.

### Why upgrade

The headline 2012 outputs (every figure in the README gallery; every paper example in `examples/paper/`) **encoded multiple math bugs** that propagated through the time-rescaling KS test, the PPAF/PPHF decoders, and the SSGLM EM iterations. v1.4.0 fixes those bugs. If you have run nSTAT on real data and trusted the KS goodness-of-fit statistic or the decoder traces, you should re-run on v1.4.0 and compare. The [pre-modernization regression report](docs/verification/pre_mod_comparison.md) documents which outputs change and by how much.

---

### Correctness fixes

These are the bugs whose fixes can change numerical output. If you have published or cached results from v1.2/v1.3, expect numerical drift in the affected families.

- **Bernoulli log-likelihood missing `log()` wrapper** (commits `acd57c7`, `d1e96cf`). `FitResult.computeLL` and `Analysis.GLMFit` computed `(1-y) .* (1 - λΔ)` instead of `(1-y) .* log(1 - λΔ)` for the binomial branch. **Effect:** AIC, BIC, and log-likelihood values were wrong for every Bernoulli fit. All downstream model comparison, KS curves, and confidence intervals derived from `logLL` change after the fix.
- **KS U-clamping before statistic computation** (`ef01a82`). `Analysis.computeKSStats` clipped the rescaled inter-event interval array `U` to `[0,1]` before computing `ks_stat`, masking true tail deviations and inflating apparent goodness-of-fit. **Effect:** KS verdicts move (typically: fits that "passed" the KS test now closer to or beyond the 95% band when the model is genuinely misspecified). The empirical pass rate on the curriculum's §4.C.1 Cor. 2 oracle was verified against the new code path in `tests/integration/testKsAgainstCurriculumZoo.m`.
- **DT-correction KS branch unreachable** (`f460aa8`). For any data with `λΔ > 0.4`, the discrete-time variant of the KS test (Haslinger–Pipa–Brown 2010 correction) was supposed to fire but never did because `setMinTime`/`setMaxTime` clobbered the cached `isSigRepBin` flag. **Effect:** examples in the high-rate regime were silently using the continuous-time KS formula. A new warning `nSTAT:DTCorrectionRegime` now fires when input data is in the DT regime to surface the regime change to callers.
- **PPAF goal-directed predict time-indexing** (`3ffebd5`). The goal-directed branch of `PPDecodeFilter` indexed `A`, `Q`, and the goal-vector at the wrong time slice. **Effect:** Example 05 fig04 (PPAF goal vs free) outputs drift; the previous trace was based on off-by-one time-indexed dynamics.
- **PPHF time-indexing + missing x0/Pi0 goal fusion** (`bc5f879`, `1bcb63e`, `ba7069a`). `PPHybridFilter(Linear)` had a one-step time-index error on `A`/`Q`, and the goal-aware path was missing the initial-state goal fusion entirely. **Effect:** Example 05 fig05/fig06 (hybrid filter outputs) change in the goal-aware branch. The linear vs nonlinear variants now agree.
- **FitResult multi-result λ indexing** (`1520034`). In the multi-result branch of `FitResult.plotLambda`, `newLambda.data` was used without indexing by the loop variable, so every fit in a multi-result comparison was plotted using result-1's λ. **Effect:** Example 03 SSGLM stimulus-effect surface plots now display per-result λ correctly.
- **`plotSeqCorr` overflow and non-finite filtering** (`f5b5734`). The inverse-Gaussian U-transform produced `Inf`/`NaN` for marginal cases; downstream code did not filter them, propagating non-finite values into autocorrelation plots. **Effect:** invGausTrans subplots in Examples 01–03 no longer have rendering artifacts.
- **`Analysis.ksdiscrete` clobbered caller-set RNG seed** (`f2307e9`). The bootstrap KS path called `rng('shuffle','twister')` internally, breaking reproducibility for any caller that had set a seed. **Effect:** `rng(0)`-based reproducibility now works end-to-end through KS-discrete code paths.
- **`sampeRate` typo, `containsChars` logic, `logLL` undefined vars** (`6f6eb13`). Three latent defects in adjacent code paths surfaced and fixed.

The full pre-modernization regression test ([docs/verification/pre_mod_comparison.md](docs/verification/pre_mod_comparison.md)) shows: **19 of 19 evaluated outputs IDENTICAL** to the pre-modernization baseline on the V3.1 MVP harness, with all numerical-output diffs attributable to the listed correctness fixes (visualized in the [README figure parity report](docs/verification/readme_figure_parity.md)).

### Architectural cleanup

These are refactors. They do not change algorithmic behavior; every legacy entry point still works through a deprecation shim.

- **`+nstat/+decoding/` package** — eight algorithm-specific classes (`KalmanFilter`, `UKF`, `PPAF`, `PPHF`, `PPLFP`, `SSGLM`, `KF_EM`, `PointProcessEM`) extracted from the 10860-line `DecodingAlgorithms.m`. The legacy class is now a 1189-line facade with 47 deprecation shims forwarding to the package.
- **`mPPCO_*` → `PPLFP_*` rename** (paper §4.B.7 alignment). The historical `mPPCO_*` family was poorly named; `mPPCO` is the *PPLFP* (point-process + LFP sensor fusion) filter, not a separate algorithm. New canonical names are in `nstat.decoding.PPLFP`. The nine `mPPCO_*` static methods on `DecodingAlgorithms` are deprecation shims forwarding to the package.
- **Woodbury matrix update centralized** in `+nstat/+decoding/+internal/computeGainMatrix.m`. Previously duplicated across `PPDecode_update`, `PPDecode_updateLinear`, `mPPCODecode_update`, and the hybrid variants.
- **`nstat.Defaults`** — a single class with named constants (`EM_TolAbs=1e-3`, `EM_MaxIter=100`, `DTRegimeBound=0.4`, `KS_NumIters=10`, …). Previously these were magic-number literals scattered across `DecodingAlgorithms`, `Analysis`, and the EM paths.
- **`nstat.setPlotStyle('modern' | 'legacy')`** — plot-style toggle. `'modern'` (default) is the readability-focused style; `'legacy'` reproduces the 2012 paper's visual style verbatim, primarily for figure regeneration parity.

### New capabilities

- **`LinearCIF`** — canonical-link conditional intensity function with **closed-form gradient and Hessian** for the Poisson and binomial canonical links. A drop-in replacement for `CIF` where the Symbolic Math Toolbox dependency is undesirable: `LinearCIF`'s derivative computation is analytic and Symbolic-free at eval time. (Construction still uses `sym(...)` for variable-name compatibility with the existing `CIF` interface contract; see [symbolic dependency audit](docs/verification/symbolic_dependency_audit.md) for the full discussion and the future-work fix shape.)
- **`History.raisedCosine(K, tMin, tMax)`** — Pillow 2008 log-spaced raised-cosine basis. Static constructor for `History`. Default bounds `tMin=0.002`, `tMax=0.100` (seconds).
- **Iterated-Laplace PPAF update** — `nstat.decoding.PPAF.PPDecode_updateIterated` and `PPDecode_updateLinearIterated` implement the iterated-Laplace step from Eden et al. 2004 (Algorithm 2), with the missing prior-gradient correction term that the original single-Newton update omits. Exposed but not yet wired into the top-level `PPDecodeFilter` — opt-in via direct call. See [PR #36](https://github.com/cajigaslab/nSTAT/pull/36) for the math derivation.
- **KS oracle integration test** — `tests/integration/testKsAgainstCurriculumZoo.m` runs the curriculum's §4.C.1 Cor. 2 KS-validation pipeline against simulated point processes and asserts the empirical pass rate matches the analytic null distribution to within tolerance. Validates the entire fit → KS path end-to-end.

### Developer experience

These are infrastructure additions that do not affect runtime behavior. They make the toolbox testable and releasable.

- **Local test gate** (`tools/run_unit_tests.sh`) — 20 unit tests + 1 integration test cover every bug-class fix. Replaces the failed-MATLAB-CI experiment ([PR #36](https://github.com/cajigaslab/nSTAT/pull/36) reverted in [PR #38](https://github.com/cajigaslab/nSTAT/pull/38)). CI no longer runs MATLAB; the local gate is canonical.
- **README figure parity** (`tools/check_readme_figures.sh`) — regenerates the `docs/figures/` paper-example gallery and pixel-diffs against the committed PNGs. Three-bucket classification (`IDENTICAL` / `TINY` / `SUBSTANTIVE`) plus a `NONDETERMINISTIC` allowlist for three Example 03 figures whose drift is intrinsic to multi-threaded BLAS reduction order in SSGLM EM. See [PR #42](https://github.com/cajigaslab/nSTAT/pull/42) and [docs/verification/readme_figure_parity.md](docs/verification/readme_figure_parity.md).
- **One-command deploy gate** (`tools/predeploy.sh`) — chains unit tests, integration tests, README figure parity, helpfile HTML republish, helpsearch rebuild, helptoc lint, and sibling-bug-pattern audit. ~30–45 minute wall clock; the canonical pre-tag check. See [`CONTRIBUTING.md`](CONTRIBUTING.md) "Release & regeneration".
- **Release stamping** (`tools/stamp_release.m`) — updates `Contents.m` version stamp, manifest `generated_at`, and the next `RELEASE_NOTES.md` section template. Idempotent. Run after the deploy gate passes; before `git tag`.
- **Bug-pattern audit** (`tools/check_bug_patterns.sh`) — `grep` over 11 known-bad patterns (Bernoulli LL wrap, `isa('nan')`, `eval()`, `histc`, `roundn`, `rng('shuffle')`, `symvar` reorder, `sampeRate` typo, `log(0)`, silent `catch`, `.^2`/`.^3` confusions). Informational; not a release blocker. Triage 2026-05-20: 0 actionable sibling defects.
- **Help-system integrity** — [docs/verification/helpsystem_audit.md](docs/verification/helpsystem_audit.md) documents the `helptoc.xml` ↔ `.html` ↔ `.m` ↔ search-index audit. 8 previously-missing TOC entries added (including the canonical onboarding `HelloNstat` and the `WhenToUseWhich` decision tree).

### Backward compatibility

**No breaking changes.** Every renamed or moved entry point is backed by a deprecation shim:

- `DecodingAlgorithms.PPDecode_*(...)` → forwards to `nstat.decoding.PPAF.PPDecode_*(...)`.
- `DecodingAlgorithms.PPHybrid*(...)` → forwards to `nstat.decoding.PPHF.PPHybrid*(...)`.
- `DecodingAlgorithms.mPPCO_*(...)` → forwards to `DecodingAlgorithms.PPLFP_*(...)` → forwards to `nstat.decoding.PPLFP.*(...)`.
- `DecodingAlgorithms.PPSS_*(...)` → forwards to `nstat.decoding.SSGLM.*(...)`.
- `DecodingAlgorithms.KF_*(...)` → forwards to `nstat.decoding.KalmanFilter.*(...)` or `nstat.decoding.KF_EM.*(...)` depending on the method.

Each shim emits `nSTAT:deprecated:DecodingAlgorithms` (warning-only, suppressible with `warning('off', 'nSTAT:deprecated:DecodingAlgorithms')`). Internal state (input/output shapes, side-effect order, RNG-consumption pattern) is preserved at the shim level. The 9-strong `tests/unit/testNstatDecoding*.m` suite verifies numerical parity between the facade and the package classes to `AbsTol 1e-12`.

### Migration guidance (from v1.2 / v1.3)

For most users: **install, re-run, compare**. If you have cached numerical results that you trust, expect drift in:
- Any Bernoulli AIC/BIC or log-likelihood value.
- Any KS goodness-of-fit p-value where `max(U) > 0.95` or `min(U) < 0.05`.
- Any PPHF goal-directed decoder trace.
- Any PPAF goal-directed decoder trace.
- Any SSGLM multi-trial λ plot (now correctly per-trial-indexed).

For users writing new code: prefer the package API.

```matlab
% v1.2/v1.3 style — still works, emits a deprecation warning
[x_p, W_p] = DecodingAlgorithms.PPDecode_predict(x_u, W_u, A, Q);

% v1.4 idiomatic
[x_p, W_p] = nstat.decoding.PPAF.PPDecode_predict(x_u, W_u, A, Q);
```

For users writing new GLM-based pipelines without the Symbolic Math Toolbox: use `LinearCIF` instead of `CIF` for canonical-link cases.

For users who relied on the `helpfiles/*.mlx` Live Scripts: those that drifted from their `.m` siblings during this work were deleted ([PR #39](https://github.com/cajigaslab/nSTAT/pull/39)). The **one exception** is `helpfiles/nSTATPaperExamples.mlx`, kept as a citation-bound historical artifact of the 2012 paper ([PR commit `7b8b369`](https://github.com/cajigaslab/nSTAT/commit/7b8b369)). The canonical, warning-free re-run path is the `.m` file directly.

### Known issues / non-blocking follow-ups

These are tracked but not blocking the release. See [docs/verification/comprehensive_audit_summary.md](docs/verification/comprehensive_audit_summary.md) for the full list.

- **80 unreferenced `.png` files** in `helpfiles/`, mostly equation rasters from older `publish()` runs. Disk-bloat cleanup; not affecting users.
- **1567 stylistic `checkcode` findings** (0 definite-error severity) across 29 core files. Opportunistic-cleanup backlog. See [docs/verification/checkcode_summary.md](docs/verification/checkcode_summary.md).
- **`LinearCIF` Symbolic Math Toolbox dependency at construction time** (not eval time). Fix shape: redefine `varIn`/`stimVars` properties as `cellstr` instead of `sym`. ~6–8 hr refactor. See [docs/verification/symbolic_dependency_audit.md](docs/verification/symbolic_dependency_audit.md).
- **`Analysis.m:609` empty-`b` defect** — `glmfit` returning an empty coefficient vector triggers a downstream `undefined data` reference. ~30 min surgical fix. Tracked as B3 in [docs/verification/remediation_backlog.md](docs/verification/remediation_backlog.md).
- **Legacy `helpfiles/helpsearch/` and `helpsearch-v3/` directories** retained from pre-R2025b MATLAB versions. The current search index lives in `helpsearch-v4_en/`. Cleanup deferred.

### Recommended deploy procedure for future releases

Documented in [`CONTRIBUTING.md`](CONTRIBUTING.md) "Release & regeneration":

```bash
tools/predeploy.sh                                    # ~30–45 min gate
matlab -batch "addpath('tools'); tools.stamp_release('vX.Y.Z')"
git add Contents.m docs/figures/manifest.json RELEASE_NOTES.md
git commit -m "release(vX.Y.Z): stamp version + manifest"
git tag vX.Y.Z
git push origin master --tags
```

### Citation

If you use nSTAT in your work, please cite:

> Cajigas I, Malik WQ, Brown EN. nSTAT: Open-source neural spike train analysis toolbox for Matlab. *J Neurosci Methods* 211: 245–264, Nov. 2012.
> DOI: [10.1016/j.jneumeth.2012.08.009](https://doi.org/10.1016/j.jneumeth.2012.08.009)
> PMID: 22981419

The 2012 paper remains the canonical reference for the toolbox's design and the foundational point-process / state-space methods. Subsequent updates are documented in `RELEASE_NOTES.md` (this file), the `docs/superpowers/plans/` directory (action plans + verification protocols), and the `% FIX:` inline tags throughout the codebase.

---

## Pre-v1.4 history

### v1.2 — 2026-03-10

The original 2026-03-10 5-phase audit identified and fixed 67 bugs across 8 core files (FitResult.m KS bin-width inversion, DecodingAlgorithms isa('nan') always-false, CIF symvar reorder, SignalObj findPeaks crash, nspikeTrain burst detection, etc.). All changes tagged with `% FIX:` inline comments. See [AUDIT_REPORT.md](AUDIT_REPORT.md) for the full historical record.

### v1.0 — 2012-11

Original release accompanying Cajigas, Malik, Brown 2012 (*J. Neurosci. Methods* 211: 245–264). Time-rescaling KS goodness-of-fit, PPAF, PPHF, SSGLM, multimodal PPLFP (originally named `mPPCO_*`). See `helpfiles/nSTATPaperExamples.{m,mlx}` for the paper-figure-reproducing artifact.
