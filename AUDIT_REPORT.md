# nSTAT Toolbox Code Audit Report

**Date**: 2026-03-10
**Scope**: Full 5-phase audit of the nSTAT (Neural Spike Train Analysis Toolbox) MATLAB codebase
**Reference**: Cajigas, Malik, Brown. J Neurosci Methods 211:245-264 (2012)
**Tag Convention**: All changes marked with `% FIX:` inline comments
**Total FIX tags**: 67 across 8 files

---

## 1. Critical Bugs Found and Fixed

### 1.1 FitResult.m — `delta = sampleRate` (inverted sample rate)
- **Line 371**: `delta=sampleRate` should be `delta=1/sampleRate`
- **Impact**: Time-rescaling KS test used sample rate as bin width instead of reciprocal
- **Severity**: Critical — invalidates goodness-of-fit analysis for any sampleRate != 1

### 1.2 DecodingAlgorithms.m — `isa(condNum,'nan')` (always false)
- **Lines 765, 925, 932**: `isa(condNum,'nan')` replaced with `isnan(condNum)`
- **Impact**: NaN condition numbers never detected; singular matrices passed unchecked
- **Severity**: Critical — decoding algorithms (PPAF, PPHF) skip regularization for NaN matrices

### 1.3 DecodingAlgorithms.m — `ExplambdaDeltaCubed` uses `ld.^2` instead of `ld.^3`
- **Lines 5483, 5537, 8071, 8125**: `ld.^2` corrected to `ld.^3`
- **Impact**: Third moment of Poisson distribution computed as variance (second moment)
- **Severity**: Critical — affects higher-order filter corrections in SSGLM

### 1.4 CIF.m — `symvar()` reorders variables alphabetically (CIF-14)
- **Lines 240, 252, 253, 264, 265, 269, 272, 277, 281, 282, 286, 287, 315, 318, 333, 336**: All `symvar(cifObj.varIn)` replaced with `cifObj.varIn`
- **Impact**: `matlabFunction('vars', symvar(...))` creates functions expecting alphabetical argument order, but all callers pass arguments in `varIn` order. For non-alphabetical variable names, arguments are silently mismatched.
- **Severity**: Critical — affects binomial lambdaDelta AND all gradient/jacobian functions for both fitTypes

### 1.5 SignalObj.m — `findGlobalPeak('minima')` crashes (typo `sOBj`)
- **Line 1574**: `sOBj` (capital B) is undefined — always crashes when finding minima
- **Severity**: Critical — `findGlobalPeak('minima')` and `findMinima()` always error

### 1.6 SignalObj.m — `findPeaks('minima')` returns maxima
- **Lines 1596-1598**: The `'minima'` branch calls `findpeaks(sObj.data(:,i))` — identical to `'maxima'` branch
- **Fix**: Negate data for peak detection, then negate values back
- **Severity**: Critical — silently returns wrong results

### 1.7 SignalObj.m — `crosscor` typo in multi-dim autocorrelation
- **Line 1066**: `crosscor(...)` should be `crosscorr(...)` (missing trailing `r`)
- **Severity**: High — multi-dimensional `autocorrelation()` always crashes

### 1.8 SignalObj.m — Handle aliasing in arithmetic operators
- **Lines 664, 713, 733**: `s3 = s1c` creates handle alias; `s3.data = ...` mutates input signal
- **Fix**: Changed to `s3 = s1c.copySignal` in `times()`, `rdivide()`, `ldivide()`
- **Severity**: High — arithmetic operations silently corrupt input signals when time axes already match

### 1.9 SignalObj.m — `plotAllVariability` checks wrong variable for ciLower
- **Line 2174**: `length(ciUpper)` should be `length(ciLower)` in the ciBottom branch
- **Severity**: Medium — custom lower CI bounds may hit wrong code path

### 1.10 nspikeTrain.m — Burst detection off-by-one + wrong append order (NST-13)
- **Line 287**: `burstEnd = [find(y(burstStart(end):end)==1, 1,'last'); burstEnd]` had two bugs:
  1. `find()` returns relative index but was used as absolute (missing `+ burstStart(end) - 1`)
  2. New burstEnd was prepended but should be appended (corresponds to last burst, not first)
