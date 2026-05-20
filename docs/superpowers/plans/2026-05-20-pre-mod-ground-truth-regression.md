# Pre-Modernization Ground-Truth Regression Plan

> **Goal:** Use the master HEAD from before this week's 2026-05-19 modernization work (`3494801`) as a ground-truth baseline. Run every example on both `3494801` and current master. Diff the outputs. Classify each diff as **identical**, **changed-as-expected** (with explanation grounded in the commit history), or **changed-unexpected** (the actual signal).

> **Date drafted:** 2026-05-20
> **Reference commit:** `3494801` — "Merge pull request #29 from cajigaslab/fix/restore-original-goal-predict-indexing", dated 2026-03-23.
> **Current commit:** `4303305` (post PR-39, full Phase 0-4 modernization + verification scaffolding).
> **Companion:** [`2026-05-20-deep-dive-verification.md`](2026-05-20-deep-dive-verification.md) — the V0-V4 plan that PR #40 executed. This plan extends V2.1 (paper-value comparison) by using pre-mod as the substitute for "paper values".

---

## Strategic counterargument first

**This plan can produce more noise than signal if you don't classify diffs carefully.** Phase 0 fixed real correctness bugs:

| Pre-mod bug | Affected output |
|---|---|
| `FitResult.logLL` missing `log()` wrapper | `fitObj.logLL` off by `(N_bins - N_spikes)` |
| `Analysis.GLMFit:641` same missing wrapper | Reported `logLL` off by same constant |
| `FitResult.m:371` `delta = sampleRate` not `1/sampleRate` | Reported `logLL` off by `sampleRate²` |
| `computeKSStats` DT-branch unreachable | DT-correction silently skipped; KS values were CT-only |
| `ksdiscrete` reseeded RNG with clock | KS values stochastic per call |
| `DecodingAlgorithms.PP_MStep` `ld.^2` instead of `ld.^3` | Third Poisson moment wrong |

Naively diffing pre-mod vs current outputs will flag every one of these as a "regression." They're *not* regressions; they're the corrections. The signal lives in the diffs that **can't be explained** by known fixes — and those are rare (Phase 3 was almost-entirely refactor, with mechanical pre/post parity verified at unit-test time).

**Do this plan if:** you want a paper-trail document confirming that Phase 0 fixes match their stated mathematical impact, *and* that Phase 3 refactors changed nothing outside the documented Phase 0 fix sites.

**Don't do this if:** you trust the Phase 0 unit tests (e.g., `testFitResultLogLikelihood` lockes the analytic identity at AbsTol 1e-6) and the Phase 3 numerical-parity tests (e.g., `testPPDecodeUpdateIterated` locks K=1 parity at AbsTol 1e-12) as sufficient evidence. They already prove what this plan re-proves at much greater cost.

The marginal value is: **catching a Phase 3 refactor regression that the unit tests happened to miss.** If you want belt-and-suspenders confidence, do it. Otherwise the unit suite is the canonical gate.

**Confidence on the strategic question:** moderate. Lean toward "skip unless paper-bound" — but it's a defensible 6-10 hour investment.

---

## Plan structure

5 phases, mostly automatable. Total effort: **6-10 hours** depending on classification depth.

### Phase D0 — Reference-commit selection + worktree setup (~1 hour)

#### D0.1 Verify `3494801` is the right reference

```bash
git log --oneline 3494801 -5
# Expected: 3494801 + the audit-era commits beneath it.
git diff 3494801 master --stat | tail
# Expected: ~50+ files changed, ~10K+ lines (the Phase 0-4 + verification work)
```

Verify pre-modernization toolbox actually runs:

```bash
git worktree add /tmp/nstat-pre-mod 3494801
cd /tmp/nstat-pre-mod
/Applications/MATLAB_R2025b.app/bin/matlab -batch \
    "addpath(genpath(pwd)); HelloNstat" 2>&1 | tail
# Expected: HelloNstat doesn't exist at 3494801 (added in PR #36).
# So pick a synthetic baseline that does exist at 3494801.
```

Pick **3 reference scripts that exist at both commits**:
- A paper example (e.g., `example01_mepsc_poisson`) — most stable, paper-aligned.
- A Tier-B class demo (e.g., `nSpikeTrainExamples`) — small surface area.
- A paper-aligned tutorial (e.g., `mEPSCAnalysis`) — large surface area, exercises GLM fit.

