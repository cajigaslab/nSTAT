classdef testComputeKSStatsDTBranch < matlab.unittest.TestCase
    %TESTCOMPUTEKSSTATSDTBRANCH verify the DT-correction branch is reached.
    %
    % Phase 4 Task 4.2 surfaced a real bug: Analysis.computeKSStats
    % gates the DT-correction branch on `nCopy.isSigRepBin`, but the
    % cached flag is clobbered by setMinTime/setMaxTime calls earlier
    % in the function -- making the DT branch unreachable for typical
    % user input.
    %
    % This test pins the contract: when DTCorrection=1 is requested on
    % a low-rate Poisson spike train (lambda*delta well below the 0.4
    % validity bound), the DT branch must execute. We verify this by
    % constructing a regime where the DT and continuous-time paths
    % produce DIFFERENT outputs (the DT path includes the uniform
    % jitter from Haslinger-Pipa-Brown 2010; the continuous path does
    % not), then asserting that DTCorrection=1 produces the DT result.

    methods (Test)
        function testDTBranchProducesDifferentResultThanCT(tc)
            % Setup: moderate-rate Poisson where the DT correction is
            % meaningful but well in-regime.
            rng(42, 'twister');
            T = 10.0;
            sampleRate = 1000;
            delta = 1/sampleRate;
            lambdaHz = 50;  % lambda*delta = 0.05 (in-regime; DT non-trivial)
            t = (0:delta:T-delta)';
            y = double(rand(numel(t),1) < lambdaHz*delta);
            spikeTimes = t(y==1);
            nst = nspikeTrain(spikeTimes', 'u', delta, 0, T);
            lambda = Covariate(t, lambdaHz*ones(numel(t),1), '\lambda', ...
                'time','s','Hz',{'oracle'});

            % Suppress regime warning (we're in-regime; doesn't fire here)
            warnState = warning('off', 'nSTAT:DTCorrectionRegime');
            cleanup = onCleanup(@() warning(warnState));

            % Pin the RNG for ksdiscrete's jitter
            rng(7, 'twister');
            [~, U_DT, ~, ~, ks_DT] = Analysis.computeKSStats(nst, lambda, 1);

            rng(7, 'twister');
            [~, U_CT, ~, ~, ks_CT] = Analysis.computeKSStats(nst, lambda, 0);

            % DT and CT should produce DIFFERENT U vectors. If they're
            % identical, that means DT silently fell through to CT --
            % the bug this test exists to catch.
            tc.verifyFalse(isequal(U_DT, U_CT), ...
                ['DTCorrection=1 must reach the DT branch and produce ' ...
                 'a different result from DTCorrection=0; if they are ' ...
                 'identical, Analysis.computeKSStats fell through to ' ...
                 'the CT path despite DT being requested.']);
        end
    end
end
