from __future__ import annotations

from typing import Sequence

import numpy as np

from .core import nspikeTrain as _LegacySpikeTrain
from .simulation import simulate_poisson_from_rate
from .trial import nstColl as _LegacySpikeTrainCollection


class SpikeTrain(_LegacySpikeTrain):
    """Canonical spike train type for point-process analyses."""

    def inter_spike_intervals(self) -> np.ndarray:
        return self.getISIs()

    def to_counts(self, bin_edges: Sequence[float]) -> np.ndarray:
        return self.to_binned_counts(bin_edges)


class SpikeTrainCollection(_LegacySpikeTrainCollection):
    """Collection of aligned spike trains for ensemble analyses."""

    def __iter__(self):
        for i in range(1, self.numSpikeTrains + 1):
            yield self.getNST(i)

    def to_matrix(self, bin_edges: Sequence[float]) -> np.ndarray:
        edges = np.asarray(bin_edges, dtype=float).reshape(-1)
        if edges.ndim != 1 or edges.size < 2:
            raise ValueError("bin_edges must be a 1D array with at least two entries")
        rows = [np.asarray(train.to_binned_counts(edges), dtype=float) for train in self]
        return np.vstack(rows)


__all__ = ["SpikeTrain", "SpikeTrainCollection", "simulate_poisson_from_rate"]
