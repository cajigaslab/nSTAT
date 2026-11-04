classdef testGenerateUnitImpulseBasisSampleRate < matlab.unittest.TestCase
    %TESTGENERATEUNITIMPULSEBASISSAMPLERATE regression test for the
    % nstColl.generateUnitImpulseBasis default-argument guard.
    %
    % The static method takes 4 inputs. The old guard was nargin<5, which
    % is always true, so a caller's sampleRate was always replaced by
    % 1000 Hz. The guard is now nargin<4 (or an empty sampleRate).

    methods (Test)
        function testExplicitSampleRateIsUsed(tc)
            b = nstColl.generateUnitImpulseBasis(0.1, 0, 1, 500);
            tc.verifyEqual(numel(b.time), 501, ...
                'A 500 Hz basis over [0,1] s must have 501 samples');
            tc.verifyEqual(b.sampleRate, 500, 'AbsTol', 1e-9);
        end

        function testDefaultSampleRateIs1000(tc)
            b = nstColl.generateUnitImpulseBasis(0.1, 0, 1);
            tc.verifyEqual(numel(b.time), 1001);
            tc.verifyEqual(b.sampleRate, 1000, 'AbsTol', 1e-9);
        end

        function testEmptySampleRateUsesDefault(tc)
            b = nstColl.generateUnitImpulseBasis(0.1, 0, 1, []);
            tc.verifyEqual(numel(b.time), 1001);
        end

        function testBasisColumnsPartitionTime(tc)
            % Each sample belongs to exactly one unit pulse.
            b = nstColl.generateUnitImpulseBasis(0.25, 0, 1, 200);
            tc.verifyEqual(size(b.data, 2), 4);
            tc.verifyEqual(sum(b.data, 2), ones(numel(b.time), 1));
        end
    end
end
