classdef testKFEMCovarianceInformationPrecedence < matlab.unittest.TestCase
    %TESTKFEMCOVARIANCEINFORMATIONPRECEDENCE (KF track M, item C2 / H1)
    % KF_ComputeParamStandardErrors' Q, R and Px0 complete-information
    % blocks used the pattern termMat = N/2*(Qhat)\em(:,m)*el(:,l)'/(Qhat)
    % (and the Rhat / Px0hat analogues). MATLAB evaluates *, / and \
    % left to right, so this was ((N/2)*Qhat)^-1*em*el'*Qhat^-1 =
    % (2/N)*Qhat^-1*em*el'*Qhat^-1 -- N^2/4 too small for Q and R (SE.Q,
    % SE.R about K/2 too large), and the Px0 analogue (1/2*(Px0hat)\...)
    % was 4x too large (SE.Px0 about 2x too small). The five sites are
    % now fully parenthesised: N/2*((Qhat)\em(:,m)*el(:,l)'/(Qhat)), etc.
    % This is the identical bug PointProcessEM/PPLFP had (H1,
    % tests/unit/testPointProcessEMCorrectness.m testCovarianceInformationFormsAgree).

    methods (Test)
        function testCovarianceInformationFormsAgree(tc)
            %TESTCOVARIANCEINFORMATIONFORMSAGREE with one state and one
            % observation channel, the diagonal, full and isotropic
            % parameterisations of Q and R describe the same single
            % parameter, so KF_ComputeParamStandardErrors must return
            % identical SEs for each (same inputs, same random state).
            % The isotropic forms (0.5*N*dx/q^2 etc.) were already right;
            % the diagonal / full forms had the precedence bug.
            P = testKFEMCovarianceInformationPrecedence.scalarProblem();
            cons0 = nstat.decoding.KF_EM.KF_EMCreateConstraints(1,0,1,0,1,0,0,0,0,200);
            [xK,WK,ll,ES] = nstat.decoding.KF_EM.KF_EStep(P.A,P.Q,P.C,P.R,P.y,P.alpha,P.x0,P.Px0); %#ok<ASGLU>
            rng(13);
            S0 = nstat.decoding.KF_EM.KF_ComputeParamStandardErrors(P.y,xK,WK,P.A,P.Q,P.C,P.R,P.alpha,P.x0,P.Px0,ES,cons0);
            variants = {
                nstat.decoding.KF_EM.KF_EMCreateConstraints(1,0,0,0,1,0,0,0,0,200), 'full Q';
                nstat.decoding.KF_EM.KF_EMCreateConstraints(1,0,1,1,1,0,0,0,0,200), 'isotropic Q';
                nstat.decoding.KF_EM.KF_EMCreateConstraints(1,0,1,0,0,0,0,0,0,200), 'full R';
                nstat.decoding.KF_EM.KF_EMCreateConstraints(1,0,1,0,1,1,0,0,0,200), 'isotropic R'};
            for i = 1:size(variants,1)
                rng(13);
                S = nstat.decoding.KF_EM.KF_ComputeParamStandardErrors(P.y,xK,WK,P.A,P.Q,P.C,P.R,P.alpha,P.x0,P.Px0,ES,variants{i,1});
                tc.verifyEqual(S.Q, S0.Q, 'RelTol', 1e-8, [variants{i,2} ': SE.Q']);
                tc.verifyEqual(S.R, S0.R, 'RelTol', 1e-8, [variants{i,2} ': SE.R']);
            end
        end
    end

    methods (Static, Access = private)
        function P = scalarProblem()
            rng(5); P.A = 0.9; P.Q = 0.02; P.C = 1.3; P.R = 0.05; P.alpha = 0.2;
            N = 300; P.x0 = 0; P.Px0 = 1e-6;
            x = zeros(1,N); xp = 0;
            for k = 1:N, xp = P.A*xp + sqrt(P.Q)*randn; x(k) = xp; end
            P.y = P.C*x + P.alpha + sqrt(P.R)*randn(1,N);
        end
    end
end
