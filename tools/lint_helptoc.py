#!/usr/bin/env python3
"""
tools/lint_helptoc.py — validate every <tocitem target="X.html"> in
helpfiles/helptoc.xml points at an existing helpfiles/X.html file.

Phase D0.1 of 2026-05-20-comprehensive-codebase-audit.md.

Exit codes:
  0  every target resolves
  1  one or more broken targets
  2  helptoc.xml itself missing or malformed
"""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HELPDIR = REPO_ROOT / "helpfiles"
TOC_PATH = HELPDIR / "helptoc.xml"


def main() -> int:
    if not TOC_PATH.exists():
        print(f"ERROR: {TOC_PATH} not found", file=sys.stderr)
        return 2

    try:
        tree = ET.parse(TOC_PATH)
    except ET.ParseError as e:
        print(f"ERROR: failed to parse {TOC_PATH}: {e}", file=sys.stderr)
        return 2

    root = tree.getroot()
    targets: list[tuple[str, str]] = []
    for item in root.iter("tocitem"):
        target = item.get("target")
        title = (item.text or "").strip()
        if target:
            targets.append((target, title))

    broken: list[tuple[str, str]] = []
    external: list[tuple[str, str]] = []
    for target, title in targets:
        if target.startswith(("http://", "https://", "mailto:")):
            external.append((target, title))
            continue
        if not (HELPDIR / target).exists():
            broken.append((target, title))

    print(f"helptoc.xml: {len(targets)} target entries")
    print(f"  resolved : {len(targets) - len(broken) - len(external)}")
    print(f"  external : {len(external)} (URLs/mailto, not file paths)")
    print(f"  broken   : {len(broken)}")

    if broken:
        print("\nBroken targets:")
        for target, title in broken:
            print(f"  - {target:<48s} ({title})")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
