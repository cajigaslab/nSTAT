from __future__ import annotations

import ast
import json
import re
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
REPORT_DIR = REPO_ROOT / "python" / "reports"

CLASS_MAPPING = {
    "SignalObj": ("SignalObj.m", "python/nstat/signal.py", "Signal"),
    "Covariate": ("Covariate.m", "python/nstat/signal.py", "Covariate"),
    "nspikeTrain": ("nspikeTrain.m", "python/nstat/spikes.py", "SpikeTrain"),
    "nstColl": ("nstColl.m", "python/nstat/spikes.py", "SpikeTrainCollection"),
    "CovColl": ("CovColl.m", "python/nstat/trial.py", "CovariateCollection"),
    "TrialConfig": ("TrialConfig.m", "python/nstat/trial.py", "TrialConfig"),
    "ConfigColl": ("ConfigColl.m", "python/nstat/trial.py", "ConfigCollection"),
    "Trial": ("Trial.m", "python/nstat/trial.py", "Trial"),
    "History": ("History.m", "python/nstat/history.py", "HistoryBasis"),
    "Events": ("Events.m", "python/nstat/events.py", "Events"),
    "ConfidenceInterval": ("ConfidenceInterval.m", "python/nstat/confidence_interval.py", "ConfidenceInterval"),
    "CIF": ("CIF.m", "python/nstat/cif.py", "CIFModel"),
    "FitResult": ("FitResult.m", "python/nstat/fit.py", "FitResult"),
    "FitResSummary": ("FitResSummary.m", "python/nstat/fit.py", "FitSummary"),
    "Analysis": ("Analysis.m", "python/nstat/analysis.py", "Analysis"),
    "DecodingAlgorithms": ("DecodingAlgorithms.m", "python/nstat/decoding_algorithms.py", "DecodingAlgorithms"),
}

IMPLEMENTED_ALIAS_MAP = {
    "runanalysisforallneurons": "run_analysis_for_all_neurons",
    "runanalysisforneuron": "run_analysis_for_neuron",
    "simulatecifbythinningfromlambda": "simulate",
    "ppdecodefilter": "kalman_filter",
    "ppdecodefilterlinear": "kalman_filter",
    "getconfig": "get_config",
    "addconfig": "add_config",
    "getnst": "get_nst",
    "getcov": "get",
    "datatomatrix": "to_matrix",
}


def _normalize(name: str) -> str:
    return re.sub(r"[^a-z0-9]", "", name.lower())


def _matlab_methods(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    methods: list[str] = []
    for m in re.finditer(r"^\s*function\s+(?:\[[^\]]*\]\s*=\s*|\w+\s*=\s*)?(\w+)\s*(?:\(|$)", text, flags=re.M):
        methods.append(m.group(1))
    return sorted(set(methods))


def _python_methods(path: Path, class_name: str) -> list[str]:
    src = path.read_text(encoding="utf-8", errors="ignore")
    tree = ast.parse(src)
    for node in tree.body:
        if isinstance(node, ast.ClassDef) and node.name == class_name:
            return sorted({n.name for n in node.body if isinstance(n, ast.FunctionDef)})
    return []


def _status_for_method(m_method: str, py_methods_norm: set[str]) -> tuple[str, str]:
    m_norm = _normalize(m_method)
    mapped = IMPLEMENTED_ALIAS_MAP.get(m_norm)

    if m_norm in py_methods_norm:
        return "implemented", "Method name exists in canonical Python class."
    if mapped is not None and _normalize(mapped) in py_methods_norm:
        return "implemented", f"Implemented via Pythonic rename: {mapped}."

    if m_norm.startswith("plot") or "histogram" in m_norm or m_norm in {"dsxy2figxy"}:
        return "intentionally_omitted", "Visualization helper is handled in notebooks/docs instead of core API."

    return "planned", "Not yet implemented in canonical class; tracked for incremental parity completion."


def build_matrix() -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    implemented_methods: list[dict[str, str]] = []
    summary = {"implemented": 0, "planned": 0, "intentionally_omitted": 0, "total": 0}

    for matlab_class, (m_rel, py_rel, py_class) in CLASS_MAPPING.items():
        m_path = REPO_ROOT / m_rel
        py_path = REPO_ROOT / py_rel

        m_methods = _matlab_methods(m_path) if m_path.exists() else []
        py_methods = _python_methods(py_path, py_class) if py_path.exists() else []
        py_norm = {_normalize(x) for x in py_methods}

        method_rows = []
        for method in m_methods:
            status, rationale = _status_for_method(method, py_norm)
            method_rows.append(
                {
                    "matlab_method": method,
                    "status": status,
                    "rationale": rationale,
                }
            )
            if status == "implemented":
                implemented_methods.append({"matlab_class": matlab_class, "matlab_method": method})
            summary[status] += 1
            summary["total"] += 1

        rows.append(
            {
                "matlab_class": matlab_class,
                "matlab_source": m_rel,
                "python_target": py_rel,
                "python_class": py_class,
                "python_methods": py_methods,
                "methods": method_rows,
            }
        )

    implemented_methods = sorted(implemented_methods, key=lambda r: (r["matlab_class"], r["matlab_method"]))
    return {"summary": summary, "implemented_methods": implemented_methods, "classes": rows}


def main() -> int:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORT_DIR / "method_parity_matrix.json"
    matrix = build_matrix()
    out.write_text(json.dumps(matrix, indent=2), encoding="utf-8")
    print(json.dumps({"report": str(out.relative_to(REPO_ROOT)), "summary": matrix["summary"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
