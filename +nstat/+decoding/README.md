# `+nstat/+decoding/` — decoding-algorithm package skeleton

**Status (2026-05): SKELETON ONLY.**

This directory establishes the target layout for the Phase 3 architectural split of `DecodingAlgorithms.m` per the [2026-05-19 nSTAT review action plan](../../docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md), Phase 3 Task 3.2. No code has moved yet; everything still lives in `DecodingAlgorithms.m` at the repo root.

See [`Contents.m`](Contents.m) for the planned class partitions and source mappings (which existing `DecodingAlgorithms.*` static methods will become which `nstat.decoding.*` class).

## Why this exists today, before any code has moved

Establishing the destination directory + the planned partition is a small commit that:

1. **Reserves the namespace.** `nstat.decoding` is now a real MATLAB package. Future user code that imports from it (`import nstat.decoding.*`) will resolve once any class file is added.
2. **Documents the partition decision.** The class-by-class mapping in `Contents.m` was derived from the structural analysis of `DecodingAlgorithms.m` in the 2026-05-19 review session. Locking that mapping here (vs. discovering it again at refactor time) means each future code-movement PR is a mechanical move rather than a design exercise.
3. **Anchors curriculum cross-references.** [`bci-curriculum/reviews/nstat-toolbox-2026-05-19/README.md`](../../docs/superpowers/plans/2026-05-19-nstat-review-action-plan.md) §C4.3 promises to update Ch. 4 §4.B.9's class-list table to point at `nstat.decoding.*`. With this skeleton in place, the chapter edit can land before the code movement without forward-reference rot.

## What you can call today

Nothing. Calling `nstat.decoding.PPAF` or `nstat.decoding.PPLFP` from the MATLAB prompt will fail with an undefined-class error. Use the existing `DecodingAlgorithms.*` static-method calls — including the 9 PPLFP-related methods renamed from `mPPCO_*` in commit `428c344`.

## What lands next (Phase 3 Task 3.2)

One file at a time, in order:
1. `nstat.decoding.PPAF` — extract the 6 PPAF methods from `DecodingAlgorithms`.
2. `nstat.decoding.KalmanFilter` — extract the 4 Kalman methods.
3. `nstat.decoding.PPHF` — extract the 2 PPHF methods.
4. `nstat.decoding.PPLFP` — extract the 9 PPLFP methods (already grouped by name after the rename).
5. `nstat.decoding.SSGLM` — extract the 4 PPSS methods.
6. `nstat.decoding.KF_EM` — extract the 5 KF_EM methods.
7. `nstat.decoding.PointProcessEM` — extract the 5 PP_EM methods.
8. `nstat.decoding.UKF` — extract the 3 UKF helpers.

`DecodingAlgorithms.m` itself becomes a thin compatibility facade — each static method becomes a one-line wrapper that calls `nstat.decoding.X.method(...)` with a `nSTAT:deprecated:DecodingAlgorithms` warning. The pattern mirrors the `mPPCO_*` deprecation shims added in commit `428c344`.

Parity tests run between each step.
