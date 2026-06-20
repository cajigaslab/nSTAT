# nSTAT — Agent Guide

A practical handbook for an AI agent (or a new engineer) working in this repo.
Optimized for "I need to do something useful in nSTAT and I have not read the
paper." Read this top to bottom before grepping. For the conceptual story, read
the paper:

- Cajigas I, Malik WQ, Brown EN. *nSTAT: Open-source neural spike train
 analysis toolbox for Matlab.* J Neurosci Methods 211:245-264 (2012).
 DOI: `10.1016/j.jneumeth.2012.08.009`. PMID: `22981419`.
 Open access PMC: `https://pmc.ncbi.nlm.nih.gov/articles/PMC3491120/`.

---

## 1. What this repository is

nSTAT is the reference MATLAB implementation of the point-process / state-space
framework for spike-train analysis. Core capabilities:

- **PP-GLM fitting** (Poisson or Bernoulli/binomial link) with stimulus,
 spike-history, and ensemble-history covariates; AIC/BIC and **time-rescaling
 KS** goodness-of-fit.
- **PPAF** — Point-Process Adaptive Filter (Eden, Frank, Barbieri, Solo & Brown
 2004): the spike-train Kalman filter, one-step Laplace approximation.
- **PPHF** — Point-Process Hybrid Filter (Srinivasan, Eden, Mitter & Brown 2007):
 joint discrete + continuous state.
- **SSGLM** — State-Space GLM (Czanner et al. 2008): trial-drifting GLM
 coefficients via EM.
- **PPLFP** — multimodal spike + LFP sensor-fusion filter (Cajigas 2013,
 unpublished derivation). Canonical implementation: `nstat.decoding.PPLFP`
 (as of v1.4 / Phase 3, 2026-05). The historical `mPPCO_*` static methods
 on `DecodingAlgorithms` are deprecation shims forwarding to the package
 class; new code should use the package directly.
- Continuous (Gaussian) signal handling via `SignalObj` (Kalman filter,
 smoother) for LFP/EEG-like data.

For the foundational math, see the original sources: Brown, Barbieri, Ventura,
Kass & Frank 2002 (time-rescaling theorem); Eden, Frank, Barbieri, Solo &
Brown 2004 (PPAF as one-step Newton on the variational free energy);
Srinivasan, Eden, Mitter & Brown 2007 (PPHF); Czanner et al. 2008 (SSGLM);
and the 2012 nSTAT paper itself for the canonical toolbox treatment.

**Status (2026):** maintenance mode. A 67-fix audit completed 2026-03-10
(`AUDIT_REPORT.md`). Active development of the algorithms has moved to the
Python port: `https://github.com/cajigaslab/nSTAT-python`. The MATLAB tree
remains authoritative for reproducing the 2012 paper examples.

**License:** GPL v2 (`LICENSE`, `license.txt`).

---

## 2. Requirements

- **MATLAB R2026a** (currently targeted by the install script and parity tests).
 Should run on R2020a+ but Simulink models predate that.
- **No required toolboxes beyond core MATLAB and Statistics**, *but*:
 - `CIF` uses the **Symbolic Math Toolbox** to build derivative functions.
 For uses where this dependency is undesirable, `LinearCIF` (v1.4+) is a
 drop-in canonical-link replacement with closed-form gradient/Hessian
 that does not require Symbolic.
 - Several plotting paths used the (removed) `spectrum.periodogram` /
 `dspdata.psd` from old Signal Processing Toolbox — those methods on
 `SignalObj` will crash on R2014a+; avoid `SignalObj.periodogram` and
 `SignalObj.MTMspectrum` until fixed.
- **Optional `nearestSPD`** helper from MATLAB File Exchange is called by
 decoding/EM routines to regularize Fisher-information matrices.
- **Git LFS** is required to pull the numeric baseline fixture
 (`fixtures/baseline_numeric/nSTATPaperExamples_numeric_baseline.mat`).

