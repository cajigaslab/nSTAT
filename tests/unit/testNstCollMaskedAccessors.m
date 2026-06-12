classdef testNstCollMaskedAccessors < matlab.unittest.TestCase
    %TESTNSTCOLLMASKEDACCESSORS regression tests for issues #21, #55, #56.
    %
    % - #21 getSpikeTimes uninitialized count when mask excludes neuron 1.
    % - #55 getFieldVal pre-increment leaves a leading-0 in neuronNumbers
    %       and offsets the paired record by one.
    % - #56 getNSTnameFromInd truthy guard (was numSpikeTrains instead of
    %       ind <= numSpikeTrains) missed real out-of-bounds index.

    methods (Static)
        function ns = buildCollection()
            % 3 spike trains with distinct names so getNSTnameFromInd can be checked.
            T = 1.0;
            n1 = nspikeTrain([0.1; 0.3; 0.7], 'unit1', 0.001, 0, T);
            n2 = nspikeTrain([0.2; 0.5; 0.8], 'unit2', 0.001, 0, T);
            n3 = nspikeTrain([0.15; 0.45], 'unit3', 0.001, 0, T);
            ns = nstColl({n1, n2, n3});
        end
    end

    methods (Test)
        function testGetSpikeTimesWithMaskExcludingFirst(tc)
            % #21: mask excludes neuron 1 -> pre-fix code left count
            % undefined when the for-loop hit the body. Post-fix count
            % is hoisted out of the if(i==1) guard.
            nsc = testNstCollMaskedAccessors.buildCollection();
            % Pass mask as a ROW vector so getIndFromMask's find(...) also
            % returns a row vector (MATLAB's `for` iterates columns).
            nsc.setMask([0 1 1]);
            spikeTimes = nsc.getSpikeTimes;
            tc.verifyEqual(numel(spikeTimes), 2, ...
                'Mask excluding neuron 1 should yield 2 cells, not error');
            tc.verifyNotEmpty(spikeTimes{1}, 'first cell holds neuron-2 spikes');
            tc.verifyNotEmpty(spikeTimes{2}, 'second cell holds neuron-3 spikes');
        end

        function testGetFieldValPairedRecords(tc)
            % #55: pre-fix paired records were offset by one with a leading
            % zero in neuronNumbers. Post-fix the parallel arrays are
            % consistent.
            % Use minTime as the probe field: it's a SignalObj-inherited
            % property reliably present in fieldnames and a scalar.
            nsc = testNstCollMaskedAccessors.buildCollection();
            [fieldVal, neuronNumbers] = nsc.getFieldVal('minTime');
            tc.verifyEqual(numel(fieldVal), numel(neuronNumbers), ...
                'fieldVal and neuronNumbers must be the same length');
            tc.verifyFalse(any(neuronNumbers == 0), ...
                'neuronNumbers must have no leading 0 (#55 regression)');
            tc.verifyEqual(neuronNumbers, [1 2 3], ...
                'all three neurons present with consecutive indices');
        end

        function testGetNSTnameFromIndOutOfBounds(tc)
            % #56: pre-fix the truthy guard (`numSpikeTrains` rather than
            % `ind<=numSpikeTrains`) silently passed any positive ind on a
            % non-empty collection, surfacing as a generic MATLAB indexing
            % error rather than a clear bounds diagnostic.
            nsc = testNstCollMaskedAccessors.buildCollection();
            % Within bounds:
            tc.verifyEqual(char(nsc.getNSTnameFromInd(1)), 'unit1');
            tc.verifyEqual(char(nsc.getNSTnameFromInd(3)), 'unit3');
            % Out of bounds:
            tc.verifyError(@() nsc.getNSTnameFromInd(4), ...
                'nstColl:getNSTnameFromInd:OutOfBounds');
            tc.verifyError(@() nsc.getNSTnameFromInd(0), ...
                'nstColl:getNSTnameFromInd:OutOfBounds');
        end
    end
end
