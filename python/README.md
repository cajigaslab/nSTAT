# Python nSTAT

Standalone Python port of the nSTAT toolbox, organized around core MATLAB-mirroring classes with a Pythonic API.

## Core API

- `nstat.signal`: `Signal`, `Covariate`
- `nstat.spikes`: `SpikeTrain`, `SpikeTrainCollection`
- `nstat.events`: `Events`
- `nstat.history`: `HistoryBasis`
- `nstat.trial`: `CovariateCollection`, `TrialConfig`, `ConfigCollection`, `Trial`
- `nstat.cif`: `CIFModel`
- `nstat.analysis`: `Analysis`
- `nstat.fit`: `FitResult`, `FitSummary`
- `nstat.decoding`: `DecoderSuite`
- `nstat.datasets`: `list_datasets`, `get_dataset_path`, `verify_checksums`

MATLAB-style module names remain importable as compatibility adapters and emit `DeprecationWarning`.

## Install

```bash
cd python
python3 -m pip install -e .
```

## Run basic examples

```bash
cd python
python3 examples/basic_data_workflow.py
python3 examples/fit_poisson_glm.py
python3 examples/simulate_population_psth.py
```

## Run tests

```bash
cd python
python3 -m pytest
```
