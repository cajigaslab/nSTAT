classdef testParityAuditJun19Fixes < matlab.unittest.TestCase
    %TESTPARITYAUDITJUN19FIXES regression tests for the four parity-audit
    % bug reports filed 2026-06-19 (issues #90, #91, #92, #93).
    %
    % Each test asserts the failing-input case the issue described now
    % succeeds (or fails with a clear error, for #92).

    methods (Test)

        function testPPLFP_Decode_update_acceptsNonSquareDN(tc)
            %#90 PPLFP_Decode_update: HkAll(:,:,time_index) used to throw
            % when numCells != K_time. Build a minimal valid HkAll with
            % numCells=2, K_time=5 and exercise the update step.
            numCells = 2;
            K_time   = 5;
            hist_cols = 1;
            HkAll = zeros(K_time, hist_cols, numCells);   % builder convention
            % single spike per cell -- arbitrary values, the test is about
            % whether sizes flow without index-out-of-bounds errors.
            HkAll(3,1,1) = 1;
            HkAll(2,1,2) = 1; HkAll(5,1,2) = 1;
            dN  = [0 0 1 0 0; 0 1 0 0 1];   % (numCells x K_time)
            stateDim = 1;
            x_p = zeros(stateDim,1);
            W_p = eye(stateDim);
            C   = zeros(0,stateDim);
            R   = zeros(0,0);
            y   = zeros(0,K_time);
            alpha = zeros(0,1);
            mu    = zeros(numCells,1);
            beta  = zeros(stateDim,numCells);
            gamma = zeros(hist_cols,numCells);

            % Run for the time index that previously exceeded the third axis.
            time_index = 5;
            tc.verifyWarningFree( @() ...
                nstat.decoding.PPLFP.PPLFP_Decode_update(x_p, W_p, C, R, ...
                    y, alpha, dN, mu, beta, 'binomial', gamma, HkAll, ...
                    time_index, []), ...
                'PPLFP_Decode_update should accept non-square dN after #90 fix');

            tc.verifyWarningFree( @() ...
                nstat.decoding.PPLFP.PPLFP_Decode_update(x_p, W_p, C, R, ...
                    y, alpha, dN, mu, beta, 'poisson', gamma, HkAll, ...
                    time_index, []), ...
                'PPLFP_Decode_update poisson branch should also accept non-square dN');
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
