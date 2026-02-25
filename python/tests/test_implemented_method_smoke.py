from __future__ import annotations

import json
from pathlib import Path

import numpy as np

from nstat import Analysis, CIFModel, ConfigCollection, Covariate, CovariateCollection, SpikeTrain, SpikeTrainCollection, Trial, TrialConfig
from nstat.DecodingAlgorithms import DecodingAlgorithms
from nstat.ConfidenceInterval import ConfidenceInterval
from nstat.cif import CIF
from nstat.events import Events
from nstat.fit import FitResSummary, FitResult
from nstat.history import History
from nstat.trial import CovColl


COVERED_IMPLEMENTED_METHODS = {
    ("nstColl", "dataToMatrix"),
    ("CovColl", "addToColl"),
    ("CovColl", "dataToMatrix"),
    ("CovColl", "getCov"),
    ("TrialConfig", "setName"),
    ("ConfigColl", "addConfig"),
    ("ConfigColl", "getConfig"),
    ("ConfigColl", "getConfigNames"),
    ("Trial", "getSpikeVector"),
    ("History", "computeHistory"),
    ("Events", "fromStructure"),
    ("Events", "plot"),
    ("Events", "toStructure"),
    ("ConfidenceInterval", "setColor"),
    ("CIF", "simulateCIFByThinningFromLambda"),
    ("FitResult", "KSPlot"),
    ("FitResult", "fromStructure"),
    ("FitResult", "getCoeffs"),
    ("FitResult", "getHistCoeffs"),
    ("FitResult", "mergeResults"),
    ("FitResult", "plotCoeffs"),
    ("FitResult", "plotInvGausTrans"),
    ("FitResult", "plotResidual"),
    ("FitResult", "plotResults"),
    ("FitResult", "plotSeqCorr"),
    ("FitResult", "toStructure"),
    ("FitResSummary", "getDiffAIC"),
    ("FitResSummary", "getDiffBIC"),
    ("FitResSummary", "plotSummary"),
    ("Analysis", "RunAnalysisForAllNeurons"),
    ("Analysis", "RunAnalysisForNeuron"),
    ("DecodingAlgorithms", "PPDecodeFilter"),
    ("DecodingAlgorithms", "PPDecodeFilterLinear"),
    ("DecodingAlgorithms", "kalman_filter"),
}


def _build_trial_and_fits() -> tuple[Trial, ConfigCollection, list[FitResult]]:
    t = np.arange(0.0, 1.0, 0.01)
    cov = Covariate(t, np.sin(2.0 * np.pi * t), "stim", "time", "s", "a.u.", ["stim"])
    cov_coll = CovariateCollection([cov])

    st1 = SpikeTrain(np.array([0.1, 0.2, 0.5]), name="n1", binwidth=0.01, minTime=0.0, maxTime=1.0)
    st2 = SpikeTrain(np.array([0.15, 0.35, 0.75]), name="n2", binwidth=0.01, minTime=0.0, maxTime=1.0)
    spikes = SpikeTrainCollection([st1, st2])
    trial = Trial(spike_collection=spikes, covariate_collection=cov_coll)

    cfg = TrialConfig(covMask=["stim"], sampleRate=100.0, name="cfg1")
    cfgs = ConfigCollection([cfg])
    fits = Analysis.run_analysis_for_all_neurons(trial, cfgs)
    return trial, cfgs, fits


def _implemented_from_matrix(repo_root: Path) -> set[tuple[str, str]]:
    matrix_path = repo_root / "python" / "reports" / "method_parity_matrix.json"
    payload = json.loads(matrix_path.read_text(encoding="utf-8"))
    out: set[tuple[str, str]] = set()
    for cls in payload.get("classes", []):
        matlab_class = str(cls.get("matlab_class", ""))
        for row in cls.get("methods", []):
            if row.get("status") == "implemented":
                out.add((matlab_class, str(row.get("matlab_method", ""))))
    return out


