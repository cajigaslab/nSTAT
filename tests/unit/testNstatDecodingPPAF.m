classdef testNstatDecodingPPAF < matlab.unittest.TestCase
    %TESTNSTATDECODINGPPAF verify the extracted nstat.decoding.PPAF class
    % produces identical output to the legacy DecodingAlgorithms.PPDecode_*
    % shim path (numerical parity), and that shims emit deprecation warnings.
    %
    % Phase 3 Task 3.2 Step C of the 2026-05-19 nSTAT review action plan.

    methods (Test)
        function testPPDecodePredictNumericalParity(tc)
            %TESTPPDECODEPREDICTNUMERICALPARITY new class vs shim parity.
            % PPDecode_predict is the smallest method in the cluster and has
            % a simple signature: (x_u, W_u, A, Q, Wconv). Confirms the
            % rewired calling convention preserves bit-exact output.
            rng(0, 'twister');
            x_u = [0.3; -0.2];
            W_u = [0.05 0.01; 0.01 0.04];
            A   = [0.95 0.05; -0.05 0.95];
            Q   = 0.01*eye(2);

            % Suppress deprecation warning during shim parity check
            warnState = warning('off', 'nSTAT:deprecated:DecodingAlgorithms');
            cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>

            % Direct call to new class
            [x_p_new, W_p_new] = nstat.decoding.PPAF.PPDecode_predict(x_u, W_u, A, Q);

            % Via the deprecation shim
            [x_p_shim, W_p_shim] = DecodingAlgorithms.PPDecode_predict(x_u, W_u, A, Q);

            tc.verifyEqual(x_p_new, x_p_shim, 'AbsTol', 1e-12, ...
                'PPDecode_predict x_p must match shim numerically');
            tc.verifyEqual(W_p_new, W_p_shim, 'AbsTol', 1e-12, ...
                'PPDecode_predict W_p must match shim numerically');
        end

        function testPPDecodeFilterLinearNumericalParity(tc)
            %TESTPPDECODEFILTERLINEARNUMERICALPARITY end-to-end parity.
            % Single-neuron 1-D random-walk state, Poisson CIF with linear
            % link. Confirms PPDecodeFilterLinear (which internally calls
            % the rewired PPDecode_predict and PPDecode_updateLinear) is
            % bit-equivalent to the shim path.
            rng(42, 'twister');
            A     = 0.95;
            Q     = 0.01;
            mu    = log(0.005);    % baseline log-rate
            beta  = 0.5;           % state coefficient
            delta = 0.001;
            % Generate a short synthetic spike train (8 bins). At baseline
            % rate ~5 Hz with delta=1ms, expect ~0-1 spikes per 8 bins.
            dN = double(rand(1, 30) < 0.02);

            warnState = warning('off', 'nSTAT:deprecated:DecodingAlgorithms');
            cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>

            [x_p_new, W_p_new, x_u_new, W_u_new] = nstat.decoding.PPAF.PPDecodeFilterLinear( ...
                A, Q, dN, mu, beta, 'poisson', delta);

            [x_p_shim, W_p_shim, x_u_shim, W_u_shim] = DecodingAlgorithms.PPDecodeFilterLinear( ...
                A, Q, dN, mu, beta, 'poisson', delta);

            tc.verifyEqual(x_p_new, x_p_shim, 'AbsTol', 1e-10, ...
                'PPDecodeFilterLinear x_p must match shim');
            tc.verifyEqual(W_p_new, W_p_shim, 'AbsTol', 1e-10, ...
                'PPDecodeFilterLinear W_p must match shim');
            tc.verifyEqual(x_u_new, x_u_shim, 'AbsTol', 1e-10, ...
                'PPDecodeFilterLinear x_u must match shim');
            tc.verifyEqual(W_u_new, W_u_shim, 'AbsTol', 1e-10, ...
                'PPDecodeFilterLinear W_u must match shim');
        end

        function testShimEmitsDeprecationWarning(tc)
            %TESTSHIMEMITSDEPRECATIONWARNING ensure shim raises the warning.
            % Uses PPDecode_predict as the smallest method to construct
            % minimal valid inputs.
            x_u = [0; 0];
            W_u = eye(2);
            A   = eye(2);
            Q   = 0.01*eye(2);

            tc.verifyWarning( ...
                @() DecodingAlgorithms.PPDecode_predict(x_u, W_u, A, Q), ...
                'nSTAT:deprecated:DecodingAlgorithms', ...
                'PPDecode_predict shim must emit deprecation warning');
        end
    end
end
