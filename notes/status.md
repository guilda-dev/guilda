# Status of the redesign

Branch: `refactor/design-alignment` (base: `version4.0`). Updated 2026-10-29.

## Tests

`DebugScript.run_all` with MATLAB R2026a:

```
/Applications/MATLAB_R2026a.app/bin/matlab -batch "cd('<repo>'); DebugScript.run_all"
```

Result on 2026-10-29 (branch `feature/api-foundation`):

```
合計 141 件: PASS 140 / KNOWN 1 / FAIL 0 / FIXED? 0   (128 s)
  F1: PASS 21  KNOWN 1    F2: PASS 12    F3: PASS 34
  F4: PASS  7             F5: PASS  3    F6: PASS 21
  F7: PASS 14             F8: PASS 12    F9: PASS  6
  F10: PASS 10
```

Use R2026a: R2026b lacks the Optimization and Control toolboxes.

### Known failure

- `test_F1_model_building/AddLocalControllerLQR` — `controller.local_LQR`
  still uses the v3 LocalController API and is abstract under v4. In v4 a
  controller's input is the component's output `Y` (for generators only
  `omega`), and `add_local_controller` holds only controllers keyed `avr` /
  `pss`. Porting a state-feedback LQR needs a decision on the controller
  input contract (state access, and which keys a component may hold).

## Open items

Checked against the code on 2026-10-29.

### Edit tracking

- **`add_local_controller` logs no edit.** Adding or replacing an AVR/PSS
  changes the dynamics but does not call `log_edit`, so neither the
  equilibrium nor the handles are marked stale
  (`_GUILDAsystem/@Component/add_local_controller.m`).
- **Network Hz edit marks the equilibrium stale.** Confirmed by design:
  `LayerPackage.edit_effect` maps `Parameter(base)` to "handles and
  equilibrium stale". Decide whether a Hz (or baseMVA) edit should require
  `initialize()` or only rebuild the handles.
- **`odeLinearizer` / `solver_ODE` called directly skip the stale check.**
  Only `PowerNetwork.initialize`, `simulate` and `get_sys` call
  `check_edit`; the analysis classes do not.

### Controllers

- **Replacing an AVR drops its nested PSS.** `add_local_controller` with a
  new AVR overwrites `a_LocalController{1}`; the PSS attached to the old AVR
  is not moved to the new one.
- **GlobalController parent property** is named `PowerNetwork` and holds
  `{net}` (a cell), unlike `a_PowerNetwork` / `a_Component` elsewhere.
- **A tripped global controller still acts.** A trip event naming a global
  controller freezes its states, but `odeSimulator` still adds its `f_Y`
  output to the controlled inputs, so a proportional (direct feed-through)
  part keeps acting. `GlobalController.l_isConnect` is never set or read;
  only the controlled units' `l_isConnect` masks the controller input.

### Topology

- **Branch tags can collide after `remove_branch`.** `add_branch` numbers
  the new branch `numel(a_Branch)+1`, which may equal a remaining tag
  (`add_bus` already skips used numbers).
- **Component tags can collide after `remove_component`** (added after
  checking the code). `add_component` uses `numel(a_Component)+1` in the
  same way.

### Simulation

- **Events outside the simulation time range are ignored silently.**
  `odeEventSet/private/getTimeSpan.m` drops event times outside
  `[t0, te]`; an event that ends before `t0` has no effect and no warning
  is issued. Events that start before `t0` and continue into the range are
  applied.

### I/O

- **CSV export does not save the network Hz and baseMVA**
  (`net.tab_parameter.base`). A network exported and re-imported gets the
  defaults (`GUILDA.config("Model","Hz")`, 100 MVA).

### Compatibility

