from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from collections import Counter
from collections import deque
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
VERIFY_SCRIPT = REPO_ROOT / "python" / "tools" / "verify_python_vs_matlab_similarity.py"
REPORT_DIR = REPO_ROOT / "python" / "reports"
DEFAULT_OUTPUT = REPORT_DIR / "parity_block_benchmark_report.json"

BLOCKS: list[tuple[str, list[str]]] = [
    (
        "core_smoke",
        ["TrialConfigExamples", "ConfigCollExamples", "FitResultExamples", "FitResSummaryExamples"],
    ),
    (
        "timeout_front",
        [
            "SignalObjExamples",
            "CovariateExamples",
            "CovCollExamples",
            "nSpikeTrainExamples",
            "nstCollExamples",
            "EventsExamples",
            "HistoryExamples",
            "TrialExamples",
            "AnalysisExamples",
        ],
    ),
    (
        "graphics_mid",
        [
            "PPThinning",
            "PSTHEstimation",
            "ValidationDataSet",
            "mEPSCAnalysis",
            "PPSimExample",
            "ExplicitStimulusWhiskerData",
            "HippocampalPlaceCellExample",
            "DecodingExample",
        ],
    ),
    (
        "heavy_tail",
        ["DecodingExampleWithHist", "StimulusDecode2D", "NetworkTutorial", "nSTATPaperExamples"],
    ),
    ("full_suite", []),
]


def _classify_matlab_failure(err: str) -> str:
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
    parser = argparse.ArgumentParser(
        description="Run staged local parity blocks to isolate slow/failing MATLAB help topics."
    )
    parser.add_argument(
        "--blocks",
        nargs="+",
        default=[name for name, _ in BLOCKS],
        help="Block names to run. Defaults to all blocks.",
    )
    parser.add_argument(
        "--matlab-extra-args",
        default="-maca64 -nodisplay -noFigureWindows -softwareopengl",
        help="Value for NSTAT_MATLAB_EXTRA_ARGS.",
    )
    parser.add_argument(
        "--force-m-help-scripts",
        action="store_true",
        default=True,
        help="Set NSTAT_FORCE_M_HELP_SCRIPTS=1 (default on).",
    )
    parser.add_argument(
        "--no-force-m-help-scripts",
        action="store_true",
        help="Disable NSTAT_FORCE_M_HELP_SCRIPTS for this run.",
    )
    parser.add_argument(
        "--default-topic-timeout",
        type=int,
        default=120,
        help="Default per-topic timeout seconds passed to verify script.",
    )
    parser.add_argument(
        "--set-actions-runner-svc",
        action="store_true",
        help="Set ACTIONS_RUNNER_SVC=1 for closer parity with self-hosted runner service mode.",
    )
    parser.add_argument(
        "--output",
        default=str(DEFAULT_OUTPUT.relative_to(REPO_ROOT)),
        help="Output JSON report path (repo-relative or absolute).",
    )
    parser.add_argument(
        "--no-stream-verify-output",
        action="store_true",
        help="Disable passthrough of verify-script output while each block is running.",
    )
    return parser.parse_args(argv)


def _resolve_output(path_arg: str) -> Path:
    out = Path(path_arg)
    if not out.is_absolute():
        out = REPO_ROOT / out
    out.parent.mkdir(parents=True, exist_ok=True)
    return out


def _block_map() -> dict[str, list[str]]:
    return {name: topics for name, topics in BLOCKS}


