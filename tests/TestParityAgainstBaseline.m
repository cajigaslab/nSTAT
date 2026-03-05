classdef TestParityAgainstBaseline < matlab.unittest.TestCase
    %TESTPARITYAGAINSTBASELINE Integration parity tests for paper examples.

    properties (Access = private)
        RootDir char
    end

    methods (TestClassSetup)
        function setup(tc)
            tc.RootDir = fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(tc.RootDir, 'tools'));
            cd(tc.RootDir);
        end
    end

    methods (Test)
        function testLegacyParity(tc)
            tc.assumeFalse(skipParityTests, 'Skipping parity integration tests via NSTAT_SKIP_PARITY_TESTS');
            report = check_parity_against_baseline('Seed', 0, 'Style', 'legacy', 'CheckPixels', false);
            tc.verifyTrue(report.passed);
            tc.verifyTrue(report.numeric.passed);
            tc.verifyTrue(report.plotStructure.passed);
        end

        function testModernParity(tc)
            tc.assumeFalse(skipParityTests, 'Skipping parity integration tests via NSTAT_SKIP_PARITY_TESTS');
            report = check_parity_against_baseline('Seed', 0, 'Style', 'modern', 'CheckPixels', false);
            tc.verifyTrue(report.passed);
            tc.verifyTrue(report.numeric.passed);
            tc.verifyTrue(report.plotStructure.passed);
        end
    end
end

function tf = skipParityTests
val = getenv('NSTAT_SKIP_PARITY_TESTS');
tf = strcmpi(strtrim(val), '1') || strcmpi(strtrim(val), 'true');
end

