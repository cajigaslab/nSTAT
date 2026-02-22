from __future__ import annotations

from dataclasses import dataclass

import numpy as np


@dataclass
class History:
    """Simple spike-history basis description."""

    lags: np.ndarray
    name: str = "History"

    def __init__(self, lags, name: str = "History") -> None:
        arr = np.asarray(lags, dtype=int).reshape(-1)
        if arr.size == 0:
            raise ValueError("lags must be non-empty")
        if np.any(arr <= 0):
            raise ValueError("lags must be strictly positive")
        self.lags = np.unique(arr)
        self.name = name

    def design_matrix(self, spike_indicator: np.ndarray) -> np.ndarray:
        y = np.asarray(spike_indicator, dtype=float).reshape(-1)
        x = np.zeros((y.shape[0], self.lags.shape[0]), dtype=float)
        for j, lag in enumerate(self.lags):
            x[lag:, j] = y[:-lag]
        return x
