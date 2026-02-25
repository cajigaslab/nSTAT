from __future__ import annotations

import warnings

import nstat


def test_canonical_api_imports() -> None:
    assert nstat.Signal is not None
    assert nstat.SpikeTrain is not None
    assert nstat.SpikeTrainCollection is not None
    assert nstat.Trial is not None
    assert nstat.Analysis is not None
    assert nstat.FitResult is not None
    assert nstat.FitSummary is not None
    assert nstat.CIFModel is not None
    assert nstat.DecoderSuite is not None


def test_compatibility_adapters_emit_deprecation() -> None:
    with warnings.catch_warnings(record=True) as w:
        warnings.simplefilter("always")
        from nstat.SignalObj import SignalObj

        _ = SignalObj([0.0, 1.0], [1.0, 2.0])
        assert any("deprecated" in str(item.message).lower() for item in w)
