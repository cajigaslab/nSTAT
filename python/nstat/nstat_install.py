from __future__ import annotations

from pathlib import Path


def nSTAT_Install() -> Path:
    """Return Python package root path (MATLAB nSTAT_Install analogue)."""
    return Path(__file__).resolve().parents[1]
