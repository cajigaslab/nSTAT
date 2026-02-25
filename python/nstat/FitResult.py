from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .fit import FitResult as _FitResult


class FitResult(_FitResult):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.FitResult.FitResult", "nstat.fit.FitResult")
        super().__init__(*args, **kwargs)


__all__ = ["FitResult"]
