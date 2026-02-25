from __future__ import annotations

import argparse

from ._common import main as _main


def run(repo_root=None):
    from ._common import run_topic

    return run_topic("CovCollExamples", repo_root)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run CovCollExamples Python help-topic workflow")
    parser.add_argument("--repo-root", default=None)
    args = parser.parse_args()
    return _main("CovCollExamples", args.repo_root)


if __name__ == "__main__":
    raise SystemExit(main())
