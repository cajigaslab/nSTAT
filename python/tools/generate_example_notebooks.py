from __future__ import annotations

import json
import xml.etree.ElementTree as ET
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TOC_PATH = REPO_ROOT / "helpfiles" / "helptoc.xml"
NB_ROOT = REPO_ROOT / "python" / "notebooks" / "helpfiles"
SRC_ROOT = REPO_ROOT / "python" / "examples" / "help_topics"


def _example_topics() -> list[tuple[str, str]]:
    tree = ET.parse(TOC_PATH)
    root = tree.getroot()
    examples = None
    for item in root.iter("tocitem"):
        if item.attrib.get("id") == "nstat_examples":
            examples = item
            break
    if examples is None:
        raise RuntimeError("Could not find examples section in helptoc.xml")

    topics: list[tuple[str, str]] = []
    for item in examples.findall("tocitem"):
        title = " ".join("".join(item.itertext()).split())
        target = item.attrib.get("target", "")
        if not target:
            continue
        topics.append((title, target))
    return topics


def _build_notebook(title: str, stem: str, matlab_target: str) -> dict:
    code_setup = (
        "from pathlib import Path\n"
        "import sys\n"
        "import json\n\n"
        "def find_repo_root(start: Path) -> Path:\n"
        "    cur = start.resolve()\n"
        "    for p in [cur, *cur.parents]:\n"
        "        if (p / '.git').exists() and (p / 'python').exists() and (p / 'helpfiles').exists():\n"
        "            return p\n"
        "    raise RuntimeError('Could not find nSTAT repo root from notebook cwd')\n\n"
        "repo_root = find_repo_root(Path.cwd())\n"
        "py_root = repo_root / 'python'\n"
        "if str(py_root) not in sys.path:\n"
        "    sys.path.insert(0, str(py_root))\n"
        "print('repo_root =', repo_root)\n"
    )

    code_run = (
        f"from examples.help_topics.{stem} import run\n"
        "out = run(repo_root=repo_root)\n"
        "print(json.dumps(out, indent=2, default=str))\n"
    )

    code_check = (
        "assert isinstance(out, dict)\n"
        "assert 'topic' in out\n"
        "print('Notebook execution check: PASS')\n"
    )

    return {
        "cells": [
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": [
                    f"# {title}\\n",
                    "\\n",
                    "Executable Python notebook generated from source help-topic scripts.\\n",
                    f"MATLAB help target: `{matlab_target}`\\n",
                ],
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": code_setup.splitlines(keepends=True),
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": code_run.splitlines(keepends=True),
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": code_check.splitlines(keepends=True),
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


def main() -> int:
    NB_ROOT.mkdir(parents=True, exist_ok=True)
    topics = _example_topics()

    generated = 0
    missing_sources: list[str] = []
    for title, target in topics:
        stem = Path(target).stem
        source_mod = SRC_ROOT / f"{stem}.py"
        if not source_mod.exists():
            missing_sources.append(stem)
            continue

        nb = _build_notebook(title, stem, target)
        out = NB_ROOT / f"{stem}.ipynb"
        out.write_text(json.dumps(nb, indent=2), encoding="utf-8")
        generated += 1

    report = {
        "total_topics": len(topics),
        "generated": generated,
        "missing_sources": missing_sources,
        "output_dir": str(NB_ROOT.relative_to(REPO_ROOT)),
    }
    print(json.dumps(report, indent=2))

    if missing_sources:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
