#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
MATLAB_EXTRA_ARGS="${NSTAT_MATLAB_EXTRA_ARGS:--maca64 -nodisplay -noFigureWindows}"
SET_ACTIONS_RUNNER_SVC="${NSTAT_SET_ACTIONS_RUNNER_SVC:-1}"
RUNTIME_MULTIPLIER="${NSTAT_PARITY_RUNTIME_MULTIPLIER:-2.5}"

DEFAULT_BLOCKS=(core_smoke timeout_front graphics_mid heavy_tail full_suite)
if [[ $# -gt 0 ]]; then
  BLOCKS=("$@")
else
  BLOCKS=("${DEFAULT_BLOCKS[@]}")
fi

baseline_runtime_sum_s() {
  case "$1" in
    core_smoke) echo 47 ;;
    timeout_front) echo 122 ;;
    graphics_mid) echo 291 ;;
    heavy_tail) echo 385 ;;
    full_suite) echo 826 ;;
    *) return 1 ;;
  esac
}

cd "${REPO_ROOT}"

echo "[ladder] repo: ${REPO_ROOT}"
echo "[ladder] python: ${PYTHON_BIN}"
echo "[ladder] matlab args: ${MATLAB_EXTRA_ARGS}"
echo "[ladder] blocks: ${BLOCKS[*]}"
echo "[ladder] runtime multiplier: ${RUNTIME_MULTIPLIER} (<=0 disables runtime regression checks)"

for block in "${BLOCKS[@]}"; do
  if ! baseline_s="$(baseline_runtime_sum_s "${block}")"; then
    echo "[ladder] unknown block: ${block}" >&2
    exit 2
  fi

  echo "[ladder] running block: ${block}"

  cmd=(
    "${PYTHON_BIN}"
    "${REPO_ROOT}/python/tools/debug_parity_blocks.py"
    --blocks "${block}"
    --matlab-extra-args "${MATLAB_EXTRA_ARGS}"
    --output "python/reports/parity_block_benchmark_report_ladder_${block}.json"
  )
  if [[ "${SET_ACTIONS_RUNNER_SVC}" == "1" ]]; then
    cmd+=(--set-actions-runner-svc)
  fi

  "${cmd[@]}"

  report_path="${REPO_ROOT}/python/reports/parity_block_${block}.json"
  if [[ ! -f "${report_path}" ]]; then
    echo "[ladder] missing report: ${report_path}" >&2
    exit 3
  fi

  "${PYTHON_BIN}" - "${report_path}" "${block}" "${baseline_s}" "${RUNTIME_MULTIPLIER}" <<'PY'
import json
import sys
from pathlib import Path

report = Path(sys.argv[1])
block = sys.argv[2]
baseline = float(sys.argv[3])
mult = float(sys.argv[4])

payload = json.loads(report.read_text(encoding="utf-8"))
summary = payload.get("helpfile_similarity", {}).get("summary", {})
rows = payload.get("helpfile_similarity", {}).get("rows", [])


def i(name: str) -> int:
    try:
        return int(summary.get(name, 0) or 0)
    except Exception:
        return 0


total = i("total_topics")
python_ok = i("python_ok")
matlab_ok = i("matlab_ok")
both_ok = i("both_ok")
scalar_ok = i("scalar_overlap_pass_topics")
parity_pass = bool(payload.get("parity_contract", {}).get("pass", False))
regression_pass = bool(payload.get("regression_gate", {}).get("pass", False))
matlab_failed = [str(r.get("topic", "")) for r in rows if not bool(r.get("matlab_ok"))]
runtime_sum = sum(float(r.get("matlab_runtime_s") or 0.0) for r in rows)

print(
    f"[ladder] block={block} total={total} python_ok={python_ok} matlab_ok={matlab_ok} "
    f"both_ok={both_ok} scalar_ok={scalar_ok} parity_pass={parity_pass} "
    f"regression_pass={regression_pass} runtime_sum_s={runtime_sum:.2f}"
)

regression_reasons = []
if total <= 0:
    regression_reasons.append("no topics were executed")
if python_ok != total:
    regression_reasons.append(f"python_ok={python_ok}/{total}")
if matlab_ok != total:
    regression_reasons.append(f"matlab_ok={matlab_ok}/{total}")
if both_ok != total:
    regression_reasons.append(f"both_ok={both_ok}/{total}")
if scalar_ok != total:
    regression_reasons.append(f"scalar_overlap_pass_topics={scalar_ok}/{total}")
if not parity_pass:
    regression_reasons.append("parity_contract=fail")
if not regression_pass:
    regression_reasons.append("regression_gate=fail")

if regression_reasons:
    print(f"[ladder] regression in {block}: {'; '.join(regression_reasons)}", file=sys.stderr)
    if matlab_failed:
        print(f"[ladder] failing matlab topics: {matlab_failed}", file=sys.stderr)
    sys.exit(10)

if mult > 0:
    threshold = baseline * mult
    if runtime_sum > threshold:
        print(
            f"[ladder] runtime regression in {block}: runtime_sum_s={runtime_sum:.2f} > "
            f"threshold_s={threshold:.2f} (baseline={baseline:.2f}, mult={mult:.2f})",
            file=sys.stderr,
        )
        sys.exit(11)

print(f"[ladder] block passed: {block}")
PY

done

echo "[ladder] all requested blocks passed"
