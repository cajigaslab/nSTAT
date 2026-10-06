classdef testFitResSummaryHistIndex < matlab.unittest.TestCase
    %TESTFITRESSUMMARYHISTINDEX regression tests for
    % FitResSummary.getHistIndex / getHistCoeffs / getCoeffs.
    %
    % FitResSummary.plotParams.bAct is (numLabels x numResults x
    % numNeurons). getHistIndex used to filter NaN labels with
    % `bAct(:,fitNum)`, which folds dims 2-3 and so only read NEURON 1.
    % computePlotParams NaNs coefficients with se >= 100, so when neuron
    % 1's history coefficients were not identifiable every history label
    % was dropped even though other neurons had them: getHistCoeffs then
    % crashed on an undefined `baseStrings`, and getCoeffs reported the
    % history terms as ordinary covariates (this is what broke
    % PointProcessEM.PP_MStep's GLM M-step with history).
    %
    % Scenario (built so the NaN pattern does not depend on RNG luck):
    % neuron 1 fires regularly every 50 ms, so no spike ever falls inside
    % its <= 5 ms history windows -> complete separation -> its history
    % coefficients are NaN in bAct. Neurons 2 and 3 fire at ~100 Hz
    % (Bernoulli), giving plenty of short intervals -> finite history
    % coefficients.

    properties (Constant, Access = private)
        WindowTimes = [0 0.001 0.002 0.005];
    end

    methods (TestMethodSetup)
        function isolateWarnings(tc)
            warnState = warning;
            tc.addTeardown(@() warning(warnState));
            warning('off', 'all');
        end
    end

    methods (Test)
        function testHistIndexUsesEveryNeuron(tc)
            frs = testFitResSummaryHistIndex.fitSummary(true);
            histLabels = find(startsWith(frs.uniqueCovLabels, '['));
            tc.assertNumElements(histLabels, numel(testFitResSummaryHistIndex.WindowTimes)-1);
            % Preconditions of the scenario.
            tc.assumeTrue(all(isnan(frs.plotParams.bAct(histLabels,1,1))), ...
                'scenario: neuron 1 history coefficients must be NaN (se >= 100)');
            tc.assumeTrue(all(isfinite(frs.plotParams.bAct(histLabels,1,3))), ...
                'scenario: neuron 3 history coefficients must be finite');

            histIndex = frs.getHistIndex();
            tc.verifyEqual(sort(histIndex(:)'), histLabels(:)', ...
                'history labels must be kept when ANY neuron has them (was: neuron 1 only)');
        end

        function testHistCoeffsReturnsPerNeuronMatrix(tc)
            frs = testFitResSummaryHistIndex.fitSummary(true);
            nW = numel(testFitResSummaryHistIndex.WindowTimes)-1;
            [histMat, labels] = frs.getHistCoeffs();      % used to crash
            tc.verifySize(histMat, [nW, 1, 3]);
            tc.verifyNumElements(labels, nW);
            tc.verifyTrue(all(isnan(histMat(:,1,1))), 'neuron 1 history coefficients are NaN');
            tc.verifyTrue(all(isfinite(histMat(:,1,3))), 'neuron 3 history coefficients are finite');
            histLabels = find(startsWith(frs.uniqueCovLabels, '['));
            tc.verifyEqual(histMat(:,1,3), frs.plotParams.bAct(histLabels,1,3), ...
                'getHistCoeffs must return the fitted history coefficients');
        end

        function testCoeffsExcludeHistoryTerms(tc)
            frs = testFitResSummaryHistIndex.fitSummary(true);
            [coeffMat, labels] = frs.getCoeffs();
            coeffMat = squeeze(coeffMat);
            tc.verifySize(coeffMat, [3, 3], ...
                'getCoeffs must return constant, v1, v2 only (history terms excluded)');
            tc.verifyEqual(labels(:)', {'constant', 'v1', 'v2'});
            tc.verifyTrue(all(isfinite(coeffMat(:))));
        end

        function testNoHistoryReturnsEmptyWithoutError(tc)
            frs = testFitResSummaryHistIndex.fitSummary(false);
            tc.verifyEmpty(frs.getHistIndex());
            [histMat, labels] = frs.getHistCoeffs();      % used to crash
            tc.verifyEmpty(histMat);
            tc.verifyEmpty(labels);
            coeffMat = squeeze(frs.getCoeffs());
            tc.verifySize(coeffMat, [3, 3]);
        end
    end

    methods (Static, Access = private)
        function frs = fitSummary(withHistory)
            rng(42);
            N = 2000; dt = 0.001; time = (0:N-1)*dt;
            x = cumsum(0.05*randn(2, N), 2);
            spikes = cell(1, 3);
            spikes{1} = time(1:50:N);                       % regular, 20 Hz
            spikes{2} = time(rand(1, N) < 0.1);             % ~100 Hz
            spikes{3} = time(rand(1, N) < 0.1);
            for i = 1:3
                nst{i} = nspikeTrain(spikes{i}); %#ok<AGROW>
            end
            vel = Covariate(time, x', 'vel', 'time', 's', 'm/s', {'v1', 'v2'});
            baseline = Covariate(time, ones(N, 1), 'Baseline', 'time', 's', '', {'constant'});
            trial = Trial(nstColl(nst), CovColl({vel, baseline}));
            if withHistory
                histWin = testFitResSummaryHistIndex.WindowTimes;
            else
                histWin = [];
            end
            cfg = TrialConfig({{'Baseline', 'constant'}, {'vel', 'v1', 'v2'}}, 1000, histWin, []);
            cfg.setName('cfg');
            results = [];
            evalc('results = Analysis.RunAnalysisForAllNeurons(trial, ConfigColl({cfg}), 0, ''GLM'');');
            frs = FitResSummary(results);
        end
    end
end
