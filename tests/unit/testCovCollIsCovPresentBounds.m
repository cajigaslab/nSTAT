classdef testCovCollIsCovPresentBounds < matlab.unittest.TestCase
    %TESTCOVCOLLISCOVPRESENTBOUNDS regression test for issue #17.
    %
    % CovColl.isCovPresent used strict less-than (cov < numCov) for the
    % integer-index branch, so the LAST covariate (index == numCov) was
    % incorrectly reported as absent. Fix changes to <=.

    methods (Test)
        function testLastCovariateIsPresent(tc)
            t = (0:0.001:1.0)';
            c1 = Covariate(t, t, 'Cov1', 'time', 's', '', {'a'});
            c2 = Covariate(t, sin(2*pi*t), 'Cov2', 'time', 's', '', {'b'});
            cc = CovColl({c1, c2});

            tc.verifyTrue(logical(cc.isCovPresent(1)), 'first covariate must be present');
            tc.verifyTrue(logical(cc.isCovPresent(2)), 'LAST covariate (#17 regression) must be present');
            tc.verifyFalse(logical(cc.isCovPresent(3)), 'out-of-range index must report absent');
            tc.verifyFalse(logical(cc.isCovPresent(0)), 'zero index must report absent');
        end
    end
end
