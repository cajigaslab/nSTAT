classdef testInstallSavePathGuard < matlab.unittest.TestCase
    %TESTINSTALLSAVEPATHGUARD nSTAT_Install('SavePath',false) must never
    % call savepath (issue #140: the release gate rewrote MATLAB's
    % SYSTEM toolbox/local/pathdef.m on every automated run).
    %
    % CRITICAL: this test must NEVER call the real savepath. It shadows
    % savepath with a path-local mock (a file named savepath.m placed
    % ahead on the MATLAB path) that only records a call count instead of
    % touching pathdef.m, and verifies the shadow actually resolved
    % before invoking anything. The real pathdef.m hash is also checked
    % as a second line of defense.

    properties
        OrigPath
        OrigDir
        MockDir
        CallCountFile
        PathdefFile
        PathdefHashBefore
        StaleEntry
    end

    methods (TestMethodSetup)
        function setup(tc)
            tc.OrigPath = path();
            % matlab.unittest changes the current folder to this test
            % file's own directory while running. nSTAT_Install's
            % removeExistingRootPaths() strips every path entry under
            % rootDir (including rootDir itself) before re-adding it a
            % few lines later; the repo root being the CURRENT folder is
            % what keeps its top-level functions resolvable in between
            % (MATLAB always implicitly searches the current folder).
            % cd there so the test exercises the same context the real
            % non-interactive callers run in (both cd to repo root first).
            tc.OrigDir = pwd();
            repoRoot = fileparts(which('nSTAT_Install'));
            tc.assertNotEmpty(repoRoot, 'Could not resolve nSTAT_Install on the path.');
            cd(repoRoot);

            tc.MockDir = tempname();
            mkdir(tc.MockDir);
            tc.CallCountFile = fullfile(tc.MockDir, 'savepath_call_count.txt');

            % Mock savepath: records a call instead of touching pathdef.m.
            mockSrc = [ ...
                "function savepath()" newline ...
                "fid = fopen('" strrep(tc.CallCountFile, '\', '\\') "', 'a');" newline ...
                "fprintf(fid, 'called\n');" newline ...
                "fclose(fid);" newline ...
                "end" newline];
            fid = fopen(fullfile(tc.MockDir, 'savepath.m'), 'w');
            tc.assertGreaterThan(fid, 0, 'Could not create mock savepath.m');
            fprintf(fid, '%s', strjoin(mockSrc, ''));
            fclose(fid);

            addpath(tc.MockDir, '-begin');

            % ABORT (do not proceed) unless the shadow really resolved.
            resolved = which('savepath');
            tc.fatalAssertEqual(resolved, fullfile(tc.MockDir, 'savepath.m'), ...
                ['savepath shadow did not resolve -- refusing to run this test ', ...
                 'to avoid any risk of calling the real savepath.']);

            % Second line of defense: hash the real system pathdef.m
            % (and the userpath one, if present) before the call.
            tc.PathdefFile = fullfile(matlabroot, 'toolbox', 'local', 'pathdef.m');
            tc.PathdefHashBefore = localHashFile(tc.PathdefFile);

            % A path entry under rootDir that does NOT exist on disk --
            % the realistic shape of staleness cleanup_user_path_prefs
            % targets (a folder that existed when the path was saved and
            % was later deleted). addpath()/path() both VALIDATE and
            % silently refuse to add a directory that doesn't exist yet,
            % so this can't be injected by just concatenating a string:
            % injectStaleEntry() below creates a real directory, addpath's
            % it (accepted, since it exists at that point), then deletes
            % it from disk -- MATLAB's in-memory path list is not
            % revalidated on deletion, so the now-dangling entry survives
            % exactly like a real stale entry would.
            tc.StaleEntry = fullfile(repoRoot, 'nstat_test_stale_dir_for_cleanup_test');
        end
    end

    methods (TestMethodTeardown)
        function teardown(tc)
            path(tc.OrigPath);
            cd(tc.OrigDir);
            if exist(tc.MockDir, 'dir') == 7
                rmdir(tc.MockDir, 's');
            end
            if ~isempty(tc.StaleEntry) && exist(tc.StaleEntry, 'dir') == 7
                rmdir(tc.StaleEntry);
            end
        end
    end

    methods (Test)
        function testSavePathFalseNeverCallsSavepath(tc)
            opts = nSTAT_Install( ...
                'SavePath', false, ...
                'RebuildDocSearch', false, ...
                'CleanUserPathPrefs', false, ...
                'DownloadExampleData', 'never');

            tc.verifyFalse(opts.SavePath, 'opts.SavePath should reflect the false input.');
            tc.verifyEqual(exist(tc.CallCountFile, 'file'), 0, ...
                'nSTAT_Install(''SavePath'',false) called savepath (mock was invoked).');

            % Confirm the real system pathdef.m is byte-identical to before.
            hashAfter = localHashFile(tc.PathdefFile);
            tc.verifyEqual(hashAfter, tc.PathdefHashBefore, ...
                'System pathdef.m hash changed -- savepath ran on the real file.');
        end

        function testSavePathDefaultIsTrue(tc)
            % Parsing-only check (does not invoke nSTAT_Install, so it
            % cannot accidentally call the real/mocked savepath): default
            % must remain 'SavePath'=true so interactive installs keep
            % their current (documented) behaviour.
            src = fileread(which('nSTAT_Install'));
            tc.verifyTrue(contains(src, "'SavePath', true"), ...
                'nSTAT_Install default for SavePath must remain true.');
        end

        function testSavePathRejectsText(tc)
            % A text value ('no') must be rejected by the input parser,
            % not coerced to a truthy logical that would call savepath.
            tc.verifyError(@() nSTAT_Install('SavePath', 'no', ...
                'RebuildDocSearch', false, 'DownloadExampleData', 'never'), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyEqual(exist(tc.CallCountFile, 'file'), 0, ...
                'Rejected SavePath value still reached savepath.');
        end

        function testCleanUserPathPrefsForwardsSavePathFalse(tc)
            % nSTAT_Install('SavePath',false,'CleanUserPathPrefs',true)
            % must also suppress cleanup_user_path_prefs's own savepath.
            %
            % NOTE: cleanup_user_path_prefs only calls savepath when it
            % actually removed something (`if ~isempty(removedEntries)`).
            % Without a stale entry on the path, this test would pass
            % trivially even if the SavePath forwarding were broken --
            % savepath would never be reached either way. Inject a stale
            % entry first so the cleanup path is genuinely exercised.
            tc.injectStaleEntry();

            opts = nSTAT_Install( ...
                'SavePath', false, ...
                'RebuildDocSearch', false, ...
                'CleanUserPathPrefs', true, ...
                'DownloadExampleData', 'never');
            tc.verifyFalse(opts.SavePath);

            % Non-vacuousness check: the stale entry must actually have
            % been removed (i.e. cleanup_user_path_prefs had real work to
            % do, not an empty removedEntries list).
            tc.verifyFalse(any(strcmp(strsplit(path(), pathsep), tc.StaleEntry)), ...
                'Stale path entry was not removed -- this test is not exercising the cleanup path.');

            tc.verifyEqual(exist(tc.CallCountFile, 'file'), 0, ...
                ['nSTAT_Install(''SavePath'',false,''CleanUserPathPrefs'',true) ', ...
                 'called savepath via cleanup_user_path_prefs while removing a stale entry.']);
            hashAfter = localHashFile(tc.PathdefFile);
            tc.verifyEqual(hashAfter, tc.PathdefHashBefore, ...
                'System pathdef.m hash changed during CleanUserPathPrefs path.');
        end

        function testCleanupUserPathPrefsDirectSavePathFalse(tc)
            % Same scenario, called directly against cleanup_user_path_prefs
            % (bypassing nSTAT_Install entirely) so this also pins the
            % function's own contract in isolation.
            tc.injectStaleEntry();
            repoRoot = fileparts(which('nSTAT_Install'));
            % Resolve the helper the same way nSTAT_Install does, so this
            % test does not depend on the runner's addpath(genpath(...)).
            % teardown restores the original path.
            addpath(fullfile(repoRoot, 'tools', 'matlab'), '-begin');

            removed = cleanup_user_path_prefs(repoRoot, 'SavePath', false);

            tc.verifyTrue(any(strcmp(removed, tc.StaleEntry)), ...
                'cleanup_user_path_prefs did not report removing the injected stale entry.');
            tc.verifyEqual(exist(tc.CallCountFile, 'file'), 0, ...
                'cleanup_user_path_prefs(...,''SavePath'',false) called savepath.');
            hashAfter = localHashFile(tc.PathdefFile);
            tc.verifyEqual(hashAfter, tc.PathdefHashBefore, ...
                'System pathdef.m hash changed by cleanup_user_path_prefs directly.');
        end
    end

    methods (Access = private)
        function injectStaleEntry(tc)
            if exist(tc.StaleEntry, 'dir') == 7
                rmdir(tc.StaleEntry);
            end
            mkdir(tc.StaleEntry);
            addpath(tc.StaleEntry, '-end');
            % NOTE: MATLAB's own rmdir() (R2026a) proactively notices the
            % deletion and auto-removes the entry from the SESSION path
            % right then ("Removed ... from the MATLAB path"), which would
            % defeat this injection before cleanup_user_path_prefs ever
            % runs. Delete via the OS directly (bypassing rmdir's path
            % bookkeeping) so the in-memory path entry is left dangling,
            % exactly like a real stale entry from a deleted folder that
            % MATLAB hasn't (yet) noticed.
            javaObj = java.io.File(tc.StaleEntry);
            removed = javaObj.delete();
            assert(removed, 'injectStaleEntry: could not delete %s via java.io.File.', tc.StaleEntry);

            % Sanity: the entry must be on the in-memory path (as a
            % dangling/nonexistent one) for this injection to be doing
            % anything at all.
            assert(any(strcmp(strsplit(path(), pathsep), tc.StaleEntry)), ...
                'injectStaleEntry: stale entry did not land on the path.');
            assert(exist(tc.StaleEntry, 'dir') ~= 7, ...
                'injectStaleEntry: directory still exists on disk -- not actually stale.');
        end
    end
end

function h = localHashFile(filePath)
if exist(filePath, 'file') ~= 2
    h = 'ABSENT';
    return;
end
import java.security.MessageDigest
import java.io.FileInputStream
digest = MessageDigest.getInstance('SHA-256');
stream = FileInputStream(filePath);
cleanupObj = onCleanup(@() stream.close()); %#ok<NASGU>
buffer = zeros(1, 65536, 'int8');
while true
    n = stream.read(buffer);
    if n <= 0
        break;
    end
    if n == numel(buffer)
        digest.update(buffer);
    else
        digest.update(buffer(1:n));
    end
end
h = lower(reshape(dec2hex(typecast(int8(digest.digest()), 'uint8'))', 1, []));
end
