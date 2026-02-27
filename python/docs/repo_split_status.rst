Repo Split Status
=================

Scope
-----

This document tracks readiness for splitting the current monorepo into:

- ``nSTAT`` (MATLAB-focused repository)
- ``nSTAT-python`` (Python-focused repository)

Inventory Source
----------------

Generated via:

.. code-block:: bash

   python3 python/tools/generate_repo_split_inventory.py

Output directory:

- ``python/reports/repo_split_inventory``

Current Snapshot
----------------

- TOC topics: 31
- TOC example topics: 25
- Python docs coverage (TOC topics): 31/31
- Python notebook coverage (TOC topics): 29/31
- Python example script coverage (TOC examples): 25/25
- Python example full coverage (docs + notebook + script): 25/25
- MATLAB example topics with ``.mlx``: 18/25

MATLAB MLX Gaps
---------------

The following example topics currently do not have a matching ``helpfiles/<Topic>.mlx``:

- ``ExplicitStimulusWhiskerData``
- ``NetworkTutorial``
- ``PPThinning``
- ``PSTHEstimation``
- ``StimulusDecode2D``
- ``ValidationDataSet``
- ``mEPSCAnalysis``

Immediate Next Actions
----------------------

1. Keep ``nSTAT`` as source-of-truth for MATLAB ``helpfiles`` and create missing ``.mlx`` examples for the 7 topics above.
2. Bootstrap ``nSTAT-python`` from the ``python/`` subtree and move parity/docs/notebook CI there.
3. Update cross-repo README links:
   - ``nSTAT`` -> points Python users to ``nSTAT-python``.
   - ``nSTAT-python`` -> points MATLAB users to ``nSTAT``.
