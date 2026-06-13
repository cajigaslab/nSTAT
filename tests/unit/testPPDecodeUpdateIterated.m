classdef testPPDecodeUpdateIterated < matlab.unittest.TestCase
 %TESTPPDECODEUPDATEITERATED Iterated-Laplace PPAF update unit tests.
 %
 % Validates Phase 4 Task 4.1 of the 2026-05-19 nSTAT review action plan:
 % the iterated PPAF update step that Newton-iterates to the posterior
 % mode (full Laplace approximation), as opposed to the one-step
 % extended-Kalman linearization PPDecode_update performs.
 %
 % Tests cover both the general CIF path (PPDecode_updateIterated) and
 % the linear CIF path (PPDecode_updateLinearIterated):
 %
 % 1. K = 1 parity: with maxIters = 1 the iterated routine must match
 % its single-step counterpart bit-for-bit (the prior-gradient
 % correction term vanishes at the first iterate, x^(0) = x_p).
 % 2. Convergence: with maxIters large, the iteration converges in
 % fewer steps than the cap (the L2 tolerance triggers an early
 % return).
 % 3. Stationarity (Bayes-mode condition): at convergence the gradient
 % of the negative log-posterior is approximately zero, i.e.
 % W_p^{-1} * (x_u - x_p) ≈ grad ell(x_u).
 %
 % Ref: Haslinger-Pipa-Brown 2010.

 methods (Test)
 function testLinearMaxItersOneMatchesSingleStep(tc)
 % Poisson linear-CIF case. maxIters = 1 must reproduce
 % PPDecode_updateLinear exactly (to 1e-12).
 rng(0, 'twister');
 ns = 3; % state dimension
 C = 2; % number of channels
 N = 5; % number of time bins
 x_p = [0.2; -0.1; 0.05];
 W_p = 0.05 * eye(ns);
 mu = [log(0.005); log(0.008)];
 beta = 0.3 * randn(ns, C);
 dN = double(rand(C, N) < 0.05);
 time_index = N;

 [x_u_single, W_u_single, ld_single] =...
 nstat.decoding.PPAF.PPDecode_updateLinear(...
 x_p, W_p, dN, mu, beta, 'poisson', [], [], time_index);

 [x_u_iter, W_u_iter, ld_iter, nIter] =...
 nstat.decoding.PPAF.PPDecode_updateLinearIterated(...
 x_p, W_p, dN, mu, beta, 'poisson', [], [], time_index, 1);

 tc.verifyEqual(nIter, 1, 'maxIters=1 must perform exactly one iteration');
 tc.verifyEqual(x_u_iter, x_u_single, 'AbsTol', 1e-12,...
 'K=1 iterated x_u must match single-step PPDecode_updateLinear');
 tc.verifyEqual(W_u_iter, W_u_single, 'AbsTol', 1e-12,...
 'K=1 iterated W_u must match single-step PPDecode_updateLinear');
 tc.verifyEqual(ld_iter, ld_single, 'AbsTol', 1e-12,...
 'K=1 iterated lambdaDeltaMat must match single-step');
 end

 function testLinearBinomialMaxItersOneMatchesSingleStep(tc)
 % Binomial linear-CIF case. Same K=1 parity assertion.
 rng(1, 'twister');
 ns = 2;
 C = 2;
 N = 4;
 x_p = [0.1; 0.0];
 W_p = 0.08 * eye(ns);
 mu = [-2.0; -1.5];
 beta = 0.4 * randn(ns, C);
 dN = double(rand(C, N) < 0.1);
 time_index = N;

 [x_u_single, W_u_single] =...
 nstat.decoding.PPAF.PPDecode_updateLinear(...
 x_p, W_p, dN, mu, beta, 'binomial', [], [], time_index);
 [x_u_iter, W_u_iter, ~, nIter] =...
 nstat.decoding.PPAF.PPDecode_updateLinearIterated(...
 x_p, W_p, dN, mu, beta, 'binomial', [], [], time_index, 1);

 tc.verifyEqual(nIter, 1);
 tc.verifyEqual(x_u_iter, x_u_single, 'AbsTol', 1e-12,...
 'K=1 iterated binomial x_u must match single-step');
 tc.verifyEqual(W_u_iter, W_u_single, 'AbsTol', 1e-12,...
 'K=1 iterated binomial W_u must match single-step');
 end

 function testLinearIteratedConverges(tc)
 % maxIters large should hit the L2 tolerance early. We assert
 % nIter < maxIters and the converged x_u sits at a Newton fixed
 % point (gradient of -log p(x|y) is near zero).
 rng(2, 'twister');
 ns = 2;
 C = 3;
 N = 6;
 x_p = [0.4; -0.3];
 W_p = 0.1 * eye(ns);
 mu = [log(0.01); log(0.02); log(0.015)];
 beta = 0.6 * randn(ns, C);
 dN = double(rand(C, N) < 0.15);
 time_index = N;
 maxIters = 50;
 tol = 1e-10;

 [x_u, W_u, ~, nIter] =...
 nstat.decoding.PPAF.PPDecode_updateLinearIterated(...
 x_p, W_p, dN, mu, beta, 'poisson', [], [], time_index,...
 maxIters, tol);

 tc.verifyLessThan(nIter, maxIters,...
 'Iteration should converge well before the maxIters cap');
 tc.verifyTrue(all(isfinite(x_u(:))), 'x_u must be finite at convergence');
 tc.verifyTrue(all(isfinite(W_u(:))), 'W_u must be finite at convergence');

 % Bayes-mode condition: gradient of negative log-posterior is 0.
 % grad F(x_u) = W_p^{-1}*(x_u - x_p) - grad ell(x_u)
 % For Poisson linear CIF: grad ell(x_u) =
 % sum_c beta_c * (dN_c - exp(mu_c + beta_c' x_u))
 % which is exactly the `sumValVec` PPDecode_updateLinear builds.
 lambdaDelta = exp(mu + beta' * x_u);
 gradLogL = sum(repmat((dN(:,time_index) - lambdaDelta)', ns, 1).* beta, 2);
 priorGrad = W_p \ (x_u - x_p);
 stationarityResidual = norm(priorGrad - gradLogL);

 tc.verifyLessThan(stationarityResidual, 1e-6,...
 ['Converged x_u must satisfy Bayes-mode condition '...
 'W_p^{-1}*(x_u - x_p) = grad ell(x_u)']);
 end

 function testCIFMaxItersOneMatchesSingleStep(tc)
 % General CIF (symbolic) path. K=1 parity against PPDecode_update.
 % Uses the symbolic CIF class because PPDecode_update requires
 % `isa(lambdaIn, 'CIF')` and LinearCIF is not a CIF subclass.
 rng(3, 'twister');
 beta = [log(0.005), 0.5]; % [intercept(log-rate), coeff]
 Xnames = {'one', 'x'};
 stimNames = {'x'};
 fitType = 'poisson';
 cif = CIF(beta, Xnames, stimNames, fitType);

 ns = 1;
 N = 4;
 x_p = 0.3;
 W_p = 0.05;
 dN = double(rand(1, N) < 0.05);
 binwidth = 0.001;
 time_index = N;

 [x_u_single, W_u_single, ld_single] =...
 nstat.decoding.PPAF.PPDecode_update(...
 x_p, W_p, dN, cif, binwidth, time_index);
 [x_u_iter, W_u_iter, ld_iter, nIter] =...
 nstat.decoding.PPAF.PPDecode_updateIterated(...
 x_p, W_p, dN, cif, binwidth, time_index, 1);

 tc.verifyEqual(nIter, 1, 'maxIters=1 must perform exactly one iteration');
 tc.verifyEqual(x_u_iter, x_u_single, 'AbsTol', 1e-10,...
 'K=1 iterated x_u must match PPDecode_update (general CIF)');
 tc.verifyEqual(W_u_iter, W_u_single, 'AbsTol', 1e-10,...
 'K=1 iterated W_u must match PPDecode_update (general CIF)');
 tc.verifyEqual(ld_iter, ld_single, 'AbsTol', 1e-10,...
 'K=1 iterated lambdaDeltaMat must match PPDecode_update');
 end

 function testInvalidMaxItersRejected(tc)
 % Defensive: maxIters < 1 must error out cleanly rather than
 % silently returning x_p.
 x_p = [0; 0];
 W_p = eye(2);
 mu = log(0.005);
 beta = [0.3; 0.2];
 dN = 0;

 tc.verifyError(...
 @() nstat.decoding.PPAF.PPDecode_updateLinearIterated(...
 x_p, W_p, dN, mu, beta, 'poisson', [], [], 1, 0),...
 'nSTAT:PPDecodeUpdateLinearIterated:InvalidMaxIters');
 end
 end
end
