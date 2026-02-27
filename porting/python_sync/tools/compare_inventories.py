#!/usr/bin/env python3
"""Compare MATLAB and Python API inventories for nSTAT parity tracking."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from datetime import date
from pathlib import Path


@dataclass
class TranslationEntry:
    matlab: str
    python_module: str | None
    status: str
    notes: str


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def load_translation_map(path: Path) -> list[TranslationEntry]:
    entries: list[TranslationEntry] = []
    if not path.is_file():
        return entries

    current: dict[str, str | None] | None = None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()

        if stripped.startswith("- matlab:"):
            if current is not None:
                entries.append(
                    TranslationEntry(
                        matlab=str(current.get("matlab", "")).strip(),
                        python_module=normalize_none(current.get("python_module")),
                        status=str(current.get("status", "")).strip(),
                        notes=str(current.get("notes", "")).strip(),
                    )
                )
            current = {"matlab": stripped.split(":", 1)[1].strip()}
            continue

        if current is None:
            continue

        key_match = re.match(r"^([a-zA-Z_]+):\s*(.*)$", stripped)
        if key_match:
            key = key_match.group(1)
            value = key_match.group(2).strip()
            current[key] = value

    if current is not None:
        entries.append(
            TranslationEntry(
                matlab=str(current.get("matlab", "")).strip(),
                python_module=normalize_none(current.get("python_module")),
                status=str(current.get("status", "")).strip(),
                notes=str(current.get("notes", "")).strip(),
            )
        )

    return entries


def normalize_none(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = value.strip().strip("\"")
    if cleaned.lower() in {"null", "none", ""}:
        return None
    return cleaned


def module_suffix(module_name: str) -> str:
    suffix = module_name.split(".")[-1]
    return suffix.lower()


def main() -> None:
    repo_root = Path(__file__).resolve().parents[3]
    sync_root = repo_root / "porting" / "python_sync"

    matlab_inventory_path = sync_root / "matlab_api_inventory.json"
    python_inventory_path = sync_root / "python_api_inventory.json"
    translation_path = sync_root / "translation_map.yaml"
    report_path = sync_root / "reports" / "latest_comparison_report.json"

    matlab_inventory = load_json(matlab_inventory_path)
    python_inventory = load_json(python_inventory_path)
    translation_entries = load_translation_map(translation_path)

    matlab_names = [entry["name"] for entry in matlab_inventory.get("public_api", [])]
    translation_index = {entry.matlab: entry for entry in translation_entries}

    canonical_modules = [entry["name"] for entry in python_inventory.get("canonical_modules", [])]
    adapter_modules = [entry["name"] for entry in python_inventory.get("compatibility_adapters", [])]
    python_suffixes = {module_suffix(name) for name in canonical_modules + adapter_modules}

    missing_translation = [name for name in matlab_names if f"{name}.m" not in translation_index]

    missing_python_targets: list[dict[str, str]] = []
    partial_entries: list[dict[str, str]] = []
    not_applicable_entries: list[dict[str, str]] = []

    for entry in translation_entries:
        if entry.status == "partial":
            partial_entries.append({"matlab": entry.matlab, "notes": entry.notes})
        elif entry.status == "not_applicable":
            not_applicable_entries.append({"matlab": entry.matlab, "notes": entry.notes})

        if entry.status == "not_applicable":
            continue
        if entry.python_module is None:
            missing_python_targets.append(
                {
                    "matlab": entry.matlab,
                    "reason": "python_module is null",
                    "status": entry.status,
                }
            )
            continue
        suffix = module_suffix(entry.python_module)
        if suffix not in python_suffixes:
            missing_python_targets.append(
                {
                    "matlab": entry.matlab,
                    "reason": f"python module suffix '{suffix}' not in Python inventories",
                    "status": entry.status,
                }
            )

    report = {
        "generated_on": str(date.today()),
        "inventory_files": {
            "matlab": str(matlab_inventory_path.relative_to(repo_root)),
            "python": str(python_inventory_path.relative_to(repo_root)),
            "translation_map": str(translation_path.relative_to(repo_root)),
        },
        "counts": {
            "matlab_public_api": len(matlab_names),
            "python_canonical_modules": len(canonical_modules),
            "python_adapter_modules": len(adapter_modules),
            "translation_entries": len(translation_entries),
            "missing_translation_entries": len(missing_translation),
            "missing_python_targets": len(missing_python_targets),
            "partial_entries": len(partial_entries),
            "not_applicable_entries": len(not_applicable_entries),
        },
        "missing_translation_entries": missing_translation,
        "missing_python_targets": missing_python_targets,
        "partial_entries": partial_entries,
        "not_applicable_entries": not_applicable_entries,
    }

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote comparison report: {report_path}")


if __name__ == "__main__":
    main()
