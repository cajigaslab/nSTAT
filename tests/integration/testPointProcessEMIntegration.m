classdef testPointProcessEMIntegration < matlab.unittest.TestCase
    %TESTPOINTPROCESSEMINTEGRATION slow end-to-end EM regression tests for
    % nstat.decoding.PointProcessEM.PP_EM and nstat.decoding.PPLFP.PPLFP_EM
    % (fix/pp-em). Moved here from tests/unit (branch-review item F6) so
    % the per-push gate `tools/run_unit_tests.sh` stays fast; they run
    % with `tools/run_unit_tests.sh --integration`, which CONTRIBUTING.md
    % requires for changes under +nstat/+decoding/. Each test runs several
    % complete EM fits:
    %   - testPPEMRunsAndConverges: all 8 fitType x MstepMethod x history
    %     combinations converge (from testPointProcessEMRuns);
    %   - testDefaultHistoryWindowsPP / PPLFP: B9 default windows
    %     0:delta:W*delta and shared-gamma expansion;
    %   - testTimeBaseEquivalencePP / PPLFP, testGLMTimeBaseEquivalencePPLFP:
    %     delta = 2 ms vs 1 ms with equivalent windows (C6, R4b, R4c).
    % Helpers live in the unit test classes testPointProcessEMRuns,
    % testPointProcessEMCorrectness and testPPLFPEMCorrectness.

    properties (TestParameter)
        fitType = {'poisson', 'binomial'};
        method = {'GLM', 'NewtonRaphson'};
        useHist = struct('noHistory', false, 'history', true);
    end

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
        function testPPEMRunsAndConverges(tc, fitType, method, useHist)
            %TESTPPEMRUNSANDCONVERGES all fitType x MstepMethod x history
            % combinations run past iteration 2, return finite real
            % parameters, increase the log-likelihood until the stopping
            % iteration, and return the best iterate.
            P = testPointProcessEMRuns.makeProblem(fitType, useHist);
            [R, emLog] = testPointProcessEMRuns.runEM(P, method, ...
                nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0));

            % Ran past iteration 2 (exercises the figure(h) path that the
            % M-step's `close all` used to break).
            nIter = numel(regexp(emLog, 'Iteration #\d+', 'match'));
            tc.verifyGreaterThanOrEqual(nIter, 2, 'PP_EM must run at least 2 EM iterations');

            % Finite, real outputs.
            outs = {R.xK, R.WK, R.A, R.Q, R.mu, R.beta, R.gamma, R.x0, R.Px0};
            names = {'xK','WK','Ahat','Qhat','muhat','betahat','gammahat','x0hat','Px0hat'};
            for i = 1:numel(outs)
                tc.verifyTrue(isreal(outs{i}) && all(isfinite(outs{i}(:))), ...
                    sprintf('%s must be finite and real', names{i}));
            end

            % Log-likelihood: increases at least once and is non-decreasing
            % up to the iteration that triggered the stop (EM stops on the
            % first decrease / non-finite value by design).
            ll = testPointProcessEMRuns.parseLogLL(emLog);
            tc.assertGreaterThanOrEqual(numel(ll), 2);
            llPre = ll(1:end-1);
            tc.verifyTrue(all(isfinite(llPre)) && all(imag(llPre)==0), ...
                'every log-likelihood before the stopping iteration must be finite and real');
            llPre = real(llPre);
            tc.verifyGreaterThan(real(ll(2)), real(ll(1)), 'EM must improve the log-likelihood');
            if numel(llPre) > 1
                tc.verifyGreaterThanOrEqual(diff(llPre), 0, ...
                    'log-likelihood must be non-decreasing before the stop');
            end
            % The returned iterate is the best one seen (the trace is
            % parsed from num2str output, ~8 significant digits).
            tc.verifyEqual(real(R.IC.llcomp), testPointProcessEMRuns.bestLL(ll), 'RelTol', 1e-7, ...
                'PP_EM must return the max-log-likelihood iterate');

            % Sane ranges.
            tc.verifyLessThan(max(abs(eig(R.A))), 1.05, 'Ahat must stay (near-)stable');
            tc.verifyGreaterThan(diag(R.Q), 0);
            tc.verifyLessThan(diag(R.Q), 1);
            tc.verifyLessThan(max(abs(R.mu - P.mu)), 1.5, 'muhat must stay near the generating baseline');
            tc.verifyLessThan(max(abs(R.beta(:))), 15, 'betahat must stay bounded');

            if strcmp(method, 'NewtonRaphson')
                % The NR M-step is a proper (Monte Carlo) EM step: it
                % recovers the generating parameters to within the noise
                % of ~35 spikes/cell.
                tc.verifyLessThan(max(abs(R.mu - P.mu)), 0.5);
                tc.verifyLessThan(max(abs(R.beta(:) - P.beta(:))), 0.8);
            end

            if useHist
                nW = numel(testPointProcessEMRuns.WindowTimes) - 1;
                tc.verifySize(R.gamma, [nW, P.C]);
                tc.verifyGreaterThan(max(abs(R.gamma(:) - testPointProcessEMRuns.Gamma0)), 0.05, ...
                    'gammahat must be genuinely estimated (moved from its initial value)');
                if strcmp(method, 'NewtonRaphson')
                    tc.verifyLessThan(mean(R.gamma(:)), 0, ...
                        'NR gammahat must recover the inhibitory (negative) history effect');
                end
            else
                tc.verifyEqual(R.gamma, 0, 'no-history fits keep gamma = 0');
            end
        end

        function testDefaultHistoryWindowsPP(tc)
            %TESTDEFAULTHISTORYWINDOWS with windowTimes = [] and a nonzero
            % gamma, PP_EM built 0:delta:(length(gamma)+1)*delta -- one
            % window too many (and length() of a W x C matrix is max(W,C))
            % -- and could not use a shared gamma column, so every
            % default-window call failed with MATLAB:innerdim. The default
            % must equal the explicit call with W = size(gamma,1) windows
            % 0:delta:W*delta and the shared column replicated per cell.
            [dN, A, Q, mu, beta, delta] = testPointProcessEMCorrectness.emProblem();
            C = size(dN,1);
            % Default (NewtonRaphson) M-step on the 1000-bin problem, where EM
            % stops after ~3 iterations (the equivalence holds per iteration).
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
            % Two cases: a scalar (one shared window; the old rule built 2 and
            % never expanded it) and a 2 x 4 matrix (W < C: length() = 4).
            % Small coefficients keep each EM run to ~3 iterations.
            cases = { -0.05,                       -0.05*ones(1,C),              0:delta:1*delta; ...
                      -0.04*[1 0.5 0.8 0.6; 0.3 0.7 0.2 0.9], ...
                      -0.04*[1 0.5 0.8 0.6; 0.3 0.7 0.2 0.9],                    0:delta:2*delta};
            for i = 1:size(cases,1)
                r1 = cell(1,7); r2 = cell(1,7);
                rng(3);
                evalc('[r1{1:7}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,Q,mu,beta,''poisson'',delta,cases{i,1},[],[],[],cons);');
                rng(3);
                evalc('[r2{1:7}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,Q,mu,beta,''poisson'',delta,cases{i,2},cases{i,3},[],[],cons);');
                tc.verifyEqual(r1, r2, sprintf('case %d: default windows must equal explicit 0:delta:W*delta', i));
            end
        end

        function testTimeBaseEquivalencePP(tc)
            %TESTTIMEBASEEQUIVALENCE PP_EM is a per-bin model: the same
            % spike matrix analysed at delta = 2 ms with history windows
            % [0 4 10 20] ms covers exactly the same bin lags as at
            % delta = 1 ms with windows [0 2 5 10] ms, so every output
            % must agree. Before the fix PP_EM built its history spike
            % trains at 1 kHz regardless of delta and the GLM M-step
            % hardcoded a 1 ms grid / sampleRate 1000.
            S = testPointProcessEMCorrectness.squareHistoryProblem('poisson');
            dN = S.dN(:, 1:300);
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0);
            g0 = -0.5*ones(3, size(dN,1));
            for m = {'GLM', 'NewtonRaphson'}
                r1 = cell(1,7); r2 = cell(1,7);
                rng(3);
                evalc(['[r1{1:7}] = nstat.decoding.PointProcessEM.PP_EM(dN,S.A,S.Q,S.mu,S.beta,' ...
                    '''poisson'',0.001,g0,[0 0.002 0.005 0.010],S.x0,S.Px0,cons,m{1});']);
                rng(3);
                evalc(['[r2{1:7}] = nstat.decoding.PointProcessEM.PP_EM(dN,S.A,S.Q,S.mu,S.beta,' ...
                    '''poisson'',0.002,g0,[0 0.004 0.010 0.020],S.x0,S.Px0,cons,m{1});']);
                names = {'xK','WK','Ahat','Qhat','muhat','betahat','gammahat'};
                for i = 1:7
                    tc.verifyEqual(r2{i}, r1{i}, 'AbsTol', 1e-9, ...
                        sprintf('%s: %s at delta=2 ms must equal the 1 ms analysis', m{1}, names{i}));
                end
            end
        end

        function testDefaultHistoryWindowsPPLFP(tc)
            %TESTDEFAULTHISTORYWINDOWS PPLFP_EM's default windowTimes rule
            % 0:delta:(length(gamma)+1)*delta had one window too many and a
            % shared gamma column was never expanded, so every
            % default-window call failed. Same equivalences as the PP_EM
            % test: W = size(gamma,1) windows, edges 0:delta:W*delta.
            % Default (NewtonRaphson) M-step on the 600-bin problem, where EM
            % stops after ~3 iterations (the equivalence holds per iteration).
            P = testPPLFPEMCorrectness.makeProblem('poisson', false, 600);
            C = P.nC; d = P.delta;
            % Two cases: a scalar (one shared window; the old rule built 2 and
            % never expanded it) and a 2 x 4 matrix (W < C: length() = 4).
            % Small coefficients keep each EM run to ~3 iterations.
            cases = { -0.05,                       -0.05*ones(1,C),              0:d:1*d; ...
                      -0.04*[1 0.5 0.8 0.6; 0.3 0.7 0.2 0.9], ...
                      -0.04*[1 0.5 0.8 0.6; 0.3 0.7 0.2 0.9],                    0:d:2*d};
            for i = 1:size(cases,1)
                r1 = cell(1,12); r2 = cell(1,12);
                rng(3);
                evalc('[r1{1:12}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,P.mu,P.beta,''poisson'',d,cases{i,1},[]);');
                rng(3);
                evalc('[r2{1:12}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,P.mu,P.beta,''poisson'',d,cases{i,2},cases{i,3});');
                tc.verifyEqual(r1, r2, sprintf('case %d: default windows must equal explicit 0:delta:W*delta', i));
            end
        end

        function testTimeBaseEquivalencePPLFP(tc)
            %TESTTIMEBASEEQUIVALENCE PPLFP_EM is a per-bin model: the same
            % data at delta = 2 ms with history windows [0 4 10 20] ms
            % cover the same bin lags as at 1 ms with [0 2 5 10] ms, so
            % every output must agree. PPLFP_EM built its history spike
            % trains at 1 kHz regardless of delta (R4b). NewtonRaphson
            % M-step (default), so PPLFP_MStep's GLM time base is not
            % involved (see testGLMTimeBaseEquivalence).
            P = testPPLFPEMCorrectness.makeProblem('poisson', true, 400);
            g0 = -0.3*ones(3, P.nC);
            r1 = cell(1,12); r2 = cell(1,12);
            rng(3);
            evalc(['[r1{1:12}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,P.mu,P.beta,' ...
                '''poisson'',0.001,g0,[0 0.002 0.005 0.010]);']);
            rng(3);
            evalc(['[r2{1:12}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,P.mu,P.beta,' ...
                '''poisson'',0.002,g0,[0 0.004 0.010 0.020]);']);
            for i = 1:12
                tc.verifyEqual(r2{i}, r1{i}, 'AbsTol', 1e-9, sprintf('output %d at delta=2 ms must equal the 1 ms analysis', i));
            end
        end

        function testGLMTimeBaseEquivalencePPLFP(tc)
            %TESTGLMTIMEBASEEQUIVALENCE the PPLFP_MStep GLM branch hardcoded
            % a 1 ms time grid / sampleRate 1000 (R4c). One GLM M-step on the
            % same E-step output at delta = 2 ms with windows [0 4 10 20] ms
            % must equal the 1 ms analysis with [0 2 5 10] ms (same bin
            % lags), and PPLFP_EM with the GLM M-step must agree likewise.
            P = testPPLFPEMCorrectness.makeProblem('poisson', true, 400);
            g0 = -0.3*ones(3, P.nC);
            wt1 = [0 0.002 0.005 0.010]; wt2 = [0 0.004 0.010 0.020];
            H1 = testPointProcessEMCorrectness.historyTensor(P.dN, wt1, 0.001);
            [xK, WK, ES] = testPPLFPEMCorrectness.eStepH(P, g0, H1);
            m1 = cell(1,10); m2 = cell(1,10);
            evalc(['[m1{1:10}] = nstat.decoding.PPLFP.PPLFP_MStep(P.dN,P.y,xK,WK,P.x0,P.Px0,ES,' ...
                '''poisson'',P.mu,P.beta,g0,wt1,H1,P.cons,''GLM'',0.001);']);
            evalc(['[m2{1:10}] = nstat.decoding.PPLFP.PPLFP_MStep(P.dN,P.y,xK,WK,P.x0,P.Px0,ES,' ...
                '''poisson'',P.mu,P.beta,g0,wt2,H1,P.cons,''GLM'',0.002);']);
            for i = 1:10
                tc.verifyEqual(m2{i}, m1{i}, 'AbsTol', 1e-9, sprintf('PPLFP_MStep output %d', i));
            end
            r1 = cell(1,12); r2 = cell(1,12);
            rng(3);
            evalc(['[r1{1:12}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,P.mu,P.beta,' ...
                '''poisson'',0.001,g0,wt1,[],[],[],''GLM'');']);
            rng(3);
            evalc(['[r2{1:12}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,P.mu,P.beta,' ...
                '''poisson'',0.002,g0,wt2,[],[],[],''GLM'');']);
            for i = 1:12
                tc.verifyEqual(r2{i}, r1{i}, 'AbsTol', 1e-9, sprintf('PPLFP_EM (GLM) output %d', i));
            end
        end
    end
end
