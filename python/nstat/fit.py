from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np

from .core import Covariate, SignalObj, nspikeTrain


@dataclass
class _SingleFit:
    name: str
    coefficients: np.ndarray
    intercept: float
    log_likelihood: float
    aic: float
    bic: float


class FitResult:
    """Simplified Python FitResult compatible with nSTAT workflows."""

    def __init__(
        self,
        neuralSpikeTrain: nspikeTrain,
        lambda_signal: Covariate,
        fits: list[_SingleFit],
    ) -> None:
        self.neuralSpikeTrain = neuralSpikeTrain
        self.lambda_signal = lambda_signal
        self.fits = fits
        self.numResults = len(fits)
        self.AIC = np.asarray([f.aic for f in fits], dtype=float)
        self.BIC = np.asarray([f.bic for f in fits], dtype=float)
        self.logLL = np.asarray([f.log_likelihood for f in fits], dtype=float)
        self.KSStats = np.zeros((self.numResults, 1), dtype=float)
        self.configNames = [f.name for f in fits]
        self.lambda_ = lambda_signal

    @property
    def lambdaSignal(self) -> Covariate:
        return self.lambda_signal

    @property
    def lambda_sig(self) -> Covariate:
        return self.lambda_signal

    @property
    def lambdaCov(self) -> Covariate:
        return self.lambda_signal

    @property
    def lambdaObj(self) -> Covariate:
        return self.lambda_signal

    @property
    def lambda_data(self) -> np.ndarray:
        return self.lambda_signal.data

    @property
    def lambda_values(self) -> np.ndarray:
        return self.lambda_signal.data

    @property
    def lambda_time(self) -> np.ndarray:
        return self.lambda_signal.time

    @property
    def lambda_rate(self) -> np.ndarray:
        return self.lambda_signal.data

    @property
    def lambda_model(self) -> Covariate:
        return self.lambda_signal

    @property
    def lambda_result(self) -> Covariate:
        return self.lambda_signal

    @property
    def lambda_(self) -> Covariate:
        return self.lambda_signal

    @lambda_.setter
    def lambda_(self, value: Covariate) -> None:
        self.lambda_signal = value

    def getCoeffs(self, fit_num: int = 1) -> np.ndarray:
        return self.fits[fit_num - 1].coefficients.copy()

    def getHistCoeffs(self, fit_num: int = 1) -> np.ndarray:
        # Placeholder for compatibility.
        return np.array([], dtype=float)

    def mergeResults(self, other: "FitResult") -> "FitResult":
        merged_fits = [*self.fits, *other.fits]
        merged_lambda = self.lambda_signal.merge(other.lambda_signal)
        out = FitResult(self.neuralSpikeTrain, merged_lambda, merged_fits)
        return out

    def plotResults(self, *_, **__) -> None:
        return None

    def KSPlot(self, *_, **__) -> None:
        return None

    def plotResidual(self, *_, **__) -> None:
        return None

    def plotInvGausTrans(self, *_, **__) -> None:
        return None

    def plotSeqCorr(self, *_, **__) -> None:
        return None

    def plotCoeffs(self, *_, **__) -> None:
        return None

    @property
    def lambda_obj(self) -> Covariate:
        return self.lambda_signal

    def toStructure(self) -> dict[str, Any]:
        return {
            "fits": [
                {
                    "name": f.name,
                    "coefficients": f.coefficients.tolist(),
                    "intercept": f.intercept,
                    "log_likelihood": f.log_likelihood,
                    "aic": f.aic,
                    "bic": f.bic,
                }
                for f in self.fits
            ],
            "lambda_time": self.lambda_signal.time.tolist(),
            "lambda_data": self.lambda_signal.data.tolist(),
            "neural_spike_times": self.neuralSpikeTrain.spikeTimes.tolist(),
            "neural_name": self.neuralSpikeTrain.name,
            "neural_min_time": self.neuralSpikeTrain.minTime,
            "neural_max_time": self.neuralSpikeTrain.maxTime,
        }

    @staticmethod
    def fromStructure(structure: dict[str, Any]) -> "FitResult":
        train = nspikeTrain(
            structure["neural_spike_times"],
            name=structure.get("neural_name", ""),
            minTime=structure.get("neural_min_time"),
            maxTime=structure.get("neural_max_time"),
        )
        lam = Covariate(
            structure["lambda_time"],
            np.asarray(structure["lambda_data"], dtype=float),
            "lambda",
            "time",
            "s",
            "spikes/sec",
        )
        fits = []
        for f in structure["fits"]:
            fits.append(
                _SingleFit(
                    name=f["name"],
                    coefficients=np.asarray(f["coefficients"], dtype=float),
                    intercept=float(f["intercept"]),
                    log_likelihood=float(f["log_likelihood"]),
                    aic=float(f["aic"]),
                    bic=float(f["bic"]),
                )
            )
        return FitResult(train, lam, fits)


class FitResSummary:
    def __init__(self, fit_result: FitResult) -> None:
        self.fit_result = fit_result
        self.AIC = fit_result.AIC.copy()
        self.BIC = fit_result.BIC.copy()
        # Keep KS as 2D for compatibility with MATLAB usage.
        self.KSStats = np.column_stack([fit_result.KSStats.reshape(-1), np.zeros(fit_result.numResults)])
        self.numNeurons = 1

    def getDiffAIC(self, idx: int = 1) -> np.ndarray:
        base = self.AIC[idx - 1]
        return self.AIC - base

    def getDiffBIC(self, idx: int = 1) -> np.ndarray:
        base = self.BIC[idx - 1]
        return self.BIC - base

    def plotSummary(self, *_, **__) -> None:
        return None


__all__ = ["FitResult", "FitResSummary", "_SingleFit"]
