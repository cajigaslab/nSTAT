#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
MATLAB_EXTRA_ARGS="${NSTAT_MATLAB_EXTRA_ARGS:--maca64 -nodisplay -noFigureWindows -softwareopengl}"
MATLAB_BIN="${NSTAT_MATLAB_BIN:-/Applications/MATLAB_R2025b.app/bin/matlab}"
SET_ACTIONS_RUNNER_SVC="${NSTAT_SET_ACTIONS_RUNNER_SVC:-1}"
RUNTIME_MULTIPLIER="${NSTAT_PARITY_RUNTIME_MULTIPLIER:-2.5}"
RETRY_TIMEOUT_BLOCKS="${NSTAT_PARITY_RETRY_TIMEOUT_BLOCKS:-0}"
TIMEOUT_RETRY_BLOCKS="${NSTAT_PARITY_TIMEOUT_RETRY_BLOCKS:-timeout_front}"
RETRY_RECOVERABLE_BLOCKS="${NSTAT_PARITY_RETRY_RECOVERABLE_BLOCKS:-1}"
RECOVERABLE_RETRY_BLOCKS="${NSTAT_PARITY_RECOVERABLE_RETRY_BLOCKS:-graphics_mid,heavy_tail,full_suite}"
RETRY_SUMMARY_PATH="${NSTAT_PARITY_RETRY_SUMMARY_PATH:-python/reports/parity_retry_summary.json}"

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

