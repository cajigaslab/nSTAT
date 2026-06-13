# 2026-06-13 — Toolbox Modernization Plan

**Owner:** Iahn Cajigas
**Status:** PROPOSED
**Goal (user-stated 2026-06-13):** *deep dive on the structure of modern MATLAB toolboxes; see if we can improve the organization and deployment of this MATLAB toolbox.*

## 1. Strategic position first

**Counterargument (consider before agreeing).** nSTAT is a 14-year-old MATLAB toolbox with thousands of in-the-wild downloads (figshare DOI), a published paper (PMID 22981419), and an established user base who knows the current install pattern (`nSTAT_Install.m`). Restructuring the directory layout to match 2026 MathWorks conventions risks breaking every user's existing path setup, every BibTeX citation that points at `nSTAT/Analysis.m` line numbers, and every downstream script that references file paths. The cost is borne by users; the benefit ("conforms to convention") is invisible to anyone who already has it working.

**Refutation (why ship the plan anyway).** Three reasons make this work worth doing despite the above:

1. **`.mltbx` packaging unlocks one-click install.** Modern MATLAB users discover toolboxes through the Add-On Explorer and expect double-click install via `.mltbx`. The current install requires cloning the repo, opening MATLAB, running a custom script, and downloading figshare data. Each of these is a discovery-funnel leak. A `.mltbx` artifact attached to GitHub Releases adds zero friction for the discoverer while changing nothing for the existing-users-who-clone.
2. **`buildtool` consolidates the current eight `tools/*.sh` scripts.** The current build infrastructure is `run_unit_tests.sh`, `check_readme_figures.sh`, `predeploy.sh`, `lint_helptoc.py`, `check_bug_patterns.sh`, `build_paper_examples.m`, `audit_help_system.py`, and `stamp_release.m` — eight orchestration entry points. MathWorks' `buildtool` is the canonical replacement: one `buildfile.m` defines named tasks (`check`, `test`, `package`, `figures`) that run with one command, integrate with the IDE, and produce machine-readable artifacts. Reorganizing this surface costs about 4 hours and saves every release engineer thereafter from remembering script names.
3. **Backwards compatibility is achievable.** The plan does NOT propose moving every `.m` file to a new path. It proposes ADDING the modern surface (`toolbox/` directory, `buildfile.m`, `toolboxOptions.m`, `.mltbx` build) ALONGSIDE the existing root-level classdefs that the user base knows. The existing classdefs stay where they are; `nSTAT_Install.m` continues to work. The new artifacts are pure addition, not removal.

**Decision gate.** If you'd rather stop here — the existing layout works, the toolbox is well-tested, and "stop adding new infrastructure" is a defensible position — say so and discard the plan. If you'd like to expose the toolbox to the MATLAB Add-On Explorer audience without breaking the existing user base, proceed.

## 2. Canonical modern structure vs. current nSTAT

