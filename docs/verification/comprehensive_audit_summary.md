# Comprehensive Codebase Audit — Summary (2026-05-20)

> Companion to [`docs/superpowers/plans/2026-05-20-comprehensive-codebase-audit.md`](../superpowers/plans/2026-05-20-comprehensive-codebase-audit.md).
>
> Per-phase reports:
> - D0 (help-system integrity): [`helpsystem_audit.md`](helpsystem_audit.md)
> - D2.1 (bug-pattern audit): [`bug_pattern_audit.md`](bug_pattern_audit.md)
> - D2.3 (Symbolic Math Toolbox audit): [`symbolic_dependency_audit.md`](symbolic_dependency_audit.md)

## What this audit found

### Phase D0 — Help-system integrity

- **D0.1 — helptoc.xml ↔ targets:** 33/33 file-path entries resolve. 2 external URLs (lab websites) intentionally exempt. **PASS.**
- **D0.2 — `.m` ↔ `.html` staleness:** 5 `.html` files older than their `.m` masters (`DecodingExample`, `DecodingExampleWithHist`, `HybridFilterExample`, `StimulusDecode2D`, `nSTATPaperExamples`). The `.m` files were edited 2026-05-20 (in this audit branch's parent merge work); the `.html` siblings predate that. Remediation: `publish_all_helpfiles` republishes all `.html` from `.m` in one canonical shot, also rebuilding the search index.
- **D0.3 — Orphans:**
  - 4 `.html` without `.m` sibling: `Analysis.html`, `SignalObj.html`, `FitResult.html` (legitimate class-reference pages published from repo-root classdefs by `publish_all_helpfiles`), `index.html` (redirect to `NeuralSpikeAnalysis_top.html`).
  - 7 `.m` not in `helptoc.xml`: 6 user-facing pages needed TOC entries (`AnalysisExamples2`, `ConfidenceIntervalOverview`, `FitResultReference`, `HelloNstat`, `HybridFilterExample`, `WhenToUseWhich`) plus 1 intentionally private helper (`publish_all_helpfiles`). Remediation: 8 new TOC entries (including a new "Analysis Reference" entry) added to `helpfiles/helptoc.xml`.
  - 67 unreferenced `.png` files (mostly `*_eq*.png` from older `publish()` runs that embedded equations differently): tracked for future cleanup, not blocking.
- **D0.4 — Search-index regeneration:** verified that `publish_all_helpfiles` calls `builddocsearchdb(helpDir)` and `rehash toolboxcache` at the end. Index lives at `helpfiles/helpsearch-v4_0/` and is regenerated as part of the canonical publish workflow.

### Phase D1 — Cross-document drift

Four tracked surfaces updated:

- **`Contents.m`** — bumped from "Version 1.2 11-Mar-2026" to "Version 1.4 20-May-2026". Now enumerates the `+nstat/+decoding/` package, `LinearCIF`, `History.raisedCosine`, and the canonical-link helpers. Tools section references `build_paper_examples` and `check_readme_figures`.
- **`AGENT_GUIDE.md`** — §1 PPLFP description updated (was: "implemented as `mPPCO_*` methods, poorly named"; now: "canonical implementation `nstat.decoding.PPLFP`, `mPPCO_*` are deprecation shims"). §2 requirements clause notes `LinearCIF` removes the symbolic-toolbox dependency at eval time. §4 class table updated for `Analysis`/`FitResult`/`DecodingAlgorithms` LOC (was 10860 for `DecodingAlgorithms`, now 1189; added `LinearCIF` row). §7 test list rewritten (now describes the 20 unit tests, the KS-oracle integration test, and the local test gate). §9.1 entirely rewritten from "10860-line single classdef" historical anecdote to current 1189-line facade + 8 cluster classes architecture.
- **`README.md`** — added "Phase 0–4 modernization (2026-05) and v1.4 release" section after the 2026-03-10 audit description. Lists Phase 0 fixes (Bernoulli LL, KS U-clamp, DT-branch, time-indexing), Phase 3 cluster decomposition, Phase 3.5/4 new capabilities, and the local-test-gate rationale.
- **`AUDIT_REPORT.md`** — added historical-status banner at the top pointing readers to the Phase 0–4 plan and this comprehensive audit for the *current* state.

**D1.5 — CONTRIBUTING vs CLAUDE consistency:** No conflicts. CONTRIBUTING.md is the canonical source for both `.m`-canonical and README-figure-parity policies; CLAUDE.md has brief pointers. Phase D4 added the new release policy to both files following the same pattern.

### Phase D2 — Static-analysis sibling-bug hunt

- **D2.1 — Bug-pattern audit (`tools/check_bug_patterns.sh`):** 102 candidate matches across 11 patterns. Triage in [`bug_pattern_audit.md`](bug_pattern_audit.md) shows **zero actionable sibling defects**. All matches are either: (a) `% FIX:` comment-text false positives (the regexes match comment lines documenting the fixes), (b) deprecation-shim warning strings inside `DecodingAlgorithms.m` itself, or (c) silent `catch` blocks in `tools/` infrastructure where the wrapped operation is genuinely optional (graphics API fallback, etc.).
- **D2.2 — `checkcode`/mlint sweep:** deferred pending MATLAB availability (the help republish was holding the license at audit-execution time). Tracked as a non-blocking follow-up.
- **D2.3 — Symbolic Math Toolbox audit (`symbolic_dependency_audit.md`):** `CIF.m` symbolic deps are intentional by design. `LinearCIF.m` has a partial-dependency at construction (`sym(Xnames)` to populate `varIn`/`stimVars`) but evaluates closed-form. No other `.m` files in core use Symbolic. **Documented exception**, not a defect.

### Phase D3 — One-command deploy gate

New scripts:

- **`tools/predeploy.sh`** — chains all six gates (unit tests, integration tests, README figure parity, helpfile publish + helptoc validation + search index, helptoc lint, bug-pattern audit). ~30–45 min wall clock. Flags `--skip-publish` and `--skip-readme` for iterative debugging.
- **`tools/stamp_release.m`** — updates `Contents.m` version stamp, bumps `docs/figures/manifest.json` `generated_at`, and inserts a `RELEASE_NOTES.md` template section. Idempotent. Supports `'DryRun', true`.
- **`tools/lint_helptoc.py`** — standalone helptoc.xml target validator (also wrapped into the deploy gate).
- **`tools/check_bug_patterns.sh`** — standalone bug-pattern audit (also wrapped into the deploy gate).

### Phase D4 — Codify

`CONTRIBUTING.md` gained a "Release & regeneration" section enumerating the deploy-gate workflow, what gets regenerated, and what stays manual. `CLAUDE.md` gained a brief pointer. `AGENT_GUIDE.md` was updated alongside (Phase D1.2 work). All three are now mutually consistent.

## What stays open after this audit

- **D2.2 — `checkcode` sweep.** Re-execute after the publish step releases the MATLAB license. Triage warnings by severity. Tracked as future work; not blocking.
- **67 unreferenced `.png` files** in `helpfiles/`. Most are `*_eq*.png` equation rasters from old `publish()` runs. Confirm whether the current `publish_all_helpfiles` regenerates them and supersedes the old set; if yes, mass-delete after one canonical publish cycle. Tracked.
- **`LinearCIF` Symbolic dependency at construction** — documented exception with fix-shape estimate.
- **Pre-tag hook documentation** (D3.3) — deferred; the gate is invokable and documented in CONTRIBUTING.md, hooks remain opt-in per the existing precedent.

## Exit criteria — status

- [x] D0–D4 phases reach their acceptance gates (D2.2 deferred).
- [ ] `tools/predeploy.sh` end-to-end clean dry run (pending publish completion).
- [x] `docs/verification/helpsystem_audit.md` exists.
- [x] `docs/verification/bug_pattern_audit.md` exists.
- [x] `docs/verification/symbolic_dependency_audit.md` exists.
- [x] `Contents.m` version stamp ≥ 2026-05-20.
- [ ] One PR landed on `master`.
- [ ] Plan transitions to status `COMPLETED`.
