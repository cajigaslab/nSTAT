function opts = toolboxOptions
%TOOLBOXOPTIONS Declarative packaging configuration for nSTAT.
%
% Returns a matlab.addons.toolbox.ToolboxOptions object that describes
% how the .mltbx is built. Used by packageToolbox.m (which is invoked
% from the 'package' task in buildfile.m).
%
% IMPORTANT: the IDENTIFIER below is a one-time UUID that uniquely
% identifies this toolbox to the MATLAB Add-On Manager. NEVER change
% it after the first publication -- if the UUID changes, the Add-On
% Manager treats it as a different toolbox and will not recognize
% updates as updates.
%
% Reference: docs/superpowers/plans/2026-06-13-toolbox-modernization.md

repoRoot = fileparts(mfilename("fullpath"));

% The toolbox identifier. Generated 2026-06-13 via
% char(matlab.lang.internal.uuid). DO NOT CHANGE.
identifier = "435c3da4-5a9f-459f-bad5-74c72e9cae4a";

opts = matlab.addons.toolbox.ToolboxOptions(repoRoot, identifier);

% --- Metadata ----------------------------------------------------------
opts.ToolboxName     = "nSTAT";
opts.ToolboxVersion  = "1.4.1";
opts.Description     = "Neural Spike Train Analysis Toolbox for MATLAB. Point-process and state-space methods for spike-train analysis: PP-GLM fitting (Poisson and binomial), time-rescaling KS goodness-of-fit, PPAF (point-process adaptive filter), PPHF (hybrid discrete + continuous-state filter), SSGLM (state-space GLM), and PPLFP (multi-modal spike + LFP sensor-fusion filter).";
opts.Summary         = "Point-process and state-space methods for spike-train analysis (Cajigas, Malik & Brown 2012).";

opts.AuthorName      = "Iahn Cajigas, Wasim Q. Malik, Emery N. Brown";
opts.AuthorEmail     = "iahn.cajigas@gmail.com";
opts.AuthorCompany   = "Cajigas Lab (RESToRe Lab)";

% --- Files to include in the package -----------------------------------
% Default: everything under repoRoot EXCEPT entries in ToolboxFiles
% exclusions. The ToolboxOptions constructor seeds ToolboxFiles with
% the full tree; trim what shouldn't ship to end users.
filesToExclude = [
    % Dev infrastructure (not user-facing)
    fullfile(repoRoot, ".git")
    fullfile(repoRoot, ".github")
    fullfile(repoRoot, ".gitignore")
    fullfile(repoRoot, ".gitattributes")
    fullfile(repoRoot, ".claude")
    fullfile(repoRoot, "CLAUDE.md")
    fullfile(repoRoot, "_build")
    fullfile(repoRoot, "release")
    fullfile(repoRoot, "buildfile.m")
    fullfile(repoRoot, "toolboxOptions.m")
    fullfile(repoRoot, "packageToolbox.m")
    % Tests + fixtures (not shipped)
    fullfile(repoRoot, "tests")
    fullfile(repoRoot, "fixtures")
    % Planning + verification docs (lab-internal)
    fullfile(repoRoot, "docs", "superpowers")
    fullfile(repoRoot, "docs", "verification")
    % Bulky figure artifacts (paper-examples ship as .m sources;
    % the figures live in the GitHub README, not the .mltbx)
    fullfile(repoRoot, "docs", "figures")
    fullfile(repoRoot, "docs", "_build")
    % The figshare paper-example dataset is downloaded post-install
    % by nSTAT_Install('DownloadExampleData', true). NEVER ship it in
    % the .mltbx (~480 MB; would explode toolbox size for no benefit).
    fullfile(repoRoot, "data")
    % Helpfile binary search index regenerates at install time via
    % nSTAT_Install('RebuildDocSearch', true). Don't ship the binary
    % blobs (multi-MB) in the .mltbx.
    fullfile(repoRoot, "helpfiles", "helpsearch-v4_en")
    fullfile(repoRoot, "helpfiles", "helpsearch-v3")
    fullfile(repoRoot, "helpfiles", "helpsearch")
    % Sphinx site source (the deployed site lives at
    % cajigaslab.github.io/nSTAT/; not shipped in the toolbox)
    fullfile(repoRoot, "docs", "intro.md")
    fullfile(repoRoot, "docs", "index.md")
    fullfile(repoRoot, "docs", "paper_examples.md")
    fullfile(repoRoot, "docs", "conf.py")
    % Misc.
    fullfile(repoRoot, "porting")
    fullfile(repoRoot, "libraries")
    fullfile(repoRoot, "test-results")
    fullfile(repoRoot, "slprj")
    fullfile(repoRoot, "tmp")
];
keep = true(numel(opts.ToolboxFiles), 1);
for i = 1:numel(opts.ToolboxFiles)
    f = string(opts.ToolboxFiles(i));
    for j = 1:numel(filesToExclude)
        ex = string(filesToExclude(j));
        if startsWith(f, ex)
            keep(i) = false;
            break;
        end
    end
end
opts.ToolboxFiles = opts.ToolboxFiles(keep);

% --- Path additions at install time ------------------------------------
% End users get these directories added to the MATLAB path. Namespace
% packages (folders starting with "+") are DELIBERATELY NOT listed:
% MATLAB discovers them automatically when their PARENT folder is on the
% path. Adding the repo root puts +nstat/ on the namespace path.
opts.ToolboxMatlabPath = [
    "."
    "tools"
    fullfile("examples", "paper")
];

% --- Compatibility -----------------------------------------------------
% buildtool itself requires R2022b+. MATLAB.addons.toolbox.ToolboxOptions
% is R2023a+. nSTAT_Install/CIF/SignalObj work back to ~R2020a but we
% target the modern release as the supported floor.
opts.MinimumMatlabRelease = "R2024a";

opts.SupportedPlatforms.Win64       = true;
opts.SupportedPlatforms.Maci64      = true;
opts.SupportedPlatforms.Glnxa64     = true;
opts.SupportedPlatforms.MatlabOnline = true;

% --- Getting Started Guide ---------------------------------------------
% Auto-shown by the Add-On Manager when the user installs the .mltbx.
% Points at the canonical onboarding tutorial.
opts.ToolboxGettingStartedGuide = fullfile(repoRoot, "helpfiles", "HelloNstat.m");

% --- Output ------------------------------------------------------------
releaseDir = fullfile(repoRoot, "release");
if ~exist(releaseDir, "dir")
    mkdir(releaseDir);
end
opts.OutputFile = fullfile(releaseDir, "nSTAT-" + opts.ToolboxVersion + ".mltbx");
end
