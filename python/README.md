# Python nSTAT

This directory contains the standalone Python implementation of nSTAT.

## Canonical API modules

- `nstat.signal`: `Signal`, `Covariate`
- `nstat.spikes`: `SpikeTrain`, `SpikeTrainCollection`
- `nstat.events`: `Events`
- `nstat.history`: `HistoryBasis`
- `nstat.trial`: `CovariateCollection`, `TrialConfig`, `ConfigCollection`, `Trial`
- `nstat.cif`: `CIFModel`
- `nstat.analysis`: `Analysis`
- `nstat.fit`: `FitResult`, `FitSummary`
- `nstat.decoding`: `DecoderSuite`
- `nstat.datasets`: dataset registry and checksum verification

MATLAB-style entry points remain importable as compatibility adapters with `DeprecationWarning` messages.

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

## Generate docs and notebooks

```bash
python3 python/tools/generate_help_topic_docs.py
python3 python/tools/generate_example_notebooks.py
```

## Validation

```bash
python3 python/tools/freeze_port_baseline.py
python3 python/tools/generate_method_parity_matrix.py
python3 python/tools/generate_implemented_method_coverage.py
python3 python/tools/verify_examples_notebooks.py
NSTAT_MATLAB_EXTRA_ARGS='-maca64 -nodisplay -noFigureWindows' \
  python3 python/tools/verify_python_vs_matlab_similarity.py --enforce-gate
python3 python/tools/freeze_similarity_baseline.py
python3 python/tools/verify_offline_standalone.py
cd python && python3 -m pytest
```

## CI

- `.github/workflows/python-ci.yml` runs docs, notebook verification, offline standalone checks, and `pytest`.
- `.github/workflows/matlab-parity-gate.yml` runs MATLAB/Python parity gate on self-hosted macOS runners with MATLAB installed.
