from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Sequence

import numpy as np

from .core import nspikeTrain
from .events import Events
from .signal import Covariate


class CovariateCollection:
    def __init__(self, covariates: Sequence[Covariate] | None = None) -> None:
        self.covariates = list(covariates or [])

    @property
    def names(self) -> list[str]:
        return [cov.name for cov in self.covariates]

    def add(self, covariate: Covariate) -> None:
        self.covariates.append(covariate)

    def addCovariate(self, covariate: Covariate) -> None:
        self.add(covariate)

    def addToColl(self, covariate: Covariate) -> None:
        self.add(covariate)

    def get(self, name: str) -> Covariate:
        for cov in self.covariates:
            if cov.name == name:
                return cov
        raise KeyError(f"Covariate '{name}' not found")

    def getCov(self, name: str) -> Covariate:
        return self.get(name)

    def dataToMatrix(self, names: Sequence[str] | None = None) -> tuple[np.ndarray, np.ndarray, list[str]]:
        if not self.covariates:
            raise ValueError("CovariateCollection is empty")
        selected = self.covariates
        if names is not None:
            keep = set(names)
            selected = [cov for cov in self.covariates if cov.name in keep]
            if not selected:
                raise ValueError("No covariates matched requested names")

        base_time = selected[0].time
        x_parts: list[np.ndarray] = []
        labels: list[str] = []
        for cov in selected:
            if cov.time.shape != base_time.shape or np.max(np.abs(cov.time - base_time)) > 1e-9:
                raise ValueError("All covariates must share the same time grid")
            x_parts.append(np.asarray(cov.data, dtype=float))
            labels.extend(cov.dataLabels)
        return base_time, np.hstack(x_parts), labels


class SpikeTrainCollection:
    def __init__(self, trains: Sequence[nspikeTrain] | nspikeTrain) -> None:
        if isinstance(trains, nspikeTrain):
            trains = [trains]
        self._trains = list(trains)
        if len(self._trains) == 0:
            raise ValueError("SpikeTrainCollection requires at least one spike train")

        self.minTime = float(min(s.minTime for s in self._trains))
        self.maxTime = float(max(s.maxTime for s in self._trains))
        rates = [s.sampleRate for s in self._trains if s.sampleRate > 0]
        self.sampleRate = float(np.median(rates)) if rates else 1000.0

    @property
    def num_spike_trains(self) -> int:
        return len(self._trains)

    @property
    def numSpikeTrains(self) -> int:
        return self.num_spike_trains

    def __iter__(self):
        for tr in self._trains:
            yield tr

    def get_nst(self, idx: int) -> nspikeTrain:
        if idx < 0 or idx >= len(self._trains):
            raise IndexError("SpikeTrainCollection index out of bounds (0-based indexing).")
        return self._trains[idx]

    def getNST(self, idx: int) -> nspikeTrain:
        if idx < 1 or idx > len(self._trains):
            raise IndexError("nstColl index out of bounds (1-based indexing).")
        return self._trains[idx - 1]

    def setMinTime(self, value: float) -> None:
        self.minTime = float(value)

    def setMaxTime(self, value: float) -> None:
        self.maxTime = float(value)

    def dataToMatrix(self, bin_edges: Sequence[float]) -> np.ndarray:
        edges = np.asarray(bin_edges, dtype=float).reshape(-1)
        if edges.ndim != 1 or edges.size < 2:
            raise ValueError("bin_edges must be a 1D array with at least two points")
        rows = [np.asarray(spk.to_binned_counts(edges), dtype=float) for spk in self._trains]
        return np.vstack(rows)

    def plot(self, *_, **__) -> None:
        return None

    def psth(self, binwidth: float) -> Covariate:
        if binwidth <= 0:
            raise ValueError("binwidth must be > 0")
        min_time = float(self.minTime)
        max_time = float(self.maxTime)
        if max_time < min_time:
            raise ValueError("maxTime must be >= minTime")

        # Match MATLAB nstColl.psth edge construction:
        #   windowTimes = minTime:binwidth:maxTime;
        #   if ~any(windowTimes==maxTime), append maxTime
        span = max_time - min_time
        n_full = int(np.floor((span / binwidth) + 1e-12))
        window_times = min_time + np.arange(n_full + 1, dtype=float) * float(binwidth)
        if window_times.size == 0:
            window_times = np.array([min_time, max_time], dtype=float)
        if window_times[-1] < max_time - 1e-12:
            window_times = np.append(window_times, max_time)
        elif window_times[-1] > max_time + 1e-12:
            window_times[-1] = max_time
        if window_times.size < 2:
            window_times = np.array([min_time, max_time], dtype=float)
            if window_times[1] <= window_times[0]:
                window_times[1] = window_times[0] + float(binwidth)

        # MATLAB histc-like counting produces one extra terminal bin for x==max;
        # nstColl.psth discards that final bin before normalizing.
        psth_hist = np.zeros(window_times.size, dtype=float)
        for spk in self._trains:
            spikes = np.asarray(spk.spikeTimes, dtype=float).reshape(-1)
            if spikes.size == 0:
                continue
            valid = np.isfinite(spikes) & (spikes >= window_times[0]) & (spikes <= window_times[-1])
            if not np.any(valid):
                continue
            idx = np.searchsorted(window_times, spikes[valid], side="right") - 1
            idx = np.clip(idx, 0, window_times.size - 1)
            psth_hist += np.bincount(idx, minlength=window_times.size).astype(float)

        rate = psth_hist[:-1] / binwidth / float(len(self._trains))
        centers = (window_times[1:] + window_times[:-1]) * 0.5
        return Covariate(centers, rate, "PSTH", "time", "s", "spikes/sec", ["psth"])

    def psthGLM(self, binwidth: float):
        psth_signal = self.psth(binwidth)
        return psth_signal, None, None


