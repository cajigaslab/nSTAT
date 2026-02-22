"""Python nSTAT package.

This directory mirrors MATLAB nSTAT core files with Python implementations.
"""

from .analysis import Analysis, psth, spike_indicator
from .cif import CIF
from .confidence_interval import ConfidenceInterval
from .core import Covariate, SignalObj, SpikeTrain, nspikeTrain
from .decoding_algorithms import DecodingAlgorithms
from .events import Events
from .fit import FitResSummary, FitResult
from .glm import PoissonGLMResult, fit_poisson_glm
from .history import History
from .nstat_install import nSTAT_Install
from .simulation import simulate_cif_from_stimulus, simulate_poisson_from_rate
from .trial import ConfigColl, CovColl, Trial, TrialConfig, nstColl

__all__ = [
    "Analysis",
    "CIF",
    "ConfidenceInterval",
    "ConfigColl",
    "CovColl",
    "Covariate",
    "DecodingAlgorithms",
    "Events",
    "FitResSummary",
    "FitResult",
    "History",
    "PoissonGLMResult",
    "SignalObj",
    "SpikeTrain",
    "Trial",
    "TrialConfig",
    "fit_poisson_glm",
    "nSTAT_Install",
    "nstColl",
    "nspikeTrain",
    "psth",
    "simulate_cif_from_stimulus",
    "simulate_poisson_from_rate",
    "spike_indicator",
]
