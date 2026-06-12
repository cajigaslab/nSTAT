classdef testTrialConfigRoundTrip < matlab.unittest.TestCase
    %TESTTRIALCONFIGROUNDTRIP regression test for issues #19 and #58.
    %
    % TrialConfig.fromStructure previously omitted ensCovMask AND had a
    % positional argument shift in the constructor call:
    %   - covLag landed in ensCovMask slot
    %   - name landed in covLag slot
    % Round-tripping a TrialConfig through toStructure -> fromStructure
    % silently corrupted these fields. Post-fix the round-trip preserves
    % every field.

    methods (Test)
        function testRoundTripPreservesAllFields(tc)
            covMask = {{'Position','x'}, {'Velocity','v_x'}};
            sampleRate = 1000;
            history = History([0 0.005 0.025]); % 2-window history basis
            ensCovHist = History([0 0.001]);
            ensCovMask = logical(eye(2));        % non-default ensCovMask
            covLag = 0.010;                       % non-default covLag
            name = 'roundtrip_probe';

            tcOriginal = TrialConfig(covMask, sampleRate, history, ...
                                     ensCovHist, ensCovMask, covLag, name);

            s = tcOriginal.toStructure();
            tcRoundTrip = TrialConfig.fromStructure(s);

            tc.verifyEqual(tcRoundTrip.sampleRate, sampleRate, ...
                'sampleRate must round-trip');
            tc.verifyEqual(tcRoundTrip.covLag, covLag, 'AbsTol', 1e-12, ...
                'covLag must round-trip (#58 regression: was getting name)');
            tc.verifyEqual(tcRoundTrip.name, name, ...
                'name must round-trip (#58 regression: was sliding into covLag)');
            tc.verifyEqual(tcRoundTrip.ensCovMask, ensCovMask, ...
                'ensCovMask must round-trip (#19 regression: was omitted)');
        end
    end
end
