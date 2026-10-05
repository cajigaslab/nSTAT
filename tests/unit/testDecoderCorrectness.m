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

        function testHybridFilterWithHistoryMatchesSingleModel(tc)
            %TESTHYBRIDFILTERWITHHISTORYMATCHESSINGLEMODEL
            % PPHybridFilterLinear could not run with windowTimes (it used an
            % undefined `delta` and the post-loop `c` / undefined gammaNew of
            % the #20 pattern). With two IDENTICAL models the hybrid
            % estimate is the single-model filter, so it must equal
            % PPDecodeFilterLinear on the same data, history windows and a
            % shared (numWindows x 1) gamma.
            rng(17); delta = 0.001; N = 600; ns = 2; C = 3;
            A = [0.98 0.02; -0.03 0.96]; Q = diag([0.01 0.02]); x0 = [0.1; -0.2]; Pi0 = 1e-3*eye(ns);
            mu = log([30; 40; 25]*delta); beta = [0.9 -0.4 0.2; 0.3 0.7 -0.5];
            wt = [0 0.002 0.005 0.010]; g = [-0.8; -0.4; -0.2];
            x = zeros(ns, N); xp = x0;
            for k = 1:N, xp = A*xp + chol(Q,'lower')*randn(ns,1); x(:,k) = xp; end
            dN = double(rand(C, N) < min(exp(mu + beta'*x), 1));
            [~, ~, xu, Wu] = nstat.decoding.PPAF.PPDecodeFilterLinear(A, Q, dN, mu, beta, ...
                'poisson', delta, g, wt, x0, Pi0);
            o = cell(1,7);
            evalc(['[o{1:7}] = nstat.decoding.PPHF.PPHybridFilterLinear({A,A},{Q,Q},' ...
                '[0.9 0.1;0.1 0.9],[0.5;0.5],dN,mu,beta,''poisson'',delta,g,wt,{x0,x0},{Pi0,Pi0});']);
            tc.verifyEqual(o{2}, xu, 'AbsTol', 1e-12, 'hybrid X must equal the single-model x_u');
            tc.verifyEqual(o{3}, Wu, 'AbsTol', 1e-12, 'hybrid W must equal the single-model W_u');
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
