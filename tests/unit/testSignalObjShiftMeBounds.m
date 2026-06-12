classdef testSignalObjShiftMeBounds < matlab.unittest.TestCase
    %TESTSIGNALOBJSHIFTMEBOUNDS regression test for issue #14.
    %
    % SignalObj.shiftMe must keep minTime/maxTime in sync with the shifted
    % time vector. Pre-fix: only data/time updated, leaving stale bounds
    % that broke alignTime, findPeaks default minDistance, and any user
    % code reading .minTime/.maxTime after a shift.

    methods (Test)
        function testShiftUpdatesMinAndMaxTime(tc)
            t = (0:0.001:1.0)';
            data = sin(2*pi*5*t);
            sig = SignalObj(t, data, 'unit1');

            originalMin = sig.minTime;
            originalMax = sig.maxTime;

            deltaT = 0.5;
            sig.shiftMe(deltaT);

            tc.verifyEqual(sig.minTime, originalMin + deltaT, 'AbsTol', 1e-12, ...
                'shiftMe must update minTime to reflect the shift');
            tc.verifyEqual(sig.maxTime, originalMax + deltaT, 'AbsTol', 1e-12, ...
                'shiftMe must update maxTime to reflect the shift');
            tc.verifyEqual(min(sig.time), sig.minTime, 'AbsTol', 1e-12, ...
                'minTime must equal min(time) after shift');
            tc.verifyEqual(max(sig.time), sig.maxTime, 'AbsTol', 1e-12, ...
                'maxTime must equal max(time) after shift');
        end

        function testNegativeShift(tc)
            t = (0.5:0.001:1.5)';
            sig = SignalObj(t, t, 'unit1');
            sig.shiftMe(-0.5);
            tc.verifyEqual(sig.minTime, 0.0, 'AbsTol', 1e-12);
            tc.verifyEqual(sig.maxTime, 1.0, 'AbsTol', 1e-12);
        end
    end
end
