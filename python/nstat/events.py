from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np


@dataclass
class Events:
    event_times: np.ndarray
    labels: list[str] | None = None

    def __init__(self, event_times, labels=None) -> None:
        self.event_times = np.asarray(event_times, dtype=float).reshape(-1)
        self.labels = None if labels is None else list(labels)

    def toStructure(self) -> dict[str, Any]:
        return {
            "event_times": self.event_times.tolist(),
            "labels": list(self.labels) if self.labels is not None else None,
        }

    @staticmethod
    def fromStructure(structure: dict[str, Any]) -> "Events":
        return Events(structure.get("event_times", []), labels=structure.get("labels"))

    def plot(self, *_, **__) -> None:
        return None


__all__ = ["Events"]
