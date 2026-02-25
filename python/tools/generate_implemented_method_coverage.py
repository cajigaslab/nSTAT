from __future__ import annotations

import ast
import json
import subprocess
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
MATRIX_PATH = REPO_ROOT / "python" / "reports" / "method_parity_matrix.json"
SMOKE_TEST_PATH = REPO_ROOT / "python" / "tests" / "test_implemented_method_smoke.py"
DOCS_TOPICS_DIR = REPO_ROOT / "python" / "docs" / "topics"
OUT_PATH = REPO_ROOT / "python" / "reports" / "implemented_method_coverage.json"

DOC_CLASS_TOKENS = {
    "SignalObj": ["signalobj", "classdefinitions"],
    "Covariate": ["covariate", "classdefinitions"],
    "nspikeTrain": ["nspiketrain", "classdefinitions"],
    "nstColl": ["nstcoll", "classdefinitions"],
    "CovColl": ["covcoll", "classdefinitions"],
    "TrialConfig": ["trialconfig", "classdefinitions"],
    "ConfigColl": ["configcoll", "classdefinitions"],
    "Trial": ["trial", "classdefinitions"],
    "History": ["history", "classdefinitions"],
    "Events": ["events", "classdefinitions"],
    "ConfidenceInterval": ["classdefinitions"],
    "CIF": ["cif", "ppthinning", "classdefinitions"],
    "FitResult": ["fitresult", "classdefinitions"],
    "FitResSummary": ["fitressummary", "classdefinitions"],
    "Analysis": ["analysis", "classdefinitions"],
    "DecodingAlgorithms": ["decoding", "classdefinitions"],
}


def _implemented_methods(matrix: dict[str, Any]) -> set[tuple[str, str]]:
    out: set[tuple[str, str]] = set()
    for cls in matrix.get("classes", []):
        matlab_class = str(cls.get("matlab_class", ""))
        for method in cls.get("methods", []):
            if method.get("status") == "implemented":
                out.add((matlab_class, str(method.get("matlab_method", ""))))
    return out


def _load_smoke_set() -> set[tuple[str, str]]:
    src = SMOKE_TEST_PATH.read_text(encoding="utf-8")
    tree = ast.parse(src)
    for node in tree.body:
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id == "COVERED_IMPLEMENTED_METHODS":
                    value = ast.literal_eval(node.value)
                    return {(str(a), str(b)) for (a, b) in value}
    raise RuntimeError("Could not find COVERED_IMPLEMENTED_METHODS in smoke test file")


def _doc_class_coverage(classes: set[str]) -> dict[str, bool]:
    topic_names = [p.stem.lower() for p in DOCS_TOPICS_DIR.glob("*.rst")]
    out: dict[str, bool] = {}
    for c in sorted(classes):
        tokens = DOC_CLASS_TOKENS.get(c, [c.lower()])
        out[c] = any(any(tok in stem for tok in tokens) for stem in topic_names)
    return out


def main() -> int:
    if not MATRIX_PATH.exists():
        subprocess.run(["python3", "python/tools/generate_method_parity_matrix.py"], cwd=str(REPO_ROOT), check=True)

    matrix = json.loads(MATRIX_PATH.read_text(encoding="utf-8"))
    implemented = _implemented_methods(matrix)
    smoke = _load_smoke_set()

    missing_in_smoke = sorted(implemented - smoke)
    extra_in_smoke = sorted(smoke - implemented)

    classes = {c for c, _ in implemented}
    doc_cov = _doc_class_coverage(classes)
    missing_doc_classes = sorted([c for c, ok in doc_cov.items() if not ok])

    report = {
        "summary": {
            "implemented_method_count": len(implemented),
            "smoke_covered_count": len(smoke),
            "missing_in_smoke_count": len(missing_in_smoke),
            "extra_in_smoke_count": len(extra_in_smoke),
            "implemented_class_count": len(classes),
            "docs_class_covered_count": sum(1 for v in doc_cov.values() if v),
            "missing_doc_class_count": len(missing_doc_classes),
        },
        "missing_in_smoke": [[c, m] for (c, m) in missing_in_smoke],
        "extra_in_smoke": [[c, m] for (c, m) in extra_in_smoke],
        "doc_class_coverage": doc_cov,
        "missing_doc_classes": missing_doc_classes,
        "pass": (len(missing_in_smoke) == 0 and len(extra_in_smoke) == 0 and len(missing_doc_classes) == 0),
    }

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"report": str(OUT_PATH.relative_to(REPO_ROOT)), "summary": report["summary"], "pass": report["pass"]}, indent=2))
    return 0 if report["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
