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

        function [xK, WK, ES, ll] = eStep(P, mu, beta, gamma)
            xK = []; WK = []; ll = []; ES = [];
            evalc(['[xK,WK,ll,ES] = nstat.decoding.PPLFP.PPLFP_EStep(P.A,P.Q,P.Cm,P.R,P.y,P.alpha,' ...
                'P.dN,mu,beta,P.fitType,P.delta,gamma,P.HkAll,P.x0,P.Px0);']);
        end
    end
end
