from __future__ import annotations

import importlib
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
PORT_ROOT = REPO_ROOT / "python" / "matlab_port"
REPORT_DIR = REPO_ROOT / "python" / "reports"
MATLAB_BIN = Path("/Applications/MATLAB_R2025b.app/bin/matlab")


@dataclass
class Entry:
    source: str
    kind: str
    function_name: str | None
    target: str


def first_code_line(text: str) -> str:
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("%"):
            continue
        return s
    return ""


def classify_m_file(path: Path) -> tuple[str, str | None]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    first = first_code_line(text)
    if first.startswith("classdef "):
        return "classdef", None

    if first.startswith("function"):
        fn = None
        args = ""
        patterns = [
            r"^function\s+\[[^\]]*\]\s*=\s*(\w+)\s*\(([^)]*)\)",
            r"^function\s+\w+\s*=\s*(\w+)\s*\(([^)]*)\)",
            r"^function\s+(\w+)\s*\(([^)]*)\)",
            r"^function\s+\[[^\]]*\]\s*=\s*(\w+)\s*$",
            r"^function\s+\w+\s*=\s*(\w+)\s*$",
            r"^function\s+(\w+)\s*$",
        ]
        for p in patterns:
            m = re.match(p, first)
            if m:
                fn = m.group(1)
                if m.lastindex and m.lastindex >= 2:
                    args = m.group(2)
                break
        if fn is None:
            fn = path.stem
        nargs = 0 if args.strip() == "" else len([x for x in args.split(",") if x.strip()])
        return ("function_no_args" if nargs == 0 else "function_args"), fn

    return "script", None


def python_module_name(target_rel: str) -> str:
    rel = Path(target_rel)
    if rel.parts and rel.parts[0] == "python":
        rel = Path(*rel.parts[1:])
    return str(rel.with_suffix("")).replace("/", ".")


def run_python_entry(module_name: str, kind: str, function_name: str | None) -> tuple[bool, str]:
    try:
        mod = importlib.import_module(module_name)
    except Exception as e:  # noqa: BLE001
        return False, f"import_error: {e}"

    if kind in {"classdef", "function_args"}:
        return True, "interface_checked"

    try:
        if hasattr(mod, "run"):
            _ = mod.run(repo_root=REPO_ROOT)
            return True, "run_ok"
        if kind == "function_no_args" and function_name and hasattr(mod, function_name):
            _ = getattr(mod, function_name)()
            return True, "function_ok"
        if hasattr(mod, "main"):
            _ = mod.main()
            return True, "main_ok"
        return False, "no_runnable_entrypoint"
    except Exception as e:  # noqa: BLE001
        return False, f"runtime_error: {e}"


def run_matlab_smoke(entries: list[Entry]) -> dict[str, dict[str, Any]]:
    results: dict[str, dict[str, Any]] = {}
    runnable = [e for e in entries if e.kind in {"script", "function_no_args"}]

    if not runnable:
        return results

    if not MATLAB_BIN.exists():
        for e in runnable:
            results[e.source] = {"ok": False, "message": "matlab_not_found"}
        return results

    repo_q = str(REPO_ROOT).replace("'", "''")
    for e in runnable:
        src_q = e.source.replace("'", "''")
        fn_q = (e.function_name or "").replace("'", "''")
        if e.kind == "script":
            run_expr = f"run(fullfile(repo,'{src_q}'));"
        else:
            run_expr = f"feval('{fn_q}');"

        cmd = (
            "restoredefaultpath; "
            f"repo='{repo_q}'; "
            "cd(repo); addpath(genpath(repo),'-begin'); set(0,'DefaultFigureVisible','off'); "
            "try; "
            + run_expr
            + " disp('CODEX_SMOKE_OK'); "
            "catch ME; disp('CODEX_SMOKE_FAIL'); disp([ME.identifier ' | ' ME.message]); "
            "end; exit(0);"
        )
        try:
            cp = subprocess.run(
                [str(MATLAB_BIN), "-batch", cmd],
                cwd=str(REPO_ROOT),
                capture_output=True,
                text=True,
                timeout=120,
                check=False,
            )
        except subprocess.TimeoutExpired:
            results[e.source] = {"ok": False, "message": "matlab_timeout"}
            continue

        out = (cp.stdout or "") + "\n" + (cp.stderr or "")
        if "CODEX_SMOKE_OK" in out:
            results[e.source] = {"ok": True, "message": "ok"}
        else:
            # Keep tail concise but preserve exact MATLAB error lines.
            tail = "\n".join([ln for ln in out.splitlines() if ln.strip()][-8:])
            results[e.source] = {"ok": False, "message": tail or "matlab_failed_without_message"}
    return results


def main() -> int:
    entries: list[Entry] = []
    for m in sorted(REPO_ROOT.rglob("*.m")):
        if PORT_ROOT in m.parents:
            continue
        rel_path = m.relative_to(REPO_ROOT)
        if rel_path.parts and rel_path.parts[0] == "python":
            continue
        rel = str(m.relative_to(REPO_ROOT))
        kind, fn = classify_m_file(m)
        tgt = PORT_ROOT.joinpath(*m.relative_to(REPO_ROOT).parts[:-1], f"{m.stem}.py")
        entries.append(Entry(source=rel, kind=kind, function_name=fn, target=str(tgt.relative_to(REPO_ROOT))))

    py_root = REPO_ROOT / "python"
    if str(py_root) not in sys.path:
        sys.path.insert(0, str(py_root))

    matlab_results = run_matlab_smoke(entries)

    rows: list[dict[str, Any]] = []
    summary = {
        "total_m_files": len(entries),
        "python_ok": 0,
        "python_runnable_ok": 0,
        "matlab_runnable_ok": 0,
        "runnable_parity_pass": 0,
        "interface_only": 0,
        "runnable_total": 0,
    }

    for e in entries:
        tgt_exists = (REPO_ROOT / e.target).exists()
        py_ok = False
        py_msg = "target_missing"
        if tgt_exists:
            py_ok, py_msg = run_python_entry(python_module_name(e.target), e.kind, e.function_name)

        if py_ok:
            summary["python_ok"] += 1

        matlab_ok = None
        matlab_msg = "not_run"
        parity = "interface_only"

        if e.kind in {"script", "function_no_args"}:
            summary["runnable_total"] += 1
            mr = matlab_results.get(e.source, {"ok": False, "message": "missing_matlab_result"})
            matlab_ok = bool(mr["ok"])
            matlab_msg = str(mr["message"])
            if py_ok:
                summary["python_runnable_ok"] += 1
            if matlab_ok:
                summary["matlab_runnable_ok"] += 1
            parity = "pass" if (py_ok and matlab_ok) else "fail"
            if parity == "pass":
                summary["runnable_parity_pass"] += 1
        else:
            summary["interface_only"] += 1

        rows.append(
            {
                "source": e.source,
                "kind": e.kind,
                "python_target": e.target,
                "python_ok": py_ok,
                "python_message": py_msg,
                "matlab_ok": matlab_ok,
                "matlab_message": matlab_msg,
                "parity": parity,
            }
        )

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORT_DIR / "mfile_parity_report.json"
    out.write_text(json.dumps({"summary": summary, "rows": rows}, indent=2), encoding="utf-8")

    print(json.dumps({"report": str(out.relative_to(REPO_ROOT)), **summary}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
