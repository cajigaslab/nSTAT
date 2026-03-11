% nSTAT - Neural Spike Train Analysis Toolbox
% Version 1.2 11-Mar-2026
%
% nSTAT implements point process generalized linear models and related
% algorithms for neural spike train data analysis. See README.md for
% full details.
%
% Reference:
%   Cajigas I, Malik WQ, Brown EN. nSTAT: Open-source neural spike train
%   analysis toolbox for Matlab. J Neurosci Methods. 2012;211(2):245-264.
%
% Core Classes
%   SignalObj          - Continuous time signal representation
%   Covariate          - Named multivariate covariate (extends SignalObj)
%   CovColl            - Collection of Covariate objects
%   nspikeTrain        - Single neural spike train (point process)
%   nstColl            - Collection of nspikeTrain objects
%   Events             - Labeled experimental events
%   History            - Spike history basis functions
%   Trial              - Combines spikes, covariates, events, history
%   TrialConfig        - Configuration for Trial-based analysis
%   ConfigColl         - Collection of TrialConfig objects
%   Analysis           - GLM fitting engine for point process models
%   FitResult          - Single model fit result
%   FitResSummary      - Summary across multiple FitResult objects
%   CIF                - Conditional Intensity Function (symbolic CIF)
%   ConfidenceInterval - Confidence interval (extends SignalObj)
%
% Algorithms
%   DecodingAlgorithms - Point process adaptive filters and decoders
%
% Utilities
%   nSTAT_Install      - Add nSTAT directories to the MATLAB path
%   getPaperDataDirs   - Resolve paths to example data directories
%
% Examples and Help
%   Open the nSTAT documentation from the MATLAB Help browser under
%   Supplemental Software, or run:
%       doc nSTAT
%   For the example index, run:
%       nstatOpenHelpPage('Examples')
%
% Copyright (c) 2012-2026 Iahn Cajigas, Wasim Malik, Emery N. Brown
% See LICENSE for details.
