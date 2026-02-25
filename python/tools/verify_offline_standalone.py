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

        install_env = {**env, "PYTHONPATH": str(site_dir)}
        source_env = {**env, "PYTHONPATH": str(REPO_ROOT / "python")}
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
                env=install_env,
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
                env=install_env,
            )
        )
        steps.append(
            _run(
                [
                    str(py),
                    "-c",
                    (
                        "import numpy as np; "
                        "from nstat.signal import Signal; "
                        "t=np.linspace(0.0,1.0,100); "
                        "sig=Signal(t, np.column_stack([np.sin(t), np.cos(t)]), name='offline_check'); "
                        "print(sig.dimension)"
                    ),
                ],
                cwd=REPO_ROOT,
                env=install_env,
            )
        )
        # Source-path fallback check keeps CI resilient if pip --target behavior changes.
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
                env=source_env,
            )
        )
        if full_notebooks:
            steps.append(
                _run(
                    [str(py), "python/tools/verify_examples_notebooks.py"],
                    cwd=REPO_ROOT,
                    env=source_env,
                )
            )

        report["steps"] = steps

    report["runtime_matlab_scan"] = _runtime_matlab_dependency_scan()
    report["target_install_ok"] = bool(report["steps"][0]["ok"])
    report["installed_runtime_ok"] = bool(report["steps"][1]["ok"] and report["steps"][2]["ok"])
    report["source_fallback_ok"] = bool(report["steps"][3]["ok"])
    report["notebook_checks_ok"] = bool((not full_notebooks) or report["steps"][-1]["ok"])
    report["install_mode"] = (
        "target_install"
        if (report["target_install_ok"] and report["installed_runtime_ok"])
        else ("source_fallback" if report["source_fallback_ok"] else "failed")
    )
    report["pass_strict_target_install"] = bool(
        report["target_install_ok"]
        and report["installed_runtime_ok"]
        and report["notebook_checks_ok"]
        and report["runtime_matlab_scan"]["ok"]
    )
    report["pass"] = bool(
        report["notebook_checks_ok"]
        and report["runtime_matlab_scan"]["ok"]
        and (report["pass_strict_target_install"] or report["source_fallback_ok"])
    )
    REPORT_PATH.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify standalone offline Python nSTAT usage from source checkout.")
    parser.add_argument("--full-notebooks", action="store_true", help="Also execute all generated notebooks.")
    parser.add_argument(
        "--require-target-install",
        action="store_true",
        help="Fail unless pip --target install succeeds (no source fallback mode).",
    )
    args = parser.parse_args()

    report = verify(full_notebooks=args.full_notebooks)
    effective_pass = bool(report["pass_strict_target_install"] if args.require_target_install else report["pass"])
    printable = {
        "report": str(REPORT_PATH.relative_to(REPO_ROOT)),
        "pass": effective_pass,
        "steps_ok": [step["ok"] for step in report["steps"]],
        "runtime_matlab_scan_ok": report["runtime_matlab_scan"]["ok"],
        "target_install_ok": report["target_install_ok"],
        "install_mode": report["install_mode"],
        "pass_strict_target_install": report["pass_strict_target_install"],
    }
    print(json.dumps(printable, indent=2))
    return 0 if effective_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
