classdef testPointProcessEMCorrectness < matlab.unittest.TestCase
    %TESTPOINTPROCESSEMCORRECTNESS numerical-correctness regressions for
    % nstat.decoding.PointProcessEM (fix/pp-em round 2). Each test fails on
    % the source before its fix.

    methods (TestMethodSetup)
        function isolateGlobalState(tc)
            warnState = warning;
            tc.addTeardown(@() warning(warnState));
            figVis = get(0, 'DefaultFigureVisible');
            set(0, 'DefaultFigureVisible', 'off');
            tc.addTeardown(@() set(0, 'DefaultFigureVisible', figVis));
            figsBefore = findall(0, 'Type', 'figure');
            tc.addTeardown(@() close(setdiff(findall(0, 'Type', 'figure'), figsBefore)));
        end
    end

    methods (Test)
        function testEStepSquareHistoryInvariance(tc)
            %TESTESTEPSQUAREHISTORYINVARIANCE numWindows == numCells used to
            % transpose the history slice in PP_EStep's logll. Appending an
            % all-zero history window (with a zero gamma row) is the same
            % model, but makes the history non-square; logll and the
            % smoothed states must not change.
            for ft = {'poisson', 'binomial'}
                S = testPointProcessEMCorrectness.squareHistoryProblem(ft{1});
                tc.assertEqual(size(S.HkAll,2), size(S.dN,1), 'scenario must be square (nW == C)');
                xK1 = []; WK1 = []; ll1 = []; xK2 = []; WK2 = []; ll2 = [];
                evalc(['[xK1,WK1,ll1] = nstat.decoding.PointProcessEM.PP_EStep(' ...
                    'S.A,S.Q,S.dN,S.mu,S.beta,ft{1},S.gamma,S.HkAll,S.x0,S.Px0);']);
                H2 = cat(2, S.HkAll, zeros(size(S.HkAll,1), 1, size(S.HkAll,3)));
                g2 = [S.gamma; zeros(1, size(S.gamma,2))];
                evalc(['[xK2,WK2,ll2] = nstat.decoding.PointProcessEM.PP_EStep(' ...
                    'S.A,S.Q,S.dN,S.mu,S.beta,ft{1},g2,H2,S.x0,S.Px0);']);
                tc.verifyEqual(xK1, xK2, 'AbsTol', 1e-12, [ft{1} ': x_K must be invariant']);
                tc.verifyEqual(WK1, WK2, 'AbsTol', 1e-12, [ft{1} ': W_K must be invariant']);
                tc.verifyEqual(ll1, ll2, 'RelTol', 1e-12, ...
                    [ft{1} ': logll must not depend on whether the history matrix is square']);
            end
        end
    end

    methods (Static)
        function S = squareHistoryProblem(fitType)
            % 3 cells, 3 history windows, non-symmetric gamma.
            rng(11);
            C = 3; N = 600; delta = 0.001; dx = 2;
            S.A = [0.98 0.02; -0.03 0.96]; S.Q = diag([0.02 0.015]);
            S.x0 = [0.1; -0.1]; S.Px0 = diag([0.05 0.08]);
            S.mu = log([30; 40; 25]*delta);
            S.beta = [0.8 -0.4 0.3; 0.2 0.6 -0.7];
            S.gamma = [-0.9 -0.2 -0.5; -0.4 -1.1 0.3; 0.2 -0.6 -0.8];
            wt = [0 0.002 0.005 0.010];
            x = zeros(dx, N); xp = S.x0;
            for k = 1:N, xp = S.A*xp + chol(S.Q,'lower')*randn(dx,1); x(:,k) = xp; end
            eta = S.mu + S.beta'*x;
            if strcmp(fitType, 'poisson'), p = min(exp(eta),1); else, p = exp(eta)./(1+exp(eta)); end
            S.dN = double(rand(C,N) < p);
            histObj = History(wt, 0, (N-1)*delta);
            S.HkAll = zeros(N, numel(wt)-1, C);
            for c = 1:C
                nst = nspikeTrain((find(S.dN(c,:)==1)-1)*delta);
                nst.setMinTime(0); nst.setMaxTime((N-1)*delta);
                S.HkAll(:,:,c) = histObj.computeHistory(nst).dataToMatrix;
            end
            S.wt = wt; S.delta = delta;
        end
    end
end
