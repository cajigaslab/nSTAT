classdef testMPPCODeprecationShims < matlab.unittest.TestCase
    %TESTMPPCODEPRECATIONSHIMS verify mPPCO_* shims forward correctly
    % and emit the nSTAT:deprecated:mPPCO warning.
    %
    % Phase 3 Task 3.1 of the 2026-05-19 nSTAT review action plan: the
    % mPPCO_* family was renamed to PPLFP_* to align with bci-curriculum
    % §4.B.7 PPLFP terminology. Deprecation shims forward calls to the
    % new names with a deprecation warning.

    methods (Test)
        function testDecodePredictShimWarns(tc)
            % mPPCODecode_predict is the smallest of the renamed methods;
            % constructs trivial state, predicts one step, verifies the
            % shim emits the deprecation warning and returns identical
            % output to the new name.
            x_u = [0; 0]; W_u = eye(2);
            A = 0.9*eye(2); Q = 0.01*eye(2);

            tc.verifyWarning( ...
                @() DecodingAlgorithms.mPPCODecode_predict(x_u, W_u, A, Q), ...
                'nSTAT:deprecated:mPPCO', ...
                'mPPCO* shim must emit nSTAT:deprecated:mPPCO warning');
        end

        function testDecodePredictShimForwards(tc)
            % Verify the shim forwards identically to PPLFP_Decode_predict.
            x_u = [0.5; -0.2]; W_u = [1 0.1; 0.1 0.5];
            A = [0.9 0; 0 0.8]; Q = [0.01 0; 0 0.02];

            % Suppress the deprecation warning for this comparison
            warnState = warning('off', 'nSTAT:deprecated:mPPCO');
            cleanup = onCleanup(@() warning(warnState));

            [x_p_shim, W_p_shim] = DecodingAlgorithms.mPPCODecode_predict(x_u, W_u, A, Q);
            [x_p_new,  W_p_new]  = DecodingAlgorithms.PPLFP_Decode_predict(x_u, W_u, A, Q);

            tc.verifyEqual(x_p_shim, x_p_new, 'AbsTol', 1e-12, ...
                'shim must return identical x_p to PPLFP_Decode_predict');
            tc.verifyEqual(W_p_shim, W_p_new, 'AbsTol', 1e-12, ...
                'shim must return identical W_p to PPLFP_Decode_predict');
        end
    end
end
