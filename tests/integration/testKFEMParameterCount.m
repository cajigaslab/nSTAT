classdef testKFEMParameterCount < matlab.unittest.TestCase
    %TESTKFEMPARAMETERCOUNT (KF track M, item C5; new, same class as
    % PPLFP's F11 "R's parameter count" bug) KF_RunEM's IC parameter
    % count for R had:
    %   if(RhatDiag==1 && RhatIsotropic==1) n4=1;
    %   elseif(QhatDiag==1 && QhatIsotropic==0) n4=size(Rhat,1);  <- BUG
    %   else n4=numel(Rhat);
    % the middle branch tested Q's flags instead of R's. With the
    % default RhatDiag=1,RhatIsotropic=0 and the default QhatDiag=1,
    % QhatIsotropic=0 this happened to give the right answer (both
    % conditions true), masking the bug; it surfaces whenever
    % QhatDiag/QhatIsotropic differ from RhatDiag=1,RhatIsotropic=0 (for
    % example QhatDiag=0, full Q, with the default diagonal R).

    methods (Test)
        function testInformationCriteriaCountUsesRFlags(tc)
            % The count is recovered from IC as nTerms = (AIC + 2*llobs)/2.
            P = testKFEMParameterCount.scalarProblem2D();
            dx = 2; dy = 2;
            base.A = dx^2; base.alpha = dy; base.C = dy*dx; base.x0 = 0; base.Px0 = 0;
            %         QhatDiag QhatIso RhatDiag RhatIso  expected R count
            cases = {1, 0, 1, 0, dy;
                     0, 0, 1, 0, dy;
                     1, 1, 1, 0, dy;
                     1, 0, 0, 0, dy^2};
            for i = 1:size(cases,1)
                cons = nstat.decoding.KF_EM.KF_EMCreateConstraints(1,0,cases{i,1},cases{i,2},cases{i,3},cases{i,4},0,0);
                cons.mcIter = 30;
                if cases{i,1}==1
                    if cases{i,2}==1, nQ = 1; else, nQ = dx; end
                else
                    nQ = dx^2;
                end
                expected = base.A + nQ + base.C + cases{i,5} + base.alpha;
                r = cell(1,10);
                rng(42);
                evalc(['[r{1:10}] = nstat.decoding.KF_EM.KF_RunEM(P.y,P.A,P.Q,P.C,P.R,P.alpha,P.x0,P.Px0,cons);']);
                IC = r{10};
                nTerms = (IC.AIC + 2*IC.llobs)/2;
                tc.verifyEqual(nTerms, expected, 'AbsTol', 1e-6, sprintf(...
                    'nTerms with QhatDiag=%d QhatIso=%d RhatDiag=%d RhatIso=%d', cases{i,1:4}));
            end
        end
    end

    methods (Static, Access = private)
        function P = scalarProblem2D()
            % dx = dy = 2, diagonal Q0/R0, chosen well inside the stable
            % / well-conditioned region (same rationale as
            % testKFEMWhitening's nonDiagonalProblem).
            rng(9); P.A = 0.9*eye(2); P.Q = [0.02 0.01; 0.01 0.03];
            P.C = eye(2); P.R = [0.1 0.03; 0.03 0.15]; P.alpha = [0; 0];
            N = 150; P.x0 = zeros(2,1); P.Px0 = eye(2);
            x = zeros(2,N); xp = zeros(2,1);
            for k = 1:N, xp = P.A*xp + chol(P.Q,'lower')*randn(2,1); x(:,k) = xp; end
            P.y = P.C*x + P.alpha + chol(P.R,'lower')*randn(2,N);
        end
    end
end
