from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .signal import Covariate


@dataclass
class HistoryBasis:
    """Spike-history basis using lagged spike-count regressors."""

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

    def compute_history(self, spike_indicator: np.ndarray, time: np.ndarray) -> Covariate:
        x = self.design_matrix(spike_indicator)
        labels = [f"hist_lag_{int(l)}" for l in self.lags]
        return Covariate(time, x, self.name, "time", "s", "count", labels)

    # MATLAB-compatible method names.
    def computeHistory(self, nst) -> Covariate:
        y = np.asarray(getattr(nst, "getSigRep")().data[:, 0], dtype=float)
        t = np.asarray(getattr(nst, "getSigRep")().time, dtype=float)
        return self.compute_history(y, t)


# Backward-compatible alias.
History = HistoryBasis


__all__ = ["HistoryBasis", "History"]
