from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import numpy as np

from nstat import (
    Analysis,
    CIFModel,
    ConfigCollection,
    Covariate,
    CovariateCollection,
    DecoderSuite,
    HistoryBasis,
    Signal,
    SpikeTrain,
    SpikeTrainCollection,
    Trial,
    TrialConfig,
    run_full_paper_examples,
    simulate_two_neuron_network,
)
from nstat.paper_examples_full import (
    run_experiment1,
    run_experiment2,
    run_experiment3,
    run_experiment4,
    run_experiment5,
    run_experiment5b,
    run_experiment6,
)


def _resolve_repo_root(repo_root: Path | str | None) -> Path:
    if repo_root is None:
        return Path(__file__).resolve().parents[3]
    return Path(repo_root).resolve()


def _result(topic: str, payload: dict[str, Any], parity: dict[str, float] | None = None) -> dict[str, Any]:
    out = {"topic": topic, **payload}
    if parity:
        out["parity"] = {k: float(v) for k, v in parity.items()}
    return out


def _toy_trial() -> tuple[Trial, ConfigCollection]:
    time = np.arange(0.0, 2.0, 0.001)
    stim = np.sin(2.0 * np.pi * 2.0 * time)
    cov = Covariate(time, stim, "stim", "time", "s", "a.u.", ["stim"])

    base_rate = 10.0 + 5.0 * np.maximum(stim, 0.0)
    model = CIFModel(time=time, rate_hz=base_rate, name="lambda")
    coll = model.simulate(num_realizations=3, seed=3)

    trial = Trial(spike_collection=coll, covariate_collection=CovariateCollection([cov]))
    cfg = TrialConfig(covMask=["stim"], sampleRate=1000.0, name="stimulus_only")
    cfgs = ConfigCollection([cfg])
    return trial, cfgs


