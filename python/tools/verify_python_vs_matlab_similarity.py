from __future__ import annotations

import argparse
import importlib
import json
import math
import re
import shutil
import subprocess
import sys
import tempfile
import time
import traceback
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
REPORT_DIR = REPO_ROOT / "python" / "reports"
MATLAB_BIN = Path("/Applications/MATLAB_R2025b.app/bin/matlab")
TOC_PATH = REPO_ROOT / "helpfiles" / "helptoc.xml"
PY_ROOT = REPO_ROOT / "python"
if str(PY_ROOT) not in sys.path:
    sys.path.insert(0, str(PY_ROOT))

EXPECTED_CLASS_TOTAL = 9
HELP_PYTHON_REQUIRED_OK = 25
HELP_MATLAB_MIN_OK = 25
SCALAR_OVERLAP_PASS_MIN_TOPICS = 25
KNOWN_MATLAB_HELP_FAILURES: set[str] = set()
PARITY_CONTRACT: dict[str, list[str]] = {
    "SignalObjExamples": ["sample_rate_hz"],
    "CovariateExamples": ["figs"],
    "CovCollExamples": ["figs"],
    "nSpikeTrainExamples": ["figs"],
    "nstCollExamples": ["figs"],
    "EventsExamples": ["figs"],
    "HistoryExamples": ["figs"],
    "TrialExamples": ["figs"],
    "TrialConfigExamples": ["figs"],
    "ConfigCollExamples": ["figs"],
    "AnalysisExamples": ["figs"],
    "FitResultExamples": ["figs"],
    "FitResSummaryExamples": ["figs"],
    "PPThinning": ["num_realizations"],
    "PSTHEstimation": ["num_realizations"],
    "ValidationDataSet": ["figs"],
    "mEPSCAnalysis": ["figs"],
    "PPSimExample": ["figs"],
    "ExplicitStimulusWhiskerData": ["figs"],
    "HippocampalPlaceCellExample": ["figs"],
    "DecodingExample": ["figs"],
    "DecodingExampleWithHist": ["figs"],
    "StimulusDecode2D": ["num_cells"],
    "NetworkTutorial": ["figs"],
    "nSTATPaperExamples": ["num_cells"],
}
FORCE_M_SCRIPT_TOPICS: set[str] = {
    "SignalObjExamples",
    "PPThinning",
    "PSTHEstimation",
    "StimulusDecode2D",
    "nSTATPaperExamples",
}


