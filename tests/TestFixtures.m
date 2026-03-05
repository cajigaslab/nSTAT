classdef TestFixtures < matlab.unittest.TestCase
    %TESTFIXTURES Validate that baseline fixture files exist.

    properties (Constant, Access = private)
        RequiredFiles = {
            fullfile('fixtures', 'baseline_numeric', 'nSTATPaperExamples_numeric_baseline.mat')
            fullfile('fixtures', 'baseline_numeric', 'nSTATPaperExamples_numeric_baseline.json')
            fullfile('fixtures', 'baseline_plot_structure.json')
            fullfile('fixtures', 'baseline_figures_legacy', 'figure_001.png')
            };
    end

    methods (Test)
        function testBaselineFilesPresent(tc)
            rootDir = fileparts(fileparts(mfilename('fullpath')));
            for i = 1:numel(tc.RequiredFiles)
                p = fullfile(rootDir, tc.RequiredFiles{i});
                tc.verifyEqual(exist(p, 'file'), 2, sprintf('Missing fixture file: %s', p));
            end
        end
    end
end

