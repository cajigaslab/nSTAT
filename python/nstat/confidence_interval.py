from __future__ import annotations

from dataclasses import dataclass

import numpy as np


@dataclass
class ConfidenceInterval:
    time: np.ndarray
    bounds: np.ndarray
    color: str = "b"

    def __init__(self, time, bounds, color: str = "b") -> None:
        t = np.asarray(time, dtype=float).reshape(-1)
        b = np.asarray(bounds, dtype=float)
        if b.ndim != 2 or b.shape[1] != 2:
            raise ValueError("bounds must have shape (n, 2)")
        if b.shape[0] != t.shape[0]:
            raise ValueError("bounds rows must match time length")
        self.time = t
        self.bounds = b
        self.color = color

    @property
    def lower(self) -> np.ndarray:
        return self.bounds[:, 0]

    @property
    def upper(self) -> np.ndarray:
        return self.bounds[:, 1]

    def setColor(self, color: str) -> None:
        self.color = str(color)