def test_implemented_method_set_matches_matrix(repo_root) -> None:
    implemented = _implemented_from_matrix(repo_root)
    assert implemented == COVERED_IMPLEMENTED_METHODS


def test_implemented_methods_smoke_execute() -> None:
    trial, cfgs, fits = _build_trial_and_fits()

    # nstColl / Trial / CovColl / TrialConfig / ConfigColl / History
    edges = np.linspace(0.0, 1.0, 11)
    _ = trial.spike_collection.dataToMatrix(edges)
    cov_coll = CovColl()
    cov = Covariate(np.linspace(0.0, 1.0, 11), np.linspace(0.0, 1.0, 11), "c1", "time", "s", "a.u.", ["c1"])
    cov_coll.addToColl(cov)
    _, x, _ = cov_coll.dataToMatrix()
    assert x.shape[0] == 11
    assert cov_coll.getCov("c1").name == "c1"

    cfg = TrialConfig(covMask=["stim"], sampleRate=100.0)
    cfg.setName("renamed")
    assert cfg.name == "renamed"

    cfg_coll = ConfigCollection([])
    cfg_coll.addConfig(cfg)
    assert cfg_coll.getConfig(1).name == "renamed"
    assert cfg_coll.getConfigNames() == ["renamed"]
    _ = trial.getSpikeVector(edges, neuron_index=1)

    hist = History([1, 2])
    hist_cov = hist.computeHistory(trial.spike_collection.getNST(1))
    assert hist_cov.dimension == 2

    # Events / ConfidenceInterval
    ev = Events([0.1, 0.2], labels=["a", "b"])
    ev_struct = ev.toStructure()
    ev2 = Events.fromStructure(ev_struct)
    ev2.plot()
    assert ev2.labels == ["a", "b"]

    ci = ConfidenceInterval([0.0, 1.0], [[0.1, 0.2], [0.2, 0.3]])
    ci.setColor("g")
    assert ci.color == "g"

    # CIF
    lam = Covariate(np.linspace(0.0, 1.0, 101), np.full(101, 5.0), "lam", "time", "s", "Hz", ["lam"])
    sim = CIF.simulateCIFByThinningFromLambda(lam, numRealizations=2)
    assert sim.numSpikeTrains == 2

    # FitResult + FitResSummary + Analysis MATLAB aliases
    fit = fits[0]
    _ = fit.getCoeffs()
    _ = fit.getHistCoeffs()
    fit.plotResults()
    fit.KSPlot()
    fit.plotResidual()
    fit.plotInvGausTrans()
    fit.plotSeqCorr()
    fit.plotCoeffs()

    merged = fit.mergeResults(fit)
    assert merged.numResults == fit.numResults * 2

    struct_payload = fit.toStructure()
    fit_roundtrip = FitResult.fromStructure(struct_payload)
    assert fit_roundtrip.numResults == fit.numResults

    summary = FitResSummary(fits)
    _ = summary.getDiffAIC()
    _ = summary.getDiffBIC()
    summary.plotSummary()

    fit_single = Analysis.RunAnalysisForNeuron(trial, 1, cfgs)
    fit_all = Analysis.RunAnalysisForAllNeurons(trial, cfgs)
    assert fit_single.numResults >= 1
    assert len(fit_all) == trial.spike_collection.num_spike_trains

    # DecodingAlgorithms
    y = np.zeros((8, 1))
    a = np.eye(1)
    h = np.eye(1)
    q = np.eye(1) * 0.01
    r = np.eye(1) * 0.1
    x0 = np.zeros(1)
    p0 = np.eye(1)
    out0 = DecodingAlgorithms.kalman_filter(y, a, h, q, r, x0, p0)
    out1 = DecodingAlgorithms.PPDecodeFilter(y, a, h, q, r, x0, p0)
    out2 = DecodingAlgorithms.PPDecodeFilterLinear(y, a, h, q, r, x0, p0)
    assert out0["state"].shape == out1["state"].shape == out2["state"].shape
