classdef testPPLFPEMCorrectness < matlab.unittest.TestCase
    %TESTPPLFPEMCORRECTNESS numerical-correctness regressions for
    % nstat.decoding.PPLFP (joint point-process / LFP EM), fix/pp-em
    % round 2. Each test fails on the source before its fix.
    %
    % Synthetic problem: 2-D AR(1) state, 4 cells at ~40 Hz, 2 Gaussian
    % "LFP" channels y = Cmat*x + alpha + noise, 1000 one-ms bins.

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
        function testGLMMStepUpdatesParameters(tc)
            %TESTGLMMSTEPUPDATESPARAMETERS PPLFP_MStep('GLM') wrote its fit
            % into its input variables and returned mu/beta/gamma unchanged.
            for useHist = [false true]
                P = testPPLFPEMCorrectness.makeProblem('poisson', useHist);
                [xK, WK, ES] = testPPLFPEMCorrectness.eStep(P, P.mu, P.beta, P.gamma0);
                muN = []; betaN = []; gammaN = [];
                evalc(['[~,~,~,~,~,muN,betaN,gammaN] = nstat.decoding.PPLFP.PPLFP_MStep(' ...
                    'P.dN,P.y,xK,WK,P.x0,P.Px0,ES,''poisson'',P.mu,P.beta,P.gamma0,P.wt,P.HkAll,P.cons,''GLM'');']);
                lbl = sprintf('history=%d', useHist);
                tc.verifyFalse(isequal(muN, P.mu), [lbl ': GLM M-step must update mu']);
                tc.verifyFalse(isequal(betaN, P.beta), [lbl ': GLM M-step must update beta']);
                tc.verifyTrue(all(isfinite(muN)) && all(isfinite(betaN(:))), lbl);
                if useHist
                    tc.verifyFalse(isequal(gammaN, P.gamma0), [lbl ': GLM M-step must update gamma']);
                end
            end
        end

        function testGLMMStepRestoresWarningState(tc)
            %TESTGLMMSTEPRESTORESWARNINGSTATE PPLFP_MStep's GLM branch called
            % warning('OFF') and never restored the caller's state.
            P = testPPLFPEMCorrectness.makeProblem('poisson', false);
            [xK, WK, ES] = testPPLFPEMCorrectness.eStep(P, P.mu, P.beta, 0);
            warning('on', 'all');
            warning('off', 'nstat:test:sentinelOff');
            before = warning;
            evalc(['nstat.decoding.PPLFP.PPLFP_MStep(P.dN,P.y,xK,WK,P.x0,P.Px0,ES,' ...
                '''poisson'',P.mu,P.beta,0,[],P.HkAll,P.cons,''GLM'');']);
            tc.verifyEqual(warning, before, ...
                'PPLFP_MStep(GLM) must leave the caller''s warning state unchanged');
        end

        function testSquareHistoryInvariance(tc)
            %TESTSQUAREHISTORYINVARIANCE numWindows == numCells used to
            % mis-orient the history slice in PPLFP_Decode_update (filter)
            % and PPLFP_EStep (logll). Appending an all-zero history window
            % with a zero gamma row is the same model but non-square;
            % x_K, W_K and logll must not change.
            for ft = {'poisson', 'binomial'}
                P = testPPLFPEMCorrectness.squareProblem(ft{1});
                tc.assertEqual(size(P.HkAll,2), size(P.dN,1), 'scenario must be square (nW == C)');
                [xK1, WK1, ~, ll1] = testPPLFPEMCorrectness.eStep(P, P.mu, P.beta, P.gamma0);
                P2 = P;
                P2.HkAll = cat(2, P.HkAll, zeros(size(P.HkAll,1), 1, size(P.HkAll,3)));
                g2 = [P.gamma0; zeros(1, size(P.gamma0,2))];
                [xK2, WK2, ~, ll2] = testPPLFPEMCorrectness.eStep(P2, P.mu, P.beta, g2);
                tc.verifyEqual(xK1, xK2, 'AbsTol', 1e-12, [ft{1} ': x_K must be invariant']);
                tc.verifyEqual(WK1, WK2, 'AbsTol', 1e-12, [ft{1} ': W_K must be invariant']);
                tc.verifyEqual(ll1, ll2, 'RelTol', 1e-12, [ft{1} ': logll must be invariant']);
            end
        end

        function testPoissonStandardErrorsMatchFiniteDifference(tc)
            %TESTPOISSONSTANDARDERRORSMATCHFINITEDIFFERENCE harness check of
            % checkSEAgainstFD on the poisson blocks (mu, beta, gamma), which
            % were already correct.
            testPPLFPEMCorrectness.checkSEAgainstFD(tc, 'poisson', true, {'mu','beta','gamma'});
        end

        function testBinomialMuStandardErrors(tc)
            %TESTBINOMIALMUSTANDARDERRORS the binomial mu information used
            % -3*E[p^3]; the Hessian of sum dN*log(p) - p in mu has -2*p^3.
            testPPLFPEMCorrectness.checkSEAgainstFD(tc, 'binomial', false, {'mu'});
        end

        function testBinomialHistoryStandardErrorsRun(tc)
            %TESTBINOMIALHISTORYSTANDARDERRORSRUN the binomial gamma block of
            % PPLFP_ComputeParamStandardErrors multiplied Hk(k,:)'*Hk(:,k)
            % and always errored. SE.gamma must now match the
            % finite-difference information.
            testPPLFPEMCorrectness.checkSEAgainstFD(tc, 'binomial', true, {'mu','gamma'});
        end

        function testBinomialBetaStandardErrors(tc)
            %TESTBINOMIALBETASTANDARDERRORS the binomial beta information
            % block of PPLFP_ComputeParamStandardErrors used
            % (E[p]+E[p^2]-2E[p^3])xx' (wrong sign). SE.beta must match the
            % finite-difference information.
            testPPLFPEMCorrectness.checkSEAgainstFD(tc, 'binomial', false, {'mu','beta'});
        end

        function testSharedGammaColumnReachesEveryCell(tc)
            %TESTSHAREDGAMMACOLUMNREACHESEVERYCELL PPLFP_DecodeLinear and
            % PPLFP_fixedIntervalSmoother expanded a shared (numWindows x 1)
            % gamma with the post-loop `c`, so only the last cell got it. A
            % shared column must decode exactly like the same column
            % replicated for every cell.
            P = testPPLFPEMCorrectness.makeProblem('poisson', true);
            gS = [-0.8; -0.4; -0.2]; gF = repmat(gS, 1, P.nC);
            out1 = cell(1,4); out2 = cell(1,4);
            evalc(['[out1{1:4}] = nstat.decoding.PPLFP.PPLFP_DecodeLinear(P.A,P.Q,P.Cm,P.R,P.y,P.alpha,' ...
                'P.dN,P.mu,P.beta,''poisson'',P.delta,gS,P.wt,P.x0,P.Px0,P.HkAll);']);
            evalc(['[out2{1:4}] = nstat.decoding.PPLFP.PPLFP_DecodeLinear(P.A,P.Q,P.Cm,P.R,P.y,P.alpha,' ...
                'P.dN,P.mu,P.beta,''poisson'',P.delta,gF,P.wt,P.x0,P.Px0,P.HkAll);']);
            for i = 1:4
                tc.verifyEqual(out1{i}, out2{i}, 'AbsTol', 1e-12, sprintf('PPLFP_DecodeLinear output %d', i));
            end
            evalc(['[out1{1:4}] = nstat.decoding.PPLFP.PPLFP_fixedIntervalSmoother(P.A,P.Q,P.Cm,P.R,P.y,P.alpha,' ...
                'P.dN,2,P.mu,P.beta,''poisson'',P.delta,gS,P.wt,P.x0,P.Px0);']);
            evalc(['[out2{1:4}] = nstat.decoding.PPLFP.PPLFP_fixedIntervalSmoother(P.A,P.Q,P.Cm,P.R,P.y,P.alpha,' ...
                'P.dN,2,P.mu,P.beta,''poisson'',P.delta,gF,P.wt,P.x0,P.Px0);']);
            for i = 1:4
                tc.verifyEqual(out1{i}, out2{i}, 'AbsTol', 1e-12, sprintf('PPLFP_fixedIntervalSmoother output %d', i));
            end
        end

        function testStandardErrorLayoutMultiStateMultiWindow(tc)
            %TESTSTANDARDERRORLAYOUTMULTISTATEMULTIWINDOW SE.beta / SE.gamma
            % were built with reshape(v,C,dx)' / reshape(v,C,W)' from
            % cell-ordered terms, scrambling entries for dx>1 / W>1 with
            % C>1. dx = 2, 3 windows, 2 cells: every entry must match the
            % finite-difference information in its own position.
            testPPLFPEMCorrectness.checkSEAgainstFD(tc, 'poisson', true, {'mu','beta','gamma'}, 2, 3, 2);
        end

        function testEMStopsOnNonFiniteLogLikelihood(tc)
            %TESTEMSTOPSONNONFINITELOGLIKELIHOOD with x0/Px0 estimation the
            % Px0 M-step collapses Px0hat (to ~0 or below) and the E-step
            % logll becomes +Inf / NaN / complex. PPLFP_EM used to feed that
            % into PPLFP_MStep (NewtonRaphson crashed in chol) or iterate on
            % NaN and select the +Inf iterate. It must now stop and return
            % the best finite, real iterate. (Constraints passed explicitly,
            % independent of PPLFP_EMCreateConstraints' defaults.)
            P = testPPLFPEMCorrectness.makeProblem('poisson', false, 600);
            cons = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints(1,0,1,0,1,0,1,1);
            for m = {'NewtonRaphson', 'GLM'}
                o = cell(1,13);
                rng(42);
                emLog = evalc(['[o{1:13}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,' ...
                    'P.mu,P.beta,''poisson'',P.delta,0,[],P.x0,P.Px0,cons,m{1});']);
                for i = [1 3 4 5 6 7 8 9]
                    tc.verifyTrue(isreal(o{i}) && all(isfinite(o{i}(:))), ...
                        sprintf('%s: output %d must be finite and real', m{1}, i));
                end
                tok = regexp(emLog, 'logll: (\S+)', 'tokens');
                ll = cellfun(@(t) str2double(t{1}), tok);
                ok = isfinite(ll) & imag(ll) == 0;
                % The printed logll values are those of the internally
                % scaled system (x_s = Tq*x, y_s = Tr*y); IC.llcomp is on
                % the original scale (F10): best + (K+1)*log|det Tq| +
                % K*log|det Tr|.
                Tq = eye(size(P.Q))/chol(P.Q); Tr = eye(size(P.R))/chol(P.R);
                K = size(P.dN,2);
                jac = (K+1)*log(abs(det(Tq))) + K*log(abs(det(Tr)));
                tc.verifyEqual(real(o{13}.llcomp), max(real(ll(ok))) + jac, 'RelTol', 1e-7, ...
                    sprintf('%s: must return the best finite log-likelihood iterate', m{1}));
            end
        end

        function testSingleCellHistoryStandardErrors(tc)
            %TESTSINGLECELLHISTORYSTANDARDERRORS one cell, two history
            % windows: the `size(Hk,1)==numCells` guards in
            % PPLFP_ComputeParamStandardErrors transposed the 1 x W row.
            testPPLFPEMCorrectness.checkSEAgainstFD(tc, 'poisson', true, {'mu','beta','gamma'}, 1, 2, 1);
            testPPLFPEMCorrectness.checkSEAgainstFD(tc, 'binomial', true, {'mu','beta','gamma'}, 1, 2, 1);
            % One cell AND one window (scalar nonzero gamma): the gamma
            % parameter count was left unassigned (F2).
            testPPLFPEMCorrectness.checkSEAgainstFD(tc, 'poisson', true, {'mu','beta','gamma'}, 1, 1, 1);
            testPPLFPEMCorrectness.checkSEAgainstFD(tc, 'binomial', true, {'mu','beta','gamma'}, 1, 1, 1);
        end

        function testNewDefaults(tc)
            %TESTNEWDEFAULTS PPLFP_EMCreateConstraints() no longer estimates
            % x0/Px0 (Px0 collapse); every other default unchanged. The
            % mPPCO_EMCreateConstraints forwarder returns the same struct.
            C = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints();
            tc.verifyEqual([C.EstimateA C.AhatDiag C.QhatDiag C.QhatIsotropic C.RhatDiag ...
                C.RhatIsotropic C.Estimatex0 C.EstimatePx0 C.Px0Isotropic C.mcIter C.EnableIkeda], ...
                [1 0 1 0 1 0 0 0 0 1000 0]);
            tc.verifyEqual(DecodingAlgorithms.mPPCO_EMCreateConstraints(), C);
        end

        function testMStepDefaultsApply(tc)
            %TESTMSTEPDEFAULTSAPPLY PPLFP_MStep's nargin tests were off by one
            % (constraints are input 14, MstepMethod input 15), so omitting
            % them errored. Omitted, they must default to
            % PPLFP_EMCreateConstraints() and 'NewtonRaphson'.
            P = testPPLFPEMCorrectness.makeProblem('poisson', false, 600);
            [xK, WK, ES] = testPPLFPEMCorrectness.eStep(P, P.mu, P.beta, 0);
            r1 = cell(1,10); r2 = cell(1,10);
            rng(9);
            evalc('[r1{1:10}] = nstat.decoding.PPLFP.PPLFP_MStep(P.dN,P.y,xK,WK,P.x0,P.Px0,ES,''poisson'',P.mu,P.beta,0,[],P.HkAll);');
            rng(9);
            evalc(['[r2{1:10}] = nstat.decoding.PPLFP.PPLFP_MStep(P.dN,P.y,xK,WK,P.x0,P.Px0,ES,''poisson'',P.mu,P.beta,0,[],P.HkAll,' ...
                'nstat.decoding.PPLFP.PPLFP_EMCreateConstraints(),''NewtonRaphson'');']);
            tc.verifyEqual(r1, r2, 'omitted constraints/MstepMethod must equal the explicit defaults');
        end

        function testBareDefaultCallConverges(tc)
            %TESTBAREDEFAULTCALLCONVERGES PPLFP_EM(y,dN,A,Q,C,R,alpha,mu,beta)
            % used to error (gamma read before it was defaulted); with the
            % old GLM + x0/Px0-estimating defaults the logll went to +Inf at
            % iteration 4. With the new defaults the bare call -- and the
            % DecodingAlgorithms.mPPCO_EM forwarder, identically -- must run
            % > 2 iterations with a finite, increasing logll and recover the
            % generating parameters.
            P = testPPLFPEMCorrectness.makeProblem('poisson', false, 600);
            o = cell(1,13); f = cell(1,13);
            rng(42);
            emLog = evalc('[o{1:13}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,P.mu,P.beta);');
            rng(42);
            evalc('[f{1:13}] = DecodingAlgorithms.mPPCO_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,P.mu,P.beta);');
            tc.verifyEqual(f, o, 'mPPCO_EM must forward the bare call unchanged');
            nIt = numel(regexp(emLog, 'Iteration #\d+', 'match'));
            tc.verifyGreaterThan(nIt, 2, 'bare PPLFP_EM must run more than 2 EM iterations');
            tok = regexp(emLog, 'logll: (\S+)', 'tokens');
            ll = cellfun(@(t) str2double(t{1}), tok);
            tc.verifyTrue(all(isfinite(ll)) && isreal(ll), 'every logll must be finite and real');
            tc.verifyGreaterThan(ll(2), ll(1), 'EM must improve the log-likelihood');
            tc.verifyGreaterThanOrEqual(diff(ll(1:end-1)), 0, 'logll non-decreasing before the stop');
            tc.verifyLessThan(max(abs(o{8} - P.mu)), 0.5, 'mu recovery');
            tc.verifyLessThan(max(abs(o{9}(:) - P.beta(:))), 0.8, 'beta recovery');
            tc.verifyLessThan(max(abs(o{5}(:) - P.Cm(:))), 0.1, 'C recovery');
            tc.verifyLessThan(max(abs(o{7}(:) - P.alpha(:))), 0.1, 'alpha recovery');
        end

        function testGLMHistoryUnestimableWindowKeepsPrevious(tc)
            %TESTGLMHISTORYUNESTIMABLEWINDOWKEEPSPREVIOUS see the PP_MStep
            % test of the same name: hard-refractory spiking makes the
            % (0,1] ms window unestimable for every cell; PPLFP_MStep's GLM
            % branch crashed in the reshape and must now keep that window's
            % previous gamma.
            [dN, A, Q, mu, beta] = testPointProcessEMCorrectness.refractoryProblem();
            C = size(dN,1); N = size(dN,2); delta = 0.001;
            rng(4);
            Cm = [1 0.5; -0.3 1]; R = 0.05*eye(2); alpha = [0.1; -0.1];
            y = alpha + chol(R,'lower')*randn(2, N);
            wt = [0 0.001 0.005 0.020];
            HkAll = testPointProcessEMCorrectness.historyTensor(dN, wt, delta);
            g0 = -0.3*ones(numel(wt)-1, C);
            xK = []; WK = []; ES = [];
            evalc(['[xK,WK,~,ES] = nstat.decoding.PPLFP.PPLFP_EStep(A,Q,Cm,R,y,alpha,dN,mu,beta,' ...
                '''poisson'',delta,g0,HkAll,zeros(2,1),1e-9*eye(2));']);
            gN = [];
            cons = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints();
            evalc(['[~,~,~,~,~,~,~,gN] = nstat.decoding.PPLFP.PPLFP_MStep(dN,y,xK,WK,zeros(2,1),' ...
                '1e-9*eye(2),ES,''poisson'',mu,beta,g0,wt,HkAll,cons,''GLM'');']);
            tc.verifySize(gN, size(g0));
            tc.verifyEqual(gN(1,:), g0(1,:), 'the unestimable (0,1] ms window must keep its previous gamma');
            tc.verifyTrue(all(isfinite(gN(:))));
            tc.verifyTrue(all(abs(gN(2:3,:) - g0(2:3,:)) > 1e-6, 'all'), 'the estimable windows must be updated');
        end

        function testMStepNumBinsEqualsNumCells(tc)
            %TESTMSTEPNUMBINSEQUALSNUMCELLS see the PP_MStep test of the same
            % name: PPLFP_MStep's NewtonRaphson branches re-oriented the
            % N x W history slice whenever N == numCells (R4d).
            [dN, H, mu, beta, g0, wt, A, Q] = testPointProcessEMCorrectness.squareBinsProblem();
            N = size(dN,2); rng(32);
            Cm = [1 0.5; -0.3 1]; R = 0.05*eye(2); alpha = [0.1; -0.1];
            y = alpha + chol(R,'lower')*randn(2, N);
            xK = []; WK = []; ES = [];
            evalc(['[xK,WK,~,ES] = nstat.decoding.PPLFP.PPLFP_EStep(A,Q,Cm,R,y,alpha,dN,mu,beta,' ...
                '''poisson'',0.001,g0,H,zeros(2,1),1e-3*eye(2));']);
            cons = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints();
            r1 = cell(1,10); r2 = cell(1,10);
            dN7 = [dN; double(rand(1,N) < 0.5)];
            H7 = cat(3, H, H(:,:,1)); mu7 = [mu; mu(1)]; b7 = [beta beta(:,1)]; g7 = [g0 g0(:,1)];
            rng(5);
            evalc(['[r1{1:10}] = nstat.decoding.PPLFP.PPLFP_MStep(dN,y,xK,WK,zeros(2,1),1e-3*eye(2),ES,' ...
                '''poisson'',mu,beta,g0,wt,H,cons,''NewtonRaphson'');']);
            rng(5);
            evalc(['[r2{1:10}] = nstat.decoding.PPLFP.PPLFP_MStep(dN7,y,xK,WK,zeros(2,1),1e-3*eye(2),ES,' ...
                '''poisson'',mu7,b7,g7,wt,H7,cons,''NewtonRaphson'');']);
            tc.verifyEqual(r2{6}(1:6), r1{6}, 'AbsTol', 1e-12, 'mu of cells 1..6');
            tc.verifyEqual(r2{7}(:,1:6), r1{7}, 'AbsTol', 1e-12, 'beta of cells 1..6');
            tc.verifyEqual(r2{8}(:,1:6), r1{8}, 'AbsTol', 1e-12, 'gamma of cells 1..6');
        end

        function testGLMHistoryAllWindowsUnestimable(tc)
            %TESTGLMHISTORYALLWINDOWSUNESTIMABLE see the PP_MStep test: one
            % refractory (0,1] ms window, no window estimable for any cell;
            % PPLFP_MStep's GLM branch crashed on histLabels(:,1) (F1).
            [dN, A, Q, mu, beta] = testPointProcessEMCorrectness.refractoryProblem();
            C = size(dN,1); N = size(dN,2); delta = 0.001; wt = [0 0.001];
            rng(4);
            Cm = [1 0.5; -0.3 1]; R = 0.05*eye(2); alpha = [0.1; -0.1];
            y = alpha + chol(R,'lower')*randn(2, N);
            HkAll = testPointProcessEMCorrectness.historyTensor(dN, wt, delta);
            g0 = -0.3*ones(1, C);
            xK = []; WK = []; ES = [];
            evalc(['[xK,WK,~,ES] = nstat.decoding.PPLFP.PPLFP_EStep(A,Q,Cm,R,y,alpha,dN,mu,beta,' ...
                '''poisson'',delta,g0,HkAll,zeros(2,1),1e-9*eye(2));']);
            gN = []; cons = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints();
            evalc(['[~,~,~,~,~,~,~,gN] = nstat.decoding.PPLFP.PPLFP_MStep(dN,y,xK,WK,zeros(2,1),' ...
                '1e-9*eye(2),ES,''poisson'',mu,beta,g0,wt,HkAll,cons,''GLM'');']);
            tc.verifyEqual(gN, g0, 'every unestimable window must keep its previous gamma');
        end

        function testGLMMStepMapsCoefficientsByLabel(tc)
            %TESTGLMMSTEPMAPSCOEFFICIENTSBYLABEL PPLFP_MStep's GLM branch had
            % the same positional mu/beta read as PP_MStep (F3).
            testPointProcessEMCorrectness.glmMStepMatchesGlmfit(tc, 'PPLFP', 10, 2, []);
            testPointProcessEMCorrectness.glmMStepMatchesGlmfit(tc, 'PPLFP', 2, 1, []);
            testPointProcessEMCorrectness.glmMStepMatchesGlmfit(tc, 'PPLFP', 2, 3, 2);
        end

        function testBinomialNewtonRaphsonBetaStepIsStable(tc)
            %TESTBINOMIALNEWTONRAPHSONBETASTEPISSTABLE the binomial NR beta
            % Hessian was positive definite (wrong sign), so one M-step
            % started at the generating parameters ran away. It must stay
            % near them.
            P = testPPLFPEMCorrectness.makeProblem('binomial', false);
            [xK, WK, ES] = testPPLFPEMCorrectness.eStep(P, P.mu, P.beta, 0);
            betaN = [];
            rng(1);
            evalc(['[~,~,~,~,~,~,betaN] = nstat.decoding.PPLFP.PPLFP_MStep(' ...
                'P.dN,P.y,xK,WK,P.x0,P.Px0,ES,''binomial'',P.mu,P.beta,0,[],P.HkAll,P.cons,''NewtonRaphson'');']);
            tc.verifyTrue(all(isfinite(betaN(:))));
            tc.verifyLessThan(max(abs(betaN(:) - P.beta(:))), 2.0, ...
                'binomial NR beta step must stay near the generating beta');
        end
    end

    methods (Static)
        function checkSEAgainstFD(tc, fitType, withHistory, fields, dx, nW, nC)
            % PPLFP_ComputeParamStandardErrors with vanishing missing
            % information: W_K ~ 0 (states known) and EVERY parameter at
            % its complete-data MLE given x (A, Q, C, alpha, R in closed
            % form; mu, beta, gamma by Newton), so every score is ~0. The
            % model's information is not block diagonal, but the routine
            % keeps only the mu / beta / gamma diagonal blocks (cross blocks
            % dropped), so its SEs are per-block conditional SEs: each must
            % equal sqrt(diag(inv(-H_block))) of the matching block of a
            % finite-difference Hessian of the per-cell point-process
            % log-likelihood.
            % Optional: dx (state dim, default 1), nW (history windows,
            % default 1), nC (cells, default 2). dx = nW = 1 makes the
            % check independent of the SE.beta/SE.gamma reshape.
            if nargin < 5 || isempty(dx), dx = 1; end
            if nargin < 6 || isempty(nW), nW = 1; end
            if nargin < 7 || isempty(nC), nC = 2; end
            rng(5);
            K = 3000; delta = 0.001;
            x = zeros(dx, K); xp = zeros(dx,1);
            for k = 1:K, xp = 0.99*xp + sqrt(0.02)*randn(dx,1); x(:,k) = xp; end
            CmAll = [1 0.3; -0.5 0.8]; Cm = CmAll(:, 1:dx);
            alphaT = [0.1; -0.1]; Rt = diag([0.05 0.08]);
            y = Cm*x + alphaT + chol(Rt,'lower')*randn(2, K);
            muT = log(0.05)*ones(nC,1);
            betaAll = [1 -0.8 0.6; 0.5 0.7 -0.4]; betaT = betaAll(1:dx, 1:nC);
            if withHistory
                wtAll = [0 0.004 0.012 0.025]; wt = wtAll(1:nW+1);
            else
                wt = [];
            end
            dN = zeros(nC, K);
            for k = 1:K
                eta = muT + betaT'*x(:,k);
                if withHistory
                    for w = 1:nW
                        lo = max(k - round(wt(w+1)/delta), 1); hi = min(k - round(wt(w)/delta) - 1, k-1);
                        if hi >= lo, eta = eta - 0.5*sum(dN(:,lo:hi),2); end
                    end
                end
                if strcmp(fitType,'poisson'), p = min(exp(eta),1); else, p = exp(eta)./(1+exp(eta)); end
                dN(:,k) = rand(nC,1) < p;
            end
            if withHistory
                histObj = History(wt, 0, (K-1)*delta);
                HkAll = zeros(K, nW, nC);
                for c = 1:nC
                    nst = nspikeTrain((find(dN(c,:)==1)-1)*delta);
                    nst.setMinTime(0); nst.setMaxTime((K-1)*delta);
                    HkAll(:,:,c) = histObj.computeHistory(nst).dataToMatrix;
                end
            else
                HkAll = zeros(K, 1, nC);
            end
            x0 = zeros(dx,1); Px0 = 1e-6*eye(dx);
            nG = withHistory*nW;
            np = 1 + dx + nG;
            mu = zeros(nC,1); beta = zeros(dx,nC); gamma = zeros(max(nG,1),nC); Hfull = cell(1,nC);
            for c = 1:nC
                Z = [ones(1,K); x];
                th = [muT(c); betaT(:,c)];
                if withHistory, Z = [Z; HkAll(:,:,c)']; th = [th; -0.5*ones(nW,1)]; end %#ok<AGROW>
                score = @(t) testPointProcessEMCorrectness.ppScore(t, Z, dN(c,:), fitType);
                for it = 1:100
                    [g, H] = score(th); step = H\g; th = th - step;
                    if max(abs(step)) < 1e-12, break; end
                end
                mu(c) = th(1); beta(:,c) = th(2:1+dx);
                if withHistory, gamma(:,c) = th(2+dx:end); end
                h = 1e-6; Hfd = zeros(np);
                for i = 1:np
                    e = zeros(np,1); e(i) = h;
                    Hfd(:,i) = (score(th+e) - score(th-e))/(2*h);
                end
                Hfull{c} = (Hfd+Hfd')/2;
            end
            if ~withHistory, gamma = 0; end
            Sx1 = x0*x0' + x(:,1:end-1)*x(:,1:end-1)';
            Sx10 = x(:,1)*x0' + x(:,2:end)*x(:,1:end-1)';
            A = Sx10/Sx1;
            sumX = x*x' - A*Sx10' - Sx10*A' + A*Sx1*A';
            Q = diag(diag(sumX))/K;
            Zy = [x; ones(1,K)]; CA = (y*Zy')/(Zy*Zy');
            Chat = CA(:,1:dx); alphahat = CA(:,end);
            res = y - Chat*x - alphahat;
            Rhat = diag(diag(res*res'))/K;
            ES.Sxkm1xkm1 = Sx1; ES.Sxkxk = x*x';
            WK = repmat(1e-12*eye(dx), [1 1 K]);
            cons = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints(1,0,1,0,1,0,0,0);
            cons.mcIter = 20;
            SE = [];
            evalc(['SE = nstat.decoding.PPLFP.PPLFP_ComputeParamStandardErrors(y, dN, x, WK, ' ...
                'A, Q, Chat, Rhat, alphahat, x0, Px0, ES, fitType, mu, beta, gamma, wt, HkAll, cons);']);
            for c = 1:nC
                Hc = Hfull{c};
                if any(strcmp(fields, 'mu'))
                    tc.verifyEqual(SE.mu(c), sqrt(1/(-Hc(1,1))), 'RelTol', 1e-6, ...
                        sprintf('%s cell %d: SE.mu must match the finite-difference information', fitType, c));
                end
                if any(strcmp(fields, 'beta'))
                    Hb = Hc(2:1+dx, 2:1+dx);
                    tc.verifyEqual(SE.beta(:,c), sqrt(diag(inv(-Hb))), 'RelTol', 1e-6, ...
                        sprintf('%s cell %d: SE.beta must match the finite-difference information', fitType, c));
                end
                if any(strcmp(fields, 'gamma'))
                    Hg = Hc(2+dx:end, 2+dx:end);
                    tc.verifyEqual(SE.gamma(:,c), sqrt(diag(inv(-Hg))), 'RelTol', 1e-6, ...
                        sprintf('%s cell %d: SE.gamma must match the finite-difference information', fitType, c));
                end
            end
        end

        function P = makeProblem(fitType, useHist, N)
            if nargin < 3 || isempty(N), N = 1000; end
            rng(21);
            P.nC = 4; P.delta = 0.001; dx = 2; dy = 2;
            P.A = 0.98*eye(dx); P.Q = 0.01*eye(dx);
            P.Cm = [1 0.5; -0.3 1]; P.R = 0.05*eye(dy); P.alpha = [0.1; -0.1];
            P.x0 = zeros(dx,1); P.Px0 = 1e-6*eye(dx);
            P.mu = log(40*P.delta)*ones(P.nC,1);
            P.beta = [1.0 -0.5; 0.3 0.8; -0.7 0.4; 0.6 0.6]';
            x = zeros(dx, N); xp = P.x0;
            for k = 1:N, xp = P.A*xp + chol(P.Q,'lower')*randn(dx,1); x(:,k) = xp; end
            P.y = P.Cm*x + P.alpha + chol(P.R,'lower')*randn(dy, N);
            wt = [0 0.005 0.010 0.020]; nW = numel(wt)-1;
            dN = zeros(P.nC, N);
            for k = 1:N
                eta = P.mu + P.beta'*x(:,k);
                if useHist
                    for w = 1:nW
                        lo = max(k - round(wt(w+1)/P.delta), 1); hi = min(k - round(wt(w)/P.delta) - 1, k-1);
                        if hi >= lo, eta = eta - 0.5*sum(dN(:,lo:hi),2); end
                    end
                end
                if strcmp(fitType,'poisson'), p = min(exp(eta),1); else, p = exp(eta)./(1+exp(eta)); end
                dN(:,k) = rand(P.nC,1) < p;
            end
            P.dN = dN; P.x = x; P.fitType = fitType;
            if useHist
                P.wt = wt;
                histObj = History(wt, 0, (N-1)*P.delta);
                P.HkAll = zeros(N, nW, P.nC);
                for c = 1:P.nC
                    nst = nspikeTrain((find(dN(c,:)==1)-1)*P.delta);
                    nst.setMinTime(0); nst.setMaxTime((N-1)*P.delta);
                    P.HkAll(:,:,c) = histObj.computeHistory(nst).dataToMatrix;
                end
                P.gamma0 = -0.5*ones(nW, P.nC);
            else
                P.wt = []; P.HkAll = zeros(N, 1, P.nC); P.gamma0 = 0;
            end
            P.cons = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints(1,0,1,0,1,0,0,0);
            P.cons.mcIter = 50;
        end

        function P = squareProblem(fitType)
            % 3 cells, 3 history windows, non-symmetric gamma.
            P = testPPLFPEMCorrectness.makeProblem(fitType, false);
            keep = 1:3;
            P.nC = 3; P.dN = P.dN(keep,:); P.mu = P.mu(keep); P.beta = P.beta(:,keep);
            wt = [0 0.002 0.005 0.010]; N = size(P.dN,2);
            histObj = History(wt, 0, (N-1)*P.delta);
            P.HkAll = zeros(N, numel(wt)-1, P.nC);
            for c = 1:P.nC
                nst = nspikeTrain((find(P.dN(c,:)==1)-1)*P.delta);
                nst.setMinTime(0); nst.setMaxTime((N-1)*P.delta);
                P.HkAll(:,:,c) = histObj.computeHistory(nst).dataToMatrix;
            end
            P.wt = wt;
            P.gamma0 = [-0.9 -0.2 -0.5; -0.4 -1.1 0.3; 0.2 -0.6 -0.8];
        end

        function [xK, WK, ES, ll] = eStepH(P, gamma, HkAll)
            xK = []; WK = []; ll = []; ES = [];
            evalc(['[xK,WK,ll,ES] = nstat.decoding.PPLFP.PPLFP_EStep(P.A,P.Q,P.Cm,P.R,P.y,P.alpha,' ...
                'P.dN,P.mu,P.beta,P.fitType,P.delta,gamma,HkAll,P.x0,P.Px0);']);
        end

        function [xK, WK, ES, ll] = eStep(P, mu, beta, gamma)
            xK = []; WK = []; ll = []; ES = [];
            evalc(['[xK,WK,ll,ES] = nstat.decoding.PPLFP.PPLFP_EStep(P.A,P.Q,P.Cm,P.R,P.y,P.alpha,' ...
                'P.dN,mu,beta,P.fitType,P.delta,gamma,P.HkAll,P.x0,P.Px0);']);
        end
    end
end
