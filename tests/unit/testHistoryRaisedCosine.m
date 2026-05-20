classdef testHistoryRaisedCosine < matlab.unittest.TestCase
    %TESTHISTORYRAISEDCOSINE verify the History.raisedCosine static constructor.
    %
    % Phase 3 Task 3.6 of the 2026-05-19 nSTAT review action plan.

    methods (Test)
        function testDefaultBoundsLogSpaced(tc)
            % Default tMin=0.002, tMax=0.100 with K=5
            h = History.raisedCosine(5);

            % Expect windowTimes = [0, 0.002, ..., 0.100]
            tc.verifyEqual(numel(h.windowTimes), 6, ...
                'K=5 peaks → 6 windowTimes (incl. prepended 0)');
            tc.verifyEqual(h.windowTimes(1), 0, ...
                'First windowTime must be 0 (spike-onset)');
            tc.verifyEqual(h.windowTimes(2), 0.002, 'AbsTol', 1e-12, ...
                'Second windowTime must equal tMin');
            tc.verifyEqual(h.windowTimes(end), 0.100, 'AbsTol', 1e-12, ...
                'Last windowTime must equal tMax');

            % Verify log spacing of the K peaks (windowTimes(2:end))
            peaks = h.windowTimes(2:end);
            logRatios = diff(log(peaks));
            tc.verifyEqual(logRatios, repmat(logRatios(1), 1, K_default()-1), ...
                'AbsTol', 1e-12, ...
                'Peaks must be exactly log-equally-spaced');
        end

        function testCustomBounds(tc)
            % Custom K=4, tMin=5ms, tMax=50ms
            h = History.raisedCosine(4, 0.005, 0.050);

            tc.verifyEqual(numel(h.windowTimes), 5);
            tc.verifyEqual(h.windowTimes(1), 0);
            tc.verifyEqual(h.windowTimes(2), 0.005, 'AbsTol', 1e-12);
            tc.verifyEqual(h.windowTimes(end), 0.050, 'AbsTol', 1e-12);
        end

        function testInvalidKRejected(tc)
            tc.verifyError(@() History.raisedCosine(1), ...
                'History:raisedCosine:InvalidK');
            tc.verifyError(@() History.raisedCosine(0), ...
                'History:raisedCosine:InvalidK');
        end

        function testInvalidtMinRejected(tc)
            tc.verifyError(@() History.raisedCosine(5, 0, 0.1), ...
                'History:raisedCosine:InvalidtMin');
            tc.verifyError(@() History.raisedCosine(5, -0.001, 0.1), ...
                'History:raisedCosine:InvalidtMin');
        end

        function testInvalidtMaxRejected(tc)
            tc.verifyError(@() History.raisedCosine(5, 0.1, 0.05), ...
                'History:raisedCosine:InvalidtMax');
            tc.verifyError(@() History.raisedCosine(5, 0.01, 0.01), ...
                'History:raisedCosine:InvalidtMax');
        end

        function testReturnsHistoryObject(tc)
            h = History.raisedCosine(3, 0.001, 0.020);
            tc.verifyClass(h, 'History', ...
                'Static constructor must return a History instance');
        end
    end
end

function K = K_default()
    % Helper: K used by testDefaultBoundsLogSpaced
    K = 5;
end
