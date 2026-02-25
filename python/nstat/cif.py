from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .signal import Covariate
from .simulation import simulate_poisson_from_rate
from .trial import SpikeTrainCollection


@dataclass
class CIFModel:
    """Conditional intensity function abstraction used by standalone workflows."""

    time: np.ndarray
    rate_hz: np.ndarray
    name: str = "lambda"

    def __post_init__(self) -> None:
        self.time = np.asarray(self.time, dtype=float).reshape(-1)
        self.rate_hz = np.asarray(self.rate_hz, dtype=float).reshape(-1)
        if self.time.shape[0] != self.rate_hz.shape[0]:
            raise ValueError("time and rate_hz length mismatch")

    def to_covariate(self) -> Covariate:
        return Covariate(self.time, self.rate_hz, self.name, "time", "s", "spikes/sec", [self.name])

    def simulate(self, num_realizations: int = 1, *, seed: int | None = None) -> SpikeTrainCollection:
        if num_realizations < 1:
            raise ValueError("num_realizations must be >= 1")
        rng = np.random.default_rng(seed)
        trains = []
        for i in range(num_realizations):
            st = simulate_poisson_from_rate(self.time, self.rate_hz, rng=rng)
            st.setName(str(i + 1))
            trains.append(st)
        return SpikeTrainCollection(trains)

    @classmethod
    def from_linear_terms(
        cls,
        time: np.ndarray,
        intercept: float,
        coefficients: np.ndarray,
        design_matrix: np.ndarray,
        dt: float,
        name: str = "lambda",
    ) -> "CIFModel":
        eta = intercept + np.asarray(design_matrix, dtype=float) @ np.asarray(coefficients, dtype=float)
        p = np.exp(np.clip(eta, -20.0, 20.0))
        p = p / (1.0 + p)
        rate = p / max(float(dt), 1e-12)
        return cls(np.asarray(time, dtype=float).reshape(-1), rate, name)


class CIF:
    """MATLAB-compatible CIF static API wrapper."""

    @staticmethod
    def simulateCIFByThinningFromLambda(lambda_covariate: Covariate, numRealizations: int = 1) -> SpikeTrainCollection:
        model = CIFModel(lambda_covariate.time, lambda_covariate.data[:, 0], getattr(lambda_covariate, "name", "lambda"))
        return model.simulate(num_realizations=numRealizations)

    @staticmethod
    def from_linear_terms(
        time: np.ndarray,
        intercept: float,
        coefficients: np.ndarray,
        design_matrix: np.ndarray,
        dt: float,
        name: str = "lambda",
    ) -> Covariate:
        return CIFModel.from_linear_terms(time, intercept, coefficients, design_matrix, dt, name).to_covariate()


__all__ = ["CIFModel", "CIF"]
