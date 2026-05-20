classdef testNstatDecodingPointProcessEM < matlab.unittest.TestCase
    %TESTNSTATDECODINGPOINTPROCESSEM verify the extracted nstat.decoding.PointProcessEM
    % class shims emit deprecation warnings and preserve numerical behavior on
    % the smallest, easily-fixturable method.
    %
    % The five PP_* methods exercise a point-process EM (Poisson spike
    % observations + linear-Gaussian latent dynamics; the PPLFP family
    % specialized to spike-only). The smallest is PP_EMCreateConstraints,
    % which assembles a struct of constraint flags from up to nine
    % optional inputs. We exercise it with no arguments (all defaults)
    % so the parity check is deterministic and free of fixture noise.
    %
    % The full EM driver (PP_EM, PP_ComputeParamStandardErrors,
    % PP_EStep, PP_MStep) is exercised through helpfiles/example fits;
    % a stable parity fixture for those large methods here would be
    % brittle, so we restrict to PP_EMCreateConstraints.
    %
    % Phase 3 Task 3.2 Step H -- FINAL extraction -- of the 2026-05-19
    % nSTAT review action plan.

    methods (Test)
        function testConstraintsShimEmitsDeprecationWarning(tc)
            %TESTCONSTRAINTSSHIMEMITSDEPRECATIONWARNING
            % Verify DecodingAlgorithms.PP_EMCreateConstraints emits the
            % deprecation warning when called through the shim. With no
            % arguments the body produces a fully-defaulted struct, so
            % the warning fires before any non-trivial logic.
            tc.verifyWarning(@() DecodingAlgorithms.PP_EMCreateConstraints(), ...
                'nSTAT:deprecated:DecodingAlgorithms', ...
                'PP_EMCreateConstraints shim must emit deprecation warning');
        end

        function testConstraintsNumericalParity(tc)
            %TESTCONSTRAINTSNUMERICALPARITY
            % Verify the shim and the new class produce bit-identical
            % output on the no-argument default-constraints call. The
            % returned struct is small and entirely deterministic.

            warnState = warning('off', 'nSTAT:deprecated:DecodingAlgorithms');
            cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>

            C_new  = nstat.decoding.PointProcessEM.PP_EMCreateConstraints();
            C_shim = DecodingAlgorithms.PP_EMCreateConstraints();

            tc.verifyEqual(C_new, C_shim, ...
                'PP_EMCreateConstraints output must match between new class and shim');
        end
    end
end
