from __future__ import annotations

import json
import os
import subprocess
import sys

import pytest


def test_generated_notebooks_execute(repo_root) -> None:
    if os.environ.get("NSTAT_CI_LIGHT") == "1":
        pytest.skip("Notebook validation already executed in dedicated CI workflow step")
    cp = subprocess.run(
        [sys.executable, "python/tools/verify_examples_notebooks.py"],
        cwd=str(repo_root),
        capture_output=True,
        text=True,
        check=True,
    )
    report = json.loads(cp.stdout)
    assert report["total_examples"] == 25
    assert report["python_modules_ok"] == 25
    assert report["notebooks_ok"] == 25
    assert report["topic_alignment_ok"] == 25