- **Severity**: High — produces incorrect burst boundaries and durations

---

## 2. Numerical Safety Fixes

### 2.1 FitResult.m — `log(0)` guards
- **Lines 353, 373, 415**: Added `max(x, eps)` before `log()` calls to prevent `-Inf`
- **Context**: Time-rescaling computation `log(1 - exp(-lambdaDelta))`

### 2.2 DecodingAlgorithms.m — Q matrix indexing out of bounds
- **Line 9299**: `Q(:,:,min(size(Q,3)))` → `Q(:,:,min(size(Q,3),k))`
- **Context**: State noise covariance selection in SSGLM

### 2.3 nspikeTrain.m — Division by zero in avgFiringRate (NST-2)
- **Line 219**: Added guard for `maxTime == minTime` case (returns NaN)

---

## 3. Code Quality Fixes

### 3.1 `eval()` → `feval()` Conversions (SignalObj.m)
- **22 conversions** across methods: abs, log, median, mode, mean, std, xcorr, xcov, merge, copySignal, normalizeTime, makeCompatible
- **Pattern**: `eval(strcat('m=',class(sObj),'(...)'))` → `m = feval(class(sObj),...)`
- **3 eval() calls remain** in plot method (architectural — `cell2str` generates eval-ready strings)

### 3.2 Silent `catch` → Named Exception Capture
- **FitResult.m**: 6 fixes (lines 250, 339, 352, 360, 521, 551)
- **FitResSummary.m**: 3 fixes (lines 413, 617, 654)
- **SignalObj.m**: 1 fix (line 2016)
- **getPaperDataDirs.m**: 1 fix (line 27)
- **Pattern**: `catch` → `catch ME %#ok<NASGU> % FIX: capture exception; [reason]`

### 3.3 Deprecated Function Replacements
| Deprecated | Replacement | File | Count |
|---|---|---|---|
| `roundn(x,-n)` (Mapping Toolbox) | `round(x,n)` (core MATLAB) | nspikeTrain.m | 7 |
| `histc` | Annotated for future `histcounts`/`histogram` | nspikeTrain.m | 2 |
| `simget` | Annotated for future `Simulink.SimulationInput` | CIF.m | 2 |

### 3.4 Magic Number Annotations
- **Analysis.m line 776**: `1.96` annotated as `norminv(0.975)` for 95% CI
- **History.m line 131**: `sampleRate = 1000` annotated as visualization-only rate

### 3.5 Floating-Point Index Fix
- **History.m lines 134-135**: Added `round()` to prevent fractional array indices

### 3.6 Array Growth Annotation
- **History.m line 229**: Added `%#ok<AGROW>` with justification (small loop count)

### 3.7 Handle Aliasing Fixes (SignalObj.m)
- **Lines 664, 713, 733**: `times()`, `rdivide()`, `ldivide()` — `s3 = s1c` → `s3 = s1c.copySignal`
- **Root cause**: `makeCompatible` returns original handles when signals are already compatible (same time axis/sampleRate), so `s3 = s1c` creates a handle alias that mutates the input

### 3.8 Typo Fixes (SignalObj.m)
- **Line 1574**: `sOBj` → `sObj` in `findGlobalPeak('minima')`
- **Line 1066**: `crosscor` → `crosscorr` in multi-dim `autocorrelation()`
- **Line 2174**: `length(ciUpper)` → `length(ciLower)` in `plotAllVariability` ciBottom branch

### 3.9 Logic Fix (SignalObj.m)
- **Lines 1596-1598**: `findPeaks('minima')` now negates data for peak detection and negates values back

### 3.10 Defensive Validation
- **CIF.m**: Added `fitType` validation (must be 'poisson' or 'binomial')
- **nspikeTrain.m**: `computeRate()` now throws explicit error instead of silent no-op
- **nspikeTrain.m**: `close all` replaced with `figure` in computeStatistics (NST-12)

---

## 4. Files Modified

