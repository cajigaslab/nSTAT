"""Auto-generated MATLAB-to-Python scaffold.

Source: helpfiles/nSTATPaperExamples.m
"""

from __future__ import annotations

from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat

import json
import sys

THIS_FILE = Path(__file__).resolve()
PY_ROOT = THIS_FILE.parents[2]
if str(PY_ROOT) not in sys.path:
    sys.path.insert(0, str(PY_ROOT))

from nstat.paper_examples_full import run_full_paper_examples

def run(*, repo_root: str | Path | None = None) -> dict[str, dict[str, float]]:
    root = Path(repo_root).resolve() if repo_root is not None else THIS_FILE.parents[3]
    return run_full_paper_examples(root)

def main() -> int:
    print(json.dumps(run(), indent=2))
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
