classdef TestCleanRoomBoundary < matlab.unittest.TestCase
    %TESTCLEANROOMBOUNDARY Ensure MATLAB-side Python usage stays in the harness.

    properties (Access = private)
        RootDir char
        AllowedPrefixes cell
    end

    methods (TestClassSetup)
        function setup(tc)
            tc.RootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            tc.AllowedPrefixes = {
                fullfile(tc.RootDir, 'tests', 'python_port_fidelity')
                fullfile(tc.RootDir, 'tools', 'python')
            };
        end
    end

    methods (Test)
        function testPythonBridgeCallsAreConfinedToHarnessPaths(tc)
            patterns = {
                'pyenv\s*\('
                'pyrun\s*\('
                '(?<!\.)\bpy\.[A-Za-z_]\w*'
                'system\s*\([^)]*python'
            };
            files = dir(fullfile(tc.RootDir, '**', '*.m'));
            violations = strings(0, 1);

            for idx = 1:numel(files)
                path = fullfile(files(idx).folder, files(idx).name);
                if tc.isAllowedPath(path)
                    continue;
                end
                text = fileread(path);
                if any(cellfun(@(pat) ~isempty(regexp(text, pat, 'once')), patterns))
                    violations(end + 1, 1) = string(path); %#ok<AGROW>
                end
            end

            tc.verifyEmpty(violations, sprintf('Python bridge usage escaped the harness:\n%s', strjoin(violations, newline)));
        end
    end

    methods (Access = private)
        function tf = isAllowedPath(tc, path)
            tf = false;
            for idx = 1:numel(tc.AllowedPrefixes)
                prefix = char(tc.AllowedPrefixes{idx});
                if startsWith(path, prefix)
                    tf = true;
                    return;
                end
            end
        end
    end
end

