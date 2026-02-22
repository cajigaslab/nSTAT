from __future__ import annotations

from typing import Sequence

import numpy as np

from .core import Covariate, nspikeTrain
from .fit import FitResult, _SingleFit
from .glm import fit_poisson_glm
from .trial import ConfigColl, Trial, TrialConfig


def spike_indicator(spike_train: nspikeTrain, time: Sequence[float]) -> np.ndarray:
    t = np.asarray(time, dtype=float).reshape(-1)
    if t.size < 2:
        raise ValueError("time must include at least two samples.")
    if np.any(np.diff(t) <= 0):
        raise ValueError("time must be strictly increasing.")

    dt = np.diff(t)
    edges = np.concatenate([t, [t[-1] + dt[-1]]])
    counts = spike_train.to_binned_counts(edges)
    return (counts > 0).astype(float)


def psth(spike_trains: Sequence[nspikeTrain], bin_edges: Sequence[float]) -> tuple[np.ndarray, np.ndarray]:
    if len(spike_trains) == 0:
        raise ValueError("spike_trains must contain at least one trial.")

    edges = np.asarray(bin_edges, dtype=float).reshape(-1)
    if edges.size < 2:
        raise ValueError("bin_edges must contain at least 2 values.")
    if np.any(np.diff(edges) <= 0):
        raise ValueError("bin_edges must be strictly increasing.")

    counts = np.vstack([trial.to_binned_counts(edges) for trial in spike_trains])
    mean_rate_hz = counts.mean(axis=0) / np.diff(edges)
    return mean_rate_hz, counts


class Analysis:
    """Python analogue of MATLAB Analysis class."""

    @staticmethod
    def RunAnalysisForAllNeurons(trial: Trial, config_coll: ConfigColl, _verbose: int = 0):
        time, x_all, labels = trial.get_covariate_matrix()
        dt = float(np.median(np.diff(time)))
        y = spike_indicator(trial.spikeColl.getNST(1), time)

        lambda_signals: list[Covariate] = []
        fits: list[_SingleFit] = []

        for i, cfg in enumerate(config_coll.configArray, start=1):
            feature_mask = Analysis._resolve_feature_mask(labels, cfg)
            x = x_all[:, feature_mask]
            offset = np.log(np.maximum(dt, 1e-12))
            model = fit_poisson_glm(x, y, offset=offset)
            lam = model.predict_rate(x, offset=offset)
            name = cfg.name if cfg.name else f"Fit {i}"

            n = y.shape[0]
            k = x.shape[1] + 1
            aic = 2.0 * k - 2.0 * model.log_likelihood
            bic = np.log(max(n, 1)) * k - 2.0 * model.log_likelihood

            lambda_signals.append(
                Covariate(
                    time,
                    lam,
                    "lambda",
                    "time",
                    "s",
                    "spikes/sec",
                    [f"lambda_{i}"],
                )
            )
            fits.append(
                _SingleFit(
                    name=name,
                    coefficients=model.coefficients,
                    intercept=model.intercept,
                    log_likelihood=model.log_likelihood,
                    aic=float(aic),
                    bic=float(bic),
                )
            )

        merged_lambda = lambda_signals[0]
        for sig in lambda_signals[1:]:
            merged_lambda = merged_lambda.merge(sig)

        fit_result = FitResult(trial.spikeColl.getNST(1), merged_lambda, fits)
        return fit_result

    @staticmethod
    def _resolve_feature_mask(labels: list[str], cfg: TrialConfig) -> np.ndarray:
        requested: set[str] = set()
        for entry in cfg.covMask:
            if len(entry) <= 1:
                continue
            for name in entry[1:]:
                requested.add(str(name))

        if not requested:
            return np.arange(len(labels), dtype=int)

        idx = [i for i, label in enumerate(labels) if label in requested]
        if not idx:
            return np.arange(len(labels), dtype=int)
        return np.asarray(idx, dtype=int)


__all__ = ["Analysis", "psth", "spike_indicator"]
