# Figure Gallery — Deep-Dive Verification V3

> **Generated:** 2026-05-20 from `tools/verify_all_examples.m` outputs.
> **Source plan:** Phase V3 of [`docs/superpowers/plans/2026-05-20-deep-dive-verification.md`](../superpowers/plans/2026-05-20-deep-dive-verification.md).
> **Status:** ready for manual inspection.

Each figure below is inlined for visual review. The per-figure inspection checklist has 4 questions:
- Title accurate? (matches what the script is computing)
- Axes labeled? (with units where applicable)
- Legend present? (where multiple data series)
- Data series complete? (no obviously missing curves or NaN gaps)

Replace ⬜ with ✅ (pass) or ❌ (fail) during review. Add a one-line note for any ❌.

**Total figures: 157 PNGs across 26 scripts.**

---

# Section 1: Paper examples (canonical reproductions)

## example01
*mEPSC Poisson Models Under Constant and Washout Magnesium*

**Paper mapping:** Section 2.3.1; Figs. 3 and 10 (nSTAT paper, 2012).

Fits constant and piecewise Poisson GLM baselines to mEPSC spike trains and visualizes model diagnostics (KS, inverse-Gaussian transform, lambda).

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/example01/fig01_constant_mg_summary.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/example01/fig02_washout_raster_overview.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/example01/fig03_piecewise_baseline_comparison.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## example02
*Whisker Stimulus GLM With Lag and History Selection*

**Paper mapping:** Section 2.3.2; Figs. 4 and 11 (nSTAT paper, 2012).

Fits explicit-stimulus point-process GLMs, estimates lag from residual xcov, and compares baseline/stimulus/history models via AIC/BIC/KS.

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/example02/fig01_data_overview.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/example02/fig02_lag_and_model_comparison.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## example03
*PSTH and SSGLM Dynamics Example*

**Paper mapping:** Sections 2.3.3-2.3.4; Figs. 5, 6, and 12 (nSTAT paper, 2012).

