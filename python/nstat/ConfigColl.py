from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .trial import ConfigCollection


class ConfigColl(ConfigCollection):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.ConfigColl.ConfigColl", "nstat.trial.ConfigCollection")
        super().__init__(*args, **kwargs)


__all__ = ["ConfigColl"]
