# 2026-06-12 — Open-Issues Remediation Plan

**Owner:** Iahn Cajigas
**Status:** PROPOSED
**Scope:** 19 open GitHub issues on `cajigaslab/nSTAT` as of 2026-06-12T15:33Z.

## 1. Strategic position first

The 19 open issues split cleanly into three groups by cohort and status:

- **March-2026 cohort (10 issues, #12–#21):** filed during the original 2026-03-10 67-bug audit. Four of them (**#12, #13, #16, #52**) have already been fixed in the codebase — the issues are stale-open. The remaining six need work.
- **June-12-2026 cohort (9 issues, #51–#59):** filed today, presumably from a comprehensive cross-toolbox audit against the Python port (AUDIT_REPORT.md `M5`–`M20`). Three (**#52, #57, #59**) involve cross-port parity; the rest are MATLAB-only bugs.
- **#19 and #58 are duplicate root causes** for the same `TrialConfig.fromStructure` defect — should be closed together by one PR.

The shape of the remediation:
- **Tier 0** (5 minutes): close the 4 already-fixed issues with commit references.
- **Tier 1** (1 PR per class, 5 PRs): batched fixes grouped by file, each small enough that a single reviewer can hold the whole change in their head.
- **Tier 2** (separate PR, 1 PR): the SSGLM `.^2` typo — single-line math fix but warrants unit-test coverage given the EM-step impact.

Total effort: ~6–10 hours wall-clock across 6 PRs.

## 2. Triage table

Verified against current code state on `master` HEAD (`80a54fa`, PR #50 merge).

| # | Title | Current state | Disposition |
|---|---|---|---|
| #12 | `findPeaks` minima negation | **FIXED** (`SignalObj.m:1605–1606` has `% FIX: negate data...`) | Close as fixed |
| #13 | `findGlobalPeak` `sOBj` typo | **FIXED** (`SignalObj.m:1582` has `% FIX: typo sOBj→sObj`) | Close as fixed |
| #14 | `shiftMe` does not update `minTime/maxTime` | OPEN (`SignalObj.m:1471–1481`) | Tier 1 / SignalObj group |
| #15 | Analysis Granger `ensCovMask` wrong columns | OPEN (`Analysis.m:1088`) | Tier 1 / Analysis group |
| #16 | `sampeRate` typo | **FIXED** (no matches in `Analysis.m`) | Close as fixed |
| #17 | `CovColl.isCovPresent` off-by-one | OPEN (`CovColl.m:430`) | Tier 1 / CovColl group |
| #18 | `CovColl.findMaxTime` `covShift` twice | OPEN (`CovColl.m:377+379`) | Tier 1 / CovColl group |
| #19 | `TrialConfig.fromStructure` omits `ensCovMask` | OPEN (`TrialConfig.m:159–164`) | Tier 1 / TrialConfig PR (closes #19 + #58 together) |
| #20 | Decoding gamma broadcasting | OPEN (`+nstat/+decoding/PPAF.m:493, 668`) | Tier 1 / Decoding group |
| #21 | `nstColl.getSpikeTimes` uninitialized `count` | OPEN (`nstColl.m:1478–1483`) | Tier 1 / nstColl group |
| #51 | Granger `phiMat` `strfind` per-coefficient | **NEEDS CLOSER LOOK** — current `Analysis.m:1103` uses `sum(gammaVals)` not the `sum(b(ix))` shown in the issue. May already be a partial fix. | Tier 1 / Analysis group (verify-then-fix) |
| #52 | `SignalObj.autocorrelation` `crosscor` typo | **FIXED** (`SignalObj.m:1059, 1066` use `crosscorr` with `% FIX:` tag) | Close as fixed |
| #53 | `times`/`rdivide` aliasing | **NEEDS CLOSER LOOK** — both methods now have `% FIX: copySignal prevents mutating input`; original aliasing claim may be stale. | Tier 1 / SignalObj group (verify-then-fix or close as fixed) |
| #54 | `SignalObj.resample` skips when window mutated | OPEN | Tier 1 / SignalObj group |
| #55 | `nstColl.getFieldVal` pre-increment | OPEN (`nstColl.m:176–178` matches issue exactly) | Tier 1 / nstColl group |
| #56 | `nstColl.getNSTnameFromInd` missing upper bound | OPEN (`nstColl.m:397`) | Tier 1 / nstColl group |
| #57 | `DecodingAlgorithms.estimateInfoMat` `Ic` assigned twice | OPEN (`DecodingAlgorithms.m:479+546`) | Tier 1 / Decoding group |
| #58 | `TrialConfig.fromStructure` positional shift | OPEN (same root cause as #19) | Closed by the same PR as #19 |
| #59 | SSGLM `PPSS_EStep` binomial `JacobianLD` `.^2` typo | OPEN (`+nstat/+decoding/SSGLM.m:373`) | Tier 2 / standalone PR |

### Counts

- **4 already fixed** → close immediately with commit reference (Tier 0).
- **13 confirmed open** → grouped into 5 PRs (Tier 1).
- **2 need execution-time verification** → assigned to their group's PR, may move to "close as fixed" if the verification finds them already-handled.

## 3. Phase 1 — Close already-fixed issues (Tier 0)

Five minutes. Close with a comment + commit reference. No code change.

| Issue | Close with reference to |
|---|---|
| #12 `findPeaks` minima | Current `SignalObj.m:1605–1606` (`% FIX: negate data to find minima (was finding maxima)`) |
| #13 `findGlobalPeak` `sOBj` | Current `SignalObj.m:1582` (`% FIX: typo sOBj→sObj`) |
| #16 `sampeRate` typo | Original audit `6f6eb13 Fix containsChars logic, sampeRate typo, hardcoded color, and undefined vars in logLL` |
| #52 `autocorrelation` `crosscor` | Current `SignalObj.m:1066` (`% FIX: typo crosscor→crosscorr`) |

**Effort:** 5 minutes.

```bash
gh issue close 12 13 16 52 --comment "Verified fixed in current master HEAD. See SignalObj.m:1605/1582/1066 and commit 6f6eb13. Closing as stale."
```

## 4. Phase 2 — Batched bug-fix PRs (Tier 1)

Each PR is scoped to one file/area to keep review small and to avoid cross-PR conflicts. Each PR ships with a unit test under `tests/unit/`.

### PR-A — `SignalObj.m` group (#14, #54, plus verify #53)

**Issues closed:** #14, #54, and either #53 (if still buggy) or close as fixed.

**Changes:**

1. **#14 `shiftMe`** — add `sObj.minTime = min(sObj.time); sObj.maxTime = max(sObj.time);` after the data/time updates at `SignalObj.m:1480`.
2. **#54 `resample`** — add a length-check guard before the `sampleRate`-equality short-circuit so window-mutating sequences (e.g. `setMinTime` between construction and resample) don't get silently skipped.
3. **#53 `times`/`rdivide`** — investigate first; the `% FIX: copySignal` patches suggest the original aliasing has already been addressed. If verified-clean, document in the PR description and close #53 as fixed via this same PR (no code change for it).

**Test:** `tests/unit/testSignalObjShiftMeBounds.m` — call `shiftMe`, assert `minTime`/`maxTime` reflect the new time vector. Plus `testSignalObjResampleWindowMutated.m` for the resample fix.

**Effort:** 1–2 hours.

### PR-B — `CovColl.m` group (#17, #18)

**Issues closed:** #17, #18.

**Changes:**

1. **#17 `isCovPresent`** — change `cov<ccObj.numCov` → `cov<=ccObj.numCov` at `CovColl.m:430`.
2. **#18 `findMaxTime`** — remove the extra `+covShift` outside the loop at `CovColl.m:379`. The in-loop `+covShift` at line 377 is correct; the second application is the bug.

**Test:** `tests/unit/testCovCollIsCovPresentBounds.m` exercises the last-covariate edge case. `testCovCollFindMaxTimeShift.m` constructs a 2-covariate `CovColl` with non-zero `covShift` and asserts `findMaxTime` matches `max(covMaxTimes)+covShift` (not `+2*covShift`).

**Effort:** 30 min.

### PR-C — `nstColl.m` group (#21, #55, #56)

**Issues closed:** #21, #55, #56.

**Changes:**

1. **#21 `getSpikeTimes`** — move `count = 1` before the loop at `nstColl.m:1477`; remove the `if(i==1)` guard inside.
2. **#55 `getFieldVal`** — reorder the increment to come *after* the `neuronNumbers(cnt) = i` write (current order leaves an off-by-one in the paired records). At `nstColl.m:176–178`.
3. **#56 `getNSTnameFromInd`** — fix the truthy-guard to a real bounds check: `ind > 0 && ind <= nstCollObj.numSpikeTrains` at `nstColl.m:397`.

**Test:** `tests/unit/testNstCollMaskedAccessors.m` covers: (a) `getSpikeTimes` with a mask that excludes neuron 1 (regression for #21), (b) `getFieldVal` paired-record consistency (regression for #55), (c) `getNSTnameFromInd` rejects out-of-bounds index with a clear error identifier (regression for #56).

**Effort:** 1 hour.

### PR-D — `TrialConfig.m` `fromStructure` (#19 + #58)

**Issues closed:** #19 AND #58 (same root cause; one PR).

**Change:** rewrite `TrialConfig.m:159–164` `fromStructure` to pass `ensCovMask` and use the correct positional order (or switch to name-value, see below):

```matlab
function tcObj = fromStructure(structure)
    tcObj = TrialConfig(structure.covMask, structure.sampleRate, ...
                        structure.history, structure.ensCovHist, ...
                        structure.ensCovMask, structure.covLag, ...
                        structure.name);
end
```

**Decision gate:** the issue #58 body suggests switching to name-value args to make future field additions safe. That's a public-API change to `TrialConfig` — every existing caller using the positional form would still work (MATLAB tolerates trailing name-value pairs), but the internal `fromStructure` would become explicit. **Recommend** the name-value approach inside `fromStructure` only (constructor signature unchanged for backwards compat).

**Test:** `tests/unit/testTrialConfigRoundTrip.m` constructs a TrialConfig with non-default `ensCovMask` + `covLag` + `name`, round-trips through `toStructure → fromStructure`, asserts all fields equal.

**Migration note:** the Python port has the matching bug (`_trial_config_impl.py:190–197` per #58 body). Coordinate the fix to land in both ports simultaneously to preserve gold-fixture parity.

**Effort:** 45 min.

### PR-E — `Analysis.m` Granger group (#15, #51)

**Issues closed:** #15, and #51 (after verification).

**Changes:**

1. **#15 `ensCovMaskTemp`** — at `Analysis.m:1088`, change `neuronNum` → `neuronNum(i)` so only the specific neuron being tested has its column zeroed.
2. **#51 `phiMat` strfind aggregation** — investigate the current `Analysis.m:1103` (`sum(gammaVals)`); the issue body references an older `sum(b(ix))` form that may already have been refactored. Document the verification in the PR; fix the per-coefficient sign aggregation if still buggy. The Python port (`nSTAT-python`) per-coefficient handling is the reference behavior.

**Test:** `tests/unit/testAnalysisGrangerEnsCovMask.m` — multi-neuron synthetic spike trains with known causal structure, assert (a) the `ensCovMask` exclusion targets the right neuron column (regression for #15), (b) `phiMat` sign matches a hand-computed reference for a 2-coefficient history basis (regression for #51).

**Effort:** 2–3 hours (Granger tests are slow; harness needs ~50 synthetic spikes × N configurations).

### PR-F — Decoding group (#20, #57)

**Issues closed:** #20, #57.

**Changes:**

1. **#20 gamma broadcasting in PPAF** — at `+nstat/+decoding/PPAF.m:493, 668`, replace `gammaNew(:,c) = gamma` (which uses the stale post-loop `c == C`) with `gammaNew = repmat(gamma, 1, C)`. Two sites in one file.
2. **#57 `estimateInfoMat` double assign** — at `DecodingAlgorithms.m:479` and `546`, both lines assign `Ic(1:R, 1:R)` with *different formulas*. Determine which formula is intended; delete or conditionalize the other. The plausible reading (based on neighboring code structure) is that line 479 is dead initialization that 546 overwrites; if confirmed, delete 479.

**Test:** `tests/unit/testPPAFGammaBroadcast.m` exercises a 2-cell decode with a single-vector `gamma`; asserts all columns of `gammaNew` are populated (regression for #20). `testEstimateInfoMatSingleAssign.m` verifies the chosen formula matches a hand-computed reference.

**Effort:** 1–2 hours.

### PR-G — SSGLM `JacobianLD` typo (#59)

**Issues closed:** #59.

**Change:** `+nstat/+decoding/SSGLM.m:373`, change `(1-2*lambdaDelta.^2)` → `(1-2*lambdaDelta)`. The four other call sites in the toolbox (DecodingAlgorithms.m:533, 603; SSGLM.m:458, 545 for `ExplambdaDelta`) all use the linear form. This is unambiguously a copy-paste typo.

**Why a standalone PR**: the EM-step Hessian estimate it affects has measurable downstream impact (per the issue body: "non-antisymmetric around p=0.5, dimensionally inconsistent with `GradLD`"). Worth its own test + commit so the parity story is recorded clearly.

**Test:** `tests/unit/testSSGLMBinomialJacobianLD.m` — construct a synthetic SSGLM fit with a binomial link, run one E-step, assert `JacobianLD` at `p=0.5` matches `basisMat .* 0` (the sigmoid second derivative vanishes at the inflection). Pre-fix: spuriously nonzero. Post-fix: zero to floating-point precision. Plus a parity check vs. the analogous Python port output.

**Effort:** 1–2 hours including the test.

## 5. Sequencing

```
Phase 1: Close already-fixed (#12, #13, #16, #52)        2026-06-12  →  5 min
Phase 2: Batched PRs in dependency order
  PR-A SignalObj group (#14, #54, [#53])                 2026-06-13  →  1–2 hr
  PR-B CovColl group (#17, #18)                          2026-06-13  →  30 min
  PR-C nstColl group (#21, #55, #56)                     2026-06-13  →  1 hr
  PR-D TrialConfig fromStructure (#19, #58)              2026-06-14  →  45 min
  PR-E Analysis Granger (#15, #51)                       2026-06-14  →  2–3 hr
  PR-F Decoding (#20, #57)                               2026-06-14  →  1–2 hr
  PR-G SSGLM JacobianLD (#59)                            2026-06-15  →  1–2 hr
                                                                       ─────────
                                                         TOTAL         ~7–10 hr
                                                         WALL CLOCK    2–3 days
```

PRs A through G are all independent (different files, no shared symbols), so they can land in any order or in parallel. The recommended order optimizes for "fastest to land first" so early progress is visible.

## 6. Acceptance gates per PR

Each PR must:

- [ ] Close the specific issue(s) it targets via `Fixes #N` syntax in the PR body.
- [ ] Add at least one unit test under `tests/unit/` (or extend an existing test class) that fails on the pre-fix code and passes on post-fix.
- [ ] Pass `tools/run_unit_tests.sh` (20+ tests including the new ones).
- [ ] Pass `tools/check_readme_figures.sh` if the change touches a code path consumed by paper examples (only PR-A `SignalObj`, PR-E `Analysis` Granger, and PR-F `Decoding` are at risk here).
- [ ] Update `AUDIT_REPORT.md` "Code quality improvements" tally if the new `% FIX:` tag count rises.

## 7. What this plan deliberately does NOT do

- **Does NOT bundle multiple-files fixes into one PR.** Six small PRs are more reviewable than one giant one. Issues grouped by file get one PR per file.
- **Does NOT investigate whether the Python port has the same fixes.** That's a separate cross-toolbox coordination question. Each PR's body should note the Python-port status (per issue body), but no Python port commits are made.
- **Does NOT touch the `% FIX:` audit-comment convention.** Existing comment style is preserved; new fixes get the same `% FIX:` tag form.
- **Does NOT chase the "needs closer look" issues (#51, #53) beyond a 30-minute investigation budget.** If the issue is genuinely already fixed, close as fixed; if it's a different bug than originally reported, file a follow-up issue with the current state and close the original.

## 8. Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| A "close as fixed" issue (#52) is actually still buggy in a path I didn't check | LOW | Each Tier-0 close cites the specific line where the fix lives. If the reporter disagrees, reopen. |
| PR-D `TrialConfig` change breaks `.mat` files saved by older versions | MED | Older `.mat` files have all the fields (the bug was the read-side path, not the write side). Add a unit test loading a fixture `.mat` from before the fix. |
| PR-E Granger test takes too long to be in the default unit-test gate | MED | Mark as integration test if >30s; runs via `--integration` flag rather than the default gate. |
| PR-F gamma broadcasting test reveals that the bug fix changes paper-example output | LOW | Run `tools/check_readme_figures.sh` as part of the PR. Three Example-03 figures are already on the BLAS-noise allowlist; gamma fix may add more or surface real CORRECTNESS_FIX drift (acceptable per the established figure-parity policy). |
| #51 "needs closer look" turns into a deep refactor | LOW–MED | Time-box at 30 min. If unresolved at that point, file a new specific issue describing current `Analysis.m:1103` behavior and close #51 with a pointer. |

## 9. Exit criteria

- [ ] All 4 Tier-0 issues closed with commit references (Phase 1).
- [ ] All 13 confirmed-open issues either: (a) fixed by a merged PR, or (b) closed as fixed during PR-A/E investigation, or (c) re-filed as a more specific follow-up issue.
- [ ] No open issues remain on master HEAD with state "stale unclosed."
- [ ] `tools/predeploy.sh` runs clean post-final-PR.
- [ ] This plan transitions to status `COMPLETED`.

## 10. Suggested execution order if you commit

1. **Today (2026-06-12, ~5 min):** close #12, #13, #16, #52 with the one-liner from §3.
2. **Tomorrow (2026-06-13):** branch + PRs A, B, C in one work session (~3 hours).
3. **2026-06-14:** PRs D, E, F (~4–6 hours).
4. **2026-06-15:** PR-G + final verification (~2 hours).

If energy/time is the constraint, halt after Tier 0 + PR-G (SSGLM `.^2` typo) — the SSGLM fix is by far the highest-impact item because it actually changes downstream EM-step math. Everything else is correctness-fix or developer-experience.
