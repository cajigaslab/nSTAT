from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .confidence_interval import ConfidenceInterval as _ConfidenceInterval


class ConfidenceInterval(_ConfidenceInterval):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.ConfidenceInterval.ConfidenceInterval", "nstat.confidence_interval.ConfidenceInterval")
        super().__init__(*args, **kwargs)


__all__ = ["ConfidenceInterval"]
