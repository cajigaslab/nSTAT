classdef testNstatDecodingUKF < matlab.unittest.TestCase
    %TESTNSTATDECODINGUKF verify the extracted nstat.decoding.UKF class
    % produces identical output to the legacy DecodingAlgorithms.ukf
    % shim path (numerical parity).
    %
    % Phase 3 Task 3.2 Step A of the 2026-05-19 nSTAT review action plan.

    methods (Test)
        function testUKFNumericalParity(tc)
            % Toy 2D nonlinear system with Gaussian noise.
            rng(0, 'twister');
            fstate = @(x) [0.9*x(1); 0.95*x(2) + 0.05*x(1)^2];  % state dyn
            hmeas  = @(x) x(1) + x(2);                            % obs
            x0 = [0.5; -0.3];
            P0 = 0.1*eye(2);
            Q  = 0.01*eye(2);
            R  = 0.05;
            z  = 0.42;

            % Suppress deprecation warning during shim parity check
            warnState = warning('off', 'nSTAT:deprecated:DecodingAlgorithms');
            cleanup = onCleanup(@() warning(warnState));

            % Same RNG state for both
            rng(0, 'twister');
            [x_new, P_new] = nstat.decoding.UKF.ukf(fstate, x0, P0, hmeas, z, Q, R);
            rng(0, 'twister');
            [x_shim, P_shim] = DecodingAlgorithms.ukf(fstate, x0, P0, hmeas, z, Q, R);

            tc.verifyEqual(x_new, x_shim, 'AbsTol', 1e-12, ...
                'nstat.decoding.UKF.ukf must match DecodingAlgorithms.ukf shim numerically');
            tc.verifyEqual(P_new, P_shim, 'AbsTol', 1e-12, ...
                'covariance must match');
        end

        function testShimEmitsDeprecationWarning(tc)
            x0 = [0; 0]; P0 = eye(2);
            tc.verifyWarning( ...
                @() DecodingAlgorithms.ukf(@(x)x, x0, P0, @(x)x(1), 0.1, eye(2), 1), ...
                'nSTAT:deprecated:DecodingAlgorithms', ...
                'shim must emit deprecation warning');
        end
    end
end
