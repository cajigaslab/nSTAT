%% nSTAT decision tree: which class / method do I need?
%
% This page answers "I have X, I want to do Y -- which nSTAT pieces?"
% Use it after |HelloNstat.m| and before diving into individual
% example pages.
%
% Cross-reference: this is the navigation page; each leaf below
% points to a worked example.

%% Decision 1: data shape
%
% * *You have spike times / spike trains:* continue with this guide.
% * *You have continuous signals (LFP/EEG/ECoG):* use |SignalObj|.
% * *You have both:* use both -- see "multi-modal sensor fusion" below.

%% Decision 2: what do you want to do?
%
% * Fit a *stationary* GLM to spike trains (no drift across trials):
% see Section A.
% * Fit a *non-stationary* GLM where coefficients drift across trials:
% see Section B (SSGLM).
% * *Decode* a continuous latent state (e.g., kinematics, cursor
% velocity) from spike trains: see Section C (PPAF).
% * *Decode* a joint discrete + continuous state (e.g., reach class +
% trajectory): see Section D (PPHF).
% * *Multi-modal* decoding from both spikes AND LFP: see Section E
% (PPLFP).
% * *Simulate* a point process from a known intensity function: see
% Section F (CIF.simulateCIF).

%% Section A: fitting a stationary PP-GLM
%
% *Classes:* nspikeTrain, nstColl, Covariate, CovColl, Trial,
% TrialConfig, ConfigColl, Analysis, FitResult.
%
% *One-line summary:* Build |Trial(nstColl, CovColl, Events, History)|,
% define a |TrialConfig| listing which covariates the GLM uses, call
% |Analysis.RunAnalysisForNeuron|, inspect the returned |FitResult|.
%
% *For canonical-link cases (Poisson with log link or binomial with
% logit link) you can avoid the Symbolic Math Toolbox by passing
% |LinearCIF| instead of the symbolic |CIF|* (Phase 3 Task 3.5).
%
% *Worked example:* |helpfiles/HelloNstat.m| (the minimum case),
% |helpfiles/AnalysisExamples.m| (deeper coverage).
%
% *Curriculum reference:* sec. 4.B.1 (PP-GLM with Poisson and binomial
% parameterizations).

%% Section B: SSGLM for trial-drifting coefficients
%
% *Class:* |nstat.decoding.SSGLM|.
%
% *One-line summary:* Random-walk evolution of GLM coefficients across
% trials, fit by EM. Use when you suspect learning, plasticity, or
% chronic-array drift.
%
% *Methods:* PPSS_EM (main loop), PPSS_EMFB (forward-backward variant),
% PPSS_EStep, PPSS_MStep.
%
% *Worked example:* |helpfiles/nSTATPaperExamples.m| (PSTH + SSGLM
% comparison, Section 2.3.3 of the 2012 paper).
%
% *Curriculum reference:* sec. 4.B.6 SSGLM (Czanner et al. 2008).

%% Section C: PPAF -- decoding continuous state from spikes
%
% *Class:* |nstat.decoding.PPAF|.
%
% *One-line summary:* The spike-train analog of the Kalman filter.
% Linear-Gaussian state dynamics + Poisson spike observations, closed
% by a Laplace approximation. Real-time, recursive.
%
% *Methods:*
%
% * |PPDecodeFilter| -- general (symbolic) CIF.
% * |PPDecodeFilterLinear| -- canonical-link linear CIF (faster).
% * |PPDecode_predict| -- time-update step.
% * |PPDecode_update| -- measurement-update step.
% * |PPDecode_updateIterated| -- iterated-Laplace variant (Phase 4
% Task 4.1).
%
% *Worked example:* |helpfiles/DecodingExample.m|,
% |examples/paper/example05_decoding_ppaf_pphf.m|.
%
% *Curriculum reference:* sec. 4.B.5 PPAF; sec. 4.C.2 PPAF as Newton
% step on the variational free energy.

%% Section D: PPHF -- joint discrete + continuous state
%
% *Class:* |nstat.decoding.PPHF|.
%
% *One-line summary:* Markov-modeling extension of PPAF. Joint
% posterior over a discrete state (Markov chain) and a continuous
% state with state-conditional dynamics. Examples: phoneme +
% articulator kinematics, sleep stage + autonomic state, DBS "on/off"
% + symptom severity.
%
% *Methods:*
%
% * |PPHybridFilter| -- general CIF.
% * |PPHybridFilterLinear| -- canonical-link linear CIF.
%
% *Worked example:* |helpfiles/HybridFilterExample.m|,
% |examples/paper/example05_decoding_ppaf_pphf.m|.
%
% *Curriculum reference:* sec. 4.B.8 PPHF (Srinivasan et al. 2007);
% sec. 4.C.3 PPHF derivation.

