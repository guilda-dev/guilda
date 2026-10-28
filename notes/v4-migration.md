# Migrating to GUILDA v4

Status: work in progress on `refactor/design-alignment` (base: `version4.0`).
Breaking changes are allowed in v4. Section 1 lists what has already
changed; section 3 lists changes that are **planned but not implemented**.

Reference designs: `_GUILDAdoc/developer/class-design.html` and
`api-design.html` on branch `docs/doc-refactoring`.

---

## 1. Changes so far — script authors

### 1.1 Nominal frequency and system base belong to the network

The network holds `Hz` and `baseMVA` in `net.tab_parameter.base`
(`net.para_base`). Components no longer have their own `Hz`, and buses no
longer have an operation `baseMVA`.

```matlab
% old
comp.tab_parameter.base.Hz          % or comp.para_base.Hz
comp.para_base.Hz = 50;
net.add_bus("baseMVA", 100, ...)

% new
net.tab_parameter.base.Hz           % read / write: whole network
net.tab_parameter.base.Hz = 50;
net.tab_parameter.base.baseMVA = 100;
comp.r_Hz                           % read-only: frequency of the network the object belongs to
net.add_bus(...)                    % no baseMVA option
```

- `r_Hz` falls back to `GUILDA.config("Model","Hz")` for an object that is
  not attached to a network.
- CSV import accepts and ignores a `baseMVA` column; CSV export no longer
  writes it.
- Removed without replacement: `rv_odeInit` (PowerNetwork, Bus) and
  `Bus.rv_odeX0`.

### 1.2 Equilibrium V is owned by the bus, I by the components

- `Bus.c_Iequilibrium` is now Dependent: the sum of its components'
  currents.
- `Component.c_Vequilibrium` reads its bus; `LocalController.c_Vequilibrium`
  / `c_Iequilibrium` read the parent.
- Do not write copies of the voltage into a component or controller.

### 1.3 Edit tracking and the stale-equilibrium error

Every parameter or topology edit is logged and records what it made stale:

| Edit                                   | f_* handles | equilibrium |
|----------------------------------------|-------------|-------------|
| `Parameter(dynamics)`                  | stale       | stale       |
| `Parameter(base)` (network Hz, baseMVA)| stale (every layer) | stale |
| `Parameter(powerflow)`, `Topology`, `Slack` | –      | stale       |
| `Parameter(operation/OPF/graph)`       | –           | –           |

`initialize`, `simulate` and `get_sys` rebuild stale `f_*` handles, so
dynamics edits now take effect without rebuilding the model. When the
equilibrium is stale, `simulate` and `get_sys` stop with
`GUILDA:PowerNetwork:EquilibriumStale`:

```matlab
net.a_Bus{2}.tab_parameter.powerflow.V = 1.02;
net.simulate([0 10]);        % error GUILDA:PowerNetwork:EquilibriumStale
net.initialize();
net.simulate([0 10]);        % OK
```

Scripts that edited parameters and relied on the old (unchanged) equilibrium
must now call `net.initialize()` after the edit.

### 1.4 Topology methods

```matlab
net.remove_bus("B003")                           % error if branches are connected
net.remove_bus("B003", "RemoveBranches", true)   % also removes those branches
net.remove_global_controller("agc")
bus = net.add_bus(...)                           % skips tag numbers still in use
new = bus.replace_component(...)                 % now returns the new component
net.add_branch(Type, ["B001","B002"], ...)       % buses may be given by tag
```

- `remove_bus` refuses a bus whose components a global controller controls.
- `remove_component`, `replace_component`, `remove_branch`, `remove_bus`
  and `remove_global_controller` detach the removed object: it no longer
  refers to the old bus or network.
- Buses are created with their network: `Bus(net, tag, opt)`. The separate
  `set_network` step after construction and `reset_odeset` (Bus, Branch,
  PowerNetwork) are gone.

### 1.5 Single slack bus

The network keeps exactly one slack bus. Setting `bus.l_isSlack = true`
releases the other slack buses (also before the first `initialize`).
Setting it to `false` now releases the bus instead of being ignored.

```matlab
net.a_Bus{3}.l_isSlack = true;   % bus 1 is no longer slack
```

### 1.6 Global controllers

Any number of global controllers is supported: `initialize`, `simulate` and
all `get_sys` algorithms (Kron, DAE, Feedback) handle every controller.
Outputs of several controllers on the same input add up. Scalar `alpha` /
`beta` of the AGC are expanded to every controlled unit.

### 1.7 Power flow, OPF, simulation

- `net.initialize("methods", "calculate from Xequilibrium")` works, and
  the dynamic power flow holds PV bus voltages at their set values.
- `Continuation_Power_Flow(net, opt)` passes its options to
  `ContinuationPowerFlow` as name-value pairs (wrapper in `_VersionSupport/`).
- OPF (ELD, DC, AC) works again. Load P/Q are fixed to their power-flow
  settings (they are not dispatched). Branch end variables are named
  `"<branch>_<bus>"` (no cubicle). Branch limits use `Smax`, `Imax`, `Pmax`,
  `Qmax`, `Vargmax`.
- Network CSV files whose `Pmin`/`Qmin` were saved as `#NAME?` (Excel's
  broken `-Inf`) are fixed in the shipped networks; check your own CSVs.
- `simulate` works without events, clears previous phase results, keeps
  phases inside the requested time range, applies offset state events that
  start after t = 0, and matches event offsets / inputs by name (summed per
  unit). Input functions receive the time since the event start.

