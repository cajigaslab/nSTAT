# Python nSTAT

This page tracks the Python implementation of the nSTAT toolbox.

## Scope

The Python project aims to reproduce core nSTAT functionality while keeping API behavior consistent with the MATLAB toolbox where practical.

Priority areas:

- Core signal and covariate objects
- Point-process GLM fitting
- Model diagnostics and summary statistics
- Simulation workflows used by published examples
- Decoding algorithms

## Status

Current phase: foundation and architecture planning.

Not yet complete:

- Public Python package
- Full class-by-class feature parity
- End-to-end benchmark parity suite against MATLAB outputs

## Proposed Python stack

- `numpy`, `scipy`
- `pandas`
- `statsmodels` (where appropriate)
- `matplotlib`
- `scikit-learn` (for selected utilities)
- `pytest` for testing

## Repository plan

Proposed layout for Python code:

- `python/nstat/` for package source
- `python/tests/` for unit and parity tests
- `python/examples/` for executable notebooks/scripts

## Validation strategy

Each major Python module should be validated against MATLAB reference outputs for:

- Conditional intensity estimates
- Fitted coefficients and confidence intervals
- Goodness-of-fit metrics (e.g., KS diagnostics)
- Simulation output statistics

## Contribution workflow

1. Branch from `codex/python-nstat`.
2. Implement a focused module or feature.
3. Add tests and MATLAB parity checks.
4. Open a pull request that includes the problem statement, implementation summary, and validation evidence.

## Short-term roadmap

1. Create package skeleton and CI checks.
2. Implement base data structures (`SignalObj`, `Covariate`, `nspikeTrain` equivalents).
3. Implement point-process GLM fitting pipeline.
4. Port one end-to-end simulation + fit example.
