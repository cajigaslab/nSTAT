from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parents[2]
PORT_ROOT = REPO_ROOT / "python" / "matlab_port"
NOTEBOOK_ROOT = REPO_ROOT / "python" / "notebooks" / "helpfiles"


@dataclass(frozen=True)
class PortEntry:
    source: str
    target: str
    kind: str


ALIAS_IMPORTS: dict[str, tuple[str, str]] = {
    "DecodingAlgorithms.m": ("nstat.decoding_algorithms", "DecodingAlgorithms"),
    "analysis.m": ("nstat.analysis", "psth"),
}


def _sanitize_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", name)


def _iter_sources() -> list[Path]:
    files: set[Path] = set()
    for pattern in ("*.m", "*.mdl", "*.mdl.r*"):
        for path in REPO_ROOT.rglob(pattern):
            if not path.is_file():
                continue
            if PORT_ROOT in path.parents:
                continue
            files.add(path)
    return sorted(files)


def _ensure_package(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)
    cur = path
    while cur != REPO_ROOT:
        if cur.is_dir() and cur.name != "":
            init_path = cur / "__init__.py"
            if not init_path.exists():
                init_path.write_text("", encoding="utf-8")
        cur = cur.parent


def _first_code_line(lines: Iterable[str]) -> str:
    for line in lines:
        s = line.strip()
        if not s or s.startswith("%"):
            continue
        return s
    return ""


def _matlab_function_name(first_line: str) -> str | None:
    patterns = [
        r"^function\s+\[[^\]]*\]\s*=\s*(\w+)",
        r"^function\s+\w+\s*=\s*(\w+)",
        r"^function\s+(\w+)\s*\(",
        r"^function\s+(\w+)\s*$",
    ]
    for pat in patterns:
        m = re.match(pat, first_line)
        if m:
            return m.group(1)
    return None


def _matlab_function_args(first_line: str) -> list[str]:
    m = re.search(r"\(([^)]*)\)", first_line)
    if not m:
        return []
    out = []
    for part in m.group(1).split(","):
        token = part.strip()
        if token:
            out.append(_sanitize_name(token))
    return out


def _py_target_for(src: Path) -> Path:
    rel = src.relative_to(REPO_ROOT)
    out_dir = PORT_ROOT.joinpath(*rel.parts[:-1])
    _ensure_package(out_dir)

    if src.suffix == ".m":
        out_name = f"{src.stem}.py"
    else:
        out_name = f"{_sanitize_name(src.name)}.py"
    return out_dir / out_name


def _header(src_rel: str) -> str:
    return (
        '"""Auto-generated MATLAB-to-Python scaffold.\n\n'
        f"Source: {src_rel}\n"
        '"""\n\n'
        "from __future__ import annotations\n\n"
        "from pathlib import Path\n"
        "import numpy as np\n"
        "import pandas as pd\n"
        "from scipy.io import loadmat, savemat\n\n"
    )


def _content_for_m(src: Path, src_rel: str) -> tuple[str, str]:
    if src_rel == "helpfiles/nSTATPaperExamples.m":
        return (
            _header(src_rel)
            + "import json\n"
            + "import sys\n\n"
            + "THIS_FILE = Path(__file__).resolve()\n"
            + "PY_ROOT = THIS_FILE.parents[2]\n"
            + "if str(PY_ROOT) not in sys.path:\n"
            + "    sys.path.insert(0, str(PY_ROOT))\n\n"
            + "from nstat.paper_examples_full import run_full_paper_examples\n\n"
            + "def run(*, repo_root: str | Path | None = None) -> dict[str, dict[str, float]]:\n"
            + "    root = Path(repo_root).resolve() if repo_root is not None else THIS_FILE.parents[3]\n"
            + "    return run_full_paper_examples(root)\n\n"
            + "def main() -> int:\n"
            + "    print(json.dumps(run(), indent=2))\n"
            + "    return 0\n\n"
            + "if __name__ == '__main__':\n"
            + "    raise SystemExit(main())\n",
            "paper_examples_entrypoint",
        )

    base = src.name
    if base in ALIAS_IMPORTS:
        module_path, symbol = ALIAS_IMPORTS[base]
        return (
            _header(src_rel)
            + f"from {module_path} import {symbol}\n\n"
            + f"__all__ = ['{symbol}']\n",
            "alias",
        )

    text = src.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines()
    first = _first_code_line(lines)

    if first.startswith("classdef "):
        class_name = _sanitize_name(first.split()[1])
        body = (
            _header(src_rel)
            + f"class {class_name}:\n"
            + "    \"\"\"Scaffold translated from MATLAB classdef.\"\"\"\n\n"
            + "    def __init__(self, *args, **kwargs) -> None:\n"
            + "        self.args = args\n"
            + "        self.kwargs = kwargs\n\n"
            + "    def metadata(self) -> dict[str, object]:\n"
            + "        return {\n"
            + f"            'source': '{src_rel}',\n"
            + "            'args_count': len(self.args),\n"
            + "            'kwargs': sorted(list(self.kwargs.keys())),\n"
            + "        }\n"
        )
        return body, "class_scaffold"

    fn = _matlab_function_name(first)
    if fn is not None:
        args = _matlab_function_args(first)
        params = ", ".join([f"{a}=None" for a in args])
        if params:
            params = "*, " + params
        body = (
            _header(src_rel)
            + f"def {fn}({params}) -> dict[str, object]:\n"
            + "    frame = pd.DataFrame({'row': np.arange(3, dtype=int)})\n"
            + "    return {\n"
            + f"        'source': '{src_rel}',\n"
            + f"        'function': '{fn}',\n"
            + "        'rows': int(frame.shape[0]),\n"
            + "    }\n\n"
            + "def run(**kwargs) -> dict[str, object]:\n"
            + f"    return {fn}(**kwargs)\n"
        )
        return body, "function_scaffold"

    body = (
        _header(src_rel)
        + "def run(*, repo_root: str | Path | None = None) -> dict[str, object]:\n"
        + "    root = Path(repo_root).resolve() if repo_root is not None else Path.cwd()\n"
        + "    frame = pd.DataFrame({'line': [1, 2, 3], 'value': [1.0, 2.0, 3.0]})\n"
        + "    return {\n"
        + f"        'source': '{src_rel}',\n"
        + "        'repo_root': str(root),\n"
        + "        'demo_mean': float(frame['value'].mean()),\n"
        + "    }\n"
    )
    return body, "script_scaffold"


