from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .spikes import SpikeTrain


class nspikeTrain(SpikeTrain):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.nspikeTrain.nspikeTrain", "nstat.spikes.SpikeTrain")
        super().__init__(*args, **kwargs)


__all__ = ["nspikeTrain"]
