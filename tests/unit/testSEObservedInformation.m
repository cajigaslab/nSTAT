classdef testSEObservedInformation < matlab.unittest.TestCase
    %TESTSEOBSERVEDINFORMATION Inverse observed information in the EM SE
    % routines (issue #136).
    %
    % PP_ComputeParamStandardErrors / PPLFP_ComputeParamStandardErrors
    % inverted the observed information with eye/IObs and projected it
    % with nearestSPD. An exactly singular IObs (a separated history
    % window) gave an Inf/NaN inverse and nearestSPD looped forever, so
    % PP_EM / PPLFP_EM never returned when SEs were requested. Both
    % routines now go through PointProcessEM.seObservedInfoInverse, which
    % also projects only the identifiable block (nearestSPD itself does not
    % return on a singular matrix).

    methods (TestMethodSetup)
        function isolateWarnings(tc)
            warnState = warning;
            tc.addTeardown(@() warning(warnState));
        end
    end

    methods (Test)
        function testNonsingularIsUnchanged(tc)
            % No zero pivot: exactly the old nearestSPD(eye(size(IObs))/IObs),
            % nothing flagged, no warning.
            rng(3);
            B = randn(5); IObs = B*B' + 0.1*eye(5);
            f = @() nstat.decoding.PointProcessEM.seObservedInfoInverse(IObs, {}, 'r');
            [invIObs, nonId] = tc.verifyWarningFree(f);
            tc.verifyEqual(invIObs, nearestSPD(eye(size(IObs))/IObs));   % bit-identical
            tc.verifyFalse(any(nonId));
        end

        function testSingularFlagsNullSpaceParameters(tc)
            % Parameters 2 and 3 enter only through their sum (null vector
            % (0,1,-1)/sqrt(2)); parameter 1 is identifiable. Before the
            % fix eye/IObs was Inf and nearestSPD(Inf/NaN) never returned.
            IObs = blkdiag(4, [1 1; 1 1]);
            labels = {'mu(1)', 'gamma(1,1)', 'gamma(2,1)'};
            f = @() nstat.decoding.PointProcessEM.seObservedInfoInverse(IObs, labels, 'r');
            [invIObs, nonId] = tc.verifyWarning(f, 'nSTAT:EM:singularInformation');
            tc.verifyEqual(nonId, [false; true; true]);
            tc.verifyTrue(all(isfinite(invIObs(:))));
            P = pinv(IObs);
            tc.verifyEqual(invIObs(1,1), nearestSPD(P(1,1)), 'AbsTol', 1e-15);   % identifiable block projected
            tc.verifyEqual(invIObs(2:3,2:3), P(2:3,2:3), 'AbsTol', 1e-14);       % flagged block left as is
            lastwarn('');
            [~, ~] = f();
            [msg, id] = lastwarn;
            tc.verifyEqual(id, 'nSTAT:EM:singularInformation');
            tc.verifySubstring(msg, 'gamma(1,1), gamma(2,1)');
            tc.verifyFalse(contains(msg, 'mu(1)'));
        end

        function testNonFiniteInformationErrors(tc)
            % A non-finite IObs used to reach nearestSPD's endless loop;
            % it now errors.
            f = @() nstat.decoding.PointProcessEM.seObservedInfoInverse([1 NaN; NaN 1], {}, 'r');
            tc.verifyError(f, 'nSTAT:EM:nonFiniteInformation');
        end

        function testTermLabels(tc)
            % Stacking order of the SE vector: A row by row, Q diagonal,
            % beta / gamma one cell's column after another.
            labels = nstat.decoding.PointProcessEM.seTermLabels({ ...
                'A', 4, [2 2], 'square'; 'Q', 2, [2 2], 'square'; 'Px0', 0, [2 2], 'square'; ...
                'mu', 2, [2 1], 'vector'; 'beta', 4, [2 2], 'cellmajor'; 'gamma', 1, [1 1], 'cellmajor'});
            tc.verifyEqual(labels, {'A(1,1)','A(1,2)','A(2,1)','A(2,2)','Q(1,1)','Q(2,2)', ...
                'mu(1)','mu(2)','beta(1,1)','beta(2,1)','beta(1,2)','beta(2,2)','gamma(1,1)'});
        end
    end
end
