from __future__ import annotations

import hashlib
import json
from pathlib import Path

from .errors import DataNotFoundError

MANIFEST_PATH = Path(__file__).resolve().parent / "data" / "manifest.json"


def _repo_root() -> Path:
    cur = Path(__file__).resolve()
    for candidate in [cur, *cur.parents]:
        if (candidate / "data").exists() and (candidate / "helpfiles").exists():
            return candidate
    raise RuntimeError("Could not locate nSTAT repository root from installed package path.")


def _load_manifest() -> dict[str, dict[str, str]]:
    if not MANIFEST_PATH.exists():
        raise DataNotFoundError(f"Dataset manifest not found: {MANIFEST_PATH}")
    payload = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    entries = payload.get("datasets", {})
    if not isinstance(entries, dict):
        raise ValueError("Invalid dataset manifest format; 'datasets' must be a mapping")
    return entries


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def list_datasets() -> list[str]:
    return sorted(_load_manifest().keys())


def get_dataset_path(name: str) -> Path:
    entries = _load_manifest()
    if name not in entries:
        raise DataNotFoundError(f"Unknown dataset '{name}'. Available: {', '.join(sorted(entries))}")

    rel = entries[name]["path"]
    path = _repo_root() / rel
    if not path.exists():
        raise DataNotFoundError(f"Dataset '{name}' not found at expected path: {path}")
    return path


def verify_checksums() -> dict[str, bool]:
    entries = _load_manifest()
    root = _repo_root()
    result: dict[str, bool] = {}
    for name, item in entries.items():
        path = root / item["path"]
        expected = item.get("sha256", "")
        if not path.exists() or not expected:
            result[name] = False
            continue
        result[name] = _sha256(path) == expected
    return result
