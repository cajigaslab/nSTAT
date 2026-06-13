% nstat.decoding — Decoding-algorithm package (Phase 3 destination)
%
% **Status (2026-05): SKELETON ONLY.** This package directory establishes
% the target layout for the Phase 3 split of `DecodingAlgorithms.m` (a
% 10860-LOC single classdef holding 48 static methods). The actual code
% movement is staged across follow-up PRs per the action plan at
% `docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md`
% (Phase 3 Task 3.2).
%
% Today everything still lives in `DecodingAlgorithms.m` at the repo
% root. This package is a placeholder — calling `nstat.decoding.PPAF`
% etc. will NOT work yet. The classes listed below are the planned
% destinations.
%
% ------------------------------------------------------------------------
% Planned class partitions
% ------------------------------------------------------------------------
%
% nstat.decoding.PPAF
% Point-process adaptive filter (Eden, Frank, Barbieri, Solo &
% Brown 2004.B.5).
% Source today: DecodingAlgorithms.{PPDecodeFilter,
% PPDecodeFilterLinear, PPDecode_predict, PPDecode_update,
% PPDecode_updateLinear, PP_fixedIntervalSmoother}.
%
% nstat.decoding.PPHF
% Point-process hybrid filter — joint discrete + continuous state
% (Srinivasan, Eden, Mitter & Brown 2007.B.8).
% Source today: DecodingAlgorithms.{PPHybridFilter,
% PPHybridFilterLinear}.
% **Naming caveat:** PPDecodeFilterLinear is NOT the PPHF — that
% name belongs to the linear-CIF PPAF (above). The "Linear" suffix
% means two different things in the current nSTAT naming.
%
% nstat.decoding.SSGLM
% State-space GLM — trial-drifting coefficients via EM
% (Czanner et al. 2008.B.6).
% Source today: DecodingAlgorithms.{PPSS_EM, PPSS_EStep,
% PPSS_MStep, PPSS_EMFB}.
%
% nstat.decoding.PPLFP
% Multi-modal spike + LFP sensor-fusion filter
% (Cajigas 2013 unpublished derivation `source/PPLFPFilter_final.pdf`;
% §4.B.7).
% Source today: DecodingAlgorithms.{PPLFP_DecodeLinear,
% PPLFP_Decode_predict, PPLFP_Decode_update, PPLFP_EM,
% PPLFP_EStep, PPLFP_MStep, PPLFP_EMCreateConstraints,
% PPLFP_ComputeParamStandardErrors, PPLFP_fixedIntervalSmoother}.
% Renamed from mPPCO_* in 2026-05 (commit 428c344); 9 deprecation
% shims preserve the old name.
%
% nstat.decoding.KalmanFilter
% Linear-Gaussian state-space filter, smoother, and RTS pass.
% Source today: DecodingAlgorithms.{kalman_filter, kalman_smoother,
% kalman_smootherFromFiltered, kalman_fixedIntervalSmoother}.
%
% nstat.decoding.KF_EM
% EM parameter learning for the linear-Gaussian state-space model.
% Source today: DecodingAlgorithms.{KF_EM, KF_EStep, KF_MStep,
% KF_ComputeParamStandardErrors, KF_EMCreateConstraints}.
%
% nstat.decoding.PointProcessEM
% Pure point-process EM (no continuous observation; the PPLFP
% family with C=R=alpha=0).
% Source today: DecodingAlgorithms.{PP_EM, PP_EStep, PP_MStep,
% PP_EMCreateConstraints, PP_ComputeParamStandardErrors}.
%
% nstat.decoding.UKF
% Unscented Kalman filter helpers.
% Source today: DecodingAlgorithms.{ukf, ukf_ut, ukf_sigmas}.
%
% ------------------------------------------------------------------------
% Planned internal helpers (nstat.decoding.internal — package-private)
% ------------------------------------------------------------------------
%
% nstat.decoding.internal.computeGainMatrix
% Woodbury-form posterior update shared by PPAF, PPHF, and PPLFP.
% Currently duplicated verbatim in 4 sites inside
% DecodingAlgorithms.m (PPDecode_update, PPDecode_updateLinear,
% PPLFP_Decode_update, PPHybridFilter variants). Plan Task 3.4.
%
% nstat.decoding.internal.defaultTolerances
% Centralised EM convergence tolerances. Currently scattered as
% hardcoded 1e-3 / 1e-6 / 100 / 10 throughout DecodingAlgorithms.m.
% Plan Task 3.3.
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%
% Cajigas I, Malik WQ, Brown EN. nSTAT: Open-source neural spike train
% analysis toolbox for Matlab. J Neurosci Methods 211:245-264 (2012).
%.md (the canonical math
% derivations for everything in this package).
% docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md Phase 3.
