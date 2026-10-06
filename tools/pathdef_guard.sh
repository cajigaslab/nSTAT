#!/usr/bin/env bash
#
# tools/pathdef_guard.sh — snapshot/verify guard for MATLAB's pathdef.m files.
#
# Protects against issue #140: an automated release-gate run must never
# persist MATLAB's search path (savepath), because that rewrites the
# MACHINE-WIDE toolbox/local/pathdef.m (and the per-user pathdef.m under
# userpath), neither of which is tracked in this repo. The v1.6.0 release
# gate did exactly this (nSTAT_Install's unconditional savepath -- see
# the SavePath option added to nSTAT_Install.m / #140).
#
# This guard does not prevent that on its own (nSTAT_Install('SavePath',
# false) is the actual fix); it is a second line of defense that FAILS
# the gate run loudly if pathdef.m changed for any reason during it.
#
# Usage (sourced -- this is how tools/predeploy.sh uses it):
#   source "$(dirname "$0")/pathdef_guard.sh"
#   pathdef_guard_snapshot "$MATLAB_BIN"
#   ...run gates...
#   pathdef_guard_verify || exit 1
#
# Usage (standalone CLI, e.g. for the fail/pass demonstration):
#   tools/pathdef_guard.sh snapshot /Applications/MATLAB_R2026a.app/bin/matlab
#   tools/pathdef_guard.sh verify
# State is persisted across standalone invocations in a state file (default
# under $TMPDIR, override with PATHDEF_GUARD_STATE_FILE).

_pathdef_guard_hash() {
    local f="$1"
    if [[ ! -f "$f" ]]; then
        echo "ABSENT"
        return
    fi
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$f" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$f" | awk '{print $1}'
    else
        echo "ERROR: neither shasum nor sha256sum found" >&2
        echo "NO_HASH_TOOL"
    fi
}

# Resolve matlabroot/userpath via one short -batch call; sets
# PATHDEF_GUARD_SYSTEM_FILE and PATHDEF_GUARD_USER_FILE ("" if no userpath).
_pathdef_guard_resolve_paths() {
    local matlab_bin="$1"
    local out
    out="$("$matlab_bin" -batch "fprintf('NSTAT_PATHDEF_GUARD_MATLABROOT=%s\n', matlabroot); up = userpath; up = regexprep(up, ';+\$', ''); fprintf('NSTAT_PATHDEF_GUARD_USERPATH=%s\n', up);" 2>/dev/null)"
    local matlabroot_val
    matlabroot_val="$(echo "$out" | sed -n 's/^NSTAT_PATHDEF_GUARD_MATLABROOT=//p')"
    if [[ -z "$matlabroot_val" ]]; then
        echo "ERROR: pathdef_guard could not resolve matlabroot via $matlab_bin" >&2
        return 1
    fi
    PATHDEF_GUARD_SYSTEM_FILE="$matlabroot_val/toolbox/local/pathdef.m"
    local userpath_dir
    userpath_dir="$(echo "$out" | sed -n 's/^NSTAT_PATHDEF_GUARD_USERPATH=//p')"
    if [[ -n "$userpath_dir" ]]; then
        PATHDEF_GUARD_USER_FILE="$userpath_dir/pathdef.m"
    else
        PATHDEF_GUARD_USER_FILE=""
    fi
}

_pathdef_guard_state_file() {
    echo "${PATHDEF_GUARD_STATE_FILE:-${TMPDIR:-/tmp}/nstat_pathdef_guard_state}"
}

