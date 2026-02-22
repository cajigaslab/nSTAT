from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from scipy.io import loadmat

from .analysis import psth
from .core import Covariate, nspikeTrain
from .decoding_algorithms import DecodingAlgorithms
from .glm import fit_poisson_glm
from .simulation import simulate_poisson_from_rate


def _aic_bic(log_likelihood: float, n_obs: int, n_params: int) -> tuple[float, float]:
    aic = 2.0 * n_params - 2.0 * log_likelihood
    bic = np.log(max(n_obs, 1)) * n_params - 2.0 * log_likelihood
    return float(aic), float(bic)


def _history_matrix(y: np.ndarray, lags: tuple[int, ...]) -> np.ndarray:
    x = np.zeros((y.shape[0], len(lags)), dtype=float)
    for j, lag in enumerate(lags):
        x[lag:, j] = y[:-lag]
    return x


def run_experiment2(data_dir: Path) -> dict[str, float]:
    mat_path = data_dir / "Explicit Stimulus" / "Dir3" / "Neuron1" / "Stim2" / "trngdataBis.mat"
    d = loadmat(mat_path, squeeze_me=True, struct_as_record=False)

    stim_raw = np.asarray(d["t"], dtype=float).reshape(-1)
    y = np.asarray(d["y"], dtype=float).reshape(-1)

    dt = 0.001
    time = np.arange(y.shape[0], dtype=float) * dt
    stim = stim_raw / 10.0
    stim_vel = np.gradient(stim, dt)
    hist = _history_matrix(y, lags=(1, 2, 3, 4, 5))

    x1 = np.zeros((y.shape[0], 0), dtype=float)
    x2 = np.column_stack([stim, stim_vel])
    x3 = np.column_stack([stim, stim_vel, hist])
    offset = np.full(y.shape[0], np.log(dt), dtype=float)

    m1 = fit_poisson_glm(x1, y, offset=offset)
    m2 = fit_poisson_glm(x2, y, offset=offset)
    m3 = fit_poisson_glm(x3, y, offset=offset)

    aic1, bic1 = _aic_bic(m1.log_likelihood, y.shape[0], 1)
    aic2, bic2 = _aic_bic(m2.log_likelihood, y.shape[0], 3)
    aic3, bic3 = _aic_bic(m3.log_likelihood, y.shape[0], 8)

    return {
        "n_samples": float(y.shape[0]),
        "model1_aic": aic1,
        "model2_aic": aic2,
        "model3_aic": aic3,
        "model1_bic": bic1,
        "model2_bic": bic2,
        "model3_bic": bic3,
    }


def run_experiment3(seed: int = 7) -> dict[str, float]:
    rng = np.random.default_rng(seed)
    dt = 0.001
    tmax = 1.0
    time = np.arange(0.0, tmax + dt, dt)

    f = 2.0
    mu = -3.0
    linear = np.sin(2.0 * np.pi * f * time) + mu
    p = np.exp(linear)
    p = p / (1.0 + p)
    rate_hz = p / dt

    trains = [simulate_poisson_from_rate(time, rate_hz, rng=rng) for _ in range(20)]
    bin_edges = np.arange(0.0, tmax + 0.05, 0.05)
    psth_rate, counts = psth(trains, bin_edges)

    return {
        "num_trials": float(len(trains)),
        "psth_peak_hz": float(np.max(psth_rate)),
        "psth_mean_hz": float(np.mean(psth_rate)),
        "total_spikes": float(np.sum(counts)),
    }


def _spike_indicator_from_times(time: np.ndarray, spike_times: np.ndarray) -> np.ndarray:
    y = np.zeros(time.shape[0], dtype=float)
    idx = np.searchsorted(time, spike_times, side="left")
    idx = idx[(idx >= 0) & (idx < time.shape[0])]
    if idx.size:
        y[idx] = 1.0
    return y


