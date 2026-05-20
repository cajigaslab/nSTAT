# Script Inventory — Deep-Dive Verification

> **Generated:** 2026-05-20 against master HEAD `4303305`.
> **Source plan:** [`docs/superpowers/plans/2026-05-20-deep-dive-verification.md`](../superpowers/plans/2026-05-20-deep-dive-verification.md).
> **Total in scope:** 43 scripts (38 helpfiles + 5 paper examples). Of these, **27 are runnable demos**; the rest are documentation, setup, or navigation files (categorized below).

## Categorization

### Category 1 — Paper examples (5 scripts; canonical reproductions)

| Script | Paper section | Tier |
|---|---|---|
| `examples/paper/example01_mepsc_poisson.m` | 2.3.1 | A (already verified) |
| `examples/paper/example02_whisker_stimulus_thalamus.m` | 2.3.2 | A (already verified) |
| `examples/paper/example03_psth_and_ssglm.m` | 2.3.3 | A (already verified; glmfit:IterationLimit) |
| `examples/paper/example04_place_cells_continuous_stimulus.m` | 2.3.4 | A (already verified) |
| `examples/paper/example05_decoding_ppaf_pphf.m` | 2.4 | A (already verified) |

### Category 2 — New tutorials (3 scripts; added in PR #36)

| Script | Purpose | Tier |
|---|---|---|
| `helpfiles/HelloNstat.m` | Minimal onboarding workflow | A (already verified) |
| `helpfiles/FoundationModelKSValidation.m` | KS validation pipeline demo | A (already verified) |
| `helpfiles/WhenToUseWhich.m` | Documentation-only decision tree | docs-only (no exec) |

### Category 3 — Class-specific demonstration scripts (15 scripts; Tier B)

These are the "Tier B" unrun helpfiles — class-level demos that haven't been routinely verified since the Feb 2026 audit.

| Script | Class demonstrated | Data dep |
|---|---|---|
| `helpfiles/AnalysisExamples.m` | `Analysis` | synthetic |
| `helpfiles/AnalysisExamples2.m` | `Analysis` (deeper) | synthetic / figshare? |
| `helpfiles/ConfigCollExamples.m` | `ConfigColl` | synthetic |
| `helpfiles/CovCollExamples.m` | `CovColl` | synthetic |
| `helpfiles/CovariateExamples.m` | `Covariate` | synthetic |
| `helpfiles/EventsExamples.m` | `Events` | synthetic |
| `helpfiles/FitResSummaryExamples.m` | `FitResSummary` | synthetic |
| `helpfiles/FitResultExamples.m` | `FitResult` | synthetic |
| `helpfiles/HistoryExamples.m` | `History` | synthetic |
| `helpfiles/PPThinning.m` | `CIF.simulateCIFByThinning` | synthetic |
| `helpfiles/SignalObjExamples.m` | `SignalObj` | synthetic |
| `helpfiles/TrialConfigExamples.m` | `TrialConfig` | synthetic |
| `helpfiles/TrialExamples.m` | `Trial` | synthetic |
| `helpfiles/ValidationDataSet.m` | training/validation API | synthetic |
| `helpfiles/nSpikeTrainExamples.m` | `nspikeTrain` | synthetic |
| `helpfiles/nstCollExamples.m` | `nstColl` | synthetic |

### Category 4 — Paper-aligned tutorial scripts (7 scripts; Tier B+)

Larger tutorials that reproduce parts of the 2012 paper or curriculum chapter 4.

| Script | Purpose | Data dep |
|---|---|---|
| `helpfiles/DecodingExample.m` | PPAF stimulus decoding | synthetic | (Tier A, migrated, verified) |
| `helpfiles/DecodingExampleWithHist.m` | PPAF with history | synthetic | (Tier A, migrated, verified) |
| `helpfiles/ExplicitStimulusWhiskerData.m` | Mirrors paper §2.3.2 | figshare |
| `helpfiles/HippocampalPlaceCellExample.m` | Mirrors paper §2.3.4 | figshare |
| `helpfiles/HybridFilterExample.m` | PPHF tutorial | synthetic | (Tier A, migrated, verified) |
| `helpfiles/NetworkTutorial.m` | Multi-neuron ensemble | synthetic |
| `helpfiles/PPSimExample.m` | CIF point-process simulation | synthetic |
| `helpfiles/PSTHEstimation.m` | PSTH via GLM | synthetic |
| `helpfiles/StimulusDecode2D.m` | 2D stim decoding | synthetic | (Tier A, migrated, verified) |
| `helpfiles/mEPSCAnalysis.m` | Mirrors paper §2.3.1 | figshare |
| `helpfiles/nSTATPaperExamples.m` | All paper examples in one file | figshare |

### Category 5 — Documentation / navigation / setup (8 scripts; not runnable demos)

These do not execute analysis code; they're navigation pages, setup scripts, or stubs. Excluded from V1 runtime verification.

| Script | Type |
|---|---|
| `helpfiles/ClassDefinitions.m` | nav page |
| `helpfiles/ConfidenceIntervalOverview.m` | doc stub (Phase 1 audit) |
| `helpfiles/DocumentationSetup2025b.m` | setup script |
| `helpfiles/Examples.m` | nav page |
| `helpfiles/FitResultReference.m` | doc stub (Phase 1 audit) |
| `helpfiles/NeuralSpikeAnalysis_top.m` | top-level nav page |
| `helpfiles/PaperOverview.m` | nav page (paper-to-code map) |
| `helpfiles/publish_all_helpfiles.m` | publishing utility |
| `helpfiles/WhenToUseWhich.m` | decision-tree doc (PR #36) |

## V1.4 scope (Tier B — first verification pass)

The 23 scripts in categories 3 + 4 (excluding the 4 already-verified Tier-A migrated helpfiles) are the unknown — never routinely re-verified after Phase 0-4 modernization.

Of these:
- **16 use only synthetic data** — safe to run on any clean clone.
- **6 require figshare data** — must verify `data/` is populated first.
- **1 large meta-script** (`nSTATPaperExamples.m`, 88 KB) — likely runs all 5 paper analyses; expect ~5-10 min runtime.

## Status legend (for the run report)

- ✅ PASS — runs to completion, no `nSTAT:deprecated:*` warnings.
- ⚠️ PASS-W — runs to completion but emits at least one `nSTAT:deprecated:*` warning (indicates incomplete Phase 3.5b migration).
- ❌ FAIL — runs to completion but produces NaN/Inf in expected-numeric output, OR errors out.
- 🚧 QUARANTINE — fails for reasons out-of-scope (e.g., requires removed MATLAB API; deprecated CSV format).
