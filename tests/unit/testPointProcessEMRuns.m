classdef testPointProcessEMRuns < matlab.unittest.TestCase
    %TESTPOINTPROCESSEMRUNS end-to-end regression tests for
    % nstat.decoding.PointProcessEM.PP_EM (and the PP_MStep / PPLFP_MStep
    % GLM M-step side effects it depends on).
    %
    % Before fix/pp-em, PP_EM could not run in ANY configuration:
    %   - no history: (1,1,numCells) HkAll -> PPAF.PPDecode_updateLinear
    %     "Index in position 3 exceeds array bounds" at time step 2;
    %   - GLM M-step: `close all` deleted PP_EM's progress figure ->
    %     `figure(h)` error at iteration 2; the GLM fit was written to the
    %     input variables, so mu/beta/gamma were never updated;
    %   - GLM M-step with history: FitResSummary.getHistIndex read only
    %     neuron 1 -> undefined `baseStrings` in getHistCoeffs;
    %   - NewtonRaphson M-step: undefined `xKDraw`; the binomial beta
    %     Hessian had the wrong sign (NR diverged);
    %   - default constraints: non-finite E-step log-likelihood fed into
    %     the M-step (crash) or selected as the "best" iterate.
    %
    % Synthetic problem (rng(42)): 2-D AR(1) latent state, 4 cells,
    % 1000 one-millisecond bins, ~40 Hz baseline, optional refractory-like
    % history over windows [0 5 10 20] ms (true gamma = -0.5). The
    % brief's original 400-bin / 20 Hz problem has only 5-9 spikes per
    % cell -- too few for the GLM M-step, which then diverges and stops
    % at iteration 2 returning the initial parameters -- so a larger,
    % still-fast problem is used for the convergence assertions.
    %
    % Constraints: PP_EMCreateConstraints(1,0,1,0,0,0) (A full, Q diagonal,
    % x0/Px0 NOT estimated). With the defaults (Estimatex0=Px0=1) the Px0
    % M-step Px0hat=(x0hat-x0)(x0hat-x0)'.*I collapses to ~1e-17 after one
    % iteration and logll -> +Inf; testDefaultConstraintsTerminate covers
    % that PP_EM now stops cleanly there instead of crashing. The parity
    % export recipe for the sibling PPLFP_EM disables x0/Px0 estimation
    % for the same reason.
    %
    % The 8-combination convergence test (testPPEMRunsAndConverges) now
    % lives in tests/integration/testPointProcessEMIntegration.m (run with
    % `tools/run_unit_tests.sh --integration`); its helpers below are
    % public for that reason.

    properties (Constant)
        WindowTimes = [0 0.005 0.010 0.020];
        GammaTrue = -0.5;
        Gamma0 = -0.5;   % initial history coefficients passed to PP_EM
    end

    methods (TestMethodSetup)
        function isolateGlobalState(tc)
            % PP_MStep's GLM branch calls warning('OFF') (global) and
            % PP_EM draws a progress figure. Restore both so other tests
            % (e.g. verifyWarning-based shims) are unaffected.
            warnState = warning;
            tc.addTeardown(@() warning(warnState));
            figVis = get(0, 'DefaultFigureVisible');
            set(0, 'DefaultFigureVisible', 'off');
            tc.addTeardown(@() set(0, 'DefaultFigureVisible', figVis));
            figsBefore = findall(0, 'Type', 'figure');
            tc.addTeardown(@() testPointProcessEMRuns.closeNewFigures(figsBefore));
        end
    end

    methods (Test)
        function testScalarZeroGammaMeansNoHistory(tc)
            %TESTSCALARZEROGAMMAMEANSNOHISTORY gamma=0 with empty
            % windowTimes must be treated like gamma=[] (mirrors PPLFP_EM
            % FIX #98) instead of inferring 2 history windows.
            P = testPointProcessEMRuns.makeProblem('poisson', false);
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0);
            mu0 = []; beta0 = []; mu1 = []; beta1 = []; g1 = [];
            rng(7);
            evalc(['[~,~,~,~,mu0,beta0] = nstat.decoding.PointProcessEM.PP_EM(' ...
                'P.dN,P.A,P.Q,P.mu,P.beta,''poisson'',P.delta,[],[],P.x0,P.Px0,cons,''NewtonRaphson'');']);
            rng(7);
            evalc(['[~,~,~,~,mu1,beta1,g1] = nstat.decoding.PointProcessEM.PP_EM(' ...
                'P.dN,P.A,P.Q,P.mu,P.beta,''poisson'',P.delta,0,[],P.x0,P.Px0,cons,''NewtonRaphson'');']);
            tc.verifyEqual(mu1, mu0, 'gamma=0 must reproduce the gamma=[] fit');
            tc.verifyEqual(beta1, beta0);
            tc.verifyEqual(g1, 0);
        end

        function testGLMMStepUpdatesParameters(tc)
            %TESTGLMMSTEPUPDATESPARAMETERS PP_MStep('GLM') used to return
            % mu/beta/gamma byte-identical to its inputs.
            for useHist = [false true]
                P = testPointProcessEMRuns.makeProblem('poisson', useHist);
                [xK, WK, ES, HkAll, gamma0, wt] = testPointProcessEMRuns.eStep(P);
                cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0);
                muN = []; betaN = []; gammaN = [];
                evalc(['[~,~,muN,betaN,gammaN] = nstat.decoding.PointProcessEM.PP_MStep(' ...
                    'P.dN,xK,WK,P.x0,P.Px0,ES,''poisson'',P.mu,P.beta,gamma0,wt,HkAll,cons,''GLM'');']);
                tc.verifyFalse(isequal(muN, P.mu), 'GLM M-step must update mu');
                tc.verifyFalse(isequal(betaN, P.beta), 'GLM M-step must update beta');
                tc.verifyTrue(all(isfinite(muN)) && all(isfinite(betaN(:))));
                if useHist
                    tc.verifyFalse(isequal(gammaN, gamma0), 'GLM M-step must update gamma');
                    tc.verifyTrue(all(isfinite(gammaN(:))));
                end
            end
        end

        function testGLMMStepLeavesFiguresOpen(tc)
            %TESTGLMMSTEPLEAVESFIGURESOPEN PP_MStep / PPLFP_MStep used to
            % `close all`, deleting the caller's figures (and PP_EM's own
            % progress figure, which crashed iteration 2).
            h = figure('Visible', 'off');
            nFigs = numel(findall(0, 'Type', 'figure'));
            P = testPointProcessEMRuns.makeProblem('poisson', false);
            [xK, WK, ES, HkAll] = testPointProcessEMRuns.eStep(P);
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0);
            evalc(['nstat.decoding.PointProcessEM.PP_MStep(P.dN,xK,WK,P.x0,P.Px0,ES,' ...
                '''poisson'',P.mu,P.beta,0,[],HkAll,cons,''GLM'');']);
            tc.verifyTrue(isgraphics(h), 'PP_MStep(GLM) must not close the caller''s figures');
            tc.verifyEqual(numel(findall(0, 'Type', 'figure')), nFigs, ...
                'the GLM M-step (makePlot=0) must neither close nor create figures');

            % PPLFP_MStep: same GLM block, same removed `close all`.
            dy = 2; Cmat = [1 0.5; -0.3 1]; R = 0.05*eye(dy); alpha = [0.1; -0.1];
            rng(3);
            y = Cmat*P.x + alpha + chol(R)'*randn(dy, size(P.x,2));
            consL = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints;
            consL.Estimatex0 = 0; consL.EstimatePx0 = 0;
            xKL = []; WKL = []; ESL = [];
            evalc(['[xKL,WKL,~,ESL] = nstat.decoding.PPLFP.PPLFP_EStep(P.A,P.Q,Cmat,R,y,alpha,' ...
                'P.dN,P.mu,P.beta,''poisson'',P.delta,0,HkAll,P.x0,P.Px0);']);
            evalc(['nstat.decoding.PPLFP.PPLFP_MStep(P.dN,y,xKL,WKL,P.x0,P.Px0,ESL,' ...
                '''poisson'',P.mu,P.beta,0,[],HkAll,consL,''GLM'');']);
            tc.verifyTrue(isgraphics(h), 'PPLFP_MStep(GLM) must not close the caller''s figures');
            close(h);
        end

        function testDefaultConstraintsTerminate(tc)
            %TESTDEFAULTCONSTRAINTSTERMINATE with x0/Px0 estimation (the
            % defaults before round 2: Estimatex0 = EstimatePx0 = 1) Px0hat collapses and the
            % E-step logll goes non-finite / complex. These three
            % combinations used to crash in the next M-step (chol; bnlrCG
            % undefined `A`) or return a degenerate iterate; PP_EM must
            % now stop and return the best valid iterate.
            cases = {'poisson','NewtonRaphson',false; ...
                     'poisson','NewtonRaphson',true; ...
                     'binomial','GLM',true};
            for i = 1:size(cases, 1)
                P = testPointProcessEMRuns.makeProblem(cases{i,1}, cases{i,3});
                % The pre-round-2 defaults (x0/Px0 estimated), passed
                % explicitly now that PP_EMCreateConstraints() no longer
                % estimates them.
                [R, emLog] = testPointProcessEMRuns.runEM(P, cases{i,2}, ...
                    nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,1,1));
                label = sprintf('%s/%s/hist=%d', cases{i,:});
                tc.verifyTrue(all(isfinite(R.mu)) && isreal(R.mu) && ...
                    all(isfinite(R.beta(:))) && all(isfinite(R.xK(:))), ...
                    [label ': returned iterate must be finite and real']);
                ll = testPointProcessEMRuns.parseLogLL(emLog);
                % The printed E-step logll values are those of PP_EM's
                % internally scaled system (x_s = Tq*x, Tq = inv(chol(Q0)));
                % IC.llcomp is on the original scale (F10), i.e. the best
                % one plus the Jacobian (K+1)*log|det Tq|.
                Tq = eye(size(P.Q))/chol(P.Q);
                jac = (size(P.dN,2)+1)*log(abs(det(Tq)));
                tc.verifyEqual(real(R.IC.llcomp), testPointProcessEMRuns.bestLL(ll) + jac, 'RelTol', 1e-7, ...
                    [label ': must return the best finite log-likelihood iterate']);
            end
        end

        function testStandardErrorOutputsRun(tc)
            %TESTSTANDARDERROROUTPUTSRUN requesting SE/Pvals/nIter
            % (nargout > 10) runs PP_ComputeParamStandardErrors. The
            % binomial + history gamma block used Hk(k,:)'*Hk(:,k) and
            % always errored. Here only "runs" (and finite poisson SEs) is
            % asserted; the SE values themselves are checked against a
            % finite-difference Hessian in testPointProcessEMCorrectness.
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0);
            cons.mcIter = 100;   % SE Monte Carlo size; only "runs/finite" is asserted here
            for ft = {'poisson', 'binomial'}
                P = testPointProcessEMRuns.makeProblem(ft{1}, true);
                g0 = testPointProcessEMRuns.Gamma0*ones(numel(P.wt)-1, P.C);
                IC = []; SE = []; Pvals = []; nIter = [];
                rng(42);
                evalc(['[~,~,~,~,~,~,~,~,~,IC,SE,Pvals,nIter] = nstat.decoding.PointProcessEM.PP_EM(' ...
                    'P.dN,P.A,P.Q,P.mu,P.beta,ft{1},P.delta,g0,P.wt,P.x0,P.Px0,cons,''NewtonRaphson'');']);
                tc.verifyGreaterThanOrEqual(nIter, 2);
                tc.verifyTrue(isstruct(SE) && isstruct(Pvals) && isstruct(IC));
                if strcmp(ft{1}, 'poisson')
                    tc.verifyTrue(all(isfinite(SE.beta(:))) && isreal(SE.beta), ...
                        'poisson beta standard errors must be finite and real');
                    tc.verifyTrue(all(isfinite(SE.mu(:))) && isreal(SE.mu));
                end
            end
        end
    end

    methods (Static)
        function P = makeProblem(fitType, useHist)
            rng(42);
            P.C = 4; P.N = 1000; P.delta = 0.001; dx = 2;
            P.A = 0.98*eye(dx); P.Q = 0.01*eye(dx);
            x = zeros(dx, P.N);
            for t = 2:P.N
                x(:,t) = P.A*x(:,t-1) + chol(P.Q)'*randn(dx,1);
            end
            P.x = x;
            P.mu = log(40*P.delta)*ones(P.C,1);
            P.beta = [1.0 -0.5; 0.3 0.8; -0.7 0.4; 0.6 0.6]';
            wt = testPointProcessEMRuns.WindowTimes; nW = numel(wt)-1;
            dN = zeros(P.C, P.N);
            for t = 1:P.N
                eta = P.mu + P.beta'*x(:,t);
                if useHist
                    for w = 1:nW
                        lo = max(t - round(wt(w+1)/P.delta), 1);
                        hi = min(t - round(wt(w)/P.delta) - 1, t-1);
                        if hi >= lo
                            eta = eta + testPointProcessEMRuns.GammaTrue*sum(dN(:,lo:hi), 2);
                        end
                    end
                end
                if strcmp(fitType, 'binomial')
                    p = exp(eta)./(1+exp(eta));
                else
                    p = min(exp(eta), 1);
                end
                dN(:,t) = rand(P.C,1) < p;
            end
            P.dN = dN;
            P.fitType = fitType;
            P.useHist = useHist;
            P.x0 = zeros(dx,1); P.Px0 = 1e-9*eye(dx);
            if useHist
                P.wt = wt;
            else
                P.wt = [];
            end
        end

        function [R, emLog] = runEM(P, method, cons)
            if P.useHist
                g0 = testPointProcessEMRuns.Gamma0*ones(numel(P.wt)-1, P.C);
            else
                g0 = [];
            end
            R = struct();
            rng(42);
            emLog = evalc(['[R.xK,R.WK,R.A,R.Q,R.mu,R.beta,R.gamma,R.x0,R.Px0,R.IC] = ' ...
                'nstat.decoding.PointProcessEM.PP_EM(P.dN,P.A,P.Q,P.mu,P.beta,' ...
                'P.fitType,P.delta,g0,P.wt,P.x0,P.Px0,cons,method);']);
        end

        function [xK, WK, ES, HkAll, gamma0, wt] = eStep(P)
            % One E-step in the original coordinates, with HkAll built as
            % PP_EM builds it (time x window x cell).
            C = P.C; N = P.N;
            if P.useHist
                wt = P.wt;
                histObj = History(wt, 0, (N-1)*P.delta);
                HkAll = zeros(N, numel(wt)-1, C);
                for c = 1:C
                    nst = nspikeTrain((find(P.dN(c,:)==1)-1)*P.delta);
                    nst.setMinTime(0); nst.setMaxTime((N-1)*P.delta);
                    HkAll(:,:,c) = histObj.computeHistory(nst).dataToMatrix;
                end
                gamma0 = testPointProcessEMRuns.Gamma0*ones(numel(wt)-1, C);
            else
                wt = []; HkAll = zeros(N, 1, C); gamma0 = 0;
            end
            xK = []; WK = []; ES = [];
            evalc(['[xK,WK,~,ES] = nstat.decoding.PointProcessEM.PP_EStep(' ...
                'P.A,P.Q,P.dN,P.mu,P.beta,P.fitType,gamma0,HkAll,P.x0,P.Px0);']);
        end

        function ll = parseLogLL(emLog)
            % 'logll: <num2str>' lines printed by PP_EStep, one per EM
            % iteration. Non-finite values parse as +/-Inf/NaN; a complex
            % value (log of a non-positive determinant) parses as complex.
            tok = regexp(emLog, 'logll: (\S+)', 'tokens');
            ll = cellfun(@(t) str2double(t{1}), tok);
        end

        function b = bestLL(ll)
            % Best finite, real log-likelihood (PP_EM's selection rule).
            ok = isfinite(ll) & imag(ll) == 0;
            b = max(real(ll(ok)));
        end

        function closeNewFigures(figsBefore)
            figsNow = findall(0, 'Type', 'figure');
            close(setdiff(figsNow, figsBefore));
        end
    end
end
