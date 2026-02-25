from __future__ import annotations

import nstat


def test_dataset_manifest_and_checksums() -> None:
    names = nstat.list_datasets()
    assert names

    check = nstat.verify_checksums()
    assert set(check.keys()) == set(names)
    assert all(check.values())


def test_get_dataset_path() -> None:
    name = nstat.list_datasets()[0]
    path = nstat.get_dataset_path(name)
    assert path.exists()
