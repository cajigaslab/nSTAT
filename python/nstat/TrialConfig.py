from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .trial import TrialConfig as _TrialConfig


class TrialConfig(_TrialConfig):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.TrialConfig.TrialConfig", "nstat.trial.TrialConfig")
        super().__init__(*args, **kwargs)


__all__ = ["TrialConfig"]
