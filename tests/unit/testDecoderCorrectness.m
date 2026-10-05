classdef testDecoderCorrectness < matlab.unittest.TestCase
    %TESTDECODERCORRECTNESS invariance regressions for the point-process
    % decoders (nstat.decoding.PPAF / PPHF), fix/pp-em round 3. Each test
    % fails on the source before its fix.

    methods (TestMethodSetup)
        function isolateGlobalState(tc)
            warnState = warning;
            tc.addTeardown(@() warning(warnState));
            warning('off', 'all');
        end
    end

    methods (Test)
        function testSquareBetaDummyStateInvariance(tc)
            %TESTSQUAREBETADUMMYSTATEINVARIANCE PPDecodeFilterLinear
            % transposed a correctly oriented (ns x C) beta whenever
            % ns == C. Appending a decoupled dummy state (own A/Q entry,
            % zero beta row) is the same model for the original states
            % but makes beta non-square; their filtered x_u / W_u must
            % not change.
            P = testDecoderCorrectness.squareProblem();
            [~, ~, xu1, Wu1] = nstat.decoding.PPAF.PPDecodeFilterLinear( ...
                P.A, P.Q, P.dN, P.mu, P.beta, 'poisson', P.delta, [], [], P.x0, P.Pi0);
            A3 = blkdiag(P.A, 0.9); Q3 = blkdiag(P.Q, 0.05);
            b3 = [P.beta; zeros(1, size(P.beta,2))];
            [~, ~, xu2, Wu2] = nstat.decoding.PPAF.PPDecodeFilterLinear( ...
                A3, Q3, P.dN, P.mu, b3, 'poisson', P.delta, [], [], [P.x0; 0], blkdiag(P.Pi0, 0.1));
            tc.verifyEqual(xu2(1:2,:), xu1, 'AbsTol', 1e-10, 'x_u of the original states must be invariant');
            tc.verifyEqual(Wu2(1:2,1:2,:), Wu1, 'AbsTol', 1e-10, 'W_u of the original states must be invariant');
        end
    end

    methods (Static)
        function P = squareProblem()
            % ns == C == 2, non-symmetric beta (ns x C).
            rng(13);
            P.delta = 0.001; N = 600; ns = 2; C = 2;
            P.A = [0.98 0.02; -0.03 0.96]; P.Q = diag([0.01 0.02]);
            P.x0 = [0.1; -0.2]; P.Pi0 = 1e-3*eye(ns);
            P.mu = log([30; 40]*P.delta);
            P.beta = [0.9 -0.4; 0.3 0.7];
            x = zeros(ns, N); xp = P.x0;
            for k = 1:N, xp = P.A*xp + chol(P.Q,'lower')*randn(ns,1); x(:,k) = xp; end
            P.dN = double(rand(C, N) < min(exp(P.mu + P.beta'*x), 1));
        end
    end
end
