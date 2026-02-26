from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TOC_PATH = REPO_ROOT / "helpfiles" / "helptoc.xml"
DOCS_ROOT = REPO_ROOT / "python" / "docs"
TOPICS_DIR = DOCS_ROOT / "topics"
HELP_TOPICS_INDEX = DOCS_ROOT / "help_topics.rst"


def _slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return value.strip("_") or "topic"


def _expected_topic_slugs() -> list[str]:
    tree = ET.parse(TOC_PATH)
    root = tree.getroot()
    seen: set[str] = set()
    slugs: list[str] = []
    for item in root.iter("tocitem"):
        target = item.attrib.get("target", "").strip()
        if not target:
            continue
        if target.startswith("http://") or target.startswith("https://"):
            continue
        slug = _slugify(Path(target).stem)
        if slug in seen:
            continue
        seen.add(slug)
        slugs.append(slug)
    return slugs


def _index_entries() -> set[str]:
    if not HELP_TOPICS_INDEX.exists():
        return set()
    entries: set[str] = set()
    for line in HELP_TOPICS_INDEX.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line.startswith("topics/"):
            continue
        entries.add(line.split("/", 1)[1])
    return entries


def main() -> int:
    if not TOC_PATH.exists():
        print(json.dumps({"error": f"missing TOC: {TOC_PATH}"}, indent=2))
        return 2

    expected = _expected_topic_slugs()
    index = _index_entries()

    missing_topic_files = [slug for slug in expected if not (TOPICS_DIR / f"{slug}.rst").exists()]
    missing_index_entries = [slug for slug in expected if slug not in index]

    payload = {
        "toc_topics": len(expected),
        "missing_topic_files": missing_topic_files,
        "missing_index_entries": missing_index_entries,
        "pass": not missing_topic_files and not missing_index_entries,
    }
    print(json.dumps(payload, indent=2))

    return 0 if payload["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
