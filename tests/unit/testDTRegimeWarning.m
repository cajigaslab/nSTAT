classdef testDTRegimeWarning < matlab.unittest.TestCase
    %TESTDTREGIMEWARNING computeKSStats should warn when λΔ > 0.4 prevalent.
    %
    % Refs: Haslinger, Pipa & Brown 2010; bci-curriculum §4.C.1 Cor. 2;
    % reviews/ks-transformer-validation/ in the bci-curriculum repo.

    methods (Test)
        function testWarnsAtHighRate(tc)
            % Construct a CIF with lambdaDelta = 0.5 (above the 0.4 bound)
            T = 1.0; sampleRate = 100;       % 10 ms bins
            t = (0:1/sampleRate:T-1/sampleRate)';
            lambdaHz = 50 * ones(size(t));   % lambda*Delta = 50/100 = 0.5
            lambda = Covariate(t, lambdaHz, '\lambda(t)', ...
                'time','s','Hz',{'\lambda_1'});

            spikeTimes = (0.02:0.02:T-0.02)';   % regular 50 Hz spikes
            nst = nspikeTrain(spikeTimes', 'unit1', 1/sampleRate, 0, T);

            tc.verifyWarning( ...
                @() Analysis.computeKSStats(nst, lambda, 1), ...
                'nSTAT:DTCorrectionRegime', ...
                'computeKSStats must warn when lambda*delta > 0.4 in significant fraction of bins');
        end

        function testNoWarningAtLowRate(tc)
            % Sanity: low-rate spike train (lambda*delta = 0.005) should NOT warn.
            T = 10.0; sampleRate = 1000;
            t = (0:1/sampleRate:T-1/sampleRate)';
            lambdaHz = 5 * ones(size(t));    % lambda*delta = 0.005
            lambda = Covariate(t, lambdaHz, '\lambda(t)', ...
                'time','s','Hz',{'\lambda_1'});

            rng(0, 'twister');
            spikeTimes = sort(rand(50,1) * T);
            nst = nspikeTrain(spikeTimes', 'unit1', 1/sampleRate, 0, T);

            tc.verifyWarningFree( ...
                @() Analysis.computeKSStats(nst, lambda, 1), ...
                'computeKSStats must NOT warn at low rates');
        end
    end
end
