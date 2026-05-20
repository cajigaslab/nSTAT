#!/usr/bin/env bash
#
# tools/run_unit_tests.sh — local pre-push gate for the nSTAT unit suite.
#
# This is the test gate every contributor is expected to run before
# pushing changes. CI does NOT run MATLAB (the team's MathWorks license
# does not extend to GitHub-hosted runners), so the local pass is the
# only test gate.
#
# Usage:
#   tools/run_unit_tests.sh                  # run tests/unit/ with R2025b
#   tools/run_unit_tests.sh --integration    # also run tests/integration/
#   tools/run_unit_tests.sh --matlab-path /Applications/MATLAB_R2024b.app
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed (or MATLAB itself errored)
#   2  MATLAB binary not found / configuration problem
#
# CI (.github/) does not run MATLAB. Do not re-add a MATLAB workflow.

set -euo pipefail

# Default MATLAB binary; override with --matlab-path or MATLAB_BIN env var
MATLAB_BIN="${MATLAB_BIN:-/Applications/MATLAB_R2025b.app/bin/matlab}"
INCLUDE_INTEGRATION=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --matlab-path)
            MATLAB_BIN="$2/bin/matlab"
            shift 2
            ;;
        --integration)
            INCLUDE_INTEGRATION=1
            shift
            ;;
        -h|--help)
            grep '^#' "$0" | head -25
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

if [[ ! -x "$MATLAB_BIN" ]]; then
    echo "ERROR: MATLAB binary not found at $MATLAB_BIN" >&2
    echo "Override with --matlab-path /Applications/MATLAB_R2024b.app or MATLAB_BIN=..." >&2
    exit 2
fi

# Resolve repo root regardless of invocation directory
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "Running nSTAT unit tests from $REPO_ROOT"
echo "MATLAB: $MATLAB_BIN"
echo

if [[ "$INCLUDE_INTEGRATION" == "1" ]]; then
    TEST_DIRS="{'tests/unit', 'tests/integration'}"
    echo "Scope: tests/unit + tests/integration"
else
    TEST_DIRS="'tests/unit'"
    echo "Scope: tests/unit (use --integration to also run tests/integration)"
fi
echo

MATLAB_CMD="addpath(genpath(pwd)); results = runtests($TEST_DIRS); disp(results); if any([results.Failed]) || any([results.Incomplete]); fprintf(2, '\nFAIL: %d failed / %d incomplete\n', sum([results.Failed]), sum([results.Incomplete])); exit(1); end; fprintf('\nOK: %d tests passed\n', numel(results));"

"$MATLAB_BIN" -batch "$MATLAB_CMD"
