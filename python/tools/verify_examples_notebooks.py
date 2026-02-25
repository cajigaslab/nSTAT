from __future__ import annotations

import contextlib
import importlib
import io
import json
import sys
import traceback
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
NOTEBOOK_ROOT = REPO_ROOT / "python" / "notebooks" / "helpfiles"
SRC_ROOT = REPO_ROOT / "python" / "examples" / "help_topics"
REPORT_DIR = REPO_ROOT / "python" / "reports"
TOC_PATH = REPO_ROOT / "helpfiles" / "helptoc.xml"
PY_ROOT = REPO_ROOT / "python"
if str(PY_ROOT) not in sys.path:
    sys.path.insert(0, str(PY_ROOT))


def example_topics() -> list[tuple[str, str]]:
    tree = ET.parse(TOC_PATH)
    root = tree.getroot()
    examples = None
    for item in root.iter("tocitem"):
        if item.attrib.get("id") == "nstat_examples":
            examples = item
            break
    if examples is None:
        raise RuntimeError("Unable to locate examples node in helptoc.xml")

    out: list[tuple[str, str]] = []
    for item in examples.findall("tocitem"):
        title = " ".join("".join(item.itertext()).split())
        target = item.attrib.get("target", "")
        if target:
            out.append((title, target))
    return out


def run_python_module(stem: str) -> dict[str, Any]:
    try:
        mod = importlib.import_module(f"examples.help_topics.{stem}")
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": f"import_error: {exc}"}

    if not hasattr(mod, "run"):
        return {"ok": False, "error": "missing run()"}
    try:
        out = mod.run(repo_root=REPO_ROOT)
    except Exception as exc:  # noqa: BLE001
        return {
            "ok": False,
            "error": "".join(traceback.format_exception_only(type(exc), exc)).strip(),
        }
    return {"ok": True, "output": out}


def execute_notebook(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"ok": False, "error": "notebook_missing", "stdout": "", "code_cells": 0}
    data = json.loads(path.read_text(encoding="utf-8"))
    ns: dict[str, Any] = {}
    buf = io.StringIO()
    code_cells = 0
    try:
        for idx, cell in enumerate(data.get("cells", []), start=1):
            if cell.get("cell_type") != "code":
                continue
            code_cells += 1
            code = "".join(cell.get("source", []))
            with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
                exec(compile(code, f"{path}:{idx}", "exec"), ns, ns)
    except Exception as exc:  # noqa: BLE001
        return {
            "ok": False,
            "error": "".join(traceback.format_exception_only(type(exc), exc)).strip(),
            "stdout": buf.getvalue(),
            "code_cells": code_cells,
        }
    return {"ok": True, "error": "", "stdout": buf.getvalue(), "code_cells": code_cells}


def main() -> int:
    topics = example_topics()
    rows: list[dict[str, Any]] = []
    summary = {
        "total_examples": len(topics),
        "python_modules_ok": 0,
        "notebooks_ok": 0,
        "topic_alignment_ok": 0,
    }

    for title, target in topics:
        stem = Path(target).stem
        py = run_python_module(stem)
        nb = execute_notebook(NOTEBOOK_ROOT / f"{stem}.ipynb")

        if py["ok"]:
            summary["python_modules_ok"] += 1
        if nb["ok"]:
            summary["notebooks_ok"] += 1

        topic_ok = bool(py.get("ok") and isinstance(py.get("output"), dict) and py["output"].get("topic") == stem)
        if topic_ok:
            summary["topic_alignment_ok"] += 1

        rows.append(
            {
                "example": stem,
                "title": title,
                "matlab_target": target,
                "python_module_ok": py["ok"],
                "python_module_error": py.get("error", ""),
                "python_output_keys": sorted(list(py.get("output", {}).keys())) if py["ok"] and isinstance(py.get("output"), dict) else [],
                "notebook_ok": nb["ok"],
                "notebook_error": nb.get("error", ""),
                "notebook_code_cells": nb.get("code_cells"),
                "topic_alignment_ok": topic_ok,
            }
        )

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORT_DIR / "examples_notebook_verification.json"
    out.write_text(json.dumps({"summary": summary, "rows": rows}, indent=2), encoding="utf-8")

    print(json.dumps({"report": str(out.relative_to(REPO_ROOT)), **summary}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
