"""Auto-generated MATLAB-to-Python scaffold.

Source: libraries/zernike/zernfun.m
"""

from __future__ import annotations

from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat

def zernfun(*, n=None, m=None, r=None, theta=None, nflag=None) -> dict[str, object]:
    frame = pd.DataFrame({'row': np.arange(3, dtype=int)})
    return {
        'source': 'libraries/zernike/zernfun.m',
        'function': 'zernfun',
        'rows': int(frame.shape[0]),
    }

def run(**kwargs) -> dict[str, object]:
    return zernfun(**kwargs)
