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

### Analysis API foundation

- Added `AnalysisResult` (result base class), `tools.resolve_options`
  (solver defaults + Name-Value overrides) and `legacy_output` (old output
  tuples). No analysis method uses them yet; power flow, OPF, CPF,
  simulation, linearization and I/O move to the v4 API next.
- `odeSimulationResult` does not inherit from `AnalysisResult` yet.
- A result does not record whether the network was edited after the
  analysis: `tab_editLog` is cleared by `initialize`, so it cannot serve as a
  stamp.
