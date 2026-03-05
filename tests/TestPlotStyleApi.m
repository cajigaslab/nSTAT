classdef TestPlotStyleApi < matlab.unittest.TestCase
    %TESTPLOTSTYLEAPI Unit tests for nstat plot style helpers.

    properties (Access = private)
        HadPref (1,1) logical = false
        PreviousStyle char = ''
    end

    methods (TestMethodSetup)
        function snapshotPreference(tc)
            if ispref('nstat', 'PlotStyle')
                tc.HadPref = true;
                tc.PreviousStyle = getpref('nstat', 'PlotStyle');
            else
                tc.HadPref = false;
                tc.PreviousStyle = '';
            end
        end
    end

    methods (TestMethodTeardown)
        function restorePreference(tc)
            if tc.HadPref
                setpref('nstat', 'PlotStyle', tc.PreviousStyle);
            elseif ispref('nstat', 'PlotStyle')
                rmpref('nstat', 'PlotStyle');
            end
        end
    end

    methods (Test)
        function testSetAndGetRoundTrip(tc)
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tools'));
            tc.assumeEqual(exist('nstat.setPlotStyle', 'file'), 2, ...
                'Plot style API not available on this branch.');
            nstat.setPlotStyle('legacy');
            tc.verifyEqual(nstat.getPlotStyle, 'legacy');

            nstat.setPlotStyle('modern');
            tc.verifyEqual(nstat.getPlotStyle, 'modern');
        end

        function testApplyStyleDoesNotCreateLegend(tc)
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tools'));
            tc.assumeEqual(exist('nstat.applyPlotStyle', 'file'), 2, ...
                'Plot style API not available on this branch.');
            f = figure('Visible', 'off');
            c = onCleanup(@()close(f)); %#ok<NASGU>
            ax = axes('Parent', f);
            plot(ax, 1:10, randn(1, 10));

            tc.verifyEmpty(findall(f, 'Type', 'Legend'));
            nstat.applyPlotStyle(ax, 'Style', 'modern');
            tc.verifyEmpty(findall(f, 'Type', 'Legend'));
        end
    end
end
