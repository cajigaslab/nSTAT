from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .fit import FitResSummary as _FitResSummary


class FitResSummary(_FitResSummary):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.FitResSummary.FitResSummary", "nstat.fit.FitSummary")
        super().__init__(*args, **kwargs)


__all__ = ["FitResSummary"]
