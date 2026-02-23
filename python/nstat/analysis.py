from __future__ import annotations

from typing import Sequence

import numpy as np


def psth(spike_trains: Sequence[object], bin_edges: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    edges = np.asarray(bin_edges, dtype=float)
    if edges.ndim != 1 or edges.size < 2:
        raise ValueError("bin_edges must be 1D and length >= 2")

    counts = np.zeros(edges.size - 1, dtype=float)
    if len(spike_trains) == 0:
        return counts.copy(), counts

    for tr in spike_trains:
        spikes = np.asarray(getattr(tr, "spikeTimes"), dtype=float).reshape(-1)
        c, _ = np.histogram(spikes, bins=edges)
        counts += c

    widths = np.diff(edges)
    mean_rate_hz = counts / (len(spike_trains) * widths)
    return mean_rate_hz, counts
