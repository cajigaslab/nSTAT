# nSTAT Python Release Notes

## Highlights

- Introduced canonical Pythonic APIs under `nstat`:
  - `nstat.signal.Signal`, `nstat.signal.Covariate`
  - `nstat.spikes.SpikeTrain`, `nstat.spikes.SpikeTrainCollection`
  - `nstat.trial.CovariateCollection`, `nstat.trial.TrialConfig`, `nstat.trial.ConfigCollection`, `nstat.trial.Trial`
  - `nstat.analysis.Analysis`
  - `nstat.fit.FitResult`, `nstat.fit.FitSummary`
  - `nstat.cif.CIFModel`
  - `nstat.decoding.DecoderSuite`
  - `nstat.datasets` dataset registry/checksum API
- Added standalone simulation replacements in `nstat.simulators`.
- Added source-driven notebook generation for all MATLAB help `Examples` topics.
- Added Sphinx docs generation from `helpfiles/helptoc.xml`.
- Added parity/baseline reporting tools:
  - `python/tools/freeze_port_baseline.py`
  - `python/tools/generate_method_parity_matrix.py`
  - `python/tools/verify_python_vs_matlab_similarity.py --enforce-gate`
  - `python/tools/freeze_similarity_baseline.py`
  - `python/tools/generate_implemented_method_coverage.py`
  - `python/tools/verify_offline_standalone.py`
- Added CI workflows:
  - `.github/workflows/python-ci.yml`
  - `.github/workflows/matlab-parity-gate.yml`

## Release criteria (v1.0 gate)

- Class similarity gate: `9/9` pass.
- Help-topic execution gate: Python `25/25`, MATLAB `25/25`.
- Parity contract gate: required topic keys pass scalar tolerance checks.
- Regression gate must pass with no unexpected failures.
- Standalone/offline source checkout workflow must pass `verify_offline_standalone.py`.

## MATLAB-to-Python API mapping (selected)

| MATLAB | Python canonical |
|---|---|
| `SignalObj` | `nstat.signal.Signal` |
| `Covariate` | `nstat.signal.Covariate` |
| `nspikeTrain` | `nstat.spikes.SpikeTrain` |
| `nstColl` | `nstat.spikes.SpikeTrainCollection` |
| `CovColl` | `nstat.trial.CovariateCollection` |
| `TrialConfig` | `nstat.trial.TrialConfig` |
| `ConfigColl` | `nstat.trial.ConfigCollection` |
| `Analysis.RunAnalysisForAllNeurons` | `nstat.analysis.Analysis.run_analysis_for_all_neurons` |
| `FitResSummary` | `nstat.fit.FitSummary` |
| `CIF` | `nstat.cif.CIFModel` |
| `DecodingAlgorithms` | `nstat.decoding.DecoderSuite` |

## Compatibility adapters

MATLAB-style adapters remain importable under `nstat/*.py` compatibility modules and emit `DeprecationWarning` with migration targets.

## Known differences / omissions

- Not all legacy MATLAB plotting helpers are ported as core API methods; visualization is notebook/doc driven.
- Method-level parity status is tracked in `python/reports/method_parity_matrix.json`.
- Scalar parity comparisons are tolerance-based and may vary when seeds/parameters diverge from MATLAB defaults.
