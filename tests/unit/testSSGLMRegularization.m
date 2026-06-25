classdef testSSGLMRegularization < matlab.unittest.TestCase
    %TESTSSGLMREGULARIZATION numerical-health tests for the SSGLM EM
    % init + posterior-covariance update.
    %
    % MATLAB-side regression tests for the two algorithmic bugs fixed in
    % parallel with cajigaslab/nSTAT-python#249:
    %
    %   1. estimateVarianceAcrossTrials propagated -120 empty-bin sentinel
    %      coefficients into Q, exploding the state-noise variance and
    %      blowing up the SSGLM EM even on clean data. The MATLAB version
    %      suffered the same flaw -- the previous "remove zero columns"
    %      pass only filtered exact-zero entries and the magnitude clamp
    %      attempt at line 1464 was commented out.
    %
    %   2. PPSS_EStep posterior-covariance update used a bare inv + eig
    %      flow. For high-rate / sparse-bin units, sumValMat reaches
    %      non-finite magnitudes (lambdaDelta up to e^30 ~ 1e13), making
    %      the inverse non-finite and the eigendecomposition error with
    %      "Eigenvalues did not converge". The fix is a robust PSD inverse
    %      + a physical bound on the log-rate state so a diverged trial
    %      cannot poison the next trial's prior.
    %
    % The SSGLM path was previously only signature-checked in
    % testNstatDecodingSSGLM (PPSS_MStep parity). The EM init + E-step
    % were never exercised end-to-end in unit tests, so neither bug
    % surfaced before they were caught in the Python port.

    methods (Test)

        function testQIsPhysicalOnCleanData(tc)
            %TESTQISPHYSICALONCLEANDATA Q must be finite and O(1) on clean
            % synthetic Poisson trials. Pre-fix Q median was ~1e3-1e4 from
            % the empty-bin sentinel contamination.
            rng(1, 'twister');
            coll = makePoissonTrialColl(40, 12.0, 1.5, 1000.0);

            Q = coll.estimateVarianceAcrossTrials(8, [], 4, 'poisson');

            tc.verifySize(Q, [8 8], 'Q must be (numBasis x numBasis)');
            tc.verifyTrue(all(isfinite(Q(:))), ...
                'Q must be finite (was Inf/NaN with sentinel coefficients in Q init)');
            tc.verifyLessThan(median(diag(Q)), 10.0, ...
                ['Q median must be O(1) on clean stationary data ' ...
                 '(pre-fix: ~1e3-1e4 from -120 sentinel contamination)']);
            tc.verifyGreaterThanOrEqual(min(diag(Q)), 0, ...
                'Q is a variance estimate; entries must be non-negative');
        end

        function testRobustPsdInverseScrubsNonFiniteEntries(tc)
            %TESTROBUSTPSDINVERSESCRUBSNONFINITEENTRIES the helper must
            % return a finite PSD matrix even when the precision input
            % contains NaN/Inf entries (the path that crashed the EM).
            dim = 4;
            invW = eye(dim);
            invW(2,3) = NaN;
            invW(3,4) = Inf;

            W = nstat.decoding.SSGLM.robustPsdInverse(invW, dim);

            tc.verifyTrue(all(isfinite(W(:))), ...
                'robustPsdInverse output must be finite for non-finite input');
            tc.verifyEqual(W, W.', 'AbsTol', 1e-10, ...
                'robustPsdInverse output must be symmetric');
            eigvals = eig(W);
            tc.verifyGreaterThanOrEqual(min(eigvals), -1e-10, ...
                'robustPsdInverse output must be PSD');
        end

        function testRobustPsdInverseMatchesEigFlooredInvOnConditionedInput(tc)
            %TESTROBUSTPSDINVERSEMATCHESEIGFLOOREDINVONCONDITIONEDINPUT
            % On a well-conditioned precision matrix the new helper must
            % be numerically equivalent to the previous flow:
            %     W = inv(invW); [v,d]=eig(W); d(d<=0)=eps; W = v*d*v';
            rng(2, 'twister');
            dim = 5;
            X = randn(dim, dim);
            invW = X*X.' + dim*eye(dim);  % well-conditioned SPD

            W_new = nstat.decoding.SSGLM.robustPsdInverse(invW, dim);

            W_old = inv(invW);
            W_old = 0.5*(W_old + W_old.');
            [v,d] = eig(W_old);
            d(d <= 0) = eps;
            W_old = v*d*v.';
            W_old = 0.5*(W_old + W_old.');

            tc.verifyEqual(W_new, W_old, 'AbsTol', 1e-9, ...
                ['On well-conditioned input, robustPsdInverse must match ' ...
                 'the previous inv+eig-floor flow within round-off']);
        end

        function testPPSSEMSurvivesHighRateBurstyUnit(tc)
            %TESTPPSSEMSURVIVESHIGHRATEBURSTYUNIT high firing rate with
            % silent second-half bins is the pattern that previously made
            % the E-step error with "Eigenvalues did not converge". After
            % the fix, EM completes and the returned states are finite
            % and within the physical bound.
            rng(3, 'twister');
            % 30 trials of bursty 120 Hz in first half, silent second half.
            % The silent bins drive lambdaDelta variance through the roof
            % in the E-step posterior precision.
            coll = makeBurstyHighRateTrialColl(30, 120.0, 1.5, 1000.0);

            % Run a single-iteration EM via the same path as nstColl.ssglm
            % but bypassing the full driver; this isolates the E-step
            % regularization from the M-step / outer EM loop.
            dN = coll.dataToMatrix';
            dN(dN > 1) = 1;
            numBasis = 6;
            delta = 1/coll.sampleRate;
            R = numBasis;
            % Trivial init -- the test is whether the E-step survives.
            A = eye(R);
            Q = 0.01*eye(R);
            x0 = zeros(R,1);
            HkAll = cell(size(dN,1),1);
            for k = 1:size(dN,1)
                HkAll{k} = 0;
            end
            gamma = 0;

            % Pre-fix: this throws "Eigenvalues did not converge" mid-EM.
            % Post-fix: returns finite states bounded at +/- 50.
            [x_K, ~, ~, ~, ~, ~] = nstat.decoding.SSGLM.PPSS_EStep( ...
                A, Q, x0, dN, HkAll, 'poisson', delta, gamma, numBasis);

            tc.verifyTrue(all(isfinite(x_K(:))), ...
                'E-step output state must be finite on the bursty-high-rate path');
            tc.verifyLessThanOrEqual(max(abs(x_K(:))), 50 + 1e-6, ...
                ['log-rate state must respect the physical bound ' ...
                 '(SSGLM_STATE_BOUND = 50; |x| <= 50 ⟺ rate within ' ...
                 '(e^-50, e^50)/delta)']);
        end

    end
end


function coll = makePoissonTrialColl(nTrials, rateHz, durSec, sampleRate)
    % A clean homogeneous-Poisson trial collection. One nspikeTrain per
    % trial. All trials share the same neuron name so the collection
    % represents repeated observations of one neuron (matches
    % helpfiles/nSTATPaperExamples.m and example03 fixture style;
    % distinct names would make RunAnalysisForAllNeurons return a cell
    % instead of a single FitResult, tripping psthGLM:1027).
    nstCellArr = cell(nTrials, 1);
    for i = 1:nTrials
        nSpikes = poissrnd(rateHz * durSec);
        if nSpikes < 1
            nSpikes = 1;
        end
        spikeTimes = sort(rand(1, nSpikes) * durSec);
        nstCellArr{i} = nspikeTrain(spikeTimes, 'n1', 1/sampleRate, ...
            0, durSec);
    end
    coll = nstColl(nstCellArr);
    coll.resample(sampleRate);
    coll.setMaxTime(durSec);
end


function coll = makeBurstyHighRateTrialColl(nTrials, rateHz, durSec, sampleRate)
    % High-rate Poisson burst in the first 40% of each trial, silent in
    % the rest. Silent bins are the pathological pattern that drives the
    % E-step posterior precision to non-finite values in the unregularized
    % flow. Single-neuron-across-trials naming convention (see above).
    nstCellArr = cell(nTrials, 1);
    burstWindow = 0.4 * durSec;
    for i = 1:nTrials
        nSpikes = poissrnd(rateHz * burstWindow);
        if nSpikes < 1
            nSpikes = 1;
        end
        spikeTimes = sort(rand(1, nSpikes) * burstWindow);
        nstCellArr{i} = nspikeTrain(spikeTimes, 'n1', 1/sampleRate, ...
            0, durSec);
    end
    coll = nstColl(nstCellArr);
    coll.resample(sampleRate);
    coll.setMaxTime(durSec);
end
