classdef testKFEMSingularInformation < matlab.unittest.TestCase
    %TESTKFEMSINGULARINFORMATION (KF track M, item C6 / #136)
    % KF_ComputeParamStandardErrors computed
    % invIObs = eye(size(IObs))/IObs then nearestSPD(invIObs), the same
    % pattern PP_ComputeParamStandardErrors / PPLFP_ComputeParamStandard-
    % Errors had before #136: when IObs is exactly singular (a parameter
    % the data cannot identify), eye/IObs is Inf/NaN, and nearestSPD's
    % "while p ~= 0" loop never returns on a NaN matrix, so KF_RunEM /
    % KF_ComputeParamStandardErrors hung forever whenever SEs were
    % requested. It now reuses PointProcessEM.seObservedInfoInverse (the
    % #136 fix already applied to PP_EM/PPLFP_EM, Access extended to
    % nstat.decoding.KF_EM rather than duplicated): no zero pivot ->
    % exactly the old eye/IObs then nearestSPD (bit-identical); a zero
    % pivot -> the pseudo-inverse, with the non-identifiable terms
    % flagged (SE/p-value NaN) via nSTAT:EM:singularInformation, and
    % only the identifiable block projected by nearestSPD; a non-finite
    % IObs/inverse raises nSTAT:EM:nonFiniteInformation instead of
    % looping.

    methods (Test)
        function testSingularObservedInformationDoesNotHang(tc)
            % A synthetic exactly-singular IObs in the shape
            % KF_ComputeParamStandardErrors builds (A, Q, C, R, Px0, x0,
            % alpha blocks), with the x0 block made exactly singular,
            % must return promptly with that block flagged, rather than
            % hang.
            IComp = blkdiag(eye(2), eye(1), eye(2), eye(1), eye(1), [1 1; 1 1], eye(1));
            IMissing = zeros(size(IComp));
            IObs = IComp - IMissing; % x0 block (the 6th, size 2) is singular: [1 1;1 1]
            labels = nstat.decoding.PointProcessEM.seTermLabels({ ...
                'A', 2, [2 1], 'vector'; 'Q', 1, [1 1], 'square'; 'C', 2, [2 1], 'vector'; ...
                'R', 1, [1 1], 'square'; 'Px0', 1, [1 1], 'square'; 'x0', 2, [2 1], 'vector'; ...
                'alpha', 1, [1 1], 'vector'});
            [invIObs, nonIdentifiable] = nstat.decoding.PointProcessEM.seObservedInfoInverse(IObs, labels, 'KF_ComputeParamStandardErrors');
            tc.verifyTrue(all(isfinite(invIObs(:))), 'invIObs must be finite, not hang-then-NaN');
            tc.verifyTrue(any(nonIdentifiable), 'the singular x0 block must be flagged non-identifiable');
        end

        function testKFComputeParamStandardErrorsUsesTheHelper(tc)
            % Direct evidence that KF_ComputeParamStandardErrors itself
            % (not just the shared helper, already covered by PP's own
            % tests) calls seObservedInfoInverse, by source inspection:
            % the legacy "eye(size(IObs))/IObs" + bare "nearestSPD(invIObs)"
            % hang path must be gone.
            src = fileread(which('nstat.decoding.KF_EM'));
            lines = regexp(src, '\r?\n', 'split');
            code = strjoin(regexprep(lines, '%.*$', ''), newline);
            tc.verifyEmpty(regexp(code, 'eye\(size\(IObs\)\)/IObs', 'once'), ...
                'KF_EM.m should no longer compute invIObs with the un-guarded eye/IObs');
            tc.verifyNotEmpty(regexp(code, 'PointProcessEM\.seObservedInfoInverse', 'once'), ...
                'KF_EM.m must call PointProcessEM.seObservedInfoInverse');
        end
    end
end