Generates simulated/real PSTH analyses and SSGLM between-trial dynamics diagnostics using bundled deterministic example data.

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/example03/fig01_simulated_and_real_rasters.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/example03/fig02_psth_comparison.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/example03/fig03_ssglm_simulation_summary.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/example03/fig04_ssglm_fit_diagnostics.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 5 | ![](../figures/example03/fig05_stimulus_effect_surfaces.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 6 | ![](../figures/example03/fig06_learning_trial_comparison.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## example04
*Place-Cell Receptive Fields (Gaussian vs Zernike)*

**Paper mapping:** Section 2.3.5; Figs. 7 and 13 (nSTAT paper, 2012).

Loads place-cell datasets and precomputed fit results, compares Gaussian and Zernike receptive-field models, and visualizes full population maps.

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/example04/fig01_example_cells_path_overlay.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/example04/fig02_model_summary_statistics.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/example04/fig03_gaussian_place_fields_animal1.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/example04/fig04_zernike_place_fields_animal1.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 5 | ![](../figures/example04/fig05_gaussian_place_fields_animal2.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 6 | ![](../figures/example04/fig06_zernike_place_fields_animal2.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 7 | ![](../figures/example04/fig07_example_cell_mesh_comparison.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## example05
*Stimulus Decoding With PPAF and PPHF*

**Paper mapping:** Sections 2.3.6-2.3.7; Figs. 8, 9, 14 plus hybrid extension from canonical example.

Runs univariate and movement decoding examples with point-process adaptive and hybrid filters, including goal-aware comparisons.

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/example05/fig01_univariate_setup.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/example05/fig02_univariate_decoding.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/example05/fig03_reach_and_population_setup.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/example05/fig04_ppaf_goal_vs_free.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 5 | ![](../figures/example05/fig05_hybrid_setup.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 6 | ![](../figures/example05/fig06_hybrid_decoding_summary.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

# Section 2: V1.4 Tier-B helpfiles (captured during verification harness run)

## AnalysisExamples
*Analysis class demonstration (single-neuron fit).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_AnalysisExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_AnalysisExamples/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_AnalysisExamples/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_AnalysisExamples/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## AnalysisExamples2
*Analysis class — multi-neuron / multi-config workflow.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_AnalysisExamples2/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_AnalysisExamples2/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_AnalysisExamples2/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_AnalysisExamples2/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## CovCollExamples
*CovColl class demonstration.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_CovCollExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_CovCollExamples/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## CovariateExamples
*Covariate class demonstration (continuous covariates).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_CovariateExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_CovariateExamples/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## EventsExamples
*Events class demonstration (trial / stim markers).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_EventsExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_EventsExamples/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_EventsExamples/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## ExplicitStimulusWhiskerData
*Paper §2.3.2 reproduction — explicit-stimulus thalamic data.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_ExplicitStimulusWhiskerData/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_ExplicitStimulusWhiskerData/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_ExplicitStimulusWhiskerData/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_ExplicitStimulusWhiskerData/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 5 | ![](../figures/verify_ExplicitStimulusWhiskerData/fig05.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 6 | ![](../figures/verify_ExplicitStimulusWhiskerData/fig06.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 7 | ![](../figures/verify_ExplicitStimulusWhiskerData/fig07.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 8 | ![](../figures/verify_ExplicitStimulusWhiskerData/fig08.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## HelloNstat
*Minimal onboarding workflow: spike times → fitted GLM → KS plot.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_HelloNstat/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## HippocampalPlaceCellExample
*Paper §2.3.4 reproduction — hippocampal place cells.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_HippocampalPlaceCellExample/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_HippocampalPlaceCellExample/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_HippocampalPlaceCellExample/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_HippocampalPlaceCellExample/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 5 | ![](../figures/verify_HippocampalPlaceCellExample/fig05.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 6 | ![](../figures/verify_HippocampalPlaceCellExample/fig06.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 7 | ![](../figures/verify_HippocampalPlaceCellExample/fig07.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 8 | ![](../figures/verify_HippocampalPlaceCellExample/fig08.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 9 | ![](../figures/verify_HippocampalPlaceCellExample/fig09.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## HistoryExamples
*History class demonstration (spike-history basis).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_HistoryExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_HistoryExamples/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_HistoryExamples/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## NetworkTutorial
*Multi-neuron ensemble GLM tutorial.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_NetworkTutorial/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_NetworkTutorial/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_NetworkTutorial/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_NetworkTutorial/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## PPSimExample
*CIF-based point-process simulation tutorial.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_PPSimExample/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_PPSimExample/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_PPSimExample/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## PPThinning
*Point-process simulation via thinning (Lewis-Shedler 1978).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_PPThinning/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_PPThinning/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_PPThinning/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## PSTHEstimation
*PSTH-via-GLM tutorial.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_PSTHEstimation/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_PSTHEstimation/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## SignalObjExamples
*SignalObj class demonstration (signal manipulation).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_SignalObjExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_SignalObjExamples/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_SignalObjExamples/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_SignalObjExamples/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 5 | ![](../figures/verify_SignalObjExamples/fig05.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 6 | ![](../figures/verify_SignalObjExamples/fig06.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 7 | ![](../figures/verify_SignalObjExamples/fig07.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 8 | ![](../figures/verify_SignalObjExamples/fig08.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 9 | ![](../figures/verify_SignalObjExamples/fig09.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 10 | ![](../figures/verify_SignalObjExamples/fig10.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 11 | ![](../figures/verify_SignalObjExamples/fig11.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 12 | ![](../figures/verify_SignalObjExamples/fig12.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 13 | ![](../figures/verify_SignalObjExamples/fig13.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 14 | ![](../figures/verify_SignalObjExamples/fig14.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 15 | ![](../figures/verify_SignalObjExamples/fig15.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 16 | ![](../figures/verify_SignalObjExamples/fig16.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## TrialExamples
*Trial class demonstration (full experiment container).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_TrialExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_TrialExamples/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_TrialExamples/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_TrialExamples/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 5 | ![](../figures/verify_TrialExamples/fig05.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 6 | ![](../figures/verify_TrialExamples/fig06.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## ValidationDataSet
*Training/validation API demonstration.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_ValidationDataSet/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_ValidationDataSet/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_ValidationDataSet/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_ValidationDataSet/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 5 | ![](../figures/verify_ValidationDataSet/fig05.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 6 | ![](../figures/verify_ValidationDataSet/fig06.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 7 | ![](../figures/verify_ValidationDataSet/fig07.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 8 | ![](../figures/verify_ValidationDataSet/fig08.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## mEPSCAnalysis
*Paper §2.3.1 reproduction — mEPSC Poisson analysis.*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_mEPSCAnalysis/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_mEPSCAnalysis/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_mEPSCAnalysis/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_mEPSCAnalysis/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## nSTATPaperExamples
*Meta-script reproducing all 5 paper analyses (stale .mlx shadows .m — see triage report).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_nSTATPaperExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## nSpikeTrainExamples
*nspikeTrain class demonstration (spike-train manipulation, burst stats).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_nSpikeTrainExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_nSpikeTrainExamples/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_nSpikeTrainExamples/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 4 | ![](../figures/verify_nSpikeTrainExamples/fig04.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---

## nstCollExamples
*nstColl class demonstration (multi-neuron collection).*

| # | Figure | Inspection |
|---|---|---|
| 1 | ![](../figures/verify_nstCollExamples/fig01.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 2 | ![](../figures/verify_nstCollExamples/fig02.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |
| 3 | ![](../figures/verify_nstCollExamples/fig03.png) | ⬜ Title accurate? ⬜ Axes labeled? ⬜ Legend present? ⬜ Data series complete? |

---
