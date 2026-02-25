from __future__ import annotations

from typing import Sequence

import numpy as np

from .core import Covariate as _LegacyCovariate
from .core import SignalObj as _LegacySignalObj


class Signal(_LegacySignalObj):
    """Canonical Pythonic signal abstraction for nSTAT."""

    def copy(self) -> "Signal":
        copied = self.copySignal()
        return Signal(
            copied.time,
            copied.data,
            copied.name,
            copied.xlabelval,
            copied.xunits,
            copied.yunits,
            copied.dataLabels,
        )

    def sub_signal(self, index: int) -> "Signal":
        """Return one channel as a new signal.

        Uses zero-based indexing in Python, unlike MATLAB's one-based indexing.
        """
        if index < 0 or index >= self.dimension:
            raise IndexError("Signal channel index out of range.")
        out = self.getSubSignal(index + 1)
        return Signal(
            out.time,
            out.data,
            out.name,
            out.xlabelval,
            out.xunits,
            out.yunits,
            out.dataLabels,
        )

    def window(self, start: float, stop: float) -> "Signal":
        out = self.getSigInTimeWindow(start, stop)
        return Signal(
            out.time,
            out.data,
            out.name,
            out.xlabelval,
            out.xunits,
            out.yunits,
            out.dataLabels,
        )

    def as_array(self) -> np.ndarray:
        return np.asarray(self.data, dtype=float)


class Covariate(_LegacyCovariate):
    """Canonical covariate type for model design matrices."""

    def standardize(self) -> "Covariate":
        data = np.asarray(self.data, dtype=float)
        mu = np.mean(data, axis=0, keepdims=True)
        sigma = np.std(data, axis=0, keepdims=True)
        sigma[sigma == 0.0] = 1.0
        z = (data - mu) / sigma
        return Covariate(
            self.time,
            z,
            self.name,
            self.xlabelval,
            self.xunits,
            self.yunits,
            self.dataLabels,
        )

    @classmethod
    def from_values(
        cls,
        time: Sequence[float],
        values: Sequence[float] | Sequence[Sequence[float]] | np.ndarray,
        *,
        name: str = "covariate",
        units: str = "",
    ) -> "Covariate":
        return cls(time=time, values=values, name=name, units=units)
