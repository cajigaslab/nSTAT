from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
REPORT_PATH = REPO_ROOT / "python" / "reports" / "offline_standalone_verification.json"


def _run(cmd: list[str], *, cwd: Path, env: dict[str, str]) -> dict[str, Any]:
    cp = subprocess.run(cmd, cwd=str(cwd), env=env, capture_output=True, text=True, check=False)
    return {
        "cmd": cmd,
        "cwd": str(cwd.relative_to(REPO_ROOT)),
        "returncode": cp.returncode,
        "stdout": cp.stdout[-4000:],
        "stderr": cp.stderr[-4000:],
        "ok": cp.returncode == 0,
    }


def _sanitize_path(path_value: str) -> str:
    parts = [p for p in path_value.split(os.pathsep) if p and "matlab" not in p.lower()]
    return os.pathsep.join(parts)


def _runtime_matlab_dependency_scan() -> dict[str, Any]:
    py_root = REPO_ROOT / "python" / "nstat"
    bad_hits: list[str] = []
    pattern = re.compile(r"(/Applications/MATLAB|subprocess\..*matlab|MATLAB_BIN)", re.IGNORECASE)
    for p in py_root.rglob("*.py"):
        text = p.read_text(encoding="utf-8", errors="ignore")
        if pattern.search(text):
            bad_hits.append(str(p.relative_to(REPO_ROOT)))
    return {"ok": len(bad_hits) == 0, "hits": bad_hits}


def verify(full_notebooks: bool = False) -> dict[str, Any]:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    report: dict[str, Any] = {"full_notebooks": bool(full_notebooks)}

    with tempfile.TemporaryDirectory(prefix="nstat_offline_site_") as td:
        site_dir = Path(td) / "site"
        site_dir.mkdir(parents=True, exist_ok=True)
        py = Path(sys.executable)
        env = dict(os.environ)
        env["PATH"] = _sanitize_path(env.get("PATH", ""))
        env["PYTHONPATH"] = str(site_dir)

        steps = []
        steps.append(
            _run(
                [
                    str(py),
                    "-m",
                    "pip",
                    "install",
                    "--no-deps",
                    "./python",
                    "--target",
                    str(site_dir),
                ],
                cwd=REPO_ROOT,
                env=env,
            )
        )
        steps.append(
            _run(
                [
                    str(py),
                    "-c",
                    (
                        "import json, pathlib, nstat; "
                        "checks=nstat.verify_checksums(); "
                        "print(json.dumps({'dataset_count': len(nstat.list_datasets()), "
                        "'checksum_all_true': all(checks.values()), "
                        "'nstat_path': str(pathlib.Path(nstat.__file__).resolve())}))"
                    ),
                ],
                cwd=REPO_ROOT,
                env={**env, "PYTHONPATH": os.pathsep.join([str(site_dir), str(REPO_ROOT / "python")])},
            )
        )
        steps.append(
            _run(
                [
                    str(py),
                    "-c",
                    (
                        "from examples.help_topics._common import run_topic; "
                        f"out=run_topic('SignalObjExamples', repo_root={repr(str(REPO_ROOT))}); "
                        "print(out['topic'])"
                    ),
                ],
                cwd=REPO_ROOT / "python",
                env={**env, "PYTHONPATH": os.pathsep.join([str(site_dir), str(REPO_ROOT / 'python')])},
            )
        )
        if full_notebooks:
            steps.append(
                _run(
                    [str(py), "python/tools/verify_examples_notebooks.py"],
                    cwd=REPO_ROOT,
                    env={**env, "PYTHONPATH": os.pathsep.join([str(site_dir), str(REPO_ROOT / "python")])},
                )
            )

        report["steps"] = steps

    report["runtime_matlab_scan"] = _runtime_matlab_dependency_scan()
    report["pass"] = all(step["ok"] for step in report["steps"]) and bool(report["runtime_matlab_scan"]["ok"])
    REPORT_PATH.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify standalone offline Python nSTAT usage from source checkout.")
    parser.add_argument("--full-notebooks", action="store_true", help="Also execute all generated notebooks.")
    args = parser.parse_args()

    report = verify(full_notebooks=args.full_notebooks)
    printable = {
        "report": str(REPORT_PATH.relative_to(REPO_ROOT)),
        "pass": report["pass"],
        "steps_ok": [step["ok"] for step in report["steps"]],
        "runtime_matlab_scan_ok": report["runtime_matlab_scan"]["ok"],
    }
    print(json.dumps(printable, indent=2))
    return 0 if report["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
