# Python nSTAT

This directory contains a standalone Python implementation of the nSTAT toolbox core APIs.

## Included MATLAB-to-Python ports

The following MATLAB files are mirrored by Python modules in `nstat/`:

- `Analysis`
- `CIF`
- `ConfidenceInterval`
- `ConfigColl`
- `CovColl`
- `Covariate`
- `DecodingAlgorithms`
- `Events`
- `FitResSummary`
- `FitResult`
- `History`
- `SignalObj`
- `Trial`
- `TrialConfig`
- `nSTAT_Install`
- `nspikeTrain`
- `nstColl`

## Install

```bash
cd python
python3 -m pip install -e .
```

## Run paper examples equivalent

```bash
cd python
python3 examples/nstat_paper_examples.py --repo-root ..
```

This runs a Python equivalent of the `nSTATPaperExamples.m` workflow (starting at Experiment 2), loading local data files from `../data`.
Plots are saved to `plots/nstat_paper_examples/` by default. Use `--no-plots` to skip plot generation.
