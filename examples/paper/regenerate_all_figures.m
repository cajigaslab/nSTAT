function regenerate_all_figures()
%REGENERATE_ALL_FIGURES Run all paper examples and export figures.
%
%   regenerate_all_figures() runs each example script with ExportFigures=true
%   and saves PNGs to docs/figures/exampleNN/. This ensures figures stay
%   current with every code change.
%
%   Called automatically by the post-commit git hook when MATLAB is available.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
figRoot = fullfile(repoRoot, 'docs', 'figures');

examples = {
    'example01_mepsc_poisson',    'example01';
    'example02_whisker_stimulus_thalamus', 'example02';
    'example03_psth_and_ssglm',   'example03';
    'example04_place_cells_continuous_stimulus', 'example04';
    'example05_decoding_ppaf_pphf', 'example05';
};

fprintf('=== Regenerating all paper figures ===\n');
nFailed = 0;

for i = 1:size(examples, 1)
    funcName = examples{i, 1};
    dirName  = examples{i, 2};
    outDir   = fullfile(figRoot, dirName);

    fprintf('\n--- %s ---\n', funcName);
    try
        fh = str2func(funcName);
        fh('ExportFigures', true, 'ExportDir', outDir, ...
           'Visible', 'off', 'CloseFigures', true);
        fprintf('  OK: figures saved to %s\n', outDir);
    catch ME
        fprintf('  FAILED: %s\n', ME.message);
        nFailed = nFailed + 1;
    end
end

fprintf('\n=== Done. %d/%d examples succeeded ===\n', ...
    size(examples, 1) - nFailed, size(examples, 1));

if nFailed > 0
    warning('regenerate_all_figures:failures', ...
        '%d example(s) failed to generate figures.', nFailed);
end
end
