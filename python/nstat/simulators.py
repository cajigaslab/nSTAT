from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .spikes import SpikeTrain, SpikeTrainCollection


@dataclass
class PointProcessSimulation:
    time: np.ndarray
    rate_hz: np.ndarray
    spikes: SpikeTrain


@dataclass
class NetworkSimulationResult:
    time: np.ndarray
    latent_drive: np.ndarray
    spikes: SpikeTrainCollection


def simulate_point_process(time: np.ndarray, rate_hz: np.ndarray, *, seed: int | None = None) -> PointProcessSimulation:
    t = np.asarray(time, dtype=float).reshape(-1)
    r = np.asarray(rate_hz, dtype=float).reshape(-1)
    if t.shape[0] != r.shape[0]:
        raise ValueError("time and rate_hz length mismatch")
    if t.shape[0] < 2:
        return PointProcessSimulation(t, r, SpikeTrain(np.array([], dtype=float)))

    dt = np.diff(t)
    dt = np.concatenate([dt, [dt[-1]]])
    p = 1.0 - np.exp(-np.clip(r, 0.0, np.inf) * dt)
    p = np.clip(p, 0.0, 1.0)

    rng = np.random.default_rng(seed)
    keep = rng.random(t.shape[0]) < p
    return PointProcessSimulation(t, r, SpikeTrain(t[keep]))


def simulate_two_neuron_network(
    duration_s: float = 2.0,
    dt: float = 0.001,
    base_rate_hz: float = 8.0,
    coupling: float = 1.2,
    seed: int | None = 13,
) -> NetworkSimulationResult:
    """Standalone Python replacement for Simulink-style 2-neuron network examples."""
    if duration_s <= 0 or dt <= 0:
        raise ValueError("duration_s and dt must be > 0")

    time = np.arange(0.0, duration_s + dt, dt)
    drive = np.sin(2.0 * np.pi * 2.0 * time)

    rng = np.random.default_rng(seed)
    spikes = np.zeros((time.shape[0], 2), dtype=float)
    for i in range(1, time.shape[0]):
        prev = spikes[i - 1]
        eta1 = np.log(base_rate_hz * dt) + 1.5 * drive[i] + coupling * (prev[1] - 0.1)
        eta2 = np.log(base_rate_hz * dt) - 1.5 * drive[i] + coupling * (prev[0] - 0.1)
        p1 = 1.0 / (1.0 + np.exp(-np.clip(eta1, -20.0, 20.0)))
        p2 = 1.0 / (1.0 + np.exp(-np.clip(eta2, -20.0, 20.0)))
        spikes[i, 0] = 1.0 if rng.random() < p1 else 0.0
        spikes[i, 1] = 1.0 if rng.random() < p2 else 0.0

    t1 = time[spikes[:, 0] > 0.5]
    t2 = time[spikes[:, 1] > 0.5]
    coll = SpikeTrainCollection([SpikeTrain(t1, name="neuron_1"), SpikeTrain(t2, name="neuron_2")])
    return NetworkSimulationResult(time=time, latent_drive=drive, spikes=coll)


__all__ = ["PointProcessSimulation", "NetworkSimulationResult", "simulate_point_process", "simulate_two_neuron_network"]
