classdef testKFEMMonteCarloDraws < matlab.unittest.TestCase
    %TESTKFEMMONTECARLODRAWS (KF track M, item C1 / F9) KF_EM.m's xKDraw
    % and x0Draw sites in KF_ComputeParamStandardErrors built every Monte
    % Carlo draw inline as m + chol(W)*z. MATLAB's chol returns the UPPER
    % factor R (R'*R = W), so R*z has covariance R*R' ~= W for any
    % non-diagonal W. Both sites now call
    % nstat.decoding.PointProcessEM.mcStateDraws (x = m + chol(W)'*z,
    % same z stream; bit-identical for diagonal W) -- the identical fix
    % PointProcessEM/PPLFP got for F9 (tests/unit/testEMMonteCarloDraws.m),
    % reused rather than duplicated (PointProcessEM.mcStateDraws's Access
    % attribute is extended to nstat.decoding.KF_EM).

    methods (Test)
        function testNoInlineDrawsLeftInKFEM(tc)
            src = fileread(which('nstat.decoding.KF_EM'));
            lines = regexp(src, '\r?\n', 'split');
            code = strjoin(regexprep(lines, '%.*$', ''), newline);
            tc.verifyEmpty(regexp(code, 'chol_m', 'once'), ...
                'KF_EM.m still builds a Monte Carlo draw inline with chol_m');
            tc.verifyEmpty(regexp(code, 'normrnd\(', 'once'), ...
                'KF_EM.m should delegate every draw to PointProcessEM.mcStateDraws');
            tc.verifyNotEmpty(regexp(code, 'PointProcessEM\.mcStateDraws', 'once'), ...
                'KF_EM.m must call PointProcessEM.mcStateDraws');
        end

        function testKFEMIsGrantedAccessToTheSharedHelper(tc)
            % Direct evidence that nstat.decoding.KF_EM can reach the
            % Access-restricted helper (Access =
            % {?nstat.decoding.PointProcessEM, ?nstat.decoding.KF_EM,
            % ?matlab.unittest.TestCase}): calling it here, as this test
            % class, also exercises the same grant KF_EM.m itself uses.
            rng(3);
            m = [1; -2];
            D = [1.0 0.8; 0.8 2.0];
            X = nstat.decoding.PointProcessEM.mcStateDraws(m, D, 500);
            tc.verifySize(X, [2 500]);
            tc.verifyTrue(all(isfinite(X(:))));
        end
    end
end
