# 2026-05-20 — Comprehensive Codebase Audit & Deploy-Gate Plan

**Owner:** Iahn Cajigas
**Status:** PROPOSED
**Companion plans (already executed):**
- [2026-05-19 nSTAT review action plan](2026-05-19-nstat-review-action-plan.md) — Phase 0–4 modernization (bug fixes, deprecation shims, +nstat/+decoding/ refactor)
- [2026-05-20 deep-dive verification](2026-05-20-deep-dive-verification.md) — V0–V4 verified all examples + tests
- [2026-05-20 pre-mod ground-truth regression](2026-05-20-pre-mod-ground-truth-regression.md) — 19 IDENTICAL outputs, 0 regressions
- [2026-05-20 README figure parity](2026-05-20-readme-figure-parity.md) — PR #42 (gallery regen + drift detector)

## 1. Strategic position first

A new "comprehensive audit" that re-treads any of the above is pure churn. **The four prior plans, combined, already cover:** point-process correctness (Bernoulli LL, KS clamp, DT branch, time-indexing, RNG seeding), architectural cleanup (47 deprecation shims + 8 cluster classes + LinearCIF + Defaults), example coverage (5 paper examples + 18 helpfile verifications), pre-modernization regression testing (19/19 outputs match), and README gallery integrity (drift detector with allowlist).

The genuine remaining gaps fall into four buckets:

