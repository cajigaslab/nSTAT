# 2026-05-31 — Aesthetic + Informative Intro Page (Jupyter Book mirror of nSTAT-python)

**Owner:** Iahn Cajigas
**Status:** PROPOSED
**Goal (user-stated 2026-05-31):** *aesthetically pleasing and informative introductory pages to the nSTAT toolbox in MATLAB utilizing existing figures, notebooks, and help files.*
**Reference site to mirror:** https://cajigaslab.github.io/nSTAT-python/intro.html

## 1. Strategic position first

**Counterargument (consider before agreeing with this plan).** nSTAT already publishes a help site at `https://cajigaslab.github.io/nSTAT/` via the MATLAB-native `publish()` workflow ([`helpfiles/publish_all_helpfiles.m`](../../../helpfiles/publish_all_helpfiles.m)). The PR #43 deploy gate verified that all 41 `.html` pages publish cleanly and `helptoc.xml` validates. Adding a *second* documentation system (Jupyter Book) duplicates the surface area, splits the source of truth, and introduces a Python toolchain to a MATLAB toolbox.


The Python port solved this with `intro.html` — a hand-authored MyST page with a hero, install snippet, **5-minute tour** (6 progressive code snippets), `extras` overview cards, paper-example thumbnail gallery, and a "where to next" hub. Bounce rate on that page is presumably much lower (no instrumentation, but the structure is empirically much friendlier).

**Decision.** Add the Jupyter Book layer **on top of** the existing helpfiles. Helpfiles remain canonical for in-MATLAB reference docs (`doc nSTAT`, MATLAB Help browser). The new intro page is the web landing for new users. Both deploy to `gh-pages`; Jupyter Book becomes the root, helpfiles live at `/helpfiles/` as pass-through HTML.

## 2. Inventory — what already exists

| Asset | Path | State |
|---|---|---|
| GitHub README (the most-visited surface) | [`README.md`](../../../README.md) | Current; has figure-gallery table; PR #43 added Phase 0–4 section |
| Canonical onboarding tutorial | [`helpfiles/HelloNstat.m`](../../../helpfiles/HelloNstat.m) | 5786 bytes; Phase 2 addition |
| Algorithm-selection decision tree | [`helpfiles/WhenToUseWhich.m`](../../../helpfiles/WhenToUseWhich.m) | 8170 bytes; Phase 2 |
| Paper-aligned toolbox map | [`helpfiles/PaperOverview.m`](../../../helpfiles/PaperOverview.m) | 3263 bytes |
| Class definitions index | [`helpfiles/ClassDefinitions.m`](../../../helpfiles/ClassDefinitions.m) | 845 bytes |
| Published HTML for all 38 `.m` pages | `helpfiles/*.html` | 41 files; PR #43 regen |
| 5-example paper figure gallery | [`docs/figures/example01..05/`](../../figures/) | 24 PNGs total; 5 `fig01_*.png` heroes; PR #42 regen |
| Manifest (provenance) | [`docs/figures/manifest.json`](../../figures/manifest.json) | `generated_at` from PR #42 |
| Paper examples index | [`docs/paper_examples.md`](../../paper_examples.md) | 4013 bytes; lightly maintained |

**What we do NOT need to create from scratch:** any class reference, any paper-example figure, any deep tutorial. Those exist. The intro page is **navigation + welcome + hero showcase**, not new content.

## 3. Phase E1 — Choose the doc framework

**Options.**

| Option | Effort | Aesthetic ceiling | Maintenance | Toolchain |
|---|---|---|---|---|
| A. Jupyter Book (matches Python port) | Medium (~1 day) | High (Sphinx + rtd-theme + custom CSS) | Same as Python port | Python: `jupyter-book`, `myst-parser`, `sphinx`, `sphinx-rtd-theme` |
| B. Hand-authored static HTML | Low (~half day) | Medium-high | High — drift-prone | None |
| C. Polished MATLAB-published `.m` | Low | Low (MATLAB `publish()` HTML is dated-looking) | Low | Existing |
| D. Hugo / mdBook / etc. | Medium | High | Yet another stack | New |

