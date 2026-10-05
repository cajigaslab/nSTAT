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
    %     delta = 2 ms vs 1 ms with equivalent windows (C6, R4b, R4c);
    %   - testStandardErrorsInvariantToStateScaling / ObservationScaling:
    %     the EM drivers' SEs are on the scale of the returned estimates (F8).
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
        function testStandardErrorsInvariantToStateScaling(tc)
            %TESTSTANDARDERRORSINVARIANTTOSTATESCALING PP_EM and PPLFP_EM run
            % EM on an internally scaled system (x_s = Tq*x, y_s = Tr*y,
            % Tq = inv(chol(Q0)), Tr = inv(chol(R0))) and return estimates on
            % the original scale, but passed the SCALED expectation sums
            % (and, in PPLFP_EM, the scaled y) to the SE routine with the
            % unscaled estimates (F8). Rescaling the latent state by t
            % (Q0 -> t^2 Q0, C -> C/t, beta -> beta/t, x0 -> t x0,
            % Px0 -> t^2 Px0) leaves the internal scaled problem, the EM path
            % and the MC draws identical, so consistent SEs must satisfy
            % SE(A) = SE(A), SE(Q) = t^2 SE(Q), SE(C) = SE(C)/t,
            % SE(beta) = SE(beta)/t, SE(mu) = SE(mu). Before the fix SE.A
            % scaled by t. PPLFP's C / Q blocks are checked loosely: its
            % nearestSPD() projection of an indefinite inverse information
            % is not scale-equivariant (a property of the SE routine, not of
            % the EM call site). RelTol 1e-3 for the exact relations: the
            % two scaled problems agree only to rounding, which the EM
            % iterations and that projection carry to ~1e-6..2e-5; the
            % defect was a factor t (= 3) in SE.A.
            t = 3;
            rng(21); delta = 0.001; N = 400; C = 3;
            A = 0.98; Q = 0.01; Cm = [1; -0.5]; R = diag([0.05 0.08]); alpha = [0.1; -0.1];
            x = zeros(1,N); xp = 0;
            for k = 1:N, xp = A*xp + sqrt(Q)*randn; x(k) = xp; end
            y = Cm*x + alpha + chol(R,'lower')*randn(2,N);
            mu = log(40*delta)*ones(C,1); beta = [1.0 -0.6 0.8];
            dN = double(rand(C,N) < min(exp(mu + beta'*x),1));
            consP = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(); consP.mcIter = 50;
            consL = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints(); consL.mcIter = 50;
            p = cell(2,13); l = cell(2,15); ts = [1 t];
            for i = 1:2
                s = ts(i);
                rng(42);
                evalc(['[p{i,1:13}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,s^2*Q,mu,beta/s,' ...
                    '''poisson'',delta,[],[],0,s^2*1e-6,consP);']);
                rng(42);
                evalc(['[l{i,1:15}] = nstat.decoding.PPLFP.PPLFP_EM(y,dN,A,s^2*Q,Cm/s,R,alpha,mu,beta/s,' ...
                    '''poisson'',delta,[],[],0,s^2*1e-6,consL);']);
            end
            SP1 = p{1,11}; SP3 = p{2,11}; SL1 = l{1,14}; SL3 = l{2,14};
            tc.verifyEqual(SP3.A, SP1.A, 'RelTol', 1e-3, 'PP_EM SE.A must not depend on the state scale');
            tc.verifyEqual(SP3.Q, t^2*SP1.Q, 'RelTol', 1e-3, 'PP_EM SE.Q');
            tc.verifyEqual(SP3.beta, SP1.beta/t, 'RelTol', 1e-3, 'PP_EM SE.beta');
            tc.verifyEqual(SP3.mu, SP1.mu, 'RelTol', 1e-3, 'PP_EM SE.mu');
            tc.verifyEqual(SL3.A, SL1.A, 'RelTol', 1e-3, 'PPLFP_EM SE.A must not depend on the state scale');
            tc.verifyEqual(SL3.beta, SL1.beta/t, 'RelTol', 1e-3, 'PPLFP_EM SE.beta');
            tc.verifyEqual(SL3.mu, SL1.mu, 'RelTol', 1e-3, 'PPLFP_EM SE.mu');
            tc.verifyEqual(SL3.C, SL1.C/t, 'RelTol', 2e-2, 'PPLFP_EM SE.C (nearestSPD tolerance)');
            tc.verifyEqual(SL3.Q, t^2*SL1.Q, 'RelTol', 1e-1, 'PPLFP_EM SE.Q (nearestSPD tolerance)');
        end

        function testStandardErrorsInvariantToObservationScaling(tc)
            %TESTSTANDARDERRORSINVARIANTTOOBSERVATIONSCALING the y half of F8:
            % PPLFP_EM passed the SCALED y (Tr*y) to the SE routine with the
            % unscaled C / R / alpha. Rescaling the continuous observations
            % by s (y -> s y, C -> s C, R -> s^2 R, alpha -> s alpha, so
            % R0 -> s^2 R0 and Tr*y is unchanged) leaves the internal scaled
            % problem, the EM path and the MC draws identical; consistent
            % SEs satisfy SE(C), SE(alpha) x s, SE(R) x s^2, the rest
            % unchanged. s = 2 keeps the rescaling exact in floating point:
            % with nearestSPD() disabled the post-fix ratios are exactly 1,
            % so the tolerances below only absorb that projection (largest
            % post-fix deviation: SE.R 14%, SE.Q 0.6%, SE.alpha 0.1%). Before
            % the fix SE.R was off by 2.86, SE.Q by 0.89, SE.alpha by 1.01.
            s = 2;
            rng(21); delta = 0.001; N = 400; C = 3;
            A = 0.98; Q = 0.01; Cm = [1; -0.5]; R = diag([0.05 0.08]); alpha = [0.1; -0.1];
            x = zeros(1,N); xp = 0;
            for k = 1:N, xp = A*xp + sqrt(Q)*randn; x(k) = xp; end
            y = Cm*x + alpha + chol(R,'lower')*randn(2,N);
            mu = log(40*delta)*ones(C,1); beta = [1.0 -0.6 0.8];
            dN = double(rand(C,N) < min(exp(mu + beta'*x),1));
            cons = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints(); cons.mcIter = 50;
            l = cell(2,15); ss = [1 s];
            for i = 1:2
                si = ss(i);
                rng(42);
                evalc(['[l{i,1:15}] = nstat.decoding.PPLFP.PPLFP_EM(si*y,dN,A,Q,si*Cm,si^2*R,si*alpha,' ...
                    'mu,beta,''poisson'',delta,[],[],0,1e-6,cons);']);
            end
            S1 = l{1,14}; S2 = l{2,14};
            tc.verifyEqual(S2.A, S1.A, 'RelTol', 1e-3, 'PPLFP_EM SE.A must not depend on the observation scale');
            tc.verifyEqual(S2.mu, S1.mu, 'RelTol', 1e-3, 'PPLFP_EM SE.mu');
            tc.verifyEqual(S2.beta, S1.beta, 'RelTol', 1e-3, 'PPLFP_EM SE.beta');
            tc.verifyEqual(S2.alpha, s*S1.alpha, 'RelTol', 5e-3, 'PPLFP_EM SE.alpha');
            tc.verifyEqual(S2.C, s*S1.C, 'RelTol', 2e-2, 'PPLFP_EM SE.C (nearestSPD tolerance)');
            tc.verifyEqual(S2.Q, S1.Q, 'RelTol', 5e-2, 'PPLFP_EM SE.Q (nearestSPD tolerance)');
            tc.verifyEqual(S2.R, s^2*S1.R, 'RelTol', 0.25, 'PPLFP_EM SE.R (nearestSPD tolerance)');
        end

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
            % parsed from num2str output, ~8 significant digits). The
            % printed logll values are those of PP_EM's internally scaled
            % system (x_s = Tq*x, Tq = inv(chol(Q0))); IC.llcomp is on the
            % original scale (F10): the best one plus (K+1)*log|det Tq|.
            Tq = eye(size(P.Q))/chol(P.Q);
            jac = (size(P.dN,2)+1)*log(abs(det(Tq)));
            tc.verifyEqual(real(R.IC.llcomp), testPointProcessEMRuns.bestLL(ll) + jac, 'RelTol', 1e-7, ...
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

        function testInformationCriteriaInvariantToStateScaling(tc)
            %TESTINFORMATIONCRITERIAINVARIANTTOSTATESCALING (F10) IC.llobs
            % mixed the scaled-system ll / sumXkTerms with the original-scale
            % Qhat / Px0hat. Rescaling the latent state by t (as in the F8
            % test) leaves the internal scaled problem identical, so llobs
            % = E[log p(obs | x)] and AIC / AICc / BIC must not change, and
            % the expected complete-data log-likelihood on the original
            % scale must shift by the Jacobian, llcomp -> llcomp -
            % (K+1)*dx*log(t) (x_0 .. x_K). For PPLFP, rescaling the
            % continuous observations by s (y -> s y, C -> s C,
            % R -> s^2 R, alpha -> s alpha) must shift llobs and llcomp by
            % -K*dy*log(s), the Jacobian of the y density. Before the fix
            % PP llobs went 18680 -> 1342 under t = 3.
            t = 3; s2 = 2;
            P = testPointProcessEMIntegration.scalingProblem();
            K = size(P.dN, 2); dx = 1; dy = size(P.y, 1);
            p = cell(2,10); l = cell(3,13); ts = [1 t];
            for i = 1:2
                s = ts(i);
                rng(42);
                evalc(['[p{i,1:10}] = nstat.decoding.PointProcessEM.PP_EM(P.dN,P.A,s^2*P.Q,P.mu,P.beta/s,' ...
                    '''poisson'',P.delta,[],[],0,s^2*1e-6,P.consP);']);
                rng(42);
                evalc(['[l{i,1:13}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,s^2*P.Q,P.Cm/s,P.R,P.alpha,' ...
                    'P.mu,P.beta/s,''poisson'',P.delta,[],[],0,s^2*1e-6,P.consL);']);
            end
            rng(42);
            evalc(['[l{3,1:13}] = nstat.decoding.PPLFP.PPLFP_EM(s2*P.y,P.dN,P.A,P.Q,s2*P.Cm,s2^2*P.R,' ...
                's2*P.alpha,P.mu,P.beta,''poisson'',P.delta,[],[],0,1e-6,P.consL);']);
            ICp = [p{1,10}, p{2,10}]; ICl = [l{1,13}, l{2,13}, l{3,13}];
            for f = {'llobs', 'AIC', 'AICc', 'BIC'}
                tc.verifyEqual(ICp(2).(f{1}), ICp(1).(f{1}), 'RelTol', 1e-8, ...
                    ['PP_EM IC.' f{1} ' must not depend on the units of x']);
                tc.verifyEqual(ICl(2).(f{1}), ICl(1).(f{1}), 'RelTol', 1e-8, ...
                    ['PPLFP_EM IC.' f{1} ' must not depend on the units of x']);
            end
            tc.verifyEqual(ICp(2).llcomp, ICp(1).llcomp - (K+1)*dx*log(t), 'RelTol', 1e-8, 'PP_EM IC.llcomp Jacobian');
            tc.verifyEqual(ICl(2).llcomp, ICl(1).llcomp - (K+1)*dx*log(t), 'RelTol', 1e-8, 'PPLFP_EM IC.llcomp Jacobian');
            tc.verifyEqual(ICl(3).llobs, ICl(1).llobs - K*dy*log(s2), 'RelTol', 1e-8, 'PPLFP_EM IC.llobs, y rescaled');
            tc.verifyEqual(ICl(3).llcomp, ICl(1).llcomp - K*dy*log(s2), 'RelTol', 1e-8, 'PPLFP_EM IC.llcomp, y rescaled');
        end

        function testInformationCriteriaMatchEStepAtEstimates(tc)
            %TESTINFORMATIONCRITERIAMATCHESTEPATESTIMATES (F10) the returned
            % estimates are the parameters of the best E-step, so running
            % the E-step in the ORIGINAL coordinates at those estimates must
            % reproduce IC.llcomp (its log-likelihood) and IC.llobs (its
            % observation part: sumPPll for PP; sumPPll + E[log p(y | x)]
            % for PPLFP). Q0 = 0.01 makes the internal scaling non-trivial
            % (Tq = 10).
            P = testPointProcessEMIntegration.scalingProblem();
            K = size(P.dN, 2); C = size(P.dN, 1); dy = size(P.y, 1);
            H0 = zeros(K, 1, C);
            p = cell(1,10); l = cell(1,13);
            rng(42);
            evalc(['[p{1:10}] = nstat.decoding.PointProcessEM.PP_EM(P.dN,P.A,P.Q,P.mu,P.beta,' ...
                '''poisson'',P.delta,[],[],0,1e-6,P.consP);']);
            rng(42);
            evalc(['[l{1:13}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,' ...
                'P.mu,P.beta,''poisson'',P.delta,[],[],0,1e-6,P.consL);']);
            llE = []; ESE = [];
            evalc(['[~,~,llE,ESE] = nstat.decoding.PointProcessEM.PP_EStep(p{3},p{4},P.dN,p{5},p{6},' ...
                '''poisson'',p{7},H0,p{8},p{9});']);
            tc.verifyEqual(p{10}.llcomp, llE, 'RelTol', 1e-9, 'PP_EM IC.llcomp vs PP_EStep at the estimates');
            tc.verifyEqual(p{10}.llobs, ESE.sumPPll, 'RelTol', 1e-9, 'PP_EM IC.llobs vs sumPPll');
            evalc(['[~,~,llE,ESE] = nstat.decoding.PPLFP.PPLFP_EStep(l{3},l{4},l{5},l{6},P.y,l{7},P.dN,' ...
                'l{8},l{9},''poisson'',P.delta,l{10},H0,l{11},l{12});']);
            Rh = l{6};
            llyE = -dy*K/2*log(2*pi) - K/2*log(det(Rh)) - 1/2*trace(Rh\ESE.sumYkTerms);
            tc.verifyEqual(l{13}.llcomp, llE, 'RelTol', 1e-9, 'PPLFP_EM IC.llcomp vs PPLFP_EStep at the estimates');
            tc.verifyEqual(l{13}.llobs, ESE.sumPPll + llyE, 'RelTol', 1e-9, 'PPLFP_EM IC.llobs vs sumPPll + E[log p(y|x)]');
        end
    end

    methods (Static, Access = private)
        function P = scalingProblem()
            % The F8 / F10 problem: dx = 1, Q = 0.01, 3 poisson cells, dy = 2.
            rng(21); P.delta = 0.001; N = 400; C = 3;
            P.A = 0.98; P.Q = 0.01; P.Cm = [1; -0.5]; P.R = diag([0.05 0.08]); P.alpha = [0.1; -0.1];
            x = zeros(1,N); xp = 0;
            for k = 1:N, xp = P.A*xp + sqrt(P.Q)*randn; x(k) = xp; end
            P.y = P.Cm*x + P.alpha + chol(P.R,'lower')*randn(2,N);
            P.mu = log(40*P.delta)*ones(C,1); P.beta = [1.0 -0.6 0.8];
            P.dN = double(rand(C,N) < min(exp(P.mu + P.beta'*x),1));
            P.consP = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(); P.consP.mcIter = 50;
            P.consL = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints(); P.consL.mcIter = 50;
        end
    end
end
