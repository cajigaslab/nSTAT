classdef testSESingularInformationEM < matlab.unittest.TestCase
    %TESTSESINGULARINFORMATIONEM PP_EM with standard errors on a problem
    % with separated history windows (issue #136).
    %
    % A separated window (no spike in it is followed by a spike) walks its
    % gamma to the exp() underflow, where its information and score are
    % exactly 0, so the observed information is singular. PP_EM with SEs
    % requested then never returned (nearestSPD looped on the Inf/NaN
    % inverse; on master this problem was killed after 150 s). Now it
    % returns, warns, and reports NaN SEs exactly for the separated
    % windows' gamma, with every other SE finite. The problem is the
    % nstat-python em_drivers.mat "pp_sep" case (rng(47), N = 600, C = 4,
    % windows [0 1 2 5] ms); the flagged set equals the Python port's.

    methods (TestMethodSetup)
        function isolateGlobalState(tc)
            warnState = warning;
            tc.addTeardown(@() warning(warnState));
            figVis = get(0, 'DefaultFigureVisible');
            set(0, 'DefaultFigureVisible', 'off');
            tc.addTeardown(@() set(0, 'DefaultFigureVisible', figVis));
            tc.addTeardown(@() close('all'));
        end
    end

    methods (Test)
        function testSeparatedWindowsGiveNaNStandardErrors(tc)
            [dN, A, Q, mu0, beta0, gamma0, wSep, delta, nSpkHist] = tc.buildSeparatedProblem();
            separated = (nSpkHist == 0);
            tc.assertTrue(any(separated(:)), 'the problem must have a separated window');
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0,0,100,0);
            o = cell(1,13);
            lastwarn('');
            evalc('[o{1:13}] = nstat.decoding.PointProcessEM.PP_EM(dN, A, Q, mu0, beta0, ''poisson'', delta, gamma0, wSep, [], [], cons);');
            [~, id] = lastwarn;
            tc.verifyEqual(id, 'nSTAT:EM:singularInformation');
            SE = o{11};
            tc.verifyEqual(isnan(SE.gamma), separated);
            f = fieldnames(SE);
            for i = 1:numel(f)
                v = SE.(f{i});
                if strcmp(f{i}, 'gamma'), v = v(~separated); end
                tc.verifyTrue(all(isfinite(v(:))), sprintf('SE.%s must be finite', f{i}));
            end
            P = o{12};
            tc.verifyEqual(isnan(P.gamma), separated);
        end
    end

    methods (Static, Access = private)
        function [dN, A, Q, mu0, beta0, gamma0, wSep, delta, nSpkHist] = buildSeparatedProblem()
        rng(47); dx=2; C=4; delta=0.001; N=600;
        A = [0.98 0.02; -0.03 0.96]; Q = diag([0.01 0.02]);
        betaTrue = [0.9 -0.7 0.5 0.6; 0.4 0.8 -0.6 -0.3];
        wSep = [0 0.001 0.002 0.005]; gammaTrue = repmat([-3; -1; -0.3],1,C);
        x = zeros(dx,N); xPrev = zeros(dx,1); cholQ = chol(Q,'lower');
        for k=1:N, xPrev = A*xPrev + cholQ*randn(dx,1); x(:,k)=xPrev; end
        mu = log(linspace(30,60,C)'*delta);
        u = rand(C,N); dN = zeros(C,N);
        for k=1:N
          eta = mu + betaTrue'*x(:,k);
          for w=1:3
            lags = find((1:N)*delta > wSep(w)+1e-12 & (1:N)*delta <= wSep(w+1)+1e-12); lags = lags(lags<k);
            if ~isempty(lags), eta = eta + gammaTrue(w,:)'.*sum(dN(:,k-lags),2); end
          end
          dN(:,k) = double(u(:,k) < min(exp(eta),1));
        end
        mu0 = mu + 0.3; beta0 = 0.5*betaTrue; gamma0 = 0.5*gammaTrue;
        histObj = History(wSep, 0, (N-1)*delta); HkAll = zeros(N,3,C);
        for c=1:C
          nst = nspikeTrain((find(dN(c,:)==1)-1)*delta, '', delta); nst.setMinTime(0); nst.setMaxTime((N-1)*delta);
          HkAll(:,:,c) = histObj.computeHistory(nst).dataToMatrix;
        end
        nSpkHist = squeeze(sum(HkAll > 0 & permute(repmat(dN,[1 1 3]),[2 3 1]),1));
        end
    end
end
