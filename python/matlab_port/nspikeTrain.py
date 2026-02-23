"""Auto-generated MATLAB-to-Python scaffold.

Source: nspikeTrain.m
"""

from __future__ import annotations

from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat

class nspikeTrain:
    """Scaffold translated from MATLAB classdef."""

    def __init__(self, *args, **kwargs) -> None:
        self.args = args
        self.kwargs = kwargs

    def metadata(self) -> dict[str, object]:
        return {
            'source': 'nspikeTrain.m',
            'args_count': len(self.args),
            'kwargs': sorted(list(self.kwargs.keys())),
        }
