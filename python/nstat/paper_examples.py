from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import numpy as np
from scipy.io import loadmat

from .analysis import psth
from .decoding_algorithms import DecodingAlgorithms
from .glm import fit_poisson_glm
from .simulation import simulate_poisson_from_rate


Summary = dict[str, float]
Payload = dict[str, Any]
Results = dict[str, Summary]
PlotPayloads = dict[str, Payload]


def _aic_bic(log_likelihood: float, n_obs: int, n_params: int) -> tuple[float, float]:
    aic = 2.0 * n_params - 2.0 * log_likelihood
    bic = np.log(max(n_obs, 1)) * n_params - 2.0 * log_likelihood
    return float(aic), float(bic)


def _history_matrix(y: np.ndarray, lags: tuple[int, ...]) -> np.ndarray:
    x = np.zeros((y.shape[0], len(lags)), dtype=float)
    for j, lag in enumerate(lags):
        x[lag:, j] = y[:-lag]
    return x


def _bin_mean(values: np.ndarray, samples_per_bin: int) -> np.ndarray:
    n_bins = values.shape[0] // samples_per_bin
    if n_bins < 1:
        return np.asarray([], dtype=float)
    trimmed = values[: n_bins * samples_per_bin]
    return trimmed.reshape(n_bins, samples_per_bin).mean(axis=1)


def _bin_sum(values: np.ndarray, samples_per_bin: int) -> np.ndarray:
    n_bins = values.shape[0] // samples_per_bin
    if n_bins < 1:
        return np.asarray([], dtype=float)
    trimmed = values[: n_bins * samples_per_bin]
    return trimmed.reshape(n_bins, samples_per_bin).sum(axis=1)