# Snapshot the current hashes. Call BEFORE running any gate.
pathdef_guard_snapshot() {
    local matlab_bin="$1"
    _pathdef_guard_resolve_paths "$matlab_bin" || return 1

    PATHDEF_GUARD_SYSTEM_HASH_BEFORE="$(_pathdef_guard_hash "$PATHDEF_GUARD_SYSTEM_FILE")"
    if [[ -n "$PATHDEF_GUARD_USER_FILE" ]]; then
        PATHDEF_GUARD_USER_HASH_BEFORE="$(_pathdef_guard_hash "$PATHDEF_GUARD_USER_FILE")"
    else
        PATHDEF_GUARD_USER_HASH_BEFORE="ABSENT"
    fi

    {
        echo "SYSTEM_FILE=$PATHDEF_GUARD_SYSTEM_FILE"
        echo "SYSTEM_HASH_BEFORE=$PATHDEF_GUARD_SYSTEM_HASH_BEFORE"
        echo "USER_FILE=$PATHDEF_GUARD_USER_FILE"
        echo "USER_HASH_BEFORE=$PATHDEF_GUARD_USER_HASH_BEFORE"
    } > "$(_pathdef_guard_state_file)"

    echo "pathdef guard: snapshotted"
    echo "  system pathdef.m: $PATHDEF_GUARD_SYSTEM_FILE"
    echo "    hash: $PATHDEF_GUARD_SYSTEM_HASH_BEFORE"
    if [[ -n "$PATHDEF_GUARD_USER_FILE" ]]; then
        echo "  user pathdef.m  : $PATHDEF_GUARD_USER_FILE"
        echo "    hash: $PATHDEF_GUARD_USER_HASH_BEFORE"
    else
        echo "  user pathdef.m  : (no userpath configured; nothing to track)"
    fi
}

# Verify the hashes are unchanged. Call AFTER running the gates. Returns
# (via $?) nonzero if either file changed, printing a loud error.
pathdef_guard_verify() {
    # Reload state if this is a fresh shell (standalone CLI usage).
    if [[ -z "${PATHDEF_GUARD_SYSTEM_FILE:-}" ]]; then
        local state_file
        state_file="$(_pathdef_guard_state_file)"
        if [[ ! -f "$state_file" ]]; then
            echo "ERROR: pathdef_guard_verify called with no prior snapshot ($state_file missing)" >&2
            return 2
        fi
        # NOTE: deliberately not `source <(...)` -- macOS's bash 3.2
        # (/bin/bash) has a race on process-substitution FIFOs that makes
        # `source` read an empty stream intermittently. Parse the (tiny,
        # trusted, locally-written) state file by hand instead.
        local line key value
        while IFS= read -r line; do
            key="${line%%=*}"
            value="${line#*=}"
            case "$key" in
                SYSTEM_FILE) PATHDEF_GUARD_SYSTEM_FILE="$value" ;;
                SYSTEM_HASH_BEFORE) PATHDEF_GUARD_SYSTEM_HASH_BEFORE="$value" ;;
                USER_FILE) PATHDEF_GUARD_USER_FILE="$value" ;;
                USER_HASH_BEFORE) PATHDEF_GUARD_USER_HASH_BEFORE="$value" ;;
            esac
        done < "$state_file"
    fi

    local failed=0
    local system_hash_after
    system_hash_after="$(_pathdef_guard_hash "$PATHDEF_GUARD_SYSTEM_FILE")"
    if [[ "$system_hash_after" != "$PATHDEF_GUARD_SYSTEM_HASH_BEFORE" ]]; then
        echo "ERROR: pathdef guard: $PATHDEF_GUARD_SYSTEM_FILE changed" >&2
        echo "       before: $PATHDEF_GUARD_SYSTEM_HASH_BEFORE" >&2
        echo "       after : $system_hash_after" >&2
        failed=1
    fi

    if [[ -n "$PATHDEF_GUARD_USER_FILE" ]]; then
        local user_hash_after
        user_hash_after="$(_pathdef_guard_hash "$PATHDEF_GUARD_USER_FILE")"
        if [[ "$user_hash_after" != "$PATHDEF_GUARD_USER_HASH_BEFORE" ]]; then
            echo "ERROR: pathdef guard: $PATHDEF_GUARD_USER_FILE changed" >&2
            echo "       before: $PATHDEF_GUARD_USER_HASH_BEFORE" >&2
            echo "       after : $user_hash_after" >&2
            failed=1
        fi
    fi

    if [[ "$failed" -eq 1 ]]; then
        echo "A gate run rewrote MATLAB's pathdef.m. This must never happen from an" >&2
        echo "automated run (issue #140) -- investigate before proceeding." >&2
        return 1
    fi
    echo "pathdef guard: OK (unchanged)"
    return 0
}

# --- Standalone CLI entry point --------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
    case "${1:-}" in
        snapshot)
            pathdef_guard_snapshot "${2:?usage: pathdef_guard.sh snapshot <matlab_bin>}"
            ;;
        verify)
            pathdef_guard_verify
            ;;
        *)
            echo "usage: $0 {snapshot <matlab_bin>|verify}" >&2
            exit 2
            ;;
    esac
fi
