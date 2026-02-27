%% Paper-Aligned Toolbox Map
% This page aligns the nSTAT toolbox documentation with the original toolbox
% paper:
%
% * Cajigas I, Malik WQ, Brown EN. nSTAT: Open-source neural spike train
%   analysis toolbox for Matlab. Journal of Neuroscience Methods 211:
%   245-264 (2012).
% * DOI: 10.1016/j.jneumeth.2012.08.009
% * PMID: 22981419
%
% Full text links:
%
% * <https://pubmed.ncbi.nlm.nih.gov/22981419/ PubMed Record>
% * <https://pmc.ncbi.nlm.nih.gov/articles/PMC3491120/ PMC Full Text>
%
%% Class Hierarchy and Object Model
% nSTAT is organized around reusable signal and trial abstractions.
%
% * Signal and covariate primitives: `SignalObj`, `Covariate`,
%   `ConfidenceInterval`, `CovColl`
% * Spiking data structures: `nspikeTrain`, `nstColl`, `History`, `Events`
% * Experiment and configuration objects: `Trial`, `TrialConfig`, `ConfigColl`
% * Modeling and inference objects: `CIF`, `Analysis`, `FitResult`,
%   `FitResSummary`, `DecodingAlgorithms`
%
% Class references and examples:
%
% * <ClassDefinitions.html Class Definitions>
% * <Examples.html Example Index>
%
%% Fitting and Assessment Workflow
% The paper's core workflow fits point-process GLMs and evaluates fit quality.
%
% 1. Build trial data with `Trial`, `CovColl`, and `nstColl`.
% 2. Define candidate models with `TrialConfig` and `ConfigColl`.
% 3. Fit models with `Analysis.RunAnalysisForNeuron` or
%    `Analysis.RunAnalysisForAllNeurons`.
% 4. Assess goodness-of-fit using `FitResult` diagnostics (KS, residuals,
%    confidence bands) and summarize across neurons with `FitResSummary`.
%
% Related examples:
%
% * <AnalysisExamples.html Analysis Examples>
% * <FitResultExamples.html FitResult Examples>
% * <FitResSummaryExamples.html FitResSummary Examples>
%
%% Simulation Workflow
% The toolbox supports simulation of point-process and related neural models.
%
% * Conditional intensity specification and simulation: `CIF`
% * Thinning-based point-process simulation:
%   <PPThinning.html Point Process Simulation via Thinning>
% * End-to-end simulated analysis:
%   <PPSimExample.html Simulated Explicit Stimulus and History>
%
%% Decoding Workflow
% nSTAT includes point-process and Gaussian-state decoding algorithms that are
% described in the paper's adaptive filtering sections.
%
% * Static decoding methods: `DecodingAlgorithms`
% * Example workflows:
%   <DecodingExample.html Decoding Univariate Simulated Stimuli>,
%   <DecodingExampleWithHist.html Decoding with History>, and
%   <StimulusDecode2D.html Decoding Bivariate Simulated Stimuli>
%
%% Example-to-Paper Section Mapping
% The examples below correspond directly to the paper's representative
% workflows.
%
% * <mEPSCAnalysis.html mEPSCAnalysis> and
%   <PSTHEstimation.html PSTHEstimation>: model-based event process analysis
% * <ExplicitStimulusWhiskerData.html Explicit Stimulus> and
%   <HippocampalPlaceCellExample.html Place Cell Receptive Fields>:
%   stimulus-response and receptive field modeling
% * <DecodingExample.html DecodingExample>,
%   <DecodingExampleWithHist.html DecodingExampleWithHist>, and
%   <StimulusDecode2D.html StimulusDecode2D>: decoding and state estimation
% * <nSTATPaperExamples.html nSTAT Paper Examples>: consolidated reproduction
%   workflow for paper analyses
