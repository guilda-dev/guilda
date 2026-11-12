# IEEJ_WEST30: transient stability, table 4.13

Comparison of `network.IEEJ_WEST30` with the transient stability results of the IEEJ
WEST 30-machine model.

## Reference

The Institute of Electrical Engineers of Japan (電気学会), 電力系統の標準モデル
(Standard models of power systems), section 4.5 "WEST 30-machine model", table 4.13
(transient stability of the peak and night sections) and fig. 4.22 (fault points).
<http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html>

Only the case data and the verdicts of table 4.13 are transcribed here.

## What is compared

Twelve cases: six fault points A to F, in the peak and the night sections. Each case is
a three-phase ground fault at a bus at the end of a line, cleared by opening the faulted
circuits for good (3LG-O):

- A to D: 1-circuit 3LG-O. The line has one card per circuit in the data, so each card is
  one branch and the opened branch is exactly the faulted circuit.
- E and F: 2-circuit 3LG-O (route outage). The card is one branch of two circuits, which
  opens as a whole.
- The fault bus is the end of the card at the fault point of fig. 4.22.

Sequence: from the equilibrium, fault at 0.10 s, cleared at 0.17 s (70 ms) by opening the
branch, which stays open to the end at 20 s (the report's cut-off time).

## Criterion

As in the note of table 4.13: a machine is out of step when the absolute difference of
its rotor angle from that of the reference machine G15 (bus B3150, the slack bus) exceeds
360 degrees. This is `result.judge_out_of_step()` with its defaults (`Reference="slack"`,
`Threshold=360`).

- The report's cases "out of step" and "divergent oscillation" are unstable, and agree
  with the GUILDA verdict `"out-of-step"`.
- The report's cases "stable" agree with `"stable"` (the simulation reaches 20 s with no
  machine out of step).
- `"incomplete"` (the simulation stopped early with no machine out of step) does not
  agree.

## Modelling differences

- Load: the report uses NLT = 2 (P constant current down to 0.7 pu and constant
  impedance below it, 3.33 %/Hz frequency dependence; Q constant impedance). GUILDA has
  no constant-current load, so the loads are `component.load.impedance` (P and Q constant
  impedance, no frequency dependence). The report itself shows that constant-impedance
  loads change a stable case to unstable (its fig. 4.28).
- Armature resistance and air-gap saturation of the Y-method model are not modelled.
- See the help of `network.IEEJ_WEST30` for the conversion of the data, the AVRs and the
  governors.

With the impedance loads the equilibrium is unstable in both sections (a growing
oscillation of 0.26 Hz at peak and 0.30 Hz at night), so every case ends out of step
here and only the report's unstable cases agree.

## Files

- `table4_13_peak.csv`, `table4_13_night.csv`: the cases as scenarios (Scenario CSV, one
  scenario per case, tags A to F; disturbances `fault` and `open`).
- `table4_13_report.csv`: the report verdict of each case (`Section`, `Scenario`,
  `ReportStable` 1/0, `Report` text) and the case data (fault type, fault bus, card,
  opened branch, its end buses and number of circuits).
- `compare_table4_13.m`: the comparison.

## How to run

Start GUILDA from the repository root (`>> GUILDA`), then either run the comparison file
with its defaults or change to this folder and call it with options:

```matlab
run(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST30", "compare_table4_13.m"))

cd(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST30"))
tab = compare_table4_13(Governor=false);                  % without the governors
tab = compare_table4_13(Sections="night", Cases=["A","D"], Plot=true);
```

This folder is not on the MATLAB path. When the current folder is not the GUILDA root,
the function adds the root to the path for the run and removes it afterwards.

Options: `Governor` (default true), `Sections` ("peak", "night"), `Cases` ("A" to "F"),
`TimeEnd` (at most 20 s), `TimeLimit`, `Plot`, `Display`. The output table has one row
per case with the report verdict, the GUILDA verdict, `Agree`, the largest angle, the
time and machines out of step, the flag of `net.simulate` and the elapsed time.

## Measured agreement

### 2026-11-04, base commit ae320a0 (MATLAB R2026a)

5 of 12 cases agree, both with and without the governors (3 of 6 at peak, 2 of 6 at
night). Every case is out of step in GUILDA, so the agreeing cases are the report's
unstable ones: peak A, B, E and night A, D. Some simulations stop before 20 s after the
machines are out of step (flag -1: 5 cases with the governors, 3 without); the verdict is
still "out-of-step".

| Section | Case | Report | GUILDA, governors: t > 360 deg [s] | GUILDA, no governors: t > 360 deg [s] |
| --- | --- | --- | --- | --- |
| peak | A | 3-swing out of step (9.0 s) | out-of-step, 4.10 | out-of-step, 4.24 |
| peak | B | divergent oscillation | out-of-step, 10.29 | out-of-step, 5.95 |
| peak | C | stable | out-of-step, 6.40 | out-of-step, 6.42 |
| peak | D | stable | out-of-step, 5.42 | out-of-step, 3.37 |
| peak | E | 5-swing out of step (18.5 s) | out-of-step, 6.05 | out-of-step, 5.80 |
| peak | F | stable | out-of-step, 6.63 | out-of-step, 4.87 |
| night | A | 2-swing out of step (4.7 s) | out-of-step, 4.10 | out-of-step, 3.64 |
| night | B | stable | out-of-step, 8.64 | out-of-step, 8.49 |
| night | C | stable | out-of-step, 2.90 | out-of-step, 2.74 |
| night | D | 2-swing out of step (7.0 s) | out-of-step, 2.51 | out-of-step, 2.52 |
| night | E | stable | out-of-step, 8.17 | out-of-step, 8.41 |
| night | F | stable | out-of-step, 5.91 | out-of-step, 3.14 |

These are the counts measured earlier with the ODEevent script of the class folder
(`scenario/run_table4_13.m`), which this comparison replaces.

Earlier record, not re-measured here: a test copy of the network with a constant-current P load (not available in GUILDA) and
the governors had a stable equilibrium at night and a mode near zero damping at peak
(largest real part 0.005), and agreed in 11 of 12 cases (5 of 6 at peak, where case D was
unstable, and 6 of 6 at night). That copy is not part of the repository.
