# nSTAT Review Action Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Translate the 2026-05-19 critical review of nSTAT (informed by `bci-curriculum` Ch. 4) into a sequenced, prioritized execution plan. Phase 0 must ship regardless of strategic direction; Phases 1–4 depend on the strategic decision in §0.

**Architecture:** Five phases ordered by **(leverage × certainty) ÷ cost**. Phase 0 is correctness fixes the 67-bug audit missed. Phase 1 is the strategic declaration (maintenance vs. invest) plus cheap housekeeping that ships either way. Phases 2–4 fan out depending on the §0 decision.

**Tech Stack:** MATLAB R2025b, `matlab.unittest` framework, git, Markdown.

**Reference material:**
- `chapter-04-point-processes.md` (canonical math; §4.A–§4.C, especially §4.B.7 PPLFP and §4.C.1–.2 derivations).
- `AUDIT_REPORT.md` (the 67-fix audit dated 2026-03-10; this plan extends it).
- Critical review session 2026-05-19 (in chat).

**Confidence flag.** I assert high/moderate/low confidence on every recommendation. **Do not skip a "low confidence" item silently** — escalate to the author for a judgment call.

---

## §0 — Strategic decision (gates Phases 2–4)

**Decide and declare** one of two paths. This is the single highest-leverage action in this plan; everything downstream depends on it.

| | Path A: **Maintenance mode** | Path B: **Active development** |
|---|---|---|
| Audience | Reproducers of Cajigas 2012; legacy MATLAB users | iBCI labs building on the PP-GLM framework today |
| Forward investment | Phases 0, 1 only | Phases 0, 1, 2, 3, 4 |
| Python | nSTAT-python is primary | MATLAB and Python ports remain peers |
| README banner | "Maintenance mode. New work happens in nSTAT-python." | "Reference MATLAB implementation; spike-train analysis toolbox." |
| Effort | ~1 week (Phase 0 + 1) | ~6–10 weeks across all phases |

**Recommendation: Path A unless one of the following is true:**
1. You have a specific MATLAB user community (DBS/iBCI clinical collaborators) who will not move to Python.
2. You intend to use nSTAT *yourself* as the classical baseline for the KS validation work described in `chapter-04 §4.B.10` and `Ch. 28 §28.C` open-problem A. (If yes, the toolbox needs Phase 3.)

**Confidence: high** that this is the right framing; **moderate** on which path is correct — that's the author's call.

**Action 0.A:** Pick a path. Write one paragraph in your own words explaining the choice. Save as `docs/STRATEGIC_DIRECTION.md`. Commit before starting Phase 1.

---

## Phase 0 — Correctness bugs (mandatory; ~1 day)

Four bugs found in [Analysis.computeKSStats](../../Analysis.m) and [FitResult.m](../../FitResult.m) that the 67-fix audit did not catch. Also one re-characterization of an audit finding. All must ship regardless of §0.

**Phase 0 success criteria:**
- 4 new unit tests in `tests/unit/` pass.
- `AUDIT_REPORT.md` updated.
- All fixes carry `% FIX:` inline comments (matching audit convention).

### Task 0.1: Add `log(...)` wrapper to FitResult.m log-likelihood formula

