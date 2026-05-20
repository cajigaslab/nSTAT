classdef testNstatDecodingKF_EM < matlab.unittest.TestCase
    %TESTNSTATDECODINGKF_EM verify the extracted nstat.decoding.KF_EM class
    % shims emit deprecation warnings and preserve numerical behavior on
    % the smallest, easily-fixturable method.
    %
    % The five KF_* methods exercise a linear-Gaussian state-space EM
    % (Shumway-Stoffer 1982). The smallest is KF_EMCreateConstraints,
    % which assembles a struct of constraint flags from up to eleven
    % optional inputs. We exercise it with no arguments (all defaults)
    % so the parity check is deterministic and free of fixture noise.
    %
    % The full EM driver (KF_EM, KF_ComputeParamStandardErrors,
    % KF_EStep, KF_MStep) is exercised through helpfiles/example fits;
    % a stable parity fixture for those large methods here would be
    % brittle, so we restrict to KF_EMCreateConstraints.
    %
    % Phase 3 Task 3.2 Step G of the 2026-05-19 nSTAT review action plan.

    methods (Test)
        function testConstraintsShimEmitsDeprecationWarning(tc)
            %TESTCONSTRAINTSSHIMEMITSDEPRECATIONWARNING
            % Verify DecodingAlgorithms.KF_EMCreateConstraints emits the
            % deprecation warning when called through the shim. With no
            % arguments the body produces a fully-defaulted struct, so
            % the warning fires before any non-trivial logic.
            tc.verifyWarning(@() DecodingAlgorithms.KF_EMCreateConstraints(), ...
                'nSTAT:deprecated:DecodingAlgorithms', ...
                'KF_EMCreateConstraints shim must emit deprecation warning');
        end

        function testConstraintsNumericalParity(tc)
            %TESTCONSTRAINTSNUMERICALPARITY
            % Verify the shim and the new class produce bit-identical
            % output on the no-argument default-constraints call. The
            % returned struct is small and entirely deterministic.

            warnState = warning('off', 'nSTAT:deprecated:DecodingAlgorithms');
            cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>

            C_new  = nstat.decoding.KF_EM.KF_EMCreateConstraints();
            C_shim = DecodingAlgorithms.KF_EMCreateConstraints();

            tc.verifyEqual(C_new, C_shim, ...
                'KF_EMCreateConstraints output must match between new class and shim');
        end
    end
end
