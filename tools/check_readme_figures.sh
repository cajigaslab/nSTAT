#!/usr/bin/env bash
#
# tools/check_readme_figures.sh — README paper-example figure parity gate.
#
# Regenerates the docs/figures/ paper-example gallery via
# build_paper_examples into a temp directory, then pixel-diffs every
# produced PNG against the committed file under docs/figures/.
#
# Errors if any figure has SUBSTANTIVE drift (mean |Δ| >= 0.5 in [0,255]
# space) or is missing in the regen output.
#
# CI does NOT run MATLAB. This script must be run locally before pushing
# changes that touch the README figure dependency set (see project
# CLAUDE.md "README figure parity" section).
#
# Usage:
#   tools/check_readme_figures.sh
#   tools/check_readme_figures.sh --matlab-path /Applications/MATLAB_R2024b.app
#   MATLAB_BIN=/Applications/MATLAB_R2024b.app/bin/matlab tools/check_readme_figures.sh
#
# Exit codes:
#   0  no SUBSTANTIVE drift (figures match current code output)
#   1  SUBSTANTIVE drift detected, or MATLAB errored
#   2  MATLAB binary not found / configuration problem

set -euo pipefail

MATLAB_BIN="${MATLAB_BIN:-/Applications/MATLAB_R2026a.app/bin/matlab}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --matlab-path)
            MATLAB_BIN="$2/bin/matlab"
            shift 2
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

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "Checking nSTAT README figure parity from $REPO_ROOT"
echo "MATLAB: $MATLAB_BIN"
echo "(this regenerates ~27 PNGs; allow ~5-10 minutes)"
echo

MATLAB_CMD="addpath(genpath(pwd)); report = check_readme_figures('FailOnDrift', true);"

"$MATLAB_BIN" -batch "$MATLAB_CMD"
