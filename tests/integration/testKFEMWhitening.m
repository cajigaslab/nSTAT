classdef testKFEMWhitening < matlab.unittest.TestCase
    %TESTKFEMWHITENING (KF track M, item C3 / G1) KF_RunEM scales the
    % state by Tq = inv(chol(Q0)) and the observation by
    % Tr = inv(chol(R0)). MATLAB's chol returns the UPPER factor R
    % (Q0 = R'*R), so Tq*Q0*Tq' = R^-1*R'*R*R^-T ~= I for a non-diagonal
    % Q0 (same for Tr/R0): the default QhatDiag=1/RhatDiag=1 M-step was
    % then applied to a scaled covariance the starting point did not
    % satisfy, so the first M-step lowered the log-likelihood and EM
    % returned the initial parameters unchanged. With the LOWER factor
    % L (Q0 = L*L'), Tq = inv(L) gives Tq*Q0*Tq' = I exactly; nothing
    % changes for a diagonal Q0/R0. This is the identical bug
    % PointProcessEM/PPLFP had (G1, tests/integration/
    % testPointProcessEMIntegration.m testNonDiagonalInitialCovarianceIsWhitened).

    methods (Test)
        function testNonDiagonalInitialCovarianceIsWhitened(tc)
            P = testKFEMWhitening.nonDiagonalProblem();
            cons = nstat.decoding.KF_EM.KF_EMCreateConstraints(1,0,1,0,1,0,0,0);
            r = cell(1,10);
            lg = evalc(['[r{1:10}] = nstat.decoding.KF_EM.KF_RunEM(P.y,P.A,P.Q0,P.C,P.R0,P.alpha,' ...
                'P.x0,P.Px0,cons);']);
            ll = testKFEMWhitening.parseLogLL(lg);
            tc.verifyGreaterThan(numel(ll), 2, 'KF_EM must run more than one M-step');
            tc.verifyGreaterThan(ll(2), ll(1), 'KF_EM: the first M-step must not lower the log-likelihood');
            tc.verifyGreaterThan(max(abs(r{5}(:) - P.C(:))), 1e-3, 'KF_EM must move Chat');
        end
    end

    methods (Static, Access = private)
        function ll = parseLogLL(logText)
            tok = regexp(logText, 'logll: (\S+)', 'tokens');
            ll = cellfun(@(t) str2double(t{1}), tok);
        end

        function P = nonDiagonalProblem()
            % dx = dy = 2, non-diagonal Q0, R0. A, Q0, C, R0 are chosen
            % well inside the stable / well-conditioned region -- the
            % Kalman smoother in this file's EM loop is fragile on more
            % aggressive problems (confirmed independently of this fix:
            % the unfixed source is equally fragile there), and this
            % file's concern is the whitening defect, not general EM
            % numerical stability.
            rng(11); N = 150;
            P.A = 0.9*eye(2); P.Q0 = [0.02 0.01; 0.01 0.03];
            x = zeros(2,N); xp = zeros(2,1);
            for k = 1:N, xp = P.A*xp + chol(P.Q0,'lower')*randn(2,1); x(:,k) = xp; end
            P.C = eye(2); P.R0 = [0.1 0.03; 0.03 0.15]; P.alpha = [0; 0];
            P.y = P.C*x + P.alpha + chol(P.R0,'lower')*randn(2,N);
            P.x0 = zeros(2,1); P.Px0 = eye(2);
        end
    end
end
