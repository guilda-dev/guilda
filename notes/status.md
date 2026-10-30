# Status of the redesign

Branch: `refactor/design-alignment` (base: `version4.0`). Updated 2026-10-30.

## Tests

`DebugScript.run_all` with MATLAB R2026a:

```
/Applications/MATLAB_R2026a.app/bin/matlab -batch "cd('<repo>'); DebugScript.run_all"
```

Result on 2026-10-30 (`refactor/design-alignment` at `b69e54b`, after the
simulator/dictionary fix, OPF stage 2, the controller wiring and
`local_LQR` port, simulation results in variable-map order and the v4
`initialize`):

```
合計 234 件: PASS 233 / KNOWN 0 / FAIL 0 / FIXED? 0 / SKIP 1
  F1: PASS 29    F2: PASS 18    F3: PASS 42
  F4: PASS 30  SKIP 1     F5: PASS  6    F6: PASS 37
  F7: PASS 31             F8: PASS 20    F9: PASS 10
  F10: PASS 10
```

- No known failures: `DebugScript.known_failures` is empty since
  `controller.local_LQR` was ported.
- SKIP: the MATPOWER comparison in F4 (`runopf` is not on the path).

Use R2026a: R2026b lacks the Optimization and Control toolboxes.

## Open items

Checked against the code on 2026-10-30 (`b69e54b`).

### Edit tracking

- Decided and implemented: a network **Hz** edit makes only the `f_*`
  handles stale (the equilibrium does not depend on the nominal frequency);
  a **baseMVA** edit makes the handles and the equilibrium stale, so it
  needs `initialize()` (`LayerPackage.edit_effect`). The edit table in
  `class-design.html` (Edit handling) on `docs/doc-refactoring` has no row
  for these edits yet.

### Bundled networks

- `IEEE14bus`, `IEEE14bus_NoTap`, `IEEE14bus_lossless`, `Ishizaki6Bus`,
  `TEST31bus` and `Txt3Bus` have no `network/parameter.csv`, so they import
  with the default base values (`GUILDA.config("Model","Hz")`, 100 MVA).
  `IEEE9bus` and `IEEE68bus` have the file.

### Tutorials

- The tutorials are updated to v4 on three branches, **on hold** by the
  user's decision until the specification settles:
  `docs/tutorial-steps-1-3-v4`, `docs/tutorial-steps-4-6-v4`,
  `docs/tutorial-classmanual-v4`. On `refactor/design-alignment` the
  `_GUILDAtutorial/*.mlx` files still use pre-v4 calls. The three branches
  predate two later changes, and must be checked against them before they
  are merged: the `comp.get_sys` / `bus.get_sys` layout (inputs, states
  and outputs per layer; `full` ignored) and `initialize`
  (`[result, flag, output]`, `Method=`; see
  [v4-migration.md](v4-migration.md) 1.12 and 1.17). A text search of
  Step1, Step3 and Step6 found only `net.get_sys` and `net.initialize()`
  without outputs, which these changes do not affect; the other files are
  not checked.

### Compatibility

