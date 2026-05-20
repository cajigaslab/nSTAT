classdef testSignalObjSpectralModernization < matlab.unittest.TestCase
    %TESTSIGNALOBJSPECTRALMODERNIZATION verify SignalObj.periodogram and
    % .MTMspectrum work on R2014a+ (no longer use removed
    % spectrum.periodogram / dspdata.psd APIs).
    %
    % Phase 3 Task 3.7 of the 2026-05-19 nSTAT review action plan.

    properties (Access = private)
        SignalObj1D
        SignalObj2D
        OrigVisibility
    end

    methods (TestClassSetup)
        function suppressFigures(tc)
            tc.OrigVisibility = get(groot, 'defaultFigureVisible');
            set(groot, 'defaultFigureVisible', 'off');
        end
    end

    methods (TestClassTeardown)
        function restoreFigures(tc)
            set(groot, 'defaultFigureVisible', tc.OrigVisibility);
            close all;
        end
    end

    methods (TestMethodSetup)
        function buildSignals(tc)
            rng(0, 'twister');
            T = 1.0;
            fs = 1000;
            t = (0:1/fs:T-1/fs)';
            % Sine + noise
            x1 = sin(2*pi*50*t) + 0.1*randn(size(t));
            tc.SignalObj1D = SignalObj(t, x1, 'sig1', 'time', 's', 'V', {'x'});

            x2 = sin(2*pi*100*t) + 0.1*randn(size(t));
            tc.SignalObj2D = SignalObj(t, [x1, x2], 'sig2', 'time', 's', 'V', {'x','y'});
        end
    end

    methods (Test)
        function testPeriodogramRunsAndReturnsStruct(tc)
            % Pre-modernization this would crash with "spectrum.periodogram
            % has been removed".
            result = tc.SignalObj1D.periodogram();
            tc.assertClass(result, 'cell');
            tc.assertNumElements(result, 1);
            tc.assertClass(result{1}, 'struct');
            tc.verifyTrue(isfield(result{1}, 'Pxx'));
            tc.verifyTrue(isfield(result{1}, 'f'));
            tc.verifyEqual(numel(result{1}.Pxx), numel(result{1}.f));
        end

        function testPeriodogramPeakAt50Hz(tc)
            % Sanity: 50 Hz sine input should have peak PSD at ~50 Hz.
            result = tc.SignalObj1D.periodogram();
            [~, peakIdx] = max(result{1}.Pxx);
            peakFreq = result{1}.f(peakIdx);
            tc.verifyEqual(peakFreq, 50, 'AbsTol', 5, ...
                'Peak frequency must be near 50 Hz');
        end

        function testMTMspectrumRunsAndReturnsStruct(tc)
            result = tc.SignalObj1D.MTMspectrum();
            tc.assertClass(result, 'cell');
            tc.assertClass(result{1}, 'struct');
            tc.verifyTrue(isfield(result{1}, 'Pxx'));
            tc.verifyTrue(isfield(result{1}, 'Pxxc'));
            tc.verifyTrue(isfield(result{1}, 'f'));
            % Pxxc is N x 2 (lower + upper bounds)
            tc.verifyEqual(size(result{1}.Pxxc, 2), 2);
        end

        function testPeriodogramTwoChannels(tc)
            result = tc.SignalObj2D.periodogram();
            tc.assertNumElements(result, 2);
            tc.verifyClass(result{1}, 'struct');
            tc.verifyClass(result{2}, 'struct');
        end
    end
end
