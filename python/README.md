# Python Port Tombstone

This MATLAB repository no longer carries an active embedded Python implementation.

The standalone Python port now lives in the separate repository:

- [cajigaslab/nSTAT-python](https://github.com/cajigaslab/nSTAT-python)

Clean-room boundary:

- MATLAB-repo Python usage is allowed only inside:
  - `tests/python_port_fidelity/**`
  - `tools/python/**`
- Those paths exist only to verify the standalone Python port from MATLAB.
- The MATLAB toolbox itself must not depend on this archived `python/` subtree for
  runtime behavior, examples, packaging, or documentation.

This directory is retained only as a tombstone pointer so historical links do not
silently disappear.
