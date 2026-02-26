Parity Runbook
==============

Use this runbook for reproducible local/CI MATLAB parity checks on this machine.

Validated environment
---------------------

- MATLAB binary: ``/Applications/MATLAB_R2025b.app/bin/matlab``
- MATLAB args: ``-maca64 -nodisplay -noFigureWindows -softwareopengl``
- Runner service mode: ``ACTIONS_RUNNER_SVC=1``
- Force ``.m`` help scripts: ``NSTAT_FORCE_M_HELP_SCRIPTS=1``
- Per-topic MATLAB retries: ``NSTAT_MATLAB_TOPIC_MAX_ATTEMPTS=2``
- Stage C strict isolation: ``NSTAT_MATLAB_FORCE_TOPIC_ISOLATION=1``
- Stage C hard cleanup on timeout/crash: ``NSTAT_MATLAB_HARD_CLEANUP_ON_FAILURE=1``
- Ladder timeout-only retry: ``NSTAT_PARITY_RETRY_TIMEOUT_BLOCKS=1``
- Ladder recoverable retry: ``NSTAT_PARITY_RETRY_RECOVERABLE_BLOCKS=1``

Preflight + staged parity
-------------------------

Run Stage A + selected Stage B preflight:

.. code-block:: bash

   ACTIONS_RUNNER_SVC=1 \
   NSTAT_FORCE_M_HELP_SCRIPTS=1 \
   NSTAT_MATLAB_EXTRA_ARGS='-maca64 -nodisplay -noFigureWindows -softwareopengl' \
   NSTAT_MATLAB_TOPIC_MAX_ATTEMPTS=2 \
   python/tools/run_parity_preflight.sh

Run the staged ladder (core -> timeout -> graphics -> heavy-tail):

.. code-block:: bash

   ACTIONS_RUNNER_SVC=1 \
   NSTAT_FORCE_M_HELP_SCRIPTS=1 \
   NSTAT_MATLAB_EXTRA_ARGS='-maca64 -nodisplay -noFigureWindows -softwareopengl' \
   NSTAT_MATLAB_TOPIC_MAX_ATTEMPTS=2 \
   NSTAT_PARITY_RETRY_TIMEOUT_BLOCKS=1 \
   NSTAT_PARITY_TIMEOUT_RETRY_BLOCKS=timeout_front \
   NSTAT_PARITY_RETRY_RECOVERABLE_BLOCKS=1 \
   NSTAT_PARITY_RECOVERABLE_RETRY_BLOCKS='graphics_mid,heavy_tail' \
   python/tools/run_parity_ladder.sh core_smoke timeout_front graphics_mid heavy_tail

Full Stage C gate
-----------------

Run full-suite parity gate report:

.. code-block:: bash

   ACTIONS_RUNNER_SVC=1 \
   NSTAT_FORCE_M_HELP_SCRIPTS=1 \
   NSTAT_MATLAB_EXTRA_ARGS='-maca64 -nodisplay -noFigureWindows -softwareopengl' \
   NSTAT_MATLAB_TOPIC_MAX_ATTEMPTS=2 \
   NSTAT_MATLAB_FORCE_TOPIC_ISOLATION=1 \
   NSTAT_MATLAB_HARD_CLEANUP_ON_FAILURE=1 \
   python3 python/tools/verify_python_vs_matlab_similarity.py \
     --enforce-gate \
     --matlab-max-attempts 2 \
     --report-path python/reports/python_vs_matlab_similarity_report.json

Useful outputs
--------------

- Full report: ``python/reports/python_vs_matlab_similarity_report.json``
- Ladder retry telemetry: ``python/reports/parity_retry_summary.json``
- Block reports: ``python/reports/parity_block_*.json``
- Summary helper:

.. code-block:: bash

   python3 python/tools/summarize_parity_report.py \
     python/reports/python_vs_matlab_similarity_report.json --json
