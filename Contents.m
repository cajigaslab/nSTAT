% nSTAT - Neural Spike Train Analysis Toolbox
% Version 1.5 13-Jun-2026
%
% nSTAT implements point process generalized linear models and related
% algorithms for neural spike train data analysis. See README.md for
% full details. The May 2026 release (v1.4) added the +nstat/+decoding
% package (cluster-class decomposition of DecodingAlgorithms), the
% LinearCIF canonical-link conditional intensity (closed-form
% derivatives, no Symbolic Math Toolbox required), History.raisedCosine
% (Pillow 2008 log-spaced basis), and the README figure parity gate.
%
% Reference:
%   Cajigas I, Malik WQ, Brown EN. nSTAT: Open-source neural spike train
%   analysis toolbox for Matlab. J Neurosci Methods. 2012;211(2):245-264.
%
% Core Classes (repo root)
%   SignalObj          - Continuous time signal representation
%   Covariate          - Named multivariate covariate (extends SignalObj)
%   CovColl            - Collection of Covariate objects
%   nspikeTrain        - Single neural spike train (point process)
%   nstColl            - Collection of nspikeTrain objects
%   Events             - Labeled experimental events
%   History            - Spike history basis functions (use
%                        History.raisedCosine(K, tMin, tMax) for the
%                        Pillow 2008 log-spaced cosine basis)
%   Trial              - Combines spikes, covariates, events, history
%   TrialConfig        - Configuration for Trial-based analysis
%   ConfigColl         - Collection of TrialConfig objects
%   Analysis           - GLM fitting engine for point process models
%   FitResult          - Single model fit result
%   FitResSummary      - Summary across multiple FitResult objects
%   CIF                - Conditional Intensity Function (symbolic CIF)
%   LinearCIF          - Canonical-link CIF with closed-form gradient and
%                        Hessian (drop-in replacement for CIF when the
%                        symbolic dependency is undesirable)
%   ConfidenceInterval - Confidence interval (extends SignalObj)
%
% Decoding (+nstat/+decoding/ package, v1.4+)
%   nstat.decoding.KalmanFilter    - Kalman filter / smoother
%   nstat.decoding.UKF             - Unscented Kalman filter
%   nstat.decoding.PPAF            - Point-process adaptive filter
%   nstat.decoding.PPHF            - Point-process hybrid filter
%   nstat.decoding.PPLFP           - Spike + LFP sensor fusion filter
%   nstat.decoding.SSGLM           - State-space GLM
%   nstat.decoding.KF_EM           - Kalman EM
%   nstat.decoding.PointProcessEM  - Point-process EM
%   DecodingAlgorithms             - Legacy static-method facade with
%                                    deprecation shims forwarding to
%                                    nstat.decoding.*; new code should
%                                    use the package classes directly
%
% Configuration (+nstat/ package)
%   nstat.Defaults     - Centralized tolerances (EM_TolAbs, EM_MaxIter,
%                        DTRegimeBound, etc.)
%   nstat.setPlotStyle - Switch plot style: 'modern' (default) or
%                        'legacy' (strict 2012 reproduction)
%
% Utilities
%   nSTAT_Install      - Add nSTAT directories to the MATLAB path
%   getPaperDataDirs   - Resolve paths to example data directories
%
% Tools (tools/, not on default path)
%   tools/build_paper_examples.m   - Regenerate the README figure gallery
%   tools/check_readme_figures.sh  - Verify gallery matches current code
%   tools/run_unit_tests.sh        - Local test gate (unit +
%                                    --integration); CI does not run
%                                    MATLAB
%
% Examples and Help
%   Open the nSTAT documentation from the MATLAB Help browser under
%   Supplemental Software, or run:
%       doc nSTAT
%   For the example index, run:
%       nstatOpenHelpPage('Examples')
%   The canonical onboarding tutorial is HelloNstat (helpfiles/HelloNstat.m).
%   For algorithm-selection guidance see WhenToUseWhich (helpfiles/WhenToUseWhich.m).
%
% Copyright (c) 2012-2026 Iahn Cajigas, Wasim Malik, Emery N. Brown
% See LICENSE for details.
