Example Data Analysis - Miniature Excitatory Post-Synaptic Currents (mEPSCs)
============================================================================

MATLAB help target: ``mEPSCAnalysis.html``

Concept
-------
This page mirrors the corresponding MATLAB help topic and documents the Python standalone equivalent.

API Mapping (MATLAB -> Python)
------------------------------
.. list-table::
   :header-rows: 1

   * - MATLAB API
     - Python API
   * - ``mEPSCAnalysis``
     - ``nstat (canonical module by topic)``

Migration Callout
-----------------
- MATLAB-style compatibility adapters remain importable for one major cycle and emit ``DeprecationWarning``.
- Prefer canonical Python modules under ``nstat`` for new code.

Python Usage
------------
.. code-block:: python

   import nstat
   print(nstat.__all__[:5])

Data Requirements
-----------------
Use ``nstat.datasets.list_datasets()`` and ``nstat.datasets.get_dataset_path(...)`` to access bundled datasets.

Expected Outputs
----------------
This topic should execute without MATLAB and produce deterministic summary metrics where applicable.

Known Differences
-----------------
- Some legacy plotting helpers are represented via notebooks/docs instead of full method parity.
- Numerical outputs may vary if random seeds, bin widths, or sample rates differ from MATLAB defaults.