block_retry_enabled() {
  local block="$1"
  [[ "${RETRY_TIMEOUT_BLOCKS}" == "1" ]] || return 1
  local token
  for token in ${TIMEOUT_RETRY_BLOCKS//,/ }; do
    [[ "${token}" == "${block}" ]] && return 0
  done
  return 1
}

block_recoverable_retry_enabled() {
  local block="$1"
  [[ "${RETRY_RECOVERABLE_BLOCKS}" == "1" ]] || return 1
  local token
  for token in ${RECOVERABLE_RETRY_BLOCKS//,/ }; do
    [[ "${token}" == "${block}" ]] && return 0
  done
  return 1
}

is_timeout_only_regression() {
  local report_path="$1"
  "${PYTHON_BIN}" - "${report_path}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    raise SystemExit(1)
payload = json.loads(path.read_text(encoding="utf-8"))
rows = payload.get("helpfile_similarity", {}).get("rows", [])
if not rows:
    raise SystemExit(1)
failed = [r for r in rows if not bool(r.get("matlab_ok"))]
if not failed or len(failed) != len(rows):
    raise SystemExit(1)
if not all(str(r.get("matlab_error", "")).strip() == "matlab_timeout" for r in failed):
    raise SystemExit(1)
topics = [str(r.get("topic", "")) for r in failed]
print(f"[ladder] timeout-only regression detected across {len(topics)} topic(s): {topics}")
raise SystemExit(0)
PY
}

warmup_matlab() {
  if [[ ! -x "${MATLAB_BIN}" ]]; then
    echo "[ladder] matlab warmup skipped; binary not executable: ${MATLAB_BIN}"
    return 0
  fi
  echo "[ladder] running matlab warmup before retry"
  "${MATLAB_BIN}" ${MATLAB_EXTRA_ARGS} -batch "disp(version); exit" >/dev/null 2>&1 || true
}

resolve_path() {
  local p="$1"
  if [[ "${p}" = /* ]]; then
    printf "%s" "${p}"
  else
    printf "%s/%s" "${REPO_ROOT}" "${p}"
  fi
}

timeout_only_topics_csv() {
  local report_path="$1"
  "${PYTHON_BIN}" - "${report_path}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    raise SystemExit(1)
payload = json.loads(path.read_text(encoding="utf-8"))
rows = payload.get("helpfile_similarity", {}).get("rows", [])
if not rows:
    raise SystemExit(1)
failed = [r for r in rows if not bool(r.get("matlab_ok"))]
if not failed or len(failed) != len(rows):
    raise SystemExit(1)
if not all(str(r.get("matlab_error", "")).strip() == "matlab_timeout" for r in failed):
    raise SystemExit(1)
topics = [str(r.get("topic", "")).strip() for r in failed if str(r.get("topic", "")).strip()]
print(",".join(topics))
raise SystemExit(0)
PY
}

retryable_failure_topics_csv() {
  local report_path="$1"
  "${PYTHON_BIN}" - "${report_path}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    raise SystemExit(1)
payload = json.loads(path.read_text(encoding="utf-8"))
rows = payload.get("helpfile_similarity", {}).get("rows", [])
if not rows:
    raise SystemExit(1)
failed = [r for r in rows if not bool(r.get("matlab_ok"))]
if not failed:
    raise SystemExit(1)

markers = (
    "matlab_timeout",
    "matlab is exiting because of fatal error",
    "fatal error",
    "mathworkscrashreporter",
    "crash report has been saved",
    "libmwhandle_graphics",
)

def retryable(err: str) -> bool:
    e = (err or "").strip().lower()
    if e == "matlab_timeout":
        return True
    return any(m in e for m in markers)

if not all(retryable(str(r.get("matlab_error", ""))) for r in failed):
    raise SystemExit(1)

topics = [str(r.get("topic", "")).strip() for r in failed if str(r.get("topic", "")).strip()]
if not topics:
    raise SystemExit(1)
print(",".join(topics))
raise SystemExit(0)
PY
}

init_retry_summary() {
  "${PYTHON_BIN}" - "${RETRY_SUMMARY_ABS}" "${RETRY_TIMEOUT_BLOCKS}" "${TIMEOUT_RETRY_BLOCKS}" "${RETRY_RECOVERABLE_BLOCKS}" "${RECOVERABLE_RETRY_BLOCKS}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
payload = {
    "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "retry_timeout_blocks_enabled": sys.argv[2] == "1",
    "timeout_retry_blocks": [b for b in sys.argv[3].replace(",", " ").split() if b],
    "retry_recoverable_blocks_enabled": sys.argv[4] == "1",
    "recoverable_retry_blocks": [b for b in sys.argv[5].replace(",", " ").split() if b],
    "events": [],
}
path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
PY
}

append_retry_summary_event() {
  local kind="$1"
  local block="$2"
  local attempt="$3"
  local max_attempts="$4"
  local status="$5"
  local return_code="$6"
  local reason="$7"
  local timeout_topics_csv="$8"
  "${PYTHON_BIN}" - "${RETRY_SUMMARY_ABS}" "${kind}" "${block}" "${attempt}" "${max_attempts}" "${status}" "${return_code}" "${reason}" "${timeout_topics_csv}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
if path.exists():
    payload = json.loads(path.read_text(encoding="utf-8"))
else:
    payload = {"generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), "events": []}
events = payload.setdefault("events", [])
topics_raw = sys.argv[9].strip()
event = {
    "ts_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "kind": sys.argv[2],
    "block": sys.argv[3],
    "attempt": int(sys.argv[4]),
    "max_attempts": int(sys.argv[5]),
    "status": sys.argv[6],
    "return_code": int(sys.argv[7]),
    "reason": sys.argv[8],
    "timeout_topics": [t for t in topics_raw.split(",") if t] if topics_raw else [],
}
events.append(event)
path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
PY
}

cd "${REPO_ROOT}"
RETRY_SUMMARY_ABS="$(resolve_path "${RETRY_SUMMARY_PATH}")"
init_retry_summary

echo "[ladder] repo: ${REPO_ROOT}"
echo "[ladder] python: ${PYTHON_BIN}"
echo "[ladder] matlab args: ${MATLAB_EXTRA_ARGS}"
echo "[ladder] blocks: ${BLOCKS[*]}"
echo "[ladder] runtime multiplier: ${RUNTIME_MULTIPLIER} (<=0 disables runtime regression checks)"
echo "[ladder] retry timeout-only blocks: ${RETRY_TIMEOUT_BLOCKS} (blocks: ${TIMEOUT_RETRY_BLOCKS})"
echo "[ladder] retry recoverable-failure blocks: ${RETRY_RECOVERABLE_BLOCKS} (blocks: ${RECOVERABLE_RETRY_BLOCKS})"
echo "[ladder] retry summary path: ${RETRY_SUMMARY_PATH}"

for block in "${BLOCKS[@]}"; do
  if ! baseline_s="$(baseline_runtime_sum_s "${block}")"; then
    echo "[ladder] unknown block: ${block}" >&2
    exit 2
  fi

  echo "[ladder] running block: ${block}"
  report_path="${REPO_ROOT}/python/reports/parity_block_${block}.json"
  max_attempts=1
  if block_retry_enabled "${block}" || block_recoverable_retry_enabled "${block}"; then
    max_attempts=2
  fi
  attempt=1
  while true; do
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

    if [[ ! -f "${report_path}" ]]; then
      echo "[ladder] missing report: ${report_path}" >&2
      exit 3
    fi

    if "${PYTHON_BIN}" - "${report_path}" "${block}" "${baseline_s}" "${RUNTIME_MULTIPLIER}" <<'PY'
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
    then
      append_retry_summary_event "block_result" "${block}" "${attempt}" "${max_attempts}" "pass" "0" "ok" ""
      break
    fi

    rc=$?
    if [[ "${rc}" -eq 10 ]] && [[ "${attempt}" -lt "${max_attempts}" ]] && timeout_topics_csv="$(timeout_only_topics_csv "${report_path}")"; then
      is_timeout_only_regression "${report_path}" >/dev/null
      echo "[ladder] retrying block ${block} after timeout-only regression (attempt ${attempt}/${max_attempts}); topics=${timeout_topics_csv}"
      append_retry_summary_event "retry_scheduled" "${block}" "${attempt}" "${max_attempts}" "retry" "${rc}" "timeout_only_regression" "${timeout_topics_csv}"
      warmup_matlab
      attempt=$((attempt + 1))
      continue
    fi
    if [[ "${rc}" -eq 10 ]] && [[ "${attempt}" -lt "${max_attempts}" ]] && retry_topics_csv="$(retryable_failure_topics_csv "${report_path}")"; then
      echo "[ladder] retrying block ${block} after recoverable MATLAB failures (attempt ${attempt}/${max_attempts}); topics=${retry_topics_csv}"
      append_retry_summary_event "retry_scheduled" "${block}" "${attempt}" "${max_attempts}" "retry" "${rc}" "recoverable_matlab_failures" "${retry_topics_csv}"
      warmup_matlab
      attempt=$((attempt + 1))
      continue
    fi
    reason="block_failure"
    if [[ "${rc}" -eq 10 ]]; then
      reason="regression_gate_failure"
    elif [[ "${rc}" -eq 11 ]]; then
      reason="runtime_regression"
    fi
    timeout_topics_csv=""
    if timeout_topics_tmp="$(timeout_only_topics_csv "${report_path}")"; then
      timeout_topics_csv="${timeout_topics_tmp}"
    fi
    append_retry_summary_event "block_result" "${block}" "${attempt}" "${max_attempts}" "fail" "${rc}" "${reason}" "${timeout_topics_csv}"
    exit "${rc}"
  done

done

echo "[ladder] all requested blocks passed"