def _normalize_key(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


def _is_number(x: Any) -> bool:
    return isinstance(x, (int, float)) and math.isfinite(float(x))


def _flatten_numeric_scalars(obj: Any, prefix: str = "", out: dict[str, float] | None = None, depth: int = 0) -> dict[str, float]:
    """Collect finite numeric scalars from nested dict payloads."""
    if out is None:
        out = {}
    if depth > 8:
        return out

    if isinstance(obj, dict):
        for k, v in obj.items():
            key = str(k)
            next_prefix = f"{prefix}.{key}" if prefix else key
            _flatten_numeric_scalars(v, next_prefix, out, depth + 1)
        return out

    if _is_number(obj):
        val = float(obj)
        if prefix:
            out[prefix] = val
            leaf = prefix.split(".")[-1]
            out.setdefault(leaf, val)
    return out


def _python_class_checks() -> dict[str, Any]:
    import numpy as np

    from nstat import CIFModel, Covariate, CovariateCollection, SpikeTrain, SpikeTrainCollection, Trial
    from nstat.history import HistoryBasis

    nst = SpikeTrain(np.array([0.1, 0.2, 0.4]), name="n1", binwidth=0.1, minTime=0.0, maxTime=1.0)
    isis = nst.getISIs().tolist()
    rate = float(nst.firing_rate_hz)

    n1 = SpikeTrain(np.array([0.1, 0.2, 0.4]), name="a", binwidth=0.1, minTime=0.0, maxTime=1.0)
    n2 = SpikeTrain(np.array([0.15, 0.25, 0.45]), name="b", binwidth=0.1, minTime=0.0, maxTime=1.0)
    coll = SpikeTrainCollection([n1, n2])
    psth = coll.psth(0.2)

    t = np.arange(0.0, 1.0 + 1e-12, 0.1)
    c1 = Covariate(t, np.sin(t), "c1", "time", "s", "", ["c1"])
    c2 = Covariate(t, np.cos(t), "c2", "time", "s", "", ["c2"])
    cc = CovariateCollection([c1, c2])
    _, x, _ = cc.dataToMatrix()

    h = HistoryBasis([1, 2])
    hmat = h.design_matrix(n1.getSigRep(0.1, 0.0, 1.0).data[:, 0])

    trial = Trial(spike_collection=coll, covariate_collection=cc)

    lam = Covariate(t, np.ones_like(t) * 5.0, "lam", "time", "s", "Hz", ["lam"])
    sim = CIFModel(lam.time, lam.data[:, 0], "lam").simulate(num_realizations=3, seed=0)

    return {
        "nspike_getISIs": isis,
        "nspike_rate": rate,
        "nstcoll_psth_len": int(psth.data.shape[0]),
        "nstcoll_psth_mean": float(np.mean(psth.data)),
        "covcoll_shape": [int(x.shape[0]), int(x.shape[1])],
        "history_num_columns": int(hmat.shape[1]),
        "trial_sample_rate": float(trial.spike_collection.sampleRate),
        "trial_minmax": [float(trial.spike_collection.minTime), float(trial.spike_collection.maxTime)],
        "cif_num_realizations": int(sim.numSpikeTrains),
    }


def _matlab_class_checks(timeout_s: int = 180) -> dict[str, Any]:
    if not MATLAB_BIN.exists():
        return {"ok": False, "error": "matlab_not_found"}

    repo_q = str(REPO_ROOT).replace("'", "''")
    cmd = (
        "restoredefaultpath; "
        f"repo='{repo_q}'; "
        "cd(repo); addpath(genpath(repo),'-begin'); set(0,'DefaultFigureVisible','off'); "
        "try; "
        "R=struct(); "
        "nst=nspikeTrain([0.1 0.2 0.4],'n1',0.1,0,1); "
        "R.nspike_getISIs=nst.getISIs(); "
        "R.nspike_rate=nst.avgFiringRate; "
        "n1=nspikeTrain([0.1 0.2 0.4],'a',0.1,0,1); "
        "n2=nspikeTrain([0.15 0.25 0.45],'b',0.1,0,1); "
        "coll=nstColl({n1,n2}); "
        "psth=coll.psth(0.2); "
        "R.nstcoll_psth_len=length(psth.data); "
        "R.nstcoll_psth_mean=mean(psth.data); "
        "t=(0:0.1:1)'; "
        "c1=Covariate(t,sin(t),'c1','time','s','','c1'); "
        "c2=Covariate(t,cos(t),'c2','time','s','','c2'); "
        "cc=CovColl({c1,c2}); "
        "X=cc.dataToMatrix(); "
        "R.covcoll_shape=size(X); "
        "h=History([0 0.1 0.2],0,1); "
        "hc=h.computeHistory(n1); "
        "hcov=hc.getCov(1); "
        "R.history_num_columns=hcov.dimension; "
        "tr=Trial(coll,cc); "
        "R.trial_sample_rate=tr.sampleRate; "
        "R.trial_minmax=[tr.minTime tr.maxTime]; "
        "lam=Covariate(t,ones(size(t))*5,'lam','time','s','Hz','lam'); "
        "sim=CIF.simulateCIFByThinningFromLambda(lam,3); "
        "R.cif_num_realizations=sim.numSpikeTrains; "
        "disp(['CODEX_JSON:' jsonencode(R)]); "
        "catch ME; "
        "disp('CODEX_JSON_ERROR'); disp([ME.identifier ' | ' ME.message]); "
        "end; exit(0);"
    )

    try:
        cp = subprocess.run(
            [str(MATLAB_BIN), "-batch", cmd],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            timeout=timeout_s,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "matlab_timeout"}

    out = (cp.stdout or "") + "\n" + (cp.stderr or "")
    m = re.search(r"CODEX_JSON:(\{.*\})", out, flags=re.S)
    if not m:
        tail = "\n".join([ln for ln in out.splitlines() if ln.strip()][-12:])
        return {"ok": False, "error": tail or "matlab_json_missing"}

    try:
        payload = json.loads(m.group(1))
    except json.JSONDecodeError as exc:
        return {"ok": False, "error": f"json_decode_error: {exc}"}

    return {"ok": True, "payload": payload}


def _compare_class_results(py: dict[str, Any], ml: dict[str, Any]) -> dict[str, Any]:
    comparisons = []

    def cmp_scalar(name: str, atol: float = 1e-6, rtol: float = 1e-4):
        pv = float(py[name])
        mv = float(ml[name])
        diff = abs(pv - mv)
        tol = atol + rtol * abs(mv)
        ok = diff <= tol
        comparisons.append({"metric": name, "python": pv, "matlab": mv, "abs_diff": diff, "pass": ok})

    def cmp_list(name: str, atol: float = 1e-6):
        pa = [float(x) for x in py[name]]
        ma = [float(x) for x in ml[name]]
        ok = len(pa) == len(ma) and all(abs(a - b) <= atol for a, b in zip(pa, ma))
        comparisons.append({"metric": name, "python": pa, "matlab": ma, "pass": ok})

    cmp_list("nspike_getISIs", atol=1e-9)
    cmp_scalar("nspike_rate", atol=1e-9, rtol=1e-9)
    cmp_scalar("nstcoll_psth_len", atol=0.0, rtol=0.0)
    cmp_scalar("nstcoll_psth_mean", atol=1e-9, rtol=1e-6)
    cmp_list("covcoll_shape", atol=0.0)
    cmp_scalar("history_num_columns", atol=0.0, rtol=0.0)
    cmp_scalar("trial_sample_rate", atol=1e-9, rtol=1e-9)
    cmp_list("trial_minmax", atol=1e-9)
    cmp_scalar("cif_num_realizations", atol=0.0, rtol=0.0)

    passed = sum(1 for c in comparisons if c["pass"])
    total = len(comparisons)
    return {
        "comparisons": comparisons,
        "summary": {
            "passed": passed,
            "total": total,
            "similarity_score": float(passed / total if total else 0.0),
        },
    }


def _example_topics() -> list[tuple[str, str]]:
    tree = ET.parse(TOC_PATH)
    root = tree.getroot()
    examples = None
    for item in root.iter("tocitem"):
        if item.attrib.get("id") == "nstat_examples":
            examples = item
            break
    if examples is None:
        raise RuntimeError("Unable to locate examples node in helptoc.xml")

    out: list[tuple[str, str]] = []
    for item in examples.findall("tocitem"):
        title = " ".join("".join(item.itertext()).split())
        target = item.attrib.get("target", "")
        if target:
            out.append((title, target))
    return out


def _run_python_topic(stem: str) -> dict[str, Any]:
    try:
        mod = importlib.import_module(f"examples.help_topics.{stem}")
        out = mod.run(repo_root=REPO_ROOT)
        if not isinstance(out, dict):
            return {"ok": False, "error": "non_dict_output", "output": out}

        scalar_map = _flatten_numeric_scalars(out)
        return {"ok": True, "output": out, "scalar_map": scalar_map}
    except Exception as exc:  # noqa: BLE001
        return {
            "ok": False,
            "error": "".join(traceback.format_exception_only(type(exc), exc)).strip(),
        }


def _run_matlab_help_script(script_rel: str, timeout_s: int = 240) -> dict[str, Any]:
    if not MATLAB_BIN.exists():
        return {"ok": False, "error": "matlab_not_found"}

    def run_script_path(path: Path, timeout: int, source_label: str | None = None) -> dict[str, Any]:
        repo_q = str(REPO_ROOT).replace("'", "''")
        path_q = str(path).replace("'", "''")
        cmd = (
            "restoredefaultpath; "
            f"repo='{repo_q}'; "
            "cd(repo); addpath(genpath(repo),'-begin'); set(0,'DefaultFigureVisible','off'); close all force; "
            "try; "
            f"run('{path_q}'); "
            "figs=numel(findall(0,'Type','figure')); "
            "vars=whos; "
            "scalars=struct(); "
            "for ii=1:numel(vars); "
            "vn=vars(ii).name; "
            "if(strcmp(vn,'P')||strcmp(vn,'ME')||strcmp(vn,'ans')); continue; end; "
            "try; vv=eval(vn); "
            "if (isnumeric(vv)&&isscalar(vv)&&isfinite(vv)); "
            "scalars.(vn)=double(vv); "
            "elseif (islogical(vv)&&isscalar(vv)); "
            "scalars.(vn)=double(vv); "
            "elseif (isstruct(vv)&&isscalar(vv)); "
            "fn=fieldnames(vv); "
            "for jj=1:numel(fn); "
            "f=fn{jj}; sv=vv.(f); "
            "if (isnumeric(sv)&&isscalar(sv)&&isfinite(sv)); "
            "if ~isfield(scalars,f); scalars.(f)=double(sv); end; "
            "scalars.([vn '_' f])=double(sv); "
            "end; "
            "end; "
            "end; "
            "catch; end; "
            "end; "
            "P=struct('ok',logical(1),'figures',figs,'var_count',numel(vars),'scalars',scalars); "
            "disp(['CODEX_JSON:' jsonencode(P)]); "
            "catch ME; "
            "errId=ME.identifier; errMsg=ME.message; "
            "try; errRep=getReport(ME,'extended','hyperlinks','off'); catch; errRep=''; end; "
            "P=struct('ok',logical(0),'error',[errId ' | ' errMsg],'error_report',errRep); "
            "disp(['CODEX_JSON:' jsonencode(P)]); "
            "end; exit(0);"
        )

        t0 = time.time()
        try:
            cp = subprocess.run(
                [str(MATLAB_BIN), "-batch", cmd],
                cwd=str(REPO_ROOT),
                capture_output=True,
                text=True,
                timeout=timeout,
                check=False,
            )
        except subprocess.TimeoutExpired:
            return {"ok": False, "error": "matlab_timeout", "runtime_s": float(timeout)}

        runtime = float(time.time() - t0)
        out = (cp.stdout or "") + "\n" + (cp.stderr or "")
        m = re.search(r"CODEX_JSON:(\{.*\})", out, flags=re.S)
        if not m:
            tail = "\n".join([ln for ln in out.splitlines() if ln.strip()][-10:])
            return {"ok": False, "error": tail or "matlab_json_missing", "runtime_s": runtime}

        try:
            payload = json.loads(m.group(1))
        except json.JSONDecodeError as exc:
            return {"ok": False, "error": f"json_decode_error: {exc}", "runtime_s": runtime}

        payload["runtime_s"] = runtime
        if source_label is not None:
            payload["script_used"] = source_label
        return payload

    def run_with_shadow_safe_copy(path: Path, timeout: int) -> dict[str, Any]:
        # If a same-stem .mlx exists, direct run() of .m is shadowed in MATLAB.
        # Execute a temporary copy with a unique name to preserve .m behavior.
        if path.suffix.lower() == ".m" and path.with_suffix(".mlx").exists():
            with tempfile.TemporaryDirectory(prefix="nstat_verify_") as temp_dir:
                temp_script = Path(temp_dir) / f"codex_{path.stem}_shadowsafe.m"
                shutil.copy2(path, temp_script)
                out = run_script_path(temp_script, timeout, f"{path.relative_to(REPO_ROOT)} [shadow_safe_copy]")
            return out
        return run_script_path(path, timeout, str(path.relative_to(REPO_ROOT)))

    script_abs = REPO_ROOT / script_rel
    if not script_abs.exists():
        return {"ok": False, "error": f"missing_script: {script_rel}"}

    primary = run_with_shadow_safe_copy(script_abs, timeout_s)
    if primary.get("ok"):
        return primary

    # If .mlx fails and peer .m exists, try .m as fallback to recover from
    # live-script execution issues and timeout-heavy topics.
    if script_abs.suffix.lower() == ".mlx":
        m_peer = script_abs.with_suffix(".m")
        if m_peer.exists():
            fallback_timeout = max(timeout_s, 180)
            fallback = run_with_shadow_safe_copy(m_peer, fallback_timeout)
            fallback["fallback_from"] = str(script_abs.relative_to(REPO_ROOT))
            if fallback.get("ok"):
                return fallback
            combined = dict(primary)
            combined["fallback_script_used"] = fallback.get("script_used")
            combined["fallback_error"] = fallback.get("error", "")
            combined["fallback_error_report"] = fallback.get("error_report", "")
            combined["error"] = f"{primary.get('error', '')} || fallback_error: {fallback.get('error', '')}"
            return combined

    return primary


def _compare_topic_scalars(py_scalars: dict[str, float], ml_scalars: dict[str, float]) -> dict[str, Any]:
    ml_norm = {_normalize_key(k): (k, float(v)) for k, v in ml_scalars.items() if _is_number(v)}
    overlaps = []
    for pk, pv in py_scalars.items():
        nk = _normalize_key(pk)
        if nk in ml_norm:
            mk, mv = ml_norm[nk]
            diff = abs(float(pv) - float(mv))
            tol = 1e-6 + 1e-3 * abs(mv)
            overlaps.append(
                {
                    "python_key": pk,
                    "matlab_key": mk,
                    "python": float(pv),
                    "matlab": float(mv),
                    "abs_diff": diff,
                    "pass": diff <= tol,
                }
            )
    passed = sum(1 for o in overlaps if o["pass"])
    return {
        "overlaps": overlaps,
        "overlap_count": len(overlaps),
        "overlap_passed": passed,
    }


def _help_similarity() -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    topics = _example_topics()

    summary = {
        "total_topics": len(topics),
        "both_ok": 0,
        "python_ok": 0,
        "matlab_ok": 0,
        "scalar_overlap_topics": 0,
        "scalar_overlap_pass_topics": 0,
        "avg_similarity_score": 0.0,
    }

    scores: list[float] = []
    topic_timeouts = {
        "DecodingExampleWithHist": 120,
        "nSTATPaperExamples": 180,
    }
    for idx, (title, target) in enumerate(topics, start=1):
        stem = Path(target).stem
        m_rel = f"helpfiles/{stem}.m"
        mlx_rel = f"helpfiles/{stem}.mlx"
        if stem in FORCE_M_SCRIPT_TOPICS and (REPO_ROOT / m_rel).exists():
            script_rel = m_rel
        elif (REPO_ROOT / mlx_rel).exists():
            script_rel = mlx_rel
        elif (REPO_ROOT / m_rel).exists():
            script_rel = m_rel
        else:
            script_rel = m_rel

        print(f"[help {idx}/{len(topics)}] {stem}", flush=True)

        py = _run_python_topic(stem)
        timeout_s = topic_timeouts.get(stem, 90)
        ml = _run_matlab_help_script(script_rel, timeout_s=timeout_s)

        if py.get("ok"):
            summary["python_ok"] += 1
        if ml.get("ok"):
            summary["matlab_ok"] += 1

        scalar_cmp = {"overlaps": [], "overlap_count": 0, "overlap_passed": 0}
        if py.get("ok") and ml.get("ok"):
            scalar_cmp = _compare_topic_scalars(py.get("scalar_map", {}), ml.get("scalars", {}))

        both_ok = bool(py.get("ok") and ml.get("ok"))
        if both_ok:
            summary["both_ok"] += 1

        if scalar_cmp["overlap_count"] > 0:
            summary["scalar_overlap_topics"] += 1
            if scalar_cmp["overlap_passed"] == scalar_cmp["overlap_count"]:
                summary["scalar_overlap_pass_topics"] += 1

        if not both_ok:
            score = 0.0
        elif scalar_cmp["overlap_count"] == 0:
            score = 0.7
        else:
            score = 0.7 + 0.3 * (scalar_cmp["overlap_passed"] / scalar_cmp["overlap_count"])
        scores.append(score)

        rows.append(
            {
                "topic": stem,
                "title": title,
                "python_ok": bool(py.get("ok")),
                "python_error": py.get("error", ""),
                "python_output_keys": sorted(list(py.get("output", {}).keys())) if py.get("ok") else [],
                "python_scalar_count": len(py.get("scalar_map", {})) if py.get("ok") else 0,
                "matlab_ok": bool(ml.get("ok")),
                "matlab_error": ml.get("error", ""),
                "matlab_error_report": ml.get("error_report", ""),
                "matlab_fallback_error": ml.get("fallback_error", ""),
                "matlab_fallback_error_report": ml.get("fallback_error_report", ""),
                "matlab_figures": ml.get("figures"),
                "matlab_var_count": ml.get("var_count"),
                "matlab_scalar_count": len(ml.get("scalars", {})) if isinstance(ml.get("scalars"), dict) else 0,
                "matlab_script_used": ml.get("script_used", script_rel),
                "matlab_fallback_script_used": ml.get("fallback_script_used", ""),
                "matlab_runtime_s": ml.get("runtime_s"),
                "scalar_overlap": scalar_cmp,
                "similarity_score": score,
            }
        )

    summary["avg_similarity_score"] = float(sum(scores) / len(scores) if scores else 0.0)
    return {"summary": summary, "rows": rows}


def _evaluate_parity_contract(help_rows: list[dict[str, Any]]) -> dict[str, Any]:
    by_topic = {str(r.get("topic", "")): r for r in help_rows}
    rows: list[dict[str, Any]] = []
    failures: list[str] = []

    for topic, required_keys in PARITY_CONTRACT.items():
        row = by_topic.get(topic)
        if row is None:
            failures.append(f"{topic}: missing topic row")
            rows.append({"topic": topic, "required_keys": required_keys, "status": "missing_topic"})
            continue

        if not (bool(row.get("python_ok")) and bool(row.get("matlab_ok"))):
            failures.append(f"{topic}: python_ok={row.get('python_ok')} matlab_ok={row.get('matlab_ok')}")
            rows.append(
                {
                    "topic": topic,
                    "required_keys": required_keys,
                    "status": "topic_not_ok",
                    "python_ok": bool(row.get("python_ok")),
                    "matlab_ok": bool(row.get("matlab_ok")),
                }
            )
            continue

        overlaps = row.get("scalar_overlap", {}).get("overlaps", [])
        normalized = {}
        for ov in overlaps:
            pkey = str(ov.get("python_key", ""))
            mkey = str(ov.get("matlab_key", ""))
            normalized[_normalize_key(pkey)] = ov
            normalized[_normalize_key(mkey)] = ov

        missing: list[str] = []
        failing: list[str] = []
        for key in required_keys:
            nk = _normalize_key(key)
            ov = normalized.get(nk)
            if ov is None:
                missing.append(key)
                continue
            if not bool(ov.get("pass")):
                failing.append(key)

        status = "pass" if not missing and not failing else "fail"
        if status == "fail":
            failures.append(f"{topic}: missing={missing} failing={failing}")
        rows.append(
            {
                "topic": topic,
                "required_keys": required_keys,
                "missing_keys": missing,
                "failing_keys": failing,
                "status": status,
            }
        )

    return {
        "pass": len(failures) == 0,
        "failures": failures,
        "rows": rows,
    }


def _evaluate_regression_gate(report: dict[str, Any]) -> dict[str, Any]:
    class_summary = report.get("class_similarity", {}).get("summary", {})
    help_summary = report.get("helpfile_similarity", {}).get("summary", {})
    help_rows = report.get("helpfile_similarity", {}).get("rows", [])
    parity_contract = report.get("parity_contract", {})

    failures: list[str] = []

    class_passed = int(class_summary.get("passed", 0))
    class_total = int(class_summary.get("total", 0))
    if class_total < EXPECTED_CLASS_TOTAL or class_passed != class_total:
        failures.append(
            f"class gate failed: expected {EXPECTED_CLASS_TOTAL}/{EXPECTED_CLASS_TOTAL}, got {class_passed}/{class_total}"
        )

    python_ok = int(help_summary.get("python_ok", 0))
    total_topics = int(help_summary.get("total_topics", 0))
    if python_ok < HELP_PYTHON_REQUIRED_OK or python_ok != total_topics:
        failures.append(f"python help gate failed: expected all topics ok, got {python_ok}/{total_topics}")

    matlab_ok = int(help_summary.get("matlab_ok", 0))
    if matlab_ok < HELP_MATLAB_MIN_OK:
        failures.append(f"matlab help gate failed: minimum {HELP_MATLAB_MIN_OK}, got {matlab_ok}")

    scalar_overlap_pass_topics = int(help_summary.get("scalar_overlap_pass_topics", 0))
    if scalar_overlap_pass_topics < SCALAR_OVERLAP_PASS_MIN_TOPICS:
        failures.append(
            f"scalar overlap gate failed: minimum {SCALAR_OVERLAP_PASS_MIN_TOPICS}, got {scalar_overlap_pass_topics}"
        )

    matlab_failed_topics = sorted([str(r.get("topic", "")) for r in help_rows if not bool(r.get("matlab_ok"))])
    unexpected_failures = sorted(set(matlab_failed_topics) - KNOWN_MATLAB_HELP_FAILURES)
    if unexpected_failures:
        failures.append(f"unexpected matlab topic failures: {unexpected_failures}")

    if not bool(parity_contract.get("pass", False)):
        failures.append(f"parity contract failed: {parity_contract.get('failures', [])}")

    known_missing = sorted(KNOWN_MATLAB_HELP_FAILURES - set(matlab_failed_topics))
    return {
        "pass": len(failures) == 0,
        "failures": failures,
        "matlab_failed_topics": matlab_failed_topics,
        "known_allowlist": sorted(KNOWN_MATLAB_HELP_FAILURES),
        "unexpected_failures": unexpected_failures,
        "known_allowlist_not_currently_failing": known_missing,
        "parity_contract_pass": bool(parity_contract.get("pass", False)),
    }


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Verify MATLAB/Python output similarity for nSTAT.")
    parser.add_argument(
        "--enforce-gate",
        action="store_true",
        help="Return non-zero exit code if regression gate fails.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    report: dict[str, Any] = {}

    print("[class] running Python/MATLAB class checks", flush=True)
    py_cls = _python_class_checks()
    ml_cls = _matlab_class_checks()
    if ml_cls.get("ok"):
        class_cmp = _compare_class_results(py_cls, ml_cls["payload"])
        report["class_similarity"] = {
            "python": py_cls,
            "matlab": ml_cls["payload"],
            **class_cmp,
        }
    else:
        report["class_similarity"] = {
            "python": py_cls,
            "matlab_error": ml_cls.get("error", "matlab_unavailable"),
            "summary": {"passed": 0, "total": 0, "similarity_score": 0.0},
            "comparisons": [],
        }

    report["helpfile_similarity"] = _help_similarity()
    report["parity_contract"] = _evaluate_parity_contract(report["helpfile_similarity"]["rows"])
    report["regression_gate"] = _evaluate_regression_gate(report)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORT_DIR / "python_vs_matlab_similarity_report.json"
    out.write_text(json.dumps(report, indent=2), encoding="utf-8")

    printable = {
        "report": str(out.relative_to(REPO_ROOT)),
        "class_similarity": report["class_similarity"]["summary"],
        "helpfile_similarity": report["helpfile_similarity"]["summary"],
        "parity_contract": report["parity_contract"],
        "regression_gate": report["regression_gate"],
    }
    print(json.dumps(printable, indent=2))
    if args.enforce_gate and not report["regression_gate"]["pass"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
