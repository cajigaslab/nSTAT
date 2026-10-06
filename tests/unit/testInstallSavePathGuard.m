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
        end
    end

    methods (TestMethodTeardown)
        function teardown(tc)
            path(tc.OrigPath);
            cd(tc.OrigDir);
            if exist(tc.MockDir, 'dir') == 7
                rmdir(tc.MockDir, 's');
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

        function testCleanUserPathPrefsForwardsSavePathFalse(tc)
            % nSTAT_Install('SavePath',false,'CleanUserPathPrefs',true)
            % must also suppress cleanup_user_path_prefs's own savepath.
            opts = nSTAT_Install( ...
                'SavePath', false, ...
                'RebuildDocSearch', false, ...
                'CleanUserPathPrefs', true, ...
                'DownloadExampleData', 'never');
            tc.verifyFalse(opts.SavePath);
            tc.verifyEqual(exist(tc.CallCountFile, 'file'), 0, ...
                ['nSTAT_Install(''SavePath'',false,''CleanUserPathPrefs'',true) ', ...
                 'called savepath via cleanup_user_path_prefs.']);
            hashAfter = localHashFile(tc.PathdefFile);
            tc.verifyEqual(hashAfter, tc.PathdefHashBefore, ...
                'System pathdef.m hash changed during CleanUserPathPrefs path.');
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
