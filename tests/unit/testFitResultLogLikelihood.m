classdef testFitResultLogLikelihood < matlab.unittest.TestCase
    %TESTFITRESULTLOGLIKELIHOOD logLL should match analytic Bernoulli LL
    % on a homogeneous Poisson spike train with known constant rate.
    %
    % Phase 0 Task 0.1 regression test. FitResult.m had three sites
    % (lines 355, 375, 417) where the Bernoulli log-likelihood formula
    % omitted log() around the (1 - lambda*delta) term, adding an
    % additive constant (N_bins - N_spikes) to the reported fitObj.logLL.
    %
    % This test triggers the single-result branch in addParamsToFit at
    % FitResult.m:355 (nargin<7 path) and asserts that the resulting
    % fitObj.logLL value matches the closed-form Bernoulli LL.

    methods (Test)
        function testHomogeneousPoissonLogLL(tc)
            rng(0, 'twister');
            T = 10.0;            % seconds
            sampleRate = 1000;   % Hz
            delta = 1/sampleRate;
            lambdaHz = 5.0;
            lambdaDelta = lambdaHz * delta;     % 0.005

            % Simulate Bernoulli-per-bin spike train at known rate.
            % nspikeTrain's binned representation (getSigRep) covers
            % [minTime, maxTime] inclusive on a delta grid, producing
            % nBins = T*sampleRate + 1 bins. Sample y on that grid so
            % the lambda Covariate and the binned spike train align.
            nBins = round(T * sampleRate) + 1;
            t = (0:nBins-1)' * delta;
            y = double(rand(nBins,1) < lambdaDelta);
            nSpikes = sum(y);

            % Build minimal nSTAT objects. nspikeTrain signature:
            % (spikeTimes, name, binwidth, minTime, maxTime, ...)
            spikeTimes = t(y==1)';
            nst = nspikeTrain(spikeTimes, 'unit1', delta, 0, T);
            nst.setMinTime(0);
            nst.setMaxTime(T);

            % Sanity-check that the binned spike train matches y.
            sigData = nst.getSigRep.dataToMatrix;
            tc.assertEqual(size(sigData,1), nBins, ...
                'Spike-train binned signal length mismatch');

            % Constant-lambda Covariate at the true rate (in Hz).
            % FitResult uses delta = 1/lambda.sampleRate, so building
            % the Covariate over the same time grid produces a
            % sampleRate equal to 1/delta = 1000 Hz.
            lambda = Covariate(t, lambdaHz*ones(nBins,1), '\lambda(t)', ...
                'time','s','Hz',{'\lambda_{1}'});

            % Manually build a FitResult shell with NaN logLL/AIC/BIC.
            % The constructor's call to addParamsToFit passes all 9
            % args, so the nargin>=7 (else) branch is taken and
            % fitObj.logLL(1) is just the NaN we passed. To trigger
            % the buggy formula at FitResult.m:355 we then call
            % addParamsToFit directly with only 5 args (neuronNum,
            % lambda, b, dev, stats), driving nargin to 6.
            cfg = ConfigColl();
            fitObj = FitResult(nst, {{'Baseline'}}, {0}, {[]}, {[]}, ...
                lambda, {log(lambdaDelta)}, 0, {struct()}, ...
                NaN, NaN, NaN, cfg, {[]}, {[]}, {'normal'});

            % Sanity: the constructor's call to addParamsToFit hit the
            % else-branch (nargin>=7), so fitObj.logLL(1) is NaN.
            tc.assertEqual(fitObj.numResults, 1);

            % Now trigger the single-result nargin<7 branch directly.
            % This populates fitObj.logLL(2) using the formula at
            % FitResult.m:355.
            fitObj.addParamsToFit(fitObj.neuronNumber, lambda, ...
                {log(lambdaDelta)}, 0, {struct()});

            % Analytic Bernoulli LL: N_spikes*log(p) + (N_bins-N_spikes)*log(1-p)
            % Use the spike count actually recovered by nspikeTrain's binner
            % (it may differ from sum(y) if multiple spikes land in a bin).
            nSpikesBinned = sum(sigData);
            expectedLL = nSpikesBinned*log(lambdaDelta) + ...
                         (nBins - nSpikesBinned)*log(1 - lambdaDelta);

            tc.verifyEqual(fitObj.logLL(2), expectedLL, ...
                'AbsTol', 1e-6, ...
                'fitObj.logLL must match analytic Bernoulli log-likelihood');
        end
    end
end
