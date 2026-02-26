from __future__ import annotations

import os

import nstat


def test_dataset_manifest_and_checksums() -> None:
    names = nstat.list_datasets()
    assert names

    check = nstat.verify_checksums()
    assert set(check.keys()) == set(names)
    assert all(isinstance(v, bool) for v in check.values())
    allow_synthetic = os.environ.get("NSTAT_ALLOW_SYNTHETIC_DATA", "").strip().lower() in {"1", "true", "yes", "on"}
    if not allow_synthetic:
        assert all(check.values())


def test_get_dataset_path() -> None:
    name = nstat.list_datasets()[0]
    path = nstat.get_dataset_path(name)
    assert path.exists()
