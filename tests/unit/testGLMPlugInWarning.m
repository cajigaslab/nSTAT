classdef testGLMPlugInWarning < matlab.unittest.TestCase
    %TESTGLMPLUGINWARNING (M3) PP_EM / PP_MStep / PPLFP_EM / PPLFP_MStep
    % must warn, with id nSTAT:EM:glmPlugIn, that MstepMethod='GLM' is a
    % plug-in fit on the smoothed means (ignores W_K), which inflates
    % beta and can drift, and that 'NewtonRaphson' (the default) is
    % preferred. The warning fires ONCE per top-level call -- once per
    % PP_EM / PPLFP_EM run, not once per internal M-step iteration, and
    % once for a direct PP_MStep / PPLFP_MStep call -- and never for
    % MstepMethod='NewtonRaphson'. This file only checks the warning;
    % testPointProcessEMCorrectness / testPPLFPEMCorrectness check that
    % the GLM path's numbers are unaffected.

    methods (Test)
        function testPP_EMWarnsOncePerCall(tc)
            [dN, A, Q, mu, beta, delta] = testPointProcessEMCorrectness.emProblem(); %#ok<ASGLU>
            r = cell(1,10); %#ok<NASGU>
            rng(42);
            warning('on', 'nSTAT:EM:glmPlugIn');
            txt = evalc(['[r{1:10}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,Q,mu,beta,' ...
                '''poisson'',delta,[],[],[],[],[],''GLM'');']);
            n = testGLMPlugInWarning.countMatches(txt);
            tc.verifyEqual(n, 1, 'PP_EM(GLM) must warn exactly once per call, not once per M-step iteration');
        end

        function testPP_EMNoWarningForNewtonRaphson(tc)
            [dN, A, Q, mu, beta, delta] = testPointProcessEMCorrectness.emProblem(); %#ok<ASGLU>
            r = cell(1,10); %#ok<NASGU>
            rng(42);
            warning('on', 'nSTAT:EM:glmPlugIn');
            txt = evalc(['[r{1:10}] = nstat.decoding.PointProcessEM.PP_EM(dN,A,Q,mu,beta,' ...
                '''poisson'',delta);']);
            n = testGLMPlugInWarning.countMatches(txt);
            tc.verifyEqual(n, 0, 'the default (NewtonRaphson) must not warn nSTAT:EM:glmPlugIn');
        end

        function testPP_MStepDirectCallWarnsOnce(tc)
            [dN, A, Q, mu, beta, delta] = testPointProcessEMCorrectness.emProblem();
            H0 = zeros(size(dN,2), 1, size(dN,1));
            xK = []; WK = []; ES = []; %#ok<NASGU>
            evalc(['[xK,WK,~,ES] = nstat.decoding.PointProcessEM.PP_EStep(A,Q,dN,mu,beta,' ...
                '''poisson'',0,H0,zeros(2,1),1e-6*eye(2));']);
            cons = nstat.decoding.PointProcessEM.PP_EMCreateConstraints(1,0,1,0,0,0); %#ok<NASGU>
            warning('on', 'nSTAT:EM:glmPlugIn');
            txt = evalc(['nstat.decoding.PointProcessEM.PP_MStep(dN,xK,WK,zeros(2,1),1e-6*eye(2),ES,' ...
                '''poisson'',mu,beta,0,[],H0,cons,''GLM'',delta);']);
            n = testGLMPlugInWarning.countMatches(txt);
            tc.verifyEqual(n, 1, 'a direct PP_MStep(...,''GLM'') call must warn exactly once');
        end

        function testPPLFP_EMWarnsOncePerCall(tc)
            P = testPPLFPEMCorrectness.makeProblem('poisson', false, 400); %#ok<NASGU>
            o = cell(1,13); %#ok<NASGU>
            rng(42);
            warning('on', 'nSTAT:EM:glmPlugIn');
            txt = evalc(['[o{1:13}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,' ...
                'P.mu,P.beta,''poisson'',P.delta,[],[],[],[],[],''GLM'');']);
            n = testGLMPlugInWarning.countMatches(txt);
            tc.verifyEqual(n, 1, 'PPLFP_EM(GLM) must warn exactly once per call, not once per M-step iteration');
        end

        function testPPLFP_EMNoWarningForNewtonRaphson(tc)
            P = testPPLFPEMCorrectness.makeProblem('poisson', false, 400); %#ok<NASGU>
            o = cell(1,13); %#ok<NASGU>
            rng(42);
            warning('on', 'nSTAT:EM:glmPlugIn');
            txt = evalc(['[o{1:13}] = nstat.decoding.PPLFP.PPLFP_EM(P.y,P.dN,P.A,P.Q,P.Cm,P.R,P.alpha,' ...
                'P.mu,P.beta,''poisson'',P.delta);']);
            n = testGLMPlugInWarning.countMatches(txt);
            tc.verifyEqual(n, 0);
        end

        function testPPLFP_MStepDirectCallWarnsOnce(tc)
            P = testPPLFPEMCorrectness.makeProblem('poisson', false, 400);
            H0 = zeros(size(P.dN,2), 1, size(P.dN,1));
            xK = []; WK = []; ES = []; %#ok<NASGU>
            evalc(['[xK,WK,~,ES] = nstat.decoding.PPLFP.PPLFP_EStep(P.A,P.Q,P.Cm,P.R,P.y,P.alpha,P.dN,' ...
                'P.mu,P.beta,''poisson'',P.delta,0,H0,P.x0,P.Px0);']);
            cons = nstat.decoding.PPLFP.PPLFP_EMCreateConstraints(); %#ok<NASGU>
            warning('on', 'nSTAT:EM:glmPlugIn');
            txt = evalc(['nstat.decoding.PPLFP.PPLFP_MStep(P.dN,P.y,xK,WK,P.x0,P.Px0,ES,''poisson'',' ...
                'P.mu,P.beta,0,[],H0,cons,''GLM'',P.delta);']);
            n = testGLMPlugInWarning.countMatches(txt);
            tc.verifyEqual(n, 1, 'a direct PPLFP_MStep(...,''GLM'') call must warn exactly once');
        end
    end

    methods (Static, Access = private)
        function n = countMatches(txt)
            % Counts nSTAT:EM:glmPlugIn warnings printed while capturing
            % console output via evalc (warnings print to the command
            % window, which evalc captures, same as the EM/M-step's own
            % progress trace).
            n = numel(regexp(txt, 'MstepMethod=''GLM'' is a plug-in fit', 'match'));
        end
    end
end
