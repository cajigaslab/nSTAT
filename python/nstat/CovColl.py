from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .trial import CovariateCollection


class CovColl(CovariateCollection):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.CovColl.CovColl", "nstat.trial.CovariateCollection")
        super().__init__(*args, **kwargs)


__all__ = ["CovColl"]