1. **Help-system integrity** — 38 helpfile `.m` files, 38 `.html` siblings, 24 `.mlx` files (5 deleted + 1 paper-ref exception), 1 `helptoc.xml`. Nothing currently audits cross-consistency between these four artifacts: is every `helptoc.xml` `target=` pointing at an existing file? Is every `.html` regenerated from the *current* `.m`? Are there orphan `.html` files with no `.m` master? Does `builddocsearchdb` index everything that's user-visible?
2. **Cross-document drift** — six surfaces document the toolbox: `README.md`, `AGENT_GUIDE.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `Contents.m`, `helptoc.xml`. Each references files/symbols that may have moved. Spot-checks already known: `Contents.m` line 2 says "Version 1.2 11-Mar-2026" (predates Phase 3); `AGENT_GUIDE.md` §9.1 says "`DecodingAlgorithms.m` is a 10860-line single classdef" (it is now 1189 lines, a thin facade); `helpfiles/nSTATPaperExamples.mlx` is now an explicit policy exception (CONTRIBUTING.md), but `AUDIT_REPORT.md` may still describe the old state.
3. **Static-analysis sibling-bug hunt** — every fix landed in Phase 0–4 has a *bug family*. The fixes addressed the surfaced instance; sibling instances of the same pattern in adjacent files have not been systematically swept. Targeted `grep` over known patterns will flush them out: `(1-y).*(1-` without `log()` wrap, `isa(.*'nan')`, `eval()` survivors, `histc()` survivors, `roundn()` survivors, `rng('shuffle'` survivors, hard-coded `sampleRate` as bin width, `symvar()` callers, `sampeRate` typo siblings.
4. **One-command deploy gate** — eight separate `tools/` scripts exist. A release engineer must remember to run them in the right order. A single `tools/predeploy.sh` (or equivalent) that runs unit tests → integration tests → README figure parity → HTML republish → helptoc lint → search-index rebuild and returns 0/non-zero would make every release reproducible without tribal knowledge.

This plan addresses exactly those four buckets and nothing else. Effort: ~12–18 hours total, sequenced over 2–3 days.

## 2. Phase D0 — Help-system integrity audit

The MATLAB help system has four coupled artifacts. Each needs verification.

### D0.1 — helptoc.xml ↔ .html target validation

Every `<tocitem target="X.html">` in `helpfiles/helptoc.xml` must resolve to an existing `helpfiles/X.html`. Write a single shell + Python (or awk) script that:

```python
import xml.etree.ElementTree as ET
from pathlib import Path
root = ET.parse('helpfiles/helptoc.xml').getroot()
helpdir = Path('helpfiles')
broken = []
for item in root.iter('tocitem'):
    target = item.get('target')
    if target and not (helpdir / target).exists():
        broken.append((target, item.text.strip() if item.text else ''))
```

Output: `docs/verification/helpsystem_audit.md` Section D0.1 with a table of `target → exists? → matched title`.

**Acceptance:** zero broken targets. Fix shape if any exist: either regenerate the missing `.html` from its `.m` sibling, or remove the stale `<tocitem>` from `helptoc.xml`.

**Effort:** 30 min.

### D0.2 — .m ↔ .html staleness audit

For every `helpfiles/*.m`, find its `.html` sibling and compare modification timestamps via `git log -1 --format=%ai`. If `.m` is newer than `.html`, the `.html` is stale (published HTML doesn't reflect current `.m`).

**Acceptance:** every `.m` ≤ `.html`'s git timestamp, OR a documented exception with rationale (e.g., the `.m` was edited only for comment changes — verify via `git diff`).

**Fix shape for true staleness:** run `tools/publish_examples.m` to regenerate the `.html` (and embedded PNG outputs). Commit as a single docs commit.

**Effort:** 1–2 hours (the audit script is 15 min; remediation depends on count).

### D0.3 — Orphan detection

- `.html` files with no `.m` sibling — historical artifacts that should be deleted.
- `.m` files not referenced from `helptoc.xml` — either need adding to the TOC or are intentionally private (verify and document).
- `.png` files (228 of them) not referenced from any `.html` — disk bloat candidates.

**Acceptance:** every orphan classified as "delete", "add to TOC", or "intentional".

**Effort:** 1–2 hours.

### D0.4 — Search-index regeneration

`builddocsearchdb('helpfiles')` rebuilds the MATLAB help-search database (`helpfiles/helpsearch-v4_0/`). Verify:

1. The current `helpsearch-v4_0/` is tracked in git or generated at install time (check `nSTAT_Install.m`).
2. Rebuilding it produces output consistent with what's committed.
3. The rebuild is invoked by the installer (`nSTAT_Install('RebuildDocSearch', true)`).

**Acceptance:** documented in [CONTRIBUTING.md](../../CONTRIBUTING.md) that the search DB is regenerated at install time, not maintained in tree.

**Effort:** 30 min.

## 3. Phase D1 — Cross-document drift audit

Six surfaces document the toolbox. Audit each for stale references.

### D1.1 — Contents.m

Currently line 2: `Version 1.2 11-Mar-2026`. Stale. The Phase 3 +nstat/+decoding/ refactor and Phase 4 PPAF iterated update are not reflected. Audit:

- Version stamp current?
- Listed classes match what exists in tree?
- Listed packages mention `+nstat/+decoding/` and `+nstat/+plotting/`?
- Reference to README.md still valid?

**Fix shape:** rewrite `Contents.m` to enumerate the canonical class list (mirroring the `classdef` files in repo root) and the `+nstat/` packages. Bump version stamp to current date + a meaningful version number.

**Effort:** 30 min.

### D1.2 — AGENT_GUIDE.md sweep

Known stale items already identified:
- §9.1: "`DecodingAlgorithms.m` is a 10860-line single classdef" — it's now 1189 lines, a thin facade with 47 deprecation shims. Update the entire §9.1 to describe the new structure.

Look for more stale references via:

```bash
grep -nE 'DecodingAlgorithms|10860|symbolic toolbox|mPPCO' AGENT_GUIDE.md
```

**Effort:** 1 hour.

### D1.3 — README.md sweep

The "Code audit (2026-03-10)" section (line 133+) describes the original 67-bug audit. Now there is also Phase 0–4 plus README figure parity. The section should either:

- Stay as historical record (with timestamp clarification), or
- Be supplemented with a "Code audit (2026-05)" section listing the more recent waves.

**Acceptance:** README's audit narrative is current as of the latest PR merge.

**Effort:** 30 min.

### D1.4 — AUDIT_REPORT.md

Was generated 2026-03-10 alongside the 67-bug audit. Likely describes the *pre-modernization* state. Decide:

- Mark as historical (top banner: "Reflects state as of 2026-03-10; see Phase 0–4 plans for subsequent fixes") and leave content, OR
- Append a section summarizing Phase 0–4 + 2026-05 follow-ups.

**Effort:** 30 min.

### D1.5 — CONTRIBUTING.md + CLAUDE.md consistency

After PR #42 merges:
- CONTRIBUTING.md has full "README figure parity" section.
- CLAUDE.md (gitignored) has a pointer.

Audit: are there other policies that drifted between the two? Specifically the `.m`-is-canonical policy (added 2026-05-19) — verify it's not duplicated or contradicted.

**Effort:** 15 min.

### D1.6 — Acceptance gate for Phase D1

- [ ] Each of the six surfaces (README, AGENT_GUIDE, CONTRIBUTING, CLAUDE, Contents.m, helptoc.xml) has zero stale references to deleted/renamed files or pre-Phase-3 line counts.
- [ ] All version stamps updated to "post-2026-05-20".
- [ ] Single docs commit lands the sweep.

## 4. Phase D2 — Static-analysis sibling-bug hunt

Every fix from Phase 0–4 belongs to a *family*. We fixed the instance that surfaced; this phase hunts siblings.

### D2.1 — Pattern catalogue

Build a `grep`-able pattern table:

| Bug family | Pattern | Already fixed instance | Search scope |
|---|---|---|---|
| Bernoulli LL missing `log()` wrap | `(1-y).*\(1-` not followed by `\)\.` containing `log` | `acd57c7`, `d1e96cf` | `FitResult.m`, `Analysis.m`, `+nstat/+decoding/*` |
| `isa(.,'nan')` always false | `isa\([^,]+,\s*'nan'\)` | Original audit | All `.m` |
| `eval()` survivors | `^[^%]*\beval\(` (exclude `feval`) | Original audit (22 → `feval`) | All `.m` |
| `histc()` deprecated | `\bhistc\(` | Original audit | All `.m` |
| `roundn()` Mapping dep | `\broundn\(` | Original audit (7) | All `.m` |
| `rng('shuffle'` reproducibility break | `rng\(\s*'shuffle'` | `f2307e9` | All `.m` |
| `symvar()` reorder bug | `\bsymvar\(` | Original audit | All `.m` |
| Hard-coded `sampleRate` as bin width | `sampleRate.*binWidth` or `binWidth.*sampleRate` | Original audit (FitResult KS) | All `.m` |
| Multi-result data indexing | `\.data\b(?!\s*\(:,)` | `1520034` | `FitResult.m`, `Analysis.m` |
| Time-indexing in PPAF/PPHF | `PPDecode.*goal` and `PPHybrid.*goal` | `3ffebd5`, `1bcb63e`, `ba7069a`, `bc5f879` | `+nstat/+decoding/PPAF.m`, `PPHF.m`, `DecodingAlgorithms.m` (shims) |
| `sampeRate` typo (missing 'l') | `sampeRate` | `6f6eb13` | All `.m` |
| Silent `catch` without exception | `^\s*catch\s*$` or `catch\s*%` | Original audit (11) | All `.m` |
| `log(0)` guard missing | `log\s*\(\s*0\s*\)` or `log\s*\([^)]*\)` near zero check | Original audit (3 fixed) | All `.m` |

Write `tools/check_bug_patterns.sh` that greps all of the above, outputs a report.

### D2.2 — `checkcode` / `mlint` sweep

MATLAB's built-in linter has had years of improvements. Run:

```matlab
results = checkcode('-fullpath', dir(fullfile(repoRoot, '**', '*.m')));
```

Triage warnings by severity. Filter for actionable ones (deprecated function use, possible bugs, definite errors). Ignore stylistic ones unless they cluster around a single class.

**Acceptance:** every checkcode warning at severity ≥ "definite error" or "deprecated" is classified as fix / suppress-with-justification / accept.

**Effort:** 2–4 hours.

### D2.3 — Symbolic toolbox dependency audit

Phase 3.5 added `LinearCIF` to eliminate Symbolic Math Toolbox dependency. Verify:

```bash
grep -rn 'symbolic\|sym(\|matlabFunction\|symvar' --include='*.m' | grep -v -E '^(tests/|docs/|tools/python/|helpfiles/.*\.html)'
```

Any remaining uses outside `CIF.m` (which is the legacy symbolic-CIF) need either:
- Migration to `LinearCIF` (preferred), or
- Documented justification.

**Effort:** 1–2 hours.

### D2.4 — Acceptance gate for Phase D2

- [ ] `tools/check_bug_patterns.sh` exists, runs, produces a report.
- [ ] Zero findings in the report (after sibling-bug fixes if any), OR documented allowlist for false positives.
- [ ] `checkcode` definite-error/deprecated count is documented; each item is fix/suppress/accept.
- [ ] Symbolic dependency outside `CIF.m` is documented (zero is ideal; some may be legitimate).

## 5. Phase D3 — One-command deploy gate

Currently a release engineer runs eight separate scripts in tribal order. Consolidate.

### D3.1 — `tools/predeploy.sh`

Single shell script that executes, in order, and short-circuits on first failure:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1) Unit + integration tests
tools/run_unit_tests.sh --integration

# 2) README figure parity (regen + diff)
tools/check_readme_figures.sh

# 3) Helpfile HTML republish (publishes every .m → .html and verifies diff)
matlab -batch "addpath(genpath('.')); tools.publish_examples('CheckParity', true);"

# 4) helptoc.xml lint (target= validation)
python3 tools/lint_helptoc.py

# 5) Bug-pattern audit
tools/check_bug_patterns.sh

# 6) Code-style audit (checkcode summary)
matlab -batch "addpath(genpath('.')); checkcode_summary = tools.runCheckcode(); exit(any([checkcode_summary.severity]>=4))"

echo "predeploy gate PASSED."
```

**Effort:** 1–2 hours (mostly orchestration; individual checks exist or are being written in D0–D2).

### D3.2 — Version + manifest stamping

Add `tools/stamp_release.m` that:
- Reads a target version from CLI argv.
- Updates `Contents.m` line 2 (`% Version X.Y date`).
- Writes `RELEASE_NOTES.md` template if missing for that version.
- Updates `docs/figures/manifest.json` regeneration timestamp.
- Tags the git ref.

**Acceptance:** every tagged release `vX.Y.Z` has a corresponding `Contents.m` version stamp and `RELEASE_NOTES.md` entry.

**Effort:** 1 hour.

### D3.3 — Pre-tag hook (optional, opt-in)

Document in CONTRIBUTING.md a `.git/hooks/pre-tag` template that runs `tools/predeploy.sh` before allowing a `git tag` to complete. Opt-in per developer (the same convention as the existing pre-push hook).

**Effort:** 15 min.

### D3.4 — Acceptance gate for Phase D3

- [ ] `tools/predeploy.sh` exists, exits 0 on a clean tree.
- [ ] `tools/stamp_release.m` exists, smoke-tested with a dry-run.
- [ ] CONTRIBUTING.md documents the pre-deploy workflow.
- [ ] At least one full dry-run of the gate on the current master.

## 6. Phase D4 — Codify in CLAUDE.md / CONTRIBUTING.md

Add a "Release & regeneration" section to **CONTRIBUTING.md** (the canonical, tracked source — recall CLAUDE.md is `.gitignore`'d):

```markdown
### Release & regeneration

Before tagging any release vX.Y.Z, the release engineer runs:

```bash
tools/predeploy.sh
```

This invokes, in order: unit + integration tests, README figure parity,
helpfile HTML republish, helptoc.xml lint, bug-pattern audit, and
checkcode style audit. The script exits non-zero on any failure.

After the gate passes:

```matlab
tools.stamp_release('vX.Y.Z')   % updates Contents.m + RELEASE_NOTES.md
```

The output is then committed and tagged:

```bash
git add Contents.m RELEASE_NOTES.md docs/figures/manifest.json
git commit -m "release(vX.Y.Z): stamp version + manifest"
git tag vX.Y.Z
git push origin master --tags
```

What gets regenerated and committed at release time:
- `docs/figures/exampleNN/*.png` (paper-example gallery — see "README
  figure parity" above for the policy and triage rubric).
- `helpfiles/*.html` (re-published from `.m` via `publish()`).
- `helpfiles/helpsearch-v4_0/` (rebuilt by `nSTAT_Install` at install
  time; tracked in tree as a convenience).
- `Contents.m` version stamp.
- `docs/figures/manifest.json` `generated_at` field.

What stays manual (NOT regenerated):
- `helpfiles/nSTATPaperExamples.mlx` — paper-reference exception (see
  ".m is canonical" section above).
- `AUDIT_REPORT.md` — historical record of the 2026-03-10 audit.
- `README.md` body prose (only the table of figure thumbnails, embedded
  by relative path, is auto-current).
```

Add a brief pointer in **CLAUDE.md** (local-only):

```markdown
## Release & regeneration

Canonical procedure: [CONTRIBUTING.md](CONTRIBUTING.md) "Release & regeneration".

One-liner: `tools/predeploy.sh && matlab -batch "tools.stamp_release('vX.Y.Z')"`.
```

Add a "What gets regenerated" pointer to **AGENT_GUIDE.md** §7.

**Effort:** 30 min.

### D4 acceptance gate

- [ ] CONTRIBUTING.md has the "Release & regeneration" section.
- [ ] AGENT_GUIDE.md §7 has a cross-link.
- [ ] CLAUDE.md (local) has the pointer.

## 7. Sequencing and total effort

```
Phase D0 (help-system integrity)        2026-05-21  →  3–4 hours
Phase D1 (cross-document drift)         2026-05-21  →  3–4 hours  (can parallelize with D0)
Phase D2 (static-analysis bug hunt)     2026-05-22  →  3–5 hours
Phase D3 (deploy gate)                  2026-05-23  →  2–4 hours
Phase D4 (codify policy)                2026-05-23  →  30 min
                                                    ──────────
                                        TOTAL          12–18 hours
                                        WALL CLOCK     2–3 days
```

Phase ordering rationale: D0 + D1 surface what needs regenerating, D2 may surface bugs that need fixing before the gate is meaningful, D3 builds the gate, D4 codifies.

## 8. What this plan deliberately does NOT do

To prevent scope creep:

- **Does NOT re-audit Phase 0–4 bug fixes.** Those were verified by the 2026-05-20 deep-dive verification.
- **Does NOT re-run pre-modernization regression.** Already done; 19/19 IDENTICAL.
- **Does NOT re-verify the README gallery.** PR #42 (this conversation) handled it.
- **Does NOT add new toolbox features.** Audit-and-codify only.
- **Does NOT touch the Python port** (`nSTAT-python` is a separate repo).
- **Does NOT add MATLAB CI.** The license-based decision against CI MATLAB stands.

## 9. Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Phase D2 surfaces a real bug that Phase D3 must wait on | MEDIUM | Each D2 finding becomes a small surgical PR; D3 plan adapts to its surface count. |
| `publish_examples` HTML regen produces gratuitously-different HTML (e.g., timestamp in `<meta>`) that flips every `.html` diff | LOW-MEDIUM | Diff in a normalized fashion (strip timestamps + auto-IDs) before comparison. |
| `checkcode` produces hundreds of warnings, most stylistic | HIGH | Triage by severity at the start; document the ignored stylistic categories rather than rejecting the audit. |
| Deploy gate is slow (~15 min total) | MEDIUM | It runs at *release time*, not pre-push. The pre-push gate stays fast (unit tests only). |
| Help-system audit reveals `helptoc.xml` has been silently broken for months | MEDIUM | This is a finding, not a failure mode — fix it as part of D0.1, document in commit. |

## 10. Acceptance criteria for the plan itself (this document)

- [x] Acknowledges prior plans + delineates non-overlapping scope (Section 1).
- [x] Names the four genuine gaps and addresses each in a dedicated phase (D0–D3).
- [x] Specifies a tracked-file canonical home (CONTRIBUTING.md), with CLAUDE.md as a pointer per the established pattern.
- [x] Total effort fits in 2–3 days; no single phase exceeds 1 day.
- [x] Explicit "what we are NOT doing" section (Section 8).

## 11. Exit criteria for the overall audit

- [ ] D0–D4 phases all reach their acceptance gates.
- [ ] `tools/predeploy.sh` runs clean on master.
- [ ] `docs/verification/helpsystem_audit.md` exists with current numbers.
- [ ] `docs/verification/bug_pattern_audit.md` exists with current numbers.
- [ ] `Contents.m` version stamp ≥ 2026-05-20.
- [ ] One PR (or a small sequence of related PRs) merged to `master`.
- [ ] This plan transitions to status `COMPLETED`.

## 12. Suggested execution order

1. Merge PR #42 (already open from the prior turn — the README figure parity work). The deploy gate in D3.1 calls `tools/check_readme_figures.sh`, which lives in that PR.
2. Open a new branch `audit/comprehensive-2026-05-21` from master after #42 merges.
3. Execute D0 + D1 in parallel (independent file sets).
4. Execute D2 — fix any sibling bugs as small atomic commits on the audit branch.
5. Execute D3 — build the deploy gate, run it end-to-end.
6. Execute D4 — single docs commit codifying the policy.
7. Open a single PR covering D0–D4 changes (or split D2 fixes into separate PRs if non-trivial).
