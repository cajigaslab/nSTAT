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

        function testDefaultHistoryWindows(tc)
            %TESTDEFAULTHISTORYWINDOWS with windowTimes = [] and a nonzero
            % gamma, PP_EM built 0:delta:(length(gamma)+1)*delta -- one
            % window too many (and length() of a W x C matrix is max(W,C))
            % -- and could not use a shared gamma column, so every
            % default-window call failed with MATLAB:innerdim. The default
            % must equal the explicit call with W = size(gamma,1) windows
            % 0:delta:W*delta and the shared column replicated per cell.
            [dN, A, Q, mu, beta, delta] = testPointProcessEMCorrectness.emProblem();
            dN = dN(:, 1:300); C = size(dN,1);
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
            cases = { -0.5*[1;0.6;0.3],            -0.5*repmat([1;0.6;0.3],1,C), 0:delta:3*delta; ...
                      -0.5,                        -0.5*ones(1,C),               0:delta:1*delta; ...
                      -0.4*[1 0.5 0.8 0.6; 0.3 0.7 0.2 0.9], ...
                      -0.4*[1 0.5 0.8 0.6; 0.3 0.7 0.2 0.9],                     0:delta:2*delta};
            for i = 1:size(cases,1)
                r1 = cell(1,7); r2 = cell(1,7);
                rng(3);
                evalc('[r1{1:7}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,Q,mu,beta,''poisson'',delta,cases{i,1},[],[],[],cons);');
                rng(3);
                evalc('[r2{1:7}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,Q,mu,beta,''poisson'',delta,cases{i,2},cases{i,3},[],[],cons);');
                tc.verifyEqual(r1, r2, sprintf('case %d: default windows must equal explicit 0:delta:W*delta', i));
            end
        end

        function testTimeBaseEquivalence(tc)
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
    end

    methods (Static)
        function checkStandardErrorsAgainstFD(tc, fitType, C)
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
            if nargin < 3 || isempty(C), C = 2; end
            % K = 1500: the comparison is exact up to the finite-difference
            % error and the ~1e-12 posterior noise, neither of which depends
            % on K; K only has to give every history window spikes.
            dx = 2; K = 1500; delta = 0.001;
            Atrue = 0.99*eye(dx); Qtrue = 0.02*eye(dx);
            x = zeros(dx, K); xp = zeros(dx,1);
            for k = 1:K, xp = Atrue*xp + chol(Qtrue,'lower')*randn(dx,1); x(:,k) = xp; end
            muT = log(0.05)*ones(C,1); betaT = [1 -0.8; 0.5 0.7]; betaT = betaT(:, 1:C);
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
                tc.verifyEqual(SE.mu(c), sqrt(1/(-Hfull{c}(1,1))), 'RelTol', 1e-3, ...
                    sprintf('%s cell %d: SE.mu must match the finite-difference information', fitType, c));
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
