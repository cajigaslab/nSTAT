from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .spikes import SpikeTrainCollection


class nstColl(SpikeTrainCollection):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.nstColl.nstColl", "nstat.spikes.SpikeTrainCollection")
        super().__init__(*args, **kwargs)


__all__ = ["nstColl"]
