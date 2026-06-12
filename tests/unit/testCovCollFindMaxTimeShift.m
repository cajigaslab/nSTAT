classdef testCovCollFindMaxTimeShift < matlab.unittest.TestCase
    %TESTCOVCOLLFINDMAXTIMESHIFT regression test for issue #18.
    %
    % CovColl.findMaxTime applied ccObj.covShift twice — once inside the
    % per-covariate loop and again to the return value — yielding an
    % inflated maxTime by exactly +covShift. Pattern was asymmetric with
    % findMinTime which only applies the shift once. Fix removes the
    % in-loop application; outside-loop application is the single
    % canonical site.

    methods (Test)
        function testCovShiftAppliedOnce(tc)
            t = (0:0.01:1.0)';
            c1 = Covariate(t,            t,             'Cov1', 'time', 's', '', {'a'});
            c2 = Covariate(t + 0.5, sin(2*pi*(t+0.5)), 'Cov2', 'time', 's', '', {'b'});
            cc = CovColl({c1, c2});

            % Capture raw covariate maxTimes BEFORE setCovShift mutates
            % ccObj's cached min/maxTime (setCovShift adjusts them by
            % +deltaT, but findMaxTime computes from the underlying
            % covArray, not the cached values).
            rawMaxC1 = c1.maxTime;
            rawMaxC2 = c2.maxTime;

            shift = 0.25;
            cc.setCovShift(shift);
            expected = max([rawMaxC1, rawMaxC2]) + shift;

            actual = cc.findMaxTime;
            tc.verifyEqual(actual, expected, 'AbsTol', 1e-12, ...
                'findMaxTime must apply covShift exactly once (#18 regression)');
        end

        function testFindMinMaxSymmetry(tc)
            t = (0:0.01:2.0)';
            c1 = Covariate(t, t, 'Cov1', 'time', 's', '', {'a'});
            cc = CovColl({c1});
            rawMin = c1.minTime;
            rawMax = c1.maxTime;
            cc.setCovShift(0.1);

            tc.verifyEqual(cc.findMinTime, rawMin + 0.1, 'AbsTol', 1e-12);
            tc.verifyEqual(cc.findMaxTime, rawMax + 0.1, 'AbsTol', 1e-12, ...
                'findMinTime and findMaxTime must apply covShift symmetrically');
        end
    end
end
