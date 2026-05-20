classdef testNstatDecodingSSGLM < matlab.unittest.TestCase
    %TESTNSTATDECODINGSSGLM verify the extracted nstat.decoding.SSGLM class
    % shims emit deprecation warnings and preserve numerical behavior on
    % the smallest, easily-fixturable method.
    %
    % The four PPSS_* methods (EMFB, EM, EStep, MStep) all take 8-10
    % positional arguments and exercise a forward-backward EM loop. The
    % smallest is PPSS_MStep, which is a closed-form M-step over the
    % posterior moments (x_K, W_K) and history covariate matrix HkAll.
    % We exercise PPSS_MStep with windowTimes=[] so that the Newton-
    % Raphson inner loop (only relevant when history coefficients are
    % being updated) is bypassed; this keeps the test deterministic and
    % free of optimization noise.
    %
    % The end-to-end EM loop is exercised through helpfiles/example05
    % (the Czanner 2008 reproduction); a stable parity fixture for the
    % full EMFB driver here would be brittle, so we restrict to
    % PPSS_MStep.
    %
    % Phase 3 Task 3.2 Step F of the 2026-05-19 nSTAT review action plan.

    methods (Test)
        function testMStepShimEmitsDeprecationWarning(tc)
            %TESTMSTEPSHIMEMITSDEPRECATIONWARNING
            % Verify DecodingAlgorithms.PPSS_MStep emits its deprecation
            % warning before any deeper logic runs. We pass synthetic
            % inputs of the minimal valid shape; the shim must warn
            % whether or not the inner body succeeds.
            tc.verifyWarning(@() callPPSSMStepMinimal(), ...
                'nSTAT:deprecated:DecodingAlgorithms', ...
                'PPSS_MStep shim must emit deprecation warning');
        end

        function testMStepNumericalParity(tc)
            %TESTMSTEPNUMERICALPARITY
            % Verify the shim and the new class produce bit-identical
            % output on a small synthetic input. windowTimes=[] bypasses
            % the Newton-Raphson history-coefficient update so the test
            % exercises the deterministic Q-update only.

            warnState = warning('off', 'nSTAT:deprecated:DecodingAlgorithms');
            cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>

            rng(0, 'twister');
            T = 50; numNeurons = 1; numBasis = 2;
            dN = double(rand(numNeurons, T) > 0.95);
            HkAll = cell(numNeurons, 1);
            HkAll{1} = zeros(T, 0);  % no history covariates
            fitType = 'poisson';
            x_K = zeros(numBasis, T);
            W_K = repmat(0.01*eye(numBasis), [1 1 T]);
            gamma = zeros(numNeurons, 0);  % no history coeffs
            delta = 0.001;
            sumXkTerms = 0.05 * eye(numBasis);  % positive-definite
            windowTimes = [];

            [Qhat_new, gamma_new]   = nstat.decoding.SSGLM.PPSS_MStep( ...
                dN, HkAll, fitType, x_K, W_K, gamma, delta, sumXkTerms, windowTimes);
            [Qhat_shim, gamma_shim] = DecodingAlgorithms.PPSS_MStep( ...
                dN, HkAll, fitType, x_K, W_K, gamma, delta, sumXkTerms, windowTimes);

            tc.verifyEqual(Qhat_new, Qhat_shim, 'AbsTol', 1e-12, ...
                'shim and new class must produce identical Qhat');
            tc.verifyEqual(gamma_new, gamma_shim, 'AbsTol', 1e-12, ...
                'shim and new class must produce identical gamma');
        end
    end
end

function callPPSSMStepMinimal()
    %CALLPPSSMSTEPMINIMAL invoke the shim with minimal valid inputs so the
    % warning fires; we wrap in try/catch because we only care about the
    % warning, not the downstream success of the math.
    try
        dN = zeros(1, 10);
        HkAll = {zeros(10, 0)};
        x_K = zeros(2, 10);
        W_K = repmat(eye(2), [1 1 10]);
        DecodingAlgorithms.PPSS_MStep(dN, HkAll, 'poisson', x_K, W_K, ...
            zeros(1, 0), 0.001, eye(2), []);
    catch
        % ignore -- warning fires before any error
    end
end
