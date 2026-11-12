# IEEJ_EAST30: transient stability, report table 4.9

Comparison of `network.IEEJ_EAST30` with the transient stability results of the
IEEJ EAST 30-machine standard model.

## Reference

The Institute of Electrical Engineers of Japan (電気学会), 電力系統の標準モデル
(standard models of power systems), technical report of the IEEJ Power and Energy
Society, section 4.4 (EAST 30-machine model), table 4.9 (transient stability, Y-method).
Contents and data: http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html

The report itself is not copied here; only the case data and the verdicts of table 4.9
are transcribed.

## What is compared

Table 4.9 gives, for the peak and the night sections, a three-phase ground fault on one
or on both circuits of a line, cleared after 70 ms by opening the faulted circuits
(3LG-O), with the exciter LAT=1 and the load NLT=2, and whether the system stays stable
or steps out (first-swing "1-swing" or multi-swing "N-swing", with the generators that
step out). There are 55 cases: peak 14 with one circuit and 15 with two, night 11 with
one circuit and 15 with two.

Only stable against out-of-step is compared. The swing type, the report's out-of-step
time and its generator group are printed for information but do not count.

## Files

- `table4_9_scenarios.csv`: the 55 cases as scenarios (`Scenario.export_csv` format),
  one scenario per case, tagged `<section>-<n>cct-<card>` (e.g. `peak-2cct-3104`),
  with `Time` [0, 21] s and a `Description`. Each has two disturbances: `fault`, a
  ground fault on the `NF` bus of the line card from 1 s to 1.07 s, and `open`, the
  faulted circuits opened from 1.07 s to the end (they stay open).
- `table4_9_report.csv`: the report's result of each scenario: `Section`, `Card` (line
  card of the data), `ReportBranch` (the line as the table names it), `Circuits`,
  `Report` (text of the table), `ReportGenerator` (out-of-step generators as given,
  `+` for "and others") and `ReportVerdict` (`stable` or `out-of-step`).
- `compare_table4_9.m`: runs the scenarios and compares the verdicts.

Mapping to the network data: each line card has two circuits, which are two parallel
branches (`EL` + 2k-1 and `EL` + 2k for the k-th card), so opening one circuit opens one
branch. The report's rows 2104-2105 and 2107-2108 are run on the cards 2104 and 2107.
Generators are numbered as in the report: G1 to G8 are nodes 2001 to 2008, G9 to G30
nodes 3001 to 3022; G18 (bus `B3010`, `B3010SG1`) is the slack.

## Sequence and criterion

For each section, `compare_table4_9` builds `network.IEEJ_EAST30(Section=..., Governor=...)`,
imports the scenarios into it with `Scenario.import_csv(..., Network=net)`, and for each
case runs `net.simulate(sc, Progress="none", TimeLimit=300)` over [0, 21] s and judges the
result with `Scenario.out_of_step(result, Reference="B3010SG1", Threshold=360)`:

- `out-of-step` when the absolute rotor angle of a generator relative to G18 exceeds
  360 degrees at some time (the printed time is the first such time, and the generators
  those beyond 360 degrees then);
- `incomplete` when the simulation stops early without that. The case is then run again
  with the relative tolerance 1e-5 (the network's default is 1e-4); if it is incomplete
  again it does not agree;
- `stable` otherwise.

A case agrees when this verdict equals `ReportVerdict`.

## Modelling differences from the report

- Loads: NLT=2 (constant current above 0.7 pu for `P`, constant impedance below and for
  `Q`, with frequency characteristics) is represented by load-impedance models: `P`
  varies with the square of the voltage above 0.7 pu, and frequency has no effect.
- Generator saturation is not represented.
- Generators, exciters and governors otherwise follow the report; see the help of
  `network.IEEJ_EAST30` for the conversions.

The report's table is computed with its exciter LAT=1; the comparison is run with the
governors (the default network) and without them (`Governor=false`).

## How to run

Start GUILDA from the repository root (`>> GUILDA`), then either run the comparison file
with its defaults or change to this folder and call it with options:

```matlab
run(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_EAST30", "compare_table4_9.m"))

cd(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_EAST30"))
[tab, r_agree] = compare_table4_9(Governor=false);
tab = compare_table4_9(Sections="night", Circuits=2, Plot=true);
```

This folder is not on the MATLAB path. When the current folder is not the GUILDA root,
the function adds the root to the path for the run and removes it afterwards.

`tab` has one row per case (report and GUILDA verdicts, time, generators, tolerance
used, agreement) and `r_agree` is [agreeing cases, cases]. Options: `Governor`,
`Sections`, `Circuits`, `Cases` (scenario tags), `TimeLimit`, `RetryTolerance`, `Plot`,
`Verbose`. A full run takes some minutes per setting.

## Measured agreement

Dated record; rerun `compare_table4_9` to check the current code.

### 2026-11-04, base commit ae320a0 (MATLAB R2026a)

| Setting | Agreement | Reruns at tolerance 1e-5 |
|---|---|---|
| `Governor=true` (default) | 55 / 55 | none |
| `Governor=false` | 55 / 55 | `peak-2cct-3105` (stable after the rerun) |

These equal the results of the earlier provisional script (`run_table4_9`, with
`ODEevent`) that this folder replaces.

For information (not part of the agreement):

- The first out-of-step generator is the first one of the report's group in all
  out-of-step cases but one: `night-2cct-2104` gives G1, where the report gives G5 and
  others.
- With the governors the multi-swing cases step out at about the report's times: 5.9 to
  6.1 s after the fault for the report's 6 to 7 s (`peak-1cct-2102`, `peak-1cct-2103`,
  `night-1cct-2104`), and 6.0 s for its 9 s (`peak-2cct-3104`). Without them
  `peak-1cct-2103` and `peak-2cct-3104` step out earlier, 2.6 s and 3.3 s after the fault.
