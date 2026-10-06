classdef testEMMonteCarloDraws < matlab.unittest.TestCase
    %TESTEMMONTECARLODRAWS Monte Carlo state draws of the point-process EM
    % (fix/pp-em, item F9).
    %
    % Every MC draw in nstat.decoding.PointProcessEM and
    % nstat.decoding.PPLFP (both SE routines: complete-information
    % expectations, missing-information draws of x_k and x_0; both
    % NewtonRaphson M-steps) was made as
    %     [chol_m,p] = chol(W); z = normrnd(0,1,dx,M); x = m + chol_m*z.
    % chol returns the UPPER factor R (R'*R = W), so the draws had
    % covariance R*R' ~= W for any non-diagonal W. All sites now call the
    % class's mcStateDraws (x = m + R'*z). These tests check that helper
    % (the code path's own construction) and that no inline draw is left.

    properties (TestParameter)
        cls = {'PointProcessEM', 'PPLFP'};
    end

    methods (Test)
        function testDrawCovarianceMatchesW(tc, cls)
            % ~1e5 draws from a non-diagonal 3 x 3 W: sample mean and
            % covariance within 5 MC standard errors of (m, W). The legacy
            % construction (covariance R*R') is checked to be far outside
            % that tolerance, so the test can tell the two apart.
            m = [0.5; -1; 2];
            W = [1.0  0.8  0.3;
                 0.8  2.0 -0.6;
                 0.3 -0.6  1.5];
            tc.assertGreaterThan(min(eig(W)), 0);
            M = 1e5;
            rng(1);
            draw = str2func(['nstat.decoding.' cls '.mcStateDraws']);
            X = draw(m, W, M);
            tc.verifySize(X, [3 M]);
            seMean = sqrt(diag(W)/M);
            tc.verifyEqual(mean(X,2), m, 'AbsTol', 5*max(seMean));
            seCov = sqrt((diag(W)*diag(W)' + W.^2)/M);   % sd of a sample covariance entry
            S = cov(X');
            tc.verifyLessThan(max(max(abs(S - W)./seCov)), 5, ...
                sprintf('%s.mcStateDraws: sample covariance %s vs W %s', cls, mat2str(S,3), mat2str(W,3)));
            R = chol(W);
            tc.assertGreaterThan(max(max(abs(R*R' - W)./seCov)), 50, ...
                'the legacy covariance R*R'' must be distinguishable from W at this M');
        end

        function testDiagonalWDrawsUnchanged(tc, cls)
            % Same random stream as the legacy construction, and identical
            % draws when W is diagonal (R' == R), so fixtures whose state
            % covariances are diagonal do not move.
            m = [1; -2; 0.25];
            D = diag([0.5 2 0.1]);
            rng(3);
            draw = str2func(['nstat.decoding.' cls '.mcStateDraws']);
            X = draw(m, D, 500);
            rng(3);
            legacy = repmat(m,[1 500]) + chol(D)*normrnd(0,1,3,500);
            tc.verifyEqual(X, legacy);
        end

        function testNoInlineDrawsLeft(tc, cls)
            % Every draw goes through mcStateDraws: no chol_m*z construction
            % in code (comments excluded) and exactly one normrnd call (in
            % mcStateDraws).
            src = fileread(which(['nstat.decoding.' cls]));
            lines = regexp(src, '\r?\n', 'split');
            code = regexprep(lines, '%.*$', '');
            code = strjoin(code, newline);
            tc.verifyEmpty(regexp(code, 'chol_m', 'once'), ...
                sprintf('%s.m still builds a Monte Carlo draw inline with chol_m', cls));
            tc.verifyNumElements(regexp(code, 'normrnd\(', 'start'), 1, ...
                sprintf('%s.m: normrnd should appear only in mcStateDraws', cls));
        end
    end
end
