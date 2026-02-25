from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .signal import Covariate as _Covariate


class Covariate(_Covariate):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.Covariate.Covariate", "nstat.signal.Covariate")
        super().__init__(*args, **kwargs)


__all__ = ["Covariate"]