def _content_for_mdl(src: Path, src_rel: str) -> tuple[str, str]:
    body = (
        _header(src_rel)
        + f"SOURCE_MODEL = Path(r'{src}')\n\n"
        + "def load_text(path: str | Path | None = None) -> str:\n"
        + "    p = Path(path) if path is not None else SOURCE_MODEL\n"
        + "    return p.read_text(encoding='utf-8', errors='ignore')\n\n"
        + "def summarize(path: str | Path | None = None) -> dict[str, object]:\n"
        + "    text = load_text(path)\n"
        + "    lines = text.splitlines()\n"
        + "    frame = pd.DataFrame({'line_number': np.arange(1, len(lines) + 1), 'line_text': lines})\n"
        + "    return {\n"
        + f"        'source': '{src_rel}',\n"
        + "        'line_count': int(frame.shape[0]),\n"
        + "        'block_count_guess': int(frame['line_text'].str.contains('Block {', regex=False).sum()),\n"
        + "    }\n"
    )
    return body, "mdl_scaffold"


def _notebook_for_helpfile(src: Path) -> dict:
    rel = src.relative_to(REPO_ROOT)
    module_name = f"matlab_port.helpfiles.{src.stem}"
    title = f"{src.stem} (Python Translation)"

    code1 = (
        "from pathlib import Path\n"
        "import sys\n"
        "import importlib\n"
        "import json\n\n"
        "def find_repo_root(start: Path) -> Path:\n"
        "    cur = start.resolve()\n"
        "    for p in [cur, *cur.parents]:\n"
        "        if (p / '.git').exists() and (p / 'helpfiles').exists():\n"
        "            return p\n"
        "    raise RuntimeError('Could not find repository root')\n\n"
        "repo_root = find_repo_root(Path.cwd())\n"
        "py_root = repo_root / 'python'\n"
        "if str(py_root) not in sys.path:\n"
        "    sys.path.insert(0, str(py_root))\n"
        "print('repo_root =', repo_root)\n"
    )

    code2 = (
        f"module = importlib.import_module('{module_name}')\n"
        "if hasattr(module, 'run'):\n"
        "    out = module.run(repo_root=repo_root)\n"
        "elif hasattr(module, 'main'):\n"
        "    out = module.main()\n"
        "else:\n"
        "    out = {'status': 'no run/main entrypoint'}\n"
        "if isinstance(out, (dict, list)):\n"
        "    print(json.dumps(out, indent=2, default=str))\n"
        "else:\n"
        "    print(out)\n"
    )

    return {
        "cells": [
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": [
                    f"# {title}\\n",
                    "\\n",
                    f"Source MATLAB file: `{rel}`\\n",
                ],
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": code1.splitlines(keepends=True),
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": code2.splitlines(keepends=True),
            },
        ],
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3",
            },
            "language_info": {
                "name": "python",
                "version": "3",
            },
        },
        "nbformat": 4,
        "nbformat_minor": 5,
    }


def generate() -> dict[str, object]:
    _ensure_package(PORT_ROOT)
    NOTEBOOK_ROOT.mkdir(parents=True, exist_ok=True)

    entries: list[PortEntry] = []
    counts: dict[str, int] = {}

    for src in _iter_sources():
        src_rel = str(src.relative_to(REPO_ROOT))
        target = _py_target_for(src)

        if src.suffix == ".m":
            content, kind = _content_for_m(src, src_rel)
        else:
            content, kind = _content_for_mdl(src, src_rel)

        target.write_text(content, encoding="utf-8")
        entries.append(PortEntry(source=src_rel, target=str(target.relative_to(REPO_ROOT)), kind=kind))
        counts[kind] = counts.get(kind, 0) + 1

    helpfiles = sorted((REPO_ROOT / "helpfiles").glob("*.m"))
    nb_count = 0
    for src in helpfiles:
        nb = _notebook_for_helpfile(src)
        out = NOTEBOOK_ROOT / f"{src.stem}.ipynb"
        out.write_text(json.dumps(nb, indent=2), encoding="utf-8")
        nb_count += 1

    mapping = {
        "repo_root": str(REPO_ROOT),
        "output_root": str(PORT_ROOT),
        "counts": {"total": len(entries), "by_kind": counts, "helpfile_notebooks": nb_count},
        "entries": [e.__dict__ for e in entries],
    }
    map_path = PORT_ROOT / "TRANSLATION_MAP.json"
    map_path.write_text(json.dumps(mapping, indent=2), encoding="utf-8")

    return {
        "translated_files": len(entries),
        "notebooks": nb_count,
        "map": str(map_path.relative_to(REPO_ROOT)),
        "kinds": counts,
    }


if __name__ == "__main__":
    print(json.dumps(generate(), indent=2))
