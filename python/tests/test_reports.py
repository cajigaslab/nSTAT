from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def test_phase0_reports_generation(repo_root) -> None:
    subprocess.run([sys.executable, "python/tools/freeze_port_baseline.py"], cwd=str(repo_root), check=True)
    subprocess.run([sys.executable, "python/tools/generate_method_parity_matrix.py"], cwd=str(repo_root), check=True)

    snapshot = json.loads((repo_root / "python/reports/port_baseline_snapshot.json").read_text(encoding="utf-8"))
    matrix = json.loads((repo_root / "python/reports/method_parity_matrix.json").read_text(encoding="utf-8"))

    assert "reports" in snapshot
    assert matrix["summary"]["total"] > 0
    assert len(matrix["classes"]) >= 10
