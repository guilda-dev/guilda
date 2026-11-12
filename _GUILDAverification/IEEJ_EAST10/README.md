# IEEJ EAST 10-machine model: transient stability, table 4.3

Comparison of `network.IEEJ_EAST10` with the transient-stability results of the IEEJ
standard model report.

## Reference

- The Institute of Electrical Engineers of Japan (電気学会), 電力系統の標準モデル
  (Standard models of power systems).
  Online: <http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html>
- Section 4.2 (EAST 10-machine model), table 4.3: stability of the peak and night
  sections for faults on the trunk lines.

The report itself is not included here; only the case data and the verdicts of table 4.3
are transcribed.

## What is compared

Each of the 44 cases of table 4.3 (21 at peak, 23 at night) gives a line card, the number
of opened circuits (1 or 2) and the result of the report (stable, sustained oscillation,
first-swing or multi-swing out-of-step with the generators named). GUILDA simulates the
same sequence and its stable / out-of-step verdict is compared with the report.

Sequence (from the equilibrium of the section, `t = 0` to `20 s`):

1. `0` to `0.07 s`: three-phase ground fault at the From bus of the line card.
2. `0.07 s` to the end: 1 or 2 circuits of that card opened. Each circuit of the `k`-th
   line card is one branch (`EL(2k-1)`, `EL(2k)`); a card with a parallel card keeps the
   parallel card when both of its circuits open.

Criterion (the footnote of the report): a generator is out of step when the absolute
value of its rotor angle relative to the reference generator exceeds 360 degrees at any
time up to 20 s. The reference is the slack generator (G3 at peak, G6 at night), which is
`result.judge_out_of_step()` with its defaults (`Reference="slack"`, `Threshold=360`). A case is
out-of-step when any generator is out of step, otherwise stable; "incomplete" when the
solver stops early without an out-of-step generator. The report's "sustained
oscillation" (peak, card 36) has no out-of-step generator and counts as stable.

The solver tolerance is `1e-6` (relative and absolute) instead of the default `1e-4`:
with `1e-4`, ode15s stops early in some large-swing cases (for example peak card 36
without governors at about 3.7 s).

## Modelling differences from the report

See the help of `network.IEEJ_EAST10` for the full list. The ones that matter here:

- Loads are constant impedance. The report's NLT=2 has constant-current P above 0.7 pu
  and frequency characteristics (4 %/Hz for P, -2 %/Hz for Q).
- The generators have no saturation, the armature time constant `Ta` is not used, and
  `D = 0`.
- Governors are `controller.governor.IEEJ_LPT1` / `IEEJ_LPT4` with the constants of the
  report's figures (`Governor=true`, the default), or none (`Governor=false`). The report
  does not state which of these its table corresponds to, so both are run.

## Files

- `table4_3_scenarios.csv`: the 44 cases as scenarios, in the format of
  `Scenario.export_csv` (one scenario per case, two rows each: `fault` and `open`; with
  `Time = [0, 20]` and a Description). Scenario tags are `<section>_card<k>_<n>cct`.
- `table4_3_report.csv`: the report verdict of each scenario: `Scenario` (tag),
  `Section`, `Card`, `From`, `To`, `Circuits`, `Report` (text of the table) and
  `ReportVerdict` (`stable` or `out-of-step`).
- `compare_table4_3.m`: builds the network of each section (options `Governor`,
  `Sections`, `Cases`, `Tolerance`, `Plot`, `Display`), imports the scenarios with
  `Scenario.import_csv(..., Network=net)`, simulates and judges each case, prints report
  vs GUILDA and the agreement, and returns a table.

## How to run

Start GUILDA from the repository root (`>> GUILDA`), then either run the comparison file
with its defaults or change to this folder and call it with options:

```matlab
run(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_EAST10", "compare_table4_3.m"))

cd(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_EAST10"))
tab = compare_table4_3(Governor=false);                  % without governors
tab = compare_table4_3(Sections="peak", Cases=21, Plot=true);   % one case with a plot
```

This folder is not on the MATLAB path. When the current folder is not the GUILDA root,
the function adds the root to the path for the run and removes it afterwards. A full run
of the 44 cases takes a few minutes.

## Measured agreement

Dated records; the newest first.

### 2026-11-04, base commit ae320a0 (`feature/ieej-report-models`), MATLAB R2026a

Constant-impedance loads, `Tolerance=1e-6`. No case was incomplete.

| Governors | peak | night | total |
|---|---|---|---|
| with (`Governor=true`) | 14 of 21 | 19 of 23 | 33 of 44 |
| without (`Governor=false`) | 17 of 21 | 18 of 23 | 35 of 44 |

Cases that differ from the report (section, card, opened circuits):

- With governors: report out-of-step, GUILDA stable: peak 15/2, 18/1, 22/2, 24/2,
  33/1; night 28/1, 30/1, 30/2, 33/2. Report stable, GUILDA out-of-step: peak 35/1,
  36/1 (the report's sustained oscillation).
- Without governors: report out-of-step, GUILDA stable: peak 33/1; night 28/1, 30/1,
  30/2, 33/2, 35/1. Report stable, GUILDA out-of-step: peak 12/1, 35/1, 36/1.

With governors, the multi-swing out-of-step cases of the peak section become stable, as
the governors damp the long-period oscillation. An earlier check found that the field-voltage
limit `0 <= EF <= 4` changes no result (not re-run for this record). These counts are the same as those of the earlier provisional script
(based on `ODEevent`) that this folder replaces.
