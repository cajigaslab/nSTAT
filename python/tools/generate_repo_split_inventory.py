from __future__ import annotations

import json
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PY_ROOT = REPO_ROOT / "python"
HELPFILES_ROOT = REPO_ROOT / "helpfiles"
TOC_PATH = HELPFILES_ROOT / "helptoc.xml"
OUT_ROOT = PY_ROOT / "reports" / "repo_split_inventory"


def _utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _slugify(value: str) -> str:
    out = []
    for ch in value.strip().lower():
        if ch.isalnum():
            out.append(ch)
    return "".join(out)


def _iter_toc_targets() -> list[dict[str, str]]:
    tree = ET.parse(TOC_PATH)
    root = tree.getroot()

    examples_node = None
    for item in root.iter("tocitem"):
        if item.attrib.get("id") == "nstat_examples":
            examples_node = item
            break

    example_stems: set[str] = set()
    if examples_node is not None:
        for item in examples_node.findall("tocitem"):
            target = item.attrib.get("target", "").strip()
            if target:
                example_stems.add(Path(target).stem)

    rows: list[dict[str, str]] = []
    seen: set[str] = set()
    for item in root.iter("tocitem"):
        target = item.attrib.get("target", "").strip()
        if not target:
            continue
        if target.startswith("http://") or target.startswith("https://"):
            continue
        stem = Path(target).stem
        key = f"{stem}|{target}"
        if key in seen:
            continue
        seen.add(key)
        rows.append(
            {
                "title": " ".join("".join(item.itertext()).split()),
                "target": target,
                "stem": stem,
                "is_example_topic": stem in example_stems,
            }
        )
    return rows


def _file_stem_set(paths: list[Path], exclude_dunder: bool = False) -> set[str]:
    out: set[str] = set()
    for p in paths:
        stem = p.stem
        if exclude_dunder and stem.startswith("__"):
            continue
        out.add(stem)
    return out


def _write_json(path: Path, payload: dict | list) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def main() -> int:
    if not TOC_PATH.exists():
        raise FileNotFoundError(f"Missing TOC file: {TOC_PATH}")

    toc_rows = _iter_toc_targets()
    toc_stems = {row["stem"] for row in toc_rows}
    example_stems = {row["stem"] for row in toc_rows if row["is_example_topic"]}

    matlab_m = sorted(HELPFILES_ROOT.glob("*.m"))
    matlab_mlx = sorted(HELPFILES_ROOT.glob("*.mlx"))
    matlab_html = sorted(HELPFILES_ROOT.glob("*.html"))

    matlab_m_stems = _file_stem_set(matlab_m)
    matlab_mlx_stems = _file_stem_set(matlab_mlx)
    matlab_html_stems = _file_stem_set(matlab_html)

    py_docs_topics = sorted((PY_ROOT / "docs" / "topics").glob("*.rst"))
    py_nb_topics = sorted((PY_ROOT / "notebooks" / "helpfiles").glob("*.ipynb"))
    py_example_topics = sorted((PY_ROOT / "examples" / "help_topics").glob("*.py"))

    py_doc_stems = _file_stem_set(py_docs_topics)
    py_nb_stems = _file_stem_set(py_nb_topics)
    py_example_stems = _file_stem_set(py_example_topics, exclude_dunder=True)
    py_doc_slugs = {_slugify(s) for s in py_doc_stems}

    coverage_rows: list[dict[str, object]] = []
    for row in sorted(toc_rows, key=lambda r: r["stem"]):
        stem = row["stem"]
        stem_slug = _slugify(stem)
        coverage_rows.append(
            {
                **row,
                "matlab_m_exists": stem in matlab_m_stems,
                "matlab_mlx_exists": stem in matlab_mlx_stems,
                "matlab_html_exists": stem in matlab_html_stems,
                "python_doc_exists": stem_slug in py_doc_slugs,
                "python_notebook_exists": stem in py_nb_stems,
                "python_example_script_exists": stem in py_example_stems,
            }
        )

    example_rows = [r for r in coverage_rows if bool(r["is_example_topic"])]
    example_all_python_ok = [
        r
        for r in example_rows
        if bool(r["python_doc_exists"])
        and bool(r["python_notebook_exists"])
        and bool(r["python_example_script_exists"])
    ]
    matlab_example_has_mlx = [r for r in example_rows if bool(r["matlab_mlx_exists"])]

    summary = {
        "generated_at_utc": _utc_now(),
        "repo_root": str(REPO_ROOT),
        "toc_target_topics": len(toc_rows),
        "toc_example_topics": len(example_rows),
        "matlab_files": {
            "m": len(matlab_m),
            "mlx": len(matlab_mlx),
            "html": len(matlab_html),
        },
        "python_assets": {
            "docs_topics_rst": len(py_docs_topics),
            "notebooks_ipynb": len(py_nb_topics),
            "example_scripts_py": len(py_example_topics),
        },
        "coverage_counts": {
            "toc_topics_with_python_docs": sum(1 for r in coverage_rows if bool(r["python_doc_exists"])),
            "toc_topics_with_python_notebooks": sum(1 for r in coverage_rows if bool(r["python_notebook_exists"])),
            "toc_topics_with_python_example_scripts": sum(
                1 for r in coverage_rows if bool(r["python_example_script_exists"])
            ),
            "example_topics_full_python_coverage": len(example_all_python_ok),
            "example_topics_with_matlab_mlx": len(matlab_example_has_mlx),
        },
        "example_topic_stems_from_toc": sorted(example_stems),
        "python_only_topic_stems_not_in_toc": sorted(py_example_stems - toc_stems),
    }

    _write_json(OUT_ROOT / "summary.json", summary)
    _write_json(OUT_ROOT / "topic_coverage_matrix.json", coverage_rows)
    _write_json(
        OUT_ROOT / "split_readiness_gates.json",
        {
            "python_example_topics_expected": len(example_rows),
            "python_example_topics_ready": len(example_all_python_ok),
            "python_example_topics_missing_coverage": [
                r["stem"] for r in example_rows if r not in example_all_python_ok
            ],
            "matlab_example_topics_expected": len(example_rows),
            "matlab_example_topics_with_mlx": len(matlab_example_has_mlx),
            "matlab_example_topics_missing_mlx": [
                r["stem"] for r in example_rows if not bool(r["matlab_mlx_exists"])
            ],
            "pass": len(example_rows) == len(example_all_python_ok) and len(example_rows) == len(matlab_example_has_mlx),
        },
    )

    print(json.dumps(summary, indent=2))
    print(f"wrote={OUT_ROOT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
