classdef testKFEMEntryPointReachable < matlab.unittest.TestCase
    %TESTKFEMENTRYPOINTREACHABLE (KF track M, item C0; the most severe
    % finding of the audit) nstat.decoding.KF_EM declared its main EM
    % loop as a STATIC method with the SAME NAME as its containing class.
    % MATLAB always dispatches a method whose name matches its class as
    % the class constructor, regardless of the methods(Static) block it
    % is written in (meta.class reports Static=0 for it). As a result:
    %   * nstat.decoding.KF_EM.KF_EM(...) errored
    %     "MATLAB:subscripting:classHasNoPropertyOrMethod ... no Static
    %     method named 'KF_EM'" (dot-call dispatch never looks at the
    %     constructor);
    %   * nstat.decoding.KF_EM(...) (constructor-call syntax) ran the
    %     method body but then errored "the constructor must preserve
    %     the class of the returned object", because the method's first
    %     output is a numeric matrix, not a KF_EM instance.
    % Both of KF_EM's documented entry points -- this method and
    % DecodingAlgorithms.KF_EM, which just forwarded to it -- were
    % unreachable since the Phase 3 class extraction. The method is
    % renamed KF_RunEM (DecodingAlgorithms.KF_EM now forwards there); the
    % class name, and every other static method on it, are unchanged.

    methods (Test)
        function testClassDotCallReaches(tc)
            P = testKFEMEntryPointReachable.toyProblem();
            cons = nstat.decoding.KF_EM.KF_EMCreateConstraints();
            r = cell(1,10);
            rng(1);
            evalc(['[r{1:10}] = nstat.decoding.KF_EM.KF_RunEM(P.y,P.A,P.Q,P.C,P.R,P.alpha,P.x0,P.Px0,cons);']);
            tc.verifyTrue(all(isfinite(r{3}(:))), 'Ahat must be finite');
            tc.verifyClass(r{10}, 'struct', 'IC must be returned');
        end

        function testOldNameIsUnreachableAsAStaticCall(tc)
            % Documents the pre-fix failure mode directly: a Static
            % method literally named the same as its class cannot be
            % reached by ClassName.MethodName(...) dispatch. KF_EM no
            % longer has such a method (it is KF_RunEM), so this probes
            % the general MATLAB restriction with a disposable local
            % class, which is what made the rename necessary.
            tc.verifyTrue(testKFEMEntryPointReachable.staticMethodNameCollidesWithClass(), ...
                'a Static method sharing its class''s name must not be dispatchable as a Static method');
        end

        function testDeprecationShimForwardsToRenamedMethod(tc)
            P = testKFEMEntryPointReachable.toyProblem();
            warnState = warning('off', 'nSTAT:deprecated:DecodingAlgorithms');
            cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>
            cons = nstat.decoding.KF_EM.KF_EMCreateConstraints();
            r1 = cell(1,10); r2 = cell(1,10);
            rng(2);
            evalc(['[r1{1:10}] = DecodingAlgorithms.KF_EM(P.y,P.A,P.Q,P.C,P.R,P.alpha,P.x0,P.Px0,cons);']);
            rng(2);
            evalc(['[r2{1:10}] = nstat.decoding.KF_EM.KF_RunEM(P.y,P.A,P.Q,P.C,P.R,P.alpha,P.x0,P.Px0,cons);']);
            for i = 1:10
                tc.verifyEqual(r1{i}, r2{i}, sprintf('output %d', i));
            end
        end
    end

    methods (Static, Access = private)
        function tf = staticMethodNameCollidesWithClass()
            % meta.class truth on the (already fixed) KF_EM class. MATLAB
            % always lists an entry named 'KF_EM' -- the IMPLICIT class
            % constructor every classdef has, Static=0 -- regardless of
            % any method defined in the file; that is not itself the bug.
            % The bug this documents is that a method explicitly written
            % under methods(Static) with that same name is silently
            % forced non-Static (coerced into being that constructor):
            % so the real EM driver must be named something else
            % (KF_RunEM), and listed with Static=1.
            mc = meta.class.fromName('nstat.decoding.KF_EM');
            names = {mc.MethodList.Name};
            ctorIdx = find(strcmp(names, 'KF_EM'), 1);
            runIdx = find(strcmp(names, 'KF_RunEM'), 1);
            tf = ~isempty(ctorIdx) && ~mc.MethodList(ctorIdx).Static ... % the implicit constructor
                && ~isempty(runIdx) && mc.MethodList(runIdx).Static;    % the real, reachable method
        end

        function P = toyProblem()
            rng(5); P.A = 0.9; P.Q = 0.02; P.C = 1.3; P.R = 0.05; P.alpha = 0.2;
            N = 100; P.x0 = 0; P.Px0 = 1e-6;
            x = zeros(1,N); xp = 0;
            for k = 1:N, xp = P.A*xp + sqrt(P.Q)*randn; x(k) = xp; end
            P.y = P.C*x + P.alpha + sqrt(P.R)*randn(1,N);
        end
    end
end
