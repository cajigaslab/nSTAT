from __future__ import annotations


class NSTATError(Exception):
    """Base exception type for the Python nSTAT package."""


class DataNotFoundError(NSTATError, FileNotFoundError):
    """Raised when a required dataset is missing from the local checkout."""


class ParityValidationError(NSTATError):
    """Raised when MATLAB/Python parity validation fails."""


class UnsupportedWorkflowError(NSTATError, NotImplementedError):
    """Raised when a legacy workflow has not yet been ported."""
