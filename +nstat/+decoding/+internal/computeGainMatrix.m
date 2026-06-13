function [W_u, isSingular] = computeGainMatrix(W_p, sumValMat)
%COMPUTEGAINMATRIX Woodbury-form posterior gain for PPAF / PPLFP updates.
%
% [W_u, isSingular] = nstat.decoding.internal.computeGainMatrix(W_p, sumValMat)
%
% Computes the Laplace-approximated posterior covariance for the
% point-process adaptive filter update step, using the Woodbury matrix
% identity to avoid inverting a possibly ill-conditioned (I + sumValMat)
% directly:
%
% W_u = W_p * (I - (I + sumValMat*W_p) \ (sumValMat*W_p))
%
% The result is then symmetrized to suppress floating-point asymmetry:
%
% W_u = 0.5 * (W_u + W_u')
%
% A singularity flag is returned: `isSingular` is true when the
% reciprocal-condition number falls below `eps` OR when any NaN/Inf
% appears in the gain matrix. Callers typically fall back to W_u = W_p
% in that case.
%
% Inputs:
% W_p — prior covariance from the predict step (n x n).
% sumValMat — sum of per-channel information contributions
% (Fisher + data-dependent curvature terms; n x n).
%
% Outputs:
% W_u — posterior gain matrix (n x n), symmetrized.
% isSingular — logical scalar; true if numerical singularity detected.
%
% Refs:
%.B.5 PPAF update; §4.C.2 PPAF as Newton
% step on the variational free energy;
% Eden, Frank, Barbieri, Solo & Brown 2004, Neural Comp 16:971-998 Eq. 2.6.
%
% Phase 3 Task 3.4 of the 2026-05-19 nSTAT review action plan: extracted
% from 4 duplicate sites in PPAF.PPDecode_update (1 site),
% PPAF.PPDecode_updateLinear (2 sites), and PPLFP.PPLFP_Decode_update
% (1 site). The unified singularity check is strictly more conservative
% than each prior site's: PPAF previously checked only rcond and PPLFP
% checked only NaN/Inf; this helper checks both.

 I = eye(size(W_p));
 W_u = W_p * (I - (I + sumValMat * W_p) \ (sumValMat * W_p));
 W_u = 0.5 * (W_u + W_u'); % symmetrize to suppress floating-point asymmetry

 cnum = rcond(W_u);
 isSingular = (cnum < eps) || isnan(cnum)...
 || any(isnan(W_u(:))) || any(isinf(W_u(:)));
end
