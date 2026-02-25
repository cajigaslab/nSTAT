from __future__ import annotations

import numpy as np

from .decoding_algorithms import DecodingAlgorithms


class DecoderSuite:
    """Canonical decoding API for the Python nSTAT package."""

    @staticmethod
    def linear(spike_counts: np.ndarray, stimulus: np.ndarray) -> dict[str, np.ndarray]:
        return DecodingAlgorithms.linear_decode(spike_counts, stimulus)

    @staticmethod
    def kalman(
        observations: np.ndarray,
        transition: np.ndarray,
        observation_matrix: np.ndarray,
        q_cov: np.ndarray,
        r_cov: np.ndarray,
        x0: np.ndarray,
        p0: np.ndarray,
    ) -> dict[str, np.ndarray]:
        """Basic linear Kalman filter used for standalone decoding workflows."""
        y = np.asarray(observations, dtype=float)
        a = np.asarray(transition, dtype=float)
        h = np.asarray(observation_matrix, dtype=float)
        q = np.asarray(q_cov, dtype=float)
        r = np.asarray(r_cov, dtype=float)
        x_prev = np.asarray(x0, dtype=float).reshape(-1)
        p_prev = np.asarray(p0, dtype=float)

        n_t = y.shape[0]
        n_x = x_prev.shape[0]
        xs = np.zeros((n_t, n_x), dtype=float)
        ps = np.zeros((n_t, n_x, n_x), dtype=float)

        for t in range(n_t):
            x_pred = a @ x_prev
            p_pred = a @ p_prev @ a.T + q

            innovation = y[t] - h @ x_pred
            s_cov = h @ p_pred @ h.T + r
            k_gain = p_pred @ h.T @ np.linalg.pinv(s_cov)

            x_post = x_pred + k_gain @ innovation
            p_post = (np.eye(n_x) - k_gain @ h) @ p_pred

            xs[t] = x_post
            ps[t] = p_post
            x_prev = x_post
            p_prev = p_post

        return {"state": xs, "cov": ps}


__all__ = ["DecoderSuite"]
