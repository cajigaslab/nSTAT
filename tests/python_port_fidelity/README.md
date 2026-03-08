# Python Port Fidelity Tests

This test suite validates the standalone Python `nSTAT-python` port directly from MATLAB
through `pyenv` and `py.` imports.

Run from the MATLAB repo root:

```matlab
addpath(fullfile(pwd, 'tools', 'python'));
setup_python_for_nstat_tests();
results = runtests('tests/python_port_fidelity');
assertSuccess(results);
```

`setup_python_for_nstat_tests` will auto-detect a `python` on your shell `PATH`
that can import `sympy` and the standalone `nSTAT-python` package. You can also
override the interpreter explicitly:

```matlab
setup_python_for_nstat_tests('/path/to/python');
```

The suite is split into:

- `TestPythonPortFidelity.m`: core class and workflow parity checks.
- `TestPythonNotebookParity.m`: notebook/parity-audit checks driven from MATLAB.
- `TestPythonSimulinkParity.m`: Simulink-derived workflow comparisons against the Python port.
