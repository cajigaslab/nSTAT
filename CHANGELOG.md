# CHANGELOG

## 2026-03-02 - MATLAB Maintenance Pass (Behavior-Preserving)

### Bug Fixes
- `DecodingAlgorithms.m`
  - Replaced removed `matlabpool('size')` calls with release-compatible pool-size lookup via `DecodingAlgorithms.getPoolSizeCompat()`.
  - Affected call sites are in EM/decoder branches where parallel-worker count is queried.
  - Intent preserved: serial path remains selected when no active pool is available.
- `helpfiles/DecodingExample.m`
  - Fixed legend handle/label mismatch that produced `MATLAB:legend:IgnoringExtraEntries` warning.
- `helpfiles/DecodingExampleWithHist.m`
  - Fixed legend handle/label mismatch in both subplots (same warning class as above).

### Documentation Additions
Expanded top-level MATLAB help headers for public classes with purpose, key methods/properties, assumptions, and usage notes:
- `Analysis.m`
- `CIF.m`
- `ConfidenceInterval.m`
- `ConfigColl.m`
- `CovColl.m`
- `Covariate.m`
- `DecodingAlgorithms.m`
- `Events.m`
- `FitResSummary.m`
- `FitResult.m`
- `History.m`
- `SignalObj.m`
- `Trial.m`
- `TrialConfig.m`
- `nspikeTrain.m`
- `nstColl.m`

### Robustness / Error Messages
- `nstatOpenHelpPage.m`
  - Added input type validation for `pageName` and `openBrowser`.
  - Added scalar-string support for `pageName`.
  - Added `.html` suffix fallback when a page name is passed without extension.
  - Kept existing valid call patterns behaviorally compatible.

### Known Remaining Issues (Not Changed)
- Direct execution of `helpfiles/*.m` from the in-place tree can be blocked in MATLAB 2025b when same-name `.mlx` files are present (Live Script shadowing behavior).
  - Validation is performed from a staged copy without `.mlx` files to preserve source script execution.
- `helpfiles/StimulusDecode2D.m` can emit `StimulusDecode2D:SymbolicDecodeFallback` and intentionally fall back to `PPDecodeFilterLinear`.
  - Existing behavior retained.
- `helpfiles/nSTATPaperExamples.m` may emit `stats:glmfit:IterationLimit` on some runs/data subsets.
  - Existing behavior retained to avoid semantic drift in model-fitting settings.