def _run_block(
    block_name: str,
    topics: list[str],
    matlab_extra_args: str,
    force_m_help_scripts: bool,
    default_topic_timeout: int,
    set_actions_runner_svc: bool,
    stream_verify_output: bool,
) -> dict[str, Any]:
    block_report = REPORT_DIR / f"parity_block_{block_name}.json"
    cmd = [
        sys.executable,
        str(VERIFY_SCRIPT),
        "--default-topic-timeout",
        str(default_topic_timeout),
        "--report-path",
        str(block_report.relative_to(REPO_ROOT)),
    ]
    if topics:
        cmd.extend(["--topics", *topics])

    env = os.environ.copy()
    env["NSTAT_MATLAB_EXTRA_ARGS"] = matlab_extra_args
    env["NSTAT_FORCE_M_HELP_SCRIPTS"] = "1" if force_m_help_scripts else "0"
    if set_actions_runner_svc:
        env["ACTIONS_RUNNER_SVC"] = "1"

    t0 = time.time()
    stdout_tail = ""
    stderr_tail = ""
    if stream_verify_output:
        stream_tail: deque[str] = deque(maxlen=40)
        proc = subprocess.Popen(
            cmd,
            cwd=str(REPO_ROOT),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        if proc.stdout is not None:
            for line in proc.stdout:
                line = line.rstrip("\n")
                print(f"[verify:{block_name}] {line}", flush=True)
                stream_tail.append(line)
        return_code = int(proc.wait())
        stdout_tail = "\n".join(stream_tail)
    else:
        cp = subprocess.run(
            cmd,
            cwd=str(REPO_ROOT),
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        return_code = int(cp.returncode)
        stdout_tail = "\n".join((cp.stdout or "").splitlines()[-20:])
        stderr_tail = "\n".join((cp.stderr or "").splitlines()[-20:])
    wall_s = float(time.time() - t0)

    report_payload: dict[str, Any] | None = None
    if block_report.exists():
        report_payload = json.loads(block_report.read_text(encoding="utf-8"))

    result: dict[str, Any] = {
        "block": block_name,
        "topics_requested": topics,
        "command": cmd,
        "return_code": return_code,
        "wall_runtime_s": wall_s,
        "report_path": str(block_report.relative_to(REPO_ROOT)),
        "stdout_tail": stdout_tail,
        "stderr_tail": stderr_tail,
    }
    if report_payload is None:
        result["report_missing"] = True
        return result

    help_rows = report_payload.get("helpfile_similarity", {}).get("rows", [])
    failed = [r for r in help_rows if not bool(r.get("matlab_ok"))]
    failure_counter = Counter(_classify_matlab_failure(str(r.get("matlab_error", ""))) for r in failed)
    slowest = sorted(
        [
            {
                "topic": str(r.get("topic", "")),
                "runtime_s": float(r.get("matlab_runtime_s") or 0.0),
                "timeout_s": int(r.get("matlab_timeout_s") or 0),
                "matlab_ok": bool(r.get("matlab_ok")),
            }
            for r in help_rows
        ],
        key=lambda x: x["runtime_s"],
        reverse=True,
    )[:5]

    result["summary"] = {
        "class_similarity": report_payload.get("class_similarity", {}).get("summary", {}),
        "help_similarity": report_payload.get("helpfile_similarity", {}).get("summary", {}),
        "parity_contract_pass": bool(report_payload.get("parity_contract", {}).get("pass", False)),
        "regression_gate_pass": bool(report_payload.get("regression_gate", {}).get("pass", False)),
        "matlab_failure_types": dict(failure_counter),
        "matlab_failed_topics": [str(r.get("topic", "")) for r in failed],
        "slowest_topics": slowest,
    }
    return result


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    block_topics = _block_map()
    unknown = [b for b in args.blocks if b not in block_topics]
    if unknown:
        print(f"unknown block(s): {unknown}", file=sys.stderr)
        return 2
    if args.default_topic_timeout <= 0:
        print("--default-topic-timeout must be positive", file=sys.stderr)
        return 2

    force_m_help_scripts = bool(args.force_m_help_scripts and not args.no_force_m_help_scripts)
    out_path = _resolve_output(args.output)
    started = time.time()
    results: list[dict[str, Any]] = []

    for block_name in args.blocks:
        topics = block_topics[block_name]
        print(f"[block] {block_name} ({'all topics' if not topics else len(topics)})", flush=True)
        res = _run_block(
            block_name=block_name,
            topics=topics,
            matlab_extra_args=args.matlab_extra_args,
            force_m_help_scripts=force_m_help_scripts,
            default_topic_timeout=args.default_topic_timeout,
            set_actions_runner_svc=args.set_actions_runner_svc,
            stream_verify_output=not bool(args.no_stream_verify_output),
        )
        results.append(res)
        summary = res.get("summary", {})
        help_summary = summary.get("help_similarity", {})
        print(
            json.dumps(
                {
                    "block": block_name,
                    "return_code": res.get("return_code"),
                    "wall_runtime_s": round(float(res.get("wall_runtime_s", 0.0)), 3),
                    "help_matlab_ok": help_summary.get("matlab_ok"),
                    "help_total": help_summary.get("total_topics"),
                    "failure_types": summary.get("matlab_failure_types", {}),
                }
            ),
            flush=True,
        )

    payload = {
        "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "repo_root": str(REPO_ROOT),
        "matlab_extra_args": args.matlab_extra_args,
        "force_m_help_scripts": force_m_help_scripts,
        "default_topic_timeout": int(args.default_topic_timeout),
        "set_actions_runner_svc": bool(args.set_actions_runner_svc),
        "blocks_requested": args.blocks,
        "total_wall_runtime_s": float(time.time() - started),
        "results": results,
    }
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    try:
        out_print = str(out_path.relative_to(REPO_ROOT))
    except ValueError:
        out_print = str(out_path)
    print(json.dumps({"report": out_print, "blocks": len(results)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
