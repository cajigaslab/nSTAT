from __future__ import annotations

import contextlib
import html
import importlib
import io
import json
import re
import subprocess
import sys
import traceback
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
NOTEBOOK_ROOT = REPO_ROOT / "python" / "notebooks" / "helpfiles"
REPORT_DIR = REPO_ROOT / "python" / "reports"
MATLAB_BIN = Path("/Applications/MATLAB_R2025b.app/bin/matlab")


def normalize(text: str) -> str:
    text = text.replace("\xa0", " ")
    text = re.sub(r"\s+", " ", text)
    return text.strip().lower()


def parse_html_reference(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {
            "exists": False,
            "title": path.stem,
            "sections": [],
            "figures": [],
            "code_outputs": [],
        }

    raw = path.read_text(encoding="utf-8", errors="ignore")

    def clean(s: str) -> str:
        s = re.sub(r"<[^>]+>", "", s, flags=re.S)
        s = html.unescape(s)
        s = s.replace("\xa0", " ")
        s = re.sub(r"\s+", " ", s).strip()
        return s

    title_match = re.search(r"<title>(.*?)</title>", raw, flags=re.I | re.S)
    title = clean(title_match.group(1)) if title_match else path.stem

    sections = [clean(x) for x in re.findall(r"<h2[^>]*>(.*?)</h2>", raw, flags=re.I | re.S)]
    sections = [s for s in sections if s]

    figures = sorted(dict.fromkeys(re.findall(r'src="([^"]+_\d+\.png)"', raw, flags=re.I)))

    code_blocks = re.findall(r'<pre class="codeoutput">(.*?)</pre>', raw, flags=re.I | re.S)
    code_outputs: list[str] = []
    for b in code_blocks:
        c = clean(b)
        if c:
            code_outputs.append(c[:500])

    return {
        "exists": True,
        "title": title,
        "sections": sections,
        "figures": figures,
        "code_outputs": code_outputs,
    }


def run_python_module(stem: str) -> dict[str, Any]:
    if str(REPO_ROOT / "python") not in sys.path:
        sys.path.insert(0, str(REPO_ROOT / "python"))
    mod = importlib.import_module(f"matlab_port.helpfiles.{stem}")
    if not hasattr(mod, "run"):
        return {"ok": False, "error": "missing run()"}
    try:
        out = mod.run(repo_root=REPO_ROOT)
        return {"ok": True, "output": out}
    except Exception as exc:  # noqa: BLE001
        return {
            "ok": False,
            "error": "".join(traceback.format_exception_only(type(exc), exc)).strip(),
        }


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


def run_matlab_script(m_rel: str, timeout_s: int) -> dict[str, Any]:
    if not MATLAB_BIN.exists():
        return {"ok": False, "error": "matlab_not_found", "stdout": "", "returncode": None}

    repo_q = str(REPO_ROOT).replace("'", "''")
    m_q = m_rel.replace("'", "''")
    cmd = (
        "restoredefaultpath; "
        f"repo='{repo_q}'; "
        "cd(repo); addpath(genpath(repo),'-begin'); "
        "set(0,'DefaultFigureVisible','off'); close all force; "
        "try; "
        f"run(fullfile(repo,'{m_q}')); "
        "figs=numel(findall(0,'Type','figure')); "
        "vars=who; "
        "disp('CODEX_MATLAB_OK'); "
        "fprintf('CODEX_MATLAB_FIGS:%d\\n',figs); "
        "fprintf('CODEX_MATLAB_VARS:%d\\n',numel(vars)); "
        "catch ME; "
        "disp('CODEX_MATLAB_FAIL'); "
        "disp([ME.identifier ' | ' ME.message]); "
        "end; exit(0);"
    )
    try:
        cp = subprocess.run(
            [str(MATLAB_BIN), "-batch", cmd],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            timeout=timeout_s,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timeout", "stdout": "", "returncode": None}

    stdout = (cp.stdout or "") + "\n" + (cp.stderr or "")
    ok = "CODEX_MATLAB_OK" in stdout
    err = ""
    if not ok:
        tail = [ln for ln in stdout.splitlines() if ln.strip()][-10:]
        err = "\n".join(tail) if tail else "matlab_failed_without_message"

    figs_match = re.search(r"CODEX_MATLAB_FIGS:(\d+)", stdout)
    vars_match = re.search(r"CODEX_MATLAB_VARS:(\d+)", stdout)
    return {
        "ok": ok,
        "error": err,
        "stdout": stdout,
        "returncode": cp.returncode,
        "figures": int(figs_match.group(1)) if figs_match else None,
        "vars": int(vars_match.group(1)) if vars_match else None,
    }


def snippet_hits(snippets: list[str], text: str) -> dict[str, Any]:
    n_text = normalize(text)
    hits = 0
    used: list[str] = []
    for s in snippets:
        key = normalize(s)
        if not key:
            continue
        if key in n_text:
            hits += 1
            used.append(s)
    return {"hits": hits, "total": len(snippets), "matched_snippets": used}


def compare_structure(stem: str, py_out: dict[str, Any], html_ref: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(py_out, dict):
        return {
            "dict_output": False,
            "section_count_match": False,
            "figure_count_match": False,
            "keys": [],
        }

    if stem == "nSTATPaperExamples":
        expected_keys = {
            "experiment1",
            "experiment2",
            "experiment3",
            "experiment3b",
            "experiment4",
            "experiment5",
            "experiment5b",
            "experiment6",
        }
        got_keys = set(py_out.keys())
        return {
            "dict_output": True,
            "paper_examples_key_match": got_keys == expected_keys,
            "missing_keys": sorted(list(expected_keys - got_keys)),
            "extra_keys": sorted(list(got_keys - expected_keys)),
            "keys": sorted(list(got_keys)),
        }

    sec_expected = len(html_ref.get("sections", []))
    fig_expected = len(html_ref.get("figures", []))
    sec_got = py_out.get("section_count")
    fig_got = py_out.get("figure_count")
    return {
        "dict_output": True,
        "section_count_match": sec_got == sec_expected,
        "figure_count_match": fig_got == fig_expected,
        "section_count_expected": sec_expected,
        "section_count_got": sec_got,
        "figure_count_expected": fig_expected,
        "figure_count_got": fig_got,
        "keys": sorted(list(py_out.keys())),
    }


def main() -> int:
    m_files = sorted((REPO_ROOT / "helpfiles").glob("*Examples.m"))
    rows: list[dict[str, Any]] = []
    summary = {
        "total_examples": len(m_files),
        "python_modules_ok": 0,
        "notebooks_ok": 0,
        "matlab_ok": 0,
        "structure_match_ok": 0,
        "matlab_vs_notebook_output_alignment_ok": 0,
    }

    for m in m_files:
        stem = m.stem
        m_rel = str(m.relative_to(REPO_ROOT))
        html_ref = parse_html_reference(m.with_suffix(".html"))
        py = run_python_module(stem)
        nb = execute_notebook(NOTEBOOK_ROOT / f"{stem}.ipynb")
        timeout_s = 1800 if stem == "nSTATPaperExamples" else 240
        matlab = run_matlab_script(m_rel, timeout_s=timeout_s)

        if py["ok"]:
            summary["python_modules_ok"] += 1
        if nb["ok"]:
            summary["notebooks_ok"] += 1
        if matlab["ok"]:
            summary["matlab_ok"] += 1

        structure = compare_structure(stem, py.get("output", {}), html_ref) if py["ok"] else {"dict_output": False}
        if stem == "nSTATPaperExamples":
            structure_ok = bool(structure.get("paper_examples_key_match"))
        else:
            structure_ok = bool(structure.get("section_count_match")) and bool(structure.get("figure_count_match"))
        if structure_ok:
            summary["structure_match_ok"] += 1

        snippets = html_ref.get("code_outputs", [])[:8]
        m_hits = snippet_hits(snippets, matlab.get("stdout", ""))
        nb_hits = snippet_hits(snippets, nb.get("stdout", ""))
        if m_hits["total"] == 0:
            aligned = True
        else:
            aligned = m_hits["hits"] == nb_hits["hits"]
        if aligned:
            summary["matlab_vs_notebook_output_alignment_ok"] += 1

        rows.append(
            {
                "example": stem,
                "matlab_source": m_rel,
                "python_module_ok": py["ok"],
                "python_module_error": py.get("error", ""),
                "python_output_keys": sorted(list(py.get("output", {}).keys())) if py["ok"] and isinstance(py.get("output"), dict) else [],
                "notebook_ok": nb["ok"],
                "notebook_error": nb.get("error", ""),
                "notebook_code_cells": nb.get("code_cells"),
                "matlab_ok": matlab["ok"],
                "matlab_error": matlab.get("error", ""),
                "matlab_figures": matlab.get("figures"),
                "matlab_vars": matlab.get("vars"),
                "structure_check": structure,
                "expected_output_snippets_considered": len(snippets),
                "matlab_snippet_hits": m_hits,
                "notebook_snippet_hits": nb_hits,
                "matlab_notebook_output_aligned": aligned,
            }
        )

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORT_DIR / "examples_notebook_verification.json"
    out.write_text(json.dumps({"summary": summary, "rows": rows}, indent=2), encoding="utf-8")

    print(json.dumps({"report": str(out.relative_to(REPO_ROOT)), **summary}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