References:
- [mathworks/toolboxdesign](https://github.com/mathworks/toolboxdesign) — MathWorks' official best-practices doc.
- [eddins/inittbx](https://github.com/eddins/inittbx) — Steve Eddins' template that bootstraps a modern toolbox.
- [matlab.addons.toolbox.ToolboxOptions](https://www.mathworks.com/help/matlab/ref/matlab.addons.toolbox.toolboxoptions.html) — the declarative-packaging class introduced in recent releases.
- [`buildtool`](https://www.mathworks.com/help/matlab/ref/buildtool.html) — the canonical task runner.

Canonical modern layout (from `mathworks/toolboxdesign`):

```text
<toolboxname>/                  # root: short, no "toolbox" suffix
├── README.md                   # user-focused + how to contribute
├── license.txt                 # license file (lowercase by convention)
├── buildfile.m                 # buildtool task definitions
├── toolboxOptions.m            # ToolboxOptions config
├── packageToolbox.m            # orchestrates .mltbx build
├── CHECKLIST.md                # release checklist
├── images/                     # README assets
├── release/                    # .mltbx output (gitignored)
├── tests/                      # not shipped to users
└── toolbox/                    # THIS is what gets shipped
    ├── <toolboxname>.m         # public top-level functions (if <20)
    ├── +<toolboxname>/         # namespace package for larger toolboxes
    │   ├── +internal/          # implementation; user-visible but discouraged
    │   └── ...
    ├── doc/
    │   └── GettingStarted.mlx  # REQUIRED — auto-shown on install
    ├── examples/               # Live Scripts demonstrating use
    └── private/                # implementation; only callable from parent
```

Comparison to current nSTAT (master HEAD):

| Aspect | Modern best practice | Current nSTAT | Gap |
|---|---|---|---|
| Root folder name | Short, no "toolbox" suffix | `nSTAT/` ✅ | None |
| Top-level structure | `toolbox/` subfolder isolates shipped code | All classdefs at root (`Analysis.m`, `CIF.m`, etc.) | **Significant** |
| Code organization | Public at top, private in `<name>.internal` namespace | Some in `+nstat/+decoding/`, most at root | **Partial** |
| Getting started | `toolbox/doc/GettingStarted.mlx` (auto-shown on install) | `helpfiles/HelloNstat.m` (must be discovered) | **Naming + location** |
| Examples | `toolbox/examples/*.mlx` | `examples/paper/*.m`, `helpfiles/*.m`, both `.m` not `.mlx` | **Scattered + non-canonical format** |
| Tests | `tests/` at root | `tests/{unit,integration,python_port_fidelity}/` ✅ | None |
| Build config | `buildfile.m` for `buildtool` | None; 8 separate `tools/*.{sh,m,py}` scripts | **Missing** |
| Declarative packaging | `toolboxOptions.m` + `ToolboxOptions` | None; custom `nSTAT_Install.m` does install | **Major gap** |
| Distribution | `.mltbx` via Add-On Manager | Manual `git clone` + `nSTAT_Install` | **Major gap** |
| Release checklist | `CHECKLIST.md` | `RELEASE_NOTES.md` only | Minor |
| MATLAB project | `.prj` file for IDE integration | None | Minor |
| CI | `matlab-actions/setup-matlab` | None for MATLAB code (license-blocked) | Architectural |
| Open in MATLAB Online badge | One-click try-it-out from README | Not present | Trivial |
| File Exchange / Add-On listing | Cross-listed for discovery | Not listed | Marketing |

**Two genuine architectural gaps:** (a) no `.mltbx` packaging means zero discoverability through the Add-On Explorer; (b) no `buildtool` integration means 8 ad-hoc scripts where 1 IDE-aware task runner would suffice. Everything else is cosmetic or a directory rename.

## 3. Strategic decision — what to actually change

Three viable scopes:

| Scope | Effort | User-impact | Recommendation |
|---|---|---|---|
| **A. Pure addition.** Add `buildfile.m`, `toolboxOptions.m`, `packageToolbox.m`, `.mltbx` build, and Add-On Explorer listing. Don't touch existing files. | 1–2 days | None (backward compatible) | **Strongly recommend.** |
| **B. Soft reorganization.** Add a `toolbox/` directory that *symlinks* or *re-exports* the existing classdefs so `addpath('toolbox')` provides the canonical public API; keep root-level files for backward compat. | 3–5 days | Slight (path semantics differ); existing users untouched | Optional. |
| **C. Hard migration.** Move every `.m` into `toolbox/`. Break every existing path. Tag as v2.0.0 (breaking change per semver). | 1–2 weeks | High; every user must update | **Do not recommend.** The 2012 paper artifact is too established. |

**Plan recommends Option A** with Option B as a deferred Phase G6 (revisit only if Add-On Explorer adoption proves the modernization is being consumed).

## 4. Phase G1 — `buildfile.m` + `buildtool` task migration

Replaces the 8 ad-hoc scripts with one declarative task definition.

### G1.1 — Inventory current `tools/*` scripts

| Current script | New task name | Action |
|---|---|---|
| `tools/run_unit_tests.sh` | `test` | `matlab.buildtool.tasks.TestTask("tests/unit")` |
| `tools/run_unit_tests.sh --integration` | `test:integration` | `matlab.buildtool.tasks.TestTask("tests/integration")` |
| `tools/check_readme_figures.sh` | `figures` | wrap existing script in a `buildtool.Task` action |
| `tools/predeploy.sh` | `predeploy` | dependencies: `test`, `figures`, `package` |
| `tools/lint_helptoc.py` | `lint:helptoc` | Python sub-shell via `runtests` or `system()` |
| `tools/check_bug_patterns.sh` | `lint:patterns` | wrap existing |
| `tools/build_paper_examples.m` | `figures:regen` | `matlab.buildtool.Task` action |
| `tools/stamp_release.m` | `stamp` | invoked from `package` |

### G1.2 — Author `buildfile.m`

```matlab
function plan = buildfile
    plan = buildplan;

    plan("check") = matlab.buildtool.tasks.CodeIssuesTask( ...
        ["+nstat" "*.m"], IncludeSubfolders=true);

    plan("test") = matlab.buildtool.tasks.TestTask("tests/unit");

    plan("test:integration") = matlab.buildtool.tasks.TestTask( ...
        "tests/integration", TestResults="results.xml");

    plan("figures") = matlab.buildtool.Task( ...
        Description="Verify README figure parity", ...
        Actions=@(~) system("tools/check_readme_figures.sh"));

    plan("package") = matlab.buildtool.Task( ...
        Description="Build .mltbx package", ...
        Dependencies=["check" "test"], ...
        Actions=@packageToolbox);

    plan("predeploy") = matlab.buildtool.Task( ...
        Description="Full pre-release gate", ...
        Dependencies=["check" "test" "test:integration" "figures" "package"]);

    plan.DefaultTasks = ["check" "test"];
end
```

### G1.3 — Acceptance gate

- [ ] `buildtool` (no args) runs `check` + `test`; exits 0 with the same 72-test pass count we have today.
- [ ] `buildtool predeploy` runs the same six checks the existing `tools/predeploy.sh` runs.
- [ ] Existing `tools/*.sh` scripts remain present (deprecation, not removal) — document in commit message.

**Effort:** 4–6 hours.

## 5. Phase G2 — `toolboxOptions.m` + `.mltbx` packaging

This is what unlocks Add-On Explorer distribution.

### G2.1 — Generate the toolbox identifier

```matlab
% One-time setup:
identifier = char(matlab.lang.internal.uuid);
% Persist this UUID forever; never change it. Used by Add-On Manager
% to recognize updates vs. fresh installs.
```

Stored in `toolboxOptions.m`.

### G2.2 — Author `toolboxOptions.m`

```matlab
function opts = toolboxOptions
    rootDir = fullfile(fileparts(mfilename("fullpath")));

    identifier = "<UUID-FROM-G2.1>";

    opts = matlab.addons.toolbox.ToolboxOptions(rootDir, identifier);

    opts.ToolboxName = "nSTAT — Neural Spike Train Analysis Toolbox";
    opts.ToolboxVersion = "1.4.1";  % read from RELEASE_NOTES.md in stamp step
    opts.AuthorName = "Iahn Cajigas, Wasim Malik, Emery N. Brown";
    opts.AuthorEmail = "iahn.cajigas@gmail.com";
    opts.Summary = "Point-process and state-space methods for spike-train analysis.";
    opts.Description = readlines("README.md");  % first paragraph

    % Folders to add to MATLAB path at install time:
    opts.ToolboxMatlabPath = [...
        rootDir, ...
        fullfile(rootDir, "+nstat", "+decoding"), ...
        fullfile(rootDir, "tools"), ...
    ];

    opts.SupportedPlatforms.Win64 = true;
    opts.SupportedPlatforms.Maci64 = true;
    opts.SupportedPlatforms.Glnxa64 = true;
    opts.SupportedPlatforms.MatlabOnline = true;

    opts.MinimumMatlabRelease = "R2024b";

    opts.RequiredAdditionalSoftware = matlab.addons.toolbox.RequiredAdditionalSoftware( ...
        Name="Statistics and Machine Learning Toolbox", ...
        DownloadUrl="https://www.mathworks.com/products/statistics.html");

    % Optional: Getting Started Guide — auto-shown on install
    opts.GettingStartedGuide = fullfile(rootDir, "helpfiles", "HelloNstat.m");

    opts.OutputFile = fullfile(rootDir, "release", "nSTAT.mltbx");
end
```

### G2.3 — Author `packageToolbox.m`

```matlab
function packageToolbox(~)
    opts = toolboxOptions;
    if ~exist(fullfile(fileparts(opts.OutputFile)), "dir")
        mkdir(fullfile(fileparts(opts.OutputFile)));
    end
    matlab.addons.toolbox.packageToolbox(opts);
    fprintf("Packaged: %s\n", opts.OutputFile);
end
```

### G2.4 — Wire `.mltbx` into release flow

Update `tools/stamp_release.m` (or its `buildtool` equivalent) to:
1. Update `toolboxOptions.ToolboxVersion` to the target version.
2. Call `buildtool package` to produce `release/nSTAT.mltbx`.
3. Upload as a GitHub Release asset alongside the existing tag.

### G2.5 — Acceptance gate

- [ ] `buildtool package` produces `release/nSTAT.mltbx`.
- [ ] Double-clicking the `.mltbx` in MATLAB installs the toolbox via Add-On Manager.
- [ ] Post-install, `Analysis.RunAnalysisForNeuron` is callable from any directory.
- [ ] `helpfiles/HelloNstat.m` is shown to the user post-install.
- [ ] The `.mltbx` is attached to the v1.4.2 (or v1.5.0) GitHub Release.

**Effort:** 4–6 hours.

## 6. Phase G3 — Add-On Explorer listing

This is the *discoverability* unlock. The `.mltbx` exists in the repo; users still don't know to look.

### G3.1 — Submit to File Exchange

[File Exchange submission form](https://www.mathworks.com/matlabcentral/fileexchange/) accepts a GitHub URL and auto-builds the listing from the repo's `README.md` + `LICENSE` + `.mltbx`. Submit `cajigaslab/nSTAT`; choose category "Computational Biology" or "Statistics and Machine Learning".

### G3.2 — Add the badges to `README.md`

```markdown
[![View nSTAT on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/<id>-nstat)
[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=cajigaslab/nSTAT&file=helpfiles/HelloNstat.m)
```

The "Open in MATLAB Online" badge is the single highest-leverage addition. It lets a discoverer try the toolbox in a browser without installing anything locally.

### G3.3 — Acceptance gate

- [ ] File Exchange listing exists with ≥1 download recorded.
- [ ] "Open in MATLAB Online" badge resolves; clicking it opens `HelloNstat.m` in the cloud MATLAB.
- [ ] README banner updates to point at File Exchange as the canonical install path.

**Effort:** 1–2 hours (mostly waiting for File Exchange review).

## 7. Phase G4 — Optional: `toolbox/` directory with re-exports

Only do this if you want the in-tree structure to match the MathWorks reference layout for the next major version.

### G4.1 — Directory layout

```text
nSTAT/
├── README.md
├── license.txt
├── buildfile.m
├── toolboxOptions.m
├── packageToolbox.m
├── images/
├── release/                # .mltbx output (gitignored)
├── tests/                  # unchanged
├── docs/                   # unchanged
├── tools/                  # unchanged (legacy scripts during transition)
├── helpfiles/              # unchanged (legacy help-system surface)
├── examples/               # unchanged (legacy paper examples)
└── toolbox/                # NEW
    ├── Analysis.m          # → symlink to ../Analysis.m
    ├── CIF.m               # → symlink to ../CIF.m
    ├── ... (every public classdef)
    ├── +nstat/             # → symlink to ../+nstat/
    ├── doc/
    │   └── GettingStarted.mlx  # NEW Live Script (port of HelloNstat.m)
    ├── examples/           # NEW (Live Script versions of paper examples)
    └── private/            # NEW (move internal helpers here over time)
```

**Symlinks vs. duplicates.** Symlinks are the right primitive on macOS/Linux but Windows is unreliable. Alternatives: (a) a `toolbox/+nstat/...m` thin re-export that just calls the root-level classdef, (b) only create `toolbox/` at packaging time via the `buildtool package` task (it copies, never lives in tree). **Recommend option (b)** — keep the tree as-is, materialize `toolbox/` only during packaging.

### G4.2 — Acceptance gate

- [ ] `buildtool package` produces a `.mltbx` whose internal layout matches the MathWorks reference (verifiable with `unzip -l release/nSTAT.mltbx`).
- [ ] Root tree is unchanged (existing-user paths still work).

**Effort:** 6–8 hours including the packaging-time materialization.

## 8. Phase G5 — Open in MATLAB Online + `MATLAB Project (.prj)` (optional)

A `.prj` file gives IDE integration: open the project in MATLAB and the path/working-dir/dependencies are set automatically.

```matlab
prj = matlab.project.createProject("nSTAT");
prj.RootFolder = ".";
prj.addPath("+nstat", "tools", "helpfiles");
% etc.
```

The `.prj` is XML; cleanest to generate it via `matlab.project.createProject` rather than hand-author.

**Effort:** 2–3 hours.

## 9. Sequencing and total effort

```
Phase G1  buildfile.m + buildtool tasks            2026-06-14  →  4–6 hr    Pure addition
Phase G2  toolboxOptions + .mltbx packaging         2026-06-15  →  4–6 hr    Pure addition
Phase G3  File Exchange + Open-in-MO badges         2026-06-16  →  1–2 hr    Marketing
Phase G4  toolbox/ directory at packaging time      2026-06-17  →  6–8 hr    Optional
Phase G5  MATLAB Project (.prj) file                 2026-06-17  →  2–3 hr    Optional
                                                                ─────────
Recommended (G1–G3 only)                             TOTAL        9–14 hr
Full (G1–G5)                                                       17–25 hr
```

Phases G1–G3 are pure addition: no existing user has a worse experience after they land. G4 and G5 are nice-to-have for the next major version, defer-able indefinitely.

## 10. What this plan deliberately does NOT do

- **Does NOT move existing classdefs.** `Analysis.m`, `CIF.m`, `SignalObj.m`, etc., stay at the repo root forever (or at least until a v2.0.0 breaking-change release). Every existing path-based reference continues to work.
- **Does NOT remove `nSTAT_Install.m`.** It remains the documented install path for users who don't use the Add-On Manager. The new `.mltbx` is an *additional* install path, not a replacement.
- **Does NOT add MATLAB CI.** The team's MathWorks license doesn't extend to GitHub-hosted runners; this is a documented decision in `CONTRIBUTING.md`. `buildtool` runs locally (the existing pattern) — it just unifies the entry points.
- **Does NOT rewrite the helpfile system.** `helpfiles/helptoc.xml` + 41 `.html` pages + the `helpsearch-v4_en/` index continue to work exactly as they do today. `toolbox/doc/GettingStarted.mlx` is an addition, not a replacement.
- **Does NOT migrate paper examples to Live Scripts.** `examples/paper/example0[1-5]_*.m` stay as `.m` files; the regen pipeline depends on them. Live Script versions would be a separate effort if desired.
- **Does NOT change the figshare-dataset-on-install behavior.** `nSTAT_Install` continues to prompt; the `.mltbx` install lives alongside (`.mltbx` ships only the code; data is still downloaded post-install).

## 11. Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| `.mltbx` install conflicts with existing repo clone on the same MATLAB path | MED | Document in README: pick one install method, don't mix. The Add-On Manager warns of duplicates. |
| `toolboxOptions.ToolboxMatlabPath` misses a subfolder, so `.mltbx`-installed users hit "undefined function" errors | MED | Test the `.mltbx` install on a fresh MATLAB session before tagging. Include a smoke-test step in `buildtool predeploy`. |
| File Exchange listing requires changes the existing user base doesn't want (e.g., specific README format) | LOW | File Exchange is permissive; existing README works. If reviewer requests changes, we can decide case-by-case. |
| Generating the toolbox UUID twice (once for testing, once for "real") creates two separate "toolboxes" in the Add-On Manager's eyes | HIGH (footgun) | The UUID lives in `toolboxOptions.m`, committed once, never changed. Document in the file as a giant warning. |
| Backward compatibility breaks because some user's path setup assumed `nSTAT/Analysis.m` and the `.mltbx` install puts it at `nSTAT/toolbox/Analysis.m` (if G4 materializes the `toolbox/` directory) | LOW (G4 is optional + at packaging time, not in tree) | G4 keeps the tree unchanged. |
| `buildtool` requires R2024a+ and the team's CI environment doesn't have it | MED | `buildtool` ships in R2022b+. The team uses R2025b. CI is Python-only for now. No blocker. |

## 12. Acceptance criteria (overall plan)

- [x] Plan written (this doc).
- [ ] G1: `buildfile.m` exists; `buildtool` runs cleanly.
- [ ] G2: `toolboxOptions.m` exists; `release/nSTAT.mltbx` builds.
- [ ] G3: File Exchange listing exists; "Open in MATLAB Online" badge in README.
- [ ] First `.mltbx` attached to a tagged release (probably v1.4.2 or v1.5.0).
- [ ] No existing test regresses; no documented user path breaks.

## 13. Suggested execution order

1. **G1 first (4–6 hr).** Author `buildfile.m`; wire the existing tools as tasks. This is pure infrastructure — no user-visible change. Land in a PR alongside the existing `tools/*.sh` scripts (deprecation, not removal).
2. **G2 next (4–6 hr).** Author `toolboxOptions.m` + `packageToolbox.m`. Generate the toolbox UUID, commit it. Build the first `.mltbx` locally, smoke-test the install on a fresh MATLAB session. Land in a PR.
3. **G3 once G2 lands (1–2 hr + waiting).** Submit File Exchange listing; add badges to README. The "Open in MATLAB Online" badge is the highest-leverage single change in the plan.
4. **G4 and G5 are optional.** Defer until G1–G3 prove the modernization is being consumed (File Exchange download count > 0; Add-On Explorer install attempts > 0).
5. **Tag v1.5.0 after G2.** The `.mltbx` packaging is a *minor* version bump per semver (new feature: install via Add-Ons) even though no API changes.

If energy is short, do **G1 only**. The 8-script-consolidation is a real maintainability win; the `.mltbx` packaging can wait.

## 14. Open questions for the user (decision gates)

1. **Are you willing to tag v1.5.0 for the `.mltbx` packaging release?** Per semver this is the right bump. Alternative: v1.4.2 with the `.mltbx` as a "feature backport".
2. **Submit to File Exchange now or after G4?** Earlier = more time for downloads to accumulate; later = a more polished listing.
3. **Generate a fresh toolbox UUID or claim the figshare DOI as the identity?** UUID is mandatory for Add-On Manager; figshare DOI is for citation. They serve different purposes. Recommend: fresh UUID.
4. **Live Script `GettingStarted.mlx` — port `HelloNstat.m` or write fresh?** `.mlx` is the canonical format; `.m` works but is non-canonical. ~1 hour to port.
5. **Open-in-MATLAB-Online target file — `HelloNstat.m` or a new tutorial?** `HelloNstat.m` is the established onboarding; new tutorial would be a separate effort.
