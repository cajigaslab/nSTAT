classdef testKsUnclamped < matlab.unittest.TestCase
    %TESTKSUNCLAMPED Verify ks_stat is computed on raw U, not clamped U.
    %
    % Pre-fix: Analysis.computeKSStats clamped U to [1e-6, 1-1e-6]
    % BEFORE computing ks_stat, biasing the statistic by O(1/N) at
    % the tails. Post-fix the clamp lives in Analysis.computeInvGausTrans
    % (where norminv needs it), so ks_stat sees the raw U.
    %
    % This test verifies the U returned by computeKSStats contains
    % values OUTSIDE the [1e-6, 1-1e-6] interval -- i.e., the clamp
    % is no longer being applied upstream of the statistic.
    %
    % Refs: Phase 0 Task 0.4 of docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md

    methods (Test)
        function testUContainsRawValuesAtBoundary(tc)
            % Engineer a spike train with a single very long inter-spike
            % interval relative to the (constant) firing rate, so the
            % integrated intensity over that ISI exceeds -log(1e-6) ~= 13.8
            % and U = 1 - exp(-Z) lands above 1 - 1e-6 = 0.999999.
            %
            % With lambdaHz = 200 and an ISI of 0.5 s, Z = 200 * 0.5 = 100,
            % so U = 1 - exp(-100) = 1 in IEEE 754 double precision. That is
            % unambiguously >= 0.999999 and cannot have been produced by
            % the removed clamp (which would have set it to exactly 0.999999).
            T = 2.0; sampleRate = 1000;
            t = (0:1/sampleRate:T-1/sampleRate)';
            lambdaHz = 200 * ones(size(t));   % lambda*delta = 0.2
            lambda = Covariate(t, lambdaHz, '\lambda(t)', ...
                'time','s','Hz',{'\lambda_1'});

            % Two spikes far apart -> one long ISI -> large Z -> U at boundary.
            spikeTimes = [0.1, 1.5];
            nst = nspikeTrain(spikeTimes, 'unit1', 1/sampleRate, 0, T);

            % DTCorrection=0 (continuous-time path; the validity-bound warning
            % is suppressed and we get the raw uniform-rescaling output).
            [~, U, ~, ~, ~] = Analysis.computeKSStats(nst, lambda, 0);

            % At least one U value must be at or beyond the [1e-6, 1-1e-6]
            % boundary. Pre-fix the upstream clamp would have prevented any
            % such value from appearing in the returned U vector.
            atBoundary = any(U(:) >= 0.999999) || any(U(:) <= 0.000001);
            tc.verifyTrue(atBoundary, ...
                ['ks_stat must see raw U values -- at least one boundary value ' ...
                 'expected. If this assertion fails, either (a) the upstream clamp ' ...
                 'returned, or (b) computeKSStats no longer yields raw U at the tails.']);

            % Stronger lock: the upstream clamp set U to *exactly* 0.999999 at
            % the boundary. Raw U values come from a continuous transform; the
            % value should be strictly greater than the sentinel when it crosses
            % it, never equal to the sentinel.
            nExactSentinel = sum(U(:) == 0.999999);
            tc.verifyEqual(nExactSentinel, 0, ...
                ['Any exact 0.999999 entry indicates the upstream clamp was ' ...
                 'reapplied to U before it was returned by computeKSStats.']);
        end
    end
end
