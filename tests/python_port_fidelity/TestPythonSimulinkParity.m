classdef TestPythonSimulinkParity < matlab.unittest.TestCase
    %TESTPYTHONSIMULINKPARITY Compare MATLAB/Simulink workflows to Python ports.

    properties (Access = private)
        RootDir char
    end

    methods (TestClassSetup)
        function setup(tc)
            tc.RootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(fullfile(tc.RootDir, 'tools', 'python'));
            addpath(fullfile(tc.RootDir, 'tests', 'python_port_fidelity'));
            setup_python_for_nstat_tests();
            addpath(tc.RootDir);
        end
    end

    methods (Test)
        function testPointProcessSimulationLambdaTraceAgainstPython(tc)
            Ts = 0.001;
            tMin = 0;
            tMax = 1;
            t = tMin:Ts:tMax;
            mu = -3;
            H = tf([0], [1], Ts, 'Variable', 'z^-1');
            S = tf([1], 1, Ts, 'Variable', 'z^-1');
            E = tf([0], 1, Ts, 'Variable', 'z^-1');
            u = sin(2*pi*1*t)';
            e = zeros(length(t), 1);
            stim = Covariate(t', u, 'Stimulus', 'time', 's', 'Voltage', {'sin'});
            ens = Covariate(t', e, 'Ensemble', 'time', 's', 'Spikes', {'n1'});
            [~, lambda] = CIF.simulateCIF(mu, H, S, E, stim, ens, 1, 'binomial');

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                'Ts = 0.001'
                't = np.arange(0.0, 1.0 + Ts, Ts)'
                'stim = nstat.Covariate(t, np.sin(2*np.pi*1.0*t), ''Stimulus'', ''time'', ''s'', ''Voltage'', [''sin''])'
                'ens = nstat.Covariate(t, np.zeros_like(t), ''Ensemble'', ''time'', ''s'', ''Spikes'', [''n1''])'
                '_, lambda_cov = nstat.CIF.simulateCIF(-3.0, np.array([0.0]), np.array([1.0]), np.array([0.0]), stim, ens, 1, ''binomial'', seed=5, return_lambda=True)'
                'json_text = json.dumps({''lambda_head'': np.asarray(lambda_cov.data[:10, 0], dtype=float).tolist()})'
            }, newline));

            tc.verifyEqual(payload.lambda_head(:), lambda.data(1:10, 1), 'AbsTol', 1e-8);
        end

        function testSimulatedNetwork2SurfaceAgainstPython(tc)
            Ts = 0.001;
            tMin = 0;
            tMax = 1;
            t = tMin:Ts:tMax;
            mu{1} = -3; mu{2} = -3; %#ok<AGROW>
            H{1} = tf([-4 -2 -1], [1], Ts, 'Variable', 'z^-1'); %#ok<AGROW>
            H{2} = tf([-4 -2 -1], [1], Ts, 'Variable', 'z^-1'); %#ok<AGROW>
            S{1} = tf([1], 1, Ts, 'Variable', 'z^-1'); %#ok<AGROW>
            S{2} = tf([-1], 1, Ts, 'Variable', 'z^-1'); %#ok<AGROW>
            E{1} = tf([1], 1, Ts, 'Variable', 'z^-1'); %#ok<AGROW>
            E{2} = tf([-4], 1, Ts, 'Variable', 'z^-1'); %#ok<AGROW>
            actNetwork = [0 1; -4 0];
            stim = Covariate(t', sin(2*pi*1*t)', 'Stimulus', 'time', 's', 'Voltage', {'sin'});

            assignin('base', 'S1', S{1}); assignin('base', 'H1', H{1}); assignin('base', 'E1', E{1}); assignin('base', 'mu1', mu{1});
            assignin('base', 'S2', S{2}); assignin('base', 'H2', H{2}); assignin('base', 'E2', E{2}); assignin('base', 'mu2', mu{2});
            % FIX: replaced simget with [] (default options); simget deprecated R2016a
            [tout, ~, yout] = sim('SimulatedNetwork2', [stim.minTime stim.maxTime], [], stim.dataToStructure); %#ok<NASGU,ASGLU>
            [h1Num, ~] = tfdata(H{1}, 'v');
            [h2Num, ~] = tfdata(H{2}, 'v');
            [s1Num, ~] = tfdata(S{1}, 'v');
            [s2Num, ~] = tfdata(S{2}, 'v');
            [e1Num, ~] = tfdata(E{1}, 'v');
            [e2Num, ~] = tfdata(E{2}, 'v');
            probMat = zeros(size(yout(:,1:2)));
            for n = 1:size(yout, 1)
                hist1 = 0; hist2 = 0;
                for lag = 1:length(h1Num)
                    if n-lag >= 1
                        hist1 = hist1 + h1Num(lag) * yout(n-lag,1);
                        hist2 = hist2 + h2Num(lag) * yout(n-lag,2);
                    end
                end
                ens1 = 0; ens2 = 0;
                if n > 1
                    ens1 = e1Num(1) * yout(n-1,2);
                    ens2 = e2Num(1) * yout(n-1,1);
                end
                eta1 = mu{1} + hist1 + s1Num(1) * stim.data(n) + ens1;
                eta2 = mu{2} + hist2 + s2Num(1) * stim.data(n) + ens2;
                probMat(n,1) = exp(eta1) / (1 + exp(eta1));
                probMat(n,2) = exp(eta2) / (1 + exp(eta2));
            end

            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import numpy as np'
                'import nstat'
                'sim = nstat.simulate_two_neuron_network(duration_s=1.0, dt=0.001, seed=4)'
                'json_text = json.dumps({'
                '    ''actual_network'': np.asarray(sim.actual_network, dtype=float).tolist(),'
                '    ''lambda_head'': np.asarray(sim.lambda_delta[:5, :], dtype=float).tolist()'
                '})'
            }, newline));

            tc.verifyEqual(payload.actual_network, actNetwork, 'AbsTol', 1e-12);
            tc.verifySize(payload.lambda_head, [5 2]);
            tc.verifyEqual(payload.lambda_head, probMat(1:5,:), 'AbsTol', 1e-8);
        end
    end
end
