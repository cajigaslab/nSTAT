classdef testAnalysisGrangerCoeffMask < matlab.unittest.TestCase
    %TESTANALYSISGRANGERCOEFFMASK regression test for issue #51.
    %
    % Analysis.computeGrangerCausalityMatrix used
    %   coeffInd = strfind(labels, ['neuron_' num2str(j) ':']);
    %   gammaVals = coeffMat(~isempty(coeffInd));
    % `strfind` on a cellarray returns a cellarray; `~isempty` on a
    % cellarray returns a SCALAR (true if the cellarray is non-empty),
    % so `coeffMat(~isempty(coeffInd))` was equivalent to
    % `coeffMat(1)` and only the first coefficient was ever consumed.
    % The fix uses `~cellfun(@isempty, strfind(...))` which returns a
    % per-label logical mask.
    %
    % This is a unit test of the mask-building pattern alone, not the
    % full Granger pipeline (which is an integration test).

    methods (Test)
        function testMaskMatchesAllOccurrencesOfPrefix(tc)
            labels = {'1:[0]', '1:[1]', '2:[0]', '1:[2]', '3:[0]'};
            target = 1;
            mask = ~cellfun(@isempty, strfind(labels, [num2str(target) ':[']));
            tc.verifyEqual(mask, [true true false true false], ...
                'mask must include every label whose name starts with the target neuron prefix');
        end

        function testMaskEmptyWhenPrefixAbsent(tc)
            labels = {'2:[0]', '3:[0]'};
            mask = ~cellfun(@isempty, strfind(labels, '1:['));
            tc.verifyEqual(mask, [false false]);
        end

        function testSumOverMaskedCoeffs(tc)
            labels = {'1:[0]', '1:[1]', '2:[0]', '1:[2]'};
            coeffMat = [0.5; -0.2; 99.0; 0.4]; % neuron-1 contributes 3 coeffs; their signed sum is 0.7
            mask = ~cellfun(@isempty, strfind(labels, '1:['));
            gammaVals = coeffMat(mask);
            tc.verifyEqual(numel(gammaVals), 3, ...
                'must consume all 3 neuron-1 coefficients (pre-fix only consumed the first)');
            tc.verifyEqual(sum(gammaVals), 0.7, 'AbsTol', 1e-12);
        end
    end
end
