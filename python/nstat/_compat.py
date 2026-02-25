from __future__ import annotations

import warnings


def warn_deprecated_adapter(old: str, new: str) -> None:
    warnings.warn(
        f"{old} is deprecated and will be removed in a future major release; use {new} instead.",
        DeprecationWarning,
        stacklevel=3,
    )
