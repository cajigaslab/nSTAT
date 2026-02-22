from __future__ import annotations

from typing import Sequence

import numpy as np

from .core import nspikeTrain


def _validate_time_and_rate(
    time: Sequence[float], rate_hz: Sequence[float]
) -> tuple[np.ndarray, np.ndarray]:
    time_arr = np.asarray(time, dtype=float).reshape(-1)
    rate_arr = np.asarray(rate_hz, dtype=float).reshape(-1)
    if time_arr.size == 0 or rate_arr.size == 0:
        raise ValueError("time and rate_hz must be non-empty.")
    if time_arr.shape[0] != rate_arr.shape[0]:
        raise ValueError("time and rate_hz must have identical length.")
    if np.any(np.diff(time_arr) <= 0):
        raise ValueError("time must be strictly increasing.")
    if np.any(rate_arr < 0):
        raise ValueError("rate_hz must be non-negative.")
    return time_arr, rate_arr


def simulate_poisson_from_rate(
    time: Sequence[float],
    rate_hz: Sequence[float],
    rng: np.random.Generator | None = None,
) -> nspikeTrain:
    """Simulate an inhomogeneous Poisson spike train on a time grid."""

    if rng is None:
        rng = np.random.default_rng()
    time_arr, rate_arr = _validate_time_and_rate(time, rate_hz)

    dt = np.diff(time_arr)
    dt_per_sample = np.empty_like(time_arr)
    dt_per_sample[0] = dt[0]
    dt_per_sample[1:] = dt

    p_spike = 1.0 - np.exp(-rate_arr * dt_per_sample)
    p_spike = np.clip(p_spike, 0.0, 1.0)
    spikes = rng.random(time_arr.shape[0]) < p_spike

    spike_times = time_arr[spikes]
    binwidth = float(np.median(dt_per_sample)) if dt_per_sample.size else 0.001
    return nspikeTrain(
        spike_times,
        name="",
        binwidth=binwidth,
        minTime=float(time_arr[0]),
        maxTime=float(time_arr[-1]),
    )


def simulate_cif_from_stimulus(
    time: Sequence[float],
    stimulus: Sequence[float],
    beta0: float = -3.0,
    beta1: float = 1.0,
    rng: np.random.Generator | None = None,
) -> tuple[nspikeTrain, np.ndarray, np.ndarray]:
    """Simulate lambda(t) = exp(beta0 + beta1 * stimulus)."""

    stim_arr = np.asarray(stimulus, dtype=float).reshape(-1)
    time_arr = np.asarray(time, dtype=float).reshape(-1)
    if stim_arr.shape[0] != time_arr.shape[0]:
        raise ValueError("stimulus and time must have identical length.")

    linear_predictor = beta0 + beta1 * stim_arr
    rate_hz = np.exp(np.clip(linear_predictor, -20.0, 20.0))
    spike_train = simulate_poisson_from_rate(time_arr, rate_hz, rng=rng)
    return spike_train, rate_hz, linear_predictor
