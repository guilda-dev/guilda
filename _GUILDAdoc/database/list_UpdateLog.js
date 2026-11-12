const updateLogData = [
  {
    "title": "Show the signal connections",
    "date": "2026-11-12",
    "type": "feature",
    "content": "New net.disp_connection prints, for each input of the components and controllers, the signals that drive it (local, global, observe or equilibrium), grouped by bus, component and controller. Options Kind and Owner narrow the view; with one output it returns the text."
  },
  {
    "title": "New automatic tag names",
    "date": "2026-11-12",
    "type": "feature",
    "content": "Automatic tags now start with the tag of the parent: a generator on bus B001 is B001SG1 (was SG1B001), its AVR B001SG1CA1 (was CA1SG1B001), and an AGC of the network PowerNetworkAGC1 (was AGC1PowerNetwork). Variable names in the results of get_sys, get_variable_map and the time simulation use the tag of the owner only, e.g. delta_B001SG1 and Vre_B001. Scripts that write tags or variable names by hand need updating."
  },
  {
    "title": "Your own model classes: no bus current argument",
    "date": "2026-11-11",
    "type": "feature",
    "content": "Model functions no longer receive the bus current I. In a component class of your own, write fcn_dx, fcn_I and fcn_Mass as (t, x, V, u, param, omega0) and fcn_Y as (t, x, V, param, omega0); in a controller class of your own, use (t, x, V, u, param, omega0). Model classes written for the old arguments need updating."
  },
  {
    "title": "Global controllers connect by input name",
    "date": "2026-11-11",
    "type": "feature",
    "content": "A global controller reads the outputs of the components it controls (their states if they have no outputs) and the voltages of all buses. Each of its outputs drives the input of the same name of a local controller on that component, or else the component input; add_global_controller prints where each output goes. net.get_variable_map lists the inputs and outputs of the controllers and returns these connections as its fourth output. get_sys with Method=\"Feedback\" also works for global controllers that read buses the method eliminates."
  },
  {
    "title": "Change settings by command",
    "date": "2026-11-10",
    "type": "feature",
    "content": "GUILDA.setting(\"PowerFlowCalculation\", Tolerance=1e-10) changes and saves a setting without opening the settings window. After an update of GUILDA, the settings of a category may return to their defaults; GUILDA says so at startup."
  },
  {
    "title": "OPF fixes",
    "date": "2026-10-29",
    "type": "fix",
    "content": "Economic load dispatch, DC OPF and AC OPF run again. Loads keep their power-flow P and Q, and the branch flow sign of DC OPF matches AC OPF."
  },
  {
    "title": "Linearization with every algorithm and several global controllers",
    "date": "2026-10-29",
    "type": "feature",
    "content": "get_sys works with every linearization algorithm (Kron, DAE, Feedback) for the bundled generator, load and controller models. initialize, simulate and get_sys accept any number of global controllers."
  },
  {
    "title": "Remove buses and global controllers",
    "date": "2026-10-29",
    "type": "feature",
    "content": "New net.remove_bus (option RemoveBranches) and net.remove_global_controller. Setting bus.l_isSlack = true makes that bus the only slack bus."
  },
  {
    "title": "Simulation event fixes",
    "date": "2026-10-29",
    "type": "fix",
    "content": "simulate runs without events, stays within the requested time range, and applies input and state offset events correctly, also when they start after t = 0."
  },
  {
    "title": "Start GUILDA in batch mode",
    "date": "2026-10-29",
    "type": "feature",
    "content": "GUILDA starts in matlab -batch. The tutorial opens only when the MATLAB desktop is available."
  },
  {
    "title": "More OPF fixes and MATPOWER export",
    "date": "2026-10-29",
    "type": "fix",
    "content": "AC OPF solves with branch current and power limits and with linear-only costs. New tools.network_to_mpc converts a network into a MATPOWER case."
  },
  {
    "title": "IEEE14bus matches MATPOWER case14",
    "date": "2026-10-29",
    "type": "model",
    "content": "network.IEEE14bus has the line charging, load reactive power, voltage and generator limits and generator costs of MATPOWER case14, so its results change. New network.IEEE14bus_NoTap has every transformer tap set to 1. CSV import keeps transformer taps."
  },
  {
    "title": "Uniform analysis results and per-call options",
    "date": "2026-10-29",
    "type": "feature",
    "content": "Power flow, OPF, continuation power flow, simulation and linearization return [result, flag, output]; the result object has Plot and Export methods. Name-Value options such as Method, Tolerance and Verbose apply to one call. Scripts that read the old outputs need updating."
  },
  {
    "title": "Continuation power flow",
    "date": "2026-10-29",
    "type": "feature",
    "content": "net.calculate_continuation_powerflow(LoadBus=...) computes PV curves (Plot), the maximum loading and the nose point. Continuation_Power_Flow(net, opt) still works but is deprecated."
  },
  {
    "title": "Simulation options",
    "date": "2026-10-29",
    "type": "feature",
    "content": "net.simulate accepts Solver, Tolerance, AbsoluteTolerance, TimeLimit, Progress, Verbose, Plot and Export. Its second output flag is 1 when the run completed, 0 when TimeLimit stopped it and -1 when the solver stopped; scripts that tested it for an early stop need updating."
  },
  {
    "title": "net.linearize and the variable map",
    "date": "2026-10-29",
    "type": "feature",
    "content": "New net.linearize gives the full linearized model; get_ss reduces it by Kron, Feedback or DAE, and Point linearizes at a given state or at a time of a simulation. net.get_variable_map shows the variable order. net.get_sys returns [sys, flag, output]."
  },
  {
    "title": "Network import and export",
    "date": "2026-10-29",
    "type": "feature",
    "content": "New PowerNetwork.import_csv, net.export_csv and PowerNetwork.import_matpower (MATPOWER cases, without MATPOWER installed). Older CSV folders still import."
  },
  {
    "title": "New IEEE 9-bus and 68-bus networks",
    "date": "2026-10-30",
    "type": "model",
    "content": "New network.IEEE9bus (WSCC 3-machine) and network.IEEE68bus (16-machine NETS-NYPS) with one-axis generators, impedance loads and an AVR and PSS on every generator. LocalController=false builds them without the AVRs and PSSs."
  },
  {
    "title": "IEEE14bus_lossless follows case14",
    "date": "2026-10-30",
    "type": "model",
    "content": "network.IEEE14bus_lossless is network.IEEE14bus with every branch resistance set to 0, keeping line charging, the bus shunt and the transformer taps. Its results change."
  },
  {
    "title": "Automatic tags are unique",
    "date": "2026-10-30",
    "type": "fix",
    "content": "add_bus, add_branch and add_component no longer repeat a tag after a removal. Adding a global controller with a tag already in use is an error."
  },
  {
    "title": "Controller fixes",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Adding or replacing an AVR or PSS requires net.initialize() afterwards. Replacing an AVR keeps its PSS. Trip events that name a global controller or a component with local controllers act on the right states."
  },
  {
    "title": "Clearer simulation event errors",
    "date": "2026-10-30",
    "type": "feature",
    "content": "Simulation disturbances are checked before the run, and an invalid input name or value stops with an error that lists the valid inputs. A disturbance entirely outside the simulation time gives a warning."
  },
  {
    "title": "Smaller fixes",
    "date": "2026-10-30",
    "type": "fix",
    "content": "net.linearize and get_sys work with buses that have no components. GUILDA.dictionary works from any current folder and no longer lists archived classes."
  },
  {
    "title": "Simulations of large networks at rest",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Simulations that start at rest no longer stop at t = 0 in large networks such as network.IEEE68bus(LocalController=false). When the solver stops, the message names the phase and its time interval."
  },
  {
    "title": "OPF load cost and DC branch susceptance",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Loads have no OPF cost by default, so r_cost is the generation cost. DC OPF uses the MATPOWER branch susceptance with taps and phase shifts, which changes DC OPF results for such branches."
  },
  {
    "title": "Controller inputs by name and local_LQR",
    "date": "2026-10-30",
    "type": "feature",
    "content": "A local controller reads the outputs or states of its component by the names of its inputs; Xall and Yall read all states or all outputs. controller.local_LQR works again in place of an AVR, with its gain computed from Q and R by net.initialize."
  },
  {
    "title": "Same get_sys layout for components and buses",
    "date": "2026-10-30",
    "type": "feature",
    "content": "comp.get_sys and bus.get_sys order inputs as [port; component inputs; controller inputs] and outputs likewise. States are no longer outputs, so scripts that read states from these outputs need updating."
  },
  {
    "title": "Simulation results by variable",
    "date": "2026-10-30",
    "type": "feature",
    "content": "Simulation results follow the order of net.get_variable_map(), including controller states. New result.get_point(t) gives the state at a time, and net.linearize(Point={sim, t}) works with controllers."
  },
  {
    "title": "net.initialize returns a result",
    "date": "2026-10-30",
    "type": "feature",
    "content": "net.initialize returns [result, flag, output] and takes Method=\"powerflow\", \"OPF\" or \"equilibrium\". A failed power flow or OPF is an error and leaves the network unchanged. Scripts that read [flag, tab] from it need updating (result.tab_bus is the old table)."
  },
  {
    "title": "Buses without states detected automatically",
    "date": "2026-11-02",
    "type": "feature",
    "content": "net.linearize and net.get_sys find buses without states by themselves, so the NonUnit setting is no longer needed; it still works with a warning."
  },
  {
    "title": "Incomplete simulations keep their results",
    "date": "2026-11-02",
    "type": "feature",
    "content": "When a simulation does not complete, net.simulate warns and returns the completed phases (flag = -1) instead of an error. TimeLimit covers the whole run. Large networks are simulated with sparse matrices."
  },
  {
    "title": "Simulation and initialize fixes",
    "date": "2026-11-02",
    "type": "fix",
    "content": "A generator with a local controller can trip. An input event on an input driven by a local controller adds to its output. net.initialize with Method=\"OPF\" or \"equilibrium\" sets a consistent operating point or stops with an error."
  },
  {
    "title": "New IEEJ standard networks",
    "date": "2026-11-04",
    "type": "model",
    "content": "New network.IEEJ_EAST10, IEEJ_EAST30, IEEJ_WEST10 and IEEJ_WEST30, the IEEJ standard power system models with the report's generators, exciters and governors. Section=\"peak\" or \"night\" selects the power-flow case; Governor=false and LocalController=false leave out controllers. See each class help for the conversions."
  },
  {
    "title": "Simulation scenarios",
    "date": "2026-11-04",
    "type": "feature",
    "content": "Describe the disturbances of a simulation as a Scenario: add faults, trips, branch openings, offsets and inputs, then net.add_scenario(sc) and net.simulate(sc). sc.judge(result) gives a stability verdict, and scenarios can be read and written as CSV."
  },
  {
    "title": "ODEevent replaced by Scenario",
    "date": "2026-11-04",
    "type": "feature",
    "content": "ODEevent still works and returns a Scenario, with a warning. Use Scenario and net.add_scenario in new scripts."
  },
  {
    "title": "Open branches during a simulation",
    "date": "2026-11-04",
    "type": "feature",
    "content": "sc.add_open_branch(branches, [t_start, t_end]) opens branches during a simulation and reconnects them at t_end."
  },
  {
    "title": "Governors and IEEJ governor models",
    "date": "2026-11-04",
    "type": "model",
    "content": "A component can have a governor beside its AVR. New controller.governor.IEEJ_LPT1 (thermal and nuclear), IEEJ_LPT3 and IEEJ_LPT4 (hydro)."
  },
  {
    "title": "AVR_DC1 field voltage limit",
    "date": "2026-11-04",
    "type": "model",
    "content": "controller.avr.AVR_DC1 takes Vfld_max and Vfld_min, a field voltage limit without windup. The defaults give the same results as before."
  },
  {
    "title": "gen-park with Xq_p = Xq",
    "date": "2026-11-04",
    "type": "fix",
    "content": "component.generator.park computes its equilibrium when Xq_p equals Xq (or Xd_p equals Xd), so a machine without a q-axis transient circuit can be modeled."
  },
  {
    "title": "Verification against published results",
    "date": "2026-11-04",
    "type": "feature",
    "content": "The folder _GUILDAverification compares bundled networks with their literature: the reference, the cases as Scenario CSV files, the published verdicts and a comparison script. It covers the four IEEJ networks."
  },
  {
    "title": "Unused tools functions removed",
    "date": "2026-11-05",
    "type": "feature",
    "content": "tools.closeUI, tools.ssfeedback, tools.input, tools.transTab, tools.DNS, tools.FigureClass and the tools.for_ss package are removed. Scripts that call them need their own copy."
  },
  {
    "title": "net.initialize updates the model after edits",
    "date": "2026-11-06",
    "type": "feature",
    "content": "After editing parameters or the topology, run net.initialize(): it recomputes only what the edits affect. simulate, linearize, get_sys and the continuation power flow stop with an error naming the edits until it has run."
  },
  {
    "title": "Edit parameters through tab_parameter",
    "date": "2026-11-06",
    "type": "feature",
    "content": "Read and edit model parameters through tab_parameter (columns dynamics, powerflow, operation, OPF, graph, base). The para_* properties are removed: scripts that use them switch to tab_parameter. The frequency and system base are in net.tab_parameter.base."
  },
  {
    "title": "OPF costs and constraints of your own",
    "date": "2026-11-07",
    "type": "feature",
    "content": "net.optimize_powerflow takes Cost and Constraint functions added to the problem, with the duals of named constraints in result.lambda.Constraints. optimize_powerflow(Problem=prob) solves a problem from net.build_opf_problem changed by the user."
  },
  {
    "title": "Power flow without toolboxes",
    "date": "2026-11-07",
    "type": "feature",
    "content": "net.calculate_powerflow takes Method (now Solver, 2026-11-10) \"newton\" (default), \"gradient\", \"levenberg-marquardt\", \"dynamic\" or \"fsolve\"; only \"fsolve\" needs Optimization Toolbox, so the power flow runs with MATLAB alone. Method=\"algebraic\" is now \"fsolve\"."
  },
  {
    "title": "Linearization without Control System Toolbox",
    "date": "2026-11-07",
    "type": "feature",
    "content": "get_sys returns a result with the matrices A, B, C, D, E and the variable names, or a struct, without any toolbox. Scripts that use ss functions on it (eig(sys), step, pole) pass Format=\"ss\", which needs Control System Toolbox."
  },
  {
    "title": "Optional toolboxes and the startup check",
    "date": "2026-11-07",
    "type": "feature",
    "content": "GUILDA needs MATLAB only. OPF and Method=\"fsolve\" (now Solver=\"fsolve\") need Optimization Toolbox, ss output and the LQR controllers need Control System Toolbox. The startup prints for each toolbox \"ok\" or the features unavailable without it; Getting Started has the full table."
  },
  {
    "title": "Show a model in a GUI",
    "date": "2026-11-07",
    "type": "feature",
    "content": "obj.gui() opens a window for a network, bus, branch, component or controller with its parameters (editable in place), its equilibrium, a breadcrumb and cards of the children to move between models, and a Docs button for the reference page of the class. obj.gui(h) puts it in a panel or tab of your own app, and a new model class needs no extra code."
  },
  {
    "title": "Solver chooses the algorithm",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Every analysis chooses its numerical algorithm with Solver, e.g. net.calculate_powerflow(Solver=\"levenberg-marquardt\"), and net.initialize passes Solver on to the power flow or the OPF. Scripts and saved settings that use Method for the power flow algorithm switch to Solver. Method now says what is built: net.linearize and net.get_sys take Method=\"Kron\", \"Feedback\" or \"DAE\" (Algorithm still works, with a warning)."
  },
  {
    "title": "Equilibrium with the inputs held",
    "date": "2026-11-10",
    "type": "feature",
    "content": "comp.set_input(u) sets the inputs of a component at the equilibrium, and net.initialize(Method=\"FixedInput\") finds the states and bus voltages with those inputs held; the first generator of the slack bus balances the power. Until then, the analyses and net.initialize() stop with an error, and net.initialize(Method=\"powerflow\") discards the edited inputs. The load properties Z and PQ_st are removed: scripts that read them use rv_Uequilibrium instead."
  },
  {
    "title": "Operating limits in the continuation power flow",
    "date": "2026-11-10",
    "type": "feature",
    "content": "net.calculate_continuation_powerflow(Limits=[\"Q\",\"V\",\"S\"]) applies the operating limits in tab_parameter.operation along the path. With \"Q\", a PV bus whose generators reach their total Qmin or Qmax becomes a PQ bus at that bound and the trace goes on; with \"V\" (bus Vmin/Vmax) and \"S\" (branch Smax), the trace stops at the first point that reaches the limit. result.tab_switch and result.tab_stop show where this happened. Limits=\"all\" applies all three; the default is \"none\"."
  },
  {
    "title": "Limit violations of the power flow",
    "date": "2026-11-10",
    "type": "feature",
    "content": "result.tab_violation of net.calculate_powerflow lists the operating limits (tab_parameter.operation) of buses, branches and components that the solution violates, one row per limit, and has no rows when there is none. The power flow itself does not apply the limits."
  },
  {
    "title": "Power flow tolerance and warm start",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The default Tolerance of net.calculate_powerflow is 1e-8, the largest P/Q mismatch in pu, with the same meaning for every Solver; change the default in the PowerFlowCalculation section of GUILDA.setting. The power flow starts from the last solution of the network (WarmStart=false for a flat start), so repeated runs with small changes need fewer iterations. The bus parameters V0 and Varg0 are removed: scripts that set them need updating."
  },
  {
    "title": "Tags must be valid variable names",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Every tag of a network, bus, branch, component or controller, including the tags in CSV data, must be a valid MATLAB variable name: a letter first, then letters, digits and underscores. Any other tag stops with an error. The branches of network.IEEJ_WEST10 are renamed like LINE20_1 and G1_TR (were LINE20-1 and G1-TR), and the AC OPF of IEEJ_WEST10 now solves."
  },
  {
    "title": "Analysis defaults in GUILDA.setting",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The defaults of every analysis (power flow, OPF, continuation power flow, time simulation, linearization) are set in GUILDA.setting; a Name-Value option changes them for one call. Solver properties such as net.solver_ODE.RelativeTolerance or net.solver_OPF.Method can no longer be set: pass the option in the call instead. net.solver_OPF keeps Cost, Constraint, DefaultCost and ReferenceBus, and net.solver_CPF keeps LoadBus. Renamed settings: Tolerance (OPF, time simulation) and MaxIteration (continuation power flow). The option Plot=true is removed: draw with result.Plot()."
  },
  {
    "title": "Watch an analysis while it runs with PlotFcn",
    "date": "2026-11-10",
    "type": "feature",
    "content": "PlotFcn shows the progress of an analysis in a figure. net.calculate_powerflow(PlotFcn=\"residual\") draws the residual of each power equation at every iteration. net.optimize_powerflow(PlotFcn=[\"fval\",\"constrviolation\"]) shows the fmincon plot functions (AC OPF, or Solver=\"fmincon\"). net.calculate_continuation_powerflow(PlotFcn=\"pvcurve\") extends the PV curves of all buses at each step. A function handle stop = f(x, optimValues, state), as in optimoptions, can also be passed and can stop the analysis. The OPF setting Display is replaced by Verbose (false by default)."
  },
  {
    "title": "Renamed keys in GUILDA.setting",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Each key of GUILDA.setting now has the name of its Name-Value option, and a setting of one solver is named after the solver and its MATLAB option, e.g. FminconAlgorithm or FsolveMaxFunctionEvaluations. NaN means automatic (MaxIteration and GradientStepSize of the power flow, where 0 meant automatic), and on/off settings are true/false. The power flow has the new setting Verbose. Saved values of renamed keys return to the default; change a saved MaxIteration or GradientStepSize of 0 to NaN."
  }
];
