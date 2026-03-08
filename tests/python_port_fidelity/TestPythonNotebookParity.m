classdef TestPythonNotebookParity < matlab.unittest.TestCase
    %TESTPYTHONNOTEBOOKPARITY Validate Python notebook/helpfile parity from MATLAB.

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
        function testNotebookAuditReportsCoreHelpfileParity(tc)
            payload = helpers.runPythonJson(strjoin({
                'import json'
                'from pathlib import Path'
                'import yaml'
                sprintf('repo = Path(r''%s'')', strrep(tc.PythonRepo, '\', '\\'))
                'entries = yaml.safe_load((repo / ''parity'' / ''notebook_fidelity.yml'').read_text())[''items'']'
                'topics = {''TrialExamples'', ''AnalysisExamples'', ''nSTATPaperExamples'', ''PPSimExample'', ''NetworkTutorial'', ''ValidationDataSet''}'
                'selected = [entry for entry in entries if entry[''topic''] in topics]'
                'json_text = json.dumps(selected)'
            }, newline));

            tc.verifyNumElements(payload, 6);
            for k = 1:numel(payload)
                tc.verifyTrue(any(strcmp(string(payload(k).fidelity_status), ["high_fidelity", "exact"])));
                tc.verifyEqual(payload(k).section_delta, 0);
                tc.verifyEqual(payload(k).figure_delta, 0);
                tc.verifyFalse(payload(k).python_contains_placeholders);
                tc.verifyFalse(payload(k).python_contains_tracker_only_cells);
            end
        end

        function testNotebookAuditPromotesStimulusDecode2DToHighFidelity(tc)
            payload = helpers.runPythonJson(strjoin({
                'import json'
                'from pathlib import Path'
                'import yaml'
                sprintf('repo = Path(r''%s'')', strrep(tc.PythonRepo, '\', '\\'))
                'entries = yaml.safe_load((repo / ''parity'' / ''notebook_fidelity.yml'').read_text())[''items'']'
                'entry = next(item for item in entries if item[''topic''] == ''StimulusDecode2D'')'
                'json_text = json.dumps(entry)'
            }, newline));

            tc.verifyTrue(any(strcmp(string(payload.fidelity_status), ["high_fidelity", "exact"])));
            tc.verifyEqual(payload.section_delta, 0);
            tc.verifyEqual(payload.figure_delta, 0);
            tc.verifyFalse(payload.python_contains_placeholders);
            tc.verifyFalse(payload.python_contains_tracker_only_cells);
        end

        function testRepresentativePythonNotebookExecutionFromMatlab(tc)
            payload = helpers.runPythonJson(strjoin({
                'import json'
                'import subprocess'
                'import sys'
                'from pathlib import Path'
                sprintf('repo = Path(r''%s'')', strrep(tc.PythonRepo, '\', '\\'))
                'cmd = [sys.executable, ''tools/notebooks/run_notebooks.py'', ''--group'', ''full'', ''--topics'', ''TrialExamples,PPSimExample'', ''--timeout'', ''1200'']'
                'proc = subprocess.run(cmd, cwd=repo, capture_output=True, text=True)'
                'json_text = json.dumps({'
                '    ''returncode'': int(proc.returncode),'
                '    ''stdout_tail'': proc.stdout.splitlines()[-10:],'
                '    ''stderr_tail'': proc.stderr.splitlines()[-10:]'
                '})'
            }, newline));

            tc.verifyEqual(payload.returncode, 0, sprintf('Notebook runner failed.\nSTDOUT:\n%s\nSTDERR:\n%s', strjoin(string(payload.stdout_tail), newline), strjoin(string(payload.stderr_tail), newline)));
        end
    end
end
