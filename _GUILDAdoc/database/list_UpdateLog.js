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
  }
];