**Recommend Option A — Jupyter Book**, because:
1. **Parity with the Python port.** The lab now has two nSTAT projects; users moving between them benefit from a consistent doc aesthetic.
2. **Toolchain already in-house.** The Python port already requires Sphinx/MyST; the user has it.
3. **Composability with helpfiles.** Jupyter Book can list pre-rendered MATLAB `.html` pages as external links or pass-through pages. The 41 `helpfiles/*.html` don't need re-rendering.
4. **CI-friendly.** Jupyter Book builds run on GitHub-hosted Python runners — no MATLAB license required. Matches the no-MATLAB-CI policy from [`CONTRIBUTING.md`](../../../CONTRIBUTING.md).
5. **MyST = Markdown + Sphinx directives.** The user already writes Markdown for the action plans and verification reports. No new authoring syntax to learn.

**Decision gate for the user.** If you'd rather **NOT** depend on Python tooling for the MATLAB toolbox's doc site, switch to Option B (hand-authored static HTML) and re-scope Phases E2/E3 accordingly. Everything else in this plan ports cleanly.

## 4. Phase E2 — Build the intro page

Single new file: `docs/intro.md`. Mirrors the Python intro page's structure 1:1.

### E2.1 — Hero section

```markdown
# nSTAT — Neural Spike Train Analysis Toolbox

> Point-process and state-space methods for spike-train analysis.
> Time-rescaling KS goodness-of-fit · PPAF / PPHF / SSGLM / PPLFP decoders ·
> History-aware GLM fitting with raised-cosine bases.

[![v1.4.0](https://img.shields.io/badge/release-v1.4.0-blue)](https://github.com/cajigaslab/nSTAT/releases/tag/v1.4.0)
[![paper](https://img.shields.io/badge/paper-Cajigas%202012-green)](https://doi.org/10.1016/j.jneumeth.2012.08.009)
[![Python port](https://img.shields.io/badge/Python%20port-nSTAT--python-orange)](https://github.com/cajigaslab/nSTAT-python)
```

(Optional hero image: a clean composite of `docs/figures/example03/fig01_simulated_and_real_rasters.png` + `example05/fig02_univariate_decoding.png` to show "we can fit AND decode" in one banner.)

### E2.2 — Install

```matlab
% In MATLAB R2025b, from the repository root:
cd('/path/to/nSTAT')
nSTAT_Install('DownloadExampleData', true);  % auto-prompts for the figshare dataset
```

Links to [`nSTAT_Install.m`](../../../nSTAT_Install.m) and the figshare dataset DOI.

### E2.3 — 5-minute tour (six MATLAB snippets, progressive complexity)

Each snippet is ~5–15 lines, runnable in MATLAB after `nSTAT_Install`, and **links to a deeper page** for the full treatment.

