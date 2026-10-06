# nSTAT Release Notes

## Unreleased — Kalman-filter EM (`fix/kf-em`)

Repairs `nstat.decoding.KF_EM` with the same defect classes the point-process EM repair (`fix/pp-em`, above) found and fixed in `PointProcessEM`/`PPLFP`, plus one defect specific to this class: its main EM loop was a Static method named identically to its own class, which MATLAB always dispatches as the constructor, so it was unreachable through either of its two documented entry points. Also adds a GLM-plug-in-M-step warning (`PP_EM`/`PP_MStep`/`PPLFP_EM`/`PPLFP_MStep`) and documentation of two pre-existing, user-decided behaviours (the whitened-frame meaning of `QhatDiag`/`RhatDiag`, and EM's "stop at first decrease" rule).

### Correctness fixes

| PR / commit | Class | Site | Effect |
|---|---|---|---|
| `dd7c7d5` | crash | `KF_EM.KF_EM` (renamed `KF_RunEM`) | A Static method cannot share its class's name — MATLAB always dispatches it as the constructor (`meta.class` reports `Static=0` for it regardless of the `methods(Static)` block it is written in). Neither `nstat.decoding.KF_EM.KF_EM(...)` ("no Static method named `KF_EM`") nor `nstat.decoding.KF_EM(...)` ("the constructor must preserve the class of the returned object") ever worked, so `KF_EM`'s only two entry points — this method and `DecodingAlgorithms.KF_EM`, which just forwarded to it — were unreachable since the Phase 3 class extraction. Renamed `KF_RunEM`; `DecodingAlgorithms.KF_EM` now forwards there. |
| `6ba92cb` | numerical | `KF_RunEM` internal whitening | Scaled the state/observation by `Tq = inv(chol(Q0))` / `Tr = inv(chol(R0))`, the **upper** Cholesky factor, which does not whiten a non-diagonal `Q0`/`R0` (`Tq·Q0·Tq' ≠ I`); the default diagonal-Q/R M-step then acted outside the starting family and the first M-step lowered the likelihood. Now uses the **lower** factor (same fix as `fix/pp-em`'s G1). |
| `6ba92cb` | numerical | `KF_RunEM`'s SE call and `IC` | `xKFinal`/`WKFinal`/`ll`/`ExpectationSumsFinal` were left on the internal Tq/Tr-scaled system while `Ahat`/`Qhat`/`Chat`/`Rhat`/`alphahat`/`x0hat`/`Px0hat` were mapped back to the original scale, and `y` (scaled at setup) was never restored; the SE call and the `IC` formula then mixed scaled sums/`y` with original-scale estimates (the same class as `fix/pp-em`'s `bac99f9`/F8/F10). Now the E-step is recomputed once from the unscaled parameters and the original `y` (exactly, by the Kalman filter/RTS smoother's equivariance under this linear change of variables), making every input to the SE call and the `IC` formula mutually consistent on one scale. `SE`/`Pvals`/`IC` from `KF_RunEM` move; direct `KF_EStep`/`KF_ComputeParamStandardErrors` calls do not. |
| `dcf03eb` | logic | `KF_RunEM`'s `IC` parameter count for R | Tested `QhatDiag`/`QhatIsotropic` instead of `RhatDiag`/`RhatIsotropic` in its middle branch (same class as `fix/pp-em`'s F11); masked by the defaults (both true), it surfaces whenever `QhatDiag`/`QhatIsotropic` differ from `RhatDiag=1,RhatIsotropic=0`. |
| `5b942b3` | numerical | `KF_ComputeParamStandardErrors`'s Q/R/Px0 information blocks | Operator precedence: `N/2*(Qhat)\em(:,m)*el(:,l)'/(Qhat)` evaluated as `((N/2)·Qhat)⁻¹·em·el'·Qhat⁻¹` — N²/4 too small for Q/R (SE about K/2 too large), 4× too large for Px0 (SE about 2× too small). Same bug as `fix/pp-em`'s H1; the five sites are now fully parenthesised. |
| `178917c` | numerical | `KF_ComputeParamStandardErrors`'s Monte Carlo draws (`xKDraw`, `x0Draw`) | `m + chol(W)*z` (the upper factor; covariance `chol(W)·chol(W)' ≠ W` for non-diagonal `W`). Same bug as `fix/pp-em`'s F9; both sites now call the shared `PointProcessEM.mcStateDraws` (`x = m + chol(W)'*z`), reused rather than duplicated. |
| `c7d177e` | hang | `KF_ComputeParamStandardErrors` with SEs requested, singular observed information | Same pattern as `#136` (`PointProcessEM`/`PPLFP`): `eye(size(IObs))/IObs` is Inf/NaN on an exactly singular `IObs`, and `nearestSPD`'s `while p ~= 0` loop never returns on a NaN matrix. Now reuses `PointProcessEM.seObservedInfoInverse`: a zero pivot falls back to the pseudo-inverse, flags the non-identifiable terms (SE/p-value NaN) with `nSTAT:EM:singularInformation`, and a non-finite information matrix raises `nSTAT:EM:nonFiniteInformation` instead of looping. Nonsingular information is unchanged (bit-identical). |
| `3f91924` | new warning | `PP_EM`/`PP_MStep`/`PPLFP_EM`/`PPLFP_MStep` with `MstepMethod='GLM'` | Warns once per top-level call, id `nSTAT:EM:glmPlugIn`: the GLM M-step is a plug-in fit on the smoothed means (ignores `W_K`), which inflates β and can drift; `NewtonRaphson` (the default) is preferred. No numerical output changes. `mPPCO_EM`/`mPPCO_MStep` inherit it via their existing forward to `PPLFP`. |

### Breaking changes

- **`nstat.decoding.KF_EM.KF_EM` is renamed `KF_RunEM`** (`dd7c7d5`). This is not a behavioural break in practice: the old name never worked (every call errored), so nothing could have depended on it. `DecodingAlgorithms.KF_EM` (the deprecated outward-facing name) is unchanged; it now forwards to `KF_RunEM`.
- **`KF_RunEM`'s `SE`, `Pvals` and `IC`** move whenever SEs are requested or `Q0`/`R0` is non-diagonal (`6ba92cb`, `dcf03eb`, `5b942b3`, `178917c`) — see the table above. Direct `KF_EStep`/`KF_ComputeParamStandardErrors`/`KF_MStep` calls are unaffected except by the precedence (`5b942b3`), draws (`178917c`) and singular-information (`c7d177e`) fixes, which apply there too.

### Docs only (no numerical change)

- `PP_EMCreateConstraints` / `PPLFP_EMCreateConstraints` / `KF_EMCreateConstraints`: `QhatDiag=1` / `RhatDiag=1` mean "diagonal in the frame whitened by Q0 / R0", not in the caller's own coordinates, whenever Q0 / R0 is non-diagonal.
- `PP_EM` / `PPLFP_EM` / `KF_EM` (`KF_RunEM`): EM stops at the first decrease of the log-likelihood, not at convergence; for `PP_EM`/`PPLFP_EM` this makes the stopping iteration random under the Monte Carlo M-step (6–11 observed on one problem), while `KF_RunEM`'s closed-form E/M steps make it deterministic for a fixed problem.

## Unreleased — point-process EM (`fix/pp-em`)

Makes `nstat.decoding.PointProcessEM.PP_EM` run (it could not run in any configuration) and fixes a series of correctness defects in the point-process EM / PPLFP / decoder cluster found while doing so. Two **default changes** (`PP_EM` and `PPLFP_EM` now use the NewtonRaphson M-step and do not estimate x0/Px0) and one **SE output-layout change** — see *Breaking changes*. The binomial likelihood throughout is the toolbox's point-process form `log L = Σ dN·log p − p`, `p = logistic(η)`.

### Correctness fixes

| PR / commit | Class | Site | Effect |
|---|---|---|---|
| `4d201c8` | crash | `PP_EM` / `PP_MStep` | No-history `HkAll` is now `zeros(N,1,numCells)` (was 1×1×C → index error at time 2); removed `close all` from the GLM M-step (deleted PP_EM's progress figure → `figure(h)` error at iteration 2); NewtonRaphson M-step used an undefined `xKDraw`. |
| `a80aae2`, `9f540c5` | logic | `PP_MStep`, `PPLFP_MStep` GLM branch | The GLM fit was written to the input variables, so μ/β/γ were returned unchanged. |
| `d37a07a` | logic | `FitResSummary.getHistIndex` / `getHistCoeffs` / `getCoeffs` | `bAct(:,fitNum)` on a 3-D array read neuron 1 only; history labels were dropped whenever neuron 1's were NaN (crash on undefined `baseStrings`, history terms misreported as covariates). Empty cases now return empty. |
| `7a2b87f`, `9f540c5` | numerical | binomial NewtonRaphson β step (PP, PPLFP) | Hessian had the wrong sign (`(p+p²−2p³)xx'`); now `(−(dN+1)p + (dN+3)p² − 2p³)xx'` (finite-difference verified). The NR M-step diverged before. |
| `74b8096`, `b26f535` | crash | binomial γ SE block (PP, PPLFP) | `Hk(k,:)'*Hk(:,k)` → `Hk(k,:)'*Hk(k,:)`. |
| `8321271`, `c44b293`, `7c8f3c1` | numerical | binomial β and μ SE information (PP, PPLFP) | β block had the wrong sign (negative-definite information); μ block used `−3E[p³]` instead of `−2E[p³]`. |
| `03c48ad`, `04413d8` | layout | `SE.beta` / `SE.gamma` (PP, PPLFP) | `reshape(v,C,dx)'` scrambled entries for dx>1 and C>1; now `reshape(v,dx,C)` / `reshape(v,W,C)`. |
| `10cce2a`, `849c68b` | guard | `PP_EM`, `PPLFP_EM` | Stop before the M-step on a non-finite / complex E-step log-likelihood; return the best finite real iterate. |
| `2403a97`, `d436fe1` | numerical | `PP_EStep`, `PPLFP_EStep`, `PPLFP_Decode_update` | Square history (numWindows == numCells) was transposed (logll, and the PPLFP filter). |
| `913af29`, `e8c5d2e`, `3338eed` | numerical | `PP_EM`, `PPLFP_EM`, both GLM M-steps | History spike trains and the GLM time grid now use `delta` (were hardcoded 1 ms). |
| `7bfcf7f` | numerical | `PPAF.PPDecodeFilterLinear` | A correctly oriented square β (ns == C) was transposed. |
| `10fc00e`, `7835a4e` | crash / logic | `PPHybridFilterLinear`, `PPLFP_DecodeLinear`, `PPLFP_fixedIntervalSmoother` | History windows used an undefined `delta`; a shared γ column reached only the last cell (#20 pattern). |
| `2219ee0`, `a457b54` | crash | `PP_EM`, `PPLFP_EM` default windows | `windowTimes = []` with nonzero γ now gives `0:delta:size(gamma,1)*delta` (was one window too many) and expands a shared nonzero γ column per cell. |
| `ef7bb22`, `605d9bc` | crash | SE routines and M-steps | Removed `size(Hk,1)==numCells` re-orientations of history slices (broke one cell with W>1, and N == numCells). |
| `cfb47d1`, `1b6132d`, `4c3beac` | crash / logic | GLM M-steps (PP, PPLFP) | γ, μ and β are mapped from the GLM fit **by label**; an unestimable coefficient keeps its previous value (crashes for dropped labels, dx ≥ 10 mis-mapping, single cell). |
| `4512384` | crash | SE routines | One cell with one nonzero history coefficient left the γ parameter count unassigned. |
| `bac99f9` | numerical | `PP_EM`, `PPLFP_EM` standard errors | The SE call received the internally rescaled expectation sums (and, in `PPLFP_EM`, the rescaled `y`) together with the original-scale estimates, so SEs were wrong whenever `Q0` or `R0` ≠ I; the sums and `y` are now mapped back to the original scale first. `SE` / `Pvals` from `PP_EM` / `PPLFP_EM` change; direct SE calls do not. |
| `c49dc00` | numerical | Monte Carlo draws in both SE routines and both NewtonRaphson M-steps | Draws were `m + chol(W)*z`, whose covariance is `chol(W)*chol(W)'` ≠ W for non-diagonal W; now `m + chol(W)'*z`. Same random stream; draws with diagonal W are unchanged. |
| `8843a94` | numerical | `PP_EM`, `PPLFP_EM` information criteria | `IC.llobs` mixed the scaled-system log-likelihood with original-scale `Qhat` / `Px0hat`, so llobs / AIC / AICc / BIC depended on the units of x. They are now on the original scale: llobs is the expected observation log-likelihood, and `IC.llcomp` is the expected complete-data log-likelihood on the original scale. |
| `564c207` | logic | `PPLFP_EM` IC parameter count | R's parameter count used Q's diagonal / isotropic flags; it now uses R's. This only matters when `RhatDiag` differs from `QhatDiag`. |
| `1c051a9` | crash | SE routines | A direct SE call with a shared history column (a nonzero scalar or `W × 1`) and several cells errored. The column is now expanded per cell, as the EM drivers already do. |
| `499690a` | numerical | `PP_EM`, `PPLFP_EM` internal whitening | The internal scaling used `inv(chol(Q0))` / `inv(chol(R0))`, the upper factor, which does not whiten a non-diagonal `Q0` / `R0`. The default diagonal-Q (and R) M-step then acted outside the starting family: the first M-step lowered the likelihood and EM returned the initial parameters. It now uses the lower factor (`Tq·Q0·Tq' = I`). Nothing changes for a diagonal `Q0` / `R0`. |
| `59f42c9` | logic / crash | `PP_ComputeParamStandardErrors` constraints | The function tested `nargin<19` but has 15 inputs, so the caller's constraints were always replaced by the defaults (`mcIter` 1000; SEs for unestimated A entries). It now uses `nargin<15`. Three paths that became reachable as a result, `EstimateA=0`, `QhatIsotropic=1` and `Px0Isotropic=1`, also crashed on undefined variables; those are fixed too. |
| `2a858a0` | numerical | Q / R / Px0 information blocks in both SE routines | Operator precedence: `N/2*(Q)\e*e'/(Q)` evaluated as `(N/2·Q)⁻¹·e·eᵀ·Q⁻¹`. As a result the Q and R information was N²/4 too small (SE.Q / SE.R about K/2 too large) and the Px0 information was 4× too large. The expressions are now parenthesised at all 8 sites. Through the joint inversion and `nearestSPD` this moved every SE that `PP_EM` / `PPLFP_EM` report. |
| #136 | hang | both SE routines (`PP_EM` / `PPLFP_EM` with SEs requested) | An exactly singular observed information (a separated history window: no spike in it is followed by a spike, so its gamma walks to the `exp()` underflow and its information and score are exactly 0) made `eye/IObs` Inf/NaN, and `nearestSPD` then never returned. Now the pseudo-inverse is used, the parameters in its null space are reported with NaN SE and p-value and named in a `nSTAT:EM:singularInformation` warning, only the identifiable block is projected with `nearestSPD` (which also does not return on a singular matrix), and a non-finite information matrix raises `nSTAT:EM:nonFiniteInformation`. Nonsingular information is unchanged (bit-identical). |
| `6d42ece` | side effect | GLM M-steps | `warning('OFF')` now restores the caller's warning state on exit. |

### Breaking changes

- **`PP_EM` / `PP_MStep` (`b0d83fd`) and `PPLFP_EM` / `PPLFP_MStep` (`7cea336`): default `MstepMethod` is now `'NewtonRaphson'`** (was `'GLM'`, a plug-in fit on the smoothed means that inflates β and drifts). Pass `'GLM'` explicitly for the old behaviour.
- **`PP_EMCreateConstraints` / `PPLFP_EMCreateConstraints`: `Estimatex0` and `EstimatePx0` now default to 0** (were 1; the single-sample Px0 update collapses Px0 to ~0 and sends the log-likelihood to +Inf after ~2 iterations). All other constraint defaults are unchanged. Pass them as 1 for the old behaviour.
- **`SE.beta` / `SE.gamma` (and `Pvals.beta` / `Pvals.gamma`) layout** from `PP_ComputeParamStandardErrors` / `PPLFP_ComputeParamStandardErrors` (and `PP_EM` / `PPLFP_EM` when SEs are requested) is now `dx × C` / `W × C` with each entry in its own position (previously scrambled; transposed when dx == C).
- `PPAF.PPDecodeFilterLinear` output changes for square problems (ns == C) only.
- **`IC` from `PP_EM` / `PPLFP_EM` (`8843a94`)**: `llobs`, `AIC`, `AICc` and `BIC` are now on the original scale, and so is `llcomp`. Previously `llcomp` was the scaled-system value, so it shifts by `(K+1)·log|det Tq|` (plus `K·log|det Tr|` for PPLFP).
- **Monte Carlo SEs and NewtonRaphson M-steps (`c49dc00`)**: results change wherever the smoothed state covariance is not diagonal.
- **Non-diagonal `Qhat0` / `Rhat0` (`499690a`)**: EM now estimates from such starting values, where it used to return them unchanged. `QhatDiag=1` / `RhatDiag=1` then mean "diagonal in the frame whitened by Q0 / R0".
- **`PP_ComputeParamStandardErrors` / `PP_EM` SEs with non-default constraints (`59f42c9`)**: SEs now follow the constraints, including `mcIter`; the SE fields and the parameter count change accordingly.
- **Standard errors (`2a858a0`)**: `SE` / `Pvals` from both SE routines and both EM drivers change. SE.Q and SE.R were about K/2 too large and SE.Px0 2× too small, and through `nearestSPD` every other SE was affected too.
- The per-iteration `logll:` console line stays on the internal scaled system (see the `PP_EM` / `PPLFP_EM` help); `IC.llcomp` is on the original scale.

### New capabilities

- **Optional `delta` inputs**: `PP_MStep(…, MstepMethod, delta)` (15th input) and `PPLFP_MStep(…, MstepMethod, delta)` (16th input), default 0.001 s; `PP_EM` / `PPLFP_EM` pass their `delta`. Existing positional arguments are unchanged.
- Tests: `tests/unit/testPointProcessEMRuns.m`, `testEMMonteCarloDraws.m`, `testPointProcessEMCorrectness.m`, `testPPLFPEMCorrectness.m`, `testDecoderCorrectness.m`, `testFitResSummaryHistIndex.m`; slow full-EM tests in `tests/integration/testPointProcessEMIntegration.m` (`tools/run_unit_tests.sh --integration`).

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