---

## 3. One-time setup

```matlab
cd /path/to/nstat
nSTAT_Install % adds runtime dirs to path
% Or non-interactive (also downloads ~paper data from figshare):
nSTAT_Install('RebuildDocSearch', true,...
 'CleanUserPathPrefs', true,...
 'DownloadExampleData', true);
addpath(fullfile(pwd, 'tools')); % for run_all_checks, etc.
```

`nSTAT_Install.m` does three things: (1) adds the runtime directories to the
MATLAB path while excluding `python/`, `.git/`, `tests/python_port_fidelity/`,
etc.; (2) optionally rebuilds the help search database via
`builddocsearchdb('helpfiles')`; (3) optionally downloads the 2012 paper
example dataset from figshare DOI `10.6084/m9.figshare.4834640.v3` into
`data/`.

Paper-example data is NOT in Git — must be downloaded once.

---

## 4. The core object model (read this first)

nSTAT uses an OO design where experiment-level data is composed from primitives.
**All major classes are `handle` classes** — `obj2 = obj1` aliases, not copies.
Use `copySignal` / `nstCopy` to get a deep copy.

```
 +---------------------+
 | Trial | (top-level container)
 +---------------------+
 | | |
 +----------+ +----+ +---+----------+
 | | | |
 +-----------------+ +---------+ +--------+ +-----------+
 | nstColl | | CovColl | | Events | | History |
 | (spike trains) | |(covars) | | (marks)| | (basis) |
 +-----------------+ +---------+ +--------+ +-----------+
 | |
 +-----------------+ +-----------+
 | nspikeTrain | | Covariate | (extends SignalObj)
 +-----------------+ +-----------+
 |
 +---------+
 |SignalObj| (raw time-indexed signal base class)
 +---------+
```

### Class quick reference

| Class | Role | Key file | Notes |
|---|---|---|---|
| `SignalObj` | Time-indexed multivariate signal | `SignalObj.m` (2375 LOC) | Base class. Arithmetic ops, resampling, plotting, spectra. |
| `Covariate` | Named multivariate signal used as GLM regressor | `Covariate.m` | Extends `SignalObj`. |
| `CovColl` | Collection of `Covariate`s | `CovColl.m` (976 LOC) | Mask-based subsetting. |
| `ConfidenceInterval` | CI ribbon attached to a signal | `ConfidenceInterval.m` | Extends `SignalObj`. |
| `nspikeTrain` | Single spike train (point process) | `nspikeTrain.m` (1043 LOC) | Carries `sigRep` SignalObj at chosen `binwidth`. Default binwidth = 1 ms. |
| `nstColl` | Collection of `nspikeTrain`s | `nstColl.m` (1613 LOC) | Neuron mask. Indexed via `getNST(i)`. |
| `Events` | Labeled experimental marks (trial onsets, stim times) | `Events.m` | |
| `History` | Spike-history basis (windows over past spikes) | `History.m` | Used by `Trial` for self- and ensemble-history. |
| `Trial` | Full experiment: spikes + covariates + events + history | `Trial.m` (1061 LOC) | Has `trainingWindow` / `validationWindow`. `Trial.setConfig(...)` MUTATES in place — there is no rollback. |
| `TrialConfig` | One named model configuration (which covariates, which history) | `TrialConfig.m` | |
| `ConfigColl` | Collection of `TrialConfig`s for model comparison | `ConfigColl.m` | |
| `CIF` | Conditional intensity function — symbolic + compiled | `CIF.m` (1120 LOC) | `fitType ∈ {'poisson','binomial'}`. Stores 12 derivative property pairs (∇, ∇², w.r.t. stimulus and history coefficients). |
| `Analysis` | GLM fitting engine (static methods) | `Analysis.m` (1822 LOC) | Entry points: `RunAnalysisForNeuron`, `RunAnalysisForAllNeurons`. Algorithms: `'GLM'` (MATLAB native) or `'BNLRCG'` (faster L2 logistic). |
| `FitResult` | Single fitted model + diagnostics | `FitResult.m` (1843 LOC) | KSPlot, residuals, CIs. |
| `FitResSummary` | Cross-neuron / cross-config summary | `FitResSummary.m` (1362 LOC) | |
| `LinearCIF` | Canonical-link CIF with closed-form derivatives | `LinearCIF.m` | Drop-in for `CIF` when the Symbolic Math Toolbox is undesirable. Added v1.4 (Phase 3.5). |
| `DecodingAlgorithms` | Legacy filter facade (static methods) | `DecodingAlgorithms.m` (1189 LOC after Phase 3) | **Thin facade**: ~47 deprecation shims + 5 helpers + 9 mPPCO→PPLFP shims, all forwarding to the `+nstat/+decoding/` package classes (`PPAF`, `PPHF`, `PPLFP`, `SSGLM`, `KalmanFilter`, `UKF`, `KF_EM`, `PointProcessEM`). New code should use `nstat.decoding.<Cluster>` directly. See §9.1. |