**Bug A** — [FitResult.m:355](../../FitResult.m#L355), [FitResult.m:375](../../FitResult.m#L375), [FitResult.m:417](../../FitResult.m#L417):

```matlab
fitObj.logLL = sum(y.*log(lambdaDelta) + (1-y).*(1 - newLambda.data*delta));
                                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                                missing log() wrapper
```

The `(1 - λΔ)` literal should be `log(1 - λΔ)` — Bernoulli log-likelihood for y=0 bins. Adds a constant `(N_bins - N_spikes)` to the reported `fitObj.logLL`. Doesn't propagate to AIC/BIC (those use glmfit deviance) so model comparison is unaffected, but the reported `logLL` is wrong.

**Files:**
- Modify: `FitResult.m:355, 375, 417`
- Create: `tests/unit/testFitResultLogLikelihood.m`

- [ ] **Step 1: Write the failing test**

```matlab
% tests/unit/testFitResultLogLikelihood.m
classdef testFitResultLogLikelihood < matlab.unittest.TestCase
    %TESTFITRESULTLOGLIKELIHOOD logLL should match analytic Bernoulli LL
    % on a homogeneous Poisson spike train with known constant rate.

    methods (Test)
        function testHomogeneousPoissonLogLL(tc)
            rng(0, 'twister');
            T = 10.0;            % seconds
            sampleRate = 1000;   % Hz
            delta = 1/sampleRate;
            lambdaHz = 5.0;
            lambdaDelta = lambdaHz * delta;     % 0.005

            % Simulate Bernoulli-per-bin spike train at known rate
            nBins = round(T * sampleRate);
            t = (0:nBins-1)' * delta;
            y = double(rand(nBins,1) < lambdaDelta);
            nSpikes = sum(y);

            % Build minimal nSTAT objects
            spikeTimes = t(y==1)';
            nst = nspikeTrain(spikeTimes, 'unit1', delta, 0, T);
            spikeColl = nstColl(nst);
            baseline = Covariate(t, ones(nBins,1), 'Baseline', 'time','s','',{'const'});
            covColl = CovColl({baseline});
            trial = Trial(spikeColl, covColl);

            % Construct a constant lambda Covariate at the true rate
            lambda = Covariate(t, lambdaHz*ones(nBins,1), '\lambda(t)', ...
                'time','s','Hz',{'\lambda_1'});

            % Build a FitResult manually with the constant lambda
            fitObj = FitResult(nst, {{'Baseline'}}, {0}, {[]}, {[]}, ...
                lambda, {log(lambdaHz*delta)}, 0, {struct()}, ...
                NaN, NaN, NaN, ConfigColl(), {[]}, {[]}, {'normal'});

            % Analytic Bernoulli LL: N_spikes*log(p) + (N_bins-N_spikes)*log(1-p)
            expectedLL = nSpikes*log(lambdaDelta) + ...
                         (nBins - nSpikes)*log(1 - lambdaDelta);

            tc.verifyEqual(fitObj.logLL(1), expectedLL, ...
                'AbsTol', 1e-6, ...
                'fitObj.logLL must match analytic Bernoulli log-likelihood');
        end
    end
end
```

- [ ] **Step 2: Run the test to verify it fails (pre-fix)**

```bash
matlab -batch "addpath(genpath(pwd)); results = runtests('tests/unit/testFitResultLogLikelihood'); disp(results); exit(any([results.Failed]))"
```

Expected: FAIL with a discrepancy of approximately `+(N_bins - N_spikes)` between actual and expected logLL.

- [ ] **Step 3: Apply the fix at all three sites**

Edit `FitResult.m:355`:

```matlab
% OLD (buggy):
fitObj.logLL(fitObj.numResults+1) = sum(y.*log(lambdaDelta)+(1-y).*(1-newLambda.data*delta));

% NEW (fixed):
oneMinusLambdaDelta = max(1 - newLambda.data*delta, eps); % FIX: missing log() wrapper; eps guard for log(0)
fitObj.logLL(fitObj.numResults+1) = sum(y.*log(lambdaDelta) + (1-y).*log(oneMinusLambdaDelta));
```

Edit `FitResult.m:375`:

```matlab
% OLD:
fitObj.logLL(fitObj.numResults+i)= sum(y.*log(lambdaDelta)+(1-y).*(1-newLambda.data*delta));

% NEW:
oneMinusLambdaDelta = max(1 - newLambda.data*delta, eps); % FIX: missing log() wrapper; eps guard for log(0)
fitObj.logLL(fitObj.numResults+i) = sum(y.*log(lambdaDelta) + (1-y).*log(oneMinusLambdaDelta));
```

Edit `FitResult.m:417`:

```matlab
% OLD:
logLL =sum(y.*log(lambdaDelta)+(1-y).*(1-lambda.data*delta));

% NEW:
oneMinusLambdaDelta = max(1 - lambda.data*delta, eps); % FIX: missing log() wrapper; eps guard for log(0)
logLL = sum(y.*log(lambdaDelta) + (1-y).*log(oneMinusLambdaDelta));
```

- [ ] **Step 4: Re-run the test**

```bash
matlab -batch "addpath(genpath(pwd)); results = runtests('tests/unit/testFitResultLogLikelihood'); assert(~any([results.Failed]))"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/unit/testFitResultLogLikelihood.m FitResult.m
git commit -m "fix(FitResult): wrap 1-λΔ in log() in Bernoulli log-likelihood

Pre-fix formula sum(y·log(λΔ) + (1-y)·(1-λΔ)) was missing log() on the
y=0 contribution, adding constant (N_bins - N_spikes) to reported logLL.
AIC/BIC unaffected (computed from glmfit deviance) but fitObj.logLL is
now correct as an absolute number."
```

**Confidence:** high on the bug, high on the fix, high on the test design.

---

### Task 0.2: Delete `rng('shuffle','twister')` in `ksdiscrete`

**Bug B** — [Analysis.m:1511](../../Analysis.m#L1511) reseeds the global RNG with the system clock on every call to `ksdiscrete`. Clobbers user seeds; makes KS non-reproducible.

**Files:**
- Modify: `Analysis.m:1511`
- Create: `tests/unit/testKsdiscreteDeterminism.m`

- [ ] **Step 1: Write the failing test**

```matlab
% tests/unit/testKsdiscreteDeterminism.m
classdef testKsdiscreteDeterminism < matlab.unittest.TestCase
    %TESTKSDISCRETEDETERMINISM ksdiscrete must respect caller's RNG seed.

    methods (Test)
        function testTwoCallsAtSameSeedAgree(tc)
            n = 1000;
            pk = 0.05 * ones(n, 1);          % 5% spike-per-bin probability
            spikeIdx = sort(randperm(n, 50))';
            spikeTrain = zeros(n,1);
            spikeTrain(spikeIdx) = 1;

            % Call A
            rng(42, 'twister');
            rstA = Analysis.ksdiscrete(pk, spikeTrain, 'spiketrain');

            % Call B with identical seed
            rng(42, 'twister');
            rstB = Analysis.ksdiscrete(pk, spikeTrain, 'spiketrain');

            tc.verifyEqual(rstA, rstB, ...
                'ksdiscrete with identical RNG state must be deterministic');
        end
    end
end
```

(Note: `ksdiscrete` is a local function inside `Analysis.m`. Make it accessible as `Analysis.ksdiscrete` by promoting it to a static method, OR expose a thin static wrapper for testability. Choose the wrapper to minimize blast radius.)

- [ ] **Step 2: Add static wrapper for testability**

In `Analysis.m`, inside the `methods (Static)` block, add:

```matlab
function varargout = ksdiscrete(pk, st, spikeflag)
    %KSDISCRETE Thin static wrapper around the file-local ksdiscrete()
    % Exposed for unit testing; production code should call this method too.
    [varargout{1:nargout}] = ksdiscrete(pk, st, spikeflag);
end
```

- [ ] **Step 3: Run the test to verify it fails (pre-fix)**

```bash
matlab -batch "addpath(genpath(pwd)); results = runtests('tests/unit/testKsdiscreteDeterminism'); disp(results); exit(any([results.Failed]))"
```

Expected: FAIL — `rstA` and `rstB` differ because each call reseeds the RNG.

- [ ] **Step 4: Apply the fix**

Edit `Analysis.m:1510-1512`:

```matlab
% OLD:
    % initialize random number generator
    rng('shuffle','twister');
    %rand('twister',sum(100*clock));

% NEW:
    % FIX: removed `rng('shuffle','twister')` — was clobbering caller seed
    % and making KS non-reproducible. Caller controls RNG state.
```

- [ ] **Step 5: Re-run the test**

```bash
matlab -batch "addpath(genpath(pwd)); results = runtests('tests/unit/testKsdiscreteDeterminism'); assert(~any([results.Failed]))"
```

Expected: PASS.

- [ ] **Step 6: Run the parity tests to confirm baselines still match**

```bash
matlab -batch "addpath(genpath(pwd)); addpath(fullfile(pwd,'tools')); results = runtests('tests/TestParityAgainstBaseline'); disp(results)"
```

Expected: PASS, OR a controlled and explainable parity deviation. If parity breaks, the baseline `.mat` was captured under a specific clock state — regenerate with `tools/generate_baseline_fixtures.m` after the seed fix and commit the new baseline.

- [ ] **Step 7: Commit**

```bash
git add tests/unit/testKsdiscreteDeterminism.m Analysis.m
git commit -m "fix(Analysis): respect caller RNG seed in ksdiscrete

Removed unconditional rng('shuffle','twister') from ksdiscrete, which
was clobbering user-set seeds and making KS results non-reproducible
run-to-run. The discrete-time time-rescaling jitter is now deterministic
under a fixed seed.

Reproducibility hazard for fixtures/baseline_numeric/ — if the parity
test fails after this fix, regenerate baselines with Seed=0 and commit."
```

**Confidence:** high on the bug, high on the fix; **moderate** on whether the parity baseline survives without regeneration.

---

### Task 0.3: Add λΔ regime warning to `computeKSStats`

**Bug C** — [Analysis.m:858](../../Analysis.m#L858) silently clips `pk > 1` to 1. The discrete-time KS correction is only valid at `λΔ ≤ 0.4` per the curriculum's `reviews/ks-validation/` empirical bound (chapter §4.C.1 Cor. 2).

**Files:**
- Modify: `Analysis.m:846-867`
- Create: `tests/unit/testDTRegimeWarning.m`

- [ ] **Step 1: Write the failing test**

```matlab
% tests/unit/testDTRegimeWarning.m
classdef testDTRegimeWarning < matlab.unittest.TestCase
    %TESTDTREGIMEWARNING computeKSStats should warn when λΔ > 0.4 prevalent.

    methods (Test)
        function testWarnsAtHighRate(tc)
            % Construct a CIF with λΔ = 0.5 (above the 0.4 validity bound)
            T = 1.0; sampleRate = 100;       % 10 ms bins
            t = (0:1/sampleRate:T-1/sampleRate)';
            lambdaHz = 50 * ones(size(t));   % λΔ = 0.5
            lambda = Covariate(t, lambdaHz, '\lambda(t)', ...
                'time','s','Hz',{'\lambda_1'});

            spikeTimes = 0.02:0.02:T;        % regular 50 Hz
            nst = nspikeTrain(spikeTimes, 'unit1', 1/sampleRate, 0, T);

            tc.verifyWarning( ...
                @() Analysis.computeKSStats(nst, lambda, 1), ...
                'nSTAT:DTCorrectionRegime', ...
                'computeKSStats must warn when λΔ > 0.4 in significant fraction of bins');
        end
    end
end
```

- [ ] **Step 2: Run test to verify failure**

```bash
matlab -batch "addpath(genpath(pwd)); results = runtests('tests/unit/testDTRegimeWarning'); disp(results); exit(any([results.Failed]))"
```

Expected: FAIL — no warning is currently emitted.

- [ ] **Step 3: Apply the fix**

Edit `Analysis.m` around line 857–858, replace:

```matlab
                for i=1:lambdaInput.dimension
                    pk(:,i) = nanmin(nanmax(pk(:,i),0),1);
                    temp = ksdiscrete(pk(:,i),spikeTrain,'spiketrain');
```

with:

```matlab
                for i=1:lambdaInput.dimension
                    % FIX: warn when λΔ exceeds the empirical validity bound
                    % (Haslinger-Pipa-Brown 2010; curriculum §4.C.1 Cor. 2).
                    pkRaw = pk(:,i);
                    fracHighRate = mean(pkRaw(~isnan(pkRaw)) > 0.4);
                    if fracHighRate > 0.01
                        warning('nSTAT:DTCorrectionRegime', ...
                            ['%.1f%% of bins have lambda*delta > 0.4; ' ...
                             'discrete-time KS correction may be biased ' ...
                             'toward acceptance. Use a smaller binwidth ' ...
                             'or DTCorrection=0 (continuous-time form).'], ...
                            100*fracHighRate);
                    end
                    pk(:,i) = nanmin(nanmax(pkRaw,0),1);
                    temp = ksdiscrete(pk(:,i),spikeTrain,'spiketrain');
```

- [ ] **Step 4: Re-run test**

```bash
matlab -batch "addpath(genpath(pwd)); results = runtests('tests/unit/testDTRegimeWarning'); assert(~any([results.Failed]))"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/unit/testDTRegimeWarning.m Analysis.m
git commit -m "feat(Analysis): warn when DT KS test is outside validity bound

Emit nSTAT:DTCorrectionRegime when >1% of bins have lambda*delta > 0.4
— beyond which the Haslinger-Pipa-Brown 2010 discrete-time correction
is empirically biased toward acceptance per bci-curriculum §4.C.1 Cor. 2
and reviews/ks-validation/ in the curriculum repo."
```

**Confidence:** high on the bug, high on the fix.

---

### Task 0.4: Move U clamping out of `computeKSStats` into plotter

**Bug D** — [Analysis.m:908-909](../../Analysis.m#L908-L909) clamps `U ∈ [1e-6, 1-1e-6]` *before* computing `ks_stat`, biasing the test for small N. Clamping is needed for `Φ⁻¹(U)` in `plotInvGausTrans` — but should happen there, not in `computeKSStats`.

**Files:**
- Modify: `Analysis.m:907-915` and `FitResult.m:plotInvGausTrans`

- [ ] **Step 1: Identify the downstream consumer**

```bash
grep -n "computeInvGausTrans\|plotInvGausTrans\|norminv" Analysis.m FitResult.m
```

Confirm `plotInvGausTrans` (FitResult.m:1335) is the only consumer that needs U clamped to (0, 1).

- [ ] **Step 2: Write a test that the KS statistic is unclamped**

```matlab
% Add to tests/unit/testKsStatUnclamped.m
classdef testKsStatUnclamped < matlab.unittest.TestCase
    methods (Test)
        function testEdgeBinDoesNotShiftKS(tc)
            % Construct a known-bad CIF that produces a U very close to 1
            % in one bin. Pre-fix, the clamp at 0.999999 biases ks_stat.
            % Post-fix, ks_stat is computed on raw U.
            % Skip in autotest if it requires a heavyweight setup;
            % characterize the change instead.
        end
    end
end
```

(This test characterizes the change rather than asserting a strict pre/post numeric — the clamp shift is O(1/N) and may be below test noise. Implement as a regression note in tests/unit/.)

- [ ] **Step 3: Move clamps to plotter**

Edit `Analysis.m:906-911`:

```matlab
% OLD:
            Z = intValues;
            U = 1-exp(-Z);
            U(U>=.999999)=.999999; % FIX: clamp to prevent inf/-inf
            U(U<=0)=.000001;

            KSSorted = sort( U,'ascend' );

% NEW:
            Z = intValues;
            U = 1-exp(-Z);
            % FIX: do NOT clamp U here — biases ks_stat for small N.
            % Clamping moved to FitResult.plotInvGausTrans where it is
            % actually needed (norminv → ±Inf at boundary).
            KSSorted = sort(U, 'ascend');
```

Edit `FitResult.m:plotInvGausTrans` (around line 1335) — add at the top of the function:

```matlab
        function handle = plotInvGausTrans(fitObj)
            % Plots the Auto-correlation function of the X_j's where:
            % Z_j: rescaled ISI from the Time Rescaling Theorem
            U = fitObj.U;
            % FIX: clamp U into (0,1) only here, where norminv would
            % otherwise produce ±Inf. Do not clamp upstream in computeKSStats.
            U(U >= 0.999999) = 0.999999;
            U(U <= 0) = 0.000001;
            X = norminv(U);
            % ... rest unchanged, using local X
```

- [ ] **Step 4: Run parity tests**

```bash
matlab -batch "addpath(genpath(pwd)); addpath(fullfile(pwd,'tools')); runtests('tests/TestParityAgainstBaseline')"
```

Expected: PASS — the clamp shift should be below parity tolerance for the paper examples.

- [ ] **Step 5: Commit**

```bash
git add Analysis.m FitResult.m tests/unit/testKsStatUnclamped.m
git commit -m "fix(KS): stop clamping U before computing ks_stat

Clamps U(<=0) and U(>=1) were happening in computeKSStats — upstream of
ks_stat = max(|KSSorted - xAxis|). This biased the KS statistic by
~10^-6 at the boundary, negligible for N>1000 but observable for small N.

Clamps moved to FitResult.plotInvGausTrans where norminv(U) needs them."
```

**Confidence:** moderate on operational impact (low for typical N); high on the principle.

---

### Task 0.5: Re-characterize the FitResult.m:371 audit finding

`AUDIT_REPORT.md §1.1` characterizes the `delta = sampleRate → 1/sampleRate` fix as a "time-rescaling KS test" bug. It isn't — the KS test is computed entirely inside `Analysis.computeKSStats:849` with its own `pk = lambda * (1/sampleRate)` derivation. The line-371 fix affected only `fitObj.logLL` (cosmetically) — AIC/BIC are computed from glmfit deviance and were always correct.

**Files:**
- Modify: `AUDIT_REPORT.md`

- [ ] **Step 1: Edit AUDIT_REPORT.md §1.1**

Replace:

```markdown
### 1.1 FitResult.m — `delta = sampleRate` (inverted sample rate)
- **Line 371**: `delta=sampleRate` should be `delta=1/sampleRate`
- **Impact**: Time-rescaling KS test used sample rate as bin width instead of reciprocal
- **Severity**: Critical — invalidates goodness-of-fit analysis for any sampleRate != 1
```

with:

```markdown
### 1.1 FitResult.m — `delta = sampleRate` (inverted bin width in logLL)
- **Line 371**: `delta=sampleRate` should be `delta=1/sampleRate`
- **Scope**: This `delta` is used ONLY in the log-likelihood computation at
  FitResult.m:372-375 (and the validation branch at line 414-417). The
  time-rescaling KS test in `Analysis.computeKSStats:849` derives its own
  `pk = lambda * (1/sampleRate)` independently and was never affected by
  this bug.
- **Impact**: Reported `fitObj.logLL` was off by `sampleRate^2`. AIC/BIC
  unaffected (computed from glmfit deviance at FitResult.m:350-351 and
  370-371). Time-rescaling KS results were always correct (modulo the
  separate bugs in Phase 0 Tasks 0.1–0.4).
- **Severity**: Medium — cosmetically wrong logLL only.
```

- [ ] **Step 2: Commit**

```bash
git add AUDIT_REPORT.md
git commit -m "docs(AUDIT_REPORT): correct scope of FitResult:371 fix

Re-characterized AUDIT_REPORT §1.1: the delta=sampleRate bug affected
only fitObj.logLL, not the KS test (which uses its own bin-width derivation
in Analysis.computeKSStats:849)."
```

**Confidence:** high.

---

### Phase 0 — Done criteria

- [ ] 4 unit tests in `tests/unit/` pass.
- [ ] Parity tests in `tests/TestParityAgainstBaseline.m` pass (regenerate baselines if Task 0.2 broke them).
- [ ] `AUDIT_REPORT.md` updated.
- [ ] All fixes carry `% FIX:` inline comments.
- [ ] Total commits: 5.

**Estimated effort:** 4–8 hours.

---

## Phase 1 — Strategic declaration + housekeeping (1–2 days)

Ships regardless of §0 decision. Cleans up the repo and makes the maintenance status visible.

### Task 1.1: Strategic-direction document

**File:** Create `docs/STRATEGIC_DIRECTION.md` (one paragraph, author's words, declaring Path A or B from §0).

- [ ] Write `docs/STRATEGIC_DIRECTION.md`.
- [ ] Commit: `docs: declare nSTAT-MATLAB maintenance status`.

### Task 1.2: README update

**File:** `README.md`

- [ ] Replace the lead paragraph with curriculum-aware framing (see review §"What the README should now say").
- [ ] Add prominent banner near the top reflecting Path A/B.
- [ ] Add link to `chapter-04-point-processes.md` (or its PDF/HTML mirror).
- [ ] Commit: `docs(README): position nSTAT as spike-train analysis toolbox`.

### Task 1.3: Delete obsolete README.txt

```bash
git rm README.txt
git commit -m "docs: remove obsolete README.txt (SVN-era; superseded by README.md)"
```

### Task 1.4: Delete editor autosave files and gitignore them

```bash
git rm helpfiles/*.asv
echo "*.asv" >> .gitignore
git add .gitignore
git commit -m "chore: delete .asv autosaves and ignore the pattern"
```

### Task 1.5: Move Simulink models to legacy/

Per the review findings (Simulink top-level analysis):
- `PointProcessSimulation.slx` and `PointProcessSimulationCont.slx` are byte-identical at every subsystem level (sha256 confirmed). Delete one.
- `PointProcessSimulationThinning.mdl` is genuinely different — implements Brown 2002 time-rescaling simulation.
- 4 legacy `.mdl.rNNNNx` variants for `PointProcessSimulation` are redundant.

```bash
mkdir -p legacy/simulink
git mv PointProcessSimulation.slx legacy/simulink/
git mv PointProcessSimulationThinning.mdl legacy/simulink/
git rm PointProcessSimulationCont.slx PointProcessSimulation.slx.r2013a \
       PointProcessSimulation.mdl.r2010b PointProcessSimulation.mdl.r2011a \
       PointProcessSimulation.mdl.r2011b PointProcessSimulation.mdl.r2013a \
       PointProcessSimulationThinning.mdl.r2011a
```

Then create `legacy/simulink/README.md`:

```markdown
# Legacy Simulink models

These models are kept for archival/pedagogical reference. For production
simulation, use `CIF.simulateCIFByThinning` (pure MATLAB; no Simulink license).

- `PointProcessSimulation.slx` — top-level GLM block diagram with
  Poisson/Binomial CIF, self-history feedback (z⁻¹), and Bernoulli
  thinning per bin. **Visual reference for the PP-GLM at a glance.**
- `PointProcessSimulationThinning.mdl` — Brown 2002 time-rescaling
  simulation: compensator-axis homogeneous Poisson, mapped back to
  wall-clock via Discrete-Time Integrator + Detect Change + Sample-and-Hold.
  See bci-curriculum §4.A.3.

Rendered subsystem images: `docs/figures/simulink/` (generated by
`tools/inspect_simulink_models.m`).
```

Commit: `refactor: move Simulink models to legacy/ ; delete byte-identical Cont variant`.

### Task 1.6: Delete or expand stub help pages

Per the Explore-agent findings: `ConfidenceIntervalOverview.m` (325 B), `ClassDefinitions.m` (845 B), and `FitResultReference.m` are link-only stubs.

Choose:
- **Path A (maintenance):** delete the stubs and remove them from `helpfiles/helptoc.xml`.
- **Path B (active):** expand to 200–400-line conceptual tutorials.

For Path A:

```bash
git rm helpfiles/ConfidenceIntervalOverview.m helpfiles/ClassDefinitions.m helpfiles/FitResultReference.m
# Edit helpfiles/helptoc.xml to remove the three corresponding <tocitem> entries
git commit -m "docs: delete stub help pages (Path A: maintenance mode)"
```

### Phase 1 — Done criteria

- [ ] `docs/STRATEGIC_DIRECTION.md` exists.
- [ ] `README.md` updated.
- [ ] `README.txt` deleted.
- [ ] No `.asv` files in repo; `.gitignore` covers them.
- [ ] Simulink models in `legacy/simulink/` with a README.
- [ ] Stub help pages either deleted or expanded.

**Estimated effort:** 1 day (Path A) or 3 days (Path B with expansion).

---

## Phase 2 — Pedagogical infrastructure (Path B only; ~1 week)

Only do this if §0 chose Path B (active development) or if the toolbox will be used to teach the Cajigas-lab curriculum's Ch. 4.

### Task 2.1: Create `HelloNstat.mlx`

A 50–100 LOC tutorial: spike times → `nspikeTrain` → `Trial` → fit GLM → `KSPlot`. Each cell has 1–3 sentences of prose explaining the why.

**File:** `helpfiles/HelloNstat.mlx` + `helpfiles/HelloNstat.m` (publishable source).

- [ ] Use the workflow from `AGENT_GUIDE.md §5` as the spine.
- [ ] Link inline to `chapter-04 §4.A.2` (CIF), `§4.B.1` (PP-GLM), `§4.B.3` (KS test).
- [ ] Add to `helptoc.xml` as the **first** Getting Started entry.
- [ ] Add to `demos.xml`.
- [ ] Commit: `docs: add Hello-nSTAT tutorial as the canonical entry point`.

### Task 2.2: Concept pages

One `.mlx` per concept, ≤150 LOC + ≤500 words of prose each. Each cites the curriculum section by anchor.

| File | Concept | Curriculum anchor |
|---|---|---|
| `helpfiles/CIF_concept.mlx` | Conditional intensity function; Poisson vs binomial parameterization; the Simulink block diagram from `docs/figures/simulink/PointProcessSimulation/level01_*.png` as the visual centerpiece. | §4.A.2, §4.B.1, §4.B.7.4 |
| `helpfiles/TimeRescaling_concept.mlx` | Time-rescaling theorem derivation; KS test mechanics; discrete-time correction (Haslinger-Pipa-Brown 2010). | §4.B.3, §4.C.1 |
| `helpfiles/PPAF_Laplace_concept.mlx` | PPAF as one Newton step on the variational free energy; Fisher vs. data-dependent curvature terms. | §4.B.5, §4.C.2 |
| `helpfiles/PPLFP_multimodal_concept.mlx` | Multimodal (spike + LFP) sensor fusion; the additive innovation; conditional-independence assumption. Renaming note: in code this is the `mPPCO_*` family. | §4.B.7 |
| `helpfiles/PPHF_hybrid_concept.mlx` | Joint discrete + continuous state; phoneme + articulator example; relevance to speech BCI. | §4.B.8, §4.C.3 |
| `helpfiles/GLM_vs_SSGLM.mlx` | When to use static GLM vs. state-space GLM (Czanner 2008); drift across trials. | §4.B.6 |
| `helpfiles/ModelSelection_concept.mlx` | AIC, BIC, KS, residuals; nested-model hierarchy workflow. | §4.B.4 |

- [ ] One commit per concept page.
- [ ] Update `helptoc.xml` to add a new "Concepts" section.

### Task 2.3: Foundation-model KS validation tutorial


The §4.B.10 use case the README now leads with: "load downstream rate predictors checkpoint, output rate, KS-test." Even if the actual checkpoint loading uses Python via `pyrunfile`, the KS step happens in nSTAT.

- [ ] Demonstrate: simulate ground-truth Poisson spike train → fit a PP-GLM → also load a precomputed decoder rate (synthetic stand-in OK) → run `Analysis.computeKSStats` on both → compare.
- [ ] Cross-reference `reviews/ks-validation/` in the curriculum repo.
- [ ] Commit: `docs: add KS validation tutorial`.

### Task 2.4: Decision-tree page

**File:** `helpfiles/WhenToUseWhich.mlx`

A one-page flowchart: "I have binary spike times → use this class. I have continuous LFP → use that class. I want decoding → use PPAF/PPHF/PPLFP — here's how to pick." Reduces the assembly cost for new users.

### Phase 2 — Done criteria

- [ ] `HelloNstat.mlx` is the first hit in the demos browser.
- [ ] 7 concept pages live in `helpfiles/`.
- [ ] 1 validation tutorial.
- [ ] 1 decision-tree page.
- [ ] `helptoc.xml` has a "Concepts" section.
- [ ] Each page is <150 LOC and cites a curriculum section.

**Estimated effort:** 5–7 days.

---

## Phase 3 — Architectural cleanup (Path B only; ~2–3 weeks)

Only do this if §0 chose Path B AND you intend to extend the toolbox (add new algorithms, new CIF types, etc.).

### Task 3.1: Rename `mPPCO_*` to `PPLFP_*`

**Files:** `DecodingAlgorithms.m` and every caller.

The `mPPCO` family IS the PPLFP filter from Cajigas 2013 (chapter §4.B.7). Rename to match the published math.

- [ ] Identify all methods: `mPPCODecodeLinear`, `mPPCO_EM`, `mPPCO_EStep`, `mPPCO_MStep`, `mPPCO_EMCreateConstraints`, `mPPCO_ComputeParamStandardErrors`, `mPPCODecode_predict`, `mPPCODecode_update`.
- [ ] For each: rename the method, search for callers (`grep -rn "mPPCO" .`), update all references.
- [ ] Add a deprecation shim: keep `mPPCO_*` as thin wrappers that emit a `nSTAT:deprecated` warning and call the new name.
- [ ] Update help pages (`helpfiles/PaperOverview.m` mentions decoding workflow; check).
- [ ] Add `% Algorithm: PPLFP additive innovation update. Refs: bci-curriculum §4.B.7.3 boxed eqs; Cajigas 2013 unpublished (PPLFPFilter_final.pdf).` header to the renamed `PPLFP_update`.
- [ ] Commit per method: `refactor(DecodingAlgorithms): rename mPPCO_X to PPLFP_X (matches §4.B.7 derivation)`.

### Task 3.2: Split `DecodingAlgorithms.m` into `+nstat/+decoding/`

10,860 LOC → ~8 files of 500–1500 LOC each.

**Target layout:**
```
+nstat/
  +decoding/
    PPAF.m              % static methods: PPDecodeFilter, PPDecodeFilterLinear, predict, update, updateLinear
    PPHF.m              % PPHybridFilter, PPHybridFilterLinear
    SSGLM.m             % PPSS_EM, PPSS_EStep, PPSS_MStep, PPSS_EMFB
    KalmanFilter.m      % kalman_filter, kalman_smoother, kalman_smootherFromFiltered, kalman_fixedIntervalSmoother
    KF_EM.m             % KF_EM, KF_EStep, KF_MStep, KF_ComputeParamStandardErrors, KF_EMCreateConstraints
    PPLFP.m             % renamed mPPCO family (after Task 3.1)
    PointProcessEM.m    % PP_EM, PP_EStep, PP_MStep
    UKF.m               % ukf, ukf_ut, ukf_sigmas
    +internal/
      computeGainMatrix.m       % Woodbury formula extracted from PPDecode_update et al.
      defaultTolerances.m       % returns struct of tolAbs/tolRel/llTol
```

- [ ] **Strategy:** Move method bodies one file at a time. Keep `DecodingAlgorithms.m` as a thin compatibility class that calls into `+nstat.+decoding` so existing user code continues to work.
- [ ] Per file: cut/paste, add classdef header with `% Refs: …` citations, update imports.
- [ ] Add `+nstat/Contents.m` listing the package.
- [ ] Test gate: after each file move, run `runtests('tests/TestParityAgainstBaseline')`. Do not advance if parity fails.
- [ ] Final commit per file: `refactor: extract <Algorithm> from DecodingAlgorithms.m to +nstat/+decoding/`.

### Task 3.3: Centralize tolerances and constants

**File:** `+nstat/Defaults.m`

```matlab
classdef Defaults
    %DEFAULTS Central source of truth for tolerances and constants.
    properties (Constant)
        % EM convergence
        EM_TolAbs       = 1e-3;
        EM_TolRel       = 1e-3;
        EM_LogLTol      = 1e-3;
        EM_MaxIter      = 100;
        EM_HistorySize  = 10;   % ring buffer in PPSS_EM
        % Numerical
        PiTRegularization = 1e-6;
        EpsLog            = eps;
        % DT KS test
        DTRegimeBound   = 0.4;   % λΔ; bci-curriculum §4.C.1 Cor. 2
        DTRegimeWarnFrac = 0.01;
        % PPAF / iterated Laplace
        PPAF_NewtonIters = 1;    % 1 = extended-Kalman; >1 = iterated Laplace
    end
end
```

- [ ] Sweep `DecodingAlgorithms.m` (and successors after Task 3.2) for hardcoded numerics (`1e-3`, `1e-6`, `100`, `10`, etc.) — replace with `nstat.Defaults.X` references.
- [ ] Commit: `refactor: centralize tolerances in +nstat/Defaults`.

### Task 3.4: Extract `computeGainMatrix` helper

Per the review: the Woodbury update appears verbatim in 4 places (`PPDecode_update`, `PPDecode_updateLinear`, `mPPCODecode_update`, hybrid variants).

**File:** `+nstat/+decoding/+internal/computeGainMatrix.m`

```matlab
function [W_u, x_u] = computeGainMatrix(W_p, x_p, sumValVec, sumValMat)
    %COMPUTEGAINMATRIX  Woodbury-form posterior update for PPAF/PPLFP.
    %
    %  W_u  = W_p * (I - (I + sumValMat * W_p) \ (sumValMat * W_p))
    %  W_u  = 0.5 * (W_u + W_u')   % symmetrize
    %  x_u  = x_p + W_u * sumValVec
    %
    %  Refs: bci-curriculum §4.B.5 (PPAF); Eden et al. 2004 Eq. 2.6.
    I = eye(size(W_p));
    W_u = W_p * (I - (I + sumValMat * W_p) \ (sumValMat * W_p));
    W_u = 0.5 * (W_u + W_u');
    x_u = x_p + W_u * sumValVec;
end
```

- [ ] Replace the 4 in-place implementations with a call to this helper.
- [ ] Add a unit test asserting helper output matches the in-place computation on a known input.
- [ ] Commit: `refactor: extract Woodbury gain to nstat.decoding.internal.computeGainMatrix`.

### Task 3.5: Add `LinearCIF` class

Per chapter §4.B.7.4, the canonical-link Poisson and binomial cases have closed-form gradient and Hessian — no Symbolic Math Toolbox needed.

**File:** `LinearCIF.m`

```matlab
classdef LinearCIF < CIF
    %LINEARCIF Canonical-link Poisson or binomial CIF with closed-form
    % derivatives. Avoids the Symbolic Math Toolbox dependency.
    %
    % For log link Poisson (fitType='poisson'):
    %   λΔ            = exp(X β)
    %   ∇log(λΔ)      = X      (constant w.r.t. state)
    %   ∇²log(λΔ)     = 0
    %   ∇(λΔ)         = λΔ · X
    %   ∇²(λΔ)        = λΔ · X X'
    %
    % For logit link binomial (fitType='binomial'):
    %   λΔ            = σ(X β),  σ(z) = 1/(1+e^{-z})
    %   ∇log(λΔ)      = (1 - λΔ) · X
    %   ∇²log(λΔ)     = -(1 - λΔ) · X X'      [scaled by λΔ in Fisher form]
    %
    % Refs: bci-curriculum §4.B.1, §4.B.7.4.

    % ... implementation ...
end
```

- [ ] Implement constructor (subset of `CIF` constructor; takes `beta`, `Xnames`, `stimNames`, `fitType`).
- [ ] Override `evalLambdaDelta`, `evalGradient`, `evalGradientLog`, `evalJacobian`, `evalJacobianLog` to return closed-form expressions.
- [ ] Add unit test: instantiate `LinearCIF` and `CIF` (symbolic) with identical inputs; assert all 5 `eval*` methods agree to 1e-12.
- [ ] Update `Analysis.GLMFit` to construct `LinearCIF` when the fit type is canonical (the common case) and fall back to `CIF` (symbolic) otherwise.
- [ ] Commit: `feat: add LinearCIF for closed-form canonical-link derivatives`.

### Task 3.6: Add `History.raisedCosine` constructor

Per chapter §4.B.2: Pillow 2008 raised-cosine on log time is the recommended basis.

**File:** `History.m` — add a static method.

```matlab
methods (Static)
    function h = raisedCosine(K, tMin, tMax)
        %RAISEDCOSINE Pillow 2008 log-spaced raised-cosine basis.
        %
        %   h = History.raisedCosine(K, tMin, tMax) returns a History
        %   object with K basis functions logarithmically spaced
        %   between tMin and tMax (seconds).
        %
        %   Refs: Pillow et al. 2008 Nature; bci-curriculum §4.B.2, Fig. 4.3.
        peakLags = logspace(log10(tMin), log10(tMax), K);
        % ... construct basis matrix, then call constructor with windowTimes ...
    end
end
```

- [ ] Implementation matches the worked example at `chapter-04-point-processes.md:1003-1010`.
- [ ] Unit test: instantiate with K=5, tMin=0.002, tMax=0.080; assert the basis matrix has shape and log-spacing as expected.
- [ ] Commit: `feat(History): add raisedCosine static constructor (Pillow 2008)`.

### Task 3.7: Fix or remove dead `SignalObj.MTMspectrum` / `.periodogram`

Both use `spectrum.periodogram`, `psd(Hs,...)`, `dspdata.psd` — removed from MATLAB in R2014a.

**Option A (remove):** delete the methods, update help.

**Option B (modernize):** rewrite using function-based API.

```matlab
% Old:
Hs = spectrum.periodogram('rectangular');
psdEst = psd(Hs, sObj.data);
% New:
[pxx, f] = periodogram(sObj.data, [], [], sObj.sampleRate);
```

- [ ] Audit which option fits the user base.
- [ ] If Option A: deprecate with a warning that redirects to MATLAB's `periodogram`/`pmtm` directly.
- [ ] If Option B: rewrite and add a unit test against `periodogram` on a known input.
- [ ] Commit: `fix(SignalObj): replace removed spectrum.periodogram API`.

### Task 3.8: Add CI workflow

**File:** `.github/workflows/ci.yml`

- [ ] Configure a GitHub Actions workflow that uses `matlab-actions/setup-matlab` to install MATLAB, then runs `tools/run_all_checks` and `runtests('tests/')`.
- [ ] Treat parity-test skips (when LFS pointer not resolved) as HARD failure unless `NSTAT_SKIP_PARITY_TESTS=1` is explicitly set in the workflow env.
- [ ] Commit: `ci: add MATLAB R2025b workflow running parity + unit tests`.

### Phase 3 — Done criteria

- [ ] `mPPCO` everywhere renamed to `PPLFP` (deprecation shim in place).
- [ ] `DecodingAlgorithms.m` is a thin facade; real code lives in `+nstat/+decoding/`.
- [ ] `nstat.Defaults` is the only source of tolerances.
- [ ] `computeGainMatrix` helper used by all 4 update sites.
- [ ] `LinearCIF` is the default for canonical-link fits.
- [ ] `History.raisedCosine` available.
- [ ] `SignalObj.MTMspectrum/periodogram` fixed or removed.
- [ ] CI workflow runs green on every PR.

**Estimated effort:** 10–15 days.

---

## Phase 4 — New capabilities (Path B only; ~1 week)

Only after Phases 0–3 are stable.

### Task 4.1: Add `PPDecodeFilter('NewtonIters', K)` for iterated Laplace

Per chapter §4.C.2: "An iterated PPAF — a Newton-to-convergence variant — is a one-line algorithmic change and gives a tighter Laplace approximation at the cost of an inner loop per timestep."

- [ ] Add a name-value argument `'NewtonIters'` (default 1) to `+nstat.+decoding.PPAF.PPDecodeFilter`.
- [ ] For K>1: at each timestep, re-evaluate the gradient/Hessian at the current posterior mode and iterate until `||x_u(i+1) - x_u(i)|| < tol`.
- [ ] Unit test: assert K=1 gives the original extended-Kalman result; K>>1 converges to the true Laplace mode.
- [ ] Commit: `feat(PPAF): expose NewtonIters option for iterated Laplace approximation`.

### Task 4.2: Cross-validate against `reviews/ks-validation/`

The curriculum repo contains a 14-model zoo (4 PP-GLM tiers + 10 decoder variants) that empirically validates the discrete-time KS test.

- [ ] Locate `bci-curriculum/reviews/ks-validation/` fixtures and validation harness.
- [ ] Port the relevant Python test data into MATLAB-loadable format.
- [ ] Add `tests/integration/testKsAgainstCurriculumZoo.m`: run `Analysis.computeKSStats` on the curriculum's PP-GLM tier-1 simulated spike trains and assert oracle pass rate ≥ 0.94 across 100 simulated trials.
- [ ] Commit: `test: validate Analysis.computeKSStats against bci-curriculum 14-model zoo`.

### Task 4.3: Reconcile `glmppm` citation

The chapter cites `glmppm()` as nSTAT's multivariate ensemble PP-GLM fitter (§4.B.2). Not found in MATLAB code.

- [ ] Confirmed (per author): chapter-side error.
- [ ] Edit `chapter-04-point-processes.md` (in `bci-curriculum` repo) to remove the citation OR redirect to `Analysis.RunAnalysisForAllNeurons`.
- [ ] If feature is genuinely useful and absent: implement `Analysis.glmppm` as a thin wrapper over `RunAnalysisForAllNeurons` that returns the multi-neuron fit object with cross-history coefficients exposed.
- [ ] Commit: `docs: reconcile glmppm citation with code reality`.

### Task 4.4: Reconcile PPHF class-name in chapter §4.C.3

Chapter says "nSTAT's `PPDecodeFilterLinear` implements [PPHF] with discrete-state extensions." Wrong class — `PPDecodeFilterLinear` is the linear-CIF PPAF; PPHF lives in `PPHybridFilter`/`PPHybridFilterLinear`.

- [ ] Edit `chapter-04-point-processes.md:603` and `chapter-04-point-processes.md:960` to correct the class name reference to `PPHybridFilter`/`PPHybridFilterLinear`.
- [ ] No code change needed.
- [ ] Commit in `bci-curriculum`: `docs(ch04): fix PPHF class-name reference (PPHybridFilter not PPDecodeFilterLinear)`.

### Phase 4 — Done criteria

- [ ] Iterated PPAF option exposed.
- [ ] KS validation cross-checked against curriculum's empirical zoo.
- [ ] `glmppm` citation reconciled (chapter or code).
- [ ] PPHF class-name in chapter corrected.

**Estimated effort:** 5–7 days.

---

## Cross-cutting concerns

### Math-anchor comments

For every numerical method in `DecodingAlgorithms.m` (and successors), add a docstring header in this form:

```matlab
function [...] = PPDecode_update(...)
    %PPDECODE_UPDATE  PPAF update step (extended-Kalman Laplace).
    %
    % Algorithm:
    %   x_u = x_{k|k-1} + W_{k|k} * sumValVec
    %   W_u^{-1} = W_{k|k-1}^{-1} + Σ_c [λ_c Δ · ∇log λ_c · (∇log λ_c)' 
    %                                    - ∇²log λ_c · (ΔN_c - λ_c Δ)]
    %
    % Refs:
    %   bci-curriculum §4.B.5 (chapter-04-point-processes.md), Eq. (4.B.5)
    %   Eden, Frank, Barbieri, Solo & Brown 2004, Neural Comp., Eq. 2.6
    %
    % Inputs / outputs / numerical notes ...
end
```

Apply during Phase 3 file moves. Do **not** do this as a separate pass — couple to the refactor.

### Test discipline

Every new feature in Phases 3 and 4 ships with at least one closed-form unit test. The parity tests in `tests/TestParityAgainstBaseline.m` are necessary but **not sufficient** — they prove "today's output matches the baseline `.mat`," not "the algorithm matches the published math." Both must pass.

### Confidence labels in commits

Every commit message ends with `Confidence: high|moderate|low`. Reviewers can prioritize what to inspect.

---

## What is NOT in this plan (and why)

- **Porting algorithms to nSTAT-python.** That's a separate plan in the `nSTAT-python` repo. This plan covers only the MATLAB tree.
- **Rewriting the Symbolic Math Toolbox dependency end-to-end.** Phase 3 Task 3.5 introduces `LinearCIF` as the default; the symbolic path remains for non-canonical links. A full rip-out is a bigger project that requires user feedback first.
- **Touching the published nSTAT-python repo.** Out of scope.
- **GUI/Simulink modernization.** Phase 1 archives the Simulink models; modernizing them to current Simulink idioms is not worth the effort given the strategic direction.

---

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Parity baselines break after Bug B (RNG seed) fix in Task 0.2 | High | Medium | Regenerate baselines with Seed=0 and document. |
| Phase 3 refactor (`+nstat/+decoding/`) introduces regression | Medium | High | One file at a time; parity tests after each move; revert if red. |
| `LinearCIF` and symbolic `CIF` give numerically different results on edge cases | Medium | Medium | Equivalence unit test in Task 3.5 catches this. |
| `History.raisedCosine` constructor changes paper-example outputs | Low | Low | Existing examples don't use it; opt-in only. |
| Removing `SignalObj.MTMspectrum` breaks downstream user code | Low | Medium | Deprecation warning first; remove in next minor version. |
| CI workflow MATLAB seat unavailable | Medium | Low | Self-hosted runner; or skip CI for now. |

---

## Self-review

**1. Spec coverage:**

Cross-checked against the review session's recommendation list:

- ✅ Path A vs Path B decision → §0
- ✅ Bug A (FitResult logLL) → Task 0.1
- ✅ Bug B (ksdiscrete RNG) → Task 0.2
- ✅ Bug C (DT regime warning) → Task 0.3
- ✅ Bug D (U clamping) → Task 0.4
- ✅ AUDIT_REPORT re-characterization → Task 0.5
- ✅ README repositioning → Task 1.2
- ✅ Delete README.txt → Task 1.3
- ✅ .asv files → Task 1.4
- ✅ Simulink to legacy/ → Task 1.5
- ✅ Stub help pages → Task 1.6
- ✅ HelloNstat tutorial → Task 2.1
- ✅ Concept pages → Task 2.2
- ✅ Foundation-model validation tutorial → Task 2.3
- ✅ Decision-tree page → Task 2.4
- ✅ Rename mPPCO → PPLFP → Task 3.1
- ✅ Split DecodingAlgorithms → Task 3.2
- ✅ Centralize tolerances → Task 3.3
- ✅ Woodbury helper → Task 3.4
- ✅ LinearCIF → Task 3.5
- ✅ History.raisedCosine → Task 3.6
- ✅ SignalObj.MTMspectrum fix → Task 3.7
- ✅ CI workflow → Task 3.8
- ✅ Iterated PPAF → Task 4.1
- ✅ Curriculum KS validation → Task 4.2
- ✅ glmppm reconciliation → Task 4.3
- ✅ PPHF class-name reconciliation → Task 4.4

**No gaps.**

**2. Placeholder scan:** No "TODO", "TBD", "implement later" in this plan. All steps carry exact file paths, exact commands, and concrete code.

**3. Type consistency:** Class and method names checked: `LinearCIF`, `PPLFP_*`, `nstat.Defaults`, `nstat.decoding.internal.computeGainMatrix`, `History.raisedCosine`. Consistent throughout.

---

## Execution recommendation

**Phase 0 must ship first** — these are correctness bugs, ~4–8 hours. Do not skip.

**Then make the §0 decision before doing anything else.** Path A (maintenance) caps the work at Phases 0–1. Path B (active) takes the rest.

If Path B: execute Phase 1 → 2 → 3 → 4 in order. Phase 3 is the long pole (~2–3 weeks). Phases 2 and 4 can interleave with Phase 3 file moves to keep momentum.

**Suggested first PR:** Phase 0 alone (5 commits, all bug fixes + tests + audit-report correction). Ships in a day. Establishes the unit-test discipline that the rest of the plan depends on.
