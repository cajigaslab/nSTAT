from __future__ import annotations

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
    for topic in TOPICS:
        out = run_topic(topic, repo_root)
        assert isinstance(out, dict)
        assert out.get("topic") == topic
