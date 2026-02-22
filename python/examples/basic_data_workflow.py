from __future__ import annotations

from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from nstat import Covariate, psth, simulate_cif_from_stimulus  # noqa: E402


def main() -> None:
    rng = np.random.default_rng(42)
    t = np.arange(0.0, 20.0, 0.001)
    stim = np.sin(2.0 * np.pi * 2.0 * t)

    stimulus = Covariate(time=t, values=stim, name="sin_2hz", units="a.u.")
    spike_train, rate_hz, _ = simulate_cif_from_stimulus(
        time=stimulus.time, stimulus=stimulus.values, beta0=-1.7, beta1=0.9, rng=rng
    )

    edges = np.arange(0.0, 20.0 + 0.25, 0.25)
    mean_rate_hz, counts = psth([spike_train], edges)

    print("Example: basic_data_workflow")
    print(f"Duration (s): {spike_train.duration:.3f}")
    print(f"Spikes: {spike_train.n_spikes}")
    print(f"Mean simulated rate (Hz): {rate_hz.mean():.3f}")
    print(f"PSTH bins: {counts.shape[1]}")
    print(f"PSTH first 5 rates (Hz): {np.round(mean_rate_hz[:5], 3)}")


if __name__ == "__main__":
    main()