---

## 5. The minimal "Hello, nSTAT" workflow

There is **no canonical hello-world tutorial in the repo**. The minimal path
from spike times to a fitted GLM with goodness-of-fit:

```matlab
% --- 1. Wrap raw spike times as an nspikeTrain --------------------------------
spikeTimes = [0.012 0.034 0.071 0.105...]; % seconds
nst = nspikeTrain(spikeTimes, 'unit1', 0.001); % 1 ms binwidth
nst.setMaxTime(10); % observation window [0,10] s

% --- 2. Build the collection (even for a single neuron) -----------------------
spikeColl = nstColl(nst);

% --- 3. Build covariates (must share a time vector matching binwidth) ---------
t = (0:0.001:10)';
baseline = Covariate(t, ones(size(t)), 'Baseline', 'time', 's', '', {'const'});
stim = Covariate(t, stim_signal, 'Stimulus', 'time', 's', 'mm', {'x'});
covarColl = CovColl({baseline, stim});

% --- 4. Optional spike-history basis ------------------------------------------
windowTimes = [0 0.002 0.004 0.008 0.016 0.032]; % seconds, log-ish
hist = History(windowTimes);

% --- 5. Assemble the Trial ----------------------------------------------------
trial = Trial(spikeColl, covarColl, [], hist);
trial.setTrialPartition([0 8 10]); % 0-8s train, 8-10s validate

% --- 6. Define one or more model configurations -------------------------------
cfg1 = TrialConfig({'Baseline','Stimulus'}, 1000, hist); % 1000 Hz sampleRate
configColl = ConfigColl(cfg1);

% --- 7. Fit -------------------------------------------------------------------
fitResults = Analysis.RunAnalysisForNeuron(trial, 1, configColl,...
 1,... % makePlot
 'GLM',...
 1); % DTCorrection
% Returns a FitResult (or cell of FitResults).

% --- 8. Diagnostics -----------------------------------------------------------
fitResults.KSPlot; % time-rescaling KS plot
fitResults.plotResults; % residuals + coeffs
```

Common pitfalls when authoring an example:

- `binwidth` of `nspikeTrain` and `Δt` of `Covariate.time` **must match** or you
 get a sampleRate-consistency error from `Trial`.
- `Trial(...)` requires a `Baseline` covariate (constant column) to fit an
 intercept — there is no implicit intercept.
- `setTrialPartition` accepts 3 (`[trainStart, splitTime, valEnd]`) or 4
 (`[trainStart, trainEnd, valStart, valEnd]`) elements.
- `DTCorrection=1` enables the `Δ`-correction in the KS plot. Use it.

---

## 6. Reproducing the paper

```matlab
% Regenerate every paper-example figure into docs/figures/<example_id>/
cd /path/to/nstat
addpath(genpath(pwd));
build_paper_examples;
```

Or run one example:

