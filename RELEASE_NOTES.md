# nSTAT Release Notes

## v1.5.2 — 22-Jun-2026

Patch release focused on the publish pipeline (substantial performance work + two distinct orphan-figure fixes), a paper-example RNG-fragility fix that was breaking the README parity gate, restoration of the deferred pedagogical figures from v1.5.1, and docs-tree hygiene. No API changes; no breaking changes. End users on v1.5.1 should upgrade — the orphan-figure fixes silently improve every shipped helpfile HTML.

### Correctness fixes

| PR | Class | Site | Effect |
|---|---|---|---|
| #121 | doc | `helpfiles/nSTATPaperExamples.m` (Experiment 2 stim-lag + history) | Three `%%` sections at lines 308 / 351 / 367 were jointly building a single composite figure (xcorr + KS/AIC/BIC scan + KS plot + GLM coefficients). `publish()` snapshots open figures at every section boundary, so the composite was captured three times — twice in partial-build states (xcorr-panel-only orphans) and once when complete. Collapsed the three section markers into one so `publish()` snapshots the figure once, fully built. 28 → 26 figure PNGs in `nSTATPaperExamples.html`. |
| #122 | numerical | `examples/paper/example05_decoding_ppaf_pphf.m` (hybrid filter blocks) | Function seeded RNG once at line 33 and let the seed propagate through three example blocks. When upstream `rand`/`randn` call counts shifted (e.g., from a numerical-tolerance change in `CIF.simulateCIF…`), the RNG state at the hybrid block diverged and `fig05_hybrid_setup.png` / `fig06_hybrid_decoding_summary.png` drifted (meanAbsDelta 0.6126 / 1.3377) — failing the predeploy README parity gate. Fix: re-seed `rng(opts.Seed, 'twister')` immediately before each fixture-producing block. Per-block RNG re-seed makes each figure reproducible regardless of upstream call-count changes. Rebaselined 22 `docs/figures/exampleNN/` PNGs to the deterministic R2026a Update 3 outputs. |
| #123 | doc | `helpfiles/nSTATPaperExamples.m` (Experiment 6 hybrid filter) | Second instance of the orphan-figure antipattern in the same file, different shape: a composite figure at line 1665 leaked into the text-only `%% Experiment 6 …` / `%% Problem Statement` sections before the next `close all;`. `publish()` re-snapshotted the same handle at each text-only section boundary. Fix: add `close all;` at the start of each affected titled section per the Phase B convention. 26 → 25 figure PNGs. |

### Performance — publish pipeline

The four-phase rebuild of `helpfiles/publish_all_helpfiles.m` brings the canonical full-publish from **~18.8 min → 8.2 min** (parallel), and an iteration warm-cache run to **~30-40 s**.

| PR | Phase | Change | Win |
|---|---|---|---|
| #116 | A | Per-file timing report at `docs/verification/publish_timing_latest.md` (gitignored, regenerated each run). Ranks every helpfile by wall-clock with figure count, section count, and a `snapshots/figure` ratio — the latter surfaces leaked open figures across `%%` boundaries. | Surfaces single-file regressions in PR diffs. |
| #116 | B | `close all;` convention between `%%` sections, applied across 7 helpfiles (`DecodingExample`, `ExplicitStimulusWhiskerData`, `HippocampalPlaceCellExample`, `NetworkTutorial`, `PPThinning`, `SignalObjExamples`, `TrialExamples`). Eliminated 13 duplicate-figure captures from the historical corpus. | 35 close-all inserts; 0 analysis-code changes. |
| #116 | C | `parfor` over the 36 helpfile publishes (independent per-file outputs into a shared output dir). Class references continue serially (~4 s of work each). | 18.8 min → 8.2 min wall-clock. |
| #117 | D | Per-file content-hash cache at `helpfiles/.publish-cache.json` (gitignored). Skips a helpfile when its `globalHash` (toolbox `.m` + MATLAB version + publish opts) **and** its own `fileHash` are unchanged AND every cached output is still on disk. On a full cache HIT, `builddocsearchdb` is also skipped. `tools/predeploy.sh` forces a full rebuild via `Force=true`. | Warm iteration: 8.2 min → **30-40 s** (~12× speedup). Per-file invalidation: 30 s + the slowest single rebuild. |

### New capabilities

