from __future__ import annotations

import numpy as np

from .core import Covariate
from .simulation import simulate_poisson_from_rate
from .trial import nstColl


class CIF:
    """Subset of MATLAB CIF behavior for Python workflows."""

    @staticmethod
    def simulateCIFByThinningFromLambda(lambda_covariate: Covariate, numRealizations: int = 1) -> nstColl:
        if numRealizations < 1:
            raise ValueError("numRealizations must be >= 1")

        time = lambda_covariate.time
        rate = lambda_covariate.data[:, 0]
        trains = []
        for i in range(numRealizations):
            st = simulate_poisson_from_rate(time, rate)
            st.setName(str(i + 1))
            trains.append(st)
        return nstColl(trains)

    @staticmethod
    def from_linear_terms(
        time: np.ndarray,
        intercept: float,
        coefficients: np.ndarray,
        design_matrix: np.ndarray,
        dt: float,
        name: str = "lambda",
    ) -> Covariate:
        eta = intercept + design_matrix @ coefficients
        p = np.exp(np.clip(eta, -20.0, 20.0))
        p = p / (1.0 + p)
        rate = p / max(dt, 1e-12)
        return Covariate(time, rate, name, "time", "s", "spikes/sec", [name])
