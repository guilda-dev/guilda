# Migrating to GUILDA v4

Status: work in progress on `refactor/design-alignment` (base: `version4.0`),
checked against the code at `be166af`. Breaking changes are allowed in v4.
Section 1 lists what has changed for scripts (1.7–1.15: the v4 analysis API
of stages 2 and 3); section 2 for models; section 3 what is still planned.

Reference designs: `_GUILDAdoc/developer/class-design.html` and
`api-design.html` on branch `docs/doc-refactoring`.

> **Silent breaking changes.** These run without an error or a warning but
> give a different meaning or different numbers. Check every script that
> uses them.
>
> - **`simulate`'s second output is inverted.** v3: `true` when the run
>   stopped early. v4: `flag = 1` completed, `0` stopped by `TimeLimit`,
>   `-1` stopped by the solver. `if flag` is now true for a completed run
>   **and** for a solver stop; test `flag < 1` for "stopped early" (1.11).
> - **`get_sys`'s second output is no longer `lin`.** `[sys, flag, output]`:
>   `flag` is a logical (all Jacobian entries finite) and
>   `output.result` is the `LinearizationResult`. `[sys, lin] = net.get_sys()`
>   gives no error; using `lin` as an `odeLinearizer` fails later (1.12).
> - **`optimize_powerflow` with 1–3 outputs has the v4 meaning.**
>   `[bus, cub, flag] = net.optimize_powerflow()` now gives
>   `bus = OPFResult`, `cub = flag`, `flag = output`. Only the 6-output form
>   returns the old tuple (with a warning) (1.9).
> - **DAE `B` sign.** `get_sys(Algorithm="DAE")` / `get_ss("DAE")` returns
>   `B` with the opposite sign on the algebraic rows (the bus current
>   balance). v3 had the wrong sign there, so its DAE model did not match
>   Kron (1.12).
> - **IEEE14bus numbers.** `network.IEEE14bus` now has the MATPOWER case14
>   data and CSV import reads transformer taps, so power flow, OPF,
>   simulation and linearization results of IEEE14bus (and, through the
>   taps, `IEEE14bus_lossless`) differ from v3 (1.15).

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

### 1.7 The v4 analysis API (common to 1.8–1.12)

Every analysis is a method `net.verb_noun(Name, Value)` that returns
`[result, flag, output]`:

- `result` is a result object (subclass of `AnalysisResult`):
  `PowerFlowResult`, `OPFResult`, `CPFResult`, `odeSimulationResult`,
  `LinearizationResult`. It holds the computed values, `flag`, `output`,
  `options` (the effective settings), `str_solver`, `r_elapsed`,
  `str_network`, `a_PowerNetwork` and `l_success`. Model data stay with the
  network.
- `flag` keeps the solver's exit flag where there is one; `output.message`
  describes the outcome.
- Name-Value options (UpperCamelCase) override the defaults in
  `net.solver_*` **for this call only**; `net.solver_*` is not changed. Edit
  `net.solver_*` to change the defaults for later calls. An unknown name
  stops with `GUILDA:resolve_options:UnknownName`, which lists the accepted
  names.
- Plotting and writing files are methods of the result: `result.Plot()`,
  `result.Export(filename)`, or the options `Plot=true` /
  `Export=true|filename` of the analysis call. A relative file name is
  relative to the **current folder** (v3 wrote to `GUILDA.pwd`).
- The solvers hold defaults only: they no longer keep the network, the last
  result or intermediate data (see each section for removed properties).
- `net.solver_LIN` (`odeLinearizer`) is new; `reset_solver` creates all
  five solvers.

### 1.8 Power flow

| v3 | v4 |
|----|----|
| `tab = net.calculate_powerflow()` | `res = net.calculate_powerflow(); tab = res.tab_bus` |
| `[tab, flag, output] = net.calculate_powerflow("dynamic")` | `[res, flag, output] = net.calculate_powerflow(Method="dynamic")` |
| `net.calculate_powerflow("dynamic", "export", true, "filename", f)` | `net.calculate_powerflow(Method="dynamic", Export=f)` or `res.Export(f)` (`.json`) |
| `net.solver_PF.rm_response`, `rr_step`, `i_iteration` | `res.cm_Vhistory`, `res.rv_step` |

