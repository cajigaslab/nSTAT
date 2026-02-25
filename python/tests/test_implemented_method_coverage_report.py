from __future__ import annotations

import json
import subprocess


def test_implemented_method_coverage_report(repo_root) -> None:
    cp = subprocess.run(
        ["python3", "python/tools/generate_implemented_method_coverage.py"],
        cwd=str(repo_root),
        capture_output=True,
        text=True,
        check=True,
    )
    payload = json.loads(cp.stdout)
    assert payload["pass"] is True
    assert payload["summary"]["missing_in_smoke_count"] == 0
    assert payload["summary"]["missing_doc_class_count"] == 0
