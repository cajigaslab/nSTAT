classdef testKsdiscreteDeterminism < matlab.unittest.TestCase
    %TESTKSDISCRETEDETERMINISM ksdiscrete must respect caller's RNG seed.
    %
    % Pre-fix: Analysis.m:1511 reseeded the global RNG with the system
    % clock on every call, making the discrete-time KS uniform-jitter
    % non-deterministic even under fixed caller seed.
    %
    % Post-fix: ksdiscrete uses whatever RNG state the caller set up.
    % Two calls at the same seed produce identical rescaled times.

    methods (Test)
        function testTwoCallsAtSameSeedAgree(tc)
            % Construct a deterministic pk + spike train
            n = 1000;
            pk = 0.05 * ones(n, 1);          % 5% spike-per-bin probability
            rng(123, 'twister');
            spikeIdx = sort(randperm(n, 50))';
            spikeTrain = zeros(n,1);
            spikeTrain(spikeIdx) = 1;

            % Call A at seed 42
            rng(42, 'twister');
            rstA = Analysis.ksdiscrete(pk, spikeTrain, 'spiketrain');

            % Call B with identical seed
            rng(42, 'twister');
            rstB = Analysis.ksdiscrete(pk, spikeTrain, 'spiketrain');

            tc.verifyEqual(rstA, rstB, ...
                'ksdiscrete with identical RNG state must be deterministic');
        end

        function testDifferentSeedsGiveDifferentResults(tc)
            % Sanity: different seeds DO produce different rescaled times
            % (proves the RNG is wired through — not constant).
            n = 1000;
            pk = 0.05 * ones(n, 1);
            rng(123, 'twister');
            spikeIdx = sort(randperm(n, 50))';
            spikeTrain = zeros(n,1);
            spikeTrain(spikeIdx) = 1;

            rng(1, 'twister');
            rstA = Analysis.ksdiscrete(pk, spikeTrain, 'spiketrain');

            rng(2, 'twister');
            rstB = Analysis.ksdiscrete(pk, spikeTrain, 'spiketrain');

            tc.verifyNotEqual(rstA, rstB, ...
                'Different RNG seeds must produce different rescaled times');
        end
    end
end
