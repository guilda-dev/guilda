const updateLogData = [
  {
    "title": "Removed objects are deleted",
    "date": "2026-11-12",
    "type": "feature",
    "content": "Generators, loads, branches, AVRs, PSSs, governors and AGCs are made only with add_component, replace_component, add_branch, add_local_controller and add_global_controller; calling a model class directly, such as controller.avr.AVR_ST1(\"1\"), stops with an error. An object you remove or replace (remove_bus, remove_branch, remove_component, replace_component, remove_local_controller, remove_global_controller, or a controller replaced by add_local_controller) is deleted, together with what was attached to it, so a variable that still holds it can no longer be used. To use it again, add a new one with its key. In a model class of your own, declare the constructor with Access={?Bus} (components), Access={?Component} (local controllers) or Access={?PowerNetwork} (branches and global controllers)."
  },
  {
    "title": "Show the signal connections",
    "date": "2026-11-12",
    "type": "feature",
    "content": "A new command lists, for each input of the components and controllers, the signals that drive it (local, global, observe or equilibrium), grouped by bus, component and controller. The list can be narrowed to one kind of signal or one owner, and returned as text instead of printed."
  },
  {
    "title": "New automatic tag names",
    "date": "2026-11-12",
    "type": "feature",
    "content": "Automatic tags now start with the tag of the parent: a generator on bus B001 is B001SG1 (was SG1B001), its AVR B001SG1CA1 (was CA1SG1B001), and an AGC of the network PowerNetworkAGC1 (was AGC1PowerNetwork). Variable names in the linearized model, the variable map and the time simulation results use the tag of the owner only, e.g. delta_B001SG1 and Vre_B001. Scripts that write tags or variable names by hand need updating."
  },
  {
    "title": "Your own model classes: no bus current argument",
    "date": "2026-11-11",
    "type": "feature",
    "content": "In your own component and controller classes, the model functions no longer take the bus current as an argument. Model classes written for the old arguments need updating."
  },
  {
    "title": "Global controllers connect by input name",
    "date": "2026-11-11",
    "type": "feature",
    "content": "A global controller reads the outputs of the components it controls (their states if they have no outputs) and the voltages of all buses. Each of its outputs drives the input of the same name of a local controller on that component, or else the component input; adding a global controller prints where each output goes. The variable map lists the inputs and outputs of the controllers and these connections. Linearization by the feedback method also works for global controllers that read buses the method eliminates."
  },
  {
    "title": "Change settings from a script",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Settings can now be changed and saved from a script without opening the settings window. After an update of GUILDA, the settings of a category may return to their defaults; GUILDA says so at startup."
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
    "content": "Linearization works with every algorithm (Kron, DAE, feedback) for the bundled generator, load and controller models. Initialization, simulation and linearization accept any number of global controllers."
  },
  {
    "title": "Remove buses and global controllers",
    "date": "2026-10-29",
    "type": "feature",
    "content": "Buses can now be removed from a network, optionally together with their branches, and so can global controllers. Marking a bus as the slack bus makes it the only slack bus."
  },
  {
    "title": "Simulation event fixes",
    "date": "2026-10-29",
    "type": "fix",
    "content": "A simulation runs without events, stays within the requested time range, and applies input and state offset events correctly, also when they start after time zero."
  },
  {
    "title": "Start GUILDA in batch mode",
    "date": "2026-10-29",
    "type": "feature",
    "content": "GUILDA starts in MATLAB batch mode. The tutorial opens only when the MATLAB desktop is available."
  },
  {
    "title": "More OPF fixes and MATPOWER export",
    "date": "2026-10-29",
    "type": "fix",
    "content": "AC OPF solves with branch current and power limits and with linear-only costs. A network can now be converted into a MATPOWER case."
  },
  {
    "title": "IEEE 14-bus network matches MATPOWER case14",
    "date": "2026-10-29",
    "type": "model",
    "content": "The IEEE 14-bus network has the line charging, load reactive power, voltage and generator limits and generator costs of MATPOWER case14, so its results change. A new variant has every transformer tap set to 1. CSV import keeps transformer taps."
  },
  {
    "title": "Uniform analysis results and per-call options",
    "date": "2026-10-29",
    "type": "feature",
    "content": "Power flow, OPF, continuation power flow, simulation and linearization all return a result, a success flag and further details; the result can be plotted and exported. Options such as the method, tolerance and message level apply to one call. Scripts that read the old outputs need updating."
  },
  {
    "title": "Continuation power flow",
    "date": "2026-10-29",
    "type": "feature",
    "content": "The continuation power flow computes PV curves for chosen load buses, which can be plotted, the maximum loading and the nose point. The old continuation power flow function still works but is deprecated."
  },
  {
    "title": "Simulation options",
    "date": "2026-10-29",
    "type": "feature",
    "content": "The time simulation takes options for the solver, tolerances, a time limit, progress display, messages, plotting and export. Its success flag is 1 when the run completed, 0 when the time limit stopped it and -1 when the solver stopped; scripts that tested it for an early stop need updating."
  },
  {
    "title": "Full linearized model and the variable map",
    "date": "2026-10-29",
    "type": "feature",
    "content": "A new command gives the full linearized model, which can be reduced by the Kron, feedback or DAE method, at a given state or at a time of a simulation. The variable map shows the variable order. Linearization returns the system, a success flag and further details."
  },
  {
    "title": "Network import and export",
    "date": "2026-10-29",
    "type": "feature",
    "content": "Networks can be imported from and exported to CSV folders, and imported from MATPOWER cases without MATPOWER installed. Older CSV folders still import."
  },
  {
    "title": "New IEEE 9-bus and 68-bus networks",
    "date": "2026-10-30",
    "type": "model",
    "content": "New IEEE 9-bus (WSCC 3-machine) and 68-bus (16-machine NETS-NYPS) networks with one-axis generators, impedance loads and an AVR and PSS on every generator. They can also be built without the AVRs and PSSs."
  },
  {
    "title": "Lossless IEEE 14-bus network follows case14",
    "date": "2026-10-30",
    "type": "model",
    "content": "The lossless IEEE 14-bus network is the IEEE 14-bus network with every branch resistance set to 0, keeping line charging, the bus shunt and the transformer taps. Its results change."
  },
  {
    "title": "Automatic tags are unique",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Adding buses, branches and components no longer repeats a tag after a removal. Adding a global controller with a tag already in use is an error."
  },
  {
    "title": "Controller fixes",
    "date": "2026-10-30",
    "type": "fix",
    "content": "After adding or replacing an AVR or PSS, initialize the network again. Replacing an AVR keeps its PSS. Trip events that name a global controller or a component with local controllers act on the right states."
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
    "content": "Linearization works with buses that have no components. The GUILDA dictionary works from any current folder and no longer lists archived classes."
  },
  {
    "title": "Simulations of large networks at rest",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Simulations that start at rest no longer stop at time zero in large networks such as the IEEE 68-bus network without local controllers. When the solver stops, the message names the phase and its time interval."
  },
  {
    "title": "OPF load cost and DC branch susceptance",
    "date": "2026-10-30",
    "type": "fix",
    "content": "Loads have no OPF cost by default, so the OPF cost is the generation cost. DC OPF uses the MATPOWER branch susceptance with taps and phase shifts, which changes DC OPF results for such branches."
  },
  {
    "title": "Controller inputs by name and the local LQR controller",
    "date": "2026-10-30",
    "type": "feature",
    "content": "A local controller reads the outputs or states of its component by the names of its inputs; the input names Xall and Yall read all states or all outputs. The local LQR controller works again in place of an AVR, with its gain computed from Q and R at initialization."
  },
  {
    "title": "Same linearized model layout for components and buses",
    "date": "2026-10-30",
    "type": "feature",
    "content": "The linearized models of a component and of a bus order the inputs as port, component inputs, then controller inputs, and the outputs likewise. States are no longer outputs, so scripts that read states from these outputs need updating."
  },
  {
    "title": "Simulation results by variable",
    "date": "2026-10-30",
    "type": "feature",
    "content": "Simulation results follow the order of the variable map, including controller states. The state at a given time can be taken from a result, and linearization at a time of a simulation works with controllers."
  },
  {
    "title": "Initialization returns a result",
    "date": "2026-10-30",
    "type": "feature",
    "content": "Initialization returns a result, a success flag and further details, and can start from the power flow, the OPF or the equilibrium. A failed power flow or OPF is an error and leaves the network unchanged. Scripts that read a flag and a table from it need updating (the bus table of the result is the old table)."
  },
  {
    "title": "Buses without states detected automatically",
    "date": "2026-11-02",
    "type": "feature",
    "content": "Linearization finds buses without states by itself, so the setting that marked them is no longer needed; it still works with a warning."
  },
  {
    "title": "Incomplete simulations keep their results",
    "date": "2026-11-02",
    "type": "feature",
    "content": "When a simulation does not complete, it warns and returns the completed phases with a flag of -1 instead of an error. The time limit covers the whole run. Large networks are simulated with sparse matrices."
  },
  {
    "title": "Simulation and initialize fixes",
    "date": "2026-11-02",
    "type": "fix",
    "content": "A generator with a local controller can trip. An input event on an input driven by a local controller adds to its output. Initialization from the OPF or the equilibrium sets a consistent operating point or stops with an error."
  },
  {
    "title": "New IEEJ standard networks",
    "date": "2026-11-04",
    "type": "model",
    "content": "New IEEJ EAST10, EAST30, WEST10 and WEST30 networks, the IEEJ standard power system models with the report's generators, exciters and governors. Options select the peak or night power-flow case and leave out the governors or the local controllers. See each class help for the conversions."
  },
  {
    "title": "Simulation scenarios",
    "date": "2026-11-04",
    "type": "feature",
    "content": "Describe the disturbances of a simulation as a scenario: add faults, trips, branch openings, offsets and inputs, then add the scenario to the network or simulate it directly. A scenario gives a stability verdict for a result, and scenarios can be read and written as CSV."
  },
  {
    "title": "Old simulation events replaced by scenarios",
    "date": "2026-11-04",
    "type": "feature",
    "content": "The old simulation event object still works and returns a scenario, with a warning. Use scenarios in new scripts."
  },
  {
    "title": "Open branches during a simulation",
    "date": "2026-11-04",
    "type": "feature",
    "content": "A scenario can open branches for a time interval during a simulation and reconnect them at its end."
  },
  {
    "title": "Governors and IEEJ governor models",
    "date": "2026-11-04",
    "type": "model",
    "content": "A component can have a governor beside its AVR. New IEEJ governor models LPT1 (thermal and nuclear), LPT3 and LPT4 (hydro)."
  },
  {
    "title": "DC1 AVR field voltage limit",
    "date": "2026-11-04",
    "type": "model",
    "content": "The DC1 AVR takes an upper and a lower field voltage, a field voltage limit without windup. The defaults give the same results as before."
  },
  {
    "title": "Park generator with equal transient and synchronous reactances",
    "date": "2026-11-04",
    "type": "fix",
    "content": "The Park generator model computes its equilibrium when the q-axis transient reactance equals the q-axis synchronous reactance (or likewise on the d axis), so a machine without a q-axis transient circuit can be modeled."
  },
  {
    "title": "Verification against published results",
    "date": "2026-11-04",
    "type": "feature",
    "content": "The folder _GUILDAverification compares bundled networks with their literature: the reference, the cases as scenario CSV files, the published verdicts and a comparison script. It covers the four IEEJ networks."
  },
  {
    "title": "Unused tools functions removed",
    "date": "2026-11-05",
    "type": "feature",
    "content": "Several unused helper functions and one helper package of the tools folder are removed. Scripts that call them need their own copy."
  },
  {
    "title": "Initialization updates the model after edits",
    "date": "2026-11-06",
    "type": "feature",
    "content": "After editing parameters or the topology, initialize the network again: it recomputes only what the edits affect. Simulation, linearization and the continuation power flow stop with an error naming the edits until it has run."
  },
  {
    "title": "Edit parameters in the parameter table",
    "date": "2026-11-06",
    "type": "feature",
    "content": "Read and edit model parameters in the parameter table of each model (columns dynamics, powerflow, operation, OPF, graph, base). The separate parameter properties are removed: scripts that use them switch to the parameter table. The frequency and system base are in the base column of the network's table."
  },
  {
    "title": "OPF costs and constraints of your own",
    "date": "2026-11-07",
    "type": "feature",
    "content": "The OPF takes cost and constraint functions of your own, added to the problem, and returns the duals of named constraints in its result. It can also solve an OPF problem built from the network and then changed by the user."
  },
  {
    "title": "Power flow without toolboxes",
    "date": "2026-11-07",
    "type": "feature",
    "content": "The power flow algorithm can be Newton (default), gradient, Levenberg-Marquardt, dynamic or fsolve; only fsolve needs Optimization Toolbox, so the power flow runs with MATLAB alone. The former algebraic choice is now fsolve. The option that chooses the algorithm was renamed on 2026-11-10."
  },
  {
    "title": "Linearization without Control System Toolbox",
    "date": "2026-11-07",
    "type": "feature",
    "content": "Linearization returns a result with the matrices A, B, C, D, E and the variable names, or a struct, without any toolbox. Scripts that apply state-space functions to it, such as eigenvalues, step responses or poles, request the state-space model output, which needs Control System Toolbox."
  },
  {
    "title": "Optional toolboxes and the startup check",
    "date": "2026-11-07",
    "type": "feature",
    "content": "GUILDA needs MATLAB only. OPF and the fsolve power flow algorithm need Optimization Toolbox; state-space model output and the LQR controllers need Control System Toolbox. The startup prints for each toolbox \"ok\" or the features unavailable without it; Getting Started has the full table."
  },
  {
    "title": "Show a model in a GUI",
    "date": "2026-11-07",
    "type": "feature",
    "content": "A window can be opened for a network, bus, branch, component or controller with its parameters (editable in place), its equilibrium, a breadcrumb and cards of the children to move between models, and a Docs button for the reference page of the class. The window can also be placed in a panel or tab of your own app, and a new model class needs no extra code."
  },
  {
    "title": "Solver chooses the algorithm",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Every analysis chooses its numerical algorithm with the Solver option, e.g. Levenberg-Marquardt for the power flow, and initialization passes it on to the power flow or the OPF. Scripts and saved settings that use the Method option for the power flow algorithm switch to Solver. Method now says what is built: for linearization it chooses Kron, feedback or DAE (the old Algorithm option still works, with a warning)."
  },
  {
    "title": "Equilibrium with the inputs held",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The inputs of a component at the equilibrium can now be set, and initialization with these inputs held finds the states and bus voltages; the first generator of the slack bus balances the power. Until then, the analyses and the default initialization stop with an error, and initialization from the power flow discards the edited inputs. The separate impedance and power properties of loads are removed: scripts that read them use the equilibrium inputs of the load instead."
  },
  {
    "title": "Operating limits in the continuation power flow",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The continuation power flow can apply the operating limits of the parameter table along the path: reactive power, bus voltage and branch apparent power. With the reactive power limit, a PV bus whose generators reach their total minimum or maximum becomes a PQ bus at that bound and the trace goes on; with the voltage or branch limit, the trace stops at the first point that reaches it. Tables in the result show where this happened. All three limits can be applied at once; by default none is."
  },
  {
    "title": "Limit violations of the power flow",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The power flow result has a table of the operating limits of buses, branches and components that the solution violates, one row per limit, with no rows when there is none. The power flow itself does not apply the limits."
  },
  {
    "title": "Power flow tolerance and warm start",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The default power flow tolerance is 1e-8, the largest P/Q mismatch in pu, with the same meaning for every algorithm; change the default in the power flow section of the settings. The power flow starts from the last solution of the network (a flat start can be requested), so repeated runs with small changes need fewer iterations. The bus parameters for the initial voltage magnitude and angle are removed: scripts that set them need updating."
  },
  {
    "title": "Tags must be valid variable names",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Every tag of a network, bus, branch, component or controller, including the tags in CSV data, must be a valid MATLAB variable name: a letter first, then letters, digits and underscores. Any other tag stops with an error. The branches of the IEEJ WEST10 network are renamed like LINE20_1 and G1_TR (were LINE20-1 and G1-TR), and its AC OPF now solves."
  },
  {
    "title": "Analysis defaults in the settings",
    "date": "2026-11-10",
    "type": "feature",
    "content": "The defaults of every analysis (power flow, OPF, continuation power flow, time simulation, linearization) are set in the GUILDA settings; an option given in a call changes them for that call. The solver properties of a network, such as the time simulation tolerance or the OPF method, can no longer be set: give the option in the call instead. The network still keeps the OPF costs, constraints, default cost and reference bus, and the load buses of the continuation power flow. The tolerance (OPF, time simulation) and the iteration limit (continuation power flow) settings are renamed. The plot option is removed: draw from the result instead."
  },
  {
    "title": "Watch an analysis while it runs",
    "date": "2026-11-10",
    "type": "feature",
    "content": "A new option shows the progress of an analysis in a figure: the residual of each power flow equation at every iteration, the MATLAB optimization plots of the AC OPF or the fmincon algorithm, or the PV curves of all buses growing at each step of the continuation power flow. A plot function of your own, written as for MATLAB optimization, can also be given and can stop the analysis. The OPF display setting is replaced by a message setting (off by default)."
  },
  {
    "title": "Renamed setting keys",
    "date": "2026-11-10",
    "type": "feature",
    "content": "Each setting key now has the name of the matching option, and a setting of one solver is named after the solver and its MATLAB option, e.g. FminconAlgorithm or FsolveMaxFunctionEvaluations. NaN means automatic (the iteration limit and gradient step size of the power flow, where 0 meant automatic), and on/off settings are true/false. The power flow has a new message setting. Saved values of renamed keys return to the default; change a saved iteration limit or gradient step size of 0 to NaN."
  }
];
