classdef testParityAuditJun19Fixes < matlab.unittest.TestCase
    %TESTPARITYAUDITJUN19FIXES regression tests for the parity-audit bugs
    % filed 2026-06-19 (issues #91, #92, #93) plus an EStep-level
    % integration test added 2026-06-19 in response to #95.
    %
    % #90 (PPLFP HkAll axis) is intentionally NOT covered by a unit test
    % targeting PPLFP_Decode_update directly: the function expects its
    % HkAll argument pre-permuted by PPLFP_EStep (time on dim 3); calling
    % it with raw HkAll tests a calling convention nothing in the codebase
    % actually uses. Instead, testPPLFP_EStep_endToEnd_nonSquareDN below
    % exercises the EStep -> Decode_update handshake the way production
    % code does. That is the test that would have caught PR #94's #95
    % regression.

    methods (Test)

        function testPPLFP_EStep_endToEnd_nonSquareDN(tc)
            %#95 PPLFP_EStep -> PPLFP_Decode_update axis handshake.
            % EStep pre-permutes HkAll so time is on dim 3 before passing
            % to Decode_update; an axis "fix" at the consumer broke this
            % handshake in PR #94. Reproduce the exact failing input from
            % the issue (numCells=2, K=30, non-square) and assert the
            % poisson chain completes without dimension-mismatch errors.
            %
            % HkAll is shaped the way PPLFP_EM builds it when windowTimes
            % is empty: zeros(1,1,numCells), 3D so the downstream
            % permute() and slice() flow.
            %
            % The binomial branch is NOT exercised here -- it has an
            % unrelated self-clobbering typo at PPLFP.m:2147
            % (`HkPerm = HkPerm(:,:,k)` instead of `Hk = HkPerm(:,:,k)`)
            % that predates PR #94. Filed separately.
            rng(0, 'twister');
            numCells = 2;
            K        = 30;
            delta    = 0.01;
            stateDim = 2;

            A   = eye(stateDim);
            Q   = 1e-3*eye(stateDim);
            C   = eye(stateDim);
            R   = 1e-2*eye(stateDim);
            x0  = zeros(stateDim,1);
            Px0 = eye(stateDim);
            y      = zeros(stateDim, K);
            alpha  = zeros(stateDim, 1);
            mu     = zeros(numCells, 1);
            beta   = zeros(stateDim, numCells);
            gamma  = 0;
            HkAll  = zeros(K, 1, numCells);   % matches EM's with-windowTimes shape
            dN     = double(rand(numCells, K) < 0.1);

            tc.verifyWarningFree( @() ...
                nstat.decoding.PPLFP.PPLFP_EStep(A, Q, C, R, y, alpha, ...
                    dN, mu, beta, 'poisson', delta, gamma, HkAll, x0, Px0), ...
                'PPLFP_EStep poisson path must complete on non-square dN (#95)');

            % Binomial branch was previously broken by an unrelated
            % self-clobbering typo at PPLFP.m:2149
            % (`HkPerm = HkPerm(:,:,k)` instead of `Hk = HkPerm(:,:,k)`).
            % Fixed alongside the #95 revert -- now both branches must
            % run end-to-end on the same input.
            tc.verifyWarningFree( @() ...
                nstat.decoding.PPLFP.PPLFP_EStep(A, Q, C, R, y, alpha, ...
                    dN, mu, beta, 'binomial', delta, gamma, HkAll, x0, Px0), ...
                'PPLFP_EStep binomial path must complete on non-square dN (typo at PPLFP.m:2149)');
        end

        function testPPHybridFilterSignatureNamesMU_u(tc)
            %#91 PPHybridFilter declared MU_s but body only assigns MU_u.
            % Verify the signature now uses MU_u (matches PPHybridFilterLinear).
            mFile = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
                '+nstat','+decoding','PPHF.m');
            txt = fileread(mFile);
            tc.verifyTrue( ...
                ~isempty(regexp(txt, ...
                'function\s*\[S_est,\s*X,\s*W,\s*MU_u,\s*X_s,\s*W_s,\s*pNGivenS\]\s*=\s*PPHybridFilter\(', ...
                'once')), ...
                'PPHybridFilter signature must declare MU_u (not MU_s) as the 4th output (#91)');
        end

        function testCIFRejectsNonIdentifierXname(tc)
            %#92 CIF constructor with Xnames={'1','x1'} previously failed
            % downstream with an opaque sym() error. Should now raise a
            % clear error at construction.
            beta = [1.0, 0.5];
            tc.verifyError( @() CIF(beta, {'1','x1'}, {'x'}, 'binomial'), ...
                'CIF:InvalidXname', ...
                'CIF must reject non-identifier Xnames entries with a clear error');
        end

        function testCIFAcceptsValidIdentifierXnames(tc)
            %#92 Sanity: the recommended workaround ('one') still constructs.
            beta = [1.0, 0.5];
            tc.verifyWarningFree( @() CIF(beta, {'one','x1'}, {'x'}, 'binomial'), ...
                'CIF must accept Xnames={''one'',''x1''} per the documented workaround');
        end

        function testSignalObjAutocorrelationRunsOnRecentMATLAB(tc)
            %#93 SignalObj.autocorrelation used legacy positional crosscorr
            % syntax that newer Econometrics Toolbox releases reject.
            % Run end-to-end on a tiny synthetic signal.
            time = (0:0.001:0.5)';
            data = sin(2*pi*5*time) + 0.1*randn(size(time));
            sig = SignalObj(time, data, 'sig', 'time', 's', '', {'x'});
            tc.verifyWarningFree( @() sig.autocorrelation(), ...
                'SignalObj.autocorrelation must accept newer crosscorr API (#93)');
        end

    end
end
