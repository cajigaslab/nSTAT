from __future__ import annotations

import sys
from pathlib import Path

# Ensure local package import works when run directly.
THIS_DIR = Path(__file__).resolve().parent
PKG_ROOT = THIS_DIR.parent
if str(PKG_ROOT) not in sys.path:
    sys.path.insert(0, str(PKG_ROOT))

from nstat.paper_examples import main


if __name__ == "__main__":
    raise SystemExit(main())
