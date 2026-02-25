from __future__ import annotations

import re
import xml.etree.ElementTree as ET
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TOC_PATH = REPO_ROOT / "helpfiles" / "helptoc.xml"
DOCS_ROOT = REPO_ROOT / "python" / "docs"
TOPICS_DIR = DOCS_ROOT / "topics"

CLASS_API_MAP = {
    "SignalObj": "nstat.signal.Signal",
    "Covariate": "nstat.signal.Covariate",
    "CovColl": "nstat.trial.CovariateCollection",
    "nSpikeTrain": "nstat.spikes.SpikeTrain",
    "nspikeTrain": "nstat.spikes.SpikeTrain",
    "nstColl": "nstat.spikes.SpikeTrainCollection",
    "Events": "nstat.events.Events",
    "History": "nstat.history.HistoryBasis",
    "Trial": "nstat.trial.Trial",
    "TrialConfig": "nstat.trial.TrialConfig",
    "ConfigColl": "nstat.trial.ConfigCollection",
    "Analysis": "nstat.analysis.Analysis",
    "FitResult": "nstat.fit.FitResult",
    "FitResSummary": "nstat.fit.FitSummary",
    "PPThinning": "nstat.cif.CIFModel.simulate",
    "PSTHEstimation": "nstat.spikes.SpikeTrainCollection.psth",
    "DecodingExample": "nstat.decoding.DecoderSuite",
    "DecodingExampleWithHist": "nstat.decoding.DecoderSuite",
    "StimulusDecode2D": "nstat.decoding.DecoderSuite",
}


def _slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return value.strip("_") or "topic"


def _iter_topics(root: ET.Element):
    for item in root.iter("tocitem"):
        target = item.attrib.get("target", "").strip()
        title = " ".join("".join(item.itertext()).split())
        if not target:
            continue
        yield title, target


def _mapping_for_target(target: str) -> tuple[str, str]:
    stem = Path(target).stem
    base = stem[:-8] if stem.endswith("Examples") else stem
    matlab_api = base
    python_api = CLASS_API_MAP.get(base, "nstat (canonical module by topic)")
    return matlab_api, python_api


def _topic_body(title: str, target: str) -> str:
    is_example = "example" in target.lower() or target.lower().endswith("examples.html")
    notebook_name = Path(target).stem
    matlab_api, python_api = _mapping_for_target(target)
    lines = [
        title,
        "=" * len(title),
        "",
        f"MATLAB help target: ``{target}``",
        "",
        "Concept",
        "-------",
        "This page mirrors the corresponding MATLAB help topic and documents the Python standalone equivalent.",
        "",
        "API Mapping (MATLAB -> Python)",
        "------------------------------",
        ".. list-table::",
        "   :header-rows: 1",
        "",
        "   * - MATLAB API",
        "     - Python API",
        f"   * - ``{matlab_api}``",
        f"     - ``{python_api}``",
        "",
        "Migration Callout",
        "-----------------",
        "- MATLAB-style compatibility adapters remain importable for one major cycle and emit ``DeprecationWarning``.",
        "- Prefer canonical Python modules under ``nstat`` for new code.",
        "",
        "Python Usage",
        "------------",
        ".. code-block:: python",
        "",
        "   import nstat",
        "   print(nstat.__all__[:5])",
        "",
        "Data Requirements",
        "-----------------",
        "Use ``nstat.datasets.list_datasets()`` and ``nstat.datasets.get_dataset_path(...)`` to access bundled datasets.",
        "",
        "Expected Outputs",
        "----------------",
        "This topic should execute without MATLAB and produce deterministic summary metrics where applicable.",
        "",
        "Known Differences",
        "-----------------",
        "- Some legacy plotting helpers are represented via notebooks/docs instead of full method parity.",
        "- Numerical outputs may vary if random seeds, bin widths, or sample rates differ from MATLAB defaults.",
        "",
    ]

    if is_example:
        lines.extend(
            [
                "Notebook",
                "--------",
                f"A generated executable notebook is available at ``python/notebooks/helpfiles/{notebook_name}.ipynb``.",
                "",
            ]
        )

    return "\n".join(lines)


def generate_docs() -> list[Path]:
    if not TOC_PATH.exists():
        raise FileNotFoundError(f"Missing TOC file: {TOC_PATH}")

    tree = ET.parse(TOC_PATH)
    toc = tree.getroot()

    TOPICS_DIR.mkdir(parents=True, exist_ok=True)
    created: list[Path] = []
    topic_entries: list[tuple[str, str, Path]] = []
    seen_slugs: set[str] = set()

    for title, target in _iter_topics(toc):
        if target.startswith("http://") or target.startswith("https://"):
            continue
        slug = _slugify(Path(target).stem)
        if slug in seen_slugs:
            continue
        seen_slugs.add(slug)
        out = TOPICS_DIR / f"{slug}.rst"
        out.write_text(_topic_body(title, target), encoding="utf-8")
        created.append(out)
        topic_entries.append((title, target, out))

    topic_index_lines = [
        "Help Topics",
        "===========",
        "",
        ".. toctree::",
        "   :maxdepth: 1",
        "",
    ]
    for _, _, out in topic_entries:
        topic_index_lines.append(f"   topics/{out.stem}")

    (DOCS_ROOT / "help_topics.rst").write_text("\n".join(topic_index_lines) + "\n", encoding="utf-8")

    api_lines = [
        "API Reference",
        "============",
        "",
        ".. code-block:: python",
        "",
        "   import nstat",
        "   print(nstat.__all__)",
        "",
        "Canonical modules include:",
        "",
        "- ``nstat.signal``",
        "- ``nstat.spikes``",
        "- ``nstat.trial``",
        "- ``nstat.analysis``",
        "- ``nstat.fit``",
        "- ``nstat.cif``",
        "- ``nstat.decoding``",
        "- ``nstat.datasets``",
    ]
    (DOCS_ROOT / "api.rst").write_text("\n".join(api_lines) + "\n", encoding="utf-8")

    index_lines = [
        "nSTAT Python Documentation",
        "==========================",
        "",
        "Standalone Python port of nSTAT with MATLAB-help topic coverage and executable notebooks.",
        "",
        ".. toctree::",
        "   :maxdepth: 2",
        "",
        "   api",
        "   help_topics",
    ]
    (DOCS_ROOT / "index.rst").write_text("\n".join(index_lines) + "\n", encoding="utf-8")

    return created


def main() -> int:
    created = generate_docs()
    print(f"generated_topics={len(created)}")
    print(f"docs_root={DOCS_ROOT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
