# MATLAB to Python Sync Hub

This directory is the canonical coordination point for keeping the Python
nSTAT implementation aligned with changes in the MATLAB toolbox.

## Contents

- `translation_map.yaml`: MATLAB-to-Python API parity map and status.
- `matlab_api_inventory.json`: inventory of public MATLAB classes/functions.
- `python_api_inventory.json`: inventory of Python APIs and adapters.
- `paper_example_mapping.yaml`: mapping between `helpfiles/nSTATPaperExamples.m`
  sections and Python equivalents.
- `tools/compare_inventories.py`: parity report generator.
- `reports/`: generated comparison reports.

## Update Workflow

1. Scan MATLAB API surface.

```bash
cd /Users/iahncajigas/Library/CloudStorage/Dropbox/Research/Matlab/nSTAT_currentRelease_Local
ls -1 *.m
```

2. Scan Python API surface.

```bash
cd /Users/iahncajigas/Library/CloudStorage/Dropbox/Research/Matlab/nSTAT_currentRelease_Local
ls -1 python/nstat/*.py
```

3. Refresh inventories and translation map.

- Update `matlab_api_inventory.json` for newly added/removed MATLAB files.
- Update `python_api_inventory.json` for newly added/removed Python modules.
- Update `translation_map.yaml` with parity status and notes.

4. Run parity comparison and generate report.

```bash
cd /Users/iahncajigas/Library/CloudStorage/Dropbox/Research/Matlab/nSTAT_currentRelease_Local
python3 porting/python_sync/tools/compare_inventories.py
```

5. Update paper-example parity table.

- Edit `paper_example_mapping.yaml` when `helpfiles/nSTATPaperExamples.m` or
  Python paper workflows change.
- Confirm each MATLAB paper section has a documented Python status
  (`mapped`, `partial`, `missing`, or `not_applicable`).

## Output Expectations

- `reports/latest_comparison_report.json` should be regenerated whenever API
  inventories change.
- `translation_map.yaml` should include every public MATLAB root `.m` file.
