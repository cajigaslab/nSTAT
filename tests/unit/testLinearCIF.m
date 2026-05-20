classdef testLinearCIF < matlab.unittest.TestCase
    %TESTLINEARCIF Verify LinearCIF matches symbolic CIF on canonical-link cases.
    %
    % Phase 3 Task 3.5 of the 2026-05-19 nSTAT review action plan. LinearCIF
    % is a drop-in replacement for CIF that implements closed-form
    % canonical-link Poisson (log link) and binomial (logit link)
    % derivatives. These tests assert numerical agreement with the
    % symbolic CIF implementation at 1e-12 across all 5 eval methods
    % used by nstat.decoding.PPAF.PPDecode_update.

    methods (Test)
        function testPoissonAgreementNoHistory(tc)
            % Build a Poisson CIF with log link: log(lambda*delta) = X*beta.
            % varIn includes an intercept ('one') and a stimulus ('x'); the
            % expandStimToVarIn path fills the intercept with 1.0. Matches
            % the canonical usage pattern in helpfiles/DecodingExample.m.
            beta      = [-2.3, 0.7];                    % [intercept, stim]
            Xnames    = {'one', 'x'};
            stimNames = {'x'};
            fitType   = 'poisson';

            cif_sym = CIF(beta, Xnames, stimNames, fitType);
            cif_lin = LinearCIF(beta, Xnames, stimNames, fitType);

            stimPoints = [-1.2, -0.3, 0.0, 0.4, 1.5, 3.0];
            for sp = stimPoints
                tc.compareAll(cif_sym, cif_lin, sp);
            end
        end

        function testBinomialAgreementNoHistory(tc)
            % Same structure but fitType = 'binomial'. The binomial sigmoid
            % introduces the (1-ld) factor.
            beta      = [0.5, -1.2];
            Xnames    = {'one', 'x'};
            stimNames = {'x'};
            fitType   = 'binomial';

            cif_sym = CIF(beta, Xnames, stimNames, fitType);
            cif_lin = LinearCIF(beta, Xnames, stimNames, fitType);

            stimPoints = [-2.5, -0.4, 0.0, 0.6, 1.8, 4.0];
            for sp = stimPoints
                tc.compareAll(cif_sym, cif_lin, sp);
            end
        end

        function testPoissonAgreementMultiStim(tc)
            % Two-dimensional stimulus, Poisson. Verifies the gradient is a
            % length-2 row vector and the Hessian is 2x2.
            beta      = [-1.5, 0.3, -0.6];   % [intercept, x, y]
            Xnames    = {'one', 'x', 'y'};
            stimNames = {'x', 'y'};
            fitType   = 'poisson';

            cif_sym = CIF(beta, Xnames, stimNames, fitType);
            cif_lin = LinearCIF(beta, Xnames, stimNames, fitType);

            stimPts = [-1.0, 0.5;
                        0.2, -0.7;
                        1.0,  1.0];
            for r = 1:size(stimPts, 1)
                tc.compareAll(cif_sym, cif_lin, stimPts(r, :)');
            end
        end

        function testBinomialAgreementMultiStim(tc)
            % Two-dimensional stimulus, binomial.
            beta      = [-0.8, 0.4, 0.9];
            Xnames    = {'one', 'x', 'y'};
            stimNames = {'x', 'y'};
            fitType   = 'binomial';

            cif_sym = CIF(beta, Xnames, stimNames, fitType);
            cif_lin = LinearCIF(beta, Xnames, stimNames, fitType);

            stimPts = [-1.5, 0.8;
                        0.3, -0.4;
                        1.2,  1.5];
            for r = 1:size(stimPts, 1)
                tc.compareAll(cif_sym, cif_lin, stimPts(r, :)');
            end
        end
    end

    methods (Access = private)
        function compareAll(tc, cif_sym, cif_lin, sp)
            %COMPAREALL Verify all 5 eval methods agree at AbsTol 1e-12.
            ld_sym = cif_sym.evalLambdaDelta(sp);
            ld_lin = cif_lin.evalLambdaDelta(sp);
            tc.verifyEqual(double(ld_lin), double(ld_sym), 'AbsTol', 1e-12, ...
                sprintf('evalLambdaDelta mismatch at sp=%s', mat2str(sp(:)')));

            g_sym = cif_sym.evalGradient(sp);
            g_lin = cif_lin.evalGradient(sp);
            tc.verifyEqual(double(g_lin), double(g_sym), 'AbsTol', 1e-12, ...
                sprintf('evalGradient mismatch at sp=%s', mat2str(sp(:)')));

            gl_sym = cif_sym.evalGradientLog(sp);
            gl_lin = cif_lin.evalGradientLog(sp);
            tc.verifyEqual(double(gl_lin), double(gl_sym), 'AbsTol', 1e-12, ...
                sprintf('evalGradientLog mismatch at sp=%s', mat2str(sp(:)')));

            J_sym = cif_sym.evalJacobian(sp);
            J_lin = cif_lin.evalJacobian(sp);
            tc.verifyEqual(double(J_lin), double(J_sym), 'AbsTol', 1e-12, ...
                sprintf('evalJacobian mismatch at sp=%s', mat2str(sp(:)')));

            Jl_sym = cif_sym.evalJacobianLog(sp);
            Jl_lin = cif_lin.evalJacobianLog(sp);
            tc.verifyEqual(double(Jl_lin), double(Jl_sym), 'AbsTol', 1e-12, ...
                sprintf('evalJacobianLog mismatch at sp=%s', mat2str(sp(:)')));
        end
    end
end
