# nSTAT — Tech Stack

- Language: **MATLAB**. Default toolchain **R2025b** at `/Applications/MATLAB_R2025b.app`. R2026a also installed (`/Applications/MATLAB_R2026a.app`); `matlab` on PATH is `/opt/homebrew/bin/matlab` (shell shim).
- Override MATLAB used by test scripts via `MATLAB_BIN=/Applications/MATLAB_R2024b.app/bin/matlab` or `--matlab-path`. `run_unit_tests.sh` exits 2 if MATLAB not found.
- Build/packaging: MATLAB toolbox project — `buildfile.m`, `toolboxOptions.m`, `packageToolbox.m`, `nSTAT_Install.m`.
- Simulink present (`slprj/`, `*.slxc`).
- Auxiliary tooling in Python + bash under `tools/` (help-system audit, lint, drift checks) and shell gate scripts.
- Version: v1.4.0. `CITATION.cff` (cff-version 1.2.0) + `RELEASE_NOTES.md` track releases.
- Git-LFS tracks `*.mat` and `*.slxc` (see `.gitattributes`).
- Serena languages configured: matlab (default), cpp, python, bash.