- Options: `Method` (`"algebraic"` | `"dynamic"`), `Tolerance`,
  `MaxIteration` (solver property `MaxIterations`), `Verbose` (sets
  `Display`), `Plot`, `Export`. New solver properties `solver_PF.Method`
  (default `"algebraic"`) and `solver_PF.Tolerance` (0 = fsolve default).
- `PowerFlowResult`: `tab_bus` (Varg, V, P, Q, Vphasor, Iphasor per bus;
  the old output table), `tab_branch` (branch flows), `cm_Vhistory`,
  `rv_step`; `Plot` draws the voltage profile, `Export` writes the bus or
  branch table (`.csv`, Excel) or the history (`.json`, GridSpring viewer).
- Behavior: `Method="dynamic"` no longer writes the JSON history by default
  (v3 did). The network is not changed, except that the first bus becomes
  the slack bus when none is set (as in v3).
- Deprecated, still working:

  | Old form | Warning ID |
  |----------|------------|
  | positional mode `calculate_powerflow("dynamic", ...)` | `GUILDA:Deprecated:CalculatePowerflowMode` |
  | options `"export"` / `"filename"` (with the positional mode or `"filename"`) | `GUILDA:Deprecated:CalculatePowerflowExport` |

  The old export keeps the v3 default file name
  `<yyMMdd_HHmmss>_PFcalculation.json`, now in `GUILDA.pwd` explicitly.
  `"export"` alone is read as the v4 option `Export`.
- Fixed earlier (stage 1): `net.initialize("methods", "calculate from
  Xequilibrium")` works, and the dynamic power flow holds PV bus voltages at
  their set values.

### 1.9 Optimal power flow

| v3 | v4 |
|----|----|
| `[bus, cub, flag, output, lambda, prob] = net.optimize_powerflow("methods", "DC OPF")` | `[res, flag, output] = net.optimize_powerflow(Method="DC OPF")` |
| `bus`, `cub`, `lambda`, `prob` | `res.tab_bus`, `res.tab_cub`, `res.lambda`, `res.OPFprob` |
| (cost computed by hand) | `res.r_cost`; branch flows `res.tab_branch` |

- Options: `Method` (`"ELD"` | `"DC OPF"` | `"AC OPF"`, default
  `"AC OPF"`), `Solver` (`"auto"` | `"linprog"` | `"quadprog"` |
  `"fmincon"`), `Tolerance` (`OptimalityTolerance`), `MaxIteration`,
  `Verbose` (sets `Display`), `Plot`, `Export`. Defaults in
  `net.solver_OPF` (`OptimalPowerFlow`, new; it was empty in v3).
- `OPFResult`: `Plot` draws the component outputs and, for DC/AC OPF, the
  bus voltages; `Export` writes the bus, connection or branch table.
  `l_success` is true for a positive exit flag. The nodal price of a bus is
  `-res.lambda.Constraints.balancedP_<bus>`.
- **Output count decides the form** (silent change): only 6 outputs return
  the v3 tuple; 1–3 outputs get the v4 meaning; 4 or 5 outputs are an error
  (too many outputs).
- Deprecated, still working:

  | Old form | Warning ID |
  |----------|------------|
  | 6 outputs `[bus, cub, flag, output, lambda, prob] = ...` | `GUILDA:Deprecated:OptimizePowerflowTuple` |
  | option `"methods"` | `GUILDA:Deprecated:OptimizePowerflowMethods` |

