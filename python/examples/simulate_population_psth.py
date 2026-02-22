from __future__ import annotations

from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from nstat import psth, simulate_cif_from_stimulus  # noqa: E402


def main() -> None:
    rng = np.random.default_rng(7)
    t = np.arange(0.0, 20.0, 0.001)
    stim = np.sin(2.0 * np.pi * 1.5 * t)

    trials = []
    n_trials = 20
    for _ in range(n_trials):
        spikes, _, _ = simulate_cif_from_stimulus(
            time=t, stimulus=stim, beta0=-2.0, beta1=1.1, rng=rng
        )
        trials.append(spikes)

    edges = np.arange(0.0, 20.0 + 0.1, 0.1)
    mean_rate_hz, counts = psth(trials, edges)

    print("Example: simulate_population_psth")
    print(f"Trials: {n_trials}")
    print(f"Total spikes: {int(counts.sum())}")
    print(f"Average rate over all bins (Hz): {mean_rate_hz.mean():.3f}")
    print(f"Peak bin rate (Hz): {mean_rate_hz.max():.3f}")


if __name__ == "__main__":
    main()
