from __future__ import annotations

import numpy as np


class DecodingAlgorithms:
    @staticmethod
    def linear_decode(spike_counts: np.ndarray, stimulus: np.ndarray) -> dict[str, np.ndarray]:
        x = np.asarray(spike_counts, dtype=float)
        y = np.asarray(stimulus, dtype=float).reshape(-1)
        if x.ndim == 1:
            x = x[:, None]
        if x.shape[0] != y.shape[0]:
            raise ValueError("spike_counts and stimulus must align")

        x_aug = np.column_stack([np.ones(x.shape[0]), x])
        beta, *_ = np.linalg.lstsq(x_aug, y, rcond=None)
        y_hat = x_aug @ beta
        resid = y - y_hat
        sigma = float(np.std(resid))
        ci = np.column_stack([y_hat - 1.96 * sigma, y_hat + 1.96 * sigma])
        return {"coefficients": beta, "decoded": y_hat, "residual": resid, "ci": ci}