- `net.build_opf_problem` keeps its option name `methods` (not renamed).
- Fixes (stage 1 and OPF step 1, see [status.md](status.md#opf)): ELD, DC
  and AC OPF run again; loads keep their power-flow P and Q (not
  dispatched); branch-end variables are `"<branch>_<bus>"`; branch limits
  `Smax`, `Imax`, `Pmax`, `Qmax`, `Vargmax`, with `Imax`/`Smax` applied
  squared; zero cost terms are left out of the objective; branch-end
  variables start at the initial bus voltages. Shipped CSVs whose
  `Pmin`/`Qmin` were `#NAME?` (Excel's `-Inf`) are fixed; check your own.
- New `tools.network_to_mpc(net)` converts a network into a MATPOWER case.

### 1.10 Continuation power flow

| v3 | v4 |
|----|----|
| `cpf = Continuation_Power_Flow(net, struct("CPFBus", b)); [sol, pred] = cpf.solve;` | `[res, flag, output] = net.calculate_continuation_powerflow(LoadBus=b)` |
| `cpf = ContinuationPowerFlow(net, "CPFBus", b)` | error; use the line above |
| `cpf.CPF_Result.x_sol` / `x_prd` | `res.rm_x` / `res.rm_xPredicted` (full variable layout, lambda in the last row) |
| (read from `x_sol`) | `res.rv_lambda`, `res.cm_Vbus`, `res.sv_bus`, `res.r_lambdaMax`, `res.r_noseStep`, `res.tab_nose`, `res.tab_path` |

Option names:

| v3 (`CPF*` property) | v4 option | `net.solver_CPF` property |
|----------------------|-----------|---------------------------|
| `CPFBus` | `LoadBus` | `LoadBus` |
| `CPFInitLam` | `InitialLambda` | `InitialLambda` |
| `CPFMaxIter` | `MaxIteration` | `MaxIterations` |
| `CPFStepSize` | `StepSize` | `StepSize` |
| `CPFArcL` | `ArcLength` | `ArcLength` |
| `CPFUseInternal` | `UseInternalState` | `UseInternalState` |
| – | `Tolerance` (default 1e-5), `Verbose`, `Plot`, `Export` | `Tolerance`, `Verbose` |
| `CPFFcn`, `CPFJac`, `CPFInitVal` | not supported | – |

- `flag` is a logical: true when the path passed the nose. `output` has
  `message`, `iterations`, `correctorIterations`.
- `CPFResult.Plot` draws the PV curves of the load buses; `Export` writes
  the path table.
- Behavior: the network must be initialized (an error names the remedy);
  an empty or unknown `LoadBus` is an error (v3 warned for an empty bus
  list). `ContinuationPowerFlow()` takes no arguments and holds defaults
  only.
- Deprecated:

  | Old form | ID | Behavior |
  |----------|----|----------|
  | `Continuation_Power_Flow(net, opt)` | `GUILDA:Deprecated:ContinuationPowerFlowFunction` | warning; returns a `ContinuationPowerFlowV3` with the v3 properties, `solve` and `CPF_Result` (`.x_sol`, `.x_prd`, `.result` = the `CPFResult`); `net.solver_CPF` is not changed |
  | `ContinuationPowerFlow(net, Name, Value)` | `GUILDA:Deprecated:ContinuationPowerFlowConstructor` | **error** |

  `sol` / `sol_pred` of the wrapper are in the full variable layout (as
  `CPF_Result.x_sol`).

### 1.11 Time simulation

| v3 | v4 |
|----|----|
| `[out, l_stop] = net.simulate(t, ev1, ev2)` | `[res, flag, output] = net.simulate(t, ev1, ev2)` |
| `if l_stop` (stopped early) | `if flag < 1` (`0` TimeLimit, `-1` solver stop) |
| `net.solver_ODE.Reporter = "none"; net.simulate(t, ev)` | `net.simulate(t, ev, Progress="none")` (one call) or `net.solver_ODE.Progress = "none"` |
| `net.solver_ODE.RelativeTolerance = 1e-6; ...` | `net.simulate(t, ev, Tolerance=1e-6)` (the property keeps its name) |
| `out.odeNetwork` | `res.a_PowerNetwork` |

- Options after the events: `Solver` (MATLAB `ode` solver, default
  `"ode15s"`), `SolverOptions`, `Tolerance` (`RelativeTolerance`),
  `AbsoluteTolerance`, `SeparateComplexParts`, `TimeLimit`, `Progress`
  (`"dialog"` | `"disp"` | `"none"`, or true/false), `Verbose`, `Plot`,
  `Export`. New solver properties `Solver`, `SolverOptions`, `Progress`,
  `Verbose`, `Plot`.
- `odeSimulationResult`: `odeResults` keeps its layout
  (`res.odeResults.Bus(i).Component(j).X.omega`, `.t`); new `sv_bus`,
  `c_component`, `Plot(Quantity=...)`, `Export` (`.csv`/`.xlsx` table, or
  `.mat` with `odeResults`, `options`, `flag`, `output`); `odeNetwork` is
  removed. `output` has `message`, `tEnd`, `phases`, `nPhases`,
  `nPhasesDone`.
- Behavior:
  - **flag** (silent change, see the box at the top).
  - On a stop the result holds the trajectories up to `output.tEnd`.
  - `TimeLimit` is the wall-clock limit **of each phase** (between event
    times), not of the whole run.
  - `odeSimulator` no longer holds `odeNetwork`, `odeTimeTable`, `odeYmat`,
    `odeResult`, `rv_odeV`; `solver_ODE.simulate(net, ...)` is replaced by
    the internal `solve(net, time, events, options)`.
- Deprecated, still working:

  | Old form | Warning ID |
  |----------|------------|
  | `net.solver_ODE.Reporter = v` (read returns `Progress`, no warning) | `GUILDA:Deprecated:SimulatorReporter` |
  | `simulate(..., "Reporter", v)` / `"RelativeTolerance", v` | `GUILDA:Deprecated:SimulateOptionName` |

- Fixed earlier (stage 1): `simulate` works without events, clears previous
  phase results, keeps phases inside the requested time range, applies
  offset state events that start after t = 0, and matches event offsets /
  inputs by name (summed per unit). Input functions receive the time since
  the event start.

### 1.12 Linearization

| v3 | v4 |
|----|----|
| `[sys, lin] = net.get_sys(NonUnit=n, Algorithm=a)` | `sys = net.get_sys(NonUnit=n, Algorithm=a)`; `[sys, flag, output] = ...`, `output.result` is the `LinearizationResult` |
| `lin = odeLinearizer(net, n, Algorithm=a); sys = lin.get_sys` | `res = net.linearize(NonUnit=n); sys = res.get_ss(a)` |
| `lin.Kxx`, `lin.Kxv`, `lin.Kvx`, `lin.Kvv`, `lin.get_DAE` | `res.rm_Axx`, `rm_Axv`, `rm_Bx`, `rm_Avx`, `rm_Avv`, `rm_Bv`, `rm_E` (unreduced DAE in the order of `res.tab_variable`) |
| – | `net.linearize(Point=x)` or `Point={sim, t}`: linearize away from the equilibrium |
| – | `net.get_variable_map()`, `bus.get_variable_map()`, `comp.get_variable_map()` |

- Options: `Algorithm` (`"Kron"` | `"Feedback"` | `"DAE"`, default
  `"Feedback"` as in v3), `NonUnit`, `Point`, `Plot` (eigenvalue map).
  Defaults in `net.solver_LIN`.
- `res.get_ss(Algorithm)` gives the same A, E, C, D and names as v3
  `get_sys` for every algorithm (checked against a copy of the v3 code in
  F7); `get_ss("DAE", Coordinate=...)` chooses `"theta&rho"` (default),
  `"theta&V"` or `"Vre&Vim"` for the bus variables.
- **DAE `B` sign** (silent change): the rows of the algebraic equations
  have the opposite sign; the input-to-state transfer function of the DAE
  model now equals that of Kron.
- `flag` is true when all Jacobian entries are finite; `output` has
  `message`, `l_equilibrium`, `n_x`, `n_v`, `n_u`, `rcond_Avv`.
- `NonUnit` is no longer written to `bus.l_isNonUnit`; the network is not
  changed. `Point={sim, t}` stops with
  `GUILDA:odeLinearizer:PointUnavailable` when the layer has local or
  global controllers (the simulation result does not store their states).
- Removed: `odeLinearizer(net, NonUnit, Name, Value)` stops with
  `GUILDA:Deprecated:OdeLinearizerConstructor` (error); `odeLinearizer()`
  takes no arguments.

### 1.13 Network files (CSV, MATPOWER)

| v3 | v4 |
|----|----|
| `net = CsvNetHandler.import(path)` | `net = PowerNetwork.import_csv(path)` |
| `CsvNetHandler.import(path, obj)` (network class constructor) | `PowerNetwork.import_csv(path, Network=obj)` |
| `CsvNetHandler.export(net, "MyNet", savepath=d)` | `net.export_csv(fullfile(d, "@MyNet"))` |
| – | `net = PowerNetwork.import_matpower(mpc)` (`"case14"`, a struct, a file or a function handle) |

- `import_csv` options: `Initialize` (default true), `Network`.
  `export_csv` options: `Overwrite` (an existing folder is otherwise an
  error, `GUILDA:export_csv:FolderExists`), `ClassFile` (default: when the
  folder name starts with `@`).
- Folder format: `network/parameter.csv` holds `Hz` and `baseMVA`; the bus
  column `Slack` marks the slack bus. Folders written before v4 (no
  `network/parameter.csv`) import with the defaults
  (`GUILDA.config("Model","Hz")`, 100 MVA); a bus column `baseMVA` is
  ignored. Equilibria and controllers are not saved.
- CSV import reads the branch columns `tap`/`phase` (as export writes
  them) and `Tap`/`Phase`; both in one file is an error. v3 read only
  `Tap`/`Phase`, so every imported transformer tap was 1.
- `import_matpower` is the inverse of `tools.network_to_mpc`; MATPOWER is
  not needed. Options `GeneratorModel`, `GeneratorParameter`, `LoadModel`,
  `Hz`, `Tag`, `Initialize`. Isolated buses, piecewise-linear and
  higher-degree costs are not supported.
- Deprecated, still working:

  | Old form | Warning ID |
  |----------|------------|
  | `CsvNetHandler.import(path, net, Initialize=tf)` | `GUILDA:Deprecated:CsvNetHandlerImport` |
  | `CsvNetHandler.export(net, ModelName, savepath=d, Overwrite=tf, version=v)` | `GUILDA:Deprecated:CsvNetHandlerExport` |

  `CsvNetHandler` now lives in `_VersionSupport/`. The bundled network
  classes call `PowerNetwork.import_csv(..., Network=obj)`; your own
  network classes that call `CsvNetHandler.import` warn once.

### 1.14 Required toolboxes

- Required: MATLAB, Control System Toolbox, Optimization Toolbox.
- **Symbolic Math Toolbox is optional.** No runtime code uses it
  (`ListToolbox.txt` no longer lists it; a test checks it).
  `NewtonRaphsonMethod` still accepts a symbolic `NRMFcn` when the toolbox
  is installed; without it this stops with
  `GUILDA:NewtonRaphsonMethod:SymbolicUnavailable` (pass a function handle,
  optionally `NRMJac`). A few developer scripts that check hand-written
  Jacobians (`validate.m` of loads and controllers, the unreleased
  `vsm1axis`) still need it.

### 1.15 Bundled networks

- **`network.IEEE14bus` matches MATPOWER `case14`** (100 MVA): line
  charging, load reactive power sign, bus voltage limits 0.94–1.06,
  generator limits and costs; loads have no OPF cost. Its transformer taps
  are read (1.13). All IEEE14bus results change (power flow, OPF,
  simulation, eigenvalues); the measured differences are in
  [status.md](status.md#ieee14-data-and-csv-taps).
- **New `network.IEEE14bus_NoTap`**: `IEEE14bus` with the transformers
  4-7, 4-9 and 5-6 at tap 1, phase 0.
- **`IEEE14bus_lossless`** keeps the old data but its taps are now read,
  so its results change too.
- There is no network with the v3 IEEE14 data; keep a copy of a v3 export
  to reproduce old results.

### 1.16 Startup

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
- **Variable map.** `net.get_variable_map()` (and `bus.` / `comp.`) is the
  single definition of the variable order: states (per bus, per component,
  then its local controllers depth first; then the global controllers),
  bus voltages `Vre`, `Vim` interleaved per bus, then the inputs. The
  `Label` column equals the StateName / InputName of `get_sys`. Do not
  rely on any other ordering.
- **Hessians (optional).** `get_hessian` on `Component`, `LocalController`
  and `GlobalController` defines the contract: a class that supports it
  adds static `Hessian_dx` (required), `Hessian_I`, `Hessian_Y` with the
  arguments of `Jacobi_*`, returning `n_eq x n_z x n_z` with
  `z = [x; V; I; u]`. No shipped model implements it yet; other classes
  stop with `GUILDA:Component:HessianNotSupported`. No symbolic
  differentiation is used.

---

## 3. Planned v4 API changes (not implemented yet)

Everything that was listed here is implemented (sections 1.7–1.13): result
classes, `[result, flag, output]`, UpperCamelCase Name-Value options over
`net.solver_*` defaults, `net.calculate_continuation_powerflow`,
`PowerNetwork.import_csv` / `import_matpower`, `net.export_csv`, and
`Plot` / `Export` as result methods. Open follow-ups (e.g. aligning
simulation results with `get_variable_map`) are in
[status.md](status.md#open-items).

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
| `calculate_powerflow(mode, ...)` (positional `"algebraic"` / `"dynamic"`) | `GUILDA:Deprecated:CalculatePowerflowMode` | warning; becomes `Method=mode` |
| `calculate_powerflow(..., "export", l, "filename", f)` | `GUILDA:Deprecated:CalculatePowerflowExport` | warning; becomes `Export=fullfile(GUILDA.pwd, f)` |
| `optimize_powerflow("methods", m)` | `GUILDA:Deprecated:OptimizePowerflowMethods` | warning; becomes `Method=m` |
| 6 outputs of `optimize_powerflow` | `GUILDA:Deprecated:OptimizePowerflowTuple` | warning; returns `{tab_bus, tab_cub, flag, output, lambda, OPFprob}` |
| `Continuation_Power_Flow(net, opt)` | `GUILDA:Deprecated:ContinuationPowerFlowFunction` | warning; returns a `ContinuationPowerFlowV3` (v3 properties, `solve`, `CPF_Result`) |
| `ContinuationPowerFlow(net, Name, Value)` | `GUILDA:Deprecated:ContinuationPowerFlowConstructor` | error |
| set `net.solver_ODE.Reporter` | `GUILDA:Deprecated:SimulatorReporter` | warning; sets `Progress` (reading `Reporter` returns `Progress`, no warning) |
| `simulate(..., "Reporter", v)` / `"RelativeTolerance", v` | `GUILDA:Deprecated:SimulateOptionName` | warning; becomes `Progress` / `Tolerance` |
| `odeLinearizer(net, NonUnit, Name, Value)` | `GUILDA:Deprecated:OdeLinearizerConstructor` | error |
| `CsvNetHandler.import(path, net, Initialize=tf)` | `GUILDA:Deprecated:CsvNetHandlerImport` | warning; calls `PowerNetwork.import_csv` |
| `CsvNetHandler.export(net, ModelName, savepath=d)` | `GUILDA:Deprecated:CsvNetHandlerExport` | warning; calls `net.export_csv(fullfile(d, "@"+ModelName))` |

Not kept: the v3 second output `lin` of `get_sys` and the v3 meaning of the
second output of `simulate` (see the box at the top).

### Hooks

Core code reaches compatibility code only through single lines tagged
`% COMPAT(v3)`. `grep -rn "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA`
lists all of them:

| File | Line | Hook |
|------|------|------|
| `@Component/Component.m` | `para_base` property | deprecated `ComponentBaseView` property |
| `@Component/Component.m` | `get.para_base` | returns `ComponentBaseView(obj)` |
| `@Component/Component.m` | `get.tab_parameter` | `ComponentBaseView.add_column`: adds the `base` column |
| `@Component/Component.m` | `set.para_base` | `ComponentBaseView.check_assign`: accepts only the view |
| `@Component/Component.m` | `set.tab_parameter` | `ComponentBaseView.remove_column`: drops the `base` column |
| `@PowerNetwork/add_bus.m` | `opt.baseMVA` argument | accepts the old option |
| `@PowerNetwork/add_bus.m` | `v3_bus_baseMVA(obj, opt)` | warns and removes the option |
| `@PowerNetwork/calculate_powerflow.m` | `v3_powerflow_args(varargin)` | positional mode, `export` / `filename` |
| `@PowerNetwork/optimize_powerflow.m` | `v3_opf_args(varargin)` | `methods` option |
| `@PowerNetwork/optimize_powerflow.m` | `legacy_output(..., 6, @v3_optimize_powerflow, ...)` | 6-output tuple |
| `@PowerNetwork/simulate.m` | `v3_simulate_args(c_nv)` | option names `Reporter`, `RelativeTolerance` |
| `_auxiliary/@odeSimulator/odeSimulator.m` | `Reporter` property (Dependent, Hidden) | old name of `Progress` |
| `_auxiliary/@odeSimulator/odeSimulator.m` | `get.Reporter` | returns `Progress` |
| `_auxiliary/@odeSimulator/odeSimulator.m` | `set.Reporter` | `v3_ode_reporter`: warns, sets `Progress` |
| `_auxiliary/@ContinuationPowerFlow/ContinuationPowerFlow.m` | `v3_cpf_constructor(varargin)` | rejects v3 constructor arguments |
| `_auxiliary/@odeLinearizer/odeLinearizer.m` | `v3_linearizer_constructor(varargin)` | rejects v3 constructor arguments |

`DebugScript.test_F10_api_foundation` checks this list and that core code
does not call `Deprecated` outside a hook line. Update both when a hook is
added.

That is 16 hooked lines (the F10 test checks the count per file).
`Continuation_Power_Flow` and `CsvNetHandler` are old names; they live
entirely in `_VersionSupport/` and need no hook. CSV import ignores a bus
`baseMVA` column simply by not reading it (no compat code).

### Contents of `_GUILDAsystem/_VersionSupport/`

| File | Purpose |
|------|---------|
| `Deprecated.m` | warning once per session, `GUILDA:Deprecated:<Key>` (convention in its header) |
| `legacy_output.m` | returns the old output tuple when `nargout` matches the old signature |
| `ComponentBaseView.m` | deprecated `comp.para_base` / `comp.tab_parameter.base` view and its hook helpers |
| `v3_bus_baseMVA.m` | `add_bus` `baseMVA` option |
| `Continuation_Power_Flow.m` | old CPF entry point (returns `ContinuationPowerFlowV3`) |
| `ContinuationPowerFlowV3.m` | v3 CPF object: `CPF*` properties, `solve`, `CPF_Result` |
| `@CsvNetHandler/` | old CSV import / export, wrappers of `import_csv` / `export_csv` |
| `v3_powerflow_args.m` | `calculate_powerflow` positional mode and `export` / `filename` |
| `v3_opf_args.m` | `optimize_powerflow` `methods` option |
| `v3_optimize_powerflow.m` | v4 outputs → the v3 6-output tuple |
| `v3_cpf_constructor.m` | error for `ContinuationPowerFlow(net, ...)` |
| `v3_simulate_args.m` | `simulate` option names `Reporter`, `RelativeTolerance` |
| `v3_ode_reporter.m` | `solver_ODE.Reporter` setter |
| `v3_linearizer_constructor.m` | error for `odeLinearizer(net, ...)` |

### Adding a compat form (stages 2 and 3)

1. Put the logic in a file in `_VersionSupport/` (a wrapper for an old name,
   or a helper the hook calls). Name helpers `v3_<what>`.
2. In core code add **one** line that calls it, tagged `% COMPAT(v3)`.
   Deleting that line must leave working v4 code.
3. Add a `<entry key="Key">` to `SystemTools/GUILDA/en/Deprecated.xml` and
   call `Deprecated("Key", ...)` from the helper. Add a row to the table
   above and a test in `+DebugScript`.

Old output tuples: declare the method with `varargout` and end it with

```matlab
varargout = {result, flag, output};
varargout = legacy_output(varargout, nargout, 6, @v3_optimize_powerflow, "OptimizePowerflowTuple"); % COMPAT(v3)
```

`v3_optimize_powerflow(result, flag, output)` (in `_VersionSupport/`)
returns the old outputs as a cell row. Only output counts above 3 can select
the old form: with 1–3 outputs the v4 form is returned. `optimize_powerflow`
selects it only for 6 outputs, so 4 or 5 outputs are an error.

### Removing compat code in one step

1. Delete every line tagged `COMPAT(v3)`:

   ```bash
   grep -rl "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA | xargs sed -i '' '/COMPAT(v3)/d'
   ```

2. Delete `_GUILDAsystem/_VersionSupport/`, `Deprecated.xml`, and the
   `_VersionSupport` line of `@GUILDA/config/ListPath.txt`.
3. Delete the tests of deprecated forms, then run `DebugScript.run_all`.
   By section title:
   - F1 "Add bus with deprecated baseMVA option"
   - F2 "COMPAT v3 positional mode and export options"
   - F3 "Deprecated component Hz forms still work and warn once",
     "Deprecated component Hz write sets the network Hz", and the
     `ComponentBaseView` assert in the network Hz edit test
   - F4 "Legacy six-output form", "Deprecated methods option"
   - F5 "COMPAT v3 Continuation_Power_Flow and ContinuationPowerFlow constructor"
   - F6 "Deprecated Reporter and option names still work"
   - F7 "odeLinearizer constructor of v3 names the remedy"
   - F8 "Deprecated CsvNetHandler wrappers"
   - F10 "Legacy output …", "COMPAT hook helper for add_bus baseMVA",
     "COMPAT hooks are single tagged lines …"
4. `odeSimulator` reads its default `Progress` from the `Reporter` key of
   `@GUILDA/config/DefaultTimeSimulation.json`; that is the config key,
   not compat code, and stays.

This procedure was checked on a copy of the code after stage 1 (only the
tests listed then failed). It has **not** been rechecked after stages 2
and 3.

---

## 5. Notes for model and analysis authors (v4 analysis API)

### Result classes

A result of power flow, OPF, CPF, simulation or linearization is a subclass of
`AnalysisResult` (`_GUILDAsystem/_auxiliary/@AnalysisResult/`), in
`_auxiliary/@<Name>Result/`.

```matlab
classdef PowerFlowResult < AnalysisResult
    properties (SetAccess=private)
        tab_bus            % computed results only
    end
    methods
        function obj = PowerFlowResult(net, solver, options, flag, output, t0, tab_bus)
            obj@AnalysisResult(net, solver, options, flag, output, t0);
            obj.tab_bus = tab_bus;
        end
        function h = Plot(obj, opt)     % override only what the class supports
            ...
        end
    end
end
```

- The base keeps `flag`, `output`, `options` (effective settings),
  `str_solver`, `r_elapsed` (pass `tic` or seconds), `str_network` and a
  reference `a_PowerNetwork`. `l_success` is true for a positive numeric or a
  true logical flag; override `is_success` for another convention.
- Store only computed values and the settings used. Never copy model data
  (parameters, V/I owned by buses and components).
- `Plot` and `Export` are the result's methods. One that a class does not
  override stops with `GUILDA:AnalysisResult:Unsupported`.

### Name-Value options

Merge `net.solver_*` defaults with the call's overrides with
`tools.resolve_options`; never write the overrides into the solver.

```matlab
function varargout = calculate_powerflow(obj, opt)
    arguments
        obj
        opt.MaxIteration (1,1) double {mustBeNonnegative, mustBeInteger}   % no default
        opt.Verbose      (1,1) logical
    end
    s_map = struct("MaxIteration", "MaxIterations", ...
                   "Verbose", {{"Display", @(l) replace(string(l), ["true","false"], ["iter","none"])}});
    options = tools.resolve_options(obj.solver_PF, s_map, opt);
    ...
end
```

- Declare the options in the `arguments` block **without defaults**, so
  that only the given names are fields of `opt`; validate them there.
- `s_map` maps each accepted name to a solver field: a name, a string array
  (several fields), a dotted path into a struct property
  (`"dynamic.t_span"`), or `{field, converter}`.
- A name not in `s_map` gives `GUILDA:resolve_options:UnknownName` with the
  list of accepted names.
