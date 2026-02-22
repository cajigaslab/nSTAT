from __future__ import annotations

from dataclasses import dataclass

import numpy as np


@dataclass
class Events:
    event_times: np.ndarray
    labels: list[str] | None = None

    def __init__(self, event_times, labels=None) -> None:
        self.event_times = np.asarray(event_times, dtype=float).reshape(-1)
        self.labels = None if labels is None else list(labels)

    def plot(self, *_, **__) -> None:
        return None
