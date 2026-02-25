from __future__ import annotations

import json
import subprocess


def test_generated_notebooks_execute(repo_root) -> None:
    cp = subprocess.run(
        ["python3", "python/tools/verify_examples_notebooks.py"],
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
