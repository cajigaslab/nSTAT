"""Auto-generated MATLAB-to-Python scaffold.

Source: helpfiles/temp.m
"""

from __future__ import annotations

from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat

def run(*, repo_root: str | Path | None = None) -> dict[str, object]:
    root = Path(repo_root).resolve() if repo_root is not None else Path.cwd()
    frame = pd.DataFrame({'line': [1, 2, 3], 'value': [1.0, 2.0, 3.0]})
    return {
        'source': 'helpfiles/temp.m',
        'repo_root': str(root),
        'demo_mean': float(frame['value'].mean()),
    }
