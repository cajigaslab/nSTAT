from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from scipy.io import loadmat

from .analysis import psth
from .decoding_algorithms import DecodingAlgorithms
from .glm import fit_poisson_glm
from .simulation import simulate_poisson_from_rate


def _aic_bic(log_likelihood: float, n_obs: int, n_params: int) -> tuple[float, float]:
    aic = 2.0 * n_params - 2.0 * log_likelihood
    bic = np.log(max(n_obs, 1)) * n_params - 2.0 * log_likelihood
    return float(aic), float(bic)


def _history_matrix(y: np.ndarray, lags: list[int]) -> np.ndarray:
    out = np.zeros((y.shape[0], len(lags)), dtype=float)
    for j, lag in enumerate(lags):
        out[lag:, j] = y[:-lag]
    return out


def _load_mepsc_times_seconds(path: Path) -> np.ndarray:
    arr = np.loadtxt(path, skiprows=1)
    return np.asarray(arr[:, 1], dtype=float).reshape(-1) / 1000.0


def _bin_spike_times(spikes: np.ndarray, t0: float, t1: float, dt: float) -> tuple[np.ndarray, np.ndarray]:
    n_bins = int(np.floor((t1 - t0) / dt)) + 1
    edges = t0 + np.arange(n_bins + 1, dtype=float) * dt
    counts, _ = np.histogram(spikes, bins=edges)
    return edges[:-1], counts.astype(float)


def run_experiment1(data_dir: Path) -> dict[str, float]:
    mepsc_dir = data_dir / "mEPSCs"
    epsc2 = _load_mepsc_times_seconds(mepsc_dir / "epsc2.txt")
    washout1 = _load_mepsc_times_seconds(mepsc_dir / "washout1.txt")
    washout2 = _load_mepsc_times_seconds(mepsc_dir / "washout2.txt")

    dt_const = 0.01
    _, y_const = _bin_spike_times(epsc2, 0.0, float(np.max(epsc2)), dt_const)
    off_const = np.full(y_const.shape[0], np.log(dt_const), dtype=float)
    m_const = fit_poisson_glm(np.zeros((y_const.shape[0], 0), dtype=float), y_const, offset=off_const, max_iter=80)
    aic_const, bic_const = _aic_bic(m_const.log_likelihood, y_const.shape[0], 1)

    spikes = np.concatenate([260.0 + washout1, np.sort(washout2) + 745.0])
    dt = 0.01
    t, y = _bin_spike_times(spikes, 260.0, float(np.max(spikes)), dt)
    off = np.full(y.shape[0], np.log(dt), dtype=float)

    seg2 = ((t >= 495.0) & (t < 765.0)).astype(float)
    seg3 = (t >= 765.0).astype(float)
    x_piece = np.column_stack([seg2, seg3])
    hist = _history_matrix(y, [1, 2, 3, 4, 5, 7, 10, 14, 20, 30])
    x_piece_hist = np.column_stack([x_piece, hist])

    m_piece = fit_poisson_glm(x_piece, y, offset=off, max_iter=100)
    m_piece_hist = fit_poisson_glm(x_piece_hist, y, offset=off, max_iter=120)
    aic_piece, bic_piece = _aic_bic(m_piece.log_likelihood, y.shape[0], x_piece.shape[1] + 1)
    aic_piece_hist, bic_piece_hist = _aic_bic(m_piece_hist.log_likelihood, y.shape[0], x_piece_hist.shape[1] + 1)

    return {
        "const_condition_spikes": float(np.sum(y_const)),
        "const_model_aic": aic_const,
        "const_model_bic": bic_const,
        "decreasing_condition_spikes": float(np.sum(y)),
        "piecewise_model_aic": aic_piece,
        "piecewise_model_bic": bic_piece,
        "piecewise_history_model_aic": aic_piece_hist,
        "piecewise_history_model_bic": bic_piece_hist,
        "dt_seconds": dt,
    }


def run_experiment2(data_dir: Path) -> dict[str, float]:
    d = loadmat(data_dir / "Explicit Stimulus" / "Dir3" / "Neuron1" / "Stim2" / "trngdataBis.mat", squeeze_me=True, struct_as_record=False)
    stim_raw = np.asarray(d["t"], dtype=float).reshape(-1)
    y = np.asarray(d["y"], dtype=float).reshape(-1)

    dt = 0.001
    stim = stim_raw / 10.0
    stim_vel = np.gradient(stim, dt)
    hist = _history_matrix(y, [1, 2, 3, 4, 5])

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

    linear = np.sin(2.0 * np.pi * 2.0 * time) - 3.0
    p = np.exp(linear)
    p = p / (1.0 + p)
    rate_hz = p / dt

    trains = [simulate_poisson_from_rate(time, rate_hz, rng=rng) for _ in range(20)]
    edges = np.arange(0.0, tmax + 0.05, 0.05)
    psth_rate_hz, counts = psth(trains, edges)

    return {
        "num_trials": float(len(trains)),
        "psth_peak_hz": float(np.max(psth_rate_hz)),
        "psth_mean_hz": float(np.mean(psth_rate_hz)),
        "total_spikes": float(np.sum(counts)),
    }