%% Section E: PPLFP -- multimodal spike + LFP sensor fusion
%
% *Class:* |nstat.decoding.PPLFP| (renamed from the historical
% |mPPCO_*| family in Phase 3 Task 3.1; legacy names still work via
% deprecation shims).
%
% *One-line summary:* Joint posterior over a continuous state given
% BOTH Poisson spike observations AND Gaussian LFP-power observations.
% Additive innovations + shared posterior covariance. Classical
% foundation for joint multimodal point-process inference.
%
% *Methods:*
%
% * |PPLFP_DecodeLinear| -- online filter.
% * |PPLFP_Decode_predict|, |PPLFP_Decode_update| -- predict/update
% primitives.
% * |PPLFP_EM|, |PPLFP_EStep|, |PPLFP_MStep| -- EM parameter learning.
%
% *Worked example:* Adapt the example05 PPAF/PPHF skeleton with the
% LFP-observation arguments.
%
% *Curriculum reference:* sec. 4.B.7 PPLFP (Cajigas 2013 unpublished;
% boxed equations sec. 4.B.7.3).

%% Section F: simulating point processes
%
% *Class:* |CIF|.
%
% *One-line summary:* Construct a symbolic conditional intensity
% function, simulate spike trains by thinning (Lewis-Shedler 1978) or
% time-rescaling (Brown 2002 inverse construction).
%
% *Methods:*
%
% * |CIF.simulateCIF|, |CIF.simulateCIFByThinning|.
%
% *For pure-Poisson-from-rate simulation* the
% |nspikeTrain.simulatePoissonFromRate| helper (planned) or the inline
% pattern in |helpfiles/HelloNstat.m| is simpler. Use |CIF| only when
% you need a symbolic CIF with history coefficients.
%
% *Curriculum reference:* sec. 4.A.3 (worked example: simulating an
% inhomogeneous Poisson process).

%% Cross-class composability
%
% These classes compose:
%
% * |Trial| aggregates |nstColl + CovColl + Events + History|.
% * |History| can be constructed with
% |History.raisedCosine(K, tMin, tMax)| (Pillow 2008 log-spaced
% basis; Phase 3 Task 3.6).
% * |LinearCIF| (Phase 3 Task 3.5) is a drop-in replacement for |CIF|
% in the canonical-link cases (5 eval methods agreeing to 1e-12),
% avoiding the Symbolic Math Toolbox dependency.
% * |Analysis.computeKSStats| accepts any |Covariate| representing a
% predicted rate -- including outputs from non-nSTAT models.

%% Defaults you might want to override
%
% |+nstat/Defaults.m| centralizes EM tolerances, ring-buffer sizes,
% PPAF Newton iterations, KS regime bounds, etc. (Phase 3 Task 3.3).
% Override at the method's call site by passing a different value
% rather than editing Defaults.m globally.

%% Where the implementations live
%
% After Phase 3 Task 3.2 (commit ed435f7 in master), all algorithmic
% code lives in |+nstat/+decoding/|. |DecodingAlgorithms.m| is a thin
% deprecation-shim facade. New code should call
% |nstat.decoding.PPAF.*| / |nstat.decoding.PPHF.*| etc. directly.
%
% Helper methods that don't belong to any single cluster
% (prepareEMResults, ComputeStimulusCIs, estimateInfoMat,
% computeSpikeRateCIs, computeSpikeRateDiffCIs) remain on
% |DecodingAlgorithms| until a future Phase 4 follow-up relocates them
% to |nstat.decoding.internal|.

%% References
%
% * The 2012 toolbox paper: Cajigas, Malik, Brown. _J Neurosci Methods_
%   211:245-264.
% * Eden, Frank, Barbieri, Solo & Brown 2004 (PPAF); Srinivasan, Eden,
%   Mitter & Brown 2007 (PPHF); Czanner et al. 2008 (SSGLM); Brown,
%   Barbieri, Ventura, Kass & Frank 2002 (time-rescaling).
% * |RELEASE_NOTES.md| for the v1.4 / v1.4.1 / v1.5 release notes.
