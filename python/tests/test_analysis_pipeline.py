from __future__ import annotations

import numpy as np

from nstat import Analysis, CIFModel, ConfigCollection, Covariate, CovariateCollection, FitSummary, Trial, TrialConfig


def test_trial_analysis_pipeline() -> None:
    t = np.arange(0.0, 1.0, 0.001)
    stim = np.sin(2 * np.pi * 2 * t)
    cov = Covariate(t, stim, "stim", "time", "s", "a.u.", ["stim"])

    model = CIFModel(t, 10.0 + 5.0 * np.maximum(stim, 0.0), name="lambda")
    spikes = model.simulate(num_realizations=3, seed=2)

    trial = Trial(spike_collection=spikes, covariate_collection=CovariateCollection([cov]))
    cfgs = ConfigCollection([TrialConfig(covMask=["stim"], sampleRate=1000.0, name="stim_model")])

    fits = Analysis.run_analysis_for_all_neurons(trial, cfgs)
    assert len(fits) == 3
    assert fits[0].AIC.shape == (1,)

    summary = FitSummary(fits)
    assert summary.numNeurons == 3
    assert summary.AIC.shape == (1,)
