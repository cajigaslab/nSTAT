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
    end

    methods (Static)
        function checkStandardErrorsAgainstFD(tc, fitType)
            % Construct a case where PP_ComputeParamStandardErrors' missing
            % information vanishes -- W_K ~ 0 (states known) and every
            % parameter at its complete-data MLE, so every score is ~0 --
            % and compare SE.beta / SE.gamma with the inverse of the
            % finite-difference Hessian of the per-cell complete-data
            % log-likelihood (poisson: sum dN*eta - exp(eta); binomial:
            % sum dN*log(p) - p, p = logistic(eta)). The function's
            % complete information is block diagonal (mu | beta | gamma),
            % so the expected SE is sqrt(diag(inv(-H_block))).
            rng(5);
            dx = 2; C = 2; K = 3000; delta = 0.001;
            Atrue = 0.99*eye(dx); Qtrue = 0.02*eye(dx);
            x = zeros(dx, K); xp = zeros(dx,1);
            for k = 1:K, xp = Atrue*xp + chol(Qtrue,'lower')*randn(dx,1); x(:,k) = xp; end
            muT = log(0.05)*ones(C,1); betaT = [1 -0.8; 0.5 0.7];
            wt = [0 0.004 0.010 0.025]; nW = numel(wt)-1;
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
                tc.verifyEqual(SE.beta(:,c), sqrt(diag(inv(-Hb))), 'RelTol', 1e-3, ...
                    sprintf('%s cell %d: SE.beta must match the finite-difference information', fitType, c));
                tc.verifyEqual(SE.gamma(:,c), sqrt(diag(inv(-Hg))), 'RelTol', 1e-3, ...
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
