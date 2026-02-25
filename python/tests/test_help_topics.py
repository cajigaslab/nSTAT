from __future__ import annotations

import os

import pytest

from examples.help_topics._common import run_topic

TOPICS = [
    "SignalObjExamples",
    "CovariateExamples",
    "CovCollExamples",
    "nSpikeTrainExamples",
    "nstCollExamples",
    "EventsExamples",
    "HistoryExamples",
    "TrialExamples",
    "TrialConfigExamples",
    "ConfigCollExamples",
    "AnalysisExamples",
    "FitResultExamples",
    "FitResSummaryExamples",
    "PPThinning",
    "PSTHEstimation",
    "ValidationDataSet",
    "mEPSCAnalysis",
    "PPSimExample",
    "ExplicitStimulusWhiskerData",
    "HippocampalPlaceCellExample",
    "DecodingExample",
    "DecodingExampleWithHist",
    "StimulusDecode2D",
    "NetworkTutorial",
    "nSTATPaperExamples",
]


def test_help_topics_all_run(repo_root) -> None:
    if os.environ.get("NSTAT_CI_LIGHT") == "1":
        pytest.skip("Help-topic execution already validated in dedicated CI workflow step")
    for topic in TOPICS:
        out = run_topic(topic, repo_root)
        assert isinstance(out, dict)
        assert out.get("topic") == topic
