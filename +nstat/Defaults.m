classdef Defaults
%DEFAULTS Centralized tolerances and numerical constants for nSTAT.
%
% Phase 3 Task 3.3 of the 2026-05-19 nSTAT review action plan.
%
% Until this class was introduced, EM tolerances were hardcoded literally
% (1e-3, 1e-6, 100, 10) and duplicated across KF_EM, SSGLM, PPLFP, and
% PointProcessEM. The duplication meant any sensitivity analysis or
% tightening of convergence criteria required editing 4-5 sites
% identically.
%
% Use:
%   tol = nstat.Defaults.EM_TolAbs;
%   maxIter = nstat.Defaults.EM_MaxIter;
%
% **Constants are documented WITH PROVENANCE.** Each value below records
% where it came from and what changes if you tune it. Do not change a
% value here without updating its provenance line and the corresponding
% test (if applicable).
%
% Refs: bci-curriculum chapter-04 §4.B.5 (PPAF tolerances),
%       §4.B.6 (SSGLM EM convergence),
%       §4.B.7 (PPLFP EM convergence),
%       §4.C.1 Cor. 2 (DT KS regime bound).

    properties (Constant)

        % --- EM convergence (used by KF_EM, SSGLM, PPLFP, PointProcessEM) ---

        % Absolute tolerance on parameter increments between EM iterations.
        % Provenance: original DecodingAlgorithms.m PPSS_EM (Czanner 2008
        % SSGLM); inherited by KF_EM, PPLFP, PP_EM.
        EM_TolAbs       = 1e-3;

        % Relative tolerance on parameter increments. Same provenance.
        EM_TolRel       = 1e-3;

        % Tolerance on log-likelihood change between EM iterations.
        EM_LogLTol      = 1e-3;

        % Maximum EM iterations. Provenance: standard cap from Czanner 2008
        % et seq. Exceeding 100 typically indicates a misspecified model
        % or singular Fisher information; see nstat.decoding §4.C.2 for
        % the variational-free-energy diagnosis.
        EM_MaxIter      = 100;

        % Ring-buffer size for parameter history. Stores the most recent
        % `EM_HistorySize` iterations of (A, Q, gamma, ...) so the EM
        % convergence check can compare iteration k against iteration
        % k-1. Provenance: original PPSS_EM design.
        EM_HistorySize  = 10;

        % --- PPAF / PPHF / PPLFP filter internals ---

        % Regularization added to PiT (target prior covariance) when not
        % explicitly supplied. Used in PPAF.PPDecodeFilter,
        % PPAF.PPDecodeFilterLinear, and PPHF.PPHybridFilter{,Linear}.
        % Provenance: original PPDecodeFilter implementation; 1e-6 chosen
        % to be small relative to typical state-noise scale.
        PiTRegularization = 1e-6;

        % Convergence threshold for the iterated Newton step inside the
        % PPAF gain-matrix computation (when Wconv is provided). Below
        % this absolute difference, the update is considered converged.
        FilterConvergenceTol = 1e-6;

        % --- PPAF Laplace approximation point ---

        % Number of Newton iterations for the Laplace approximation in
        % PPAF.PPDecode_update / PPDecode_updateLinear. The default of 1
        % is the "extended-Kalman" linearization at the prediction mean
        % (Eden et al. 2004; bci-curriculum §4.C.2). Set > 1 to iterate
        % Newton's method to the posterior mode (closer to the true
        % Laplace approximation; phase-3-task-4.1 will expose this as
        % a named-value argument).
        PPAF_NewtonIters = 1;

        % --- Numerical safety ---

        % Floor for `log()` arguments to prevent -Inf when lambdaDelta
        % approaches 0 or 1. Used by FitResult.addParamsToFit,
        % Analysis.GLMFit, FitResult.computeValLambda. Provenance: the
        % Phase 0 audit fixes (commits acd57c7, d1e96cf).
        EpsLog            = eps;  % Built-in MATLAB eps; ~2.22e-16

        % --- Discrete-time KS regime warning (Haslinger-Pipa-Brown 2010) ---

        % Maximum lambda*delta for which the discrete-time KS correction
        % is empirically valid. Provenance: bci-curriculum §4.C.1 Cor. 2
        % and reviews/ks-transformer-validation/ in the curriculum repo.
        % Beyond this bound the KS test biases toward acceptance.
        DTRegimeBound        = 0.4;

        % Fraction of bins exceeding DTRegimeBound that triggers the
        % nSTAT:DTCorrectionRegime warning in Analysis.computeKSStats.
        % Provenance: Phase 0 Task 0.3 (commit 6586b26); 1% threshold
        % avoids false positives on isolated edge bins.
        DTRegimeWarnFrac     = 0.01;

    end
end