| File | Size | Changes | FIX Tags |
|---|---|---|---|
| SignalObj.m | ~106 KB | 22 eval→feval, 1 silent catch, 2 typos, 1 minima fix, 3 handle aliases, 1 ciLower fix | 31 |
| FitResult.m | ~82 KB | 1 delta bug, 3 log guards, 6 silent catches | 10 |
| DecodingAlgorithms.m | ~488 KB | 3 isnan, 4 ld^3, 1 Q-index | 8 |
| nspikeTrain.m | ~45 KB | 1 div-by-zero, 1 burst fix, 7 roundn, 1 close-all, 2 histc annotations, 1 computeRate | 7 |
| CIF.m | ~49 KB | 16 symvar fixes, 1 fitType validation, 2 simget annotations | 4 |
| FitResSummary.m | ~60 KB | 3 silent catches | 3 |
| History.m | ~12 KB | 1 magic number, 2 float index, 1 array growth | 3 |
| getPaperDataDirs.m | ~2 KB | 1 silent catch | 1 |

---

## 5. Deprecated Patterns — Verified Clean

| Pattern | Occurrences | Status |
|---|---|---|
| `isstr` | 0 | Clean |
| `bitmax` | 0 | Clean |
| `EraseMode` | 0 | Clean |
| `roundn` (functional) | 0 | All 7 replaced with `round` |
| `isa(x,'nan')` (functional) | 0 | All 3 replaced with `isnan` |

---

## 6. Architectural Observations (Not Fixed)

### 6.1 SignalObj.m — Plot `eval()` with `cell2str`
The plot method uses `eval(evalstring)` where `evalstring` is built from `cell2str(plotProps)`. The `cell2str` function recursively unwraps cell arrays to produce eval-ready strings (e.g., `'''r'',''LineWidth'',2'`), not cell arrays of property-value pairs. Converting these to `feval` or direct function calls would require restructuring how `plotProps` are stored and propagated throughout the class hierarchy.

### 6.2 CIF.m — `assignin('base', ...)` for Simulink
The CIF simulation methods use `assignin('base', ...)` to pass variables to Simulink models. This creates side effects in the base workspace and is fragile. The modern approach uses `Simulink.SimulationInput` with `setVariable()`. However, this requires restructuring the Simulink model interface.

### 6.3 CIF.m — `simget`/`simset` Legacy API
Lines 920 and 1009 use `simget` (deprecated). Line 920's result is unused (dead code). Line 1009's result is passed to `sim()`. Modernizing requires migrating to `Simulink.SimulationInput`.

### 6.4 nspikeTrain.m — `histc` + `bar(...,'histc')` Deprecated
The ISI histogram plot uses both `histc` (deprecated R2014b) and `bar(...,'histc')` (deprecated plot style). The modern replacement is `histogram()` which handles both binning and plotting.

### 6.5 SignalObj.m — `spectrum.periodogram` and `dspdata.psd` Removed
Lines 1094, 1109, 1139 use `spectrum.periodogram('rectangular')`, `psd(Hs,...)`, and `dspdata.psd(...)` which were removed from the Signal Processing Toolbox in R2014a. These methods (`periodogram`, `MTMspectrum`) will crash on any modern MATLAB. The replacement is `periodogram()` and `pmtm()` function-based API.

### 6.6 nspikeTrain.m — Binning Interval Convention (NST-5)
The `getSigRep` method switches between open-right `[t_i, t_{i+1})` and closed-right `(t_i, t_{i+1}]` interval conventions partway through (around line 459). This may be intentional for the first vs. subsequent bins but should be documented and verified against the original paper's convention.

---

## 7. Verification Commands

```matlab
% Verify all FIX tags
>> !grep -rn "% FIX:" *.m | wc -l
% Expected: 67

% Verify no deprecated patterns remain
>> !grep -rn "\bisstr\b\|bitmax\|EraseMode" *.m
% Expected: (no output)

% Verify no roundn calls remain
>> !grep -rn "roundn(" *.m
% Expected: only in FIX comment text

% Verify no isa(x,'nan') in active code
>> !grep -n "isa(.*,'nan')" DecodingAlgorithms.m
% Expected: only in FIX comment text
```
