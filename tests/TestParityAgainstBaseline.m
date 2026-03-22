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
            tc.assumeFalse(baselineFixtureIsLfsPointer(tc.RootDir), ...
                'Baseline .mat fixture is a Git LFS pointer (run git lfs pull to resolve)');
            report = check_parity_against_baseline('Seed', 0, 'Style', 'legacy', 'CheckPixels', false);
            tc.verifyTrue(report.passed);
            tc.verifyTrue(report.numeric.passed);
            tc.verifyTrue(report.plotStructure.passed);
        end

        function testModernParity(tc)
            tc.assumeFalse(skipParityTests, 'Skipping parity integration tests via NSTAT_SKIP_PARITY_TESTS');
            tc.assumeFalse(baselineFixtureIsLfsPointer(tc.RootDir), ...
                'Baseline .mat fixture is a Git LFS pointer (run git lfs pull to resolve)');
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

function tf = baselineFixtureIsLfsPointer(rootDir)
%BASELINEFIXTUREISLFSPOINTER True when the numeric baseline .mat is a Git LFS pointer.
matPath = fullfile(rootDir, 'fixtures', 'baseline_numeric', ...
    'nSTATPaperExamples_numeric_baseline.mat');
tf = false;
if exist(matPath, 'file') ~= 2
    tf = true;
    return;
end
fid = fopen(matPath, 'r');
if fid == -1
    tf = true;
    return;
end
header = fread(fid, 40, '*char')';
fclose(fid);
tf = contains(header, 'version https://git-lfs');
end

