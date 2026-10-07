classdef testReleaseVersionConsistency < matlab.unittest.TestCase
    %TESTRELEASEVERSIONCONSISTENCY Contents.m, toolboxOptions.m, and
    % RELEASE_NOTES.md must agree on the released version.
    %
    % stamp_release did not update toolboxOptions.m's ToolboxVersion (it
    % stayed "1.5.1" through v1.5.2 while Contents.m and RELEASE_NOTES.md
    % moved on), so the shipped .mltbx reported the wrong version. This
    % test pins the three sources of truth together going forward.

    methods (Test)
        function testCommittedTreeIsConsistent(tc)
            [contentsMajorMinor, toolboxFull, notesFull] = localReadVersions();

            toolboxMajorMinor = localMajorMinor(toolboxFull);
            notesMajorMinor = localMajorMinor(notesFull);

            tc.verifyEqual(contentsMajorMinor, toolboxMajorMinor, ...
                sprintf(['Contents.m (%s) and toolboxOptions.m ToolboxVersion ', ...
                 '(%s) disagree on major.minor.'], contentsMajorMinor, toolboxMajorMinor));
            tc.verifyEqual(contentsMajorMinor, notesMajorMinor, ...
                sprintf(['Contents.m (%s) and RELEASE_NOTES.md''s top ## vX.Y.Z ', ...
                 'heading (%s) disagree on major.minor.'], contentsMajorMinor, notesMajorMinor));
            tc.verifyEqual(toolboxFull, notesFull, ...
                sprintf(['toolboxOptions.m ToolboxVersion (%s) and RELEASE_NOTES.md''s ', ...
                 'top ## vX.Y.Z heading (%s) disagree.'], toolboxFull, notesFull));
        end

        function testStampReleaseUpdatesToolboxVersion(tc)
            % Exercise stamp_release on a scratch copy of the three files
            % (never the real repo files) and confirm it actually writes
            % toolboxOptions.m's ToolboxVersion to the full X.Y.Z target.
            import matlab.unittest.fixtures.PathFixture

            repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            scratchDir = tempname();
            mkdir(scratchDir);
            tc.addTeardown(@() rmdirIfExists(scratchDir));

            toolsScratchDir = fullfile(scratchDir, 'tools');
            mkdir(toolsScratchDir);
            copyfile(fullfile(repoRoot, 'tools', 'stamp_release.m'), toolsScratchDir);
            copyfile(fullfile(repoRoot, 'Contents.m'), scratchDir);
            copyfile(fullfile(repoRoot, 'toolboxOptions.m'), scratchDir);
            copyfile(fullfile(repoRoot, 'RELEASE_NOTES.md'), scratchDir);
            mkdir(fullfile(scratchDir, 'docs', 'figures'));
            copyfile(fullfile(repoRoot, 'docs', 'figures', 'manifest.json'), ...
                fullfile(scratchDir, 'docs', 'figures'));

            tc.applyFixture(PathFixture(toolsScratchDir));
            resolved = which('stamp_release');
            tc.assertEqual(resolved, fullfile(toolsScratchDir, 'stamp_release.m'), ...
                'stamp_release did not resolve to the scratch copy -- refusing to run.');

            targetVersion = 'v99.98.97';
            stamp_release(targetVersion, 'DryRun', false);

            toolboxOptionsText = fileread(fullfile(scratchDir, 'toolboxOptions.m'));
            tc.verifyTrue(contains(toolboxOptionsText, 'opts.ToolboxVersion  = "99.98.97";'), ...
                'stamp_release did not stamp toolboxOptions.m ToolboxVersion to the target version.');
        end

        function testStampReleaseFoldsUnreleasedSection(tc)
            % Releases fold the accumulated "## Unreleased" content into
            % the new "## vX.Y.Z" section rather than leaving Unreleased
            % behind as an orphaned separate block (compare how v1.6.0's
            % own notes read -- this repo's committed RELEASE_NOTES.md
            % currently has a real "## Unreleased" section at the top, so
            % this test exercises the fold against real content, just on
            % a scratch copy).
            import matlab.unittest.fixtures.PathFixture

            repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            scratchDir = tempname();
            mkdir(scratchDir);
            tc.addTeardown(@() rmdirIfExists(scratchDir));

            toolsScratchDir = fullfile(scratchDir, 'tools');
            mkdir(toolsScratchDir);
            copyfile(fullfile(repoRoot, 'tools', 'stamp_release.m'), toolsScratchDir);
            copyfile(fullfile(repoRoot, 'RELEASE_NOTES.md'), scratchDir);
            copyfile(fullfile(repoRoot, 'Contents.m'), scratchDir);
            copyfile(fullfile(repoRoot, 'toolboxOptions.m'), scratchDir);
            mkdir(fullfile(scratchDir, 'docs', 'figures'));
            copyfile(fullfile(repoRoot, 'docs', 'figures', 'manifest.json'), ...
                fullfile(scratchDir, 'docs', 'figures'));

            originalNotes = fileread(fullfile(scratchDir, 'RELEASE_NOTES.md'));
            tc.assertTrue(contains(originalNotes, sprintf('## Unreleased\n')), ...
                'Fixture RELEASE_NOTES.md has no "## Unreleased" section to fold -- test setup is stale.');
            % Grab one line of Unreleased body content to confirm it
            % survives the fold (not just the header rename).
            tc.assertTrue(contains(originalNotes, 'Fixes #140'), ...
                'Fixture RELEASE_NOTES.md Unreleased body is missing the expected #140 line.');

            tc.applyFixture(PathFixture(toolsScratchDir));
            tc.assertEqual(which('stamp_release'), fullfile(toolsScratchDir, 'stamp_release.m'), ...
                'stamp_release did not resolve to the scratch copy -- refusing to run.');

            stamp_release('v98.76.54', 'DryRun', false);

            newNotes = fileread(fullfile(scratchDir, 'RELEASE_NOTES.md'));
            tc.verifyFalse(contains(newNotes, '## Unreleased'), ...
                'Unreleased header should have been folded away, not left behind.');
            tc.verifyTrue(contains(newNotes, '## v98.76.54'), ...
                'Expected the new version header to replace Unreleased.');

            % The folded body must appear BETWEEN the new header and the
            % next "## " section (i.e. actually became that section's
            % body, not dropped or relocated elsewhere).
            newHeaderPos = strfind(newNotes, '## v98.76.54');
            afterNewHeader = newNotes(newHeaderPos(1):end);
            nextSectionPos = regexp(afterNewHeader, '\n## ', 'once');
            bodyChunk = afterNewHeader(1:nextSectionPos);
            tc.verifyTrue(contains(bodyChunk, 'Fixes #140'), ...
                'Unreleased body content did not end up inside the new version section.');

            % The section that originally followed Unreleased (v1.6.0)
            % must still immediately follow, untouched.
            tc.verifyTrue(contains(newNotes, '## v1.6.0'), ...
                'The pre-existing ## v1.6.0 section should be unaffected by the fold.');
        end

        function testStampReleaseTemplatesWhenNoUnreleasedSection(tc)
            % Without an "## Unreleased" section, stamp_release must fall
            % back to creating a fresh templated section (the pre-fold
            % behaviour), not error or silently do nothing.
            import matlab.unittest.fixtures.PathFixture

            repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            scratchDir = tempname();
            mkdir(scratchDir);
            tc.addTeardown(@() rmdirIfExists(scratchDir));

            toolsScratchDir = fullfile(scratchDir, 'tools');
            mkdir(toolsScratchDir);
            copyfile(fullfile(repoRoot, 'tools', 'stamp_release.m'), toolsScratchDir);
            copyfile(fullfile(repoRoot, 'Contents.m'), scratchDir);
            copyfile(fullfile(repoRoot, 'toolboxOptions.m'), scratchDir);
            mkdir(fullfile(scratchDir, 'docs', 'figures'));
            copyfile(fullfile(repoRoot, 'docs', 'figures', 'manifest.json'), ...
                fullfile(scratchDir, 'docs', 'figures'));

            fid = fopen(fullfile(scratchDir, 'RELEASE_NOTES.md'), 'w');
            fprintf(fid, '# nSTAT Release Notes\n\n## v1.0.0 — 1-Jan-2020\n\nOld stuff.\n');
            fclose(fid);

            tc.applyFixture(PathFixture(toolsScratchDir));
            tc.assertEqual(which('stamp_release'), fullfile(toolsScratchDir, 'stamp_release.m'), ...
                'stamp_release did not resolve to the scratch copy -- refusing to run.');

            stamp_release('v2.0.0', 'DryRun', false);

            newNotes = fileread(fullfile(scratchDir, 'RELEASE_NOTES.md'));
            tc.verifyTrue(contains(newNotes, '## v2.0.0'), ...
                'Expected a new ## v2.0.0 section to be created.');
            tc.verifyTrue(contains(newNotes, '_Fill in highlights:_'), ...
                'Expected the fallback template placeholder when there is no Unreleased section to fold.');
            tc.verifyTrue(contains(newNotes, '## v1.0.0'), ...
                'The pre-existing ## v1.0.0 section should be unaffected.');
        end
    end