Avoid `nSTATPaperExamples.m` as a reference (pre-mod, it called direct `DecodingAlgorithms.*` paths; post-mod the `.m` is migrated but the `.mlx` shadow issue makes comparison ambiguous).

#### D0.2 Worktree at the reference commit

```bash
git worktree add /tmp/nstat-pre-mod 3494801
# /tmp/nstat-pre-mod is now a fully-functional clone at 3494801
# Original repo at /Users/iahncajigas/projects/nstat stays on master.
```

Worktree approach avoids the cost of branch-switching back-and-forth — the two clones live side-by-side.

#### D0.3 Confirm data parity

Both worktrees need access to the same figshare data. The reference at `3494801` already used `getPaperDataDirs`; the current master uses the same helper. Verify `data/` symlinks correctly:

```bash
# Either share via a symlink:
ln -s /Users/iahncajigas/projects/nstat/data /tmp/nstat-pre-mod/data
# Or copy if disk allows.
```

**Acceptance:** both worktrees resolve `getPaperDataDirs()` to existing data, both worktrees' MATLAB sessions can `addpath(genpath(pwd))` without missing-toolbox errors.

---

### Phase D1 — Capture pre-mod baseline outputs (~2-3 hours)

#### D1.1 Adapt the harness

`tools/verify_all_examples.m` exists on current master but not at `3494801`. **Copy it into the pre-mod worktree** (the harness is verification scaffolding; using the current harness against the pre-mod code is fine — it's just `runtests` + `lastwarn` + `exportgraphics`):

```bash
cp tools/verify_all_examples.m /tmp/nstat-pre-mod/tools/
```

#### D1.2 Run the harness against pre-mod

```bash
cd /tmp/nstat-pre-mod
/Applications/MATLAB_R2025b.app/bin/matlab -batch \
    "addpath(genpath(pwd)); results = verify_all_examples('Scope', 'all'); \
     save('docs/verification/pre_mod_baseline.mat', 'results');"
```

**Important caveats** (anticipated):
- Some Tier-B helpfiles may **fail differently** on pre-mod than on current master — e.g., `findGlobalPeak('minima')` crashed pre-audit due to the `sOBj` typo. The audit fixed those. Pre-audit failures should NOT be ground truth.
- **`getPaperDataDirs` did exist at 3494801**, so figshare-dependent scripts should run.
- **The Tier-A migrated helpfiles** (DecodingExample etc.) ran via `DecodingAlgorithms.*` directly at `3494801` — they SHOULD produce identical outputs to current master because the deprecation shims forward verbatim.
- **Scripts that didn't exist** at `3494801` (HelloNstat, FoundationModelKSValidation, WhenToUseWhich — all added in PR #36) **must be skipped**; mark them "no baseline available."

#### D1.3 Capture outputs

For each pre-mod-runnable script, capture:
- **Numerical outputs:** `fitObj.logLL`, `fitObj.AIC`, `fitObj.BIC`, fitted coefficients, KS statistics. These should be `disp`'d or assigned to base-workspace variables that the harness can introspect.
- **Figure PNGs:** captured via `exportgraphics`.
- **Stdout text:** captured via `evalc`.

Save as `docs/verification/pre_mod_artifacts/<script_id>/`:
- `numeric.json` — coefficient vector, KS stat, AIC, BIC, logLL.
- `fig*.png` — figures.
- `stdout.txt` — captured stdout.

**Expected failure cases:**
- ~5-10% of Tier-B helpfiles may have pre-audit bugs that cause crashes. Mark those "no baseline available; pre-mod was broken too."

#### D1.4 Cleanup worktree

```bash
git worktree remove /tmp/nstat-pre-mod
```

Or keep it around if you want to re-run.

---

### Phase D2 — Capture current outputs (already mostly done)

The V0-V4 verification (PR #40) already captured current outputs at master `4303305`. Specifically:
- `docs/figures/verify_<ScriptName>/fig*.png` — 91 PNGs from V1.4
- `docs/figures/example0[1-5]/*.png` — 24 paper-example PNGs (from earlier `build_paper_examples`)
- `docs/verification/run_report_20260520-134941.json` — runtime + warning status

**Gap:** the V1.4 harness captures figures but does NOT serialize numerical outputs (no `numeric.json` per script). Need to extend the harness to capture key numerics if D3 is to compare them.

**Option A** (cheap): add a post-run hook that scans the base workspace for variables matching a known schema (e.g., `fitObj`, `xK`, `ks_stat`, `b`, `lambda`) and serializes them.

**Option B** (clean): require each verified script to write a known `<script_id>_outputs.json` in a known location. More invasive but standardized.

Recommend Option A for D3 to keep this plan tractable.

---

### Phase D3 — Diff + classify (~2-4 hours)

For each script that has both a pre-mod baseline and a current output:

#### D3.1 Numerical diff

Pairwise compare:
- Log-likelihood values: expect to **DIFFER** if the script's GLMFit path goes through `Analysis.GLMFit:641` (Phase 0 Task 0.1c bug fix). Document the expected delta: pre-mod logLL = current logLL + `(N_bins - N_spikes)` (plus a `sampleRate²` factor for FitResult bug).
- AIC / BIC: expect to **MATCH** to floating-point precision (both pre- and post-mod compute these from `glmfit` deviance, not from `logLL`).
- Fitted coefficients (`b`): expect to **MATCH** to ~1e-10 (GLM fit is unaffected by the logLL fix).
- KS statistics: expect to **DIFFER unpredictably** if the script uses `DTCorrection=1` (Phase 0 fix made the DT branch reachable; pre-mod was silently CT). For scripts using `DTCorrection=0`, expect MATCH.

#### D3.2 Visual diff (PNG)

For each figure pair:
- **Pixel-identical:** the script's output is byte-exact between pre-mod and current. Implies the refactor was pure (no numerical drift in any path that drives that figure).
- **Pixel-different but visually equivalent:** axes / titles / data series qualitatively match but pixels differ (font rendering, default colors, etc.). Acceptable; document.
- **Visually different:** different data plotted. **Real signal** — needs investigation.

Pixel diff via ImageMagick:
```bash
compare -metric AE pre_mod/figXX.png current/figXX.png /dev/null
# Output: number of differing pixels.
```

Or Python PIL for tolerance-aware:
```python
from PIL import Image, ImageChops
diff = ImageChops.difference(Image.open(pre), Image.open(cur))
bbox = diff.getbbox()
# bbox is None if identical
```

#### D3.3 Per-diff classification

Use this decision tree:

```
diff observed?
├── No → IDENTICAL — record and continue
└── Yes:
    ├── Magnitude consistent with known Phase 0 fix?
    │   ├── Yes → CHANGED-AS-EXPECTED — record the explanation
    │   └── No → CHANGED-UNEXPECTED — investigate
```

Known Phase 0 fix signatures:
- `logLL` shifted by exactly `(N_bins - N_spikes)`: Task 0.1 / 0.1c (Bernoulli `log()` wrapper).
- `logLL` shifted by factor `sampleRate²`: Task 0.5 (`delta = sampleRate` reinterpretation).
- `ks_stat` differs only when `DTCorrection=1` is in effect: Phase 0 follow-up DT-branch fix.
- Anything `mPPCO_*` → `PPLFP_*`-tagged: Phase 3 Task 3.1 rename (identical numerics; only the warning identifier changed).

Anything else is **CHANGED-UNEXPECTED** and gets investigated.

---

### Phase D4 — Report (~1-2 hours)

#### D4.1 Master comparison table

`docs/verification/pre_mod_comparison.md`:

| Script | Output | Pre-mod | Current | Status | Explanation |
|---|---|---|---|---|---|
| example01 | logLL | -867.4 | -2531.8 | CHANGED-AS-EXPECTED | Task 0.1c: shift = (N_bins - N_spikes) = 1664 |
| example01 | AIC | 1739.4 | 1739.4 | IDENTICAL | from glmfit deviance |
| example01 | coefficient[0] | -4.401 | -4.401 | IDENTICAL | β-fit unaffected |
| example01 | ks_stat | 0.052 | 0.057 | CHANGED-EXPECTED | DT-correction branch now reaches |
| example01 | fig01.png | match | match | IDENTICAL | pixel-equivalent |
| ...

#### D4.2 Unexpected-change report

The signal-rich subset. Any CHANGED-UNEXPECTED rows from D4.1 get a dedicated section:

```markdown
## CHANGED-UNEXPECTED — needs investigation

### example_X: <output_name>
- Pre-mod value: A
- Current value: B
- Difference: B - A = Δ
- Could not be explained by: Tasks 0.1, 0.1c, 0.2, 0.3, 0.4, 0.5, 3.x, 4.x
- Hypothesis: ???
- Recommended next step: trace through git log -p --follow on the relevant code path
```

**Expected count:** 0-2 items. Phase 3 refactors had numerical-parity unit tests; any genuine regression would have surfaced there. If D3 finds >5 unexpected changes, the unit tests have a coverage gap.

#### D4.3 Sign-off

`docs/verification/pre_mod_comparison.md` ends with:

```markdown
## Sign-off

- IDENTICAL: N rows
- CHANGED-AS-EXPECTED: M rows (all explained by Phase 0 fix sites — see linked commits)
- CHANGED-UNEXPECTED: K rows (K should be 0 or near-zero)

Reviewer: __________________ Date: __________________
```

---

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Pre-mod toolbox itself crashes on R2025b for some Tier-B helpfiles | Medium | Medium | Mark "no baseline" for those scripts; exclude from D3 diff. |
| RNG-determinism: pre-mod KS values stochastic | High | Low | Either run pre-mod side 5× and take median, OR document KS diffs as "expected uncertain". |
| Data parity not exact (figshare cached files may have been re-downloaded with different SHA between worktrees) | Low | Low | sha256 the data files before D1; assert match. |
| Pre-mod scripts use a different `rng` seed by default | Low | Medium | Force `rng(0, 'twister')` at every script entry in the harness. |
| `glmfit` from MATLAB Statistics Toolbox changed between R2024 and R2025 | Low | Medium | Both worktrees use R2025b; ruled out. |
| Numerical drift from floating-point reassociation in refactored code | Low | Low | Phase 3 unit tests already enforce 1e-12 numerical parity; D3 just confirms at integration scale. |

---

## What this plan does NOT do

- **Does not regenerate the 2012 paper figures.** Those are immutable; we're comparing two versions of the toolbox to each other, not to the paper.
- **Does not fix any regressions.** D3-D4 produces a backlog. Fixes ship in subsequent PRs.
- **Does not modify the harness mid-flight.** If D1 surfaces a script the harness can't capture, mark it and move on.
- **Does not extend to the 28 pre-modernization `.mlx` files.** Those have already been triaged (B1/B2 in the V4 backlog).

---

## Acceptance criteria for the plan itself

When complete, the repo contains:
- [ ] `docs/verification/pre_mod_baseline.mat` — pre-mod harness results
- [ ] `docs/verification/pre_mod_artifacts/<script>/` — per-script captured outputs at `3494801`
- [ ] `docs/verification/pre_mod_comparison.md` — the master diff table
- [ ] A documented count of IDENTICAL / CHANGED-EXPECTED / CHANGED-UNEXPECTED rows
- [ ] Any CHANGED-UNEXPECTED rows have a hypothesis + recommended next step
- [ ] Reviewer sign-off slot (you complete this manually)

---

## Suggested execution

**MVP (4-6 hours):** scope D3 to 3 scripts only (`example01`, `nSpikeTrainExamples`, `mEPSCAnalysis`). If the 3-script diff produces zero CHANGED-UNEXPECTED rows, the unit tests are likely catching everything and the full plan is low-value. Otherwise, scale to the full 23+5 scripts.

**Full plan (6-10 hours):** D0 + D1 (all scripts pre-mod runnable) + D2 (extend harness for numerical capture) + D3 (diff all) + D4 (report).

**Skip path:** the V0-V4 verification (PR #40) already confirms 34/34 current scripts pass with correct analytic identities. The unit-test suite locks Phase 3 refactors at 1e-12 numerical parity. Pre-mod ground-truth comparison would add belt-and-suspenders confidence but might not surface anything the unit tests haven't.

---

## My recommendation

**Execute the MVP first.** If the 3-script diff produces zero CHANGED-UNEXPECTED rows, stop — the unit tests caught everything that mattered. If it produces ≥1 CHANGED-UNEXPECTED row, that's the signal that justifies the full plan. This staged approach avoids investing 6-10 hours into noise-only confirmation.

The MVP is also the right size to ship as a single PR (D0 + D1 + D3 narrow + D4 minimal), so partial progress is reviewable.
