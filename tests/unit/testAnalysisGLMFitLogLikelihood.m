classdef testAnalysisGLMFitLogLikelihood < matlab.unittest.TestCase
    %TESTANALYSISGLMFITLOGLIKELIHOOD logLL returned by Analysis.GLMFit
    % must match the analytic Bernoulli LL on a homogeneous Poisson
    % spike train with known constant rate.
    %
    % Sibling test of testFitResultLogLikelihood — Task 0.1 fixed the
    % missing log() wrapper at FitResult.m:355, 377, 420; the smoke
    % test of Phase 0 surfaced a fifth instance at Analysis.m:641
    % which is the canonical pipeline reached by every call to
    % Analysis.RunAnalysisForNeuron / RunAnalysisForAllNeurons.
    %
    % This test locks the same analytic identity at the Analysis.GLMFit
    % return path:
    %
    %   logLL = N_spikes * log(λΔ) + (N_bins - N_spikes) * log(1 - λΔ)
    %
    % Refs: bci-curriculum §4.B.1 PP-GLM Bernoulli parameterization.

    methods (Test)
        function testHomogeneousPoissonGLMFitLogLL(tc)
            rng(0, 'twister');
            T = 10.0;            % seconds
            sampleRate = 1000;   % Hz
            delta = 1/sampleRate;
            lambdaHz = 5.0;
            lambdaDelta = lambdaHz * delta;     % 0.005

            % Build minimal nSTAT objects sufficient to call Analysis.GLMFit
            nBins = round(T * sampleRate) + 1;   % inclusive [0, T] convention
            t = (0:nBins-1)' * delta;
            y = double(rand(nBins,1) < lambdaDelta);
            spikeTimes = t(y==1)';

            nst = nspikeTrain(spikeTimes, 'unit1', delta, 0, T);
            spikeColl = nstColl(nst);
            baseline = Covariate(t, ones(nBins,1), 'Baseline', ...
                'time','s','',{'const'});
            covColl = CovColl({baseline});
            trial = Trial(spikeColl, covColl);

            % Configure a single-covariate baseline-only model
            cfg = TrialConfig({'Baseline'}, sampleRate, []);
            configColl = ConfigColl(cfg);

            % Verify the binned signal is binary (precondition of the
            % Bernoulli identity)
            sigData = nst.getSigRep.dataToMatrix;
            tc.assertTrue(all(sigData == 0 | sigData == 1), ...
                'binned signal must be binary for Bernoulli identity to hold');
            nSpikesBinned = sum(sigData);
            nBinsActual = numel(sigData);

            % Fit
            [lambda, b, dev, stats, AIC, BIC, logLL, distrib] = ...
                Analysis.GLMFit(trial, 1, 1, 'GLM'); %#ok<ASGLU>

            % The fitted constant rate is exp(b) / delta (Poisson link
            % via Analysis.GLMFit's exp link). Use the actual fitted
            % lambdaDelta rather than the simulation truth so the
            % identity isolates the formula error from estimator noise.
            fittedLambdaDelta = exp(b(1));
            expectedLL = nSpikesBinned*log(fittedLambdaDelta) + ...
                         (nBinsActual - nSpikesBinned)*log(1 - fittedLambdaDelta);

            tc.verifyEqual(logLL, expectedLL, 'AbsTol', 1e-6, ...
                ['Analysis.GLMFit logLL must match analytic Bernoulli LL ' ...
                 'at the fitted lambda*delta']);
        end
    end
end
