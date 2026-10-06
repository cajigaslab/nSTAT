classdef testKFEMInformationCriteria < matlab.unittest.TestCase
    %TESTKFEMINFORMATIONCRITERIA (KF track M, item C4; same defect class
    % as PP/PPLFP's bac99f9 SE-scale bug and 8843a94/F10 IC-scale bug)
    % KF_RunEM left xKFinal, WKFinal, ll and ExpectationSumsFinal on the
    % internal Tq/Tr-scaled system (from the loop's own x_K/W_K/ll/
    % ExpectationSums) while Ahat/Qhat/Chat/Rhat/alphahat/x0hat/Px0hat
    % were mapped back to the original scale, and y (scaled at setup via
    % y = Tr*y) was never restored. The SE call and the IC formula below
    % then mixed scaled sums/y with original-scale estimates. Now the
    % E-step is recomputed once, from the unscaled parameters and the
    % original y: the Kalman filter/RTS smoother is exactly equivariant
    % under this linear change of variables, so this reproduces (rather
    % than approximates) the original-coordinate values, all mutually
    % consistent on one scale.
    %
    % These tests check the IC formula directly, via one E-step at
    % fixed, consistent parameters (not by running the EM loop, so the
    % comparison is not confounded by the loop's own iteration-count
    % sensitivity -- Q/R can walk toward a degenerate value near
    % convergence, and that walk is not bit-identical between two
    % differently-scaled EM runs even though it mathematically should
    % be): exactly the quantities the post-loop block now feeds into the
    % same formula KF_RunEM uses.

    methods (Test)
        function testInformationCriteriaInvariantToStateScaling(tc)
            % Rescaling ONLY the latent state by t (x -> t x: A
            % unchanged, Q -> t^2 Q, C -> C/t, x0 -> t x0,
            % Px0 -> t^2 Px0; y, R, alpha unchanged) must leave llobs /
            % AIC / AICc / BIC unchanged, and llcomp shifts by the state
            % Jacobian, -(K+1)*dx*log(t) -- one factor per state density
            % x_0..x_K.
            t = 2.5;
            P = testKFEMInformationCriteria.scalarProblem();
            K = size(P.y, 2); dx = 1;
            IC0 = testKFEMInformationCriteria.icFromEStep(P.A,P.Q,P.C,P.R,P.y,P.alpha,P.x0,P.Px0);
            IC1 = testKFEMInformationCriteria.icFromEStep(P.A,t^2*P.Q,P.C/t,P.R,P.y,P.alpha,t*P.x0,t^2*P.Px0);
            % RelTol is 2e-3, not the brief's 1e-8 for the PP/PPLFP
            % EM-internal comparisons: those compare the SAME internal
            % scaled loop (t cancels out of Tq algebraically), but this
            % runs the Kalman filter/smoother TWICE at genuinely
            % different parameter magnitudes, so it also picks up the
            % two runs' different floating-point conditioning over
            % K=300 recursive steps.
            for f = {'llobs', 'AIC', 'AICc', 'BIC'}
                tc.verifyEqual(IC1.(f{1}), IC0.(f{1}), 'RelTol', 2e-3, ...
                    ['KF_EM IC.' f{1} ' must not depend on the units of x']);
            end
            tc.verifyEqual(IC1.llcomp, IC0.llcomp - (K+1)*dx*log(t), 'RelTol', 2e-3, ...
                'KF_EM IC.llcomp Jacobian under state rescaling');
        end

        function testInformationCriteriaShiftsUnderObservationScaling(tc)
            % Rescaling ONLY the observation by s (y -> s y, C -> s C,
            % R -> s^2 R, alpha -> s alpha; state A, Q, x0, Px0
            % unchanged): llobs and llcomp (both expectations of
            % log p(y | x), a continuous density) must shift by the
            % observation Jacobian, -K*dy*log(s) -- the same shift the
            % brief's PPLFP test requires for its y -> 2y case; unlike
            % state rescaling, this is not absorbed by llobs (there is
            % no state-density Jacobian to cancel it).
            s = 1.7;
            P = testKFEMInformationCriteria.scalarProblem();
            K = size(P.y, 2); dy = 1;
            IC0 = testKFEMInformationCriteria.icFromEStep(P.A,P.Q,P.C,P.R,P.y,P.alpha,P.x0,P.Px0);
            IC1 = testKFEMInformationCriteria.icFromEStep(P.A,P.Q,s*P.C,s^2*P.R,s*P.y,s*P.alpha,P.x0,P.Px0);
            tc.verifyEqual(IC1.llobs, IC0.llobs - K*dy*log(s), 'RelTol', 1e-9, ...
                'KF_EM IC.llobs Jacobian under observation rescaling');
            tc.verifyEqual(IC1.llcomp, IC0.llcomp - K*dy*log(s), 'RelTol', 1e-9, ...
                'KF_EM IC.llcomp Jacobian under observation rescaling');
        end
    end

    methods (Static, Access = private)
        function IC = icFromEStep(A,Q,C,R,y,alpha,x0,Px0)
            % Reproduces KF_RunEM's IC formula from a single E-step.
            [~,~,ll,ES] = nstat.decoding.KF_EM.KF_EStep(A,Q,C,R,y,alpha,x0,Px0);
            Dx = size(A,2); K = size(y,2);
            IC.llobs = ll + Dx*K/2*log(2*pi)+K/2*log(det(Q)) ...
                + 1/2*trace(Q\ES.sumXkTerms) ...
                + Dx/2*log(2*pi)+1/2*log(det(Px0)) + 1/2*Dx;
            IC.llcomp = ll;
            nTerms = numel(A) + numel(Q) + numel(C) + numel(R) + numel(Px0) + numel(x0) + numel(alpha);
            IC.AIC = 2*nTerms - 2*IC.llobs;
            IC.AICc = IC.AIC + 2*nTerms*(nTerms+1)/(K-nTerms-1);
            IC.BIC = -2*IC.llobs + nTerms*log(K);
        end

        function P = scalarProblem()
            rng(5); P.A = 0.9; P.Q = 0.02; P.C = 1.3; P.R = 0.05; P.alpha = 0.2;
            N = 300; P.x0 = 0; P.Px0 = 1e-6;
            x = zeros(1,N); xp = 0;
            for k = 1:N, xp = P.A*xp + sqrt(P.Q)*randn; x(k) = xp; end
            P.y = P.C*x + P.alpha + sqrt(P.R)*randn(1,N);
        end
    end
end