def run_experiment2(data_dir: Path, *, return_payload: bool = False) -> Summary | tuple[Summary, Payload]:
    mat_path = data_dir / "Explicit Stimulus" / "Dir3" / "Neuron1" / "Stim2" / "trngdataBis.mat"
    d = loadmat(mat_path, squeeze_me=True, struct_as_record=False)

    stim_raw = np.asarray(d["t"], dtype=float).reshape(-1)
    y = np.asarray(d["y"], dtype=float).reshape(-1)

    dt = 0.001
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

    summary: Summary = {
        "n_samples": float(y.shape[0]),
        "model1_aic": aic1,
        "model2_aic": aic2,
        "model3_aic": aic3,
        "model1_bic": bic1,
        "model2_bic": bic2,
        "model3_bic": bic3,
    }
    if not return_payload:
        return summary

    rate1_hz = m1.predict_rate(x1, offset=offset)
    rate2_hz = m2.predict_rate(x2, offset=offset)
    rate3_hz = m3.predict_rate(x3, offset=offset)

    samples_per_bin = 50  # 50 ms bins.
    t_binned = np.arange(y.shape[0] // samples_per_bin, dtype=float) * dt * samples_per_bin
    obs_rate_hz = _bin_sum(y, samples_per_bin) / (dt * samples_per_bin)
    stim_binned = _bin_mean(stim, samples_per_bin)
    rate1_binned_hz = _bin_mean(rate1_hz, samples_per_bin)
    rate2_binned_hz = _bin_mean(rate2_hz, samples_per_bin)
    rate3_binned_hz = _bin_mean(rate3_hz, samples_per_bin)

    payload: Payload = {
        "time_binned_s": t_binned,
        "stimulus_binned": stim_binned,
        "obs_rate_hz": obs_rate_hz,
        "rate1_binned_hz": rate1_binned_hz,
        "rate2_binned_hz": rate2_binned_hz,
        "rate3_binned_hz": rate3_binned_hz,
        "aic": np.asarray([aic1, aic2, aic3], dtype=float),
        "bic": np.asarray([bic1, bic2, bic3], dtype=float),
    }
    return summary, payload


def run_experiment3(seed: int = 7, *, return_payload: bool = False) -> Summary | tuple[Summary, Payload]:
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
    psth_rate_hz, counts = psth(trains, bin_edges)

    summary: Summary = {
        "num_trials": float(len(trains)),
        "psth_peak_hz": float(np.max(psth_rate_hz)),
        "psth_mean_hz": float(np.mean(psth_rate_hz)),
        "total_spikes": float(np.sum(counts)),
    }
    if not return_payload:
        return summary

    payload: Payload = {
        "time_s": time,
        "true_rate_hz": rate_hz,
        "psth_bin_centers_s": 0.5 * (bin_edges[:-1] + bin_edges[1:]),
        "psth_rate_hz": psth_rate_hz,
        "raster_spike_times": [np.asarray(train.spikeTimes, dtype=float) for train in trains],
    }
    return summary, payload


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


def run_experiment4(data_dir: Path, *, return_payload: bool = False) -> Summary | tuple[Summary, Payload]:
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
    delta_aic = []
    delta_bic = []
    for i in range(n_eval):
        spike_times = np.asarray(neurons[i].spikeTimes, dtype=float).reshape(-1)
        y_spike = _spike_indicator_from_times(time, spike_times)

        m_g = fit_poisson_glm(x_gauss, y_spike, offset=offset)
        m_z = fit_poisson_glm(x_zern, y_spike, offset=offset)

        aic_g, bic_g = _aic_bic(m_g.log_likelihood, y_spike.shape[0], x_gauss.shape[1] + 1)
        aic_z, bic_z = _aic_bic(m_z.log_likelihood, y_spike.shape[0], x_zern.shape[1] + 1)
        delta_aic.append(aic_g - aic_z)
        delta_bic.append(bic_g - bic_z)

    summary: Summary = {
        "num_cells_fit": float(n_eval),
        "mean_delta_aic_gaussian_minus_zernike": float(np.mean(delta_aic)),
        "mean_delta_bic_gaussian_minus_zernike": float(np.mean(delta_bic)),
    }
    if not return_payload:
        return summary

    first_cell_spikes = np.asarray(neurons[0].spikeTimes, dtype=float).reshape(-1)
    payload: Payload = {
        "time_s": time,
        "x_pos": x,
        "y_pos": y,
        "first_cell_spike_times_s": first_cell_spikes,
        "delta_aic": np.asarray(delta_aic, dtype=float),
        "delta_bic": np.asarray(delta_bic, dtype=float),
    }
    return summary, payload


def run_experiment5(seed: int = 11, *, return_payload: bool = False) -> Summary | tuple[Summary, Payload]:
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

    summary: Summary = {
        "num_cells": float(n_cells),
        "decode_rmse": rmse,
    }
    if not return_payload:
        return summary

    payload: Payload = {
        "time_s": time,
        "stimulus": stim,
        "decoded": np.asarray(decoded["decoded"], dtype=float),
        "ci_low": np.asarray(decoded["ci"][:, 0], dtype=float),
        "ci_high": np.asarray(decoded["ci"][:, 1], dtype=float),
    }
    return summary, payload


def run_paper_examples(
    repo_root: Path, *, return_plot_data: bool = False
) -> Results | tuple[Results, PlotPayloads]:
    data_dir = repo_root / "data"
    if not data_dir.exists():
        raise FileNotFoundError(f"Could not locate data directory: {data_dir}")

    if not return_plot_data:
        return {
            "experiment2": run_experiment2(data_dir),  # type: ignore[arg-type]
            "experiment3": run_experiment3(),
            "experiment4": run_experiment4(data_dir),  # type: ignore[arg-type]
            "experiment5": run_experiment5(),
        }

    exp2_summary, exp2_payload = run_experiment2(data_dir, return_payload=True)  # type: ignore[misc]
    exp3_summary, exp3_payload = run_experiment3(return_payload=True)  # type: ignore[misc]
    exp4_summary, exp4_payload = run_experiment4(data_dir, return_payload=True)  # type: ignore[misc]
    exp5_summary, exp5_payload = run_experiment5(return_payload=True)  # type: ignore[misc]

    results: Results = {
        "experiment2": exp2_summary,
        "experiment3": exp3_summary,
        "experiment4": exp4_summary,
        "experiment5": exp5_summary,
    }
    plot_payloads: PlotPayloads = {
        "experiment2": exp2_payload,
        "experiment3": exp3_payload,
        "experiment4": exp4_payload,
        "experiment5": exp5_payload,
    }
    return results, plot_payloads


def _save_paper_example_plots(plot_payloads: PlotPayloads, plots_dir: Path) -> list[Path]:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    plots_dir.mkdir(parents=True, exist_ok=True)
    saved_paths: list[Path] = []

    # Experiment 2: explicit stimulus + model comparison.
    e2 = plot_payloads["experiment2"]
    fig, (ax_rate, ax_metrics) = plt.subplots(2, 1, figsize=(11, 8), constrained_layout=True)
    ax_rate.plot(e2["time_binned_s"], e2["obs_rate_hz"], label="Observed spike rate", color="tab:blue", lw=1.5)
    ax_rate.plot(e2["time_binned_s"], e2["rate1_binned_hz"], label="Model 1 rate", color="tab:orange", lw=1.2)
    ax_rate.plot(e2["time_binned_s"], e2["rate2_binned_hz"], label="Model 2 rate", color="tab:green", lw=1.2)
    ax_rate.plot(e2["time_binned_s"], e2["rate3_binned_hz"], label="Model 3 rate", color="tab:red", lw=1.2)
    ax_rate.set_title("Experiment 2: Stimulus and GLM Rate Fits")
    ax_rate.set_xlabel("Time (s)")
    ax_rate.set_ylabel("Rate (Hz)")
    ax_rate.grid(alpha=0.3)

    ax_stim = ax_rate.twinx()
    ax_stim.plot(e2["time_binned_s"], e2["stimulus_binned"], color="black", alpha=0.25, lw=1.0, label="Stimulus")
    ax_stim.set_ylabel("Stimulus (a.u.)")

    handles1, labels1 = ax_rate.get_legend_handles_labels()
    handles2, labels2 = ax_stim.get_legend_handles_labels()
    ax_rate.legend(handles1 + handles2, labels1 + labels2, loc="upper right", fontsize=8)

    xloc = np.arange(3)
    ax_metrics.bar(xloc - 0.175, e2["aic"], width=0.35, label="AIC", color="tab:purple")
    ax_metrics.bar(xloc + 0.175, e2["bic"], width=0.35, label="BIC", color="tab:brown")
    ax_metrics.set_xticks(xloc, ["Model 1", "Model 2", "Model 3"])
    ax_metrics.set_ylabel("Information Criterion")
    ax_metrics.set_title("Experiment 2: Model Comparison")
    ax_metrics.grid(alpha=0.3, axis="y")
    ax_metrics.legend()

    out = plots_dir / "experiment2_stimulus_glm_comparison.png"
    fig.savefig(out, dpi=180)
    plt.close(fig)
    saved_paths.append(out)

    # Experiment 3: true CIF and PSTH with raster.
    e3 = plot_payloads["experiment3"]
    fig, (ax_rate, ax_raster) = plt.subplots(2, 1, figsize=(11, 8), constrained_layout=True)
    ax_rate.plot(e3["time_s"], e3["true_rate_hz"], color="tab:gray", lw=1.5, label="True rate")
    ax_rate.step(
        e3["psth_bin_centers_s"],
        e3["psth_rate_hz"],
        where="mid",
        color="tab:blue",
        lw=2.0,
        label="Estimated PSTH",
    )
    ax_rate.set_title("Experiment 3: Simulated CIF and Estimated PSTH")
    ax_rate.set_xlabel("Time (s)")
    ax_rate.set_ylabel("Rate (Hz)")
    ax_rate.grid(alpha=0.3)
    ax_rate.legend(loc="upper right")

    n_show = min(10, len(e3["raster_spike_times"]))
    for row, spikes in enumerate(e3["raster_spike_times"][:n_show], start=1):
        if len(spikes) > 0:
            ax_raster.vlines(spikes, row - 0.4, row + 0.4, color="black", lw=0.6)
    ax_raster.set_ylim(0.5, n_show + 0.5)
    ax_raster.set_title("Experiment 3: Spike Raster (first 10 trials)")
    ax_raster.set_xlabel("Time (s)")
    ax_raster.set_ylabel("Trial")
    ax_raster.grid(alpha=0.2)

    out = plots_dir / "experiment3_psth_and_raster.png"
    fig.savefig(out, dpi=180)
    plt.close(fig)
    saved_paths.append(out)

    # Experiment 4: trajectory and model deltas.
    e4 = plot_payloads["experiment4"]
    fig, (ax_traj, ax_delta) = plt.subplots(1, 2, figsize=(13, 5.5), constrained_layout=True)
    ax_traj.plot(e4["x_pos"], e4["y_pos"], color="tab:blue", alpha=0.45, lw=0.8, label="Trajectory")
    spike_x = np.interp(e4["first_cell_spike_times_s"], e4["time_s"], e4["x_pos"])
    spike_y = np.interp(e4["first_cell_spike_times_s"], e4["time_s"], e4["y_pos"])
    ax_traj.scatter(spike_x, spike_y, s=8, color="tab:red", alpha=0.6, label="Cell 1 spikes")
    ax_traj.set_title("Experiment 4: Place Trajectory and Cell 1 Spikes")
    ax_traj.set_xlabel("X position")
    ax_traj.set_ylabel("Y position")
    ax_traj.set_aspect("equal", adjustable="box")
    ax_traj.grid(alpha=0.3)
    ax_traj.legend(loc="upper right", fontsize=8)

    cells = np.arange(1, len(e4["delta_aic"]) + 1)
    ax_delta.plot(cells, e4["delta_aic"], marker="o", lw=1.5, color="tab:purple", label="Delta AIC")
    ax_delta.plot(cells, e4["delta_bic"], marker="s", lw=1.5, color="tab:green", label="Delta BIC")
    ax_delta.axhline(0.0, color="black", lw=1.0, alpha=0.5)
    ax_delta.set_title("Experiment 4: Gaussian - Zernike Model Delta")
    ax_delta.set_xlabel("Cell index")
    ax_delta.set_ylabel("Score difference")
    ax_delta.grid(alpha=0.3)
    ax_delta.legend(loc="upper right")

    out = plots_dir / "experiment4_placecell_model_comparison.png"
    fig.savefig(out, dpi=180)
    plt.close(fig)
    saved_paths.append(out)

    # Experiment 5: decode quality with confidence bounds.
    e5 = plot_payloads["experiment5"]
    fig, ax = plt.subplots(1, 1, figsize=(11, 4.5), constrained_layout=True)
    ax.plot(e5["time_s"], e5["stimulus"], color="tab:blue", lw=1.8, label="True stimulus")
    ax.plot(e5["time_s"], e5["decoded"], color="tab:orange", lw=1.5, label="Decoded stimulus")
    ax.fill_between(e5["time_s"], e5["ci_low"], e5["ci_high"], color="tab:orange", alpha=0.2, label="95% CI")
    ax.set_title("Experiment 5: Linear Decoding of Simulated Stimulus")
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Stimulus (a.u.)")
    ax.grid(alpha=0.3)
    ax.legend(loc="upper right")

    out = plots_dir / "experiment5_stimulus_decoding.png"
    fig.savefig(out, dpi=180)
    plt.close(fig)
    saved_paths.append(out)

    return saved_paths


def main() -> int:
    parser = argparse.ArgumentParser(description="Python nSTAT paper examples equivalent")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--no-plots", action="store_true", help="Run metrics only without generating plots")
    parser.add_argument("--plots-dir", type=Path, default=None, help="Directory for generated PNG plots")
    parser.add_argument("--output-json", type=Path, default=None)
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    default_plots_dir = repo_root / "python" / "plots" / "nstat_paper_examples"
    plots_dir = (args.plots_dir or default_plots_dir).resolve()

    if args.no_plots:
        results = run_paper_examples(repo_root)
        saved_plots: list[Path] = []
    else:
        results, payloads = run_paper_examples(repo_root, return_plot_data=True)
        saved_plots = _save_paper_example_plots(payloads, plots_dir)

    if args.output_json is not None:
        args.output_json.write_text(json.dumps(results, indent=2), encoding="utf-8")

    print(json.dumps(results, indent=2))
    if saved_plots:
        print("\nGenerated plots:")
        for path in saved_plots:
            print(str(path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
