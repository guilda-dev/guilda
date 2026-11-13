# IEEJ WEST 10-machine model: table 4.5 of the IEEJ report

This folder compares `network.IEEJ_WEST10` with the transient stability results that the
IEEJ report gives for the WEST 10-machine model. It is a verification of the model, not a
GUILDA feature: the scenarios, the verdicts of the report and the comparison script live
here, and the network class only points to this folder.

## Source

- The Institute of Electrical Engineers of Japan (電気学会), 電力系統の標準モデル
  (standard models of power systems), technical report, section 4.3 (WEST 10-machine
  model), table 4.5 (transient stability of the peak and night sections), and the dynamic
  input data in the format of the Y-method program of CRIEPI.
  http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html

Only the case definitions and the verdicts are taken from the report; its figures and text
are not copied here.

## Files

- `table4_5_scenarios.csv`: the 26 cases (13 per section) as scenarios, one row per
  disturbance. The tag is `<section>_<case>`
  (`peak_A` ... `night_G8`); `Description` is the case of the report; `Time` is [0, 20] s.
- `table4_5_report.csv`: the verdict of the report for each scenario tag: `Verdict`
  (`out-of-step`, `stable` or `growing`), `TimeOutOfStep` [s] and `OutOfStepGen` for the
  out-of-step cases, `Period` [s] of the swing read from the waveforms of the report, and
  `ReportText`, a short summary of these values.
- `compare_table4_5.m`: builds the network, imports the scenarios, simulates and judges
  each case, and prints the report against GUILDA with the agreement count.

## Cases (the sequence)

- A to L: a three-phase ground fault (3LG-O) on one circuit of a two-circuit line, at the
  line end on the fault bus, from 0.10 s to 0.17 s (70 ms); the faulted circuit is then
  opened for good (both ends at once, no reclosing). Each circuit is its own branch in
  the network (`LINE<card>-1`, `-2`), so only the faulted circuit is opened.
- G8: the generator G8 (bus `B028`) trips at 0.10 s and stays tripped. The report opens
  its transformer 980; tripping the generator leaves the rest of the network the same.

Each case starts from the equilibrium of its section (peak or night).

## Criterion

The judge function `judge_table4_5` in `compare_table4_5.m` (the definition of the report,
and of the comparison made when the model was built):

- `out-of-step`: `result.judge_out_of_step()` with the slack generator G10 (`B030`) as the
  reference: some `|delta_i - delta_G10|` exceeds 360 degrees in the 20 s.
- `stopped`: the solver stopped early (flag ~= 1) before an angle passed 360 degrees
  (the `incomplete` of `judge_out_of_step`). It counts as a disagreement.
- otherwise `growing` when the peak-to-peak spread of the angles from G10 over the last
  5 s is larger than over 0.2 s to 5 s, and `stable` when it is not.

A case agrees when the verdict equals that of the report. `Period` is the period of the
swing of G1 from G10, from its upward crossings of its mean after 2 s (NaN when out of
step, stopped, or with fewer than two crossings).

## Modelling differences

- Loads are load-impedance models. The report (`NLT = 2`) has constant-current `P`
  changing to constant impedance below 0.7 pu, constant-impedance `Q` and 3.33 %/Hz of
  `P`. The report states that constant-impedance loads are less stable: its case C at
  peak is stable with `NLT = 2` and not with them.
- The armature time constant (`Ta`) is not modelled (no stator transients), and the input
  data have no saturation.
- The short-circuit time constants of the report are converted to open-circuit ones (see
  the help of `network.IEEJ_WEST10`). In a separate check the results depended strongly
  on `Tq_pp`.
- The G8 case trips the generator instead of opening its transformer.

## How to run

Start GUILDA from the repository root (`>> GUILDA`), then either run the comparison file
with its defaults or change to this folder and call it with options:

```matlab
run(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST10", "compare_table4_5.m"))

cd(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST10"))
[tab, summary] = compare_table4_5(Governor=false);      % AVRs only
tab = compare_table4_5(Sections="peak", Cases=["A","L"], Plot=true);
tab = compare_table4_5(SimulateOptions={"Tolerance", 1e-6, "AbsoluteTolerance", 1e-8});
```

This folder is not on the MATLAB path. When the current folder is not the GUILDA root,
the function adds the root to the path for the run and removes it afterwards.

Options: `Governor` (network option; true adds the `LPT = 1` governors of the report),
`Sections` (`"peak"`, `"night"`), `Cases` (case ids such as `"A"`, `"G8"`), `Plot`,
`Display`, `SimulateOptions` (Name-Value options of `net.simulate`). A full run of both
sections takes a few minutes.

## Measured agreement

Record of 2026-11-04, base commit `ae320a0` (`feature/ieej-report-models`), MATLAB
R2026a, default solver settings:

| Governor | Agree | Peak | Night |
| --- | --- | --- | --- |
| true  | 9 of 26 | 2 of 13 | 7 of 13 |
| false | 9 of 26 | 2 of 13 | 7 of 13 |

- Peak: only the two out-of-step cases A and L agree. The report has the other 11
  stable and G8 with a growing swing; GUILDA has them out of step, mostly within 3 to
  8 s (G8 at 13.8 s with governors and 11.3 s without), except E with governors, which
  stops the solver at 252 degrees (`stopped`; without governors E is out of step at
  15.6 s after a growing swing).
- Night: A and E to I agree in both runs; with governors also G8, without them J. The
  other cases (B, C, D, K, L, and J with governors) go out of step within 3 to 8 s, and
  G8 without governors stops the solver at 125 degrees.
- The swing periods of the stable night cases are 2.0 to 2.4 s without governors and
  1.3 to 2.2 s with them (the report: 2.2 to 2.5 s).
- With `Tolerance` 1e-6 and `AbsoluteTolerance` 1e-8 (earlier check), E at peak with
  governors is out of step at 11.7 s, and G at peak stops instead; G8 at night without
  governors still stops.
- The verdicts, angles and periods are the same as those of the earlier provisional
  script (`scenario/run_table4_5.m` in the class folder, with `ODEevent`) in all 26
  cases of both runs. The cause of the disagreement at peak is not identified.
