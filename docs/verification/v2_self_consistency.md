# V2 Self-Consistency Verification

> **Date:** 2026-05-20
> **Scope:** numerical accuracy checks that don't require external (paper) PDF lookup.
> **Source plan:** Phase V2 of [`docs/superpowers/plans/2026-05-20-deep-dive-verification.md`](../superpowers/plans/2026-05-20-deep-dive-verification.md).

## V2.2 — Tutorial self-consistency

Both new tutorials are fully synthetic — they generate ground truth and then check their own output against it. V2.2 verifies the prose claims match the numerical reality.

### `HelloNstat.m`

**Prose claim:** baseline-only GLM on a homogeneous Poisson spike train should recover the intercept `log(λΔ) = log(0.012)` for the simulated rate λ=12 Hz, sampleRate=1000 Hz.

**Observed (from harness run):**
- Simulated 124 spikes (target ~120; matches Poisson noise).
- Fitted intercept: **-4.3902**.
- True log(λΔ) = log(0.012) = **-4.4228**.
- Deviation: 0.033, within Bernoulli sampling SE of ≈ 0.09 (1/√124).
- KS plot stays inside the 95% confidence band (verified visually in `docs/figures/verify_HelloNstat/fig01.png`).

**Status: ✅ PASS** — fitted intercept recovers true value within sampling noise; KS plot consistent with constant-rate truth.

---


**Prose claim:**
1. Oracle (true rate as candidate intensity): PASSES KS at α=0.05.
2. Noisy (true + 10% Gaussian): PASSES at this sample size.
3. Misspecified (constant baseline): FAILS by ~2× the critical value.

**Observed (from harness run):**
- Simulated 463 spikes (mean rate 7.51 Hz over 60 s — matches the intended setup).
- KS critical value at α=0.05: 0.0632 (1.36/√463).
- Oracle: ks_stat = **0.0469** → **✅ PASS**.
- Noisy: ks_stat = **0.0462** → **✅ PASS** (essentially matches oracle by happenstance of noise realization).
- Misspecified: ks_stat = **0.1224** → **❌ FAIL** (1.94× the critical value — matches prose "~2× the band").

**Status: ✅ PASS** — all three predicted outcomes match the harness measurements. The KS-test discriminator works as advertised.

---

## V2.3 — Helpfile demonstration API-correctness (deferred)

The V1.4 run confirmed all 23 Tier-B helpfiles execute without error and capture figures (91 total). Subjective "exercises the documented class API" check is folded into the V3 visual-inspection step — the reviewer assesses whether each figure illustrates what its script claims.

---

## V2.1 — Paper-value comparison (deferred to user / future PR)

Comparing the 5 paper-example outputs against published 2012 values (Cajigas, Malik, Brown 2012, DOI `10.1016/j.jneumeth.2012.08.009`) requires PDF lookup of specific numerical values:

- Example 1 — mEPSC Poisson: KS stat for constant-rate Mg²⁺-free fit (paper Fig. 3).
- Example 2 — whisker: lag estimate; coefficient values; per-model KS (paper Fig. 4 / 11).
- Example 3 — PSTH + SSGLM: trial-drift variance (paper Fig. 5 / 12).
- Example 4 — place cells: Gaussian vs Zernike basis comparison (paper Fig. 6 / 13).
- Example 5 — decoding: PPAF / PPHF MSE on simulated reach (paper Fig. 7 / 14).

The 5 paper examples produce figures at `docs/figures/example0[1-5]/` that visually match the published figures (per the V1.4 run and prior verifications). The numerical-comparison table requires either (a) extracting values from the paper PDF or (b) running the original 2012 implementation and diffing — both out of scope for an automated MATLAB-side check.

**Action item for user:** open `docs/figures/example0[1-5]/` in parallel with the open-access paper at <https://pmc.ncbi.nlm.nih.gov/articles/PMC3491120/> and compare key reported numbers. The figure gallery at `docs/verification/figure_gallery.md` provides one-click inspection.

**Acceptance criterion for V2.1:** within 5% on continuous values; exact match on KS pass/fail verdicts; sign and order-of-magnitude match on coefficients.
