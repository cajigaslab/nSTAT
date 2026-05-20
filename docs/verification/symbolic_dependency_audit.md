# Symbolic Math Toolbox Dependency Audit — Phase D2.3

> Phase D2.3 of [docs/superpowers/plans/2026-05-20-comprehensive-codebase-audit.md](../superpowers/plans/2026-05-20-comprehensive-codebase-audit.md).

## Scope

Identify every use of Symbolic Math Toolbox primitives (`sym(`, `matlabFunction`, `symvar`, `subs`, `diff` on sym, etc.) in core toolbox code (excludes tests, helpfiles, fixtures, and Python port).

## Findings

### CIF.m — legitimate, by design

`CIF.m` is the original symbolic-CIF implementation. Its class docstring explicitly states: *"symbolically via the Symbolic Math Toolbox and matlabFunction"*. Every use of `sym(`, `matlabFunction(`, and `symvar(` in this file is intentional.

The 16 `% FIX:` fixes from the 2026-03-10 audit (passing `cifObj.varIn` directly to `matlabFunction`'s `'vars'` argument instead of `symvar(cifObj.varIn)` which reordered alphabetically) remain in place and verified by D2.1.

### LinearCIF.m — partial dependency at construction only

`LinearCIF.m` (added Phase 3.5, May 2026) is the canonical-link drop-in for `CIF`. Its **derivative computation is closed-form** (analytic gradient and Hessian for Poisson and binomial canonical links), so it does NOT require Symbolic at evaluation time.

**However**, the constructor at lines 101, 106, 108 stores `varIn` and `stimVars` as `sym` objects for downstream compatibility with the existing `CIF` interface contract:

```matlab
obj.varIn = sym(Xnames);     % line 101
obj.stimVars = sym(stimNames');  % line 106 (or 108)
```

This means **LinearCIF construction still requires the Symbolic Math Toolbox**, even though its math does not. To make LinearCIF truly toolbox-free, these properties would need to be redefined as `cellstr` (or `string`) and every caller that reads them adjusted accordingly. This is a non-trivial refactor (touches every site that introspects `cifObj.varIn` or `.stimVars`).

**Decision:** documented exception. The path-of-least-resistance promise of LinearCIF ("closed-form derivatives without symbolic-toolbox dependency") is fulfilled at evaluation time, which is the hot path. Construction-time dependency is acceptable for now.

**Fix shape (if a toolbox-free environment becomes a real requirement):** redefine `LinearCIF.varIn :: string`, `LinearCIF.stimVars :: string`, then update every reader. Estimated effort: 6–8 hours plus parity testing.

## Decision

| Item | Status |
|---|---|
| Core `CIF.m` symbolic deps | Intentional, by design. ✓ |
| `LinearCIF.m` symbolic deps at construction | Documented exception. ⚠ |
| Any other `.m` outside `CIF.m`/`LinearCIF.m` using `sym(`, `matlabFunction`, or `symvar` | None. ✓ |

**No action required for Phase D2.3.** The `LinearCIF` partial-dependency is a known design tradeoff documented here for future reference.