end

function [contentsMajorMinor, toolboxFull, notesFull] = localReadVersions()
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));

contentsText = fileread(fullfile(repoRoot, 'Contents.m'));
m = regexp(contentsText, '(?m)^% Version (\d+\.\d+)', 'tokens', 'once');
assert(~isempty(m), 'Could not parse Contents.m version line.');
contentsMajorMinor = m{1};

toolboxOptionsText = fileread(fullfile(repoRoot, 'toolboxOptions.m'));
m = regexp(toolboxOptionsText, 'opts\.ToolboxVersion\s*=\s*"([^"]+)"', 'tokens', 'once');
assert(~isempty(m), 'Could not parse toolboxOptions.m ToolboxVersion.');
toolboxFull = m{1};

notesText = fileread(fullfile(repoRoot, 'RELEASE_NOTES.md'));
% First "## vX.Y.Z" heading, tolerating a leading "## Unreleased" section
% (stamp_release inserts new sections above it).
m = regexp(notesText, '(?m)^## v(\d+\.\d+\.\d+)', 'tokens', 'once');
assert(~isempty(m), 'Could not find a ## vX.Y.Z heading in RELEASE_NOTES.md.');
notesFull = m{1};
end

function majorMinor = localMajorMinor(fullVersion)
parts = regexp(fullVersion, '\.', 'split');
majorMinor = sprintf('%s.%s', parts{1}, parts{2});
end

function rmdirIfExists(dirPath)
if exist(dirPath, 'dir') == 7
    rmdir(dirPath, 's');
end
end