```matlab
example01_mepsc_poisson('ExportFigures', true,...
 'ExportDir', fullfile(pwd,'docs','figures','example01'));
```

| Example | Question | Script | Paper section |
|---|---|---|---|
| 01 | Is mEPSC firing constant or piecewise Poisson under Mg²⁺ washout? | `examples/paper/example01_mepsc_poisson.m` | 2.3.1 |
| 02 | Does adding stimulus / spike-history improve a thalamic GLM? | `example02_whisker_stimulus_thalamus.m` | 2.3.2 |
| 03 | PSTH vs SSGLM for within- and across-trial dynamics | `example03_psth_and_ssglm.m` | 2.3.3-2.3.4 |
| 04 | Gaussian vs Zernike basis for hippocampal place cells | `example04_place_cells_continuous_stimulus.m` | 2.3.5 |
| 05 | PPAF vs PPHF decoding (univariate stimulus, reach state) | `example05_decoding_ppaf_pphf.m` | 2.4 |

All accept `'ExportFigures'`, `'ExportDir'`, `'Resolution'`, `'WidthPx'`,
`'HeightPx'`, `'Visible'`, `'Seed'` (default 0). They `cd` to the repo root and
restore on cleanup. Data paths come from `getPaperDataDirs`.

---

## 7. Running tests and parity checks

```matlab
% From the repo root, with tools/ on the path:
run_all_checks('GenerateBaseline', false,...
 'CheckParity', true,...
 'RunTests', true,...
 'PublishDocs', false,...
 'Style', 'legacy');
```

What lives in `tests/`:

- `tests/unit/` — 20 unit tests added during Phase 0–4 modernization (v1.4).
 Each targets a specific bug or contract: `testFitResultLogLikelihood.m`
 (Bernoulli LL wrap), `testKsUnclamped.m` (KS U-clamp removal),
 `testComputeKSStatsDTBranch.m` (DT-branch reachability),
 `testDTRegimeWarning.m`, `testKsdiscreteDeterminism.m` (seed-respect),
 `testHistoryRaisedCosine.m`, `testLinearCIF.m`, `testComputeGainMatrix.m`
 (Woodbury extraction), `testNstatDecoding{KalmanFilter,UKF,PPAF,PPHF,
 PPLFP,SSGLM,KF_EM,PointProcessEM}.m` (cluster-class numerical parity vs
 the legacy facade), `testPPDecodeUpdateIterated.m` (Phase 4.1 iterated
 Laplace), `testMPPCODeprecationShims.m`, `testAnalysisGLMFitLogLikelihood.m`,
 `testSignalObjSpectralModernization.m`.
- `tests/integration/testKsAgainstReferenceZoo.m` — KS oracle pass-rate
 validation against the reference (~2–4 min).
- `tests/TestParityAgainstBaseline.m` — older integration test: regenerates
 paper examples and diffs numeric outputs + plot structure against
 `fixtures/baseline_numeric/`. **Skips silently if the LFS pointer hasn't
 been resolved** (`git lfs pull`).
- `tests/TestPlotStyleApi.m` — `nstat.setPlotStyle('legacy'|'modern')` round-trip.
- `tests/TestFixtures.m`, `test_eval_removal.m`, `test_histc_migration.m`,
 `test_warning_exist_fixes.m` — small unit regressions tied to specific audit
 fixes from the 2026-03-10 67-bug audit.
- `tests/python_port_fidelity/` — cross-language fixtures for the Python port.

The local test gate (CI does not run MATLAB):

```bash
tools/run_unit_tests.sh # 20 unit tests, ~30s
tools/run_unit_tests.sh --integration # + KS oracle integration, ~3 min
```

If you change `DecodingAlgorithms.m`, `Analysis.m`, `FitResult.m`, or
`CIF.m`, also run README figure parity (see below) — figures encode
bug-fixed math invisibly to text diffs.

