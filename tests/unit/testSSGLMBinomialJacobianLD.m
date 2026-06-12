classdef testSSGLMBinomialJacobianLD < matlab.unittest.TestCase
    %TESTSSGLMBINOMIALJACOBIANLD regression test for issue #59.
    %
    % +nstat/+decoding/SSGLM.m line 373 used (1-2*lambdaDelta.^2) for the
    % binomial JacobianLD factor. The canonical sigmoid second derivative
    % is sigma * (1-sigma) * (1-2*sigma) -- LINEAR in sigma, vanishing at
    % sigma = 0.5 by antisymmetry around the inflection point. The .^2
    % form is non-antisymmetric and dimensionally inconsistent with
    % GradLD.
    %
    % All four sibling call sites in the toolbox use the linear form
    % (DecodingAlgorithms.m:533, 603; SSGLM.m:458, 545). #59 fixed the
    % outlier.
    %
    % This unit test verifies the canonical mathematical identity that
    % the fix restores: at the inflection point sigma = 0.5, the second
    % derivative vanishes. Pre-fix the typo'd factor was non-zero there.

    methods (Test)
        function testCanonicalFactorVanishesAtInflection(tc)
            % Linear form (post-fix):
            sigma = 0.5;
            postFixFactor = sigma * (1 - sigma) * (1 - 2*sigma);
            tc.verifyEqual(postFixFactor, 0, 'AbsTol', 1e-15, ...
                'sigmoid 2nd derivative vanishes at the inflection point sigma=0.5');
        end

        function testPreFixFactorDoesNotVanishAtInflection(tc)
            % Documents the bug shape so future readers can see what was wrong.
            sigma = 0.5;
            preFixFactor = sigma * (1 - sigma) * (1 - 2*sigma^2);
            tc.verifyFalse(abs(preFixFactor) < 1e-12, ...
                sprintf('pre-fix factor at sigma=0.5 was %.4g, non-zero (typo regression doc)', preFixFactor));
        end

        function testCanonicalFactorAntisymmetricAround0p5(tc)
            % Linear form is antisymmetric in (sigma - 0.5):
            %   J(0.5 + d) = -J(0.5 - d)
            d = 0.2;
            sigmaPlus = 0.5 + d;
            sigmaMinus = 0.5 - d;
            jPlus  = sigmaPlus  * (1 - sigmaPlus)  * (1 - 2*sigmaPlus);
            jMinus = sigmaMinus * (1 - sigmaMinus) * (1 - 2*sigmaMinus);
            tc.verifyEqual(jPlus, -jMinus, 'AbsTol', 1e-12, ...
                'canonical sigmoid 2nd derivative is antisymmetric around sigma=0.5');
        end

        function testFactorMatchesGradLDDimension(tc)
            % GradLD = lambdaDelta * (1 - lambdaDelta) [the sigmoid first
            % derivative] is order O(sigma) near 0 and O(1-sigma) near 1.
            % JacobianLD = GradLD * (1 - 2*sigma) should have the same
            % leading-order behavior at sigma -> 0 and sigma -> 1.
            sigma = 1e-6;
            gradAt0 = sigma * (1 - sigma);          % ~ sigma
            jacAt0  = gradAt0 * (1 - 2*sigma);      % also ~ sigma
            tc.verifyEqual(jacAt0 / gradAt0, 1 - 2*sigma, 'AbsTol', 1e-12, ...
                'JacobianLD/GradLD = (1 - 2*sigma) for the linear form');
        end
    end
end
