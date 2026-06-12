classdef testSignalObjResampleWindowMutated < matlab.unittest.TestCase
    %TESTSIGNALOBJRESAMPLEWINDOWMUTATED regression test for issue #54.
    %
    % SignalObj.resample(rate) short-circuits when newSampleRate equals
    % sObj.sampleRate. Pre-fix: even if setMinTime/setMaxTime had mutated
    % the window without changing sampleRate, resample still skipped, so
    % the time vector was inconsistent with (maxTime-minTime)*sampleRate+1.
    % Downstream makeCompatible would surface this as length-mismatch
    % failures that looked like data corruption.
    %
    % Post-fix: the same-rate branch also length-checks against the
    % expected grid and forces a resampleMe when stale.

    methods (Test)
        function testSameRateAfterWindowMutationTriggersRegrid(tc)
            t = (0:0.001:1.0)';
            data = sin(2*pi*3*t);
            sig = SignalObj(t, data, 'unit1');
            originalRate = sig.sampleRate;
            tc.assumeNotEmpty(originalRate);
            tc.assumeTrue(isfinite(originalRate));

            % Mutate the window without changing sampleRate.
            sig.setMinTime(0.2);
            sig.setMaxTime(0.8);

            % Same-rate resample should still produce a time vector that
            % matches the expected sample count for the mutated window.
            out = sig.resample(originalRate);
            expectedLen = round((out.maxTime - out.minTime) * originalRate) + 1;
            tc.verifyEqual(length(out.time), expectedLen, ...
                'resample at same rate must regrid when window has been mutated');
            tc.verifyEqual(min(out.time), out.minTime, 'AbsTol', 1e-9);
            tc.verifyEqual(max(out.time), out.maxTime, 'AbsTol', 1e-9);
        end

        function testSameRateNoMutationNoOp(tc)
            % Sanity: same rate, no window mutation -> behavior unchanged.
            t = (0:0.001:0.5)';
            sig = SignalObj(t, t, 'unit1');
            originalLen = length(sig.time);
            out = sig.resample(sig.sampleRate);
            tc.verifyEqual(length(out.time), originalLen, ...
                'unmutated same-rate resample must not change the time vector length');
        end
    end
end
