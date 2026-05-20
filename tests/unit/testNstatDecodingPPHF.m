classdef testNstatDecodingPPHF < matlab.unittest.TestCase
    %TESTNSTATDECODINGPPHF verify the extracted nstat.decoding.PPHF class
    % shims emit deprecation warnings.
    %
    % No numerical parity test is included for PPHF: the methods take
    % 17-18 required positional arguments, making a stable parity fixture
    % fragile and slow. The intra-cluster rewires only call
    % nstat.decoding.PPAF.PPDecode_{predict,update,updateLinear}, all of
    % which already have numerical parity tests in testNstatDecodingPPAF.
    % A shim-warning test plus existing PPAF parity is sufficient coverage
    % for the extraction's behavioral guarantee.
    %
    % Phase 3 Task 3.2 Step D of the 2026-05-19 nSTAT review action plan.

    methods (Test)
        function testPPHybridFilterShimEmitsDeprecationWarning(tc)
            %TESTPPHYBRIDFILTERSHIMEMITSDEPRECATIONWARNING
            % Verify DecodingAlgorithms.PPHybridFilter emits its deprecation
            % warning before any deeper logic runs. We don't care if the
            % deeper logic errors out due to empty inputs - verifyWarning
            % only checks whether the specified warning was issued.
            tc.verifyWarning(@() callPPHybridFilterMinimal(), ...
                'nSTAT:deprecated:DecodingAlgorithms', ...
                'shim must emit deprecation warning before any deeper logic');
        end

        function testPPHybridFilterLinearShimEmitsDeprecationWarning(tc)
            %TESTPPHYBRIDFILTERLINEARSHIMEMITSDEPRECATIONWARNING
            % Same check for the Linear variant.
            tc.verifyWarning(@() callPPHybridFilterLinearMinimal(), ...
                'nSTAT:deprecated:DecodingAlgorithms', ...
                'Linear shim must emit deprecation warning before any deeper logic');
        end
    end
end

function callPPHybridFilterMinimal()
    % Build the smallest valid-shape input set; we only care that the
    % warning fires before any computation. Wrap in try/catch so post-
    % warning errors don't mask the warning emission.
    try
        DecodingAlgorithms.PPHybridFilter([], [], [], [], [], [], [], [], [], [], [], [], []);
    catch
        % Ignore - we only need the warning to have been emitted
    end
end

function callPPHybridFilterLinearMinimal()
    try
        DecodingAlgorithms.PPHybridFilterLinear([], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []);
    catch
        % Ignore - we only need the warning to have been emitted
    end
end
