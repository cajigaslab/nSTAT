from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Sequence

import numpy as np


def _as_1d_float(values: Sequence[float] | np.ndarray, name: str) -> np.ndarray:
    array = np.asarray(values, dtype=float).reshape(-1)
    if array.size == 0:
        raise ValueError(f"{name} must be non-empty.")
    return array


class SignalObj:
    """Python approximation of nSTAT SignalObj.

    The class stores a time vector and one or more aligned signal channels.
    """

    def __init__(
        self,
        time: Sequence[float],
        data: Sequence[float] | Sequence[Sequence[float]] | np.ndarray,
        name: str = "signal",
        xlabel: str = "time",
        xunits: str = "s",
        yunits: str = "",
        data_labels: Sequence[str] | None = None,
    ) -> None:
        t = _as_1d_float(time, "time")
        if np.any(np.diff(t) <= 0):
            raise ValueError("time must be strictly increasing.")

        x = np.asarray(data, dtype=float)
        if x.ndim == 1:
            x = x[:, None]
        if x.shape[0] != t.shape[0]:
            raise ValueError("data must have same first dimension as time.")

        self.time = t
        self.data = x
        self.name = name
        self.xlabelval = xlabel
        self.xunits = xunits
        self.yunits = yunits

        if data_labels is None:
            labels = [f"{name}_{k+1}" for k in range(self.data.shape[1])]
        else:
            labels = list(data_labels)
            if len(labels) != self.data.shape[1]:
                raise ValueError("data_labels length must match signal dimension.")
        self.dataLabels = labels
        self.conf_interval: tuple[np.ndarray, np.ndarray] | None = None

    @property
    def dimension(self) -> int:
        return int(self.data.shape[1])

    @property
    def values(self) -> np.ndarray:
        if self.dimension == 1:
            return self.data[:, 0]
        return self.data

    @property
    def units(self) -> str:
        return self.yunits

    @property
    def sample_rate(self) -> float:
        if self.time.shape[0] < 2:
            return 0.0
        dt = np.median(np.diff(self.time))
        if dt <= 0:
            return 0.0
        return float(1.0 / dt)

    def copySignal(self) -> "SignalObj":
        out = SignalObj(
            self.time.copy(),
            self.data.copy(),
            self.name,
            self.xlabelval,
            self.xunits,
            self.yunits,
            self.dataLabels,
        )
        out.conf_interval = None if self.conf_interval is None else (
            self.conf_interval[0].copy(),
            self.conf_interval[1].copy(),
        )
        return out

    def setName(self, name: str) -> None:
        self.name = str(name)

    def setDataLabels(self, labels: Sequence[str]) -> None:
        labels = list(labels)
        if len(labels) != self.dimension:
            raise ValueError("labels length must equal number of signal channels.")
        self.dataLabels = labels

    def setConfInterval(self, bounds: tuple[np.ndarray, np.ndarray]) -> None:
        low, high = bounds
        low = np.asarray(low, dtype=float)
        high = np.asarray(high, dtype=float)
        if low.shape[0] != self.time.shape[0] or high.shape[0] != self.time.shape[0]:
            raise ValueError("confidence interval bounds must align with time.")
        self.conf_interval = (low, high)

    def getSubSignal(self, idx: int) -> "SignalObj":
        if idx < 1 or idx > self.dimension:
            raise IndexError("Signal index out of range. Indexing is 1-based.")
        j = idx - 1
        return SignalObj(
            self.time,
            self.data[:, j],
            self.name,
            self.xlabelval,
            self.xunits,
            self.yunits,
            [self.dataLabels[j]],
        )

    def getSigInTimeWindow(self, t0: float, t1: float) -> "SignalObj":
        mask = (self.time >= t0) & (self.time <= t1)
        if not np.any(mask):
            raise ValueError("Requested time window has no samples.")
        return SignalObj(
            self.time[mask],
            self.data[mask, :],
            self.name,
            self.xlabelval,
            self.xunits,
            self.yunits,
            self.dataLabels,
        )

    def merge(self, other: "SignalObj") -> "SignalObj":
        if self.time.shape != other.time.shape or np.max(np.abs(self.time - other.time)) > 1e-9:
            raise ValueError("Signals must share an identical time grid to merge.")
        return SignalObj(
            self.time,
            np.column_stack([self.data, other.data]),
            self.name,
            self.xlabelval,
            self.xunits,
            self.yunits,
            [*self.dataLabels, *other.dataLabels],
        )

    def resample(self, sample_rate: float) -> "SignalObj":
        if sample_rate <= 0:
            raise ValueError("sample_rate must be > 0.")
        dt = 1.0 / float(sample_rate)
        t_new = np.arange(self.time[0], self.time[-1] + 0.5 * dt, dt)
        x_new = np.column_stack(
            [np.interp(t_new, self.time, self.data[:, i]) for i in range(self.dimension)]
        )
        return SignalObj(
            t_new,
            x_new,
            self.name,
            self.xlabelval,
            self.xunits,
            self.yunits,
            self.dataLabels,
        )

    @property
    def derivative(self) -> "SignalObj":
        dt = np.gradient(self.time)
        deriv = np.column_stack([np.gradient(self.data[:, i], self.time) for i in range(self.dimension)])
        # Avoid numerical noise spikes where dt is near 0.
        deriv[~np.isfinite(deriv)] = 0.0
        return SignalObj(
            self.time,
            deriv,
            f"d/dt({self.name})",
            self.xlabelval,
            self.xunits,
            self.yunits,
            [f"d_{lbl}" for lbl in self.dataLabels],
        )

    def plot(self, *_, **__) -> None:
        # Intentionally lightweight: plotting is handled in examples where needed.
        return None


