from __future__ import annotations

import os
import shutil
import subprocess

import pytest


def test_sphinx_build(repo_root) -> None:
    if os.environ.get("NSTAT_CI_LIGHT") == "1":
        pytest.skip("Sphinx build already validated in dedicated CI workflow step")
    if shutil.which("sphinx-build") is None:
        pytest.skip("sphinx-build not available in environment")

    cp = subprocess.run(
        ["sphinx-build", "-b", "html", "python/docs", "python/docs/_build/html"],
        cwd=str(repo_root),
        capture_output=True,
        text=True,
        check=False,
    )
    assert cp.returncode == 0, cp.stdout + "\n" + cp.stderr
