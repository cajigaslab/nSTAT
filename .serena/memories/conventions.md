# nSTAT — Conventions & Policies

Canonical policy text = tracked `CONTRIBUTING.md`; agent usage guide = `AGENT_GUIDE.md`; historical bug catalog = `AUDIT_REPORT.md`.

## Source-of-truth rules
- **`.m` is canonical, not `.mlx`.** `.mlx` Live Scripts are binary/drift-prone. Edit the `.m`; if an `.mlx` drifts, delete it rather than hand-patch. Sole exception: `helpfiles/nSTATPaperExamples.mlx` (2012-paper artifact, preserved deliberately).
- When smoke-testing an edited helpfile `.m`, watch the `.mlx`-shadows-`.m` trap (an `.mlx` of the same name shadows the `.m` on the MATLAB path) — see CONTRIBUTING.md "Smoke-testing an edited helpfile `.m`".
- **Never hand-edit generated artifacts:** `helpfiles/*.html`, `helpfiles/helpsearch-v4_0/`, `docs/figures/exampleNN/*.png`, `docs/figures/manifest.json`. They regenerate via `tools/predeploy.sh` / `build_paper_examples` / `publish_all_helpfiles`.

## Parity & figures (invariants)
- **Numeric baseline** `fixtures/baseline_numeric/` + `tests/TestParityAgainstBaseline.m` = ground truth. A change breaking the baseline is WRONG unless the baseline is deliberately regenerated (`tools/generate_baseline_fixtures.m`).
- **README figure parity:** committed PNGs under `docs/figures/exampleNN/` ARE the GitHub-rendered docs. Any change to `examples/paper/exampleNN_*.m`, a core class, `+nstat/+decoding/*`, or `tools/+nstat/applyPlotStyle.m` must run `tools/check_readme_figures.sh`. `IDENTICAL`/`TINY`/`NONDETERMINISTIC` → proceed; `SUBSTANTIVE` → regenerate `docs/figures/` and commit PNGs+manifest, or fix the regression.

## Code style
- MATLAB class/method names are the public API — do not rename.
- Audit comments use `% FIX:` convention; deprecations use the shim pattern (see `docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md`).
- Branches `fix/<area>` or `feat/<area>`; short imperative commit subjects.
- No checked-in git hooks (deliberate maintainer decision; CONTRIBUTING.md pre-push hook is opt-in per developer).