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
NSTAT_MATLAB_EXTRA_ARGS='-maca64 -nodisplay -noFigureWindows -softwareopengl' \
  python3 python/tools/verify_python_vs_matlab_similarity.py --enforce-gate
python3 python/tools/freeze_similarity_baseline.py
python3 python/tools/verify_offline_standalone.py
cd python && python3 -m pytest
```

If Git LFS assets are unavailable (for example, CI quota exhaustion), set
`NSTAT_ALLOW_SYNTHETIC_DATA=1` to use deterministic synthetic fallbacks for
data-heavy paper example loaders.

### Local parity block debugging

```bash
python3 python/tools/debug_parity_blocks.py \
  --set-actions-runner-svc \
  --matlab-extra-args "-maca64 -nodisplay -noFigureWindows -softwareopengl"
```

Single wrapper command (fail-fast ladder):

```bash
python/tools/run_parity_ladder.sh
```

Single preflight command (Stage A ladder + selected Stage B topics):

```bash
python/tools/run_parity_preflight.sh
```

Notes:

- Runs blocks in order: `core_smoke -> timeout_front -> graphics_mid -> heavy_tail -> full_suite`.
- Exits immediately if a block regresses (`python_ok`, `matlab_ok`, scalar overlap, parity contract, or regression gate).
- Includes runtime regression guard using machine baseline block times with multiplier `NSTAT_PARITY_RUNTIME_MULTIPLIER` (default `2.5`).
- Set `NSTAT_PARITY_RUNTIME_MULTIPLIER=0` to disable runtime regression checks.
- Pass specific block names as args to run subset ladders, e.g.:
  `python/tools/run_parity_ladder.sh core_smoke timeout_front`.
- Ladder writes retry telemetry to `python/reports/parity_retry_summary.json` (block, attempt count, retry reason, timeout-topic list).
- Retry behavior is controlled by `NSTAT_PARITY_RETRY_TIMEOUT_BLOCKS` and `NSTAT_PARITY_TIMEOUT_RETRY_BLOCKS`.
- Preflight topic selection can be overridden with `NSTAT_PARITY_PREFLIGHT_STAGEB_TOPICS`.

Use targeted blocks to debug delays locally before running remote CI:

```bash
# 1) Fast API/parity smoke
python3 python/tools/debug_parity_blocks.py --blocks core_smoke \
  --set-actions-runner-svc --matlab-extra-args "-maca64 -nodisplay -noFigureWindows -softwareopengl"

# 2) Former timeout-prone front topics
python3 python/tools/debug_parity_blocks.py --blocks timeout_front \
  --set-actions-runner-svc --matlab-extra-args "-maca64 -nodisplay -noFigureWindows -softwareopengl"

# 3) Graphics-sensitive middle topics
python3 python/tools/debug_parity_blocks.py --blocks graphics_mid \
  --set-actions-runner-svc --matlab-extra-args "-maca64 -nodisplay -noFigureWindows -softwareopengl"

# 4) Heavy tail topics
python3 python/tools/debug_parity_blocks.py --blocks heavy_tail \
  --set-actions-runner-svc --matlab-extra-args "-maca64 -nodisplay -noFigureWindows -softwareopengl"

# 5) Full gate-equivalent suite
python3 python/tools/debug_parity_blocks.py --blocks full_suite \
  --set-actions-runner-svc --matlab-extra-args "-maca64 -nodisplay -noFigureWindows -softwareopengl"
```

Summarize a parity report quickly:

```bash
python3 python/tools/summarize_parity_report.py python/reports/parity_block_full_suite.json
```

Recent local baseline on this machine (MATLAB R2025b, no figure windows, software OpenGL):

- `core_smoke`: ~47s
- `timeout_front`: ~122s
- `graphics_mid`: ~291s
- `heavy_tail`: ~385s
- `full_suite` (25 topics): ~826s

## CI

- `.github/workflows/python-ci.yml` runs docs, notebook verification, offline standalone checks, and `pytest`.
- `.github/workflows/matlab-parity-gate.yml` runs MATLAB/Python parity gate on self-hosted macOS runners with MATLAB installed.
