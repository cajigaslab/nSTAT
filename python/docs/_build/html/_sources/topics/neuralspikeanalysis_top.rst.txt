nSTAT Neural Spike Train Analysis Toolbox Overview MATLAB 2025b Help Integration Class Definitions SignalObj Reference FitResult Reference Examples Using the SignalObj Class Using the Covariate Class Using the CovColl Class Using the nSpikeTrain Class Using the nstColl Class Using the Events Class Using the History Class Using the Trial Class Using the TrialConfig Class Using the ConfigColl Class Using the Analysis Class Using the FitResult Class Using the FitResSummary Class Point Process Simulation via Thinning Example Data Analysis - Simulated Data - Computing a Peri-Stimulus Time Histogram (PSTH) Example Data Analysis - Simulated Constant (Piecewise Constant) Rate Poisson Example Data Analysis - Miniature Excitatory Post-Synaptic Currents (mEPSCs) Example Data Analysis - Simulated Explicit Stimulus and History Example Data Analysis - Explicit Stimulus Example Data Analysis - Hippocampal Place Cell Receptive Field Estimation Example Data Analysis - Decoding Univariate Simulated Stimuli (No History Effect) Example Data Analysis - Decoding Univariate Simulated Stimuli with and without History Effect Example Data Analysis - Decoding Bivariate Simulated Stimuli Example Data Analysis - Two Neuron Network Simulation and Estimation of Ensemble Effect nSTAT Paper Examples Neuroscience Statistics Research Laboratory
===================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================

MATLAB help target: ``NeuralSpikeAnalysis_top.html``

Concept
-------
This page mirrors the corresponding MATLAB help topic and documents the Python standalone equivalent.

API Mapping (MATLAB -> Python)
------------------------------
.. list-table::
   :header-rows: 1

   * - MATLAB API
     - Python API
   * - ``NeuralSpikeAnalysis_top``
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
