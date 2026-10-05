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
        function checkSEAgainstFD(tc, fitType, withHistory, fields)
            % PPLFP_ComputeParamStandardErrors with vanishing missing
            % information: W_K ~ 0 (states known) and EVERY parameter at
            % its complete-data MLE given x (A, Q, C, alpha, R in closed
            % form; mu, beta, gamma by Newton), so every score is ~0. The
            % complete information is block diagonal, so each SE must equal
            % sqrt(diag(inv(-H_block))) of a finite-difference Hessian of
            % the per-cell point-process log-likelihood. dx = 1 and one
            % history window keep the comparison independent of the
            % (unchanged) SE.beta/SE.gamma reshape in this function.
            rng(5);
            dx = 1; nC = 2; K = 3000; delta = 0.001;
            x = zeros(dx, K); xp = 0;
            for k = 1:K, xp = 0.99*xp + sqrt(0.02)*randn; x(:,k) = xp; end
            Cm = [1; -0.5]; alphaT = [0.1; -0.1]; Rt = diag([0.05 0.08]);
            y = Cm*x + alphaT + chol(Rt,'lower')*randn(2, K);
            muT = log(0.05)*ones(nC,1); betaT = [1 -0.8];
            if withHistory, wt = [0 0.010]; else, wt = []; end
            dN = zeros(nC, K);
            for k = 1:K
                eta = muT + betaT'*x(:,k);
                if withHistory
                    lo = max(k - round(wt(2)/delta), 1); hi = k-1;
                    if hi >= lo, eta = eta - 0.5*sum(dN(:,lo:hi),2); end
                end
                if strcmp(fitType,'poisson'), p = min(exp(eta),1); else, p = exp(eta)./(1+exp(eta)); end
                dN(:,k) = rand(nC,1) < p;
            end
            if withHistory
                histObj = History(wt, 0, (K-1)*delta);
                HkAll = zeros(K, 1, nC);
                for c = 1:nC
                    nst = nspikeTrain((find(dN(c,:)==1)-1)*delta);
                    nst.setMinTime(0); nst.setMaxTime((K-1)*delta);
                    HkAll(:,:,c) = histObj.computeHistory(nst).dataToMatrix;
                end
            else
                HkAll = zeros(K, 1, nC);
            end
            x0 = 0; Px0 = 1e-6;
            np = 1 + dx + withHistory;
            mu = zeros(nC,1); beta = zeros(dx,nC); gamma = zeros(1,nC); Hfull = cell(1,nC);
            for c = 1:nC
                Z = [ones(1,K); x];
                th = [muT(c); betaT(:,c)];
                if withHistory, Z = [Z; HkAll(:,1,c)']; th = [th; -0.5]; end %#ok<AGROW>
                score = @(t) testPointProcessEMCorrectness.ppScore(t, Z, dN(c,:), fitType);
                for it = 1:100
                    [g, H] = score(th); step = H\g; th = th - step;
                    if max(abs(step)) < 1e-12, break; end
                end
                mu(c) = th(1); beta(:,c) = th(2:1+dx);
                if withHistory, gamma(c) = th(end); end
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
                    tc.verifyEqual(SE.mu(c), sqrt(1/(-Hc(1,1))), 'RelTol', 1e-3, ...
                        sprintf('%s cell %d: SE.mu must match the finite-difference information', fitType, c));
                end
                if any(strcmp(fields, 'beta'))
                    Hb = Hc(2:1+dx, 2:1+dx);
                    tc.verifyEqual(SE.beta(:,c), sqrt(diag(inv(-Hb))), 'RelTol', 1e-3, ...
                        sprintf('%s cell %d: SE.beta must match the finite-difference information', fitType, c));
                end
                if any(strcmp(fields, 'gamma'))
                    tc.verifyEqual(SE.gamma(:,c), sqrt(1/(-Hc(end,end))), 'RelTol', 1e-3, ...
                        sprintf('%s cell %d: SE.gamma must match the finite-difference information', fitType, c));
                end
            end
        end

        function P = makeProblem(fitType, useHist)
            rng(21);
            P.nC = 4; N = 1000; P.delta = 0.001; dx = 2; dy = 2;
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

        function [xK, WK, ES, ll] = eStep(P, mu, beta, gamma)
            xK = []; WK = []; ll = []; ES = [];
            evalc(['[xK,WK,ll,ES] = nstat.decoding.PPLFP.PPLFP_EStep(P.A,P.Q,P.Cm,P.R,P.y,P.alpha,' ...
                'P.dN,mu,beta,P.fitType,P.delta,gamma,P.HkAll,P.x0,P.Px0);']);
        end
    end
end
