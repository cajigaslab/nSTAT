classdef TestPythonPortFidelity < matlab.unittest.TestCase
    %TESTPYTHONPORTFIDELITY Load Python nSTAT objects directly from MATLAB.

    properties (Access = private)
        RootDir char
        PythonRepo char
    end

    methods (TestClassSetup)
        function setup(tc)
            tc.RootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(fullfile(tc.RootDir, 'tools', 'python'));
            addpath(fullfile(tc.RootDir, 'tests', 'python_port_fidelity'));
            [~, tc.PythonRepo] = setup_python_for_nstat_tests();
            addpath(tc.RootDir);
        end
    end

    methods (Test)
        function testSignalObjConstructionAndSubSignal(tc)
            t = (0:0.1:0.4)';
            x = [sin(t), cos(t)];
            sig = SignalObj(t, x, 'TestSignal', 'time', 's', 'a.u.', {'s1', 's2'});
            subSig = sig.getSubSignal(1);

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                't = np.arange(0.0, 0.5, 0.1)'
                'x = np.column_stack([np.sin(t), np.cos(t)])'
                'sig = nstat.SignalObj(t, x, ''TestSignal'', ''time'', ''s'', ''a.u.'', [''s1'', ''s2''])'
                'sub = sig.getSubSignal(1)'
                'json_text = json.dumps({'
                '    ''time'': np.asarray(sig.time, dtype=float).tolist(),'
                '    ''data'': np.asarray(sig.data, dtype=float).tolist(),'
                '    ''sampleRate'': float(sig.sampleRate),'
                '    ''sub_data'': np.asarray(sub.data, dtype=float).tolist()'
                '})'
            }, newline));

            tc.verifyEqual(payload.time(:), sig.time(:), 'AbsTol', 1e-12);
            tc.verifyEqual(payload.data, sig.data, 'AbsTol', 1e-12);
            tc.verifyEqual(payload.sampleRate, sig.sampleRate, 'AbsTol', 1e-12);
            tc.verifyEqual(payload.sub_data, subSig.data, 'AbsTol', 1e-12);
        end

        function testNSpikeTrainSignalRepresentation(tc)
            nst = nspikeTrain([0.1 0.3 0.35]);
            nst.setMinTime(0);
            nst.setMaxTime(0.5);
            sigRep = nst.getSigRep(0.1);
            spikeTimes = nst.getSpikeTimes();

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                'nst = nstat.nspikeTrain([0.1, 0.3, 0.35])'
                'nst.setMinTime(0.0)'
                'nst.setMaxTime(0.5)'
                'sig_rep = nst.getSigRep(0.1)'
                'json_text = json.dumps({'
                '    ''spike_times'': np.asarray(nst.getSpikeTimes(), dtype=float).tolist(),'
                '    ''sampleRate'': float(nst.sampleRate),'
                '    ''sig_rep'': np.asarray(sig_rep.data, dtype=float).tolist()'
                '})'
            }, newline));

            tc.verifyEqual(payload.spike_times(:), spikeTimes(:), 'AbsTol', 1e-12);
            tc.verifyEqual(payload.sampleRate, nst.sampleRate, 'AbsTol', 1e-12);
            tc.verifyEqual(payload.sig_rep, sigRep.data, 'AbsTol', 1e-12);
        end

        function testCovariateConfidenceIntervalAgainstPython(tc)
            t = (0:0.1:0.4)';
            cov = Covariate(t, sin(t), 'Stimulus', 'time', 's', 'a.u.', {'stim'});
            ci = ConfidenceInterval(t, [sin(t)-0.1, sin(t)+0.1], 'CI', 'time', 's', 'a.u.');
            cov.setConfInterval(ci);

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                't = np.arange(0.0, 0.5, 0.1)'
                'cov = nstat.Covariate(t, np.sin(t), ''Stimulus'', ''time'', ''s'', ''a.u.'', [''stim''])'
                'ci = nstat.ConfidenceInterval(t, np.column_stack([np.sin(t)-0.1, np.sin(t)+0.1]), ''b'')'
                'cov.setConfInterval(ci)'
                'json_text = json.dumps({'
                '    ''ci_set'': bool(cov.isConfIntervalSet()),'
                '    ''lower'': np.asarray(cov.ci[0].lower, dtype=float).tolist(),'
                '    ''upper'': np.asarray(cov.ci[0].upper, dtype=float).tolist()'
                '})'
            }, newline));

            tc.verifyTrue(payload.ci_set);
            tc.verifyEqual(payload.lower(:), ci.data(:, 1), 'AbsTol', 1e-12);
            tc.verifyEqual(payload.upper(:), ci.data(:, 2), 'AbsTol', 1e-12);
        end

        function testNSTCollCollectionSurfaceAgainstPython(tc)
            n1 = nspikeTrain([0.1 0.3], '1', 10, 0, 0.5, 'time', 's', '', '', -1);
            n2 = nspikeTrain([0.2], '2', 10, 0, 0.5, 'time', 's', '', '', -1);
            coll = nstColl({n1, n2});
            dataMat = coll.dataToMatrix([1 2], 0.1, 0.0, 0.5);

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                'n1 = nstat.nspikeTrain([0.1, 0.3], ''1'', 10.0, 0.0, 0.5, ''time'', ''s'', '''', '''', -1)'
                'n2 = nstat.nspikeTrain([0.2], ''2'', 10.0, 0.0, 0.5, ''time'', ''s'', '''', '''', -1)'
                'coll = nstat.nstColl([n1, n2])'
                'data_mat = np.asarray(coll.dataToMatrix([1, 2], 0.1, 0.0, 0.5), dtype=float)'
                'json_text = json.dumps({'
                '    ''num_spike_trains'': int(coll.numSpikeTrains),'
                '    ''first_name'': str(coll.getNST(1).name),'
                '    ''data_matrix'': data_mat.tolist()'
                '})'
            }, newline));

            tc.verifyEqual(payload.num_spike_trains, coll.numSpikeTrains);
            tc.verifyEqual(string(payload.first_name), string(coll.getNST(1).name));
            tc.verifyEqual(payload.data_matrix, dataMat, 'AbsTol', 1e-12);
        end

        function testTrialConfigAndConfigCollSurface(tc)
            cfg = TrialConfig({{'Baseline', 'mu'}}, 10, [], []);
            cfg.setName('Baseline');
            cfgColl = ConfigColl({cfg});
            configNames = cfgColl.getConfigNames();

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import nstat'
                'cfg = nstat.TrialConfig([[''Baseline'', ''mu'']], 10.0, [], [], [], name=''Baseline'')'
                'cfg_coll = nstat.ConfigColl([cfg])'
                'json_text = json.dumps({'
                '    ''config_name'': cfg.name,'
                '    ''num_configs'': int(cfg_coll.numConfigs),'
                '    ''config_names'': list(cfg_coll.configNames)'
                '})'
            }, newline));

            tc.verifyEqual(string(payload.config_name), "Baseline");
            tc.verifyEqual(payload.num_configs, cfgColl.numConfigs);
            tc.verifyEqual(string(payload.config_names(:)), string(configNames(:)));
        end

        function testDecodingAlgorithmsPredictAgainstPython(tc)
            xu = [0.1; -0.2];
            Wu = [1.0 0.1; 0.1 2.0];
            A = [1.0 0.2; 0.0 0.9];
            Q = 0.05 * eye(2);
            [xp, Wp] = DecodingAlgorithms.PPDecode_predict(xu, Wu, A, Q);

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                'xu = np.array([0.1, -0.2], dtype=float)'
                'Wu = np.array([[1.0, 0.1], [0.1, 2.0]], dtype=float)'
                'A = np.array([[1.0, 0.2], [0.0, 0.9]], dtype=float)'
                'Q = 0.05 * np.eye(2)'
                'xp, Wp = nstat.DecodingAlgorithms.PPDecode_predict(xu, Wu, A, Q)'
                'json_text = json.dumps({'
                '    ''xp'': np.asarray(xp, dtype=float).tolist(),'
                '    ''Wp'': np.asarray(Wp, dtype=float).tolist()'
                '})'
            }, newline));

            tc.verifyEqual(payload.xp(:), xp(:), 'AbsTol', 1e-12);
            tc.verifyEqual(payload.Wp, Wp, 'AbsTol', 1e-12);
        end

        function testCIFEvaluationAgainstPython(tc)
            cif = CIF([0.1 0.5], {'stim1', 'stim2'}, {'stim1', 'stim2'}, 'binomial');
            stimVal = [0.6; -0.2];

            lambdaDelta = cif.evalLambdaDelta(stimVal);
            gradient = cif.evalGradient(stimVal);
            jacobian = cif.evalJacobian(stimVal);

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                'cif = nstat.CIF(beta=np.array([0.1, 0.5], dtype=float), Xnames=[''stim1'', ''stim2''], stimNames=[''stim1'', ''stim2''], fitType=''binomial'')'
                'stim_val = np.array([0.6, -0.2], dtype=float)'
                'json_text = json.dumps({'
                '    ''lambda_delta'': float(cif.evalLambdaDelta(stim_val)),'
                '    ''gradient'': np.asarray(cif.evalGradient(stim_val), dtype=float).tolist(),'
                '    ''jacobian'': np.asarray(cif.evalJacobian(stim_val), dtype=float).tolist()'
                '})'
            }, newline));

            tc.verifyEqual(payload.lambda_delta, lambdaDelta, 'AbsTol', 1e-10);
            tc.verifyEqual(payload.gradient(:), gradient(:), 'AbsTol', 1e-10);
            tc.verifyEqual(payload.jacobian, jacobian, 'AbsTol', 1e-10);
        end

        function testAnalysisAndFitSummaryAgainstPython(tc)
            t = (0:0.1:1.0)';
            stim = Covariate(t, sin(2*pi*t), 'Stimulus', 'time', 's', '', {'stim'});
            spikeTrain = nspikeTrain([0.1 0.4 0.7], '1', 0.1, 0.0, 1.0, 'time', 's', '', '', -1);
            trial = Trial(nstColl({spikeTrain}), CovColl({stim}));
            cfg = TrialConfig({{'Stimulus', 'stim'}}, 10, [], []);
            cfg.setName('stim');
            fit = Analysis.RunAnalysisForNeuron(trial, 1, ConfigColl({cfg}));
            summary = FitResSummary({fit});

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                't = np.arange(0.0, 1.0 + 0.1, 0.1)'
                'stim = nstat.Covariate(t, np.sin(2*np.pi*t), ''Stimulus'', ''time'', ''s'', '''', [''stim''])'
                'spike_train = nstat.nspikeTrain([0.1, 0.4, 0.7], ''1'', 0.1, 0.0, 1.0, ''time'', ''s'', '''', '''', -1)'
                'trial = nstat.Trial(nstat.nstColl([spike_train]), nstat.CovColl([stim]))'
                'cfg = nstat.TrialConfig([[''Stimulus'', ''stim'']], 10.0, [], [], name=''stim'')'
                'fit = nstat.Analysis.RunAnalysisForNeuron(trial, 1, nstat.ConfigColl([cfg]))'
                'summary = nstat.FitResSummary([fit])'
                'json_text = json.dumps({'
                '    ''aic'': float(np.asarray(fit.AIC, dtype=float)[0]),'
                '    ''bic'': float(np.asarray(fit.BIC, dtype=float)[0]),'
                '    ''config_name'': fit.configNames[0],'
                '    ''summary_aic'': float(np.asarray(summary.AIC, dtype=float)[0]),'
                '    ''bic_minus_aic'': float(np.asarray(fit.BIC, dtype=float)[0] - np.asarray(fit.AIC, dtype=float)[0])'
                '})'
            }, newline));

            tc.verifyEqual(string(payload.config_name), string(fit.configNames{1}));
            tc.verifyTrue(isfinite(payload.aic));
            tc.verifyTrue(isfinite(payload.bic));
            tc.verifyTrue(isfinite(fit.AIC(1)));
            tc.verifyTrue(isfinite(fit.BIC(1)));
            tc.verifyEqual(payload.bic_minus_aic, fit.BIC(1) - fit.AIC(1), 'AbsTol', 1e-10);
            tc.verifyEqual(payload.summary_aic, payload.aic, 'AbsTol', 1e-10);
        end

        function testNSTCollSSGLMSurfaceAgainstPython(tc)
            ss1 = nspikeTrain([0.1 0.3], '1', 10, 0.0, 0.5, 'time', 's', 'spikes', 'spk', -1);
            ss2 = nspikeTrain([0.2], '1', 10, 0.0, 0.5, 'time', 's', 'spikes', 'spk', -1);
            coll = nstColl({ss1, ss2});
            [xK, WK, Qhat, gammahat, logll, fitSummary] = coll.ssglm([0.0 0.1 0.2], 2, 2, 'binomial');

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                'ss1 = nstat.nspikeTrain([0.1, 0.3], ''1'', 10.0, 0.0, 0.5, ''time'', ''s'', ''spikes'', ''spk'', -1)'
                'ss2 = nstat.nspikeTrain([0.2], ''1'', 10.0, 0.0, 0.5, ''time'', ''s'', ''spikes'', ''spk'', -1)'
                'coll = nstat.nstColl([ss1, ss2])'
                'xK, WK, Qhat, gammahat, logll, fit_summary = coll.ssglm([0.0, 0.1, 0.2], 2, 2, ''binomial'')'
                'json_text = json.dumps({'
                '    ''xK_shape'': list(np.asarray(xK, dtype=float).shape),'
                '    ''WK_shape'': list(np.asarray(WK, dtype=float).shape),'
                '    ''Qhat_finite'': bool(np.all(np.isfinite(np.asarray(Qhat, dtype=float)))),'
                '    ''gammahat_finite'': bool(np.all(np.isfinite(np.asarray(gammahat, dtype=float)))),'
                '    ''logll_finite'': bool(np.all(np.isfinite(np.asarray(logll, dtype=float)))),'
                '    ''summary_aic_finite'': bool(np.all(np.isfinite(np.asarray(fit_summary.AIC, dtype=float)))),'
                '    ''logll_last'': float(np.asarray(logll, dtype=float).reshape(-1)[-1])'
                '})'
            }, newline));

            tc.verifyEqual(double(payload.xK_shape(:))', double(size(xK)));
            tc.verifyEqual(double(payload.WK_shape(:))', double(size(WK)));
            tc.verifyTrue(payload.Qhat_finite);
            tc.verifyTrue(payload.gammahat_finite);
            tc.verifyTrue(payload.logll_finite);
            tc.verifyGreaterThan(numel(Qhat), 0);
            tc.verifyGreaterThan(numel(gammahat), 0);
            tc.verifyTrue(payload.summary_aic_finite);
            tc.verifyTrue(all(isfinite(fitSummary.AIC(:))));
            tc.verifyTrue(isfinite(payload.logll_last));
            tc.verifyTrue(isfinite(logll(end)));
        end
    end
end
