"""Auto-generated MATLAB-to-Python scaffold.

Source: helpfiles/SignalObjExamples.m
"""

from __future__ import annotations

from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat

import html as _html
import json
import re

from nstat import SpikeTrain, fit_poisson_glm, psth

def _parse_html_reference(html_path: Path) -> dict[str, object]:
    if not html_path.exists():
        return {'title': html_path.stem, 'sections': [], 'figures': [], 'code_outputs': []}
    text = html_path.read_text(encoding='utf-8', errors='ignore')
    title_m = re.search(r'<title>(.*?)</title>', text, flags=re.I | re.S)
    title = _html.unescape(re.sub(r'<[^>]+>', '', title_m.group(1))).strip() if title_m else html_path.stem
    sections = [_html.unescape(re.sub(r'<[^>]+>', '', s)).strip() for s in re.findall(r'<h2[^>]*>(.*?)</h2>', text, flags=re.I | re.S)]
    sections = [s for s in sections if s]
    figures = sorted(dict.fromkeys(re.findall(r'src="([^"]+_\d+\.png)"', text, flags=re.I)))
    raw_outputs = re.findall(r'<pre class="codeoutput">(.*?)</pre>', text, flags=re.I | re.S)
    code_outputs = []
    for b in raw_outputs:
        cleaned = _html.unescape(re.sub(r'<[^>]+>', '', b)).replace('\xa0', ' ')
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
        if cleaned:
            code_outputs.append(cleaned)
    return {'title': title, 'sections': sections, 'figures': figures, 'code_outputs': code_outputs}

def run(*, repo_root: str | Path | None = None) -> dict[str, object]:
    root = Path(repo_root).resolve() if repo_root is not None else Path.cwd()
    html_ref = _parse_html_reference(root / 'helpfiles/SignalObjExamples.html')
    # Minimal nSTAT Python smoke using translated utilities.
    x = np.linspace(-1.0, 1.0, 200)
    y = (np.sin(2.0 * np.pi * x) > 0).astype(float)
    fit = fit_poisson_glm(x[:, None], y, offset=np.zeros_like(y), max_iter=40)
    trains = [SpikeTrain(np.array([0.1, 0.3, 0.7], dtype=float)), SpikeTrain(np.array([0.2, 0.4], dtype=float))]
    psth_rate, _ = psth(trains, np.linspace(0.0, 1.0, 11))
    frame = pd.DataFrame({'section': html_ref['sections']})
    return {
        'source': 'helpfiles/SignalObjExamples.m',
        'html_title': html_ref['title'],
        'section_count': int(len(html_ref['sections'])),
        'sections': html_ref['sections'],
        'figure_count': int(len(html_ref['figures'])),
        'figure_refs': html_ref['figures'],
        'expected_code_outputs': html_ref['code_outputs'][:8],
        'nstat_smoke': {
            'glm_log_likelihood': float(fit.log_likelihood),
            'psth_peak': float(np.max(psth_rate)),
        },
        'table_rows': int(frame.shape[0]),
    }

def main() -> int:
    print(json.dumps(run(), indent=2))
    return 0
