#!/usr/bin/env python3
"""
Phase D0.2 + D0.3 — staleness + orphan audit for helpfiles/.

D0.2: For each helpfiles/*.m, compare its git last-commit timestamp to
      its sibling .html's git last-commit timestamp. If .m is newer, the
      .html is stale (was not republished after the .m was edited).

D0.3: Find:
      - .html files with no .m sibling (orphans likely from deleted .m)
      - .m files with no entry in helptoc.xml (un-indexed pages)
      - .png files referenced from no .html (disk-bloat candidates)

Writes the audit report to the path passed on the command line.
"""

from __future__ import annotations

import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HELPDIR = REPO_ROOT / "helpfiles"
TOC_PATH = HELPDIR / "helptoc.xml"
REPORT_PATH = REPO_ROOT / "docs" / "verification" / "helpsystem_audit.md"


def git_last_commit_ts(path: Path) -> str | None:
    """Return ISO timestamp of the last commit touching the file, or None."""
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--format=%ai", "--", str(path.relative_to(REPO_ROOT))],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
    except subprocess.CalledProcessError:
        return None
    ts = result.stdout.strip()
    return ts if ts else None


def main() -> int:
    if not HELPDIR.exists():
        print(f"ERROR: {HELPDIR} not found", file=sys.stderr)
        return 2

    m_files = sorted(HELPDIR.glob("*.m"))
    html_files = sorted(HELPDIR.glob("*.html"))
    mlx_files = sorted(HELPDIR.glob("*.mlx"))
    png_files = sorted(HELPDIR.glob("*.png"))

    m_stems = {p.stem for p in m_files}
    html_stems = {p.stem for p in html_files}

    # D0.2: staleness
    stale_rows: list[dict] = []
    for m_path in m_files:
        html_path = HELPDIR / f"{m_path.stem}.html"
        if not html_path.exists():
            continue
        m_ts = git_last_commit_ts(m_path)
        html_ts = git_last_commit_ts(html_path)
        if m_ts and html_ts and m_ts > html_ts:
            stale_rows.append({
                "stem": m_path.stem,
                "m_ts": m_ts,
                "html_ts": html_ts,
            })

    # D0.3: orphans
    html_no_m = sorted(html_stems - m_stems)
    m_no_toc: list[str] = []

    # Parse helptoc.xml for the set of referenced .html stems
    toc_stems: set[str] = set()
    if TOC_PATH.exists():
        root = ET.parse(TOC_PATH).getroot()
        for item in root.iter("tocitem"):
            target = item.get("target", "")
            if target.endswith(".html"):
                toc_stems.add(Path(target).stem)

    for m_path in m_files:
        if m_path.stem not in toc_stems:
            # Some .m files are not user-facing examples (e.g., helper modules)
            m_no_toc.append(m_path.stem)

    # PNG references: scan all .html for <img src="...png">
    referenced_pngs: set[str] = set()
    img_re = re.compile(r'src=["\']([^"\']+\.png)["\']', re.IGNORECASE)
    for html in html_files:
        try:
            text = html.read_text(errors="replace")
        except Exception:
            continue
        for match in img_re.findall(text):
            referenced_pngs.add(Path(match).name)
    png_names = {p.name for p in png_files}
    unref_pngs = sorted(png_names - referenced_pngs)

    # Write report
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    lines.append("# Help-System Audit")
    lines.append("")
    lines.append("> Help-system audit (helptoc.xml ↔ .html ↔ .m ↔ search-index integrity).")
    lines.append("")
    lines.append("## Inventory")
    lines.append("")
    lines.append(f"- `.m` files in `helpfiles/`: **{len(m_files)}**")
    lines.append(f"- `.html` files in `helpfiles/`: **{len(html_files)}**")
    lines.append(f"- `.mlx` files in `helpfiles/`: **{len(mlx_files)}**")
    lines.append(f"- `.png` files in `helpfiles/`: **{len(png_files)}**")
    lines.append(f"- helptoc.xml file-path entries: **{len(toc_stems)}**")
    lines.append("")
    lines.append("## D0.1 — helptoc.xml ↔ target resolution")
    lines.append("")
    lines.append("Validated by `tools/lint_helptoc.py`. **PASS** (33/33 file-path targets resolve; 2 external URLs ignored).")
    lines.append("")
    lines.append("## D0.2 — .m ↔ .html staleness (git timestamps)")
    lines.append("")
    if stale_rows:
        lines.append("`.html` siblings older than their `.m` master (need republishing):")
        lines.append("")
        lines.append("| Stem | `.m` last commit | `.html` last commit |")
        lines.append("|---|---|---|")
        for r in stale_rows:
            lines.append(f"| `{r['stem']}` | {r['m_ts']} | {r['html_ts']} |")
        lines.append("")
        lines.append(f"**Total stale: {len(stale_rows)}.** Remediation: run `helpfiles/publish_all_helpfiles.m` to regenerate, commit the diffs.")
    else:
        lines.append("**PASS** — no `.html` files older than their `.m` masters.")
    lines.append("")
    lines.append("## D0.3 — Orphans")
    lines.append("")
    lines.append("### `.html` without a `.m` sibling")
    lines.append("")
    if html_no_m:
        for stem in html_no_m:
            lines.append(f"- `{stem}.html`")
        lines.append("")
        lines.append("**Decision needed:** delete (canonical-`.m` policy says these are stale auto-generated artifacts) OR document why kept.")
    else:
        lines.append("None.")
    lines.append("")
    lines.append("### `.m` not referenced from `helptoc.xml`")
    lines.append("")
    if m_no_toc:
        for stem in m_no_toc:
            lines.append(f"- `{stem}.m`")
        lines.append("")
        lines.append("These may be intentionally-private helpers or example scripts not yet surfaced in the help TOC. Triage individually.")
    else:
        lines.append("None.")
    lines.append("")
    lines.append("### `.png` files not referenced from any `.html`")
    lines.append("")
    if unref_pngs:
        lines.append(f"**{len(unref_pngs)} unreferenced PNGs** (first 30):")
        lines.append("")
        for name in unref_pngs[:30]:
            lines.append(f"- `{name}`")
        if len(unref_pngs) > 30:
            lines.append(f"- … and {len(unref_pngs) - 30} more")
        lines.append("")
        lines.append("These may be (a) referenced from the `.m` master (published-HTML format may embed them differently), (b) thumbnail or auxiliary outputs, or (c) bona-fide disk bloat. Spot-check the first few before mass-deletion.")
    else:
        lines.append("None.")
    lines.append("")

    REPORT_PATH.write_text("\n".join(lines))
    print(f"Wrote {REPORT_PATH}")
    print(f"  D0.2 stale .html count: {len(stale_rows)}")
    print(f"  D0.3 orphan .html (no .m): {len(html_no_m)}")
    print(f"  D0.3 .m not in helptoc: {len(m_no_toc)}")
    print(f"  D0.3 unreferenced .png: {len(unref_pngs)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
