classdef testPPAFGammaBroadcast < matlab.unittest.TestCase
    %TESTPPAFGAMMABROADCAST regression test for issue #20.
    %
    % +nstat/+decoding/PPAF.m had the multi-cell single-gamma broadcast
    % bug at two sites (lines 493 and 668). The code reads:
    %     for c=1:C
    %         ...build HkAll(:,:,c)...
    %     end
    %     if(size(gamma,2)==1 && C>1)
    %         gammaNew(:,c) = gamma;
    %     ...
    % `c` retains its post-loop value (C), so only the LAST column of
    % gammaNew was ever populated. All earlier columns remained zero.
    % Fix uses repmat(gamma, 1, C) instead.
    %
    % This is a unit test of the broadcast pattern alone: we can't call
    % PPDecodeFilter without a full Trial/Analysis setup, but we can
    % verify the canonical pattern produces a full-rank matrix while
    % the bug pattern produces zeros in every column except the last.

    methods (Test)
        function testRepmatPopulatesAllColumns(tc)
            gamma = [0.3; -0.1; 0.2];     % single-cell gamma (3 history coeffs)
            C = 4;                          % four cells
            gammaNew = repmat(gamma, 1, C);
            tc.verifyEqual(size(gammaNew), [3 4]);
            for col = 1:C
                tc.verifyEqual(gammaNew(:,col), gamma, 'AbsTol', 1e-15, ...
                    sprintf('column %d must equal the source gamma', col));
            end
        end

        function testPreFixPatternOnlyFillsLastColumn(tc)
            % Documents the historical bug shape: writing gammaNew(:,c)
            % where c is the post-for-loop variable equal to C only
            % populates the last column. This test does NOT exercise the
            % shipped code; it verifies our understanding of the bug shape
            % so future readers can see why repmat is the right fix.
            gamma = [0.3; -0.1; 0.2];
            C = 4;
            for c = 1:C
                % simulate the per-cell pre-loop body that doesn't touch gammaNew
            end
            % c retains the value 4 here; mimic the pre-fix line:
            gammaNew = zeros(numel(gamma), C);
            gammaNew(:,c) = gamma;
            tc.verifyEqual(gammaNew(:,1), zeros(numel(gamma),1), ...
                'pre-fix shape leaves column 1 zero (regression doc)');
            tc.verifyEqual(gammaNew(:,end), gamma, ...
                'pre-fix shape only fills the last column (regression doc)');
        end
    end
end