- Done: every compat hook in core code is a single line tagged
  `% COMPAT(v3)`, with the logic in `_GUILDAsystem/_VersionSupport/`
  (`grep -rn "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA`; see
  [v4-migration.md](v4-migration.md#4-compatibility-policy)).

### OPF

Requirements and roadmap: [opf-requirements.md](opf-requirements.md).
Step 1 (correctness of ELD, DC OPF and AC OPF) is done on
`fix/opf-correctness`:

- Fixed: AC OPF with a branch `Imax` or `Smax` stopped in fmincon (NaN
  derivative of `sqrt` at the zero start). The limits are now squared
  (`|I|^2 <= Imax^2`, `P^2+Q^2 <= Smax^2`) and branch-end variables start at
  the values of the initial bus voltages.
- Fixed: AC OPF with linear-only costs (`HP = HQ = 0`) failed inside
  fmincon; zero cost terms are no longer added to the objective.
- Checked, no change: ELD balance includes the loads; DC sign convention
  (power into a bus is `Im(Y_ij)*(θj-θi)`); slack-bus reference angle;
  generator Q limits; duals are labeled by constraint name, and the nodal
  price is `-lambda.Constraints.balancedP_<bus>` (verified against finite
  differences).
- Start point: bus `V0`/`Varg0` (flat by default). A power-flow warm start
  was measured and not adopted: it did not reduce iterations (9-bus 43 → 43,
  IEEE14 59 → 72) and `calculate_powerflow` may set the slack bus, which
  would edit the network.
- `DebugScript.run_all` on `fix/opf-correctness` (2026-10-29): 162 tests,
  PASS 160 / KNOWN 1 / FAIL 0 / SKIP 1 (the MATPOWER comparison). `run_all`
  reports a test as SKIP when it throws `DebugScript:Skip`.
- `tools.network_to_mpc` converts a network into a MATPOWER case. The
  MATPOWER comparison test reports SKIP when `runopf` is not on the path;
  it has not been run against a real MATPOWER installation yet. The
  case14 optimum (8081.53 / 7642.59 $/hr) is checked without MATPOWER.

Open:

- **DC susceptance convention.** GUILDA uses `b = Im(Y_ij)` (= `X/(R²+X²)`),
  MATPOWER and most textbooks use `1/X`. Results differ when `R ≠ 0`.
  Phase shifters are not modeled in DC OPF.
- **Load cost defaults.** `add_component` gives every component, including
  loads, `HP = fP = 1`. A fixed load's cost is a constant that is added to
  `r_cost`; finite differences of `r_cost` with respect to a load include it.
  `IEEE14bus` now gives its loads `HP = fP = 0` (see below); the
  `add_component` default is unchanged.
- **`IEEE14bus_lossless` still has the old IEEE14 data** (load Q sign, line
  charging, the shifted B values, ±Inf generator limits, 0.5–1.5 voltage
  limits, unit costs). Its transformer taps are read since the CSV fix
  (effect below).

### IEEE14 data and CSV taps

Fixed on `fix/ieee14-data-and-tap-import`:

- **CSV import reads transformer taps.** `CsvNetHandler.import` now reads the
  `tap`/`phase` columns that the bundled networks and `CsvNetHandler.export`
  write, and still accepts `Tap`/`Phase`; both spellings in one file is an
  error (`network:import_csv:DuplicateColumns`). Before, every imported tap
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
- **`IEEE14bus_lossless` changed through the tap fix only** (data
  untouched): bus voltages up to 0.016 pu (bus 5), angles 0.15°, bus
  reactive power up to 27.9 MVAr, slowest mode −0.332 → −0.385 (smallest
  damping ratio unchanged, 0.037); ω after a B008 fault differs by 1.5e-4
  (peak 1.6e-3); OPF costs unchanged. Decide whether to give it the case14
  data.
- `DebugScript.run_all` on `fix/ieee14-data-and-tap-import` (2026-10-29):
  165 tests, PASS 163 / KNOWN 1 / FAIL 0 / SKIP 1 (the MATPOWER comparison).

### Analysis API foundation

- Added `AnalysisResult` (result base class), `tools.resolve_options`
  (solver defaults + Name-Value overrides) and `legacy_output` (old output
  tuples). No analysis method uses them yet; power flow, OPF, CPF,
  simulation, linearization and I/O move to the v4 API next.
- `odeSimulationResult` does not inherit from `AnalysisResult` yet.
- A result does not record whether the network was edited after the
  analysis: `tab_editLog` is cleared by `initialize`, so it cannot serve as a
  stamp.