- Done: every compat hook in core code is a single line tagged
  `% COMPAT(v3)`, with the logic in `_GUILDAsystem/_VersionSupport/`
  (`grep -rn "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA`; see
  [v4-migration.md](v4-migration.md#4-compatibility-policy)). There are
  19 hooks.
- The one-step removal procedure (v4-migration.md, "Removing compat code
  in one step") was run only after stage 1. It has not been re-verified
  since stage 2; its test list was extended by reading the tests.

### OPF

Requirements and roadmap: [opf-requirements.md](opf-requirements.md).
Steps 1 (correctness) and 2 (`set_opffcn`) are done; step 3 (external
backends) is open.

Step 1, on `fix/opf-correctness`:

- Fixed: AC OPF with a branch `Imax` or `Smax` stopped in fmincon (NaN
  derivative of `sqrt` at the zero start). The limits are now squared
  (`|I|^2 <= Imax^2`, `P^2+Q^2 <= Smax^2`) and branch-end variables start at
  the values of the initial bus voltages.
- Fixed: AC OPF with linear-only costs (`HP = HQ = 0`) failed inside
  fmincon; zero cost terms are no longer added to the objective.
- Checked, no change: ELD balance includes the loads; DC sign convention;
  slack-bus reference angle; generator Q limits; duals are labeled by
  constraint name, and the nodal price is
  `-lambda.Constraints.balancedP_<bus>` (verified against finite
  differences).
- Start point: bus `V0`/`Varg0` (flat by default). A power-flow warm start
  was measured and not adopted: it did not reduce iterations (9-bus 43 → 43,
  IEEE14 59 → 72) and `calculate_powerflow` may set the slack bus, which
  would edit the network.
- `tools.network_to_mpc` converts a network into a MATPOWER case. The
  MATPOWER comparison test reports SKIP when `runopf` is not on the path;
  it has not been run against a real MATPOWER installation yet. The
  case14 optimum (8081.53 / 7642.59 $/hr) is checked without MATPOWER.

Step 2, on `feature/opf-set-opffcn` (F4 tests):

- `set_opffcn` / `reset_opffcn` on Component, Bus, Branch and
  PowerNetwork, as specified in opf-requirements.md; an OPF edit (tag
  `OPF`) that does not make the equilibrium stale.
- Default OPF cost of loads is 0 (`add_component`), and the bundled
  networks store 0 for their loads, so `r_cost` is the generation cost
  only. A load with finite P/Q bounds is dispatched within them.
- DC OPF uses the MATPOWER susceptance `b = 1/(X·tap)` with the phase
  shift (`makeBdc` convention); before, `Im(Y_ij)`.
- `check_solver`: a `Solver` that cannot express the problem stops with
  `GUILDA:OptimalPowerFlow:UnsupportedSolver` and the usable names. This is
  the point where external backends add their own check.

Open:

- **Step 3: external backends** (CPLEX / Gurobi via `prob2struct`,
  MATPOWER via `tools.network_to_mpc`) behind `Solver`.
- **Multi-period OPF** is deferred as a possible future extension; its
  open design questions stay in opf-requirements.md.

### IEEE14 data and CSV taps

Fixed on `fix/ieee14-data-and-tap-import`:

- **CSV import reads transformer taps.** CSV import (now
  `PowerNetwork.import_csv`) reads the `tap`/`phase` columns that the
  bundled networks and the export write, and still accepts `Tap`/`Phase`; both spellings in one file is an
  error (`GUILDA:import_csv:DuplicateColumns`). Before, every imported tap
  was 1 (IEEE14 4-7, 4-9, 5-6; `IEEE14bus_lossless` too). `TEST31bus`
  already used `Tap`. `Ishizaki6Bus` and `Txt3Bus` have `tap = 0` on `pi`
  lines, which `pi` ignores.
- **`IEEE14bus` matches MATPOWER `case14`** (100 MVA base): `C` = b/2 with
  the case14 b, load Q = −Qd, bus `Vmin`/`Vmax` = 0.94/1.06, generator
  `Pmin`/`Pmax`/`Qmin`/`Qmax` and costs `HP = c2·100²`, `fP = c1·100`. The
  Ybus equals the case14 Ybus (1e-14), power flow gives the `runpf(case14)`
  generator Q (−16.55, 43.56, 25.08, 12.73, 17.62 MVAr), and AC/DC OPF give
  8081.53 / 7642.59 $/hr without changing the network.
- Kept on purpose: every generator (also the compensators at buses 3, 6, 8)
  is `gen-park` with one dynamic parameter set; bus 7 has a zero load; branch
  7-9 is a `pi` line (tap 1 in case14).
- **Load cost decision:** loads in `IEEE14bus` have no OPF cost
  (`HP = HQ = fP = fQ = 0`). case14 has no load cost, a fixed load's cost is
  only a constant, and with 0 `r_cost` equals the MATPOWER objective.
- **`IEEE14bus_NoTap`** is `IEEE14bus` with the transformers 4-7, 4-9 and
  5-6 at tap 1 (phase 0); all other data are the same. Only the transformer
  entries of the admittance matrix differ (off-diagonals and the tap-side
  diagonals). Against `IEEE14bus`: bus voltages differ by up to 0.015 pu
  (bus 5) and angles by 0.45°; AC OPF cost 8079.95 vs 8081.52 $/hr; slowest
  mode −0.530 vs −0.540. The F8 test checks the data against `IEEE14bus`
  and pins its bus voltages, AC OPF cost and slowest eigenvalue.
- Effects users see (`IEEE14bus` now vs. before the fix, computed with the
  code at `63bc5a0`): bus voltages
  differ by up to 0.052 pu (bus 14) and angles by 0.82°; slack P 232.86 →
  232.39 MW; net reactive power at the generator buses
  (−34.3, −8.7, −13.9, −12.0, 3.1) → (−16.6, 30.9, 6.1, 5.2, 17.6) MVAr;
  ELD/DC OPF dispatch 51.8 MW each (cost 2.66) → 221.0 / 38.0 / 0 / 0 / 0 MW
  (7642.59 $/hr); AC OPF cost 2.68 → 8081.52 $/hr; slowest mode −0.535 →
  −0.540, smallest damping ratio 0.037 → 0.035. Bus 8 runs at 1.09 pu in
  power flow, above its `Vmax` 1.06, as in case14 (power flow does not
  enforce limits).
- **`IEEE14bus_lossless` changed through the tap fix** first (data
  untouched): bus voltages up to 0.016 pu (bus 5), angles 0.15°, bus
  reactive power up to 27.9 MVAr, slowest mode −0.332 → −0.385 (smallest
  damping ratio unchanged, 0.037); ω after a B008 fault differs by 1.5e-4
  (peak 1.6e-3); OPF costs unchanged.
- **`IEEE14bus_lossless` is now `IEEE14bus` with R = 0** (decided and done
  on `fix/network-templates-v4`): line charging, the bus 9 shunt and the
  taps stay; bus, load and generator data, limits and costs are those of
  `IEEE14bus`. Against the tap-fixed old data (computed with the code at
  `2723422` and the `fe1e5c3` CSVs): bus voltages up to 0.054 pu (bus 14),
  angles 0.33°, slack P unchanged (219.0 MW, no loss), slowest mode
  −0.385 → −0.595, smallest damping ratio 0.037 → 0.035, ELD/DC/AC OPF cost
  2.66 → 7642.59 $/hr (all three equal without loss). The F8 test pins its
  bus voltages and slowest eigenvalue.
- `DebugScript.run_all` on `fix/ieee14-data-and-tap-import` (2026-10-29):
  165 tests, PASS 163 / KNOWN 1 / FAIL 0 / SKIP 1 (the MATPOWER comparison).

### Analysis API (stages 2 and 3)

Done: power flow, OPF, CPF, simulation, linearization and I/O use the v4
API (`AnalysisResult` subclasses, `[result, flag, output]`, Name-Value
overrides of `net.solver_*`); Symbolic Math Toolbox is optional. Migration:
[v4-migration.md](v4-migration.md) 1.7–1.15.

Done since stage 3: simulation results are stored in variable-map order
(also the controller states), `sim.get_point(t)` reads them, and
`net.linearize(Point={sim, t})` works with controllers; `initialize`
returns `[result, flag, output]` with `Method="powerflow"|"OPF"|"equilibrium"`
([v4-migration.md](v4-migration.md) 1.11, 1.12, 1.17).

Open:

- **`TimeLimit` applies per phase.** `odeSimulator.TimeLimit` limits the
  wall-clock time of each integration phase (between event times), not
  the whole run; a run with many events can take many times `TimeLimit`.
  Decide whether it should be a total limit.

Other items noticed while writing the migration notes (checked in the
code at `b69e54b`):

- A result does not record whether the network was edited after the
  analysis: `tab_editLog` is cleared by `initialize`, so it cannot serve as a
  stamp.
