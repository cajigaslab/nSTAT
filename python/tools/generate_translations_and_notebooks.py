from __future__ import annotations

import json
import re
from pathlib import Path

from generate_example_notebooks import main as generate_notebooks

REPO_ROOT = Path(__file__).resolve().parents[2]
PORT_ROOT = REPO_ROOT / "python" / "matlab_port"


def _classify_m_file(path: Path) -> str:
    text = path.read_text(encoding="utf-8", errors="ignore")
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("%"):
            continue
        if s.startswith("classdef"):
            return "classdef"
        if s.startswith("function"):
            return "function"
        break
    return "script"


def _iter_matlab_sources() -> list[Path]:
    files: list[Path] = []
    for p in REPO_ROOT.rglob("*.m"):
        rel = p.relative_to(REPO_ROOT)
        if rel.parts and rel.parts[0] == "python":
            continue
        files.append(p)
    return sorted(files)


def _target_for_source(src: Path) -> str:
    rel = src.relative_to(REPO_ROOT)
    return str((PORT_ROOT / rel.parent / f"{src.stem}.py").relative_to(REPO_ROOT))


def build_translation_map() -> dict[str, object]:
    entries = []
    counts: dict[str, int] = {}
    for src in _iter_matlab_sources():
        kind = _classify_m_file(src)
        counts[kind] = counts.get(kind, 0) + 1
        entries.append(
            {
                "source": str(src.relative_to(REPO_ROOT)),
                "target": _target_for_source(src),
                "kind": kind,
                "status": "archived_reference",
                "note": "matlab_port is kept as historical scaffold; canonical implementation lives in python/nstat",
            }
        )

    return {
        "repo_root": str(REPO_ROOT),
        "output_root": str(PORT_ROOT),
        "counts": {"total": len(entries), "by_kind": counts},
        "entries": entries,
    }


def main() -> int:
    PORT_ROOT.mkdir(parents=True, exist_ok=True)

    mapping = build_translation_map()
    map_path = PORT_ROOT / "TRANSLATION_MAP.json"
    map_path.write_text(json.dumps(mapping, indent=2), encoding="utf-8")

    nb_rc = generate_notebooks()

    print(
        json.dumps(
            {
                "translation_map": str(map_path.relative_to(REPO_ROOT)),
                "matlab_sources": mapping["counts"]["total"],
                "notebook_generation_rc": nb_rc,
            },
            indent=2,
        )
    )
    return int(nb_rc)


if __name__ == "__main__":
    raise SystemExit(main())
