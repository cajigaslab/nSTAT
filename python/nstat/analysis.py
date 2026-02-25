from __future__ import annotations

from typing import Sequence

import numpy as np

from .fit import FitResult, _SingleFit
from .glm import fit_poisson_glm
from .signal import Covariate
from .trial import ConfigCollection, Trial


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


class Analysis:
    """Canonical analysis entry points preserving the paper's workflow semantics."""

    @staticmethod
    def psth(spike_trains: Sequence[object], bin_edges: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
        return psth(spike_trains, bin_edges)

    @staticmethod
    def run_analysis_for_neuron(
        trial: Trial,
        neuron_index: int,
        config_collection: ConfigCollection,
        *,
        l2: float = 1e-6,
        max_iter: int = 120,
    ) -> FitResult:
        time, x_all, labels = trial.get_covariate_matrix()
        spike_train = trial.spike_collection.get_nst(neuron_index)

        dt = float(np.median(np.diff(time))) if time.shape[0] > 1 else 1.0
        edges = np.concatenate([time, [time[-1] + dt]])
        y = spike_train.to_binned_counts(edges)
        offset = np.full(y.shape[0], np.log(max(dt, 1e-12)), dtype=float)

        fits: list[_SingleFit] = []
        for idx, cfg in enumerate(config_collection.configs, start=1):
            names = cfg.covariate_names
            if names:
                cols = [i for i, lab in enumerate(labels) if lab in set(names)]
                x = x_all[:, cols] if cols else np.zeros((x_all.shape[0], 0), dtype=float)
            else:
                x = x_all

            glm_res = fit_poisson_glm(x, y, offset=offset, l2=l2, max_iter=max_iter)
            n_params = x.shape[1] + 1
            aic = 2.0 * n_params - 2.0 * glm_res.log_likelihood
            bic = np.log(max(y.shape[0], 1)) * n_params - 2.0 * glm_res.log_likelihood
            fit_name = cfg.name if cfg.name else f"Fit {idx}"
            fits.append(
                _SingleFit(
                    name=fit_name,
                    coefficients=np.asarray(glm_res.coefficients, dtype=float),
                    intercept=float(glm_res.intercept),
                    log_likelihood=float(glm_res.log_likelihood),
                    aic=float(aic),
                    bic=float(bic),
                )
            )

        if x_all.shape[1] == 0:
            x_for_rate = np.zeros((y.shape[0], 0), dtype=float)
        else:
            x_for_rate = x_all
        rate = fit_poisson_glm(x_for_rate, y, offset=offset, l2=l2, max_iter=max_iter).predict_rate(x_for_rate, offset=offset)
        lambda_signal = Covariate(time, rate, "lambda", "time", "s", "spikes/sec", ["lambda"])
        return FitResult(spike_train, lambda_signal, fits)

    @staticmethod
    def run_analysis_for_all_neurons(
        trial: Trial,
        config_collection: ConfigCollection,
        *,
        l2: float = 1e-6,
        max_iter: int = 120,
    ) -> list[FitResult]:
        out: list[FitResult] = []
        for i in range(trial.spike_collection.num_spike_trains):
            out.append(
                Analysis.run_analysis_for_neuron(
                    trial,
                    i,
                    config_collection,
                    l2=l2,
                    max_iter=max_iter,
                )
            )
        return out

    # MATLAB-compatible method names.
    @staticmethod
    def RunAnalysisForNeuron(tObj: Trial, neuronNumber: int, configColl: ConfigCollection):
        return Analysis.run_analysis_for_neuron(tObj, neuronNumber - 1, configColl)

    @staticmethod
    def RunAnalysisForAllNeurons(tObj: Trial, configs: ConfigCollection, *_):
        return Analysis.run_analysis_for_all_neurons(tObj, configs)


__all__ = ["Analysis", "psth"]