def _zernike_like_basis(x: np.ndarray, y: np.ndarray) -> np.ndarray:
    theta = np.arctan2(y, x)
    r = np.sqrt(x * x + y * y)
    return np.column_stack(
        [
            np.ones_like(r),
            r,
            r**2,
            np.cos(theta),
            np.sin(theta),
            r * np.cos(theta),
            r * np.sin(theta),
            r**2 * np.cos(2.0 * theta),
            r**2 * np.sin(2.0 * theta),
            r**3,
        ]
    )


def run_experiment4(data_dir: Path) -> dict[str, float]:
    mat_path = data_dir / "Place Cells" / "PlaceCellDataAnimal1.mat"
    d = loadmat(mat_path, squeeze_me=True, struct_as_record=False)

    x = np.asarray(d["x"], dtype=float).reshape(-1)
    y = np.asarray(d["y"], dtype=float).reshape(-1)
    time = np.asarray(d["time"], dtype=float).reshape(-1)
    neurons = np.asarray(d["neuron"], dtype=object).reshape(-1)

    dt = float(np.median(np.diff(time)))
    offset = np.full(time.shape[0], np.log(max(dt, 1e-12)), dtype=float)

    x_gauss = np.column_stack([x, y, x * x, y * y, x * y])
    x_zern = _zernike_like_basis(x, y)

    n_eval = int(min(8, neurons.shape[0]))
    d_aic = []
    d_bic = []
    for i in range(n_eval):
        spike_times = np.asarray(neurons[i].spikeTimes, dtype=float).reshape(-1)
        y_spike = _spike_indicator_from_times(time, spike_times)

        m_g = fit_poisson_glm(x_gauss, y_spike, offset=offset)
        m_z = fit_poisson_glm(x_zern, y_spike, offset=offset)

        aic_g, bic_g = _aic_bic(m_g.log_likelihood, y_spike.shape[0], x_gauss.shape[1] + 1)
        aic_z, bic_z = _aic_bic(m_z.log_likelihood, y_spike.shape[0], x_zern.shape[1] + 1)
        d_aic.append(aic_g - aic_z)
        d_bic.append(bic_g - bic_z)

    return {
        "num_cells_fit": float(n_eval),
        "mean_delta_aic_gaussian_minus_zernike": float(np.mean(d_aic)),
        "mean_delta_bic_gaussian_minus_zernike": float(np.mean(d_bic)),
    }


def run_experiment5(seed: int = 11) -> dict[str, float]:
    rng = np.random.default_rng(seed)

    dt = 0.001
    time = np.arange(0.0, 1.0 + dt, dt)
    stim = np.sin(2.0 * np.pi * 2.0 * time)

    n_cells = 20
    spikes = np.zeros((time.shape[0], n_cells), dtype=float)
    for i in range(n_cells):
        b1 = rng.normal(1.0, 0.5)
        b0 = np.log(10.0 * dt) + rng.normal(0.0, 0.3)
        eta = b1 * stim + b0
        p = np.exp(eta)
        p = p / (1.0 + p)
        spikes[:, i] = (rng.random(time.shape[0]) < p).astype(float)

    decoded = DecodingAlgorithms.linear_decode(spikes, stim)
    rmse = float(np.sqrt(np.mean((decoded["decoded"] - stim) ** 2)))

    return {
        "num_cells": float(n_cells),
        "decode_rmse": rmse,
    }


def run_paper_examples(repo_root: Path) -> dict[str, dict[str, float]]:
    data_dir = repo_root / "data"
    if not data_dir.exists():
        raise FileNotFoundError(f"Could not locate data directory: {data_dir}")

    return {
        "experiment2": run_experiment2(data_dir),
        "experiment3": run_experiment3(),
        "experiment4": run_experiment4(data_dir),
        "experiment5": run_experiment5(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Python nSTAT paper examples equivalent")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--no-plots", action="store_true", help="Accepted for API compatibility")
    parser.add_argument("--output-json", type=Path, default=None)
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    results = run_paper_examples(repo_root)

    if args.output_json is not None:
        args.output_json.write_text(json.dumps(results, indent=2), encoding="utf-8")

    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
