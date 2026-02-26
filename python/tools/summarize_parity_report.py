from __future__ import annotations

import argparse
import json
import statistics
from collections import Counter
from pathlib import Path
from typing import Any


def _classify_failure(err: str) -> str:
    e = (err or "").strip()
    if not e:
        return "unknown"
    if e == "matlab_timeout":
        return "timeout"
    if "libmwhandle_graphics" in e or "MATLAB is exiting because of fatal error" in e:
        return "graphics_crash"
    if "matlab_json_missing" in e:
        return "json_missing"
    return "other_error"


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Summarize nSTAT MATLAB/Python parity report runtime and failures.")
    parser.add_argument("report", help="Path to python_vs_matlab_similarity_report.json style file.")
    parser.add_argument("--top", type=int, default=10, help="Number of slowest topics to print.")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable summary JSON.")
    return parser.parse_args(argv)


def _load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _summarize_rows(rows: list[dict[str, Any]], top: int) -> dict[str, Any]:
    runtimes = [float(r.get("matlab_runtime_s") or 0.0) for r in rows]
    failures = [r for r in rows if not bool(r.get("matlab_ok"))]
    failure_types = Counter(_classify_failure(str(r.get("matlab_error", ""))) for r in failures)
    sorted_rows = sorted(rows, key=lambda r: float(r.get("matlab_runtime_s") or 0.0), reverse=True)
    slowest = [
        {
            "topic": str(r.get("topic", "")),
            "runtime_s": float(r.get("matlab_runtime_s") or 0.0),
            "timeout_s": int(r.get("matlab_timeout_s") or 0),
            "matlab_ok": bool(r.get("matlab_ok")),
            "matlab_error": str(r.get("matlab_error", "")),
        }
        for r in sorted_rows[: max(1, top)]
    ]
    near_timeout = []
    for r in rows:
        timeout_s = int(r.get("matlab_timeout_s") or 0)
        runtime_s = float(r.get("matlab_runtime_s") or 0.0)
        if timeout_s > 0 and runtime_s / timeout_s >= 0.8:
            near_timeout.append(
                {
                    "topic": str(r.get("topic", "")),
                    "runtime_s": runtime_s,
                    "timeout_s": timeout_s,
                    "pct_timeout": round((runtime_s / timeout_s) * 100.0, 2),
                    "matlab_error": str(r.get("matlab_error", "")),
                }
            )
    near_timeout.sort(key=lambda x: float(x["pct_timeout"]), reverse=True)
    p50 = statistics.median(runtimes) if runtimes else 0.0
    p90 = sorted(runtimes)[int(0.9 * (len(runtimes) - 1))] if runtimes else 0.0
    return {
        "topic_count": len(rows),
        "matlab_failures": len(failures),
        "failure_types": dict(failure_types),
        "runtime_s": {
            "sum": round(sum(runtimes), 3),
            "p50": round(float(p50), 3),
            "p90": round(float(p90), 3),
            "max": round(max(runtimes) if runtimes else 0.0, 3),
        },
        "slowest_topics": slowest,
        "near_timeout_topics": near_timeout,
    }


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    path = Path(args.report).expanduser().resolve()
    payload = _load(path)

    if "helpfile_similarity" not in payload:
        raise SystemExit(f"Unsupported report schema: {path}")

    summary = payload.get("helpfile_similarity", {}).get("summary", {})
    rows = payload.get("helpfile_similarity", {}).get("rows", [])
    details = _summarize_rows(rows, top=args.top)
    out = {
        "report_path": str(path),
        "help_summary": summary,
        "details": details,
    }

    if args.json:
        print(json.dumps(out, indent=2))
        return 0

    print(f"report: {path}")
    print(f"help summary: {summary}")
    print(
        "runtime seconds: "
        f"sum={details['runtime_s']['sum']} p50={details['runtime_s']['p50']} "
        f"p90={details['runtime_s']['p90']} max={details['runtime_s']['max']}"
    )
    print(f"matlab failures: {details['matlab_failures']} ({details['failure_types']})")

    print("slowest topics:")
    for row in details["slowest_topics"]:
        print(
            f"  - {row['topic']}: runtime={row['runtime_s']:.2f}s "
            f"timeout={row['timeout_s']} ok={row['matlab_ok']}"
        )

    if details["near_timeout_topics"]:
        print("near-timeout topics (>=80% of timeout):")
        for row in details["near_timeout_topics"]:
            print(
                f"  - {row['topic']}: {row['runtime_s']:.2f}/{row['timeout_s']}s "
                f"({row['pct_timeout']:.1f}%)"
            )
    else:
        print("near-timeout topics (>=80% of timeout): none")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
