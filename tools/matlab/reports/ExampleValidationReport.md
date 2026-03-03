# Example Validation Report

- Pre-change run timestamp: `2026-03-02T22:06:37-05:00`
- Post-change run timestamp: `2026-03-02T22:49:49-05:00`
- Pre result: **28/28 pass**
- Post result: **28/28 pass**

## Per-example Status

| Example Script | Pre | Post | Notes |
|---|---|---|---|
| `AnalysisExamples.m` | PASS | PASS | none |
| `AnalysisExamples2.m` | PASS | PASS | none |
| `ConfigCollExamples.m` | PASS | PASS | none |
| `CovCollExamples.m` | PASS | PASS | none |
| `CovariateExamples.m` | PASS | PASS | none |
| `DecodingExample.m` | PASS | PASS | warning removed: `MATLAB:legend:IgnoringExtraEntries` |
| `DecodingExampleWithHist.m` | PASS | PASS | warning removed: `MATLAB:legend:IgnoringExtraEntries` |
| `EventsExamples.m` | PASS | PASS | none |
| `Examples.m` | PASS | PASS | none |
| `ExplicitStimulusWhiskerData.m` | PASS | PASS | none |
| `FitResSummaryExamples.m` | PASS | PASS | none |
| `FitResultExamples.m` | PASS | PASS | none |
| `HippocampalPlaceCellExample.m` | PASS | PASS | none |
| `HistoryExamples.m` | PASS | PASS | none |
| `HybridFilterExample.m` | PASS | PASS | none |
| `NetworkTutorial.m` | PASS | PASS | none |
| `PPSimExample.m` | PASS | PASS | none |
| `PPThinning.m` | PASS | PASS | none |
| `PSTHEstimation.m` | PASS | PASS | none |
| `SignalObjExamples.m` | PASS | PASS | none |
| `StimulusDecode2D.m` | PASS | PASS | none |
| `TrialConfigExamples.m` | PASS | PASS | none |
| `TrialExamples.m` | PASS | PASS | none |
| `ValidationDataSet.m` | PASS | PASS | none |
| `mEPSCAnalysis.m` | PASS | PASS | none |
| `nSTATPaperExamples.m` | PASS | PASS | none |
| `nSpikeTrainExamples.m` | PASS | PASS | none |
| `nstCollExamples.m` | PASS | PASS | none |

## Warning Delta

- `DecodingExample.m`: pre `MATLAB:legend:IgnoringExtraEntries` -> post ``
- `DecodingExampleWithHist.m`: pre `MATLAB:legend:IgnoringExtraEntries` -> post ``

## Numeric Signature Comparison

- Comparison method: variable-level MD5 of numeric/logical arrays captured after each script run.
- `DecodingExampleWithHist.m`: signature mismatch (likely nondeterministic numerics in this workflow).
- `NetworkTutorial.m`: signature mismatch (likely nondeterministic numerics in this workflow).
- `ValidationDataSet.m`: signature mismatch (likely nondeterministic numerics in this workflow).
- `nSTATPaperExamples.m`: signature mismatch (likely nondeterministic numerics in this workflow).
- Total scripts with signature mismatch: **4**.

## Notes

- Runs were executed from a staged helpfile copy without `.mlx` files to avoid MATLAB 2025b `.mlx` shadowing of same-name `.m` scripts.
- This preserves source behavior while allowing direct execution of `.m` example scripts for validation.
