from __future__ import annotations

from dataclasses import dataclass

import numpy as np


@dataclass
class SpikeTrain:
    spikeTimes: np.ndarray


def simulate_poisson_from_rate(time: np.ndarray, rate_hz: np.ndarray, rng: np.random.Generator | None = None) -> SpikeTrain:
    t = np.asarray(time, dtype=float).reshape(-1)
    r = np.asarray(rate_hz, dtype=float).reshape(-1)
    if t.shape[0] != r.shape[0]:
        raise ValueError("time and rate_hz length mismatch")
    if t.shape[0] < 2:
        return SpikeTrain(np.asarray([], dtype=float))

    if rng is None:
        rng = np.random.default_rng()

    dt = np.diff(t)
    dt = np.concatenate([dt, [dt[-1]]])
    p = 1.0 - np.exp(-np.clip(r, 0.0, np.inf) * dt)
    p = np.clip(p, 0.0, 1.0)
    keep = rng.random(t.shape[0]) < p
    return SpikeTrain(spikeTimes=t[keep])
