classdef testNstatDecodingKalmanFilter < matlab.unittest.TestCase
    %TESTNSTATDECODINGKALMANFILTER verify the extracted nstat.decoding.KalmanFilter
    % class produces identical output to the legacy DecodingAlgorithms.kalman_*
    % shim path (numerical parity).
    %
    % Phase 3 Task 3.2 Step B of the 2026-05-19 nSTAT review action plan.

    methods (Test)
        function testKalmanFilterNumericalParity(tc)
            % 2D LTI system: damped oscillator with full-state observation.
            rng(0, 'twister');
            A   = [0.95 0.05; -0.05 0.95];   % rotation-like dynamics
            C   = eye(2);                    % full-state observation
            Pv  = 0.01*eye(2);               % process noise covariance
            Pw  = 0.05*eye(2);               % measurement noise covariance
            Px0 = 0.1*eye(2);                % initial state covariance
            x0  = [0.5; -0.3];               % initial state

            % Generate 20-sample observation sequence
            N = 20;
            y = zeros(2, N);
            xtrue = x0;
            for n = 1:N
                xtrue = A*xtrue + sqrtm(Pv)*randn(2,1);
                y(:,n) = C*xtrue + sqrtm(Pw)*randn(2,1);
            end

            % Suppress deprecation warning during shim parity check
            warnState = warning('off', 'nSTAT:deprecated:DecodingAlgorithms');
            cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>

            % Call the new class directly
            [x_p_new, Pe_p_new, x_u_new, Pe_u_new] = ...
                nstat.decoding.KalmanFilter.kalman_filter(A, C, Pv, Pw, Px0, x0, y);

            % Call via the deprecation shim
            [x_p_shim, Pe_p_shim, x_u_shim, Pe_u_shim] = ...
                DecodingAlgorithms.kalman_filter(A, C, Pv, Pw, Px0, x0, y);

            tc.verifyEqual(x_p_new, x_p_shim, 'AbsTol', 1e-12, ...
                'kalman_filter x_p must match shim numerically');
            tc.verifyEqual(Pe_p_new, Pe_p_shim, 'AbsTol', 1e-12, ...
                'kalman_filter Pe_p must match shim numerically');
            tc.verifyEqual(x_u_new, x_u_shim, 'AbsTol', 1e-12, ...
                'kalman_filter x_u must match shim numerically');
            tc.verifyEqual(Pe_u_new, Pe_u_shim, 'AbsTol', 1e-12, ...
                'kalman_filter Pe_u must match shim numerically');
        end

        function testShimEmitsDeprecationWarning(tc)
            % Minimal viable inputs for kalman_filter
            A   = eye(2);
            C   = eye(2);
            Pv  = 0.01*eye(2);
            Pw  = 0.05*eye(2);
            Px0 = 0.1*eye(2);
            x0  = [0; 0];
            y   = zeros(2, 3);

            tc.verifyWarning( ...
                @() DecodingAlgorithms.kalman_filter(A, C, Pv, Pw, Px0, x0, y), ...
                'nSTAT:deprecated:DecodingAlgorithms', ...
                'kalman_filter shim must emit deprecation warning');
        end
    end
end