def run_topic(topic: str, repo_root: Path | str | None = None) -> dict[str, Any]:
    root = _resolve_repo_root(repo_root)
    data_dir = root / "data"

    if topic == "SignalObjExamples":
        sample_rate_hz = 5000.0
        dt = 1.0 / sample_rate_hz
        t = np.arange(0.0, 1.0 + dt * 0.5, dt)
        sig = Signal(t, np.column_stack([np.sin(2 * np.pi * t), np.cos(2 * np.pi * t)]), name="demo")
        return _result(
            topic,
            {"dimension": sig.dimension, "sample_rate": sig.sample_rate},
            parity={"sample_rate_hz": sig.sample_rate},
        )

    if topic == "CovariateExamples":
        t = np.linspace(0.0, 1.0, 100)
        cov = Covariate.from_values(t, np.sin(2 * np.pi * t), name="stim", units="a.u.")
        cov_z = cov.standardize()
        return {"topic": topic, "mean": float(np.mean(cov_z.data)), "std": float(np.std(cov_z.data))}

    if topic == "CovCollExamples":
        trial, _ = _toy_trial()
        _, x, labels = trial.get_covariate_matrix()
        return {"topic": topic, "matrix_shape": list(x.shape), "labels": labels}

    if topic == "nSpikeTrainExamples":
        st = SpikeTrain(np.array([0.1, 0.12, 0.25, 0.4]), binwidth=0.01)
        return {"topic": topic, "n_spikes": st.n_spikes, "rate_hz": st.firing_rate_hz}

    if topic == "nstCollExamples":
        trial, _ = _toy_trial()
        coll = trial.spike_collection
        psth = coll.psth(0.05)
        return {"topic": topic, "num_trains": coll.num_spike_trains, "psth_points": int(psth.time.shape[0])}

    if topic == "EventsExamples":
        from nstat.events import Events

        ev = Events([0.2, 0.9, 1.4], labels=["start", "cue", "reward"])
        return {"topic": topic, "n_events": int(ev.event_times.shape[0])}

    if topic == "HistoryExamples":
        basis = HistoryBasis([1, 2, 5, 10])
        y = np.random.default_rng(0).poisson(0.1, size=500)
        x = basis.design_matrix(y)
        return {"topic": topic, "lags": basis.lags.tolist(), "design_shape": list(x.shape)}

    if topic == "TrialExamples":
        trial, _ = _toy_trial()
        _, x, _ = trial.get_covariate_matrix()
        return {"topic": topic, "covariate_rows": int(x.shape[0]), "neurons": trial.spike_collection.num_spike_trains}

    if topic == "TrialConfigExamples":
        cfg = TrialConfig(covMask=[["stim", "hist"]], sampleRate=1000.0, name="demo_cfg")
        return {"topic": topic, "covariates": cfg.covariate_names, "sample_rate": cfg.sampleRate}

    if topic == "ConfigCollExamples":
        c1 = TrialConfig(covMask=["stim"], sampleRate=1000.0, name="cfg1")
        c2 = TrialConfig(covMask=["stim", "hist"], sampleRate=1000.0, name="cfg2")
        coll = ConfigCollection([c1, c2])
        return {"topic": topic, "num_configs": coll.numConfigs, "names": coll.getConfigNames()}

    if topic == "AnalysisExamples":
        trial, cfgs = _toy_trial()
        out = Analysis.run_analysis_for_all_neurons(trial, cfgs)
        return {"topic": topic, "num_results": len(out), "first_aic": float(out[0].AIC[0])}

    if topic == "FitResultExamples":
        trial, cfgs = _toy_trial()
        fit = Analysis.run_analysis_for_neuron(trial, 0, cfgs)
        return {"topic": topic, "coeffs": fit.getCoeffs().tolist(), "bic": float(fit.BIC[0])}

    if topic == "FitResSummaryExamples":
        trial, cfgs = _toy_trial()
        fits = Analysis.run_analysis_for_all_neurons(trial, cfgs)
        from nstat.fit import FitSummary

        summary = FitSummary(fits)
        return {"topic": topic, "mean_aic": summary.AIC.tolist(), "mean_bic": summary.BIC.tolist()}

    if topic == "PPThinning":
        t = np.arange(0.0, 1.0, 0.001)
        rate = 20.0 + 15.0 * np.sin(2 * np.pi * 3 * t) ** 2
        model = CIFModel(t, rate)
        spikes = model.simulate(num_realizations=20, seed=1)
        return _result(
            topic,
            {"num_realizations": spikes.num_spike_trains},
            parity={"num_realizations": spikes.num_spike_trains},
        )

    if topic == "PSTHEstimation":
        delta = 0.001
        tmax = 10.0
        time = np.arange(0.0, tmax + delta, delta)
        rate_hz = 10.0 * np.sin(2.0 * np.pi * 0.2 * time) + 10.0
        coll = CIFModel(time, rate_hz, name="lambda").simulate(num_realizations=20, seed=17)
        psth = coll.psth(0.5)
        peak = float(np.max(psth.data[:, 0]))
        return _result(
            topic,
            {"peak_rate": peak, "num_realizations": coll.num_spike_trains},
            parity={"num_realizations": coll.num_spike_trains},
        )

    if topic == "ValidationDataSet":
        summary = run_experiment3(seed=7)
        return {"topic": topic, **summary}

    if topic == "mEPSCAnalysis":
        summary = run_experiment1(data_dir)
        return {"topic": topic, **summary}

    if topic == "PPSimExample":
        summary = run_experiment2(data_dir)
        return {"topic": topic, **summary}

    if topic == "ExplicitStimulusWhiskerData":
        summary = run_experiment2(data_dir)
        return {"topic": topic, **summary}

    if topic == "HippocampalPlaceCellExample":
        summary = run_experiment4(data_dir)
        return {"topic": topic, **summary}

    if topic == "DecodingExample":
        summary = run_experiment5(seed=11)
        return _result(topic, summary, parity={"num_cells": summary["num_cells"]})

    if topic == "DecodingExampleWithHist":
        summary = run_experiment5b(seed=19)
        return _result(topic, summary, parity={"num_cells": summary["num_cells"]})

    if topic == "StimulusDecode2D":
        summary = run_experiment5b(seed=23, n_cells=80)
        return _result(
            topic,
            summary,
            parity={
                "num_cells": summary["num_cells"],
                "decode_rmse_x": summary["decode_rmse_x"],
                "decode_rmse_y": summary["decode_rmse_y"],
            },
        )

    if topic == "NetworkTutorial":
        sim = simulate_two_neuron_network(duration_s=2.0, dt=0.001, seed=13)
        psth = sim.spikes.psth(0.05)
        return {
            "topic": topic,
            "samples": int(sim.time.shape[0]),
            "neuron_count": sim.spikes.num_spike_trains,
            "psth_peak": float(np.max(psth.data[:, 0])),
        }

    if topic == "nSTATPaperExamples":
        # Keep this help-topic notebook fast and deterministic in CI by running
        # a representative subset of paper experiments.
        summary = {
            "experiment2": run_experiment2(data_dir),
            "experiment3": run_experiment3(seed=7),
            "experiment5": run_experiment5(seed=11, n_cells=40),
        }
        return _result(
            topic,
            {"experiments": sorted(summary.keys()), "summary": summary},
            parity={
                "num_cells": summary["experiment5"]["num_cells"],
                "decode_rmse": summary["experiment5"]["decode_rmse"],
            },
        )

    raise KeyError(f"Unknown help topic: {topic}")


def main(topic: str, repo_root: Path | str | None = None) -> int:
    out = run_topic(topic, repo_root)
    print(json.dumps(out, indent=2, default=str))
    return 0
