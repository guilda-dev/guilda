const updateLogData = [
  {
    "title": "GUILDA ver5 start",
    "date": "2025-10-01",
    "content": "GUILDA ver5 development started."
  },
  {
    "title": "LayerPackage.m",
    "date": "2025-10-08",
    "content": "LayerPackage.m updated."
  },
  {
    "title": "Build Layer Structure",
    "date": "2025-10-09",
    "content": "GuildaWorksSpace.m only generate; PowerNeteork.m add/remove bus, branch, and global_controller methods; Bus.m set_network, add/remove component and cubicle; Cubicle.m set_bus; Branch.m set_network."
  },
  {
    "title": "Component and ControllerPackage generation",
    "date": "2025-10-13",
    "content": "Component.m updated; ControllerPackage.m only generate; LocalController.m only generate; GlobalController.m only generate."
  },
  {
    "title": "Parameter Operation",
    "date": "2025-10-14",
    "content": "Parameter.m created by inheriting the dynamicprops class."
  },
  {
    "title": "Rename +config to +GUILDAconfig",
    "date": "2025-10-15",
    "content": "Renamed \"+config\" to \"+GUILDAconfig\" and enabled GUILDAconfig.gitpull."
  },
  {
    "title": "OPF works again",
    "date": "2026-10-29",
    "content": "ELD, DC OPF and AC OPF run again. Loads keep their power-flow P and Q, and the DC OPF branch flow sign matches AC OPF."
  },
  {
    "title": "Linearization and multiple global controllers",
    "date": "2026-10-29",
    "content": "get_sys works with every linearization algorithm (Kron, DAE, Feedback) for the shipped generator, load and controller models. Any number of global controllers is supported in initialize, simulate and get_sys."
  },
  {
    "title": "Edit tracking",
    "date": "2026-10-29",
    "content": "Parameter and topology edits now take effect: changed dynamics are rebuilt automatically. When an edit makes the equilibrium out of date, simulate and get_sys stop with GUILDA:PowerNetwork:EquilibriumStale until net.initialize() is run."
  },
  {
    "title": "Network base values",
    "date": "2026-10-29",
    "content": "The nominal frequency and system base are held by the network in net.tab_parameter.base (Hz, baseMVA); models read comp.r_Hz. comp.para_base.Hz and the add_bus option baseMVA are deprecated and warn with GUILDA:Deprecated:* IDs."
  },
  {
    "title": "remove_bus, remove_global_controller and single slack bus",
    "date": "2026-10-29",
    "content": "New net.remove_bus (with option RemoveBranches) and net.remove_global_controller. Removed objects are detached from the network. Setting bus.l_isSlack = true makes that bus the only slack bus."
  },
  {
    "title": "Simulation event fixes",
    "date": "2026-10-29",
    "content": "simulate runs without events, keeps phases within the requested time range, and applies input and state offset events correctly, including events that start after t = 0."
  },
  {
    "title": "Start in batch mode",
    "date": "2026-10-29",
    "content": "GUILDA now starts in matlab -batch; the tutorial is opened only when the desktop is available."
  },
  {
    "title": "Optimal power flow fixes",
    "date": "2026-10-29",
    "content": "AC OPF solves with branch Imax and Smax limits (they stopped fmincon before) and with linear-only costs (HP = HQ = 0). Branch flow variables start at the values of the initial bus voltages. OPFResult.lambda documents the nodal price as -lambda.Constraints.balancedP_<bus>. New tools.network_to_mpc converts a network into a MATPOWER case."
  },
  {
    "title": "IEEE14bus matches MATPOWER case14",
    "date": "2026-10-29",
    "content": "network.IEEE14bus now has the MATPOWER case14 line charging, load reactive power, voltage limits 0.94-1.06, generator limits and generator costs; loads have no OPF cost. Power-flow, OPF, simulation and linearization results of IEEE14bus change. CSV import now reads the transformer tap and phase columns (tap/phase, as export writes them; Tap/Phase is also accepted), so imported transformers keep their taps; this also changes IEEE14bus_lossless. New network.IEEE14bus_NoTap is IEEE14bus with every transformer tap set to 1."
  },
  {
    "title": "Analysis results and per-call options",
    "date": "2026-10-29",
    "content": "Power flow, OPF, continuation power flow, simulation and linearization now return [result, flag, output], where result is a result object (PowerFlowResult, OPFResult, CPFResult, odeSimulationResult, LinearizationResult) with Plot and Export methods. Name-Value options such as Method, Tolerance, MaxIteration and Verbose override the defaults in net.solver_* for one call only; an unknown name is an error that lists the accepted names."
  },
  {
    "title": "Power flow and OPF results",
    "date": "2026-10-29",
    "content": "net.calculate_powerflow returns a PowerFlowResult (tab_bus, tab_branch, iteration history) and takes Method=\"algebraic\" or \"dynamic\". net.optimize_powerflow returns an OPFResult (tab_bus, tab_cub, tab_branch, r_cost, lambda) and takes Method and Solver. The positional power flow mode, the export/filename options, the OPF option methods and the 6-output OPF form still work with GUILDA:Deprecated:* warnings; with 1 to 3 outputs optimize_powerflow returns the new outputs."
  },
  {
    "title": "net.calculate_continuation_powerflow",
    "date": "2026-10-29",
    "content": "The continuation power flow is now net.calculate_continuation_powerflow(LoadBus=...), returning a CPFResult with the PV curves (Plot), the maximum loading r_lambdaMax and the nose point. Continuation_Power_Flow(net, opt) is deprecated but still works; ContinuationPowerFlow(net, ...) is an error."
  },
  {
    "title": "Simulation outputs and options",
    "date": "2026-10-29",
    "content": "net.simulate(time, events..., Name, Value) accepts Solver, Tolerance, AbsoluteTolerance, TimeLimit, Progress, Verbose, Plot and Export. Its second output changed meaning: flag is 1 when the run completed, 0 when it stopped by TimeLimit and -1 when the solver stopped (it used to be true for an early stop). solver_ODE.Reporter and the option names Reporter and RelativeTolerance are deprecated (use Progress and Tolerance)."
  },
  {
    "title": "net.linearize and the variable map",
    "date": "2026-10-29",
    "content": "New net.linearize returns a LinearizationResult with the unreduced Jacobian blocks; result.get_ss(\"Kron\" | \"Feedback\" | \"DAE\") gives the reduced model, and Point linearizes at a given state or at a time of a simulation result. net.get_variable_map (also on buses and components) defines the variable order. net.get_sys now returns [sys, flag, output] (the second output is no longer an odeLinearizer), and the DAE model's B matrix has the corrected sign on the algebraic rows. Components and controllers define an optional get_hessian contract."
  },
  {
    "title": "Network import and export",
    "date": "2026-10-29",
    "content": "New PowerNetwork.import_csv, net.export_csv and PowerNetwork.import_matpower (MATPOWER cases without MATPOWER). CSV folders now store Hz and baseMVA in network/parameter.csv and the slack bus in the bus column Slack; older folders still import. CsvNetHandler.import and CsvNetHandler.export are deprecated wrappers."
  },
  {
    "title": "Symbolic Math Toolbox is optional",
    "date": "2026-10-29",
    "content": "GUILDA no longer requires Symbolic Math Toolbox; only MATLAB, Control System Toolbox and Optimization Toolbox are required."
  }
];
