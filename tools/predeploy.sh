#!/usr/bin/env bash
#
# tools/predeploy.sh — one-command release gate for nSTAT.
#
# Phase D3.1 of docs/superpowers/plans/2026-05-20-comprehensive-codebase-audit.md.
#
# Chains every existing local check in canonical order:
#   1. Unit tests             — tools/run_unit_tests.sh
#   2. Integration tests      — tools/run_unit_tests.sh --integration
#   3. README figure parity   — tools/check_readme_figures.sh
#   4. Helpfile HTML republish + helptoc validation + search-index rebuild
#      — helpfiles/publish_all_helpfiles.m
#   5. helptoc.xml lint       — tools/lint_helptoc.py
#   6. Bug-pattern audit      — tools/check_bug_patterns.sh
#
# Wall clock: ~30–45 minutes on a current laptop (the publish step is the
# slow one because it re-executes every example).
#
# CI does NOT run MATLAB. This gate is local-only. Run before any tagged
# release (v1.4, v1.5, …).
#
# Usage:
#   tools/predeploy.sh
#   tools/predeploy.sh --skip-publish    # skip the slow helpfile republish
#   tools/predeploy.sh --skip-readme     # skip README figure parity
#
# Exit codes:
#   0  every gate passed (release-ready)
#   1  one or more gates failed
#   2  configuration problem (MATLAB binary not found, etc.)

set -uo pipefail

MATLAB_BIN="${MATLAB_BIN:-/Applications/MATLAB_R2025b.app/bin/matlab}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

SKIP_PUBLISH=0
SKIP_README=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-publish) SKIP_PUBLISH=1; shift ;;
    --skip-readme)  SKIP_README=1;  shift ;;
    -h|--help)
      grep '^#' "$0" | head -30
      exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ ! -x "$MATLAB_BIN" ]]; then
  echo "ERROR: MATLAB binary not found at $MATLAB_BIN" >&2
  echo "Override with MATLAB_BIN=/Applications/MATLAB_R20XXy.app/bin/matlab" >&2
  exit 2
fi

gate_count=0
gate_failed=0

run_gate() {
  local label="$1"; shift
  gate_count=$((gate_count + 1))
  echo
  echo "=== [${gate_count}] ${label} ==="
  if "$@"; then
    echo "  → PASS"
  else
    echo "  → FAIL"
    gate_failed=$((gate_failed + 1))
  fi
}

run_gate "Unit tests" \
  "$REPO_ROOT/tools/run_unit_tests.sh"

run_gate "Integration tests" \
  "$REPO_ROOT/tools/run_unit_tests.sh" --integration

if [[ $SKIP_README -eq 0 ]]; then
  run_gate "README figure parity" \
    "$REPO_ROOT/tools/check_readme_figures.sh"
else
  echo
  echo "=== [skipped] README figure parity (--skip-readme) ==="
fi

if [[ $SKIP_PUBLISH -eq 0 ]]; then
  run_gate "Helpfile HTML republish + search-index rebuild" \
    "$MATLAB_BIN" -batch "addpath(genpath('$REPO_ROOT')); cd('$REPO_ROOT'); publish_all_helpfiles('EvalCode', true);"
else
  echo
  echo "=== [skipped] Helpfile HTML republish (--skip-publish) ==="
fi

run_gate "helptoc.xml lint" \
  python3 "$REPO_ROOT/tools/lint_helptoc.py"

run_gate "Bug-pattern audit (review report afterwards)" \
  "$REPO_ROOT/tools/check_bug_patterns.sh" "$REPO_ROOT/docs/verification/bug_pattern_audit_latest.md"

echo
echo "============================================================"
if [[ $gate_failed -eq 0 ]]; then
  echo "predeploy gate: PASSED ($gate_count of $gate_count)"
  echo "Release-ready. Run tools/stamp_release.m to update Contents.m + manifest."
else
  echo "predeploy gate: FAILED ($gate_failed of $gate_count gates failed)"
  echo "Investigate failures and re-run."
fi
echo "============================================================"

exit $(( gate_failed > 0 ? 1 : 0 ))
