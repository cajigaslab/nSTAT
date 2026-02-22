from __future__ import annotations

from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from nstat import fit_poisson_glm, simulate_cif_from_stimulus  # noqa: E402


def main() -> None:
    rng = np.random.default_rng(123)
    t = np.arange(0.0, 60.0, 0.001)
    stim = np.sin(2.0 * np.pi * 1.0 * t)

    true_beta0 = -2.4
    true_beta1 = 0.9
    spikes, _, _ = simulate_cif_from_stimulus(
        time=t, stimulus=stim, beta0=true_beta0, beta1=true_beta1, rng=rng
    )
    bin_width = 0.01
    edges = np.arange(0.0, 60.0 + bin_width, bin_width)
    y = spikes.to_binned_counts(edges)

    samples_per_bin = int(round(bin_width / (t[1] - t[0])))
    x = stim.reshape(-1, samples_per_bin).mean(axis=1)[:, None]
    offset = np.full(y.shape, np.log(bin_width))

    fit = fit_poisson_glm(x, y, offset=offset, l2=1e-4, max_iter=80, tol=1e-9)

    print("Example: fit_poisson_glm")
    print(f"True intercept:      {true_beta0:.4f}")
    print(f"Estimated intercept: {fit.intercept:.4f}")
    print(f"True stim beta:      {true_beta1:.4f}")
    print(f"Estimated stim beta: {fit.coefficients[0]:.4f}")
    print(f"Converged: {fit.converged} in {fit.n_iter} iterations")
    print(f"Log-likelihood: {fit.log_likelihood:.4f}")


if __name__ == "__main__":
    main()
