#!/usr/bin/env bash
#
# tools/resolve_latest_matlab.sh — resolve the newest installed MATLAB.
#
# Maintainer policy: test nSTAT gates/probes on the latest installed
# MATLAB only (no fixed-version pin that silently goes stale as new
# releases are installed). Prints the bin/matlab path of the newest
# /Applications/MATLAB_R20XXy.app found, or nothing (and returns 1) if
# none are installed. MATLAB_BIN / --matlab-path at each call site still
# override this -- this only supplies the DEFAULT.
#
# Usage (sourced):
#   source "$(dirname "$0")/resolve_latest_matlab.sh"
#   MATLAB_BIN="${MATLAB_BIN:-$(resolve_latest_matlab_bin)}"

resolve_latest_matlab_bin() {
    local candidates=(/Applications/MATLAB_R[0-9][0-9][0-9][0-9][ab].app)
    if [[ ! -e "${candidates[0]}" ]]; then
        return 1
    fi
    # RYYYYa < RYYYYb < R(YYYY+1)a lexicographically, so a plain sort
    # correctly orders these (e.g. R2025b < R2026a).
    local newest
    newest="$(printf '%s\n' "${candidates[@]}" | sort | tail -1)"
    echo "$newest/bin/matlab"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    resolve_latest_matlab_bin
fi
