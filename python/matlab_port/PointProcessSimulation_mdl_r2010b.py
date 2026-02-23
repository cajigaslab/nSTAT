"""Auto-generated MATLAB-to-Python scaffold.

Source: PointProcessSimulation.mdl.r2010b
"""

from __future__ import annotations

from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat

SOURCE_MODEL = Path(r'/Users/iahncajigas/Library/CloudStorage/Dropbox/Research/Matlab/nSTAT_currentRelease_Local/PointProcessSimulation.mdl.r2010b')

def load_text(path: str | Path | None = None) -> str:
    p = Path(path) if path is not None else SOURCE_MODEL
    return p.read_text(encoding='utf-8', errors='ignore')

def summarize(path: str | Path | None = None) -> dict[str, object]:
    text = load_text(path)
    lines = text.splitlines()
    frame = pd.DataFrame({'line_number': np.arange(1, len(lines) + 1), 'line_text': lines})
    return {
        'source': 'PointProcessSimulation.mdl.r2010b',
        'line_count': int(frame.shape[0]),
        'block_count_guess': int(frame['line_text'].str.contains('Block {', regex=False).sum()),
    }