def run_experiment3b(data_dir: Path) -> dict[str, float]:
    d = loadmat(data_dir / "SSGLMExampleData.mat", squeeze_me=False, struct_as_record=False)
    stimulus = np.asarray(d["stimulus"], dtype=float)
    xk = np.asarray(d["xK"], dtype=float)
    stim_cis = np.asarray(d["stimCIs"], dtype=float)
    qhat = np.asarray(d["Qhat"], dtype=float).reshape(-1)
    gammahat = np.asarray(d["gammahat"], dtype=float).reshape(-1)
    logll = float(np.asarray(d["logll"], dtype=float).reshape(-1)[0])

    coverage = np.mean((stimulus >= stim_cis[:, :, 0]) & (stimulus <= stim_cis[:, :, 1]))
    rmse = np.sqrt(np.mean((xk - stimulus) ** 2))

    return {
        "num_trials": float(stimulus.shape[0]),
        "num_time_bins": float(stimulus.shape[1]),
        "state_rmse": float(rmse),
        "ci_coverage": float(coverage),
        "mean_qhat": float(np.mean(qhat)),
        "mean_gammahat": float(np.mean(gammahat)),
        "log_likelihood": logll,
    }


def _spike_indicator(time: np.ndarray, spike_times: np.ndarray) -> np.ndarray:
    y = np.zeros(time.shape[0], dtype=float)
    idx = np.searchsorted(time, spike_times, side="left")
    idx = idx[(idx >= 0) & (idx < time.shape[0])]
    if idx.size > 0:
        y[idx] = 1.0
    return y


def _zernike_like_basis(x: np.ndarray, y: np.ndarray) -> np.ndarray:
    theta = np.arctan2(y, x)
    r = np.sqrt(x * x + y * y)
    return np.column_stack([
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
    ])


def run_experiment4(data_dir: Path) -> dict[str, float]:
    d = loadmat(data_dir / "Place Cells" / "PlaceCellDataAnimal1.mat", squeeze_me=True, struct_as_record=False)
    x = np.asarray(d["x"], dtype=float).reshape(-1)
    y = np.asarray(d["y"], dtype=float).reshape(-1)
    time = np.asarray(d["time"], dtype=float).reshape(-1)
    neurons = np.asarray(d["neuron"], dtype=object).reshape(-1)

    dt = float(np.median(np.diff(time)))
    offset = np.full(time.shape[0], np.log(max(dt, 1e-12)), dtype=float)
    x_gauss = np.column_stack([x, y, x * x, y * y, x * y])
    x_zern = _zernike_like_basis(x, y)

    d_aic = []
    d_bic = []
    n_eval = int(min(8, neurons.shape[0]))
    for i in range(n_eval):
        spike_times = np.asarray(neurons[i].spikeTimes, dtype=float).reshape(-1)
        y_spike = _spike_indicator(time, spike_times)
        mg = fit_poisson_glm(x_gauss, y_spike, offset=offset)
        mz = fit_poisson_glm(x_zern, y_spike, offset=offset)
        aicg, bicg = _aic_bic(mg.log_likelihood, y_spike.shape[0], x_gauss.shape[1] + 1)
        aicz, bicz = _aic_bic(mz.log_likelihood, y_spike.shape[0], x_zern.shape[1] + 1)
        d_aic.append(aicg - aicz)
        d_bic.append(bicg - bicz)

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
    return {"num_cells": float(n_cells), "decode_rmse": rmse}


def run_experiment5b(seed: int = 19) -> dict[str, float]:
    rng = np.random.default_rng(seed)

    dt = 0.01
    time = np.arange(0.0, 20.0 + dt, dt)
    x_true = 0.25 * np.sin(2.0 * np.pi * 0.15 * time)
    y_true = 0.20 * np.cos(2.0 * np.pi * 0.10 * time)
    vx = np.gradient(x_true, dt)
    vy = np.gradient(y_true, dt)

    n_cells = 30
    spikes = np.zeros((time.shape[0], n_cells), dtype=float)
    for i in range(n_cells):
        wx = rng.normal(0.0, 1.0)
        wy = rng.normal(0.0, 1.0)
        b0 = -3.0 + rng.normal(0.0, 0.2)
        eta = b0 + 3.0 * wx * vx + 3.0 * wy * vy
        p = 1.0 / (1.0 + np.exp(-np.clip(eta, -20.0, 20.0)))
        spikes[:, i] = (rng.random(time.shape[0]) < p).astype(float)

    dx = DecodingAlgorithms.linear_decode(spikes, x_true)["decoded"]
    dy = DecodingAlgorithms.linear_decode(spikes, y_true)["decoded"]
    return {
        "num_cells": float(n_cells),
        "num_samples": float(time.shape[0]),
        "decode_rmse_x": float(np.sqrt(np.mean((dx - x_true) ** 2))),
        "decode_rmse_y": float(np.sqrt(np.mean((dy - y_true) ** 2))),
    }


