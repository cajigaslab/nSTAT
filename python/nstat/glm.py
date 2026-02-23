from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

import numpy as np


@dataclass(frozen=True)
class PoissonGLMResult:
    intercept: float
    coefficients: np.ndarray
    n_iter: int
    converged: bool
    log_likelihood: float

    def predict_rate(
        self, x: Sequence[Sequence[float]] | Sequence[float] | np.ndarray, offset: Sequence[float] | np.ndarray | None = None
    ) -> np.ndarray:
        x_arr = np.asarray(x, dtype=float)
        if x_arr.ndim == 1:
            x_arr = x_arr[:, None]
        eta = self.intercept + x_arr @ self.coefficients
        if offset is not None:
            eta = eta + np.asarray(offset, dtype=float).reshape(-1)
        return np.exp(np.clip(eta, -20.0, 20.0))


def fit_poisson_glm(
    x: Sequence[Sequence[float]] | Sequence[float] | np.ndarray,
    y: Sequence[float] | np.ndarray,
    *,
    offset: Sequence[float] | np.ndarray | None = None,
    l2: float = 1e-6,
    max_iter: int = 120,
    tol: float = 1e-8,
) -> PoissonGLMResult:
    x_arr = np.asarray(x, dtype=float)
    y_arr = np.asarray(y, dtype=float).reshape(-1)
    if x_arr.ndim == 1:
        x_arr = x_arr[:, None]
    if x_arr.shape[0] != y_arr.shape[0]:
        raise ValueError("x and y must have same row count")

    if offset is None:
        offset_arr = np.zeros_like(y_arr)
    else:
        offset_arr = np.asarray(offset, dtype=float).reshape(-1)
        if offset_arr.shape[0] != y_arr.shape[0]:
            raise ValueError("offset size mismatch")

    n_samples, n_features = x_arr.shape
    x_aug = np.column_stack([np.ones(n_samples), x_arr])
    beta = np.zeros(n_features + 1, dtype=float)

    eye = np.eye(n_features + 1)
    eye[0, 0] = 0.0

    converged = False
    n_iter = 0
    for n_iter in range(1, max_iter + 1):
        eta = x_aug @ beta + offset_arr
        lam = np.exp(np.clip(eta, -20.0, 20.0))

        grad = x_aug.T @ (y_arr - lam) - l2 * (eye @ beta)
        hess_pos = x_aug.T @ (lam[:, None] * x_aug) + l2 * eye
        try:
            step = np.linalg.solve(hess_pos, grad)
        except np.linalg.LinAlgError:
            step = np.linalg.lstsq(hess_pos, grad, rcond=None)[0]

        beta_next = beta + step
        if np.linalg.norm(beta_next - beta, ord=2) < tol:
            beta = beta_next
            converged = True
            break
        beta = beta_next

    eta = x_aug @ beta + offset_arr
    lam = np.exp(np.clip(eta, -20.0, 20.0))
    log_likelihood = float(np.sum(y_arr * np.log(np.maximum(lam, 1e-12)) - lam))

    return PoissonGLMResult(
        intercept=float(beta[0]),
        coefficients=beta[1:].copy(),
        n_iter=n_iter,
        converged=converged,
        log_likelihood=log_likelihood,
    )