@dataclass
class TrialConfig:
    covMask: Sequence[Sequence[str]] | Sequence[str]
    sampleRate: float
    history: object | None = None
    ensCovHist: object | None = None
    covLag: object | None = None
    name: str = ""

    def setName(self, name: str) -> None:
        self.name = str(name)

    @property
    def covariate_names(self) -> list[str]:
        if not self.covMask:
            return []
        names: list[str] = []
        for item in self.covMask:
            if isinstance(item, str):
                names.append(item)
            else:
                names.extend([str(v) for v in item])
        return names


class ConfigCollection:
    def __init__(self, configs: Sequence[TrialConfig] | None = None) -> None:
        self.configs: list[TrialConfig] = list(configs or [])

    @property
    def numConfigs(self) -> int:
        return len(self.configs)

    @property
    def configArray(self) -> list[TrialConfig]:
        return self.configs

    def add_config(self, cfg: TrialConfig) -> None:
        self.configs.append(cfg)

    def addConfig(self, cfg: TrialConfig) -> None:
        self.add_config(cfg)

    def get_config(self, idx: int) -> TrialConfig:
        if idx < 0 or idx >= len(self.configs):
            raise IndexError("ConfigCollection index out of bounds (0-based indexing).")
        return self.configs[idx]

    def getConfig(self, idx: int) -> TrialConfig:
        return self.configs[idx - 1]

    def getConfigNames(self, index: Sequence[int] | None = None) -> list[str]:
        if index is None:
            index = list(range(1, self.numConfigs + 1))
        out: list[str] = []
        for i in index:
            cfg = self.configs[i - 1]
            out.append(cfg.name if cfg.name else f"Fit {i}")
        return out


class Trial:
    def __init__(
        self,
        spike_collection: SpikeTrainCollection | None = None,
        covariate_collection: CovariateCollection | None = None,
        events: Events | None = None,
        *,
        spikeColl: SpikeTrainCollection | None = None,
        covarColl: CovariateCollection | None = None,
    ) -> None:
        self.spike_collection = spike_collection if spike_collection is not None else spikeColl
        self.covariate_collection = covariate_collection if covariate_collection is not None else covarColl
        if self.spike_collection is None or self.covariate_collection is None:
            raise ValueError("Trial requires both spike_collection and covariate_collection")
        self.events = events

    @property
    def spikeColl(self) -> SpikeTrainCollection:
        return self.spike_collection

    @property
    def covarColl(self) -> CovariateCollection:
        return self.covariate_collection

    def get_covariate_matrix(self, selected_covariates: Sequence[str] | None = None) -> tuple[np.ndarray, np.ndarray, list[str]]:
        return self.covariate_collection.dataToMatrix(selected_covariates)

    def getSpikeVector(self, bin_edges: Sequence[float], neuron_index: int = 1) -> np.ndarray:
        return self.spike_collection.getNST(neuron_index).to_binned_counts(bin_edges)


# Backward-compatible MATLAB-style aliases.
CovColl = CovariateCollection
nstColl = SpikeTrainCollection
ConfigColl = ConfigCollection


__all__ = [
    "CovariateCollection",
    "SpikeTrainCollection",
    "TrialConfig",
    "ConfigCollection",
    "Trial",
    "CovColl",
    "nstColl",
    "ConfigColl",
]
