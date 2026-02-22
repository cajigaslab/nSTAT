from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

import numpy as np

from .core import Covariate, SignalObj, nspikeTrain


class CovColl:
    def __init__(self, covariates: Sequence[Covariate] | None = None) -> None:
        self.covariates = list(covariates or [])

    def addCovariate(self, covariate: Covariate) -> None:
        self.covariates.append(covariate)

    def get(self, name: str) -> Covariate:
        for cov in self.covariates:
            if cov.name == name:
                return cov
        raise KeyError(f"Covariate '{name}' not found")


class nstColl:
    def __init__(self, trains: Sequence[nspikeTrain] | nspikeTrain) -> None:
        if isinstance(trains, nspikeTrain):
            trains = [trains]
        self._trains = list(trains)
        if len(self._trains) == 0:
            raise ValueError("nstColl requires at least one spike train")

        self.minTime = float(min(s.minTime for s in self._trains))
        self.maxTime = float(max(s.maxTime for s in self._trains))
        rates = [s.sampleRate for s in self._trains if s.sampleRate > 0]
        self.sampleRate = float(np.median(rates)) if rates else 1000.0

    @property
    def numSpikeTrains(self) -> int:
        return len(self._trains)

    def getNST(self, idx: int) -> nspikeTrain:
        if idx < 1 or idx > len(self._trains):
            raise IndexError("nstColl index out of bounds (1-based indexing).")
        return self._trains[idx - 1]

    def setMinTime(self, value: float) -> None:
        self.minTime = float(value)

    def setMaxTime(self, value: float) -> None:
        self.maxTime = float(value)

    def plot(self, *_, **__) -> None:
        return None

    def psth(self, binwidth: float) -> SignalObj:
        edges = np.arange(self.minTime, self.maxTime + 1.5 * binwidth, binwidth)
        counts = np.vstack([spk.to_binned_counts(edges) for spk in self._trains])
        rate = counts.mean(axis=0) / binwidth
        centers = edges[:-1] + 0.5 * binwidth
        return Covariate(centers, rate, "PSTH", "time", "s", "spikes/sec", ["psth"])

    def psthGLM(self, binwidth: float):
        psth_signal = self.psth(binwidth)
        return psth_signal, None, None


@dataclass
class TrialConfig:
    covMask: Sequence[Sequence[str]]
    sampleRate: float
    history: object | None = None
    ensCovHist: object | None = None
    covLag: object | None = None
    name: str = ""

    def setName(self, name: str) -> None:
        self.name = str(name)


class ConfigColl:
    def __init__(self, configs: Sequence[TrialConfig] | None = None) -> None:
        self.configArray: list[TrialConfig] = list(configs or [])
        self.numConfigs = len(self.configArray)

    def addConfig(self, cfg: TrialConfig) -> None:
        self.configArray.append(cfg)
        self.numConfigs = len(self.configArray)

    def getConfig(self, idx: int) -> TrialConfig:
        return self.configArray[idx - 1]

    def getConfigNames(self, index: Sequence[int] | None = None) -> list[str]:
        if index is None:
            index = list(range(1, self.numConfigs + 1))
        out: list[str] = []
        for i in index:
            cfg = self.configArray[i - 1]
            out.append(cfg.name if cfg.name else f"Fit {i}")
        return out


@dataclass
class Trial:
    spikeColl: nstColl
    covarColl: CovColl

    def get_covariate_matrix(self) -> tuple[np.ndarray, np.ndarray, list[str]]:
        if not self.covarColl.covariates:
            raise ValueError("Trial contains no covariates")
        base_time = self.covarColl.covariates[0].time
        x_parts: list[np.ndarray] = []
        labels: list[str] = []
        for cov in self.covarColl.covariates:
            if cov.time.shape != base_time.shape or np.max(np.abs(cov.time - base_time)) > 1e-9:
                raise ValueError("All covariates must share the same time grid")
            x_parts.append(cov.data)
            labels.extend(cov.dataLabels)
        x = np.hstack(x_parts)
        return base_time, x, labels