**Tour 1 — Create spike-train objects.**
```matlab
spiketimes = sort(0.1 * rand(200, 1) + 5);     % 200 sample spikes
nst = nspikeTrain(spiketimes);
figure; plot(nst); title('Single spike train');
```
[→ deeper: `nSpikeTrainExamples.html`](https://cajigaslab.github.io/nSTAT/nSpikeTrainExamples.html)

**Tour 2 — Assemble a trial with covariates.**
```matlab
T = linspace(0, 1, 1000)';
position = Covariate(T, [sin(2*pi*T), cos(2*pi*T)], 'Position', 'time', 's', 'm', {'x','y'});
covarColl = CovColl({position});
spikeColl = nstColl({nst});
trial = Trial(spikeColl, covarColl);
tc = TrialConfig({{'Position','x','y'}}, 1000, []);
```
[→ deeper: `TrialExamples.html`](https://cajigaslab.github.io/nSTAT/TrialExamples.html)

**Tour 3 — Fit a Poisson GLM and check KS.**
```matlab
fitResults = Analysis.RunAnalysisForAllNeurons(trial, ConfigColl({tc}), 0);
figure; fitResults.KSPlot;   % time-rescaling KS test against the 95% band
```
[→ deeper: `HelloNstat.html`](https://cajigaslab.github.io/nSTAT/HelloNstat.html)
[→ math: `PaperOverview.html`](https://cajigaslab.github.io/nSTAT/PaperOverview.html) §2.3.1

**Tour 4 — Decoder choice for your problem.**
```matlab
% Univariate / continuous-state stimulus decoding:
[x_p, W_p] = nstat.decoding.PPAF.PPDecode_predict(x_u, W_u, A, Q);
[x_u, W_u] = nstat.decoding.PPAF.PPDecode_update(x_p, W_p, dN, mu, beta, fitType, ...);

% Hybrid discrete+continuous state (e.g., reach with goal): nstat.decoding.PPHF
% Multimodal spike + LFP: nstat.decoding.PPLFP
```
[→ deeper: `WhenToUseWhich.html`](https://cajigaslab.github.io/nSTAT/WhenToUseWhich.html)
[→ examples: `DecodingExample.html`](https://cajigaslab.github.io/nSTAT/DecodingExample.html)

**Tour 5 — State-space GLM for trial-drifting coefficients.**
```matlab
% Czanner et al. 2008 SSGLM (canonical implementation: nstat.decoding.SSGLM)
[results] = nstat.decoding.SSGLM.PPSS_EMFB(trial, tc, sampleRate);
figure; plot(results.stimulusGain);   % per-trial coefficient drift
```
[→ deeper: `AnalysisExamples2.html`](https://cajigaslab.github.io/nSTAT/AnalysisExamples2.html) and the SSGLM section of `nSTATPaperExamples.html`

### E2.4 — Paper-example thumbnail gallery

Mirror the Python intro's gallery: 5 thumbnail rows with question, hero image, and run command. All thumbnails ALREADY EXIST in `docs/figures/example0N/fig01_*.png`:

```markdown
| Example | Thumbnail | Question | Run |
|---|---|---|---|
| 01 — mEPSC Poisson | ![](figures/example01/fig01_constant_mg_summary.png) | Do mEPSCs follow constant vs piecewise Poisson firing? | `example01_mepsc_poisson` |
| 02 — Whisker stimulus | ![](figures/example02/fig01_data_overview.png) | Do explicit stimulus and history improve thalamic GLM fits? | `example02_whisker_stimulus_thalamus` |
| 03 — PSTH + SSGLM | ![](figures/example03/fig01_simulated_and_real_rasters.png) | How do PSTH and SSGLM capture within- and across-trial dynamics? | `example03_psth_and_ssglm` |
| 04 — Place cells | ![](figures/example04/fig01_example_cells_path_overlay.png) | Gaussian vs Zernike basis for place-cell receptive fields? | `example04_place_cells_continuous_stimulus` |
| 05 — Decoding | ![](figures/example05/fig01_univariate_setup.png) | How well do PPAF/PPHF decode stimulus and reach state? | `example05_decoding_ppaf_pphf` |
```

### E2.5 — Where to next (navigation hub)

```markdown
## Where to next

- [Paper-aligned toolbox map](PaperOverview.html) — match 2012 paper sections to code
- [Class definitions](ClassDefinitions.html) — SignalObj, Covariate, Trial, Analysis, FitResult, ...
- [Algorithm decision tree](WhenToUseWhich.html) — which decoder for which problem?
- [Full helpfiles index](helpfiles/) — every published `.m` page
- [Release notes](https://github.com/cajigaslab/nSTAT/blob/master/RELEASE_NOTES.md)
- [Python port](https://github.com/cajigaslab/nSTAT-python) — same algorithms in Python
- [Cite the paper](https://doi.org/10.1016/j.jneumeth.2012.08.009) (Cajigas, Malik, Brown 2012; PMID 22981419)
```

**Effort:** 4–6 hours to author + proofread.

## 5. Phase E3 — Wire the build and deployment

### E3.1 — Repo layout

```
docs/
├── _config.yml          # Jupyter Book config (theme, repository link, etc.)
├── _toc.yml             # navigation tree (intro.md + the other markdown pages)
├── intro.md             # the new landing page (Phase E2)
├── installation.md      # extracted install/quickstart section (optional)
├── paper_examples.md    # already exists; surface in TOC
├── figures/             # already exists; referenced by intro.md
└── (existing dirs)      # superpowers/, verification/ — excluded from build via _config
```

`_config.yml`:
```yaml
title: nSTAT
author: Cajigas Lab
logo: figures/example03/fig01_simulated_and_real_rasters.png
execute:
  execute_notebooks: 'off'   # MATLAB code, do not try to execute
repository:
  url: https://github.com/cajigaslab/nSTAT
  branch: master
html:
  use_repository_button: true
  use_issues_button: true
  use_edit_page_button: true
sphinx:
  extra_extensions:
    - sphinx_design       # for thumbnail-card grid layout
exclude_patterns:
  - superpowers/**
  - verification/**
```

`_toc.yml`:
```yaml
format: jb-book
root: intro
chapters:
  - file: paper_examples
  - url: https://cajigaslab.github.io/nSTAT/NeuralSpikeAnalysis_top.html
    title: In-MATLAB Help (full reference)
  - url: https://github.com/cajigaslab/nSTAT/blob/master/RELEASE_NOTES.md
    title: Release notes
  - url: https://github.com/cajigaslab/nSTAT-python
    title: Python port
```

### E3.2 — Build

Local:
```bash
python -m pip install jupyter-book sphinx-design
jupyter-book build docs/
# output: docs/_build/html/
```

### E3.3 — Deploy via GitHub Actions

`.github/workflows/docs.yml`:
```yaml
name: Build and deploy intro page
on:
  push:
    branches: [master]
    paths:
      - 'docs/intro.md'
      - 'docs/paper_examples.md'
      - 'docs/_config.yml'
      - 'docs/_toc.yml'
      - 'docs/figures/**'
      - '.github/workflows/docs.yml'
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - run: python -m pip install jupyter-book sphinx-design
      - run: jupyter-book build docs/
      - uses: actions/upload-pages-artifact@v3
        with: { path: docs/_build/html }
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: github-pages
    steps:
      - uses: actions/deploy-pages@v4
```

This **coexists with** the existing helpfile deploy (whatever's currently producing `cajigaslab.github.io/nSTAT/NeuralSpikeAnalysis_top.html`). Option to consolidate later by adding a `helpfiles/` copy step to the workflow so both surfaces live under one Pages deployment.

### E3.4 — DNS / URL strategy

Two choices:

- **A.** Replace the current `cajigaslab.github.io/nSTAT/` root with the Jupyter Book site. The existing helpfile HTML moves to `cajigaslab.github.io/nSTAT/helpfiles/...`. All in-MATLAB browser links keep working (they target relative paths inside the helpfiles dir).
- **B.** Add the Jupyter Book site at `cajigaslab.github.io/nSTAT/docs/`. The current helpfile root stays where it is. Users land on the austere page unless we update the redirect.

**Recommend A** — the Jupyter Book site IS the new landing, and helpfiles become the reference docs accessible from it.

**Effort:** 2–3 hours for config + workflow + first successful deploy.

## 6. Phase E4 — Cross-link from existing surfaces

Once the intro page is live:

1. **`README.md`** — replace the `https://cajigaslab.github.io/nSTAT/` link with a more prominent banner pointing at the intro page, e.g.:
   ```markdown
   📖 **Start here:** [the introduction page](https://cajigaslab.github.io/nSTAT/) with a 5-minute tour and example gallery.
   ```
2. **`helpfiles/NeuralSpikeAnalysis_top.html`** — add a top banner:
   ```html
   <p>New here? Start with the <a href="../">5-minute introduction</a>.</p>
   ```
3. **`AGENT_GUIDE.md`** — add the intro URL to Section 8 ("Help / docs surface").

**Effort:** 30 minutes.

## 7. Sequencing and total effort

```
Phase E1 (framework decision)         2026-06-01  →  30 min  (user signs off)
Phase E2 (author intro.md)            2026-06-01  →  4–6 hr
Phase E3 (build + deploy wiring)      2026-06-02  →  2–3 hr
Phase E4 (cross-link existing)        2026-06-02  →  30 min
                                                  ─────────
                                      TOTAL       ~7–10 hr
                                      WALL CLOCK  1–2 days
```

## 8. What this plan deliberately does NOT do

- **Does NOT replace `helpfiles/`** — those remain the in-MATLAB doc-browser-canonical source and the API reference.
- **Does NOT migrate to Sphinx for API reference.** Class reference pages (`SignalObj.html`, `Analysis.html`, `FitResult.html`) stay published via `publish_all_helpfiles`.
- **Does NOT introduce MATLAB CI.** The Jupyter Book build runs as Python; no MathWorks license needed.
- **Does NOT rewrite `README.md` body prose.** README adds one banner link.
- **Does NOT touch the figure-parity gate.** PR #42's `tools/check_readme_figures.sh` continues to manage `docs/figures/exampleN/*.png`. The intro page consumes those PNGs; it does not regenerate them.

## 9. Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Adding Python toolchain creates a footgun for MATLAB-only contributors | LOW–MED | Jupyter Book runs only on CI for deployment; local edits are pure Markdown. Document explicitly in CONTRIBUTING.md. |
| Existing helpfile URLs break when the deploy structure changes | MED | URL strategy A keeps `cajigaslab.github.io/nSTAT/helpfiles/<page>.html` working as a synonym for the old `cajigaslab.github.io/nSTAT/<page>.html`. Add a redirect index `helpfiles/index.html` if needed. |
| Code snippets in the 5-minute tour fall out of date | MED | The intro is hand-authored; add to the [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) "README figure parity" section so policy is: snippets edited only when API surface changes. The deploy-gate's `check_bug_patterns.sh` greps for `DecodingAlgorithms.*` direct calls and would catch a reverted recommendation. |
| Jupyter Book version drift between this repo and the Python port | LOW | Pin both repos to the same `jupyter-book` minor version in their respective workflow files. |
| GitHub Pages quota / build time | LOW | Static site is ~5MB including figures; build is <2 min. Well under free-tier limits. |

## 10. Acceptance criteria

- [ ] `docs/intro.md` exists and renders the five sections (hero, install, 5-minute tour, gallery, where to next).
- [ ] `docs/_config.yml` + `docs/_toc.yml` build without warnings via `jupyter-book build docs/` locally.
- [ ] `.github/workflows/docs.yml` deploys successfully on push to `master`.
- [ ] `https://cajigaslab.github.io/nSTAT/` shows the new intro page within 5 minutes of push.
- [ ] The existing helpfile HTML pages (`cajigaslab.github.io/nSTAT/helpfiles/<page>.html`) still resolve.
- [ ] `README.md` has a top-of-page link to the intro page.
- [ ] Every code snippet in the 5-minute tour was tested in MATLAB and runs without error.
- [ ] One PR (or a small sequence) merged to `master`.

## 11. Suggested execution order

1. **Sign off on Option A vs B** (framework choice). If A → Jupyter Book → continue. If B → hand-authored HTML → adapt E2/E3.
2. Open branch `feat/intro-page` from current `master`.
3. Execute E2 (author `docs/intro.md`); test each MATLAB snippet locally.
4. Execute E3 (`_config.yml`, `_toc.yml`, GitHub workflow); local build clean before pushing.
5. Push to a feature branch, watch CI, confirm site renders.
6. Execute E4 (cross-link from README + AGENT_GUIDE + helpfile top).
7. Open PR. Self-review for accuracy of code snippets and links.
8. Merge.

## 12. Open questions for the user (decision gates)

1. **Framework**: Jupyter Book (recommended, matches Python port) or hand-authored HTML (no Python dep)?
2. **Hero image**: composite of paper-example thumbnails, or a custom Lab logo, or no image?
3. **Snippet philosophy**: prefer "minimal runnable" (5–10 lines each, copy-pasteable) or "complete pipeline" (15–30 lines, more context)? The Python port chose minimal; recommend matching.
4. **`extras`-equivalent section**: the Python port has an `extras` section for opt-in dependencies (`spikeinterface`, `neo`, etc.). MATLAB has no opt-in extras. **Recommend**: replace that section with a "**v1.4 highlights**" section that calls out PPAF iterated update, `LinearCIF`, `History.raisedCosine`, and the deploy gate.
5. **MATLAB-specific feature to spotlight that Python lacks**: the Symbolic-CIF derivation path (you can hand-design a CIF in MATLAB symbols, fit it, and inspect the symbolic-derivative chain). Is this worth a "MATLAB-specific superpower" callout, or out of scope for a first version?