### 1.8 Startup

`GUILDA` starts in `matlab -batch` (no desktop); the tutorial is not opened
there.

---

## 2. Changes so far — model authors

- **Function signatures.** `fcn_dx`, `fcn_I`, `fcn_Y`, `fcn_Mass` take
  `(obj, t, x, V, I, u, param, omega0)`. Declare them with `omega0` in the
  `classdef` too.
- **`omega0` is the nominal frequency in Hz**, not rad/s. Multiply by
  `2*pi` inside the model where needed. It is the network's `r_Hz`.
- **Parameters are on the system base** (`net.tab_parameter.base.baseMVA`).
  There is no per-bus or per-component base.
- **Analytic Jacobians** are `Static` methods named exactly `Jacobi_dx`,
  `Jacobi_I`, `Jacobi_Y`, declared in `methods (Static)` and implemented in
  files with the same names (case matters: `Jacobi_Y`, not `Jacobi_y`):

  ```matlab
  methods (Static)
      [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
      [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
      [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
  end
  ```

  A missing Jacobian falls back to a numerical one (`Jacobi_*_num`).
  `get_sys` and `odeSimulator` use the same `f_Jacobi*` handles.
- **The old `getJacobiAxx` / `getJacobiBxu` / … style is no longer used.**
  Per-matrix files are ignored; port them to the three `Jacobi_*` methods.
- **Frequency inside a model:** read `obj.r_Hz`, never a fixed `60` or a
  component `para_base`.
- **Equilibrium:** `get_equilibrium(obj, c_V, c_I, r_P, r_Q)`; do not store
  copies of V or I (see 1.2).
- **Controllers:** local controllers receive their parent through
  `set_parent`; a PSS is attached to its AVR. Global controllers are
  coupled to components by port names (`sv_u` / `sv_y`).

---

## 3. Planned v4 API changes (not implemented yet)

- **Result classes:** `PowerFlowResult`, `OPFResult`, `CPFResult`, and
  `odeSimulationResult` for simulations.
- **Outputs** of analysis methods: `[result, flag, output]`.
- **Common Name-Value options** in UpperCamelCase: `Method`, `Tolerance`,
  `MaxIteration`, `Solver`, `TimeLimit`, `Verbose`, `Progress`, `Plot`,
  `Export`. `net.solver_*` keep persistent defaults; per-call options
  override them.
- **Method names** `net.verb_noun`, e.g. `net.calculate_continuation_powerflow`.
- **I/O:** `PowerNetwork.import_csv`, `PowerNetwork.import_matpower`,
  `net.export_csv`.
- **Plot / Export** become methods of the result classes.

---

## 4. Compatibility policy

- Breaking changes are acceptable. Compatibility is added only where it is
  easy.
- **All compatibility code lives in `_GUILDAsystem/_VersionSupport/`.**
- A hook in core code is **a single line tagged `% COMPAT(v3)`** that calls
  into `_VersionSupport/`.
- Deprecated forms warn once per MATLAB session through
  `_VersionSupport/Deprecated.m` with ID `GUILDA:Deprecated:<Key>`; texts in
  `SystemTools/GUILDA/en/Deprecated.xml`.
  - Silence: `warning("off", "GUILDA:Deprecated:<Key>")`
  - Show again: `clear Deprecated`

### Deprecated forms

| Old form | ID | Behavior |
|----------|----|----------|
| read `comp.tab_parameter.base.Hz` / `comp.para_base.Hz` | `GUILDA:Deprecated:ComponentBaseHz` | warning; returns the network Hz (`ComponentBaseView`) |
| set `comp.tab_parameter.base.Hz` / `comp.para_base.Hz` | `GUILDA:Deprecated:ComponentBaseHzSet` | warning; sets `net.tab_parameter.base.Hz` for the **whole network** |
| set it on a component without a network | `GUILDA:Deprecated:ComponentBaseHzNoNetwork` | error |
| assign a non-view value to `comp.para_base` | `GUILDA:Deprecated:ComponentBaseHz` | error |
| `net.add_bus(..., "baseMVA", x)` with x = system base | `GUILDA:Deprecated:BusBaseMVA` | warning; ignored |
| `net.add_bus(..., "baseMVA", x)` with x ≠ system base | `GUILDA:Deprecated:BusBaseMVAMismatch` | warning; ignored, system base used |
| `Continuation_Power_Flow(net, opt)` | – | wrapper for `ContinuationPowerFlow` (no warning) |

### Current hooks (to be aligned)

The existing hooks do not yet follow the one-line `% COMPAT(v3)` rule:

- `_GUILDAsystem/@Component/Component.m`: `para_base` property, its get/set
  methods and the `base` column of `tab_parameter` (`ComponentBaseView`).
- `_GUILDAsystem/@PowerNetwork/add_bus.m`: the `baseMVA` option and the
  `Deprecated("BusBaseMVA…")` calls.

### Removing compat code later

1. Delete `_GUILDAsystem/_VersionSupport/` (or the files for the version
   being dropped) and the `Deprecated` entries in `Deprecated.xml`.
2. Search for `COMPAT(v3)` and delete every tagged line:
   `grep -rn "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA`.
3. Remove `_VersionSupport` from `@GUILDA/config/ListPath.txt` if nothing is
   left in it.
4. Run `DebugScript.run_all`; tests that check deprecated forms are removed
   with the compat code.
