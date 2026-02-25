from __future__ import annotations

from ._compat import warn_deprecated_adapter
from .decoding_algorithms import DecodingAlgorithms as _DecodingAlgorithms


class DecodingAlgorithms(_DecodingAlgorithms):
    def __init__(self, *args, **kwargs) -> None:
        warn_deprecated_adapter("nstat.DecodingAlgorithms.DecodingAlgorithms", "nstat.decoding.DecoderSuite")
        super().__init__(*args, **kwargs)


__all__ = ["DecodingAlgorithms"]
