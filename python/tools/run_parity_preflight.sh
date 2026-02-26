#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
MATLAB_EXTRA_ARGS="${NSTAT_MATLAB_EXTRA_ARGS:--maca64 -nodisplay -noFigureWindows -softwareopengl}"
STAGE_A_BLOCKS_RAW="${NSTAT_PARITY_PREFLIGHT_STAGEA_BLOCKS:-core_smoke timeout_front}"
STAGE_B_TOPICS_RAW="${NSTAT_PARITY_PREFLIGHT_STAGEB_TOPICS:-PPThinning,ValidationDataSet,DecodingExample,StimulusDecode2D}"
STAGE_B_REPORT_PATH="${NSTAT_PARITY_PREFLIGHT_STAGEB_REPORT:-python/reports/parity_preflight_stageb_selected.json}"

stage_a_tokens="${STAGE_A_BLOCKS_RAW//,/ }"
read -r -a STAGE_A_BLOCKS <<< "${stage_a_tokens}"
if [[ "${#STAGE_A_BLOCKS[@]}" -eq 0 ]]; then
  echo "[preflight] no Stage A blocks resolved from NSTAT_PARITY_PREFLIGHT_STAGEA_BLOCKS='${STAGE_A_BLOCKS_RAW}'" >&2
  exit 2
fi

stage_b_tokens="${STAGE_B_TOPICS_RAW//,/ }"
read -r -a STAGE_B_TOPICS <<< "${stage_b_tokens}"
if [[ "${#STAGE_B_TOPICS[@]}" -eq 0 ]]; then
  echo "[preflight] no Stage B topics resolved from NSTAT_PARITY_PREFLIGHT_STAGEB_TOPICS='${STAGE_B_TOPICS_RAW}'" >&2
  exit 2
fi

cd "${REPO_ROOT}"
export NSTAT_MATLAB_EXTRA_ARGS="${MATLAB_EXTRA_ARGS}"
export NSTAT_FORCE_M_HELP_SCRIPTS="${NSTAT_FORCE_M_HELP_SCRIPTS:-1}"
if [[ "${NSTAT_SET_ACTIONS_RUNNER_SVC:-1}" == "1" ]]; then
  export ACTIONS_RUNNER_SVC=1
fi

echo "[preflight] repo: ${REPO_ROOT}"
echo "[preflight] python: ${PYTHON_BIN}"
echo "[preflight] matlab args: ${NSTAT_MATLAB_EXTRA_ARGS}"
echo "[preflight] stage A blocks: ${STAGE_A_BLOCKS[*]}"
echo "[preflight] stage B selected topics: ${STAGE_B_TOPICS[*]}"
echo "[preflight] stage B report: ${STAGE_B_REPORT_PATH}"

python/tools/run_parity_ladder.sh "${STAGE_A_BLOCKS[@]}"

"${PYTHON_BIN}" python/tools/verify_python_vs_matlab_similarity.py \
  --enforce-gate \
  --report-path "${STAGE_B_REPORT_PATH}" \
  --topics "${STAGE_B_TOPICS[@]}"

"${PYTHON_BIN}" python/tools/summarize_parity_report.py "${STAGE_B_REPORT_PATH}" || true

echo "[preflight] complete"
