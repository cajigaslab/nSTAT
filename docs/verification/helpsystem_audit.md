# Help-System Audit

> **Phases D0.1, D0.2, D0.3, D0.4** of [`docs/superpowers/plans/2026-05-20-comprehensive-codebase-audit.md`](../superpowers/plans/2026-05-20-comprehensive-codebase-audit.md).

## Inventory

- `.m` files in `helpfiles/`: **38**
- `.html` files in `helpfiles/`: **41**
- `.mlx` files in `helpfiles/`: **24**
- `.png` files in `helpfiles/`: **235**
- helptoc.xml file-path entries: **40**

## D0.1 — helptoc.xml ↔ target resolution

Validated by `tools/lint_helptoc.py`. **PASS** (33/33 file-path targets resolve; 2 external URLs ignored).

## D0.2 — .m ↔ .html staleness (git timestamps)

`.html` siblings older than their `.m` master (need republishing):

| Stem | `.m` last commit | `.html` last commit |
|---|---|---|
| `DecodingExample` | 2026-05-20 08:22:46 -0400 | 2026-03-11 11:18:12 -0400 |
| `DecodingExampleWithHist` | 2026-05-20 08:22:46 -0400 | 2026-03-11 11:18:12 -0400 |
| `HybridFilterExample` | 2026-05-20 08:22:46 -0400 | 2026-03-11 10:35:13 -0400 |
| `StimulusDecode2D` | 2026-05-20 08:22:46 -0400 | 2026-03-11 10:35:13 -0400 |
| `nSTATPaperExamples` | 2026-05-20 08:22:46 -0400 | 2026-03-11 11:18:12 -0400 |

**Total stale: 5.** Remediation: run `tools/publish_examples.m` to regenerate, commit the diffs.

## D0.3 — Orphans

### `.html` without a `.m` sibling

- `Analysis.html`
- `FitResult.html`
- `SignalObj.html`
- `index.html`

**Decision needed:** delete (canonical-`.m` policy says these are stale auto-generated artifacts) OR document why kept.

### `.m` not referenced from `helptoc.xml`

- `publish_all_helpfiles.m`

These may be intentionally-private helpers or example scripts not yet surfaced in the help TOC. Triage individually.

### `.png` files not referenced from any `.html`

**80 unreferenced PNGs** (first 30):

- `AnalysisExamples.png`
- `AnalysisExamples2.png`
- `AnalysisExamples2_06.png`
- `CovCollExamples.png`
- `CovariateExamples.png`
- `DecodingExample.png`
- `DecodingExampleWithHist.png`
- `DecodingExample_06.png`
- `DecodingExample_07.png`
- `EventsExamples.png`
- `EventsExamples_04.png`
- `ExplicitStimulusWhiskerData.png`
- `ExplicitStimulusWhiskerData_10.png`
- `FoundationModelKSValidation.png`
- `HelloNstat.png`
- `HippocampalPlaceCellExample.png`
- `HippocampalPlaceCellExample_10.png`
- `HippocampalPlaceCellExample_11.png`
- `HistoryExamples.png`
- `HistoryExamples_04.png`
- `HistoryExamples_05.png`
- `HistoryExamples_06.png`
- `HistoryExamples_07.png`
- `HybridFilterExample.png`
- `HybridFilterExample_eq06211.png`
- `Logo.png`
- `NetworkTutorial.png`
- `NetworkTutorial_05.png`
- `NetworkTutorial_eq01608.png`
- `NetworkTutorial_eq05678.png`
- … and 50 more

These may be (a) referenced from the `.m` master (published-HTML format may embed them differently), (b) thumbnail or auxiliary outputs, or (c) bona-fide disk bloat. Spot-check the first few before mass-deletion.