- **Pedagogical figure additions** (PR #115) — closes issues #81, #82, #83, #84, #85, #86, #102. Re-attempt of the figure work that was rolled back in PR #105 and explicitly deferred in v1.5.1's "Out of scope" section. Stable after the publish-pipeline hardening above.

### Documentation

- **CONTRIBUTING.md — publish pipeline architecture** (PR #118). New subsection under "Release & regeneration" walks through the four phases (A/B/C/D), documents the two contracts a future change must respect (the `globalHash` dependency-set contract and `predeploy.sh`'s `Force=true` requirement), and explains why the cache file is gitignored / per-machine / per-MATLAB.
- **`helpfiles/DocumentationSetup2025b.{m,html}` → `DocumentationSetup.{m,html}`** (PR #120). Collapsed the version-suffixed file to evergreen. The page's content is 95% MATLAB-toolbox-documentation-layout boilerplate; only one line was genuinely version-specific. Removing the suffix and that one line eliminates the per-release rename treadmill. References updated in `helpfiles/helptoc.xml` (target/id/label) and `helpfiles/NeuralSpikeAnalysis_top.{m,html}`.

### Repo hygiene

- **`docs/figures/` prune** (PR #119). After two completed verification audits (2026-03 and 2026-05), their output snapshots were sitting in the docs tree but referenced by nothing — no README link, no release gate, no downstream tool. Removed 22 `docs/figures/verify_*/` directories (~6.4 MB) + the legacy/modern paper-example comparison artifacts (~7.5 MB) + the now-orphan producer tools `tools/verify_all_examples.m` and `tools/publish_examples.m`. Stale references in `tools/audit_help_system.py`, `AGENT_GUIDE.md`, and `docs/DEVPLAN.md` corrected as part of the clean break. Surviving `docs/figures/` contents are exactly the artifacts that `README.md` and `AGENT_GUIDE.md` reference: `example01–05/`, `manifest.json`, `simulink/`. Net: **22 MB → 9.2 MB**.

### Breaking changes

None.

### Out of scope (deferred to v1.6 or later)

- **Phase E** — `figureSnapMethod` tuning to further reduce cold-publish time. Lower marginal value now that the Phase D incremental cache makes warm iteration cheap; pick up if cold-publish time becomes a problem again.
- **Defensive RNG pinning in `example01..04`** — example05 had the per-block re-seed pattern applied in #122, but the same fragility shape exists in the other four paper examples (single top-of-function seed, then long script). Worth a defensive sweep before the next non-trivial numerical change in `+nstat/+decoding/` ripples into a parity-gate failure.
- **Cross-helpfile renderer noise** — every helpfile's PNGs show byte-level drift between runs on the same R2026a Update 3 machine. `tools/check_helpfile_drift.m` classifies the bulk as `TINY`/`NONDETERMINISTIC` and the helpfile gate already accepts it. The committed corpus rebaselines naturally on each predeploy run; not a blocker, but a long-term cleanup target.
- **4 latent extra PNGs** in `AnalysisExamples2`, `HybridFilterExample`, `PPSimExample`, `SignalObjExamples`: the current publish produces figure numbers HEAD's HTMLs don't reference. Either the committed HTMLs are missing real figures the scripts now produce, or the publish is producing spurious orphans. Needs a 30-min investigation per file; deferred.

---

## v1.5.1 — 22-Jun-2026

Patch release. Bug fixes from the 2026-06-19 parity-audit ledger, the helpfile-rendering pipeline rebuild, the MATLAB R2025b→R2026a switch, and a `checkcode`-surfaced sweep of `+nstat/+decoding/`. End users on v1.5.0 should upgrade; behavior change is limited to specific edge cases documented below.

### Correctness fixes

| PR | Class | Site | Effect |
|---|---|---|---|
| #87 | numerical | `Analysis.m` KS rescaling | `1 - exp(-Z)` → `-expm1(-Z)`. Catastrophic-cancellation fix for KS statistics at small `λ·dt` (sub-Hz firing with ms bins). Math-equivalent for the parity-baseline regime; tightens precision in the sub-Hz tail. |
| #87 | plotting | `Events.m` label x-coord | Event labels now anchor to event time in data coordinates with `HorizontalAlignment='center'` instead of axes-fraction nudge that drifted on tight `xlim`. |
| #94 | API | `CIF` constructor | `Xnames` entries must be valid MATLAB identifiers. `Xnames={'1',...}` now errors clearly at construction (`CIF:InvalidXname`) instead of failing opaquely in `sym()` downstream. Migrate intercepts to `'one'`. |
| #94 | API | `SignalObj.autocorrelation` / `.crosscorrelation` | `crosscorr(x,y,n-1)` → `crosscorr(x,y,'NumLags',n-1)`. Required for R2023b+ Econometrics Toolbox. |
| #97 | typo | `PPLFP_EStep` binomial branch | `HkPerm = HkPerm(:,:,k)` self-clobber → `Hk = HkPerm(:,:,k)`. Binomial-fitType log-likelihood accumulator was effectively dead code; now exercised correctly. |
| #100 | API | 6 sites in `+nstat/+decoding/PPLFP.m` and `+nstat/+decoding/PointProcessEM.m` | `matlabpool('size')` → `gcp('nocreate')` idiom. Required for R2017a+ MATLAB. Tripwire test prevents reintroduction. |
| #100 | logic | `PPLFP_EM` windowTimes guard | Scalar `gamma=0` no longer misinterpreted as "1-window history". Closed PPLFP_EM matmul-mismatch on the no-history fast path. |
| #106 | doc | `helpfiles/DecodingExample.m` orphan `figure;` | Removed bare `figure;` before `results{1}.plotResults` that produced a blank `_03.png` snapshot. |
| #109 | doc | `FitResult.plotCoeffs` + 3× `FitResSummary` | Replaced third-party `xticklabel_rotate` with the R2014b+ built-in `xtickangle`. GLM coefficient labels render cleanly under `publish()` instead of overlapping vertical scribbles. |
| #112 | logic | `PointProcessEM.m:268` | Missing `=` in binomial Hessian update was discarding the computation. Standard-error estimates for binomial `PointProcessEM` fits are now correct (filter convergence and KS were always unaffected). |
| #112 | guard | `PointProcessEM.m:1111` | Replaced bare `time;` in the Ikeda-acceleration `gammahat~=0` branch (which silently fell through to stale data) with a clear `IkedaHistNotImplemented` error. |

### New capabilities

- **`tools/smoke_helpfile.m`** — publishes one helpfile in a staged sandbox, reports figure count + sizes + blank suspects + delta vs HEAD baseline. Strips `.mlx` siblings to avoid the shadow-execution trap (CONTRIBUTING.md). Forces `defaultFigureVisible='on'` (the silent figure-capture-suppression bug we diagnosed in PR #107).
- **`tools/check_helpfile_drift.m`** — pixel-diff two helpfile directories. Default compares current `helpfiles/` against HEAD-staged temp; pass `'Other'` to compare against an older worktree. Verdict classes mirror `check_readme_figures.m`.
- **`helpfiles/publish_all_helpfiles.m`** — new `validateNoBlankFigures` step errors with `nSTAT:BlankFigureArtifact` when any `Foo_NN.png` figure snapshot drops below `BlankPngThresholdBytes` (default 5000 B). Catches the orphan-`figure;`-before-`plotResults` antipattern (PR #106).
- **`tools/predeploy.sh`** — `--skip-publish` escape hatch removed. The publish step is the only gate that catches blank-figure / partial-render regressions; allowing skip is how earlier regressions landed.

### MATLAB toolchain

- **Default switched from R2025b to R2026a** (MATLAB 26.1). `tools/predeploy.sh`, `tools/run_unit_tests.sh`, `tools/check_readme_figures.sh`, `helpfiles/publish_all_helpfiles.m` (ExpectedGenerator), `info.xml`, and several doc pointers updated.

### Documentation

- **CONTRIBUTING.md** — two new subsections:
  - **Smoke-testing an edited helpfile `.m`** documents the `.mlx`-shadows-`.m` trap (a smoke test using `run('Foo')` silently executes the stale `.mlx` against assertions, not the freshly-edited `.m`). Recommends `tools/smoke_helpfile.m` as the safe entry point with two ad-hoc fallback patterns.
  - **Verifying regenerated `.mlx` / `.html` / PNG artifacts before commit** encodes the lesson from the PR #105 rollback: regenerated rendered docs can silently degrade vs the committed baseline. Three pre-commit checks documented.
- **`tools/check_helpfile_drift.m`** integration with the verification workflow.

### Breaking changes

- **CIF intercept symbol must be `'one'`, not `'1'`** (PR #94). Helpfiles and tests already updated. External callers passing `Xnames={'1', ...}` will get a clear `CIF:InvalidXname` error at construction. Migrate to `Xnames={'one', ...}`.

### Out of scope (deferred to v1.6 or later)

- Re-attempting the pedagogical figure additions from PRs #88/#89 that were rolled back in PR #105. The pipeline is now stable enough to try again, but each requires careful artifact verification.
- `checkcode` style/perf cleanup (275 `AGROW`, 124 `NASGU`, etc.). Not bug-class; out of scope for a patch release.
- Closed without fix: issue #110 (PPAF+History decoded-peak drift). Bisect showed no numerical regression; the visual estimate was an artifact of headless rendering at 1278×770 vs 1882×1026.

---

## v1.5.0 — 2026-06-13

Minor release. **No code changes**; the version bump reflects the addition of a new install path. Existing users upgrading from v1.4.1 by `git pull` see no behavior change.

### Why upgrade

If you discover MATLAB toolboxes through the Add-On Explorer or want one-click install for collaborators who don't use git, v1.5.0 gives you both. If you already clone the repo and run `nSTAT_Install`, you don't need to do anything — that path still works.

### New install path — `.mltbx` via Add-On Manager

Download `nSTAT-1.5.0.mltbx` from this release's assets and double-click in MATLAB. The Add-On Manager handles path setup, metadata, and update notifications. After install, run `nSTAT_Install('DownloadExampleData', true)` once to fetch the figshare paper-example dataset (which is too large to ship in the `.mltbx`).

The README now documents two install options side by side:
- **Option A** (new): `.mltbx` one-click via Add-On Manager — recommended for new users.
- **Option B** (legacy): `git clone` + `nSTAT_Install` — recommended for contributors who want the editable source tree.

### New discoverability — Open in MATLAB Online

The README gained an [Open in MATLAB Online](https://matlab.mathworks.com/open/github/v1?repo=cajigaslab/nSTAT&file=helpfiles/HelloNstat.m) badge. Clicking it opens `helpfiles/HelloNstat.m` in a browser MATLAB session with the toolbox already on the path — no local install required. Anyone landing on the README from a search result can try the toolbox in the cloud before deciding to install locally.

### Infrastructure additions (transparent to end users)

Three new repo-root files implement the modern MATLAB toolbox packaging conventions per [`mathworks/toolboxdesign`](https://github.com/mathworks/toolboxdesign):

- **`buildfile.m`** — `buildtool` task definitions. Consolidates the 8 `tools/*.{sh,m,py}` scripts into one IDE-aware entry point. Use `buildtool test`, `buildtool figures`, `buildtool predeploy`. The old `tools/*.sh` scripts are preserved for CI and shell users; nothing was removed.
- **`toolboxOptions.m`** — declarative `.mltbx` packaging configuration (`matlab.addons.toolbox.ToolboxOptions`). Records toolbox name, version, author metadata, supported platforms, MATLAB-path additions, the GettingStarted guide, and the persistent toolbox identifier UUID (`435c3da4-5a9f-459f-bad5-74c72e9cae4a`, generated once, never changes — the Add-On Manager uses it to recognize updates vs fresh installs).
- **`packageToolbox.m`** — thin wrapper that reads `toolboxOptions()` and invokes `matlab.addons.toolbox.packageToolbox`. Invoked from `buildtool package`.

### What's NOT in v1.5.0

- No File Exchange listing yet. Submission requires manually filling out the [MathWorks form](https://www.mathworks.com/matlabcentral/fileexchange/); planned for a follow-up.
- No classdefs moved. Every existing path-based reference (`Analysis`, `CIF`, etc.) works exactly as before. The `toolbox/` subfolder layout described in [`mathworks/toolboxdesign`](https://github.com/mathworks/toolboxdesign) is deferred — applied at packaging time only if Phase G4 is approved, never in the repo tree.
- No MATLAB CI added. License constraint stands per `CONTRIBUTING.md`; `buildtool` runs locally (same pattern as v1.4.1).

### Driving work

Three phases of a modernization plan: G1 (`buildfile.m` + `buildtool` task migration), G2 (`.mltbx` packaging), G3 partial (Open-in-MATLAB-Online badge + dual-install-path README). Phases G4 (`toolbox/` materialization at packaging time) and G5 (`.prj` MATLAB Project) deferred.

PRs landed: #71 (G1), #72 (G2), #73 (G3 partial), #74 (this release).

---

## v1.4.1 — 2026-06-12

Patch release closing all 19 open issues on the tracker as of 2026-06-12. Seven small PRs land in one day, each scoped to a single file or area, each with a unit test. **The headline change is the SSGLM binomial `JacobianLD` typo** (#59) — the only fix in this release that actually changes downstream math; everything else is correctness-tightening or dead-code cleanup.

This is a **drop-in upgrade** from v1.4.0. No API changes, no deprecations. If you upgraded to v1.4.0 in May, run `git pull` and you're done.

### Why upgrade

If you use the binomial-link SSGLM EM step, **upgrade now** — pre-fix the Hessian estimate was corrupted by a `(1-2*λΔ²)` typo where the canonical sigmoid 2nd derivative is `(1-2*λΔ)` (linear, not squared). The error is non-antisymmetric around the inflection point λΔ = 0.5 and biases EM convergence. See [#59](https://github.com/cajigaslab/nSTAT/issues/59) for the full math and the Python-port-parity reference.

For everyone else: 14 other quality-of-life fixes (correct bounds, correct array indexing, correct deprecation hygiene) — none user-visible in normal use, but each one was a latent bug that could surface in adjacent paths.

### Correctness fixes (one section per PR; all merged 2026-06-12)

- **#60 / SignalObj** — `shiftMe` now updates `minTime`/`maxTime` to match the shifted time vector (`#14`); `resample` at the same sample rate length-checks the implied grid so a `setMinTime`/`setMaxTime` between construction and resample doesn't silently leave a stale time vector (`#54`). Bonus: `times`/`rdivide` aliasing (`#53`) closed as stale-fixed — already addressed by prior `copySignal` patches.
- **#61 / CovColl** — `isCovPresent` no longer off-by-one excludes the last covariate (`#17`); `findMaxTime` applies `covShift` exactly once (was twice) so it's symmetric with `findMinTime` (`#18`).
- **#62 / nstColl** — `getSpikeTimes` initializes its counter outside the `if(i==1)` guard so a mask excluding neuron 1 no longer errors (`#21`); `getFieldVal` reorders the pre-increment so paired `fieldVal`/`neuronNumbers` records align (`#55`); `getNSTnameFromInd` does a real upper-bound check instead of a truthy guard, with a clear `nstColl:getNSTnameFromInd:OutOfBounds` identifier (`#56`).
- **#63 / TrialConfig** — `fromStructure` now passes `ensCovMask` and uses the correct positional order, fixing both omitted-argument (`#19`) and positional-shift (`#58`) reports in one change. **Note**: the Python port (`nSTAT-python _trial_config_impl.py:190–197`) has the matching bug; coordinated fix recommended to preserve gold-fixture parity.
- **#64 / Analysis Granger** — `ensCovMaskTemp` zeroes the column for only the neuron under test, not the full neuron list (`#15`); `phiMat` coefficient mask uses `~cellfun(@isempty, strfind(...))` instead of `~isempty(coeffInd)` so every history-basis coefficient contributes to the sign aggregation (was always just the first) (`#51`).
- **#65 / Decoding** — `+nstat/+decoding/PPAF.m` (two sites) now broadcasts a shared single-cell `gamma` across all `C` cells via `repmat`; pre-fix only the last column was populated because `c` retained its post-for-loop value (`#20`). `DecodingAlgorithms.estimateInfoMat` removes a dead-code first-formula assignment that was always overwritten by the canonical second formula (`#57`).
- **#66 / SSGLM** — **HEADLINE FIX**. `+nstat/+decoding/SSGLM.m:373` `JacobianLD` factor changes from `(1-2*λΔ.^2)` to `(1-2*λΔ)`. The four sibling call sites in the toolbox (`DecodingAlgorithms.m:533, 603`; `SSGLM.m:458, 545`) and the Python port (`nSTAT-python decoding_algorithms.py:2641`) all use the linear form. Line 373 was the lone outlier. Pre-fix the binomial-link SSGLM EM step produced biased Hessian estimates; post-fix the math matches the canonical sigmoid second derivative `σ(1-σ)(1-2σ)` (`#59`).

### Stale-issue closures (no code change)

Four 2026-03-10 issues were already addressed by Phase 0–4 modernization in v1.4.0 but the issues remained open. Closed with commit references on 2026-06-12: **#12** (`findPeaks` minima), **#13** (`findGlobalPeak` `sOBj` typo), **#16** (`sampeRate` typo), **#52** (`autocorrelation` `crosscor` typo).

### Test additions

Six new `matlab.unittest` test classes under `tests/unit/` covering each PR's regression surface:

- `testSignalObjShiftMeBounds`, `testSignalObjResampleWindowMutated`
- `testCovCollIsCovPresentBounds`, `testCovCollFindMaxTimeShift`
- `testNstCollMaskedAccessors`
- `testTrialConfigRoundTrip`
- `testAnalysisGrangerCoeffMask`
- `testPPAFGammaBroadcast`
- `testSSGLMBinomialJacobianLD`

Local gate: **72 of 72 unit tests pass** (was 54 at v1.4.0; +18 new tests).

### Paper-example figure parity

`tools/check_readme_figures.sh` detected three `SUBSTANTIVE` drifts attributable to PR #65's PPAF gamma broadcast fix (Example 02 fig02 AIC/BIC + Example 05 fig05/fig06 hybrid-decoder traces) plus six `SHAPE_DIFFER` rasterizer-pixel drifts. The tree was regenerated via `build_paper_examples` to reflect post-fix outputs; the Example 03 SSGLM-derived figures (`fig03_ssglm_simulation_summary`, `fig05_stimulus_effect_surfaces`, `fig06_learning_trial_comparison`) remain on the `NONDETERMINISTIC_BLAS` allowlist per the figure-parity policy from PR #42.

### Driving plan

The open-issues remediation plan that drove this release recorded per-issue triage, file-grouping rationale, seven-PR sequencing, and the figure-parity-gate strategy.

---

## v1.4.0 — 2026-05-20

The first substantive release since the 2012 paper. Roughly two months of work — Phase 0 through Phase 4 of the 2026-05-19 nSTAT review action plan, plus a 2026-05-20 deep-dive verification, a pre-modernization ground-truth regression, the README figure-parity sweep, and a comprehensive codebase audit — consolidated into a single release.

This is a **drop-in upgrade** from v1.2/v1.3 — every public-API change ships with a deprecation shim that forwards to the new entry point and emits a one-time warning. No user code should break on the v1.4.0 upgrade.

### Why upgrade

The headline 2012 outputs (every figure in the README gallery; every paper example in `examples/paper/`) **encoded multiple math bugs** that propagated through the time-rescaling KS test, the PPAF/PPHF decoders, and the SSGLM EM iterations. v1.4.0 fixes those bugs. If you have run nSTAT on real data and trusted the KS goodness-of-fit statistic or the decoder traces, you should re-run on v1.4.0 and compare; a pre-modernization regression analysis showed which outputs change and by how much.

---

### Correctness fixes

These are the bugs whose fixes can change numerical output. If you have published or cached results from v1.2/v1.3, expect numerical drift in the affected families.

- **Bernoulli log-likelihood missing `log()` wrapper** (commits `acd57c7`, `d1e96cf`). `FitResult.computeLL` and `Analysis.GLMFit` computed `(1-y) .* (1 - λΔ)` instead of `(1-y) .* log(1 - λΔ)` for the binomial branch. **Effect:** AIC, BIC, and log-likelihood values were wrong for every Bernoulli fit. All downstream model comparison, KS curves, and confidence intervals derived from `logLL` change after the fix.
- **KS U-clamping before statistic computation** (`ef01a82`). `Analysis.computeKSStats` clipped the rescaled inter-event interval array `U` to `[0,1]` before computing `ks_stat`, masking true tail deviations and inflating apparent goodness-of-fit. **Effect:** KS verdicts move (typically: fits that "passed" the KS test now closer to or beyond the 95% band when the model is genuinely misspecified). The empirical pass rate on the discrete-time KS oracle was verified against the new code path in `tests/integration/testKsAgainstReferenceZoo.m`.
- **DT-correction KS branch unreachable** (`f460aa8`). For any data with `λΔ > 0.4`, the discrete-time variant of the KS test (Haslinger–Pipa–Brown 2010 correction) was supposed to fire but never did because `setMinTime`/`setMaxTime` clobbered the cached `isSigRepBin` flag. **Effect:** examples in the high-rate regime were silently using the continuous-time KS formula. A new warning `nSTAT:DTCorrectionRegime` now fires when input data is in the DT regime to surface the regime change to callers.
- **PPAF goal-directed predict time-indexing** (`3ffebd5`). The goal-directed branch of `PPDecodeFilter` indexed `A`, `Q`, and the goal-vector at the wrong time slice. **Effect:** Example 05 fig04 (PPAF goal vs free) outputs drift; the previous trace was based on off-by-one time-indexed dynamics.
- **PPHF time-indexing + missing x0/Pi0 goal fusion** (`bc5f879`, `1bcb63e`, `ba7069a`). `PPHybridFilter(Linear)` had a one-step time-index error on `A`/`Q`, and the goal-aware path was missing the initial-state goal fusion entirely. **Effect:** Example 05 fig05/fig06 (hybrid filter outputs) change in the goal-aware branch. The linear vs nonlinear variants now agree.
- **FitResult multi-result λ indexing** (`1520034`). In the multi-result branch of `FitResult.plotLambda`, `newLambda.data` was used without indexing by the loop variable, so every fit in a multi-result comparison was plotted using result-1's λ. **Effect:** Example 03 SSGLM stimulus-effect surface plots now display per-result λ correctly.
- **`plotSeqCorr` overflow and non-finite filtering** (`f5b5734`). The inverse-Gaussian U-transform produced `Inf`/`NaN` for marginal cases; downstream code did not filter them, propagating non-finite values into autocorrelation plots. **Effect:** invGausTrans subplots in Examples 01–03 no longer have rendering artifacts.
- **`Analysis.ksdiscrete` clobbered caller-set RNG seed** (`f2307e9`). The bootstrap KS path called `rng('shuffle','twister')` internally, breaking reproducibility for any caller that had set a seed. **Effect:** `rng(0)`-based reproducibility now works end-to-end through KS-discrete code paths.
- **`sampeRate` typo, `containsChars` logic, `logLL` undefined vars** (`6f6eb13`). Three latent defects in adjacent code paths surfaced and fixed.

The full pre-modernization regression test showed: **19 of 19 evaluated outputs IDENTICAL** to the pre-modernization baseline on the V3.1 MVP harness, with all numerical-output diffs attributable to the listed correctness fixes.

### Architectural cleanup

These are refactors. They do not change algorithmic behavior; every legacy entry point still works through a deprecation shim.

- **`+nstat/+decoding/` package** — eight algorithm-specific classes (`KalmanFilter`, `UKF`, `PPAF`, `PPHF`, `PPLFP`, `SSGLM`, `KF_EM`, `PointProcessEM`) extracted from the 10860-line `DecodingAlgorithms.m`. The legacy class is now a 1189-line facade with 47 deprecation shims forwarding to the package.
- **`mPPCO_*` → `PPLFP_*` rename** (paper §4.B.7 alignment). The historical `mPPCO_*` family was poorly named; `mPPCO` is the *PPLFP* (point-process + LFP sensor fusion) filter, not a separate algorithm. New canonical names are in `nstat.decoding.PPLFP`. The nine `mPPCO_*` static methods on `DecodingAlgorithms` are deprecation shims forwarding to the package.
- **Woodbury matrix update centralized** in `+nstat/+decoding/+internal/computeGainMatrix.m`. Previously duplicated across `PPDecode_update`, `PPDecode_updateLinear`, `mPPCODecode_update`, and the hybrid variants.
- **`nstat.Defaults`** — a single class with named constants (`EM_TolAbs=1e-3`, `EM_MaxIter=100`, `DTRegimeBound=0.4`, `KS_NumIters=10`, …). Previously these were magic-number literals scattered across `DecodingAlgorithms`, `Analysis`, and the EM paths.
- **`nstat.setPlotStyle('modern' | 'legacy')`** — plot-style toggle. `'modern'` (default) is the readability-focused style; `'legacy'` reproduces the 2012 paper's visual style verbatim, primarily for figure regeneration parity.

### New capabilities

- **`LinearCIF`** — canonical-link conditional intensity function with **closed-form gradient and Hessian** for the Poisson and binomial canonical links. A drop-in replacement for `CIF` where the Symbolic Math Toolbox dependency is undesirable: `LinearCIF`'s derivative computation is analytic and Symbolic-free at eval time. (Construction still uses `sym(...)` for variable-name compatibility with the existing `CIF` interface contract; a follow-up could redefine `varIn`/`stimVars` as `cellstr` to eliminate the construction-time dependency.)
- **`History.raisedCosine(K, tMin, tMax)`** — Pillow 2008 log-spaced raised-cosine basis. Static constructor for `History`. Default bounds `tMin=0.002`, `tMax=0.100` (seconds).
- **Iterated-Laplace PPAF update** — `nstat.decoding.PPAF.PPDecode_updateIterated` and `PPDecode_updateLinearIterated` implement the iterated-Laplace step from Eden et al. 2004 (Algorithm 2), with the missing prior-gradient correction term that the original single-Newton update omits. Exposed but not yet wired into the top-level `PPDecodeFilter` — opt-in via direct call. See [PR #36](https://github.com/cajigaslab/nSTAT/pull/36) for the math derivation.
- **KS oracle integration test** — `tests/integration/testKsAgainstReferenceZoo.m` runs the reference KS-validation pipeline against simulated point processes and asserts the empirical pass rate matches the analytic null distribution to within tolerance. Validates the entire fit → KS path end-to-end.

### Developer experience

These are infrastructure additions that do not affect runtime behavior. They make the toolbox testable and releasable.

- **Local test gate** (`tools/run_unit_tests.sh`) — 20 unit tests + 1 integration test cover every bug-class fix. Replaces the failed-MATLAB-CI experiment ([PR #36](https://github.com/cajigaslab/nSTAT/pull/36) reverted in [PR #38](https://github.com/cajigaslab/nSTAT/pull/38)). CI no longer runs MATLAB; the local gate is canonical.
- **README figure parity** (`tools/check_readme_figures.sh`) — regenerates the `docs/figures/` paper-example gallery and pixel-diffs against the committed PNGs. Three-bucket classification (`IDENTICAL` / `TINY` / `SUBSTANTIVE`) plus a `NONDETERMINISTIC` allowlist for three Example 03 figures whose drift is intrinsic to multi-threaded BLAS reduction order in SSGLM EM. See [PR #42](https://github.com/cajigaslab/nSTAT/pull/42).
- **One-command deploy gate** (`tools/predeploy.sh`) — chains unit tests, integration tests, README figure parity, helpfile HTML republish, helpsearch rebuild, helptoc lint, and sibling-bug-pattern audit. ~30–45 minute wall clock; the canonical pre-tag check. See [`CONTRIBUTING.md`](CONTRIBUTING.md) "Release & regeneration".
- **Release stamping** (`tools/stamp_release.m`) — updates `Contents.m` version stamp, manifest `generated_at`, and the next `RELEASE_NOTES.md` section template. Idempotent. Run after the deploy gate passes; before `git tag`.
- **Bug-pattern audit** (`tools/check_bug_patterns.sh`) — `grep` over 11 known-bad patterns (Bernoulli LL wrap, `isa('nan')`, `eval()`, `histc`, `roundn`, `rng('shuffle')`, `symvar` reorder, `sampeRate` typo, `log(0)`, silent `catch`, `.^2`/`.^3` confusions). Informational; not a release blocker. Triage 2026-05-20: 0 actionable sibling defects.
- **Help-system integrity** — the v1.4 audit covered the `helptoc.xml` ↔ `.html` ↔ `.m` ↔ search-index relationship. 8 previously-missing TOC entries added (including the canonical onboarding `HelloNstat` and the `WhenToUseWhich` decision tree).

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

These are tracked but not blocking the release.

- **80 unreferenced `.png` files** in `helpfiles/`, mostly equation rasters from older `publish()` runs. Disk-bloat cleanup; not affecting users.
- **1567 stylistic `checkcode` findings** (0 definite-error severity) across 29 core files. Opportunistic-cleanup backlog.
- **`LinearCIF` Symbolic Math Toolbox dependency at construction time** (not eval time). Fix shape: redefine `varIn`/`stimVars` properties as `cellstr` instead of `sym`. ~6–8 hr refactor.
- **`Analysis.m:609` empty-`b` defect** — `glmfit` returning an empty coefficient vector triggers a downstream `undefined data` reference. ~30 min surgical fix.
- **Legacy `helpfiles/helpsearch/` and `helpsearch-v3/` directories** retained from pre-R2025b MATLAB versions. The current search index lives in `helpsearch-v4_en/`. Cleanup deferred.

### Recommended deploy procedure for future releases

Documented in [`CONTRIBUTING.md`](CONTRIBUTING.md) "Release & regeneration":

```bash
tools/predeploy.sh # ~30–45 min gate
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

The 2012 paper remains the canonical reference for the toolbox's design and the foundational point-process / state-space methods. Subsequent updates are documented in `RELEASE_NOTES.md` (this file) and the `% FIX:` inline tags throughout the codebase.

---

## Pre-v1.4 history

### v1.2 — 2026-03-10

The original 2026-03-10 5-phase audit identified and fixed 67 bugs across 8 core files (FitResult.m KS bin-width inversion, DecodingAlgorithms isa('nan') always-false, CIF symvar reorder, SignalObj findPeaks crash, nspikeTrain burst detection, etc.). All changes tagged with `% FIX:` inline comments. See [AUDIT_REPORT.md](AUDIT_REPORT.md) for the full historical record.

### v1.0 — 2012-11

Original release accompanying Cajigas, Malik, Brown 2012 (*J. Neurosci. Methods* 211: 245–264). Time-rescaling KS goodness-of-fit, PPAF, PPHF, SSGLM, multimodal PPLFP (originally named `mPPCO_*`). See `helpfiles/nSTATPaperExamples.{m,mlx}` for the paper-figure-reproducing artifact.
