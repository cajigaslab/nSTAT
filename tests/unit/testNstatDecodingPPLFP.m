classdef testNstatDecodingPPLFP < matlab.unittest.TestCase
    %TESTNSTATDECODINGPPLFP verify the extracted nstat.decoding.PPLFP class
    % shims emit deprecation warnings and preserve numerical behavior on
    % the smallest, easily-fixturable method.
    %
    % Smallest method is PPLFP_Decode_predict (8 LOC of body):
    %   x_p = A * x_u;  W_p = A * W_u * A' + Q;  W_p = (W_p + W_p')/2;
    %
    % That's a deterministic linear-Gaussian time update with no side
    % effects and no calls into other DecodingAlgorithms members - the
    % ideal parity fixture. Larger methods (EM, EStep, MStep, etc.) have
    % 15-20 required positional arguments and are exercised end-to-end
    % through helpfiles/example05 - a stable fixture here would be costly
    % and brittle.
    %
    % Phase 3 Task 3.2 Step E of the 2026-05-19 nSTAT review action plan.

    methods (Test)
        function testPredictShimEmitsDeprecationWarning(tc)
            %TESTPREDICTSHIMEMITSDEPRECATIONWARNING
            % Verify DecodingAlgorithms.PPLFP_Decode_predict emits its
            % deprecation warning before any deeper logic runs.
            x_u = [0; 0]; W_u = eye(2);
            A = 0.9*eye(2); Q = 0.01*eye(2);
            tc.verifyWarning( ...
                @() DecodingAlgorithms.PPLFP_Decode_predict(x_u, W_u, A, Q), ...
                'nSTAT:deprecated:DecodingAlgorithms', ...
                'PPLFP_Decode_predict shim must emit deprecation warning');
        end

        function testPredictNumericalParity(tc)
            %TESTPREDICTNUMERICALPARITY
            % Verify the shim and the new class produce bit-identical
            % output (linear-Gaussian time update is deterministic).
            x_u = [0.5; -0.2];
            W_u = [1 0.1; 0.1 0.5];
            A = [0.9 0; 0 0.8];
            Q = [0.01 0; 0 0.02];

            warnState = warning('off', 'nSTAT:deprecated:DecodingAlgorithms');
            cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>

            [x_p_new, W_p_new]   = nstat.decoding.PPLFP.PPLFP_Decode_predict(x_u, W_u, A, Q);
            [x_p_shim, W_p_shim] = DecodingAlgorithms.PPLFP_Decode_predict(x_u, W_u, A, Q);

            tc.verifyEqual(x_p_new, x_p_shim, 'AbsTol', 1e-12, ...
                'shim and new class must produce identical x_p');
            tc.verifyEqual(W_p_new, W_p_shim, 'AbsTol', 1e-12, ...
                'shim and new class must produce identical W_p');

            % Also check the mathematics is correct: x_p = A*x_u, and W_p
            % is the symmetrized A*W_u*A' + Q.
            W_p_expected = A*W_u*A' + Q;
            W_p_expected = (W_p_expected + W_p_expected')/2;
            tc.verifyEqual(x_p_new, A*x_u, 'AbsTol', 1e-12);
            tc.verifyEqual(W_p_new, W_p_expected, 'AbsTol', 1e-12);
        end
    end
end