def _simulate_hybrid_spikes(x: np.ndarray, mstate: np.ndarray, dt: float, n_cells: int, seed: int):
    rng = np.random.default_rng(seed)
    vx = x[2, :]
    vy = x[3, :]
    wvx = rng.normal(0.0, 1.0, size=n_cells)
    wvy = rng.normal(0.0, 1.0, size=n_cells)
    b1 = rng.normal(-3.8, 0.2, size=n_cells)
    b2 = rng.normal(-2.8, 0.2, size=n_cells)

    spikes = np.zeros((x.shape[1], n_cells), dtype=float)
    for t in range(x.shape[1]):
        base = b1 if int(mstate[t]) == 1 else b2
        eta = base + 1.2 * wvx * vx[t] + 1.2 * wvy * vy[t]
        lam = np.exp(np.clip(eta, -15.0, 15.0))
        p = 1.0 - np.exp(-lam * dt)
        spikes[t, :] = (rng.random(n_cells) < p).astype(float)
    return spikes, wvx, wvy, b1, b2


def _hybrid_state_filter(spikes: np.ndarray, x: np.ndarray, dt: float, p_ij: np.ndarray, wvx: np.ndarray, wvy: np.ndarray, b1: np.ndarray, b2: np.ndarray) -> np.ndarray:
    n_t, _ = spikes.shape
    post = np.zeros((n_t, 2), dtype=float)
    post[0, :] = [0.5, 0.5]
    vx = x[2, :]
    vy = x[3, :]

    for t in range(1, n_t):
        eta1 = b1 + 1.2 * wvx * vx[t] + 1.2 * wvy * vy[t]
        eta2 = b2 + 1.2 * wvx * vx[t] + 1.2 * wvy * vy[t]
        p1 = np.clip(1.0 - np.exp(-np.exp(np.clip(eta1, -15.0, 15.0)) * dt), 1e-6, 1.0 - 1e-6)
        p2 = np.clip(1.0 - np.exp(-np.exp(np.clip(eta2, -15.0, 15.0)) * dt), 1e-6, 1.0 - 1e-6)
        k = spikes[t, :]
        ll1 = np.sum(k * np.log(p1) + (1.0 - k) * np.log(1.0 - p1))
        ll2 = np.sum(k * np.log(p2) + (1.0 - k) * np.log(1.0 - p2))
        pred0 = max(post[t - 1, 0] * p_ij[0, 0] + post[t - 1, 1] * p_ij[1, 0], 1e-15)
        pred1 = max(post[t - 1, 0] * p_ij[0, 1] + post[t - 1, 1] * p_ij[1, 1], 1e-15)
        logs = np.array([np.log(pred0) + ll1, np.log(pred1) + ll2], dtype=float)
        logs = logs - np.max(logs)
        un = np.exp(logs)
        post[t, :] = un / np.sum(un)
    return post


def run_experiment6(repo_root: Path, seed: int = 37) -> dict[str, float]:
    d = loadmat(repo_root / "helpfiles" / "paperHybridFilterExample.mat", squeeze_me=True, struct_as_record=False)
    x = np.asarray(d["X"], dtype=float)
    mstate = np.asarray(d["mstate"], dtype=int).reshape(-1)
    p_ij = np.asarray(d["p_ij"], dtype=float)
    dt = float(np.asarray(d["delta"], dtype=float).reshape(-1)[0])

    n_cells = 24
    spikes, wvx, wvy, b1, b2 = _simulate_hybrid_spikes(x, mstate, dt, n_cells=n_cells, seed=seed)
    post = _hybrid_state_filter(spikes, x, dt, p_ij, wvx, wvy, b1, b2)
    state_hat = np.argmax(post, axis=1) + 1
    state_acc = np.mean(state_hat == mstate)

    dx = DecodingAlgorithms.linear_decode(spikes, x[0, :])["decoded"]
    dy = DecodingAlgorithms.linear_decode(spikes, x[1, :])["decoded"]
    return {
        "num_samples": float(x.shape[1]),
        "num_cells": float(n_cells),
        "state_accuracy": float(state_acc),
        "decode_rmse_x": float(np.sqrt(np.mean((dx - x[0, :]) ** 2))),
        "decode_rmse_y": float(np.sqrt(np.mean((dy - x[1, :]) ** 2))),
    }


def run_full_paper_examples(repo_root: Path) -> dict[str, dict[str, float]]:
    data_dir = repo_root / "data"
    if not data_dir.exists():
        raise FileNotFoundError(f"Could not locate data directory: {data_dir}")

    return {
        "experiment1": run_experiment1(data_dir),
        "experiment2": run_experiment2(data_dir),
        "experiment3": run_experiment3(),
        "experiment3b": run_experiment3b(data_dir),
        "experiment4": run_experiment4(data_dir),
        "experiment5": run_experiment5(),
        "experiment5b": run_experiment5b(),
        "experiment6": run_experiment6(repo_root),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Native Python approximation of nSTATPaperExamples.m")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--output-json", type=Path, default=None)
    args = parser.parse_args()

    results = run_full_paper_examples(args.repo_root.resolve())
    if args.output_json is not None:
        args.output_json.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