Skip parity in CI when needed: `setenv('NSTAT_SKIP_PARITY_TESTS','1')`.

### README figure parity

The `docs/figures/exampleNN/*.png` files are the README's rendered gallery
(produced by `build_paper_examples`). Touching `examples/paper/*`, core
fitting/decoding classes, or the plotting helpers can change these PNGs —
which is invisible to text diffs and to the unit-test suite. Run
`tools/check_readme_figures.sh` before pushing changes in those areas. Full
policy and triage rubric in [CONTRIBUTING.md](CONTRIBUTING.md) → "README
figure parity".

---

## 8. Help / docs surface

- **Intro page at [cajigaslab.github.io/nSTAT](https://cajigaslab.github.io/nSTAT/)** —
 the public landing. Hero + install + 5-minute tour + paper-example gallery +
 v1.4 highlights. Source: `docs/index.md` (Sphinx + MyST + sphinx-rtd-theme).
 Auto-deploys on push to `master` via `.github/workflows/docs.yml`. Helpfiles
 HTML is served alongside (via `html_extra_path` in `docs/conf.py`).
- **`Contents.m`** — `help nSTAT` entry point.
- **`helpfiles/`** — 348 entries: `.m` (publish source) + `.mlx` (live notebook)
 + `.html` (published output) + `.png` (thumbnails) per class/example.
 - Browse via `doc nSTAT` once the help index is built.
 - **Concept-level pages do not exist** for `CIF`, time-rescaling, GLM vs
 SSGLM. You must read the paper.
- **`helpfiles/PaperOverview.m`** — class hierarchy and paper-mapping summary
 (good starting page).
- **`helpfiles/nSTATPaperExamples.m` / `.mlx`** — consolidated reproduction of
 all paper analyses (2.5 MB MLX, contains embedded outputs).
- **`docs/paper_examples.md`** — figure gallery and example index in markdown.
- **`docs/DEVPLAN.md`** — internal modernization plan; not user-facing.
- **`README.md`** — current. `README.txt` is **stale** (references the old SVN
 repo); ignore it.
- **GitHub Pages mirror**: `https://cajigaslab.github.io/nSTAT/`.

To open a help page from MATLAB code: `nstatOpenHelpPage('AnalysisExamples.html')`.

---

## 9. Gotchas, sharp edges, and known issues

Read these before editing anything in those files.

### 9.1 `DecodingAlgorithms.m` is now a 1189-line facade (post Phase 3, v1.4)

Historical: this file was a 10860-line single classdef with 48 static
methods, 4-way duplicated Woodbury update steps, scattered magic-number
tolerances, and EM-interleaved diagnostic plotting.

Current (v1.4, May 2026): a thin facade with ~47 deprecation shims +
5 helpers + 9 mPPCO→PPLFP shims, all forwarding to per-algorithm classes
in `+nstat/+decoding/`:

- `nstat.decoding.PPAF` — Point-process adaptive filter
- `nstat.decoding.PPHF` — Point-process hybrid filter
- `nstat.decoding.PPLFP` — Spike + LFP sensor fusion (was `mPPCO_*`)
- `nstat.decoding.SSGLM` — State-space GLM
- `nstat.decoding.KalmanFilter`, `nstat.decoding.UKF`
- `nstat.decoding.KF_EM`, `nstat.decoding.PointProcessEM`

The Woodbury update is centralized in `+nstat/+decoding/+internal/computeGainMatrix.m`.
Tolerances and constants are in `+nstat/Defaults.m`.

New code should call `nstat.decoding.<Cluster>` methods directly. The
shims on `DecodingAlgorithms` emit `nSTAT:deprecated:DecodingAlgorithms`
warnings (warning-only; do not fail) and are retained for backwards
compatibility with users of the v1.3 API.

### 9.2 Handle-class aliasing

`SignalObj`, `Trial`, `nspikeTrain`, `nstColl`, `CIF` are all `handle`. Assignment is aliasing. To copy:

- `SignalObj` / `Covariate` / `ConfidenceInterval` → `obj.copySignal`
- `nspikeTrain` → `nst.nstCopy`
- `Trial` → `trial.restoreToOriginal` reverts mutations; there is no
 `Trial.copy` — assume `Analysis.RunAnalysisForNeuron` mutates the trial.

### 9.3 The 67-fix audit (`AUDIT_REPORT.md`, tags `% FIX:`)

Recent bug class fixes that you should not re-introduce:

| File | Bug | Symptom |
|---|---|---|
| `FitResult.m:371` | `delta = sampleRate` | KS test wrong for any sampleRate ≠ 1 |
| `DecodingAlgorithms.m` (×3) | `isa(x,'nan')` always false | Singular matrices passed unchecked in PPAF/PPHF |
| `DecodingAlgorithms.m` (×4) | `ld.^2` instead of `ld.^3` | Third Poisson moment computed as variance |
| `CIF.m` (×16) | `symvar(varIn)` reorders alphabetically | Silent argument mismatch in compiled function handles |
| `SignalObj.m` | `sOBj` typo, `findPeaks('minima')` returns maxima, handle aliasing in `times/rdivide/ldivide` | Silent wrong results |
| `nspikeTrain.m` | Burst detection off-by-one + wrong append order | Wrong burst boundaries |

`grep -rn "% FIX:" *.m` lists all 67 sites.

### 9.4 Things still broken (audit acknowledged, not fixed)

- `SignalObj.periodogram`, `SignalObj.MTMspectrum` use APIs removed from MATLAB R2014a (`spectrum.periodogram`, `dspdata.psd`). **They will crash on any modern MATLAB.** Avoid.
- `nspikeTrain.computeStatistics` uses `histc` + `bar(...,'histc')` which throw deprecation warnings on R2014b+.
- `CIF` simulation uses `assignin('base',...)` to pass variables into Simulink — fragile under parfor / non-default workspaces.
- 5 redundant Simulink model versions (`PointProcessSimulation.{mdl.r2010b,r2011a,r2011b,r2013a,slx,slx.r2013a}`).

### 9.5 Reproducibility

- All paper-example scripts set `rng(opts.Seed,'twister')` (default Seed=0).
- Parity baselines live in `fixtures/baseline_numeric/` and are tracked via Git
 LFS. Run `git lfs pull` after clone.
- Plot style toggle: `nstat.setPlotStyle('modern')` (default) or `'legacy'`
 (strict reproduction of 2012 figure style).
- **Example 03 has known non-deterministic figures.** SSGLM EM iterations
 exercise multi-threaded BLAS reductions whose accumulation order is not
 reproducible between MATLAB process invocations. Three figures drift between
 same-code same-seed runs (`example03/fig03_ssglm_simulation_summary.png`,
 `fig05_stimulus_effect_surfaces.png`, `fig06_learning_trial_comparison.png`)
 by mean |Δ| ≈ 2–7 in [0,255] space. They are allowlisted in
 `tools/check_readme_figures.m` so the drift detector treats them as
 informational.

---

## 10. Tools directory (`tools/`)

- `build_paper_examples.m` — regenerates all paper figures into `docs/figures/`.
- `check_readme_figures.m` / `check_readme_figures.sh` — README gallery drift
 detector. Regenerates + pixel-diffs; errors on unexplained `SUBSTANTIVE`
 drift; allowlists Example 03's BLAS-noise figures.
- `check_parity_against_baseline.m` — numeric + plot-structure parity check;
 optionally checks pixel diffs.
- `generate_baseline_fixtures.m` — write new baselines (only when intentionally
 resetting parity).
- `publish_examples.m` — publish `.m` examples to HTML.
- `run_all_checks.m` — top-level orchestrator.
- `+nstat/setPlotStyle.m` — plot style namespace (use `nstat.setPlotStyle`).
- `matlab/`, `python/` — language-specific helpers (Python helpers exist for the
 port-fidelity tests).

---

## 11. When NOT to use the MATLAB version

- You want active development on new algorithms → use `cajigaslab/nSTAT-python`.
- You want fast autodiff / GPU → use Python with JAX or PyTorch; nSTAT's CIF
 derivatives are symbolic and slow.
- You need to integrate with `neo`, `elephant`, `nwb-matnwb`, or modern
 neuroscience data loaders → the MATLAB toolbox has no native NWB or NEO
 bridges.
- You need rigorous unit tests → not present in this repo. Add your own.

---

## 11.5 Simulink models (legacy, kept for archival reference)

Three Simulink models live in the repo root, with multiple R-version variants.
A walk via `tools/inspect_simulink_models.m` exported every subsystem level
to `docs/figures/simulink/`.

- `PointProcessSimulation.slx` and `PointProcessSimulationCont.slx` are
 **byte-identical at every subsystem level** (sha256 confirmed across all 24
 exported PNGs). The "Cont" suffix is no longer meaningful — one of them
 should be deleted.
- `PointProcessSimulationThinning.mdl` is genuinely different: it adds
 `Detect Change`, `Difference`, `Sample and Hold` (×2), `Discrete-Time
 Integrator`, and a `Clock` to implement the time-rescaling simulation method
 (Brown 2002 §3.1; curriculum §4.A.3) — events drawn from a unit-rate Poisson
 on the compensator axis, mapped back to wall-clock by inverting Λ.
- The level-01 block diagram of `PointProcessSimulation.slx` is the cleanest
 visual statement of the PP-GLM in the repo. Steal it for documentation.
- For production simulation, prefer `CIF.simulateCIFByThinning` (pure MATLAB;
 no Simulink license required). The Simulink models are a pedagogical
 artifact, not a runtime dependency.

## 12. Cheatsheet for an agent doing a code task

| You want to | Look here |
|---|---|
| Add a new GLM regressor | Build a `Covariate`, add to `CovColl`, list its name in `TrialConfig`. |
| Add a new history basis | Construct `History(windowTimes)` and pass to `Trial` or `TrialConfig`. |
| Fit a Poisson vs Bernoulli GLM | Set `fitType` when constructing the `CIF`; `Analysis.GLMFit` picks via `distrib`. |
| Change decoding algorithm | `DecodingAlgorithms.PPDecodeFilter` (general CIF) vs `PPDecodeFilterLinear` (linear CIF). |
| Add a new EM variant | Look at `PPSS_EM` for the canonical EStep/MStep pattern. Expect to copy ~150 lines of boilerplate; this is a known wart. |
| Add a hybrid (discrete+continuous) state | `PPHybridFilter` / `PPHybridFilterLinear`. |
| Add a unit test | `tests/`. Follow `matlab.unittest.TestCase`. Use a closed-form expected output — do NOT rely on parity baselines for math correctness. |
| Change figure style | `nstat.setPlotStyle('modern'|'legacy')`. |
| Regenerate paper figures | `build_paper_examples` (all) or `exampleNN_*('ExportFigures',true,...)` (one). |
| Find a method on a class | `methods('ClassName')` then `help ClassName.methodName`. |
| Get to the doc page | `nstatOpenHelpPage('AnalysisExamples.html')` from MATLAB; or open `helpfiles/<name>.html` directly. |

---

## 13. Citation

If you use nSTAT in published work:

```bibtex
@article{cajigas2012nstat,
 author = {Cajigas, I. and Malik, W. Q. and Brown, E. N.},
 title = {{nSTAT}: Open-source neural spike train analysis toolbox for {Matlab}},
 journal = {Journal of Neuroscience Methods},
 volume = {211},
 number = {2},
 pages = {245--264},
 year = {2012},
 doi = {10.1016/j.jneumeth.2012.08.009},
 pmid = {22981419}
}
```

See `CITATION.cff` for machine-readable form.
