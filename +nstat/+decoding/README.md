# `+nstat/+decoding/` — decoding-algorithm package skeleton

**Status (v1.4+): POPULATED.**

This directory holds the per-algorithm cluster classes extracted from the legacy `DecodingAlgorithms.m`. As of v1.4 the package has been fully populated with `KalmanFilter`, `UKF`, `PPAF`, `PPHF`, `PPLFP`, `SSGLM`, `KF_EM`, and `PointProcessEM`. `DecodingAlgorithms.m` itself is now a thin facade (1189 LOC, down from 10860) that holds 47 deprecation shims forwarding to these package classes.

See [`Contents.m`](Contents.m) for the class partitions and source mappings.

## What you can call today

Every cluster class:

```matlab
[x_p, W_p] = nstat.decoding.PPAF.PPDecode_predict(x_u, W_u, A, Q);
[x_u, W_u] = nstat.decoding.PPHF.PPHybridFilter(...);
results    = nstat.decoding.SSGLM.PPSS_EMFB(trial, cfg, sampleRate);
```

Legacy `DecodingAlgorithms.PPDecode_*`, `DecodingAlgorithms.PPSS_*`, and `DecodingAlgorithms.mPPCO_*` calls still work but emit a one-time `nSTAT:deprecated:DecodingAlgorithms` warning routing the caller to the package class.

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
