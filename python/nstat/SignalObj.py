from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .signal import Signal


class SignalObj(Signal):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.SignalObj.SignalObj", "nstat.signal.Signal")
        super().__init__(*args, **kwargs)


__all__ = ["SignalObj"]
