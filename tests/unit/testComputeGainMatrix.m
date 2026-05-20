classdef testComputeGainMatrix < matlab.unittest.TestCase
    %TESTCOMPUTEGAINMATRIX verify the Woodbury gain helper.
    %
    % Phase 3 Task 3.4 of the 2026-05-19 nSTAT review action plan.
    %
    % The Woodbury identity used by the helper:
    %   W_u = W_p * (I - (I + sumValMat*W_p) \ (sumValMat*W_p))
    % is algebraically equivalent (when invertible) to:
    %   W_u = inv(inv(W_p) + sumValMat)
    %
    % This test asserts the equivalence on a well-conditioned input,
    % verifies symmetrization, and verifies the singularity flag fires
    % when the result becomes NaN/Inf.

    methods (Test)
        function testEquivalentToDirectInverse(tc)
            % Well-conditioned 3x3 case
            rng(42, 'twister');
            W_p = 0.5*eye(3) + 0.01*(rand(3) + rand(3)');  % SPD
            W_p = 0.5*(W_p + W_p');                         % ensure symmetric
            sumValMat = 0.1*eye(3) + 0.02*rand(3);
            sumValMat = 0.5*(sumValMat + sumValMat');

            [W_u_helper, isSingular] = nstat.decoding.internal.computeGainMatrix(W_p, sumValMat);

            % Direct formula
            W_u_direct = inv(inv(W_p) + sumValMat);
            W_u_direct = 0.5*(W_u_direct + W_u_direct');

            tc.verifyEqual(W_u_helper, W_u_direct, 'AbsTol', 1e-10, ...
                'Helper must match inv(inv(W_p) + sumValMat) to 1e-10');
            tc.verifyFalse(isSingular, ...
                'Well-conditioned input must not trigger singularity flag');
        end

        function testSymmetrization(tc)
            % Output should be exactly symmetric even if input isn't
            W_p = [1 0.1 0; 0.1 1 0.2; 0 0.2 1];
            sumValMat = [0.5 0.05 0; 0.05 0.5 0.1; 0 0.1 0.5];

            W_u = nstat.decoding.internal.computeGainMatrix(W_p, sumValMat);

            tc.verifyEqual(W_u, W_u', 'AbsTol', 0, ...
                'Output must be exactly symmetric (W_u == W_u'')');
        end

        function testSingularityDetection(tc)
            % Pathological case: zero W_p produces NaN, should flag
            W_p = zeros(3);
            sumValMat = eye(3);

            [~, isSingular] = nstat.decoding.internal.computeGainMatrix(W_p, sumValMat);

            tc.verifyTrue(isSingular, ...
                'Zero W_p must produce singularity flag');
        end

        function testMatchesPriorPPAFInlineComputation(tc)
            % Numerical parity: helper must produce the same W_u as the
            % pre-extraction inline computation in PPDecode_update.
            rng(0, 'twister');
            W_p = 0.3*eye(2) + 0.05*rand(2);
            W_p = 0.5*(W_p + W_p');
            sumValMat = 2*eye(2) + 0.1*rand(2);
            sumValMat = 0.5*(sumValMat + sumValMat');

            % Pre-extraction inline computation
            I = eye(size(W_p));
            Wu_inline = W_p*(I - (I + sumValMat*W_p) \ (sumValMat*W_p));
            Wu_inline = 0.5*(Wu_inline + Wu_inline');

            % Helper computation
            W_u_helper = nstat.decoding.internal.computeGainMatrix(W_p, sumValMat);

            tc.verifyEqual(W_u_helper, Wu_inline, 'AbsTol', 0, ...
                'Helper must match pre-extraction inline computation byte-for-byte');
        end
    end
end