class Covariate(SignalObj):
    """MATLAB-compatible alias for SignalObj.

    Accepts both MATLAB-style positional arguments and Pythonic keywords:
    `Covariate(time=t, values=x, name='stim', units='a.u.')`.
    """

    def __init__(self, *args, **kwargs) -> None:
        if "values" in kwargs and "data" not in kwargs:
            kwargs["data"] = kwargs.pop("values")
        if "units" in kwargs and "yunits" not in kwargs:
            kwargs["yunits"] = kwargs.pop("units")
        super().__init__(*args, **kwargs)


@dataclass
class nspikeTrain:
    """Python approximation of MATLAB nspikeTrain."""

    spikeTimes: np.ndarray
    name: str = ""
    binwidth: float = 0.001
    minTime: float | None = None
    maxTime: float | None = None

    def __post_init__(self) -> None:
        spikes = np.asarray(self.spikeTimes, dtype=float).reshape(-1)
        spikes = np.sort(spikes)
        self.spikeTimes = spikes

        if self.minTime is None:
            self.minTime = float(spikes[0]) if spikes.size else 0.0
        if self.maxTime is None:
            self.maxTime = float(spikes[-1]) if spikes.size else self.minTime

        self.minTime = float(self.minTime)
        self.maxTime = float(self.maxTime)
        self.sampleRate = float(1.0 / self.binwidth)

    @property
    def times(self) -> np.ndarray:
        return self.spikeTimes

    @property
    def n_spikes(self) -> int:
        return int(self.spikeTimes.shape[0])

    @property
    def duration(self) -> float:
        return float(self.maxTime - self.minTime)

    @property
    def firing_rate_hz(self) -> float:
        d = self.duration
        if d <= 0:
            return 0.0
        return float(self.n_spikes / d)

    def setName(self, name: str) -> None:
        self.name = str(name)

    def setMinTime(self, value: float) -> None:
        self.minTime = float(value)

    def setMaxTime(self, value: float) -> None:
        self.maxTime = float(value)

    def getISIs(self) -> np.ndarray:
        if self.n_spikes < 2:
            return np.array([], dtype=float)
        return np.diff(self.spikeTimes)

    def getSigRep(
        self,
        binwidth: float | None = None,
        minTime: float | None = None,
        maxTime: float | None = None,
    ) -> SignalObj:
        bw = self.binwidth if binwidth is None else float(binwidth)
        t0 = self.minTime if minTime is None else float(minTime)
        t1 = self.maxTime if maxTime is None else float(maxTime)
        if bw <= 0:
            raise ValueError("binwidth must be > 0")
        if t1 < t0:
            raise ValueError("maxTime must be >= minTime")

        edges = np.arange(t0, t1 + 1.5 * bw, bw)
        if edges.shape[0] < 2:
            edges = np.array([t0, t0 + bw], dtype=float)
        counts, _ = np.histogram(self.spikeTimes, bins=edges)
        centers = edges[:-1] + 0.5 * bw
        return SignalObj(centers, counts.astype(float), self.name or "spikes", "time", "s", "count", ["counts"])

    def to_binned_counts(self, bin_edges: Sequence[float]) -> np.ndarray:
        edges = np.asarray(bin_edges, dtype=float).reshape(-1)
        counts, _ = np.histogram(self.spikeTimes, bins=edges)
        return counts.astype(float)


# Backward-compatible alias used by earlier Python scaffolding.
SpikeTrain = nspikeTrain
