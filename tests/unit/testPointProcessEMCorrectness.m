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

        function testPoissonStandardErrorsMatchFiniteDifference(tc)
            %TESTPOISSONSTANDARDERRORSMATCHFINITEDIFFERENCE SE.beta / SE.gamma
            % were built with reshape(v,C,dx)' from cell-ordered terms,
            % scrambling the entries whenever dx>1 and C>1. See
            % checkStandardErrorsAgainstFD.
            testPointProcessEMCorrectness.checkStandardErrorsAgainstFD(tc, 'poisson');
        end

        function testBinomialStandardErrorsMatchFiniteDifference(tc)
            %TESTBINOMIALSTANDARDERRORSMATCHFINITEDIFFERENCE the binomial
            % beta information block used (E[p]+E[p^2]-2E[p^3])xx', which
            % is negative definite (wrong sign), so SE.beta was
            % meaningless. Same FD construction as the poisson test.
            testPointProcessEMCorrectness.checkStandardErrorsAgainstFD(tc, 'binomial');
        end

        function testSingleCellHistoryStandardErrors(tc)
            %TESTSINGLECELLHISTORYSTANDARDERRORS with one cell and several
            % history windows the SE code's `size(Hk,1)==numCells` guard
            % transposed the 1 x W history row and the information blocks
            % failed. SEs must match the finite-difference information.
            testPointProcessEMCorrectness.checkStandardErrorsAgainstFD(tc, 'poisson', 1);
            testPointProcessEMCorrectness.checkStandardErrorsAgainstFD(tc, 'binomial', 1);
            % One cell AND one window: gamma is a nonzero scalar and the SE
            % routine left its gamma parameter count unassigned (F2).
            testPointProcessEMCorrectness.checkStandardErrorsAgainstFD(tc, 'poisson', 1, 1);
            testPointProcessEMCorrectness.checkStandardErrorsAgainstFD(tc, 'binomial', 1, 1);
        end

        function testStandardErrorsHonourConstraints(tc)
            %TESTSTANDARDERRORSHONOURCONSTRAINTS (G2) the arity check
            % nargin<19 in a 15-input function replaced the caller's
            % constraints with the defaults on every call (nTerms was 18
            % here for every constraint set). With them honoured the
            % parameter count, the SE fields and the Monte Carlo size follow
            % the constraints; EstimateA=0, QhatIsotropic=1 and
            % Px0Isotropic=1 also run (they used undefined N / dx).
            % nTerms = A + Q + Px0 + x0 + mu (C) + beta (dx*C).
            [dN, A, Q, mu, beta] = testPointProcessEMCorrectness.emProblem();
            dN = dN(:, 1:300); C = size(dN, 1); dx = size(A, 1); H = zeros(300, 1, C);
            xK = []; WK = []; ES = [];
            evalc(['[xK,WK,~,ES] = nstat.decoding.PointProcessEM.PP_EStep(A,Q,dN,mu,beta,' ...
                '''poisson'',0,H,zeros(dx,1),1e-6*eye(dx));']);
            base = C + dx*C;
            % EstimateA AhatDiag QhatDiag QhatIso Estx0 EstPx0 Px0Iso | expected nTerms, SE fields
            cases = {[1 0 1 0 0 0 0], dx^2 + dx + base,     {'A','Q','mu','beta'};
                     [0 0 1 0 0 0 0], dx + base,            {'Q','mu','beta'};
                     [1 1 1 0 0 0 0], dx + dx + base,       {'A','Q','mu','beta'};
                     [1 0 0 0 0 0 0], dx^2 + dx^2 + base,   {'A','Q','mu','beta'};
                     [1 0 1 1 0 0 0], dx^2 + 1 + base,      {'A','Q','mu','beta'};
                     [1 0 1 0 1 0 0], dx^2 + dx + dx + base, {'A','Q','x0','mu','beta'};
                     [1 0 1 0 0 1 0], dx^2 + dx + dx + base, {'A','Q','Px0','mu','beta'};
                     [1 0 1 0 0 1 1], dx^2 + dx + 1 + base,  {'A','Q','Px0','mu','beta'}};
            for i = 1:size(cases, 1)
                v = cases{i,1};
                cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(v(1),v(2),v(3),v(4),v(5),v(6),v(7));
                cons.mcIter = 20;
                [S, n] = testPointProcessEMCorrectness.ppSE(dN, xK, WK, A, Q, ES, mu, beta, H, cons);
                label = sprintf('constraints %s', mat2str(v));
                tc.verifyEqual(n, cases{i,2}, [label ': nTerms']);
                tc.verifyEqual(sort(fieldnames(S)), sort(cases{i,3}(:)), [label ': SE fields']);
                if v(1) == 1 && v(2) == 1
                    tc.verifyTrue(isdiag(S.A), [label ': SE.A must be diagonal']);
                end
            end
            cons5 = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0); cons5.mcIter = 5;
            cons7 = cons5; cons7.mcIter = 7;
            S5 = testPointProcessEMCorrectness.ppSE(dN, xK, WK, A, Q, ES, mu, beta, H, cons5);
            S7 = testPointProcessEMCorrectness.ppSE(dN, xK, WK, A, Q, ES, mu, beta, H, cons7);
            tc.verifyNotEqual(S5.mu, S7.mu, 'mcIter must set the Monte Carlo sample size');
        end

        function testSharedGammaColumnStandardErrors(tc)
            %TESTSHAREDGAMMACOLUMNSTANDARDERRORS (F12) a direct SE call with
            % a shared history column (a nonzero scalar for one window, or a
            % numWindows x 1 column) and several cells failed: one gamma
            % parameter was counted against per-cell information blocks /
            % scores, and gammahat(:,c) was indexed for c > 1. It is now
            % expanded per cell as PP_EM does (B9), so the call must equal
            % the call with the expanded gamma, entry for entry.
            [dN, A, Q, mu, beta] = testPointProcessEMCorrectness.refractoryProblem();
            dN = dN(:, 1:600); C = size(dN, 1); dx = size(A, 1);
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
            cases = {[0 0.002], -0.3; [0 0.002 0.005], [-0.3; -0.1]};
            for i = 1:size(cases, 1)
                wt = cases{i,1}; g = cases{i,2}; gC = repmat(g, 1, C);
                H = testPointProcessEMCorrectness.historyTensor(dN, wt, 0.001);
                xK = []; WK = []; ES = [];
                evalc(['[xK,WK,~,ES] = nstat.decoding.PointProcessEM.PP_EStep(A,Q,dN,mu,beta,' ...
                    '''poisson'',gC,H,zeros(dx,1),1e-6*eye(dx));']);
                out1 = cell(1,3); out2 = cell(1,3);
                rng(7);
                evalc(['[out1{1:3}] = nstat.decoding.PointProcessEM.PP_ComputeParamStandardErrors(dN,xK,WK,' ...
                    'A,Q,zeros(dx,1),1e-6*eye(dx),ES,''poisson'',mu,beta,g,wt,H,cons);']);
                rng(7);
                evalc(['[out2{1:3}] = nstat.decoding.PointProcessEM.PP_ComputeParamStandardErrors(dN,xK,WK,' ...
                    'A,Q,zeros(dx,1),1e-6*eye(dx),ES,''poisson'',mu,beta,gC,wt,H,cons);']);
                label = sprintf('shared gamma %s', mat2str(g));
                tc.verifySize(out1{1}.gamma, [numel(wt)-1, C], label);
                tc.verifyEqual(out1{1}, out2{1}, [label ': SE']);
                tc.verifyEqual(out1{2}, out2{2}, [label ': Pvals']);
                tc.verifyEqual(out1{3}, out2{3}, [label ': nTerms']);
            end
        end

        function testGLMMStepRestoresWarningState(tc)
            %TESTGLMMSTEPRESTORESWARNINGSTATE PP_MStep's GLM branch called
            % warning('OFF') and never restored the caller's state.
            S = testPointProcessEMCorrectness.squareHistoryProblem('poisson');
            H0 = zeros(size(S.dN,2), 1, size(S.dN,1));
            xK = []; WK = []; ES = [];
            evalc(['[xK,WK,~,ES] = nstat.decoding.PointProcessEM.PP_EStep(' ...
                'S.A,S.Q,S.dN,S.mu,S.beta,''poisson'',0,H0,S.x0,S.Px0);']);
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0);
            warning('on', 'all');
            warning('off', 'nstat:test:sentinelOff');
            before = warning;
            evalc(['nstat.decoding.PointProcessEM.PP_MStep(S.dN,xK,WK,S.x0,S.Px0,ES,' ...
                '''poisson'',S.mu,S.beta,0,[],H0,cons,''GLM'');']);
            tc.verifyEqual(warning, before, ...
                'PP_MStep(GLM) must leave the caller''s warning state unchanged');
        end

        function testNewDefaults(tc)
            %TESTNEWDEFAULTS PP_EMCreateConstraints() no longer estimates
            % x0/Px0 (Px0 collapse); everything else unchanged.
            C = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
            tc.verifyEqual([C.EstimateA C.AhatDiag C.QhatDiag C.QhatIsotropic ...
                C.Estimatex0 C.EstimatePx0 C.Px0Isotropic C.mcIter C.EnableIkeda], ...
                [1 0 1 0 0 0 0 1000 0]);
        end

        function testBareDefaultCallConverges(tc)
            %TESTBAREDEFAULTCALLCONVERGES PP_EM(dN,A,Q,mu,beta,'poisson',delta)
            % with every other argument defaulted used to run the GLM
            % M-step with x0/Px0 estimation: Px0 collapsed, logll -> +Inf
            % after 2 iterations, and beta came back inflated. With the
            % new defaults (NewtonRaphson, x0/Px0 fixed) it must run > 2
            % iterations, increase the log-likelihood, and recover beta.
            [dN, A, Q, mu, beta, delta] = testPointProcessEMCorrectness.emProblem();
            % 10 outputs (no SE): with every logll finite (asserted below)
            % no non-finite stop can occur, so the number of 'Iteration #'
            % lines equals the nIter output.
            r = cell(1,10);
            rng(42);
            emLog = evalc('[r{1:10}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,Q,mu,beta,''poisson'',delta);');
            tok = regexp(emLog, 'logll: (\S+)', 'tokens');
            ll = cellfun(@(t) str2double(t{1}), tok);
            tc.verifyTrue(all(isfinite(ll)) && isreal(ll), 'every logll must be finite and real');
            nIter = numel(regexp(emLog, 'Iteration #\d+', 'match'));
            tc.verifyGreaterThan(nIter, 2, 'default PP_EM must complete more than 2 EM iterations');
            tc.verifyGreaterThan(ll(2), ll(1), 'EM must improve the log-likelihood');
            tc.verifyGreaterThanOrEqual(diff(ll(1:end-1)), 0, 'logll non-decreasing before the stop');
            tc.verifyLessThan(max(abs(r{6}(:) - beta(:))), 0.8, 'default PP_EM must recover beta');
            tc.verifyLessThan(max(abs(r{5} - mu)), 0.5, 'default PP_EM must recover mu');
        end

        function testZeroGammaWithExplicitWindowsUnchanged(tc)
            %TESTZEROGAMMAWITHEXPLICITWINDOWSUNCHANGED gamma = 0 means "no
            % history coefficients" (M-step gammahat==0, IC parameter count,
            % SE gamma block); the B9 shared-gamma expansion must not turn
            % it into zeros(1,numCells). This is the pplfp_EM gold recipe's
            % configuration (gamma = 0, one explicit window).
            [dN, A, Q, mu, beta, delta] = testPointProcessEMCorrectness.emProblem();
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
            r = cell(1,10);
            rng(3);
            evalc('[r{1:10}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,Q,mu,beta,''poisson'',delta,0,[0 0.005],[],[],cons);');
            tc.verifyEqual(r{7}, 0, 'gammahat must stay the scalar 0');
            P = testPPLFPEMCorrectness.makeProblem('poisson', false, 600);
            o = cell(1,13);
            rng(3);
            evalc('[o{1:13}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,P.mu,P.beta,''poisson'',P.delta,0,[0 0.599]);');
            tc.verifyEqual(o{10}, 0, 'PPLFP gammahat must stay the scalar 0');
        end

        function testGLMHistoryUnestimableWindowKeepsPrevious(tc)
            %TESTGLMHISTORYUNESTIMABLEWINDOWKEEPSPREVIOUS hard refractory
            % spiking (never two spikes in consecutive bins, for any cell)
            % makes the (0,1] ms history window unestimable for every cell
            % (complete separation -> se>=100 -> NaN -> label dropped by
            % FitResSummary). The GLM M-step used to crash in
            % reshape(getHistCoeffs,[nWindows numCells]); it must keep that
            % window's previous gamma and estimate the other windows.
            [dN, A, Q, mu, beta] = testPointProcessEMCorrectness.refractoryProblem();
            C = size(dN,1); N = size(dN,2); delta = 0.001;
            wt = [0 0.001 0.005 0.020];
            HkAll = testPointProcessEMCorrectness.historyTensor(dN, wt, delta);
            g0 = -0.3*ones(numel(wt)-1, C);
            xK = []; WK = []; ES = [];
            evalc(['[xK,WK,~,ES] = nstat.decoding.PointProcessEM.PP_EStep(A,Q,dN,mu,beta,' ...
                '''poisson'',g0,HkAll,zeros(2,1),1e-9*eye(2));']);
            gN = [];
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
            evalc(['[~,~,~,~,gN] = nstat.decoding.PointProcessEM.PP_MStep(dN,xK,WK,zeros(2,1),' ...
                '1e-9*eye(2),ES,''poisson'',mu,beta,g0,wt,HkAll,cons,''GLM'');']);
            tc.verifySize(gN, size(g0));
            tc.verifyEqual(gN(1,:), g0(1,:), 'the unestimable (0,1] ms window must keep its previous gamma');
            tc.verifyTrue(all(isfinite(gN(:))));
            tc.verifyTrue(all(abs(gN(2:3,:) - g0(2:3,:)) > 1e-6, 'all'), 'the estimable windows must be updated');
        end

        function testMStepNumBinsEqualsNumCells(tc)
            %TESTMSTEPNUMBINSEQUALSNUMCELLS PP_MStep's NewtonRaphson branches
            % re-oriented Hk = HkAll(:,:,c) (N x W) whenever N == numCells,
            % then indexed Hk(k,:) on the transpose (R4d). Invariance: an
            % N == C == 6 problem vs the same problem plus a 7th dummy cell
            % (same E-step output and MC draws) -- cells 1..6 must get the
            % identical mu / beta / gamma update.
            [dN, H, mu, beta, g0, wt, A, Q] = testPointProcessEMCorrectness.squareBinsProblem();
            xK = []; WK = []; ES = [];
            evalc(['[xK,WK,~,ES] = nstat.decoding.PointProcessEM.PP_EStep(A,Q,dN,mu,beta,' ...
                '''poisson'',g0,H,zeros(2,1),1e-3*eye(2));']);
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
            r1 = cell(1,7); r2 = cell(1,7);
            dN7 = [dN; double(rand(1,size(dN,2)) < 0.5)];
            H7 = cat(3, H, H(:,:,1)); mu7 = [mu; mu(1)]; b7 = [beta beta(:,1)]; g7 = [g0 g0(:,1)];
            rng(5);
            evalc(['[r1{1:7}] = nstat.decoding.PointProcessEM.PP_MStep(dN,xK,WK,zeros(2,1),1e-3*eye(2),ES,' ...
                '''poisson'',mu,beta,g0,wt,H,cons,''NewtonRaphson'');']);
            rng(5);
            evalc(['[r2{1:7}] = nstat.decoding.PointProcessEM.PP_MStep(dN7,xK,WK,zeros(2,1),1e-3*eye(2),ES,' ...
                '''poisson'',mu7,b7,g7,wt,H7,cons,''NewtonRaphson'');']);
            tc.verifyEqual(r2{3}(1:6), r1{3}, 'AbsTol', 1e-12, 'mu of cells 1..6');
            tc.verifyEqual(r2{4}(:,1:6), r1{4}, 'AbsTol', 1e-12, 'beta of cells 1..6');
            tc.verifyEqual(r2{5}(:,1:6), r1{5}, 'AbsTol', 1e-12, 'gamma of cells 1..6');
            tc.verifyEqual(r2{1}, r1{1}, 'AbsTol', 1e-12, 'Ahat');
        end

        function testGLMHistoryAllWindowsUnestimable(tc)
            %TESTGLMHISTORYALLWINDOWSUNESTIMABLE single (0,1] ms window with
            % hard-refractory spiking: NO history window is estimable for
            % any cell, getHistCoeffs returns empty labels, and the GLM
            % M-step crashed on histLabels(:,1) (F1). gamma must keep its
            % previous value, in PP_MStep and end to end in PP_EM.
            [dN, A, Q, mu, beta] = testPointProcessEMCorrectness.refractoryProblem();
            C = size(dN,1); delta = 0.001; wt = [0 0.001];
            HkAll = testPointProcessEMCorrectness.historyTensor(dN, wt, delta);
            g0 = -0.3*ones(1, C);
            xK = []; WK = []; ES = [];
            evalc(['[xK,WK,~,ES] = nstat.decoding.PointProcessEM.PP_EStep(A,Q,dN,mu,beta,' ...
                '''poisson'',g0,HkAll,zeros(2,1),1e-9*eye(2));']);
            gN = []; cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
            evalc(['[~,~,~,~,gN] = nstat.decoding.PointProcessEM.PP_MStep(dN,xK,WK,zeros(2,1),' ...
                '1e-9*eye(2),ES,''poisson'',mu,beta,g0,wt,HkAll,cons,''GLM'');']);
            tc.verifyEqual(gN, g0, 'every unestimable window must keep its previous gamma');
            o = cell(1,7); rng(1);
            evalc('[o{1:7}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,Q,mu,beta,''poisson'',delta,g0,wt,[],[],cons,''GLM'');');
            tc.verifyEqual(o{7}, g0, 'PP_EM (GLM): gammahat must stay at its initial value');
        end

        function testGLMMStepMapsCoefficientsByLabel(tc)
            %TESTGLMMSTEPMAPSCOEFFICIENTSBYLABEL the GLM M-step read mu/beta
            % positionally from getCoeffs (F3): it crashed when a covariate
            % label was dropped for every cell, mis-mapped for dx >= 10
            % ('v10' sorts before 'v2') and crashed for a single cell. The
            % result must equal glmfit on the same smoothed states, with a
            % dropped (unestimable) covariate keeping its previous beta.
            testPointProcessEMCorrectness.glmMStepMatchesGlmfit(tc, 'PP', 10, 2, []);
            testPointProcessEMCorrectness.glmMStepMatchesGlmfit(tc, 'PP', 2, 1, []);
            testPointProcessEMCorrectness.glmMStepMatchesGlmfit(tc, 'PP', 2, 3, 2);
        end

    end

    methods (Static)
        function checkStandardErrorsAgainstFD(tc, fitType, C, nW)
            % Construct a case where PP_ComputeParamStandardErrors' missing
            % information vanishes -- W_K ~ 0 (states known) and every
            % parameter at its complete-data MLE, so every score is ~0 --
            % and compare SE.beta / SE.gamma with the inverse of the
            % finite-difference Hessian of the per-cell complete-data
            % log-likelihood (poisson: sum dN*eta - exp(eta); binomial:
            % sum dN*log(p) - p, p = logistic(eta)). The model's
            % information is NOT block diagonal; PP_ComputeParamStandardErrors
            % assembles only the mu, beta and gamma diagonal blocks (cross
            % blocks are dropped), so its SEs are per-block conditional SEs
            % and the expected value is sqrt(diag(inv(-H_block))) of the
            % matching block of the FD Hessian.
            rng(5);
            if nargin < 3 || isempty(C), C = 2; end
            if nargin < 4 || isempty(nW), nW = 3; end
            % K = 1500: the comparison is exact up to the finite-difference
            % error and the ~1e-12 posterior noise, neither of which depends
            % on K; K only has to give every history window spikes.
            dx = 2; K = 1500; delta = 0.001;
            Atrue = 0.99*eye(dx); Qtrue = 0.02*eye(dx);
            x = zeros(dx, K); xp = zeros(dx,1);
            for k = 1:K, xp = Atrue*xp + chol(Qtrue,'lower')*randn(dx,1); x(:,k) = xp; end
            muT = log(0.05)*ones(C,1); betaT = [1 -0.8; 0.5 0.7]; betaT = betaT(:, 1:C);
            wtAll = [0 0.004 0.010 0.025]; wt = wtAll(1:nW+1);
            dN = zeros(C,K);
            for k = 1:K
                eta = muT + betaT'*x(:,k);
                for w = 1:nW
                    lo = max(k - round(wt(w+1)/delta), 1); hi = min(k - round(wt(w)/delta) - 1, k-1);
                    if hi >= lo, eta = eta - 0.5*sum(dN(:,lo:hi),2); end
                end
                if strcmp(fitType,'poisson'), p = min(exp(eta),1); else, p = exp(eta)./(1+exp(eta)); end
                dN(:,k) = rand(C,1) < p;
            end
            histObj = History(wt, 0, (K-1)*delta);
            HkAll = zeros(K, nW, C);
            for c = 1:C
                nst = nspikeTrain((find(dN(c,:)==1)-1)*delta);
                nst.setMinTime(0); nst.setMaxTime((K-1)*delta);
                HkAll(:,:,c) = histObj.computeHistory(nst).dataToMatrix;
            end
            x0 = zeros(dx,1); Px0 = 1e-6*eye(dx);

            % Complete-data MLEs of (mu, beta, gamma) per cell given x.
            np = 1 + dx + nW;
            mu = zeros(C,1); beta = zeros(dx,C); gamma = zeros(nW,C); Hfull = cell(1,C);
            for c = 1:C
                Z = [ones(1,K); x; HkAll(:,:,c)'];
                score = @(th) testPointProcessEMCorrectness.ppScore(th, Z, dN(c,:), fitType);
                th = [muT(c); betaT(:,c); -0.5*ones(nW,1)];
                for it = 1:100
                    [g, H] = score(th);
                    step = H\g; th = th - step;
                    if max(abs(step)) < 1e-12, break; end
                end
                mu(c) = th(1); beta(:,c) = th(2:1+dx); gamma(:,c) = th(2+dx:end);
                h = 1e-6; Hfd = zeros(np);
                for i = 1:np
                    e = zeros(np,1); e(i) = h;
                    Hfd(:,i) = (score(th+e) - score(th-e))/(2*h);
                end
                Hfull{c} = (Hfd+Hfd')/2;
            end
            Sx1 = x0*x0' + x(:,1:end-1)*x(:,1:end-1)';
            Sx10 = x(:,1)*x0' + x(:,2:end)*x(:,1:end-1)';
            A = Sx10/Sx1;
            sumX = x*x' - A*Sx10' - Sx10*A' + A*Sx1*A';
            Q = diag(diag(sumX))/K;
            ES.Sxkm1xkm1 = Sx1;
            WK = repmat(1e-12*eye(dx), [1 1 K]);
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0);
            cons.mcIter = 20;
            SE = [];
            evalc(['SE = nstat.decoding.PointProcessEM.PP_ComputeParamStandardErrors(' ...
                'dN, x, WK, A, Q, x0, Px0, ES, fitType, mu, beta, gamma, wt, HkAll, cons);']);
            for c = 1:C
                Hb = Hfull{c}(2:1+dx, 2:1+dx); Hg = Hfull{c}(2+dx:end, 2+dx:end);
                tc.verifyEqual(SE.mu(c), sqrt(1/(-Hfull{c}(1,1))), 'RelTol', 1e-6, ...
                    sprintf('%s cell %d: SE.mu must match the finite-difference information', fitType, c));
                tc.verifyEqual(SE.beta(:,c), sqrt(diag(inv(-Hb))), 'RelTol', 1e-6, ...
                    sprintf('%s cell %d: SE.beta must match the finite-difference information', fitType, c));
                tc.verifyEqual(SE.gamma(:,c), sqrt(diag(inv(-Hg))), 'RelTol', 1e-6, ...
                    sprintf('%s cell %d: SE.gamma must match the finite-difference information', fitType, c));
            end
        end

        function [g, H] = ppScore(th, Z, dNc, fitType)
            % Score and analytic Hessian of the per-cell complete-data
            % log-likelihood (used only to find the MLE; the expected SEs
            % come from a finite difference of g).
            eta = th'*Z;
            if strcmp(fitType, 'poisson')
                lam = exp(eta);
                g = Z*(dNc - lam)';
                H = -(Z.*lam)*Z';
            else
                p = 1./(1+exp(-eta));
                g = Z*((dNc - p).*(1 - p))';
                H = -(Z.*(p.*(1-p).*(1+dNc-2*p)))*Z';
            end
        end

        function [SE, nTerms] = ppSE(dN, xK, WK, A, Q, ES, mu, beta, H, cons)
            % Direct PP_ComputeParamStandardErrors call (no history), rng(3).
            dx = size(A, 1); SE = []; nTerms = [];
            rng(3);
            evalc(['[SE,~,nTerms] = nstat.decoding.PointProcessEM.PP_ComputeParamStandardErrors(dN,xK,WK,' ...
                'A,Q,zeros(dx,1),1e-6*eye(dx),ES,''poisson'',mu,beta,0,[],H,cons);']);
        end

        function [dN, A, Q, mu, beta, delta] = emProblem()
            % Same 4-cell / 1000-bin problem as testPointProcessEMRuns.
            rng(42);
            C = 4; N = 1000; delta = 0.001; dx = 2;
            A = 0.98*eye(dx); Q = 0.01*eye(dx);
            x = zeros(dx, N);
            for t = 2:N, x(:,t) = A*x(:,t-1) + chol(Q)'*randn(dx,1); end
            mu = log(40*delta)*ones(C,1);
            beta = [1.0 -0.5; 0.3 0.8; -0.7 0.4; 0.6 0.6]';
            dN = double(rand(C,N) < min(exp(mu + beta'*x), 1));
        end

        function [dN, A, Q, mu, beta] = refractoryProblem()
            % 4 cells, 1500 bins, ~40 Hz, hard 1-bin refractory period.
            rng(8);
            C = 4; N = 1500; delta = 0.001; dx = 2;
            A = 0.98*eye(dx); Q = 0.01*eye(dx);
            x = zeros(dx, N);
            for t = 2:N, x(:,t) = A*x(:,t-1) + chol(Q)'*randn(dx,1); end
            mu = log(40*delta)*ones(C,1);
            beta = [1.0 -0.5; 0.3 0.8; -0.7 0.4; 0.6 0.6]';
            dN = zeros(C, N);
            for t = 1:N
                p = min(exp(mu + beta'*x(:,t)), 1);
                if t > 1, p(dN(:,t-1) == 1) = 0; end
                dN(:,t) = rand(C,1) < p;
            end
        end

        function HkAll = historyTensor(dN, wt, delta)
            % N x nWindows x C, built as PP_EM builds it.
            [C, N] = size(dN);
            histObj = History(wt, 0, (N-1)*delta);
            HkAll = zeros(N, numel(wt)-1, C);
            for c = 1:C
                nst = nspikeTrain((find(dN(c,:)==1)-1)*delta, '', delta);
                nst.setMinTime(0); nst.setMaxTime((N-1)*delta);
                HkAll(:,:,c) = histObj.computeHistory(nst).dataToMatrix;
            end
        end

        function [dN, H, mu, beta, g0, wt, A, Q] = squareBinsProblem()
            % N == C == 6 bins/cells, 2 history windows (synthetic counts).
            rng(31);
            C = 6; N = 6; dx = 2;
            A = 0.95*eye(dx); Q = 0.05*eye(dx);
            mu = log(0.3)*ones(C,1); beta = 0.5*randn(dx, C);
            dN = double(rand(C, N) < 0.4);
            H = double(rand(N, 2, C) < 0.4) + double(rand(N, 2, C) < 0.2);
            g0 = -0.3 - 0.2*rand(2, C);
            wt = [0 0.001 0.003];
        end

        function glmMStepMatchesGlmfit(tc, driver, dx, C, dropRow)
            % One GLM M-step (PP_MStep or PPLFP_MStep) on E-step output vs
            % glmfit(x_K', dN(c,:)', 'poisson') for every cell. dropRow:
            % replace that state row of x_K by 1e-5 noise so its
            % coefficient has se >= 100 for every cell (FitResSummary drops
            % the label); that beta row must keep its previous value.
            rng(19); N = 1000; delta = 0.001;
            A = 0.95*eye(dx); Q = 0.01*eye(dx);
            x = zeros(dx, N);
            for t = 2:N, x(:,t) = A*x(:,t-1) + chol(Q)'*randn(dx,1); end
            mu = log(40*delta)*ones(C,1); beta = 0.8*randn(dx, C);
            dN = double(rand(C, N) < min(exp(mu + beta'*x), 1));
            H0 = zeros(N, 1, C); x0 = zeros(dx,1); Px0 = 1e-9*eye(dx);
            xK = []; WK = []; ES = []; muN = []; betaN = [];
            if strcmp(driver, 'PP')
                evalc(['[xK,WK,~,ES] = nstat.decoding.PointProcessEM.PP_EStep(A,Q,dN,mu,beta,' ...
                    '''poisson'',0,H0,x0,Px0);']);
            else
                Cm = randn(2, dx); R = 0.05*eye(2); alpha = [0.1; -0.1];
                y = Cm*x + alpha + chol(R,'lower')*randn(2, N);
                evalc(['[xK,WK,~,ES] = nstat.decoding.PPLFP.PPLFP_EStep(A,Q,Cm,R,y,alpha,dN,mu,beta,' ...
                    '''poisson'',delta,0,H0,x0,Px0);']);
            end
            if ~isempty(dropRow)
                rng(2); xK(dropRow,:) = 1e-5*randn(1, N);
            end
            if strcmp(driver, 'PP')
                cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
                evalc(['[~,~,muN,betaN] = nstat.decoding.PointProcessEM.PP_MStep(dN,xK,WK,x0,Px0,ES,' ...
                    '''poisson'',mu,beta,0,[],H0,cons,''GLM'');']);
            else
                cons = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints();
                evalc(['[~,~,~,~,~,muN,betaN] = nstat.decoding.PPLFP.PPLFP_MStep(dN,y,xK,WK,x0,Px0,ES,' ...
                    '''poisson'',mu,beta,0,[],H0,cons,''GLM'');']);
            end
            lbl = sprintf('%s dx=%d C=%d drop=%s', driver, dx, C, mat2str(dropRow));
            tc.verifySize(muN, [C 1], lbl); tc.verifySize(betaN, [dx C], lbl);
            ws = warning('off', 'all'); restore = onCleanup(@() warning(ws));
            for c = 1:C
                b = glmfit(xK', dN(c,:)', 'poisson');
                tc.verifyEqual(muN(c), b(1), 'AbsTol', 1e-6, [lbl ': mu']);
                for i = 1:dx
                    if isequal(i, dropRow)
                        tc.verifyEqual(betaN(i,c), beta(i,c), [lbl ': dropped covariate keeps previous beta']);
                    else
                        tc.verifyEqual(betaN(i,c), b(i+1), 'AbsTol', 1e-6, sprintf('%s: beta(%d,%d)', lbl, i, c));
                    end
                end
            end
        end

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
