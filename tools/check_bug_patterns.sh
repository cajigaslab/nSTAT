#!/usr/bin/env bash
#
# tools/check_bug_patterns.sh — sibling-bug pattern audit.
#
# Introduced for the 2026-05-20 comprehensive codebase audit (Phase D2.1).
#
# Greps every .m file in the repo for known-bad patterns drawn from
# previously-fixed bugs (the "bug families" of Phase 0–4 and the 2026-03-10
# audit). Any match in a non-allowlisted file is a candidate sibling defect
# that should be inspected.
#
# Exit code: 0 (always — this is a diagnostic that writes a report for
# human triage; it does not gate releases. Candidate matches include
# `% FIX:` comment text and deprecation-shim warning strings and need
# human review.)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# .m files to search: everything except generated, tests for the audit
# tools themselves, and vendored copies.
SCOPE=(
  --include='*.m'
  --exclude-dir='helpfiles'
  --exclude-dir='tests'
  --exclude-dir='docs'
  --exclude-dir='fixtures'
  --exclude-dir='tools/python'
  --exclude-dir='+nstat/+baseline'
)

REPORT="${1:-/dev/stdout}"

total_matches=0
section() {
  echo
  echo "## $1"
}

check_pattern() {
  local label="$1"
  local pattern="$2"
  local matches
  if matches=$(grep -nE "${SCOPE[@]/#/}" --include='*.m' -E "$pattern" -r . 2>/dev/null | grep -vE '(^|/)(tests|docs|fixtures|helpfiles|tools/python|\+nstat/\+baseline)/'); then
    if [[ -n "$matches" ]]; then
      section "$label"
      echo "Pattern: \`$pattern\`"
      echo
      echo '```'
      echo "$matches"
      echo '```'
      local count
      count=$(echo "$matches" | wc -l | tr -d ' ')
      total_matches=$((total_matches + count))
    fi
  fi
}

{
  echo "# Bug-pattern audit — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "Sibling-bug pattern audit (introduced for the 2026-05-20 codebase audit, Phase D2.1)."
  echo

  # Bernoulli LL: (1-y).*(1-... should be (1-y).*log(1-...
  check_pattern "Bernoulli LL missing log() wrap" '\(1\s*-\s*y\)\s*\.\*\s*\(1\s*-'

  # isa(_, 'nan') always false — should be isnan()
  check_pattern "isa(x,'nan') always-false" "isa\([^,]+,\s*'nan'\)"

  # eval() survivors (the original audit converted 22)
  check_pattern "eval() survivors (should be feval or refactor)" '(^|[^a-zA-Z_])eval\('

  # histc() — deprecated since R2015a, replaced by histcounts
  check_pattern 'histc() deprecated' '(^|[^a-zA-Z_])histc\('

  # roundn() — Mapping Toolbox dependency
  check_pattern 'roundn() Mapping Toolbox dependency' '(^|[^a-zA-Z_])roundn\('

  # rng('shuffle') — breaks reproducibility
  check_pattern "rng('shuffle') reproducibility break" "rng\(\s*'shuffle'"

  # sampeRate typo (missing 'l')
  check_pattern 'sampeRate typo (missing l)' 'sampeRate'

  # symvar() — reorders alphabetically (CIF compiled-handle bug family)
  check_pattern 'symvar() reorder hazard' '(^|[^a-zA-Z_])symvar\('

  # log(0) — explicit
  check_pattern 'log(0) literal' 'log\s*\(\s*0\s*\)'

  # Silent catch: lone "catch" with no exception capture
  check_pattern 'silent catch (no exception captured)' '^[[:space:]]*catch[[:space:]]*$'

  # ld.^2 / .^3 mix-up family (third-moment Poisson)
  check_pattern 'ExplambdaDeltaCubed should be .^3 not .^2 (review context)' 'ExplambdaDeltaCubed.*\.\^2'

  # FitResult multi-result .data without (:, i) indexing
  check_pattern 'multi-result data ungated by loop var (.data\b not followed by (:,)' '\.data\b(?![ \t]*\()'

  # Direct DecodingAlgorithms static call from new code (should use nstat.decoding.*)
  check_pattern 'DecodingAlgorithms.* static call from app code' 'DecodingAlgorithms\.(PPDecode|PPHybrid|PPSS|mPPCO|PPLFP)_'

  echo
  echo "## Summary"
  echo
  echo "Total candidate matches across all patterns: **$total_matches**"
  echo
  echo "Note: matches are *candidates*; some patterns have legitimate uses (e.g., "
  echo "\`eval(\` inside backwards-compat shims, \`DecodingAlgorithms.*\` calls in"
  echo "the facade itself or in cross-language parity tests). Human triage required."
} > "$REPORT"

if [[ "$REPORT" != "/dev/stdout" ]]; then
  echo "Wrote $REPORT (total candidate matches: $total_matches — review report for triage)"
fi

# Always exit 0: this script is diagnostic. The 2026-05-20 audit triaged
# every pattern and confirmed all matches are either comment text (% FIX:
# tags) or intentional code (deprecation shim warnings). Use the report to
# spot-check after substantial refactors; do not gate releases on it.
exit 0
