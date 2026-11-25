window.GUILDA_DOC_INDEX = {
  "schema": {
    "name": "GUILDA documentation class index",
    "version": 5,
    "classDocumentVersion": 5,
    "pathBase": "_GUILDAdoc",
    "matlabRelease": "2025b",
    "modelCategories": [
      "PowerNetwork",
      "Bus",
      "Branch",
      "Component",
      "LocalController",
      "GlobalController"
    ],
    "coreClasses": [
      "PowerNetwork",
      "Bus",
      "Branch",
      "Component",
      "LocalController",
      "GlobalController"
    ],
    "tags": {
      "class": [
        "Examples",
        "Citations",
        "Deprecated"
      ],
      "property": [
        "Type",
        "Stale",
        "Deprecated"
      ],
      "method": [
        "Examples",
        "Group",
        "Deprecated"
      ],
      "removed": {
        "Summary": "write the summary as the first comment line (H1 line)",
        "Desc": "write the description as the comment lines after the H1 line",
        "Role": "the role is derived from the class hierarchy",
        "Category": "the category is derived from the package",
        "Constructor": "document the constructor method and use <@Examples>",
        "Notes": "write notes in the description",
        "SeeAlso": "write a \"See also A, B\" line",
        "Since": "record changes in the Update log",
        "Signatures": "signatures are derived from the function line and arguments blocks",
        "Parameters": "describe inputs with comments in an arguments block",
        "Returns": "describe outputs with comments in an arguments (Output) block",
        "Calls": "calls are no longer documented",
        "Throws": "error IDs are collected from error(msg(...)) and MException(...) calls",
        "Size": "state the size in the declaration",
        "Default": "state the default value in the declaration",
        "Constraints": "state constraints with validators in the declaration",
        "Unit": "start the comment with the unit, e.g. \"[MVA] Base power.\"",
        "Model": "describe the model in the H1 line or the description",
        "Abst": "write the summary as the first comment line (H1 line)",
        "Description": "write the description as the comment lines after the H1 line",
        "varargin": "describe inputs with comments in an arguments block",
        "varargout": "describe outputs with comments in an arguments (Output) block",
        "DetailsCode": "write details in the description",
        "Example": "use <@Examples>",
        "Seealso": "write a \"See also A, B\" line"
      }
    }
  },
  "classes": [
    {
      "Name": "auxiliary",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "handle",
      "Superclasses": [
        "handle"
      ],
      "Ancestors": [
        "handle"
      ],
      "Subclasses": [
        "ContinuationPowerFlowV3",
        "CsvNetHandler",
        "DrawerGUILDA",
        "DrawerModelGUI",
        "DrawerOptionDialog",
        "DrawerResultGUI",
        "DrawerTagPicker",
        "EventBase",
        "GraphBase",
        "GraphEventData",
        "GraphTimeEventData",
        "HistoryGUILDA",
        "MethodBase",
        "MethodDynamic",
        "Parameter",
        "ProgressGUILDA",
        "ResultBase",
        "Scenario",
        "SolverCPF",
        "SolverLIN",
        "SolverODE",
        "SolverOPF",
        "SolverPF"
      ],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@auxiliary/auxiliary.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the classes that assist analyses (solvers, results, parameters, drawers).",
      "Desc": "It separates the classes that make up the power system model from those intended for\nanalysis assistance:\n\n- Classes that constitute the power system model inherit from PowerSystemModel.\n- Classes intended for analysis assistance inherit from auxiliary.\n\n`obj.doc()` opens the class reference page of the object's class.",
      "SeeAlso": [
        "PowerSystemModel",
        "ResultBase"
      ],
      "Examples": "",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 0
      },
      "MethodCount": {
        "Own": 2,
        "Total": 2
      },
      "path": "./database/GUILDAsystem/auxiliary.js",
      "Image": ""
    },
    {
      "Name": "Branch",
      "Origin": "System",
      "Folder": "_GUILDAsystem",
      "Category": "",
      "Type": "PowerSystemModel",
      "Model": "Branch",
      "Parent": "PowerSystemModel",
      "Superclasses": [
        "PowerSystemModel"
      ],
      "Ancestors": [
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "branch.pi",
        "branch.pi_transformer",
        "branch.T",
        "branch.two_winding_transformer"
      ],
      "Package": "",
      "File": "_GUILDAsystem/@Branch/Branch.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Abstract class of a line or transformer between two buses, which computes its own 2x2 admittance matrix.",
      "Desc": "The network sums the matrices of its branches into the bus admittance matrix used by the\npower flow, the OPF and the simulation.\n\n- Owns R, X, C, tap, phase, circuit (`tab_parameter.dynamics`), its operating limits\n  (`tab_parameter.operation`: Smax, Imax, Pmax, Qmax, Vargmax) and drawing data, and\n  decides how they form an admittance matrix (the subclass contract\n  `get_admittance_matrix`).\n- Parameters (`tab_parameter`) are per unit on the system base, set by add_branch (R, X,\n  C, Tap, Phase, Circuit and the limits) or by writing the table. An edit of dynamics\n  makes the power flow of the network stale; operation and graph make nothing stale.\n- R, X and C are the values of all circuits together; `circuit` (default 2) is the number\n  of parallel circuits. One circuit has n*R, n*X and C/n, so its closed matrix is the\n  closed matrix of the branch divided by n. Only the states that act on one circuit\n  (\"3LG\", \"3open\") depend on `circuit`.\n- get_admittance_matrix(Status=, Point=) gives the matrix of the branch in one of five\n  states: \"close\" (default, the normal matrix), \"3LG\" (one circuit grounded at Point),\n  \"6LG\" (all circuits grounded at Point), \"3open\" (one circuit open) and \"6open\" (all\n  circuits open: the zero matrix). Point is the fault position along the branch, from 0\n  (from end) to 1 (to end), with 0 < Point < 1; only \"3LG\" and \"6LG\" use it and the other\n  states ignore it. A fault at an end is a bus fault (Scenario.add_fault on the bus).\n  Faults are bolted (no fault resistance). A branch with one circuit has no \"3LG\" or\n  \"3open\" (error GUILDA:Branch:SingleCircuit). The faulted circuit is split at Point into\n  two sections of the same form as the branch (pi into two pi sections, T into two T\n  sections) with the series impedance and the shunt in proportion to their lengths; the\n  shunt at the fault point is shorted to ground. A transformer has its ideal transformer\n  (tap and phase) at the from end, and Point is the position on the series part after it\n  (the series impedance of a two-winding transformer, the pi line of a pi transformer).\n  Common simulators place a transformer fault on a terminal bus and only open a\n  transformer; GUILDA also accepts the fault states for transformers.\n- PowerNetwork.get_admittance_matrix(BranchStatus=) sums these matrices for a table of\n  branch states (the network matrix of a fault or an open branch).\n- Refers to its two end buses (`a_Bus`, from and to), but is not their parent and does\n  not own their voltages. The end voltages and currents it shows are derived from the\n  buses. The order of `a_Bus` is the row and column order of the 2x2 matrix.\n- struct(br) is the LayerPackage struct with one more field, `cm_Y`: the 2x2 matrix of\n  get_admittance_matrix. A network snapshot (struct(net, false)) thus carries the\n  admittance of every branch, also of a branch class of your own; ResultPF reads it.\n- Has no states and no function-handle cache. It takes part in the simulation only\n  through the admittance matrix built when an analysis starts.\n- Created only by `PowerNetwork.add_branch` (the constructors of the concrete classes\n  are accessible only from `PowerNetwork`); only the network sets `a_PowerNetwork` and\n  `a_Bus`, and `PowerNetwork.remove_branch` deletes the branch. No dangling ends: `PowerNetwork.remove_bus` on a bus with\n  branches stops unless RemoveBranches=true.\n\nSubclasses in the `branch` package define `key` (the type name of add_branch), `header`\n(the tag prefix, \"EL\" for lines and \"ET\" for transformers) and `get_admittance_matrix`.",
      "SeeAlso": [
        "PowerNetwork.add_branch",
        "PowerNetwork.get_admittance_matrix",
        "branch.pi",
        "Bus"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nbr  = net.a_Branch{1};               % or net.add_branch(\"pi\", [1,2], R=0.01, X=0.085)\nbr.tab_parameter.dynamics            % R, X, C, tap, phase, circuit\nY   = br.get_admittance_matrix();    % 2x2 admittance matrix\nYo  = br.get_admittance_matrix(Status=\"3open\");             % one of the 2 circuits open\nYf  = br.get_admittance_matrix(Status=\"3LG\", Point=0.3);    % one circuit grounded at 30 %\nbr.tab_parameter.operation.Smax = Inf;   % no apparent-power limit\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_PowerNetwork",
          "Type": "PowerNetwork"
        },
        {
          "Name": "a_Bus",
          "Type": "Bus"
        }
      ],
      "PropertyCount": {
        "Own": 8,
        "Total": 14
      },
      "MethodCount": {
        "Own": 6,
        "Total": 16
      },
      "path": "./database/GUILDAsystem/Branch.js",
      "Image": "./database/images/Branch.svg"
    },
    {
      "Name": "branch.pi",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+branch",
      "Category": "branch",
      "Type": "PowerSystemModel",
      "Model": "Branch",
      "Parent": "Branch",
      "Superclasses": [
        "Branch"
      ],
      "Ancestors": [
        "Branch",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "branch",
      "File": "_GUILDAobject/+branch/@pi/pi.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Transmission line modeled as a pi circuit with shunt capacitance at both ends.",
      "Desc": "The series impedance is `R + 1j*X` and each end has a shunt admittance\n`1j*C`, so `C` is half of the total line charging (`C = b/2`).\nAll values are in per unit on the network base.\n\nA line has no transformer, so tab_parameter.dynamics.tap and .phase are NaN. Tap and\nPhase of add_branch are ignored (with a warning unless Tap is 0 or 1 and Phase is 0); use\nbranch.pi_transformer for an off-nominal tap or a phase shift.\n\nR, X and C are the values of all circuits together (tab_parameter.dynamics.circuit,\ndefault 2). get_admittance_matrix(Status=, Point=) also gives the line with one or all\ncircuits grounded (\"3LG\", \"6LG\" at Point from the from end, 0 < Point < 1) or open\n(\"3open\", \"6open\"); see Branch.\n\n```\n ---+---[R + jX]---+---\n    |              |\n  [jC]           [jC]\n    |              |\n ---+--------------+---\n```",
      "SeeAlso": [
        "branch.pi_transformer",
        "branch.T",
        "PowerNetwork.add_branch"
      ],
      "Examples": "Add a line between buses 1 and 2 of a network:\n\n```matlab\nnet = PowerNetwork();\nnet.add_bus();\nnet.add_bus();\nbr =net.add_branch(\"pi\", [1,2], \"R\",0.01, \"X\",0.085, \"C\",0.0088);\nY  = br.get_admittance_matrix();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 2,
        "Total": 14
      },
      "MethodCount": {
        "Own": 2,
        "Total": 16
      },
      "path": "./database/GUILDAobject/branch.pi.js",
      "Image": ""
    },
    {
      "Name": "branch.pi_transformer",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+branch",
      "Category": "branch",
      "Type": "PowerSystemModel",
      "Model": "Branch",
      "Parent": "Branch",
      "Superclasses": [
        "Branch"
      ],
      "Ancestors": [
        "Branch",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "branch",
      "File": "_GUILDAobject/+branch/@pi_transformer/pi_transformer.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Pi-circuit line with a phase-shifting transformer at the from end.",
      "Desc": "An ideal transformer with complex ratio `tap*exp(1j*phase)` at the from\nbus is followed by a pi line with series impedance `R + 1j*X` and shunt\nadmittance `1j*C` at each end. `tap` [pu] is the voltage magnitude ratio\nand `phase` [rad] the phase shift (set with \"Tap\" and \"Phase\" in\nPowerNetwork.add_branch). Other values are in per unit on the network base.\n\nR, X and C are the values of all circuits together (tab_parameter.dynamics.circuit,\ndefault 2). get_admittance_matrix(Status=, Point=) also gives the branch with one or all\ncircuits grounded (\"3LG\", \"6LG\") or open (\"3open\", \"6open\"); see Branch. The ideal\ntransformer is taken to be at the from end, and Point (0 < Point < 1) is the fault\nposition on the pi line after it. Common simulators place a transformer fault on a\nterminal bus and only open a transformer; GUILDA also accepts the fault states.\n\n```\n ---+  +----+--[R + jX]--+---\n    @  @    |            |\n    @  @  [jC]         [jC]\n    @  @    |            |\n ---+  +----+------------+---\n```",
      "SeeAlso": [
        "branch.pi",
        "branch.two_winding_transformer",
        "PowerNetwork.add_branch"
      ],
      "Examples": "Add a transformer with tap 0.978 between buses 1 and 2 of a network:\n\n```matlab\nnet = PowerNetwork();\nnet.add_bus();\nnet.add_bus();\nbr = net.add_branch(\"pi_transformer\", [1,2], \"X\",0.2091, \"Tap\",0.978);\nY  = br.get_admittance_matrix();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 2,
        "Total": 14
      },
      "MethodCount": {
        "Own": 2,
        "Total": 16
      },
      "path": "./database/GUILDAobject/branch.pi_transformer.js",
      "Image": ""
    },
    {
      "Name": "branch.T",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+branch",
      "Category": "branch",
      "Type": "PowerSystemModel",
      "Model": "Branch",
      "Parent": "Branch",
      "Superclasses": [
        "Branch"
      ],
      "Ancestors": [
        "Branch",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "branch",
      "File": "_GUILDAobject/+branch/@T/T.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Transmission line modeled as a T circuit with the shunt capacitance at the midpoint.",
      "Desc": "The series impedance `R + 1j*X` is split into two halves and the shunt\nadmittance `1j*C` sits between them, so `C` is the total line charging.\nAll values are in per unit on the network base.\n\nA line has no transformer, so tab_parameter.dynamics.tap and .phase are NaN. Tap and\nPhase of add_branch are ignored (with a warning unless Tap is 0 or 1 and Phase is 0); use\nbranch.pi_transformer for an off-nominal tap or a phase shift.\n\nR, X and C are the values of all circuits together (tab_parameter.dynamics.circuit,\ndefault 2). get_admittance_matrix(Status=, Point=) also gives the line with one or all\ncircuits grounded (\"3LG\", \"6LG\" at Point from the from end, 0 < Point < 1) or open\n(\"3open\", \"6open\"); see Branch.\n\n```\n ---[(R+jX)/2]---+---[(R+jX)/2]---\n                 |\n               [jC]\n                 |\n ----------------+----------------\n```",
      "SeeAlso": [
        "branch.pi",
        "PowerNetwork.add_branch"
      ],
      "Examples": "Add a T-model line between buses 1 and 2 of a network:\n\n```matlab\nnet = PowerNetwork();\nnet.add_bus();\nnet.add_bus();\nbr = net.add_branch(\"T\", [1,2], \"R\",0.01, \"X\",0.085, \"C\",0.0176);\nY  = br.get_admittance_matrix();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 2,
        "Total": 14
      },
      "MethodCount": {
        "Own": 2,
        "Total": 16
      },
      "path": "./database/GUILDAobject/branch.T.js",
      "Image": ""
    },
    {
      "Name": "branch.two_winding_transformer",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+branch",
      "Category": "branch",
      "Type": "PowerSystemModel",
      "Model": "Branch",
      "Parent": "Branch",
      "Superclasses": [
        "Branch"
      ],
      "Ancestors": [
        "Branch",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "branch",
      "File": "_GUILDAobject/+branch/@two_winding_transformer/two_winding_transformer.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Two-winding transformer with an off-nominal tap ratio and a phase shift.",
      "Desc": "The series impedance is `R + 1j*X`, the shunt admittance `1j*C` is at the\nfrom end, `tap` [pu] is the voltage magnitude ratio and `phase` [rad] the\nphase shift (set with \"Tap\" and \"Phase\" in PowerNetwork.add_branch).\nOther values are in per unit on the network base.\n\nR, X and C are the values of all circuits together (tab_parameter.dynamics.circuit,\ndefault 2). get_admittance_matrix(Status=, Point=) also gives the branch with one or all\ncircuits grounded (\"3LG\", \"6LG\") or open (\"3open\", \"6open\"); see Branch. The ideal\ntransformer is taken to be at the from end, and Point (0 < Point < 1) is the fault\nposition on the series impedance after it. Common simulators place a transformer fault\non a terminal bus and only open a transformer; GUILDA also accepts the fault states.",
      "SeeAlso": [
        "branch.pi_transformer",
        "PowerNetwork.add_branch"
      ],
      "Examples": "Add a transformer with tap 0.969 between buses 1 and 2 of a network:\n\n```matlab\nnet = PowerNetwork();\nnet.add_bus();\nnet.add_bus();\nbr = net.add_branch(\"two_winding_transformer\", [1,2], \"X\",0.5562, \"Tap\",0.969);\nY  = br.get_admittance_matrix();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 2,
        "Total": 14
      },
      "MethodCount": {
        "Own": 2,
        "Total": 16
      },
      "path": "./database/GUILDAobject/branch.two_winding_transformer.js",
      "Image": ""
    },
    {
      "Name": "Bus",
      "Origin": "System",
      "Folder": "_GUILDAsystem",
      "Category": "",
      "Type": "PowerSystemModel",
      "Model": "Bus",
      "Parent": "PowerSystemModel",
      "Superclasses": [
        "PowerSystemModel"
      ],
      "Ancestors": [
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/@Bus/Bus.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Node of a power network: owns the bus voltage and its components.",
      "Desc": "The bus voltage is the algebraic variable of the network. A bus turns the settings of\nits components into the power-flow specification of the node.\n\n- Owns its voltage (power-flow settings and the equilibrium `c_Vequilibrium`), its shunt\n  admittance, its voltage limits and the list of its components (`a_Component`).\n- The power-flow type (slack, PV, PQ) is not stored: it follows from `l_isSlack` and the\n  Q settings of the components. The slack bus fixes V and Varg, a bus whose components\n  leave Q as NaN is a PV bus, and any other bus is a PQ bus. Setting `l_isSlack` makes the\n  network clear the flag of the other buses (a bus never changes another bus); with no\n  slack bus, `calculate_powerflow` selects one.\n- Parameters (`tab_parameter`) are set by `add_bus` or by writing the table. An edit of\n  powerflow or dynamics (shunt), a slack-bus change and a component added, replaced or\n  removed make the power flow of the network stale (`net.sct_stale.powerflow`);\n  operation and graph make nothing stale. A bus has no stale tags of its own.\n- Down: splits the equilibrium bus power among its components (`set_equilibrium`).\n  Up: aggregates them (current, linear model, variable map).\n- Does not own the system base (baseMVA belongs to `PowerNetwork`; a bus baseMVA given\n  to `add_bus` or in a CSV bus table is accepted and ignored), the branches that end at\n  it (a branch only refers to it; a bus does not know its branches), or any dynamics\n  (components carry the equations).\n- Created only by `PowerNetwork.add_bus`, so a bus is always on a network. Only the\n  parent sets a parent reference: the network sets `a_PowerNetwork`, and the bus sets\n  `Component.a_Bus` of its components. `PowerNetwork.remove_bus` deletes the bus with its\n  components.\n\nWhat differs from bus to bus (slack, PV, PQ, shunt) is data, not a type, so Bus has\nno subclasses.",
      "SeeAlso": [
        "PowerNetwork.add_bus",
        "Component",
        "Branch"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nbus = net.a_Bus{1};\nbus.tab_parameter.powerflow          % V, Varg\nbus.s_bustype                        % \"slack\", \"PV\" or \"PQ\"\ngen = bus.add_component(\"gen-park\", P=0.5);\nbus.remove_component(gen.s_tag);\nsys = bus.get_sys();                 % linear model from V to I\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_PowerNetwork",
          "Type": "PowerNetwork"
        },
        {
          "Name": "a_Component",
          "Type": "Component"
        }
      ],
      "PropertyCount": {
        "Own": 9,
        "Total": 15
      },
      "MethodCount": {
        "Own": 11,
        "Total": 22
      },
      "path": "./database/GUILDAsystem/Bus.js",
      "Image": "./database/images/Bus.svg"
    },
    {
      "Name": "Component",
      "Origin": "System",
      "Folder": "_GUILDAsystem",
      "Category": "",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "PowerSystemModel",
      "Superclasses": [
        "PowerSystemModel"
      ],
      "Ancestors": [
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "component.generator.abstract",
        "component.GFLInverter.abstract",
        "component.GFMInverter.abstract",
        "component.load.abstract"
      ],
      "Package": "",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Abstract class of the equipment connected to a bus, such as generators and loads.",
      "Desc": "A component is a dynamical system with state $x$, input $u$ and output $y$, connected to\nits bus through the bus voltage $V$ and the current $I$ it injects (positive for generation):\n\n- `fcn_dx`, `fcn_Mass`: the state equation M*dx/dt = fcn_dx(t, x, V, u)\n- `fcn_I`: the current injected into the bus, fcn_I(t, x, V, u)\n- `fcn_Y`: the output signals fcn_Y(t, x, V), read by the local and global controllers.\n  The output does not depend on u (no feedthrough), so there is no algebraic loop through\n  the inputs.\n\nNo model function takes the bus current: it is the sum of all the components on the bus.\n\nSubclasses in the `component` package define these static methods, the names of the\nvariables (`sv_x`, `sv_u`, `sv_y`, `sv_para`) and the equilibrium (`get_equilibrium`).\nComponents are created by `Bus.add_component`. Their parameters are in\n`tab_parameter`: dynamics, operation limits, power-flow settings (P, Q), OPF costs and\ndiagram settings, set by `add_component` (dynamics by the subclass constructor) or by\nwriting the table. An edit of dynamics makes the handles and the equilibrium of the\ncomponent stale (stale tags odefcn and equilibrium), an edit of powerflow the power flow\nof the network; operation, OPF and graph make nothing stale. The OPF\ncost of a component is $H_P P^2 + f_P P + H_Q Q^2 + f_Q Q$. Analytic Jacobians (static\nmethods Jacobi_dx, Jacobi_I, Jacobi_Y) are optional; without them the Jacobians are\ncomputed numerically.\n\nRole in the model:\n\n- Owns the device equations (through its subclass), its parameters (dynamics, power-flow\n  P and Q, operation limits, OPF cost, drawing), its equilibrium (`rv_Xequilibrium`,\n  `rv_Uequilibrium`, `c_Iequilibrium`) and its local controllers (`a_LocalController`).\n- The base class turns the static model functions into the cached handles `f_*`, adds its\n  local controllers to the DAE and the linear model, and computes Jacobians numerically\n  when the subclass gives none. The handles @(t,x,V,u) (f_Y and f_JacobiY: @(t,x,V)) bind the parameters and omega0;\n  `set_odefcn` builds them, called by `PowerNetwork.initialize` when they are stale\n  (`sct_stale.odefcn`, or a network frequency other than `r_odefcnHz`).\n- Stale tags (`sct_stale`): `equilibrium` (its dynamics, its local controllers, its\n  attachment) and `odefcn` (its dynamics). `initialize`, called by\n  PowerNetwork.initialize through the bus, rebuilds the handles and recomputes the\n  equilibrium from the held V and I when they are stale.\n- Does not own the bus voltage (it reads `a_Bus.c_Vequilibrium`), the network frequency\n  (it reads `get_Hz()`) or the system base.\n- Created only by `Bus.add_component` and `Bus.replace_component` (the constructors of\n  the concrete classes are accessible only from `Bus`), so a component is always on a\n  bus of a network. Only the bus sets `a_Bus` (`SetAccess`) and logs the attachment as a\n  \"Topology\" edit of the component; the component sets `LocalController.a_Component` of\n  its controllers. `Bus.remove_component` and `Bus.replace_component` delete the\n  component they take out (with its local controllers). A\n  `GlobalController` refers to controlled components in `controlledUnits`; a controlled\n  component cannot be removed or replaced while the controller is on the network.\n\nA new model inherits from `component.generator.abstract`, `component.load.abstract`,\n`component.GFMInverter.abstract` or `component.GFLInverter.abstract`.\nThe framework relies on three more rules:\n\n- `get_equilibrium` is always called with all of c_V, c_I, r_P and r_Q (a trip of\n  `simulate` passes c_I = r_P = r_Q = 0).\n- `fcn_Mass` is constant: `simulate` calls it with empty t, x, V and u.\n- `getCompPQ(obj, x, V, u, param)`, which returns the injected power [P; Q], is needed only\n  by the continuation power flow with `UseInternalState=true`.",
      "SeeAlso": [
        "Bus.add_component",
        "LocalController",
        "component.generator.abstract"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\ngen = net.a_Bus{1}.a_Component{1};\ngen.tab_parameter.powerflow                  % P, Q settings of the power flow\ngen.add_local_controller(\"avr-ST1\");\nnet.initialize();\ngen.rv_Xequilibrium                          % state equilibrium\nsys = gen.get_sys();                         % linear model from V to I\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_Bus",
          "Type": "Bus"
        },
        {
          "Name": "a_LocalController",
          "Type": "LocalController"
        }
      ],
      "PropertyCount": {
        "Own": 26,
        "Total": 32
      },
      "MethodCount": {
        "Own": 28,
        "Total": 38
      },
      "path": "./database/GUILDAsystem/Component.js",
      "Image": "./database/images/Component.svg"
    },
    {
      "Name": "component.ConstSource.power",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+ConstSource",
      "Category": "component.ConstSource",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.load.abstract",
      "Superclasses": [
        "component.load.abstract"
      ],
      "Ancestors": [
        "component.load.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.ConstSource",
      "File": "_GUILDAobject/+component/+ConstSource/@power/power.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Legacy constant-power load model with the v1 component interface.",
      "Desc": "The model has no states and two input ports, `RealPower` and `ReactivePower`\n(`naming_port`). It uses the old interface (`get_dx_constraint`,\n`get_linear_matrix`) and does not define the model constants of `Component`\n(`key`, `sv_x`, `sv_u`, `sv_y`, `sv_para`), so it cannot be created or added to a\nbus.",
      "SeeAlso": [
        "component.load.power"
      ],
      "Examples": "",
      "Citations": "",
      "Deprecated": "Use `component.load.power` (key `\"load-power\"`).",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 32
      },
      "MethodCount": {
        "Own": 5,
        "Total": 33
      },
      "path": "./database/GUILDAobject/component.ConstSource.power.js",
      "Image": ""
    },
    {
      "Name": "component.generator.abstract",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+generator",
      "Category": "component.generator",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "Component",
      "Superclasses": [
        "Component"
      ],
      "Ancestors": [
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "component.generator.classical",
        "component.generator.droop",
        "component.generator.one_axis",
        "component.generator.park",
        "component.generator.two_axis"
      ],
      "Package": "component.generator",
      "File": "_GUILDAobject/+component/+generator/@abstract/abstract.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the synchronous generator models.",
      "Desc": "A generator model connects to one bus, takes the mechanical power `Pmech` and\nthe field voltage `Vfield` as input signals, and injects a current into the bus.\nSubclasses define the state variables, the equations and the parameter names\n(`sv_x`, `sv_u`, `sv_y`, `sv_para`).\n\nAdd a generator with `Bus.add_component` and a model key such as\n`\"gen-classical\"`, `\"gen-1axis\"`, `\"gen-2axis\"`, `\"gen-park\"` or `\"gen-droop\"`.\nIn the power flow the generator is a PV source: `tab_parameter.powerflow.Q`\nis always `NaN`. A `Q` other than `NaN` or 0 is ignored with a warning.\n\nThe `parameter` argument of `add_component` sets the dynamic parameters:\n- a table whose columns include the names in `sv_para`;\n- `\"NGT2\"`, `\"NGT6\"` or `\"NGT8\"`, a row of the bundled `parameter.csv`;\n- anything else but text (default `NaN`): the first row of `parameter.csv` (NGT2).\n\nA missing column or another name stops with an error.\n\nA new generator has a Static AVR (`\"avr-static\"`) and a Static governor\n(`\"gov-static\"`), which keep `Vfield` and `Pmech` at their equilibrium\n(controller.avr.Static, controller.governor.Static). Another AVR or governor\nreplaces them without a warning. A model without the input `Vfield` (`Pmech`) gets\nno Static AVR (governor).",
      "SeeAlso": [
        "Component",
        "Bus.add_component",
        "component.generator.classical",
        "component.generator.park"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\ngen = bus.add_component(\"gen-1axis\", \"P\", 0.5, \"parameter\", \"NGT6\");\ngen.tab_parameter.dynamics          % parameters taken from parameter.csv\ngen.add_local_controller(\"avr-ST1\")\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 3,
        "Total": 35
      },
      "MethodCount": {
        "Own": 6,
        "Total": 36
      },
      "path": "./database/GUILDAobject/component.generator.abstract.js",
      "Image": ""
    },
    {
      "Name": "component.generator.classical",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+generator",
      "Category": "component.generator",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.generator.abstract",
      "Superclasses": [
        "component.generator.abstract"
      ],
      "Ancestors": [
        "component.generator.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.generator",
      "File": "_GUILDAobject/+component/+generator/@classical/classical.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Classical generator model: swing equation with a constant internal voltage.",
      "Desc": "The rotor follows the swing equation. The internal voltage is the field input\n`Vfield` behind the reactances `Xd` and `Xq`; the model has no flux dynamics.\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- `delta` [rad]: Rotor angle in the network reference frame.\n- `omega` [pu]: Rotor speed deviation from the network frequency.\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers)\n- `Pmech` [pu]: Mechanical power (governor output).\n- `Vfield` [pu]: Field voltage (AVR output).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- `omega` [pu]: Rotor speed deviation from the network frequency.\n\n**Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)\n- `M` [s]: Inertia constant (`M = 2H`).\n- `D` [pu]: Damping coefficient.\n- `Xd` [pu]: d-axis synchronous reactance.\n- `Xq` [pu]: q-axis synchronous reactance.\n\n**Equations** ($\\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$, $I_d$, $I_q$\nare the bus voltage and current in the rotor dq frame)\n```math\n\\left\\{\n\\begin{aligned}\n\\dot{\\delta} &= 2\\pi\\omega_0\\,\\omega \\\\\nM\\dot{\\omega} &= -D\\,\\omega - P + P_\\mathrm{mech}\n\\end{aligned}\n\\right.\n```\nwith\n```math\nI_d = \\frac{V_\\mathrm{field} - V_q}{X_d}, \\quad I_q = \\frac{V_d}{X_q}, \\quad P = V_d I_d + V_q I_q\n```",
      "SeeAlso": [
        "component.generator.abstract",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\ngen = bus.add_component(\"gen-classical\", \"P\", 0.5);\ngen.sv_x                          % delta, omega\ngen.tab_parameter.dynamics        % M, D, Xd, Xq\ngen.add_local_controller(\"avr-ST1\")\n```",
      "Citations": "- P. W. Sauer, M. A. Pai, and J. H. Chow, *Power System Dynamics and Stability: With\n  Synchrophasor Measurement and Power System Toolbox*, 2nd ed. Hoboken, NJ, USA:\n  Wiley-IEEE Press, 2017, Sect. 5.6, doi:\n  [10.1002/9781119355755](https://doi.org/10.1002/9781119355755).\n- P. M. Anderson and A. A. Fouad, *Power System Control and Stability*, 2nd ed.\n  Piscataway, NJ, USA: IEEE Press / Wiley-Interscience, 2003, doi:\n  [10.1109/9780470545577](https://doi.org/10.1109/9780470545577).\n- 加藤政一, 『詳解 電力系統工学』, 東京電機大学出版局, 2017, ISBN 978-4-501-11770-2.",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 35
      },
      "MethodCount": {
        "Own": 12,
        "Total": 39
      },
      "path": "./database/GUILDAobject/component.generator.classical.js",
      "Image": ""
    },
    {
      "Name": "component.generator.droop",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+generator",
      "Category": "component.generator",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.generator.abstract",
      "Superclasses": [
        "component.generator.abstract"
      ],
      "Ancestors": [
        "component.generator.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.generator",
      "File": "_GUILDAobject/+component/+generator/@droop/droop.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Droop generator model: first-order angle dynamics without inertia.",
      "Desc": "The rotor inertia is neglected and the angle changes in proportion to the power\nmismatch (droop characteristic). The internal voltage is the field input `Vfield`.\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- `delta` [rad]: Rotor angle in the network reference frame.\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers)\n- `Pmech` [pu]: Mechanical power (governor output).\n- `Vfield` [pu]: Field voltage (AVR output).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- none\n\n**Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)\n- `D` [pu]: Damping coefficient.\n- `Xd` [pu]: d-axis synchronous reactance.\n- `Xq` [pu]: q-axis synchronous reactance.\n\n**Equations** ($\\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$, $I_d$, $I_q$\nare the bus voltage and current in the rotor dq frame)\n```math\n\\frac{D}{2\\pi\\omega_0}\\,\\dot{\\delta} = P_\\mathrm{mech} - P\n```\nwith\n```math\nI_d = \\frac{V_\\mathrm{field} - V_q}{X_d}, \\quad I_q = \\frac{V_d}{X_q}, \\quad P = V_d I_d + V_q I_q\n```\n\nThe model has no output (`sv_y` is empty) and no `omega` state.",
      "SeeAlso": [
        "component.generator.abstract",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\ngen = bus.add_component(\"gen-droop\", \"P\", 0.5);\ngen.sv_x                          % delta\ngen.tab_parameter.dynamics        % D, Xd, Xq\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 35
      },
      "MethodCount": {
        "Own": 10,
        "Total": 38
      },
      "path": "./database/GUILDAobject/component.generator.droop.js",
      "Image": ""
    },
    {
      "Name": "component.generator.one_axis",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+generator",
      "Category": "component.generator",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.generator.abstract",
      "Superclasses": [
        "component.generator.abstract"
      ],
      "Ancestors": [
        "component.generator.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.generator",
      "File": "_GUILDAobject/+component/+generator/@one_axis/one_axis.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "One-axis generator model: swing equation with q-axis transient dynamics.",
      "Desc": "The rotor follows the swing equation and the q-axis internal voltage `Eq`\nfollows the field circuit (flux decay model).\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- `delta` [rad]: Rotor angle in the network reference frame.\n- `omega` [pu]: Rotor speed deviation from the network frequency.\n- `Eq` [pu]: q-axis internal voltage behind the transient reactance.\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers)\n- `Pmech` [pu]: Mechanical power (governor output).\n- `Vfield` [pu]: Field voltage (AVR output).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- `omega` [pu]: Rotor speed deviation from the network frequency.\n- `Ifield` [pu]: Field current, the right-hand side of the `Eq` equation without `Vfield`\n  (`Ifield = Vfield - Td'*dEq/dt`; textbook (5.30)). An AVR_ST1 reads it for its\n  output limit `gamma_max*|V| - k0*Ifield`.\n\n**Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)\n- `M` [s]: Inertia constant (`M = 2H`).\n- `D` [pu]: Damping coefficient.\n- `Xd` [pu]: d-axis synchronous reactance.\n- `Xq` [pu]: q-axis synchronous reactance.\n- `Xd_p` [pu]: d-axis transient reactance.\n- `Td_p` [s]: d-axis open-circuit transient time constant.\n\n**Equations** ($\\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$, $I_d$, $I_q$\nare the bus voltage and current in the rotor dq frame; a prime marks a transient\nquantity, e.g. $X_d'$ is `Xd_p`)\n```math\n\\left\\{\n\\begin{aligned}\n\\dot{\\delta} &= 2\\pi\\omega_0\\,\\omega \\\\\nM\\dot{\\omega} &= -D\\,\\omega - P + P_\\mathrm{mech} \\\\\nT_{d}'\\dot{E}_q &= -E_q - (X_d - X_d')\\,I_d + V_\\mathrm{field}\n\\end{aligned}\n\\right.\n```\nwith\n```math\nI_d = \\frac{E_q - V_q}{X_d'}, \\quad I_q = \\frac{V_d}{X_q}, \\quad P = V_d I_d + V_q I_q\n```",
      "SeeAlso": [
        "component.generator.abstract",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\ngen = bus.add_component(\"gen-1axis\", \"P\", 0.5);\ngen.sv_x                          % delta, omega, Eq\ngen.tab_parameter.dynamics        % M, D, Xd, Xq, ...\ngen.add_local_controller(\"avr-ST1\")\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Sect. 2.3.2, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).\n- P. W. Sauer, M. A. Pai, and J. H. Chow, *Power System Dynamics and Stability: With\n  Synchrophasor Measurement and Power System Toolbox*, 2nd ed. Hoboken, NJ, USA:\n  Wiley-IEEE Press, 2017, Sect. 5.5, doi:\n  [10.1002/9781119355755](https://doi.org/10.1002/9781119355755).\n- P. M. Anderson and A. A. Fouad, *Power System Control and Stability*, 2nd ed.\n  Piscataway, NJ, USA: IEEE Press / Wiley-Interscience, 2003, doi:\n  [10.1109/9780470545577](https://doi.org/10.1109/9780470545577).\n- N. Tsolas, A. Arapostathis, and P. Varaiya, \"A structure preserving energy function\n  for power system transient stability analysis,\" *IEEE Trans. Circuits Syst.*, vol.\n  CAS-32, no. 10, pp. 1041–1049, 1985, doi:\n  [10.1109/TCS.1985.1085625](https://doi.org/10.1109/TCS.1985.1085625).\n- P. Varaiya, F. F. Wu, and R.-L. Chen, \"Direct methods for transient stability analysis\n  of power systems: Recent results,\" *Proc. IEEE*, vol. 73, no. 12, pp. 1703–1715, 1985,\n  doi: [10.1109/PROC.1985.13366](https://doi.org/10.1109/PROC.1985.13366).\n- H.-D. Chiang, *Direct Methods for Stability Analysis of Electric Power Systems:\n  Theoretical Foundation, BCU Methodologies, and Applications*. Hoboken, NJ, USA: Wiley,\n  2011, doi: [10.1002/9780470872130](https://doi.org/10.1002/9780470872130).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 35
      },
      "MethodCount": {
        "Own": 12,
        "Total": 39
      },
      "path": "./database/GUILDAobject/component.generator.one_axis.js",
      "Image": ""
    },
    {
      "Name": "component.generator.park",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+generator",
      "Category": "component.generator",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.generator.abstract",
      "Superclasses": [
        "component.generator.abstract"
      ],
      "Ancestors": [
        "component.generator.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.generator",
      "File": "_GUILDAobject/+component/+generator/@park/park.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Park generator model: swing equation with transient and subtransient dynamics.",
      "Desc": "The rotor follows the swing equation. The transient voltages `Eq`, `Ed` and the\nsubtransient flux linkages `psiq`, `psid` follow the field and damper circuits\n(sixth-order model).\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- `delta` [rad]: Rotor angle in the network reference frame.\n- `omega` [pu]: Rotor speed deviation from the network frequency.\n- `Eq` [pu]: q-axis internal voltage behind the transient reactance.\n- `Ed` [pu]: d-axis internal voltage behind the transient reactance.\n- `psiq` [pu]: q-axis subtransient flux linkage.\n- `psid` [pu]: d-axis subtransient flux linkage.\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers)\n- `Pmech` [pu]: Mechanical power (governor output).\n- `Vfield` [pu]: Field voltage (AVR output).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- `omega` [pu]: Rotor speed deviation from the network frequency.\n- `Ifield` [pu]: Field current, the right-hand side of the `Eq` equation without `Vfield`\n  (`Ifield = Vfield - Td'*dEq/dt`; textbook (5.30)). An AVR_ST1 reads it for its\n  output limit `gamma_max*|V| - k0*Ifield`.\n\n**Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)\n- `M` [s]: Inertia constant (`M = 2H`).\n- `D` [pu]: Damping coefficient.\n- `Xd` [pu]: d-axis synchronous reactance.\n- `Xd_p` [pu]: d-axis transient reactance.\n- `Xd_pp` [pu]: d-axis subtransient reactance.\n- `Xq` [pu]: q-axis synchronous reactance.\n- `Xq_p` [pu]: q-axis transient reactance.\n- `Xq_pp` [pu]: q-axis subtransient reactance.\n- `Td_p` [s]: d-axis open-circuit transient time constant.\n- `Td_pp` [s]: d-axis open-circuit subtransient time constant.\n- `Tq_p` [s]: q-axis open-circuit transient time constant.\n- `Tq_pp` [s]: q-axis open-circuit subtransient time constant.\n- `X_ls` [pu]: Armature leakage reactance.\n\n**Equations** ($\\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$, $I_d$, $I_q$\nare the bus voltage and current in the rotor dq frame; one and two primes mark transient\nand subtransient quantities, e.g. $X_d'$ is `Xd_p` and $X_d''$ is `Xd_pp`)\n```math\n\\left\\{\n\\begin{aligned}\n\\dot{\\delta} &= 2\\pi\\omega_0\\,\\omega \\\\\nM\\dot{\\omega} &= -D\\,\\omega - P + P_\\mathrm{mech} \\\\\nT_{d}'\\dot{E}_q &= -E_q - (X_d - X_d')\\left(I_d + \\frac{X_d' - X_d''}{(X_d' - X_{ls})^2}\\,T_{d}''\\dot{\\psi}_d\\right) + V_\\mathrm{field} \\\\\nT_{q}'\\dot{E}_d &= -E_d + (X_q - X_q')\\left(I_q + \\frac{X_q' - X_q''}{(X_q' - X_{ls})^2}\\,T_{q}''\\dot{\\psi}_q\\right) \\\\\nT_{q}''\\dot{\\psi}_q &= -\\psi_q - E_d - (X_q' - X_{ls})\\,I_q \\\\\nT_{d}''\\dot{\\psi}_d &= -\\psi_d + E_q - (X_d' - X_{ls})\\,I_d\n\\end{aligned}\n\\right.\n```\nwith\n```math\n\\begin{aligned}\nI_d &= \\frac{1}{X_d''}\\left(\\frac{(X_d'' - X_{ls})E_q + (X_d' - X_d'')\\psi_d}{X_d' - X_{ls}} - V_q\\right) \\\\\nI_q &= \\frac{1}{X_q''}\\left(V_d - \\frac{(X_q'' - X_{ls})E_d - (X_q' - X_q'')\\psi_q}{X_q' - X_{ls}}\\right) \\\\\nP &= V_d I_d + V_q I_q\n\\end{aligned}\n```",
      "SeeAlso": [
        "component.generator.abstract",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\ngen = bus.add_component(\"gen-park\", \"P\", 0.5);\ngen.sv_x                          % delta, omega, Eq, Ed, psiq, psid\ngen.tab_parameter.dynamics        % M, D, Xd, Xd_p, ...\ngen.add_local_controller(\"avr-ST1\")\n```",
      "Citations": "- P. W. Sauer, M. A. Pai, and J. H. Chow, *Power System Dynamics and Stability: With\n  Synchrophasor Measurement and Power System Toolbox*, 2nd ed. Hoboken, NJ, USA:\n  Wiley-IEEE Press, 2017, doi:\n  [10.1002/9781119355755](https://doi.org/10.1002/9781119355755).\n- P. Kundur, *Power System Stability and Control*. New York, NY, USA: McGraw-Hill, 1994,\n  ISBN 0-07-035958-X.\n- 電気協同研究会 系統安定化専門委員会, 「電力系統の安定度」, 『電気協同研究』, vol. 34,\n  no. 5, 1979.",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 35
      },
      "MethodCount": {
        "Own": 12,
        "Total": 39
      },
      "path": "./database/GUILDAobject/component.generator.park.js",
      "Image": ""
    },
    {
      "Name": "component.generator.two_axis",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+generator",
      "Category": "component.generator",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.generator.abstract",
      "Superclasses": [
        "component.generator.abstract"
      ],
      "Ancestors": [
        "component.generator.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.generator",
      "File": "_GUILDAobject/+component/+generator/@two_axis/two_axis.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Two-axis generator model: swing equation with d- and q-axis transient dynamics.",
      "Desc": "The rotor follows the swing equation, and the internal voltages `Eq` and `Ed`\nfollow the field circuit and the q-axis damper circuit.\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- `delta` [rad]: Rotor angle in the network reference frame.\n- `omega` [pu]: Rotor speed deviation from the network frequency.\n- `Eq` [pu]: q-axis internal voltage behind the transient reactance.\n- `Ed` [pu]: d-axis internal voltage behind the transient reactance.\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers)\n- `Pmech` [pu]: Mechanical power (governor output).\n- `Vfield` [pu]: Field voltage (AVR output).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- `omega` [pu]: Rotor speed deviation from the network frequency.\n- `Ifield` [pu]: Field current, the right-hand side of the `Eq` equation without `Vfield`\n  (`Ifield = Vfield - Td'*dEq/dt`; textbook (5.30)). An AVR_ST1 reads it for its\n  output limit `gamma_max*|V| - k0*Ifield`.\n\n**Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)\n- `M` [s]: Inertia constant (`M = 2H`).\n- `D` [pu]: Damping coefficient.\n- `Xd` [pu]: d-axis synchronous reactance.\n- `Xd_p` [pu]: d-axis transient reactance.\n- `Xq` [pu]: q-axis synchronous reactance.\n- `Xq_p` [pu]: q-axis transient reactance.\n- `Td_p` [s]: d-axis open-circuit transient time constant.\n- `Tq_p` [s]: q-axis open-circuit transient time constant.\n\n**Equations** ($\\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$, $I_d$, $I_q$\nare the bus voltage and current in the rotor dq frame; a prime marks a transient\nquantity, e.g. $X_d'$ is `Xd_p`)\n```math\n\\left\\{\n\\begin{aligned}\n\\dot{\\delta} &= 2\\pi\\omega_0\\,\\omega \\\\\nM\\dot{\\omega} &= -D\\,\\omega - P + P_\\mathrm{mech} \\\\\nT_{d}'\\dot{E}_q &= -E_q - (X_d - X_d')\\,I_d + V_\\mathrm{field} \\\\\nT_{q}'\\dot{E}_d &= -E_d + (X_q - X_q')\\,I_q\n\\end{aligned}\n\\right.\n```\nwith\n```math\nI_d = \\frac{E_q - V_q}{X_d'}, \\quad I_q = \\frac{V_d - E_d}{X_q'}, \\quad P = V_d I_d + V_q I_q\n```",
      "SeeAlso": [
        "component.generator.abstract",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\ngen = bus.add_component(\"gen-2axis\", \"P\", 0.5);\ngen.sv_x                          % delta, omega, Eq, Ed\ngen.tab_parameter.dynamics        % M, D, Xd, Xd_p, ...\ngen.add_local_controller(\"avr-ST1\")\n```",
      "Citations": "- P. W. Sauer, M. A. Pai, and J. H. Chow, *Power System Dynamics and Stability: With\n  Synchrophasor Measurement and Power System Toolbox*, 2nd ed. Hoboken, NJ, USA:\n  Wiley-IEEE Press, 2017, Sect. 5.4, doi:\n  [10.1002/9781119355755](https://doi.org/10.1002/9781119355755).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 35
      },
      "MethodCount": {
        "Own": 12,
        "Total": 39
      },
      "path": "./database/GUILDAobject/component.generator.two_axis.js",
      "Image": ""
    },
    {
      "Name": "component.GFLInverter.abstract",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+GFLInverter",
      "Category": "component.GFLInverter",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "Component",
      "Superclasses": [
        "Component"
      ],
      "Ancestors": [
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "component.GFLInverter.Static"
      ],
      "Package": "component.GFLInverter",
      "File": "_GUILDAobject/+component/+GFLInverter/@abstract/abstract.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the grid-following inverter models.",
      "Desc": "A grid-following inverter connects to one bus, follows the bus voltage and injects the\ncurrent that delivers its power references. Its tag is the bus tag + `\"GFL\"` + a number,\ne.g. `\"B001GFL1\"`. In the power flow it is a PQ source: `tab_parameter.powerflow.P` and\n`Q` are injected into the bus (positive for generation). Like a load, its default OPF\ncost is 0 and the OPF keeps its power-flow P and Q when it has no output limits.\nAdd a grid-following inverter with `Bus.add_component` and the key `\"gfl-static\"`.",
      "SeeAlso": [
        "Component",
        "Bus.add_component",
        "component.GFLInverter.Static",
        "component.GFMInverter.abstract"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\ngfl = bus.add_component(\"gfl-static\", \"P\", 0.4, \"Q\", 0.1);\ngfl.tab_parameter.powerflow       % P = 0.4, Q = 0.1\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 32
      },
      "MethodCount": {
        "Own": 1,
        "Total": 31
      },
      "path": "./database/GUILDAobject/component.GFLInverter.abstract.js",
      "Image": ""
    },
    {
      "Name": "component.GFLInverter.Static",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+GFLInverter",
      "Category": "component.GFLInverter",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.GFLInverter.abstract",
      "Superclasses": [
        "component.GFLInverter.abstract"
      ],
      "Ancestors": [
        "component.GFLInverter.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.GFLInverter",
      "File": "_GUILDAobject/+component/+GFLInverter/@Static/Static.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Grid-following inverter that injects constant power.",
      "Desc": "The inverter injects the power `Pref + jQref` into the bus whatever the voltage, as\nthe constant-power load `component.load.power` with the opposite naming of the sign\n(positive for generation). The steady inputs come from the power-flow solution\n(`get_equilibrium`). The inverter internals and the inner control loops are not modeled.\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- none\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)\n- `Pref` [pu]: active power injected into the bus (positive for generation).\n- `Qref` [pu]: reactive power injected into the bus (positive for generation).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- none\n\n**Parameters** (`sv_para`)\n- none\n\n**Equation**\n```math\nI = \\overline{\\left(\\frac{P_\\mathrm{ref} + jQ_\\mathrm{ref}}{V}\\right)}\n```",
      "SeeAlso": [
        "component.GFLInverter.abstract",
        "component.load.power",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\ngfl = bus.add_component(\"gfl-static\", \"P\", 0.4, \"Q\", 0.1);\ngfl.s_tag                         % \"B001GFL1\"\ngfl.sv_u                          % Pref, Qref\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 32
      },
      "MethodCount": {
        "Own": 11,
        "Total": 35
      },
      "path": "./database/GUILDAobject/component.GFLInverter.Static.js",
      "Image": ""
    },
    {
      "Name": "component.GFMInverter.abstract",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+GFMInverter",
      "Category": "component.GFMInverter",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "Component",
      "Superclasses": [
        "Component"
      ],
      "Ancestors": [
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "component.GFMInverter.VSG_classical"
      ],
      "Package": "component.GFMInverter",
      "File": "_GUILDAobject/+component/+GFMInverter/@abstract/abstract.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the grid-forming inverter models.",
      "Desc": "A grid-forming inverter connects to one bus, sets its own internal voltage and\nfrequency, and injects a current into the bus. Subclasses define the state variables,\nthe equations and the parameter names (`sv_x`, `sv_u`, `sv_y`, `sv_para`).\n\nAdd a grid-forming inverter with `Bus.add_component` and a model key such as\n`\"gfm-vsg-classical\"`. Its tag is the bus tag + `\"GFM\"` + a number, e.g. `\"B001GFM1\"`.\nIn the power flow the inverter is a PV source: `tab_parameter.powerflow.Q` is always\n`NaN`. A `Q` other than `NaN` or 0 is ignored with a warning.\n\nThe `parameter` argument of `add_component` sets the dynamic parameters:\n- a table whose columns include the names in `sv_para`;\n- a name in the column `Name` of the `parameter.csv` bundled with the subclass\n  (in its class folder);\n- anything else but text (default `NaN`): the first row of that `parameter.csv`.\n\nA missing column or another name stops with an error. A new inverter has no local\ncontrollers: its inputs stay at their equilibrium until a controller drives them.",
      "SeeAlso": [
        "Component",
        "Bus.add_component",
        "component.GFMInverter.VSG_classical",
        "component.GFLInverter.abstract"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\nvsg = bus.add_component(\"gfm-vsg-classical\", \"P\", 0.5);\nvsg.s_tag                           % \"B001GFM1\"\nvsg.tab_parameter.dynamics          % parameters taken from parameter.csv\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 32
      },
      "MethodCount": {
        "Own": 1,
        "Total": 31
      },
      "path": "./database/GUILDAobject/component.GFMInverter.abstract.js",
      "Image": ""
    },
    {
      "Name": "component.GFMInverter.VSG_classical",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+GFMInverter",
      "Category": "component.GFMInverter",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.GFMInverter.abstract",
      "Superclasses": [
        "component.GFMInverter.abstract"
      ],
      "Ancestors": [
        "component.GFMInverter.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.GFMInverter",
      "File": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/VSG_classical.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Grid-forming inverter as a virtual synchronous generator of the classical model.",
      "Desc": "The inverter behaves as the classical generator (`component.generator.classical`): the\ninternal angle follows the swing equation and the internal voltage `Vref` sits behind\nthe virtual reactances `Xd` and `Xq`. The current of that classical machine is rotated by\nthe angle `alpha` before it enters the bus. The swing equation uses the virtual power of\nthe classical current before the rotation, $\\tilde{P} = \\cos\\alpha\\,P - \\sin\\alpha\\,Q$ with\n$P + jQ$ the power supplied to the bus, as the phase-compensated VSG of Koizumi et al.:\nwith `alpha` equal to the impedance angle of lossy lines, the network seen in the\nrotated frame is lossless. With `alpha = 0` the model is the classical generator. The\ninverter internals and the inner control loops are not modeled.\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- `delta` [rad]: Internal angle in the network reference frame.\n- `omega` [pu]: Internal frequency deviation from the network frequency.\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers)\n- `Pref` [pu]: Virtual power reference (the mechanical power of the classical model); at\n  the equilibrium it is $\\tilde{P}$, not the bus power $P$ (unless `alpha = 0`).\n- `Vref` [pu]: Internal voltage reference (the field voltage of the classical model).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- `omega` [pu]: Internal frequency deviation from the network frequency.\n\n**Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)\n- `M` [s]: Virtual inertia constant.\n- `D` [pu]: Damping coefficient.\n- `Xd` [pu]: d-axis virtual reactance.\n- `Xq` [pu]: q-axis virtual reactance.\n- `alpha` [rad]: Rotation of the current injected into the bus.\n\n**Equations** ($\\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$ are the bus\nvoltage in the internal dq frame, $I_d$, $I_q$ the current of the classical model)\n```math\n\\left\\{\n\\begin{aligned}\n\\dot{\\delta} &= 2\\pi\\omega_0\\,\\omega \\\\\nM\\dot{\\omega} &= -D\\,\\omega - \\tilde{P} + P_\\mathrm{ref}\n\\end{aligned}\n\\right.\n```\nwith\n```math\nI_d = \\frac{V_\\mathrm{ref} - V_q}{X_d}, \\quad I_q = \\frac{V_d}{X_q}, \\quad\nI_0 = e^{j\\delta}(I_q - jI_d), \\quad I = e^{j\\alpha} I_0, \\quad\n\\tilde{P} = \\mathrm{Re}\\left(V\\,\\overline{I_0}\\right)\n```\nwhere $I_0$ is the current of the classical model and $I$ the current injected into the bus.",
      "SeeAlso": [
        "component.GFMInverter.abstract",
        "component.generator.classical",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\nvsg = bus.add_component(\"gfm-vsg-classical\", \"P\", 0.5);\nvsg.sv_x                          % delta, omega\nvsg.tab_parameter.dynamics        % M, D, Xd, Xq, alpha\nvsg.tab_parameter.dynamics.alpha = pi/12;\n```",
      "Citations": "- J. Koizumi, T. Nishino, and T. Ishizaki, \"A necessary and sufficient condition for\n  small-signal stability of lossy power systems with impedance-angle-based\n  phase-compensated inverters,\" in *Proc. 65th IEEE Conf. Decision and Control (CDC)*,\n  2026, to appear.\n- M. Colombino, D. Groß, J.-S. Brouillon, and F. Dörfler, \"Global phase and magnitude\n  synchronization of coupled oscillators with application to the control of grid-forming\n  power inverters,\" *IEEE Trans. Autom. Control*, vol. 64, no. 11, pp. 4496–4511, 2019,\n  doi: [10.1109/TAC.2019.2898549](https://doi.org/10.1109/TAC.2019.2898549).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 32
      },
      "MethodCount": {
        "Own": 12,
        "Total": 35
      },
      "path": "./database/GUILDAobject/component.GFMInverter.VSG_classical.js",
      "Image": ""
    },
    {
      "Name": "component.load.abstract",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+load",
      "Category": "component.load",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "Component",
      "Superclasses": [
        "Component"
      ],
      "Ancestors": [
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "component.ConstSource.power",
        "component.load.current",
        "component.load.impedance",
        "component.load.power",
        "component.load.ZIP"
      ],
      "Package": "component.load",
      "File": "_GUILDAobject/+component/+load/@abstract/abstract.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the load models.",
      "Desc": "A load connects to one bus. Its tag starts with `\"L\"`, and its default OPF cost is 0\nbecause a fixed load adds nothing to the cost. Add a load with `Bus.add_component` and\nthe key `\"load-impedance\"`, `\"load-power\"`, `\"load-current\"` or `\"load-ZIP\"`. Powers\nfollow the bus convention: `P` and `Q` are injected into the bus, so a consuming load\nhas negative `P`. A load without dynamic parameters ignores the `parameter` argument of\n`add_component`; a load with dynamic parameters reads it in its own constructor\n(component.load.ZIP).",
      "SeeAlso": [
        "Component",
        "Bus.add_component",
        "component.load.impedance",
        "component.load.power",
        "component.load.current",
        "component.load.ZIP"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\nld  = bus.add_component(\"load-power\", \"P\", -0.8, \"Q\", -0.3);\nld.tab_parameter.powerflow        % P = -0.8, Q = -0.3\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 32
      },
      "MethodCount": {
        "Own": 1,
        "Total": 31
      },
      "path": "./database/GUILDAobject/component.load.abstract.js",
      "Image": ""
    },
    {
      "Name": "component.load.current",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+load",
      "Category": "component.load",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.load.abstract",
      "Superclasses": [
        "component.load.abstract"
      ],
      "Ancestors": [
        "component.load.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.load",
      "File": "_GUILDAobject/+component/+load/@current/current.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Constant-current load model.",
      "Desc": "The load draws a current of fixed magnitude and power factor from the bus. The\ncurrent keeps its phase relative to the bus voltage: the active part `Ip` is in\nphase with the voltage and the reactive part `Iq` is in quadrature with it. The\nload therefore injects `P = |V|*Ip` and `Q = |V|*Iq`, both proportional to the\nvoltage magnitude. The steady inputs come from the power-flow solution\n(`get_equilibrium`).\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- none\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)\n- `Ip` [pu]: current in phase with the bus voltage, injected into the bus (negative for consumption).\n- `Iq` [pu]: current in quadrature with the bus voltage, injected into the bus (negative for consumption).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- none\n\n**Parameters** (`sv_para`)\n- none\n\n**Equation**\n```math\nI = (I_p - jI_q)\\frac{V}{|V|}, \\quad P + jQ = V\\overline{I} = |V|(I_p + jI_q)\n```\n\n**Energy function**\nThe reactive part has the energy function $-I_q|V|$. The active power $P = |V| I_p$\ndepends on the voltage and has no energy function: `get_hessian` returns the\nJacobian of the port balance, which is not symmetric.",
      "SeeAlso": [
        "component.load.abstract",
        "component.load.power",
        "component.load.impedance",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\nld  = bus.add_component(\"load-current\", \"P\", -0.8, \"Q\", -0.3);\nld.s_tag                          % \"B001LI1\"\nld.sv_u                           % Ip, Iq\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Sect. 2.4.1, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 32
      },
      "MethodCount": {
        "Own": 11,
        "Total": 35
      },
      "path": "./database/GUILDAobject/component.load.current.js",
      "Image": ""
    },
    {
      "Name": "component.load.impedance",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+load",
      "Category": "component.load",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.load.abstract",
      "Superclasses": [
        "component.load.abstract"
      ],
      "Ancestors": [
        "component.load.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.load",
      "File": "_GUILDAobject/+component/+load/@impedance/impedance.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Constant-impedance load model.",
      "Desc": "The load draws the current of a fixed impedance `Z = R + jX` from the bus. The\nimpedance is set from the power-flow solution (`get_equilibrium`), so the load\nconsumes the specified `P` and `Q` at the power-flow voltage and less or more\npower when the voltage changes.\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- none\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)\n- `R` [pu]: resistance of the load.\n- `X` [pu]: reactance of the load.\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- none\n\n**Parameters** (`sv_para`)\n- none\n\n**Equation**\n```math\nI = -\\frac{V}{R + jX}\n```",
      "SeeAlso": [
        "component.load.abstract",
        "component.load.power",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\nld  = bus.add_component(\"load-impedance\", \"P\", -0.8, \"Q\", -0.3);\nld.s_tag                          % \"B001LRX1\"\nld.sv_u                           % R, X\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Sect. 2.4.1, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 32
      },
      "MethodCount": {
        "Own": 10,
        "Total": 34
      },
      "path": "./database/GUILDAobject/component.load.impedance.js",
      "Image": ""
    },
    {
      "Name": "component.load.power",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+load",
      "Category": "component.load",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.load.abstract",
      "Superclasses": [
        "component.load.abstract"
      ],
      "Ancestors": [
        "component.load.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.load",
      "File": "_GUILDAobject/+component/+load/@power/power.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Constant-power load model.",
      "Desc": "The load injects the power `Pload + jQload` into the bus whatever the voltage.\nThe steady inputs come from the power-flow solution (`get_equilibrium`).\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- none\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)\n- `Pload` [pu]: active power injected into the bus (negative for consumption).\n- `Qload` [pu]: reactive power injected into the bus (negative for consumption).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- none\n\n**Parameters** (`sv_para`)\n- none\n\n**Equation**\n```math\nI = \\overline{\\left(\\frac{P_\\mathrm{load} + jQ_\\mathrm{load}}{V}\\right)}\n```",
      "SeeAlso": [
        "component.load.abstract",
        "component.load.impedance",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\nld  = bus.add_component(\"load-power\", \"P\", -0.8, \"Q\", -0.3);\nld.s_tag                          % \"B001LPQ1\"\nld.sv_u                           % Pload, Qload\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Sect. 2.4.1, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 6,
        "Total": 33
      },
      "MethodCount": {
        "Own": 11,
        "Total": 35
      },
      "path": "./database/GUILDAobject/component.load.power.js",
      "Image": ""
    },
    {
      "Name": "component.load.ZIP",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+component/+load",
      "Category": "component.load",
      "Type": "PowerSystemModel",
      "Model": "Component",
      "Parent": "component.load.abstract",
      "Superclasses": [
        "component.load.abstract"
      ],
      "Ancestors": [
        "component.load.abstract",
        "Component",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "component.load",
      "File": "_GUILDAobject/+component/+load/@ZIP/ZIP.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "ZIP load model: a mix of constant-impedance, constant-current and constant-power parts.",
      "Desc": "The power of the load is a polynomial of the bus voltage magnitude $|V|$. The inputs\n`Pload` and `Qload` are the power at $|V| = 1$ pu, and the coefficients `kPZ`, `kPI`,\n`kPP` (`kQZ`, `kQI`, `kQP`) split it into the constant-impedance (Z), constant-current (I)\nand constant-power (P) parts. Below `VswitchP` the constant-power parts and below\n`VswitchI` the constant-current parts become constant impedance, matched continuously at\nthe threshold, so the load current goes to zero with the voltage. The steady inputs come\nfrom the power-flow solution (`get_equilibrium`): the load takes the specified `P` and `Q`\nat the power-flow voltage.\n\n**Dynamic model**\nThe model is a dynamical system with state $x$, input $u$ and output $y$, connected\nto its bus through the bus voltage $V$ and the current $I$ it injects.\n\n**State variables** $x$ (`sv_x`)\n- none\n\n**Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)\n- `Pload` [pu]: active power injected into the bus at $|V| = 1$ pu (negative for consumption).\n- `Qload` [pu]: reactive power injected into the bus at $|V| = 1$ pu (negative for consumption).\n\n**Output signals** $y$ (`sv_y`; read by local controllers)\n- none\n\n**Parameters** (`sv_para`; the `parameter` argument of `Bus.add_component`)\n- `kPZ`, `kPI`, `kPP`: shares of the constant-impedance, constant-current and constant-power parts of `Pload` (default 0, 1, 0).\n- `kQZ`, `kQI`, `kQP`: the same for `Qload` (default 1, 0, 0).\n- `VswitchP` [pu]: voltage below which the constant-power parts are constant impedance (default 0.7).\n- `VswitchI` [pu]: voltage below which the constant-current parts are constant impedance (default 0.7).\n\nThe defaults are the load of the IEEJ standard networks (NLT = 2: constant-current P,\nconstant-impedance Q). The `parameter` argument is a one-row table or a scalar struct\nwith some of these names; a missing name or a NaN value takes the default, and another\nname stops with an error (`ParameterID`, the key column of an imported `dynamics.csv`, is\nignored). `VswitchP` and `VswitchI` must be positive and the coefficients finite; a\ncoefficient sum other than 1 gives a warning (the load then takes a power other than\n`Pload`, `Qload` at 1 pu, but the power flow is still met).\n\n**Equation**\n```math\nP = P_\\mathrm{load}\\, f_P(|V|), \\quad Q = Q_\\mathrm{load}\\, f_Q(|V|), \\quad\nI = \\overline{\\left(\\frac{P + jQ}{V}\\right)}\n```\n```math\nf_P(v) = k_{PZ} v^2 + k_{PI}\\, g_I(v) + k_{PP}\\, g_P(v), \\quad\ng_I(v) = \\begin{cases} v & v \\ge V_\\mathrm{switchI} \\\\ v^2 / V_\\mathrm{switchI} & v < V_\\mathrm{switchI} \\end{cases}, \\quad\ng_P(v) = \\begin{cases} 1 & v \\ge V_\\mathrm{switchP} \\\\ v^2 / V_\\mathrm{switchP}^2 & v < V_\\mathrm{switchP} \\end{cases}\n```\nand $f_Q$ the same with $k_{QZ}$, $k_{QI}$, $k_{QP}$.",
      "SeeAlso": [
        "component.load.abstract",
        "component.load.power",
        "component.load.impedance",
        "Bus.add_component"
      ],
      "Examples": "```matlab\nnet = PowerNetwork();\nbus = net.add_bus();\nld  = bus.add_component(\"load-ZIP\", \"P\", -0.8, \"Q\", -0.3);\nld.s_tag                          % \"B001LZIP1\"\nld.tab_parameter.dynamics         % kPI = 1, kQZ = 1, VswitchP = VswitchI = 0.7\nld2 = bus.add_component(\"load-ZIP\", \"P\", -0.5, \"Q\", -0.1, ...\n          \"parameter\", struct(\"kPZ\", 0.3, \"kPI\", 0.3, \"kPP\", 0.4));\n```",
      "Citations": "- 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,\n  電気学会技術報告 第754号, 1999.\n- 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,\n  [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)\n  (accessed 2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 32
      },
      "MethodCount": {
        "Own": 13,
        "Total": 37
      },
      "path": "./database/GUILDAobject/component.load.ZIP.js",
      "Image": ""
    },
    {
      "Name": "ContinuationPowerFlowV3",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_VersionSupport",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "v3 view of the continuation power flow, returned by Continuation_Power_Flow(net, opt).",
      "Desc": "It keeps the v3 option names (CPFBus, CPFInitLam, CPFMaxIter, CPFStepSize, CPFArcL,\nCPFUseInternal), `[sol, sol_pred] = solve(obj)` and `CPF_Result.x_sol` / `x_prd`.\nsolve runs net.calculate_continuation_powerflow with these options; net.solver_CPF is\nnot changed. Differences from v3: sol and sol_pred are in the full variable layout\n(the same as CPF_Result.x_sol / x_prd, lambda in the last row), CPF_Result.result holds\nthe ResultCPF, and an empty CPFBus stops with an error instead of a warning. The v3\noptions CPFFcn, CPFJac and CPFInitVal are not supported.",
      "SeeAlso": [
        "Continuation_Power_Flow",
        "PowerNetwork.calculate_continuation_powerflow",
        "ResultCPF"
      ],
      "Examples": "```matlab\ncpf = Continuation_Power_Flow(net, struct(\"CPFBus\", [\"B009\",\"B010\"]));\n[sol, sol_pred] = cpf.solve;\n```",
      "Citations": "",
      "Deprecated": "Use net.calculate_continuation_powerflow(LoadBus=sv_bus), which returns a ResultCPF.",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 8,
        "Total": 8
      },
      "MethodCount": {
        "Own": 2,
        "Total": 3
      },
      "path": "./database/GUILDAsystem/ContinuationPowerFlowV3.js",
      "Image": ""
    },
    {
      "Name": "controller.agc.broadcast_PI_AGC",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+agc",
      "Category": "controller.agc",
      "Type": "PowerSystemModel",
      "Model": "GlobalController",
      "Parent": "GlobalController",
      "Superclasses": [
        "GlobalController"
      ],
      "Ancestors": [
        "GlobalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.agc",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/broadcast_PI_AGC.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Automatic generation control that broadcasts one PI command to several generators.",
      "Desc": "The controller observes the frequency deviations of the controlled generators and\ndrives the `Pmech` input of each of them.\n\n**Dynamic model**\nThe controller is a dynamical system with state $x$, input $u$ and output $y$.\n\n**State variables** $x$ (`sv_x`)\n- `xi`: Integral of the broadcast frequency.\n\n**Input signals** $u$ (`sv_u`, one per controlled generator $i$)\n- `omega` [pu]: Frequency deviation $\\omega_i$ of the generator.\n\n**Output signals** $y$ (`sv_y`, one per controlled generator $i$)\n- `Pmech` [pu]: Mechanical power command $P_{\\mathrm{mech},i}$, added to the `Pmech`\n  input of the generator.\n\n**Equations**\n```math\n\\dot{\\xi} = w, \\qquad w = \\sum_i \\beta_i\\,\\omega_i, \\qquad P_{\\mathrm{mech},i} = -\\alpha_i\\,(k_P\\,w + k_I\\,\\xi)\n```\n\n$\\alpha_i$ (`alpha`) shares the command among the generators and $\\beta_i$ (`beta`)\nweights their frequency deviations.",
      "SeeAlso": [
        "GlobalController",
        "PowerNetwork.add_global_controller"
      ],
      "Examples": "Control the generators at buses 1 and 2 and simulate a fault:\n\n```matlab\nnet = network.IEEE9bus();\ng1  = net.a_Bus{1}.a_Component{1};\ng2  = net.a_Bus{2}.a_Component{1};\nagc = net.add_global_controller(\"agc-PI\", {g1, g2}, parameter=struct(kP=100, kI=500));\nnet.initialize;\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B007\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Sect. 5.1.1, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 6,
        "Total": 26
      },
      "MethodCount": {
        "Own": 7,
        "Total": 25
      },
      "path": "./database/GUILDAobject/controller.agc.broadcast_PI_AGC.js",
      "Image": ""
    },
    {
      "Name": "controller.avr.abstract",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+avr",
      "Category": "controller.avr",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "LocalController",
      "Superclasses": [
        "LocalController"
      ],
      "Ancestors": [
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "controller.avr.AVR_DC1",
        "controller.avr.AVR_ST1"
      ],
      "Package": "controller.avr",
      "File": "_GUILDAobject/+controller/+avr/@abstract/abstract.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the automatic voltage regulators (AVR) attached to a generator.",
      "Desc": "An AVR observes the terminal voltage `V` [pu] of the generator and takes the\ninput signals `u = [Vref; Vpss]` [pu]: the voltage reference and the output of an\nattached PSS. Its output signal `Vfield` [pu] is the field voltage input of the\ngenerator. A PSS is attached to the AVR as its own local controller.",
      "SeeAlso": [
        "controller.avr.AVR_ST1",
        "controller.avr.AVR_DC1",
        "controller.pss.abstract"
      ],
      "Examples": "",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 30
      },
      "MethodCount": {
        "Own": 2,
        "Total": 34
      },
      "path": "./database/GUILDAobject/controller.avr.abstract.js",
      "Image": ""
    },
    {
      "Name": "controller.avr.AVR_DC1",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+avr",
      "Category": "controller.avr",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "controller.avr.abstract",
      "Superclasses": [
        "controller.avr.abstract"
      ],
      "Ancestors": [
        "controller.avr.abstract",
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.avr",
      "File": "_GUILDAobject/+controller/+avr/@AVR_DC1/AVR_DC1.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Automatic voltage regulator with a DC exciter (IEEE type DC1).",
      "Desc": "The AVR observes the terminal voltage $V$ [pu] of the generator it is attached to\nand drives the field voltage input of the generator.\n\n**Dynamic model**\nThe controller is a dynamical system with state $x$, input $u$ and output $y$.\n\n**State variables** $x$ (`sv_x`)\n- `Vtr` [pu]: Transducer output.\n- `Vap` [pu]: Amplifier output.\n- `Vfld` [pu]: Exciter output (field voltage).\n- `Vst` [pu]: Stabilizing feedback.\n\n**Input signals** $u$ (`sv_u`)\n- `Vref` [pu]: Voltage reference.\n- `Vpss` [pu]: Output of the attached PSS (0 without a PSS).\n\n**Output signals** $y$ (`sv_y`)\n- `Vfield` [pu]: Field voltage, the `Vfield` input of the generator.\n\n**Equations** (transducer, amplifier, exciter, stabilizing feedback)\n```math\n\\left\\{\n\\begin{aligned}\nt_\\mathrm{tr}\\dot{V}_\\mathrm{tr} &= -V_\\mathrm{tr} + |V| \\\\\nt_\\mathrm{ap}\\dot{V}_\\mathrm{ap} &= -V_\\mathrm{ap} + k_\\mathrm{ap}\\,(V_\\mathrm{ref} + V_\\mathrm{pss} - V_\\mathrm{tr} - V_\\mathrm{st}) \\\\\nt_\\mathrm{ex}\\dot{V}_\\mathrm{fld} &= -\\left(a_\\mathrm{ex1} + a_\\mathrm{ex2}\\,e^{b_\\mathrm{ex}V_\\mathrm{fld}}\\right)V_\\mathrm{fld} + V_\\mathrm{ap} \\\\\nt_\\mathrm{st}\\dot{V}_\\mathrm{st} &= -V_\\mathrm{st} + k_\\mathrm{st}\\,\\dot{V}_\\mathrm{fld}\n\\end{aligned}\n\\right.\n```\n\nThe output is `Vfield = Vfld`. Two non-windup limits freeze a state while it is out\nof its range and the input drives it further out: `Vap` outside\n`(Vap_min, Vap_max)`, and `Vfld` at or beyond `Vfld_max` or `Vfld_min` (a limit on\nthe field voltage). The logical parameter `Limiter` switches both limits: true (the\ndefault) applies them, false ignores them (the same as all four limits at +-Inf).",
      "SeeAlso": [
        "controller.avr.AVR_ST1",
        "controller.pss.PSS1",
        "controller.avr.abstract"
      ],
      "Examples": "Attach the AVR and a PSS to a generator and simulate a fault:\n\n```matlab\nnet = network.IEEE9bus(LocalController=false);\ngen = net.a_Bus{1}.a_Component{1};\ngen.add_local_controller(\"avr-DC1\", parameter=struct(kap=20));\ngen.add_local_controller(\"pss-PSS1\");\nnet.initialize;\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B007\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Sect. 5.3.2, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).\n- *IEEE Recommended Practice for Excitation System Models for Power System Stability\n  Studies*, IEEE Std 421.5-2016, 2016, doi:\n  [10.1109/IEEESTD.2016.7553421](https://doi.org/10.1109/IEEESTD.2016.7553421).\n- P. Kundur, *Power System Stability and Control*. New York, NY, USA: McGraw-Hill, 1994,\n  ISBN 0-07-035958-X.\n- P. M. Anderson and A. A. Fouad, *Power System Control and Stability*, 2nd ed.\n  Piscataway, NJ, USA: IEEE Press / Wiley-Interscience, 2003, doi:\n  [10.1109/9780470545577](https://doi.org/10.1109/9780470545577).\n- 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,\n  電気学会技術報告 第754号, 1999.\n- 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,\n  [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)\n  (accessed 2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 30
      },
      "MethodCount": {
        "Own": 7,
        "Total": 34
      },
      "path": "./database/GUILDAobject/controller.avr.AVR_DC1.js",
      "Image": ""
    },
    {
      "Name": "controller.avr.AVR_ST1",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+avr",
      "Category": "controller.avr",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "controller.avr.abstract",
      "Superclasses": [
        "controller.avr.abstract"
      ],
      "Ancestors": [
        "controller.avr.abstract",
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.avr",
      "File": "_GUILDAobject/+controller/+avr/@AVR_ST1/AVR_ST1.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Automatic voltage regulator with a static exciter (IEEE type ST1).",
      "Desc": "The AVR observes the terminal voltage $V$ [pu] of the generator it is attached to\nand drives the field voltage input of the generator.\n\n**Dynamic model**\nThe controller is a dynamical system with state $x$, input $u$ and output $y$.\n\n**State variables** $x$ (`sv_x`)\n- `Vtr` [pu]: Transducer output.\n- `Vap` [pu]: Amplifier output.\n- `Vst` [pu]: Stabilizing feedback.\n\n**Input signals** $u$ (`sv_u`)\n- `Vref` [pu]: Voltage reference.\n- `Vpss` [pu]: Output of the attached PSS (0 without a PSS).\n- `Ifield` [pu]: Field current of the generator (its output `Ifield`). A generator without\n  this output (`gen-classical`, `gen-droop`) leaves it at its equilibrium value `Vfield`.\n  On such a generator `Vfield` drives the internal voltage directly, so a finite\n  `gamma_max` that the output reaches during a fault can keep the consistent initial\n  condition at the fault clearing from converging.\n\n**Output signals** $y$ (`sv_y`)\n- `Vfield` [pu]: Field voltage, the `Vfield` input of the generator.\n\n**Equations** (transducer, amplifier, stabilizing feedback)\n```math\n\\left\\{\n\\begin{aligned}\nt_\\mathrm{tr}\\dot{V}_\\mathrm{tr} &= -V_\\mathrm{tr} + |V| \\\\\nt_\\mathrm{ap}\\dot{V}_\\mathrm{ap} &= -V_\\mathrm{ap} + k_\\mathrm{ap}\\,(V_\\mathrm{ref} + V_\\mathrm{pss} - V_\\mathrm{tr} - V_\\mathrm{st}) \\\\\nt_\\mathrm{st}\\dot{V}_\\mathrm{st} &= -V_\\mathrm{st} + k_\\mathrm{st}\\,\\dot{V}_\\mathrm{ap}\n\\end{aligned}\n\\right.\n```\n\nA non-windup limit holds `Vap` while it is at `Vap_max` or `Vap_min` and the input\ndrives it further out, so `Vap` stays within `[Vap_min, Vap_max]`; with `tap = 0` the\namplifier is static and `Vap` is `kap*Vcom` clipped to these limits. The output is the\namplifier output limited by the bus voltage and the field current (textbook (5.32)):\n```math\nV_\\mathrm{field} = \\max\\bigl(\\min(V_\\mathrm{ap},\\ \\gamma_\\mathrm{max}|V| - k_0 I_\\mathrm{field}),\\ \\gamma_\\mathrm{min}|V|\\bigr)\n```\nThe lower limit wins when the upper one falls below it. `gamma_max = Inf` and\n`gamma_min = -Inf` leave that side without a limit. The logical parameter `Limiter`\nswitches all the limits: true (the default) applies them, false ignores them. With the\ndefaults (`ttr = 0`, `tst = kst = 0`, no limits) the AVR is the first-order lag\n`kap/(1 + tap*s)`.",
      "SeeAlso": [
        "controller.avr.AVR_DC1",
        "controller.pss.PSS1",
        "controller.avr.abstract"
      ],
      "Examples": "Attach the AVR and a PSS to a generator and simulate a fault:\n\n```matlab\nnet = network.IEEE9bus(LocalController=false);\ngen = net.a_Bus{1}.a_Component{1};\ngen.add_local_controller(\"avr-ST1\", parameter=struct(kap=30));\ngen.add_local_controller(\"pss-PSS1\");\nnet.initialize;\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B007\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Sect. 5.3.2, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).\n- *IEEE Recommended Practice for Excitation System Models for Power System Stability\n  Studies*, IEEE Std 421.5-2016, 2016, doi:\n  [10.1109/IEEESTD.2016.7553421](https://doi.org/10.1109/IEEESTD.2016.7553421).\n- P. Kundur, *Power System Stability and Control*. New York, NY, USA: McGraw-Hill, 1994,\n  Sect. 8.6.3, ISBN 0-07-035958-X.\n- J. H. Chow, G. E. Boukarim, and A. Murdoch, \"Power system stabilizers as undergraduate\n  control design projects,\" *IEEE Trans. Power Syst.*, vol. 19, no. 1, pp. 144–151,\n  2004, doi: [10.1109/TPWRS.2003.821003](https://doi.org/10.1109/TPWRS.2003.821003).\n- T. Sadamoto, A. Chakrabortty, T. Ishizaki, and J. Imura, \"Dynamic modeling, stability,\n  and control of power systems with distributed energy resources: Handling faults using\n  two control methods in tandem,\" *IEEE Control Syst. Mag.*, vol. 39, no. 2, pp. 34–65,\n  2019, doi: [10.1109/MCS.2018.2888680](https://doi.org/10.1109/MCS.2018.2888680).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 30
      },
      "MethodCount": {
        "Own": 7,
        "Total": 34
      },
      "path": "./database/GUILDAobject/controller.avr.AVR_ST1.js",
      "Image": ""
    },
    {
      "Name": "controller.avr.Static",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+avr",
      "Category": "controller.avr",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "LocalController",
      "Superclasses": [
        "LocalController"
      ],
      "Ancestors": [
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.avr",
      "File": "_GUILDAobject/+controller/+avr/@Static/Static.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Static AVR: the default AVR of a synchronous generator, which keeps the field voltage at its reference.",
      "Desc": "Every synchronous generator (`component.generator.*`) gets one at creation, so that its\nAVR slot is always filled. It has no state and passes its inputs through:\n`Vfield = Vfd_ref + Vpss`. `Vfd_ref` matches no output of the generator, so it stays at its\nequilibrium, which `get_equilibrium` sets to the equilibrium `Vfield` of the generator.\n`Vpss` is the output of a PSS attached under it (0 at the equilibrium, and 0 without a PSS).\nWithout a PSS the generator therefore behaves as without an AVR, with its `Vfield` input\nat its equilibrium; with a PSS (e.g. `add_local_controller(\"pss-PSS1\")`) the PSS output\nadds to the field voltage directly.\n\nAttaching another AVR (e.g. `gen.set_avr(\"avr-ST1\")` or\n`add_local_controller(\"avr-ST1\")`) replaces it without a warning. Tripping it in a scenario makes\nthe `Vfield` input of the generator take its equilibrium value, which is the\nvalue that the controller gives, so the result is the same as not tripping it. An input event or\na global controller on `Vfield` adds to its output, as on a generator without an AVR.\nThe built-in networks keep it on every synchronous generator with `LocalController=false`\n(their default), which adds none of the controllers of `local_controller/`.\n\n**Dynamic model**\nNo state.\n\n**Input signals** $u$ (`sv_u`)\n- `Vfd_ref` [pu] Reference of the field voltage (kept at its equilibrium).\n- `Vpss` [pu] Output of the PSS under it (0 without a PSS).\n\n**Output signals** $y$ (`sv_y`)\n- `Vfield` [pu] Field voltage, the `Vfield` input of the generator.\n\n**Equations**\n```math\nV_\\mathrm{field} = V_\\mathrm{fd,ref} + V_\\mathrm{pss}\n```",
      "SeeAlso": [
        "controller.governor.Static",
        "controller.avr.AVR_ST1",
        "Component.add_local_controller"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\ngen = net.a_Bus{1}.a_Component{1};\ngen.avr    % the Static AVR (\"avr-static\")\ngen.add_local_controller(\"avr-ST1\");    % replaces it\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 6,
        "Total": 30
      },
      "MethodCount": {
        "Own": 8,
        "Total": 34
      },
      "path": "./database/GUILDAobject/controller.avr.Static.js",
      "Image": ""
    },
    {
      "Name": "controller.governor.abstract",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+governor",
      "Category": "controller.governor",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "LocalController",
      "Superclasses": [
        "LocalController"
      ],
      "Ancestors": [
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "controller.governor.IEEJ_LPT1",
        "controller.governor.IEEJ_LPT3",
        "controller.governor.IEEJ_LPT4"
      ],
      "Package": "controller.governor",
      "File": "_GUILDAobject/+controller/+governor/@abstract/abstract.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the governors (speed governor and turbine) attached to a generator.",
      "Desc": "A governor is attached to the generator beside its AVR (role \"governor\"). It\nobserves the speed deviation `omega` [pu] of the generator and takes the input\nsignals `u = [omega; Pref; Plimit]`: `Pref` is the load setting (65M) and `Plimit` the\nload limiter (77M), in pu of the rated MW of the machine. They match no output\nof the generator, so they stay at their equilibrium. Its output signal `Pmech` [pu on\nthe system base] is the mechanical power input of the generator.\n\n`Prate` [pu] is the rated MW of the machine divided by the system base, so that\n`Pmech = Prate*Pt` for the turbine output `Pt` [pu of the rated MW]. Its default NaN\nuses the operation `Pmax` of the generator, which stands in for the rated MW (1 when\n`Pmax` is not finite and positive); the parameter table keeps NaN. `PLM` [%]\nis the governor margin of the report (the Y-method data):\n\n- `PLM > 0` (governor-free operation): `Pref` = the initial output, and\n  `Plimit = Pref + PLM/100`\n- `PLM = 0`: `Plimit` is the upper limit of the servo position, so the\n  output can rise up to that limit\n- `PLM < 0` (load-limit operation): `Pref` = the initial output + `|PLM|/100`,\n  and `Plimit` = the initial output, so the output does not rise when the\n  frequency drops\n\nThe values are in units of the servo position, which equals the turbine output\nat a steady state when the gains of the turbine sum to 1 (as in the report).\nA governor that does not move (\"locked\", e.g. a pumping machine in the report) is\nsimply no governor: the generator then keeps `Pmech` at its equilibrium.",
      "SeeAlso": [
        "controller.governor.IEEJ_LPT1",
        "controller.governor.IEEJ_LPT3",
        "controller.governor.IEEJ_LPT4",
        "Component.add_local_controller"
      ],
      "Examples": "",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 30
      },
      "MethodCount": {
        "Own": 8,
        "Total": 39
      },
      "path": "./database/GUILDAobject/controller.governor.abstract.js",
      "Image": ""
    },
    {
      "Name": "controller.governor.IEEJ_LPT1",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+governor",
      "Category": "controller.governor",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "controller.governor.abstract",
      "Superclasses": [
        "controller.governor.abstract"
      ],
      "Ancestors": [
        "controller.governor.abstract",
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.governor",
      "File": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/IEEJ_LPT1.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Governor of thermal and nuclear units of the IEEJ standard models (LPT = 1).",
      "Desc": "The model of fig. A1.2 (a) of the IEEJ technical report on the standard power\nsystem models (appendix 1, section 3). It observes the speed deviation of the\ngenerator and drives its mechanical power input.\n\n**Dynamic model**\nThe controller is a dynamical system with state $x$, input $u$ and output $y$.\n\n**State variables** $x$ (`sv_x`, in pu of the rated MW)\n- `Pgov`: Speed governor output.\n- `Psv`: Servo position.\n- `Pch`: Steam chest output.\n- `Prh`: Reheater output.\n\n**Input signals** $u$ (`sv_u`)\n- `omega` [pu]: Speed deviation of the generator.\n- `Pref` [pu of the rated MW]: Load setting (65M), kept at its equilibrium.\n- `Plimit` [pu of the rated MW]: Load limiter (77M), kept at its equilibrium.\n\n**Output signals** $y$ (`sv_y`)\n- `Pmech` [pu on the system base]: Mechanical power, the `Pmech` input of the generator.\n\n**Equations**\n```math\n\\left\\{\n\\begin{aligned}\nT_g\\,\\dot{P}_\\mathrm{gov} &= -P_\\mathrm{gov} + \\frac{100}{\\mathrm{droop}}\\,\\omega \\\\\n\\dot{P}_\\mathrm{sv} &= K_s\\,(g - P_\\mathrm{sv}) \\\\\nT_\\mathrm{ch}\\dot{P}_\\mathrm{ch} &= -P_\\mathrm{ch} + P_\\mathrm{sv} \\\\\nT_\\mathrm{rh}\\dot{P}_\\mathrm{rh} &= -P_\\mathrm{rh} + P_\\mathrm{ch}\n\\end{aligned}\n\\right.\n```\nwith the low value gate and the output\n```math\ng = \\min(P_\\mathrm{ref} - P_\\mathrm{gov},\\ P_\\mathrm{limit}), \\qquad P_\\mathrm{mech} = P_\\mathrm{rate}\\,(F_\\mathrm{hp}P_\\mathrm{ch} + F_\\mathrm{rh}P_\\mathrm{rh})\n```\n\nThe servo rate $\\dot{P}_\\mathrm{sv}$ is limited to `[rate_min, rate_max]`, and `Psv` is\nfrozen while it is at `pos_max` or `pos_min` and pushed further out (non-windup).\n\n`Prate` is the rated MW of the machine divided by the system base (default NaN: the\noperation `Pmax` of the generator, which stands in for the rated MW; 1 if not finite) and `PLM` [%]\nthe governor margin, which sets `Pref` and `Plimit` at the equilibrium (see\ncontroller.governor.abstract). The other defaults are the values of the figure.",
      "SeeAlso": [
        "controller.governor.IEEJ_LPT3",
        "controller.governor.IEEJ_LPT4",
        "controller.governor.abstract",
        "controller.avr.AVR_DC1"
      ],
      "Examples": "Attach a governor beside the AVR of a generator and trip a load:\n\n```matlab\nnet = network.IEEE9bus();\ngen = net.a_Bus{1}.a_Component{1};\ngen.add_local_controller(\"gov-LPT1\", parameter=struct(Prate=2.5, PLM=5));\nnet.initialize;\nsc  = net.add_scenario(\"trip\");\nsc.add_trip(net.a_Bus{5}.a_Component{1}.s_tag, 1);\nsol = net.simulate(\"trip\", Time=[0,30]);\n```",
      "Citations": "- 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,\n  電気学会技術報告 第754号, 1999.\n- 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,\n  [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)\n  (accessed 2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 30
      },
      "MethodCount": {
        "Own": 9,
        "Total": 40
      },
      "path": "./database/GUILDAobject/controller.governor.IEEJ_LPT1.js",
      "Image": ""
    },
    {
      "Name": "controller.governor.IEEJ_LPT3",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+governor",
      "Category": "controller.governor",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "controller.governor.abstract",
      "Superclasses": [
        "controller.governor.abstract"
      ],
      "Ancestors": [
        "controller.governor.abstract",
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.governor",
      "File": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/IEEJ_LPT3.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Governor of hydro units of the IEEJ standard models, model 1 (LPT = 3).",
      "Desc": "The model of fig. A1.2 (b) of the IEEJ technical report on the standard power\nsystem models (appendix 1, section 3). It observes the speed deviation of the\ngenerator and drives its mechanical power input.\n\n**Dynamic model**\nThe controller is a dynamical system with state $x$, input $u$ and output $y$.\n\n**State variables** $x$ (`sv_x`, in pu of the rated MW)\n- `Pgov`: Speed governor output.\n- `Psv`: Servo position.\n\n**Input signals** $u$ (`sv_u`)\n- `omega` [pu]: Speed deviation of the generator.\n- `Pref` [pu of the rated MW]: Load setting (65M), kept at its equilibrium.\n- `Plimit` [pu of the rated MW]: Load limiter (77M), kept at its equilibrium.\n\n**Output signals** $y$ (`sv_y`)\n- `Pmech` [pu on the system base]: Mechanical power, the `Pmech` input of the generator.\n\n**Equations**\n```math\n\\left\\{\n\\begin{aligned}\nT_g\\,\\dot{P}_\\mathrm{gov} &= -P_\\mathrm{gov} + \\frac{100}{\\mathrm{droop}}\\,\\omega \\\\\nT_s\\,\\dot{P}_\\mathrm{sv} &= g - P_\\mathrm{sv}\n\\end{aligned}\n\\right.\n```\nwith the low value gate and the output\n```math\ng = \\min(P_\\mathrm{ref} - P_\\mathrm{gov},\\ P_\\mathrm{limit}), \\qquad P_\\mathrm{mech} = P_\\mathrm{rate}\\,P_\\mathrm{sv}\n```\n\nThe servo rate $\\dot{P}_\\mathrm{sv}$ is limited to `[rate_min, rate_max]`, and `Psv` is\nfrozen while it is at `pos_max` or `pos_min` and pushed further out (non-windup).\n\nThe turbine output is the servo position.\n\n`Prate` is the rated MW of the machine divided by the system base (default NaN: the\noperation `Pmax` of the generator, which stands in for the rated MW; 1 if not finite) and `PLM` [%]\nthe governor margin, which sets `Pref` and `Plimit` at the equilibrium (see\ncontroller.governor.abstract). The other defaults are the values of the figure.",
      "SeeAlso": [
        "controller.governor.IEEJ_LPT1",
        "controller.governor.IEEJ_LPT4",
        "controller.governor.abstract"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\ngen = net.a_Bus{2}.a_Component{1};\ngen.add_local_controller(\"gov-LPT3\", parameter=struct(Prate=2, PLM=10));\nnet.initialize;\n```",
      "Citations": "- 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,\n  電気学会技術報告 第754号, 1999.\n- 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,\n  [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)\n  (accessed 2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 30
      },
      "MethodCount": {
        "Own": 9,
        "Total": 40
      },
      "path": "./database/GUILDAobject/controller.governor.IEEJ_LPT3.js",
      "Image": ""
    },
    {
      "Name": "controller.governor.IEEJ_LPT4",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+governor",
      "Category": "controller.governor",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "controller.governor.abstract",
      "Superclasses": [
        "controller.governor.abstract"
      ],
      "Ancestors": [
        "controller.governor.abstract",
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.governor",
      "File": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/IEEJ_LPT4.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Governor of hydro units of the IEEJ standard models, model 2 (LPT = 4).",
      "Desc": "The model of fig. A1.2 (c) of the IEEJ technical report on the standard power\nsystem models (appendix 1, section 3). It observes the speed deviation of the\ngenerator and drives its mechanical power input.\n\n**Dynamic model**\nThe controller is a dynamical system with state $x$, input $u$ and output $y$.\n\n**State variables** $x$ (`sv_x`, in pu of the rated MW)\n- `Pgov`: Speed governor output.\n- `Pdr`: Temporary droop state.\n- `Psv`: Servo position.\n- `Pw`: Water column output.\n\n**Input signals** $u$ (`sv_u`)\n- `omega` [pu]: Speed deviation of the generator.\n- `Pref` [pu of the rated MW]: Load setting (65M), kept at its equilibrium.\n- `Plimit` [pu of the rated MW]: Load limiter (77M), kept at its equilibrium.\n\n**Output signals** $y$ (`sv_y`)\n- `Pmech` [pu on the system base]: Mechanical power, the `Pmech` input of the generator.\n\n**Equations**\n```math\n\\left\\{\n\\begin{aligned}\nT_g\\,\\dot{P}_\\mathrm{gov} &= -\\omega - \\frac{\\mathrm{droop}}{100}\\,P_\\mathrm{gov} - \\frac{K_t}{T_t}\\,(P_\\mathrm{gov} - P_\\mathrm{dr}) \\\\\nT_t\\,\\dot{P}_\\mathrm{dr} &= -P_\\mathrm{dr} + P_\\mathrm{gov} \\\\\nT_s\\,\\dot{P}_\\mathrm{sv} &= g - P_\\mathrm{sv} \\\\\nT_w\\,\\dot{P}_\\mathrm{w} &= -P_\\mathrm{w} + P_\\mathrm{sv}\n\\end{aligned}\n\\right.\n```\nwith the low value gate and the output\n```math\ng = \\min(P_\\mathrm{ref} + P_\\mathrm{gov},\\ P_\\mathrm{limit}), \\qquad P_\\mathrm{mech} = P_\\mathrm{rate}\\,(K_wP_\\mathrm{w} + K_vP_\\mathrm{sv})\n```\n\nThe servo rate $\\dot{P}_\\mathrm{sv}$ is limited to `[rate_min, rate_max]`, and `Psv` is\nfrozen while it is at `pos_max` or `pos_min` and pushed further out (non-windup).\n\nThe speed governor is an integrator with the permanent droop `droop/100` and the\ntemporary droop $K_t s/(1 + T_t s)$ in its feedback. With the defaults the turbine is\n`(1 - 3s)/(1 + 1.5s)`.\n\n`Prate` is the rated MW of the machine divided by the system base (default NaN: the\noperation `Pmax` of the generator, which stands in for the rated MW; 1 if not finite) and `PLM` [%]\nthe governor margin, which sets `Pref` and `Plimit` at the equilibrium (see\ncontroller.governor.abstract). The other defaults are the values of the figure.",
      "SeeAlso": [
        "controller.governor.IEEJ_LPT1",
        "controller.governor.IEEJ_LPT3",
        "controller.governor.abstract"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\ngen = net.a_Bus{3}.a_Component{1};\ngen.add_local_controller(\"gov-LPT4\", parameter=struct(Prate=1.5, PLM=10));\nnet.initialize;\n```",
      "Citations": "- 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,\n  電気学会技術報告 第754号, 1999.\n- 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,\n  [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)\n  (accessed 2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 30
      },
      "MethodCount": {
        "Own": 9,
        "Total": 40
      },
      "path": "./database/GUILDAobject/controller.governor.IEEJ_LPT4.js",
      "Image": ""
    },
    {
      "Name": "controller.governor.Static",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+governor",
      "Category": "controller.governor",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "LocalController",
      "Superclasses": [
        "LocalController"
      ],
      "Ancestors": [
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.governor",
      "File": "_GUILDAobject/+controller/+governor/@Static/Static.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Static governor: the default governor of a synchronous generator, which keeps the mechanical power at its reference.",
      "Desc": "Every synchronous generator (`component.generator.*`) gets one at creation, so that its\ngovernor slot is always filled. It has no state and passes its input through:\n`Pmech = Pmech_ref`. `Pmech_ref` matches no output of the generator, so it stays at its\nequilibrium, which `get_equilibrium` sets to the equilibrium `Pmech` of the generator.\nThe generator therefore behaves as without a governor, with its `Pmech` input at its equilibrium.\n\nAttaching another governor (e.g. `gen.set_governor(\"gov-LPT1\")` or\n`add_local_controller(\"gov-LPT1\")`) replaces it without a warning. Tripping it in a scenario makes\nthe `Pmech` input of the generator take its equilibrium value, which is the\nvalue that the controller gives, so the result is the same as not tripping it. An input event or\na global controller on `Pmech` adds to its output, as on a generator without a governor.\nThe built-in networks keep it on every synchronous generator with `LocalController=false`\n(their default), which adds none of the controllers of `local_controller/`.\n\n**Dynamic model**\nNo state.\n\n**Input signals** $u$ (`sv_u`)\n- `Pmech_ref` [pu] Reference of the mechanical power (kept at its equilibrium).\n\n**Output signals** $y$ (`sv_y`)\n- `Pmech` [pu] Mechanical power, the `Pmech` input of the generator.\n\n**Equations**\n```math\nPmech = Pmech\\_ref\n```",
      "SeeAlso": [
        "controller.avr.Static",
        "controller.governor.IEEJ_LPT1",
        "Component.add_local_controller"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\ngen = net.a_Bus{1}.a_Component{1};\ngen.governor    % the Static governor (\"gov-static\")\ngen.add_local_controller(\"gov-LPT1\");    % replaces it\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 6,
        "Total": 30
      },
      "MethodCount": {
        "Own": 8,
        "Total": 34
      },
      "path": "./database/GUILDAobject/controller.governor.Static.js",
      "Image": ""
    },
    {
      "Name": "controller.local_LQR",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller",
      "Category": "controller",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "LocalController",
      "Superclasses": [
        "LocalController"
      ],
      "Ancestors": [
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller",
      "File": "_GUILDAobject/+controller/@local_LQR/local_LQR.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "State-feedback LQR controller of one component.",
      "Desc": "The controller observes all the state variables `x` of the component it is attached to\n(the reserved input signal name \"Xall\") and drives the inputs `Input` of the component\n(by name, e.g. \"Vfield\" [pu] or \"Pmech\" [pu]; all its inputs by default):\n\n```\nu = u* - K*(x - x*)\n```\n\nwhere `x*` and `u*` are the equilibrium of the component. It has no state of\nits own. `net.initialize` computes the gain `K = lqr(A, B, Q, R)` from the\nlinear model of the component alone (`comp.get_linear_matrix`)\nconnected to an infinite bus of voltage `V0` [pu] through the admittance that\ngives the equilibrium current (as in GUILDA v2). A network Hz edit keeps the\nequilibrium, so `net.initialize` only redesigns `K` at that equilibrium.\n\nAttach it with `comp.add_local_controller(\"local-LQR\")`; it takes the place of an AVR\n(and of the PSS attached to that AVR). It needs the Control System Toolbox (`lqr`);\nwithout it, the constructor stops with GUILDA:require_toolbox:Unavailable. The output of a global controller (e.g. an\nAGC) on a driven input adds to its output, and the design of `K` does not take it\ninto account (use `Input=\"Vfield\"` with an AGC on Pmech to keep them apart).\n\n- Editing `Q`, `R` or `V0` makes the equilibrium and the handles of the controller\n  stale; `net.initialize` recomputes `K`. After a network Hz edit, `net.initialize`\n  rebuilds the handles and redesigns `K` when the equilibrium is up to date.\n- `sys_design` is the component connected to the infinite bus; its inputs are the\n  driven inputs and its outputs the states.\n- At another operating point (a step of `net.calculate_continuation_powerflow`, a point\n  of the stability-constrained OPF) the observed signals are the state `x` of the\n  component there, while `K`, `x*` and `u*` stay as designed by `net.initialize`. The\n  point is then not exactly an equilibrium with the controller: its output\n  `u* - K*(x - x*)` differs from the input of the component at the point.",
      "SeeAlso": [
        "Component.add_local_controller",
        "controller.avr.abstract",
        "controller.pss.Retrofit"
      ],
      "Examples": "Attach LQR controllers to two generators and simulate a fault:\n\n```matlab\nnet = network.IEEE9bus(LocalController=false);\nnet.a_Bus{1}.a_Component{1}.add_local_controller(\"local-LQR\");\nnet.a_Bus{2}.a_Component{1}.add_local_controller(\"local-LQR\", parameter=struct(Input=\"Vfield\", R=2));\nnet.initialize;\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B007\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 14,
        "Total": 38
      },
      "MethodCount": {
        "Own": 16,
        "Total": 37
      },
      "path": "./database/GUILDAobject/controller.local_LQR.js",
      "Image": ""
    },
    {
      "Name": "controller.pss.abstract",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+pss",
      "Category": "controller.pss",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "LocalController",
      "Superclasses": [
        "LocalController"
      ],
      "Ancestors": [
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "controller.pss.PSS1"
      ],
      "Package": "controller.pss",
      "File": "_GUILDAobject/+controller/+pss/@abstract/abstract.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the power system stabilizers (PSS) attached to an AVR.",
      "Desc": "A PSS observes the frequency deviation `omega` [pu] of the generator and has the\noutput signal `Vpss` [pu], which is the `Vpss` input of the AVR it is\nattached to. The base class has no state and outputs 0.",
      "SeeAlso": [
        "controller.pss.PSS1",
        "controller.avr.abstract"
      ],
      "Examples": "",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 30
      },
      "MethodCount": {
        "Own": 5,
        "Total": 34
      },
      "path": "./database/GUILDAobject/controller.pss.abstract.js",
      "Image": ""
    },
    {
      "Name": "controller.pss.PSS1",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+pss",
      "Category": "controller.pss",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "controller.pss.abstract",
      "Superclasses": [
        "controller.pss.abstract"
      ],
      "Ancestors": [
        "controller.pss.abstract",
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.pss",
      "File": "_GUILDAobject/+controller/+pss/@PSS1/PSS1.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Power system stabilizer with a washout filter and two lead-lag blocks.",
      "Desc": "The PSS observes the frequency deviation of the generator and drives the `Vpss`\ninput of the AVR it is attached to.\n\n**Dynamic model**\nThe controller is a dynamical system with state $x$, input $u$ and output $y$.\n\n**State variables** $x$ (`sv_x`)\n- `xiWS` [pu]: State of the washout filter.\n- `xi1` [pu]: State of the first lead-lag block.\n- `xi2` [pu]: State of the second lead-lag block.\n\n**Input signals** $u$ (`sv_u`)\n- `omega` [pu]: Frequency deviation of the generator.\n\n**Output signals** $y$ (`sv_y`)\n- `Vpss` [pu]: Stabilizing signal, the `Vpss` input of the AVR.\n\n**Equations** (transfer function from $\\omega$ to $V_\\mathrm{pss}$)\n```math\nk_\\mathrm{pss}\\,\\frac{t_\\mathrm{WS}s}{1 + t_\\mathrm{WS}s}\\,\\frac{1 + t_\\mathrm{n1}s}{1 + t_\\mathrm{d1}s}\\,\\frac{1 + t_\\mathrm{n2}s}{1 + t_\\mathrm{d2}s}\n```\n\nThe output is limited to `[Vpss_min, Vpss_max]`.\n\nA lead-lag block with `tn = td = 0` is the identity (its state stays 0), so one block can\nbe left out. A block with `tn = 0` and `td > 0` is the first-order lag `1/(1 + td*s)`; its\nstate is then the block output. A block with `td = 0` and `tn ~= 0` is improper and raises\nan error at `initialize`.",
      "SeeAlso": [
        "controller.avr.AVR_ST1",
        "controller.pss.abstract"
      ],
      "Examples": "Attach an AVR with this PSS to a generator and simulate a fault:\n\n```matlab\nnet = network.IEEE9bus(LocalController=false);\ngen = net.a_Bus{1}.a_Component{1};\ngen.add_local_controller(\"avr-ST1\");\ngen.add_local_controller(\"pss-PSS1\", parameter=struct(kpss=5));\nnet.initialize;\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B007\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Sect. 5.3.4, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).\n- *IEEE Recommended Practice for Excitation System Models for Power System Stability\n  Studies*, IEEE Std 421.5-2016, 2016, doi:\n  [10.1109/IEEESTD.2016.7553421](https://doi.org/10.1109/IEEESTD.2016.7553421).\n- P. Kundur, *Power System Stability and Control*. New York, NY, USA: McGraw-Hill, 1994,\n  ISBN 0-07-035958-X.\n- J. H. Chow, G. E. Boukarim, and A. Murdoch, \"Power system stabilizers as undergraduate\n  control design projects,\" *IEEE Trans. Power Syst.*, vol. 19, no. 1, pp. 144–151,\n  2004, doi: [10.1109/TPWRS.2003.821003](https://doi.org/10.1109/TPWRS.2003.821003).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 30
      },
      "MethodCount": {
        "Own": 7,
        "Total": 34
      },
      "path": "./database/GUILDAobject/controller.pss.PSS1.js",
      "Image": ""
    },
    {
      "Name": "controller.pss.Retrofit",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+controller/+pss",
      "Category": "controller.pss",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "LocalController",
      "Superclasses": [
        "LocalController"
      ],
      "Ancestors": [
        "LocalController",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "controller.pss",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Retrofit power system stabilizer: an LQR on the generator alone with an exact compensator.",
      "Desc": "Based on retrofit control (textbook section 5.4, Eqs. (5.36)-(5.42)). The controller\ngoes under the Static AVR of a generator (role \"pss\", like a PSS) and drives its\n`Vpss` input, so that `Vfield = Vfd_ref + Vpss`. It observes all the states `x` of the\ngenerator (\"Xall\") and holds a copy `hat_x` of them, driven by the generator model\nwith its inputs at the equilibrium:\n\n```math\nE\\,\\dot{\\hat{x}} = f(x, V, u^*) - A_d\\,(x - \\hat{x}), \\qquad\nV_\\mathrm{pss} = -K\\,(x - \\hat{x})\n```\n\nwhere `E dx/dt = f(x, V, u)` is the generator, `u* = [Pmech*; Vfield*]` its\nequilibrium input, `A_d = df/dx` and `B = df/dVfield` at the equilibrium (`V` and\n`u` fixed there), and `K = lqr(E\\A_d, E\\B, Q, R)`.\n\nProperties:\n\n- The error `e = x - hat_x` follows `E de/dt = (A_d - B K) e` exactly, because `f`\n  is linear in `Vfield`. The controller only acts on what starts in the generator\n  itself (an initial-value disturbance of its states).\n- At the equilibrium `hat_x = x` and `Vpss = 0`, so attaching it does not move the\n  equilibrium.\n- A disturbance that enters through the voltage `V` (e.g. a fault on a distant bus)\n  drives `x` and `hat_x` in the same way: `e` stays 0 and so does `Vpss`.\n- The eigenvalues of the linearized network are those without the controller plus\n  `eig(E\\(A_d - B K))`.\n\n`Pmech` is not observed, so the compensator uses its equilibrium value. This is exact\nwith the default Static governor (\"gov-static\"); with a governor that moves `Pmech`\n(e.g. \"gov-LPT1\") or an AGC on `Pmech` it is an approximation, and `e` is no longer\nindependent of the rest of the network.\n\nDesign weights and what is guaranteed:\n\n- With the default weights (`Q = I`, `R = 1`, as in local-LQR) the effect can be very\n  small. Give a smaller `R` (e.g. `R = 0.01`) to make it act.\n- Only the decay of the error `e` is guaranteed. The swing of the generator as a whole\n  does not always get smaller: `x = hat_x + e`, and `hat_x` is driven by the rest of the\n  network through `V` (e.g. with an initial-value disturbance of the rotor angle, the\n  integral of `|omega|` can grow).\n\nIt goes only under the Static AVR (\"avr-static\"): attaching it under another AVR, or\nreplacing the Static AVR above it, stops with an error and leaves the generator as it\nwas; remove the controller first. The generator must have an invertible mass matrix\n`E` (no algebraic state). It needs the Control System Toolbox (`lqr`); without it, the\nconstructor stops with GUILDA:require_toolbox:Unavailable.\n\n- `net.initialize` designs `K` at the equilibrium of the generator; editing `Q` or `R`\n  makes the equilibrium and the handles stale. After a network Hz edit,\n  `net.initialize` rebuilds the handles and redesigns `K`.\n- `sys_design` is `ss(E\\A_d, E\\B, I, 0)`: the generator alone with its voltage and\n  `Pmech` at the equilibrium, from `Vfield` to the states.\n- At another operating point (a step of `net.calculate_continuation_powerflow`, a point\n  of the stability-constrained OPF) `hat_x` is the state `x` of the generator there,\n  so `Vpss = 0`, while `K`, `A_d` and `u*` stay as designed by `net.initialize`. The\n  point is then not exactly an equilibrium of the controller: `E dhat_x/dt = f(x, V, u*)`\n  is not 0 when the input of the generator there differs from `u*`.\n\n**State variables** $x$ (`sv_x`)\n- `hat_<name>` for each state `<name>` of the generator: the compensator copy of it.\n\n**Input signals** $u$ (`sv_u`)\n- All the states of the generator (\"Xall\").\n\n**Output signals** $y$ (`sv_y`)\n- `Vpss` [pu]: the `Vpss` input of the Static AVR.",
      "SeeAlso": [
        "controller.local_LQR",
        "controller.avr.Static",
        "Component.add_local_controller"
      ],
      "Examples": "Put a generator back on its Static AVR, attach the controller and simulate an\ninitial-value disturbance:\n\n```matlab\nnet = network.IEEE9bus(LocalController=true);\ngen = net.a_Bus{2}.a_Component{1};\ngen.remove_local_controller(gen.avr.s_tag, RemoveNested=true);   % AVR_ST1 and PSS1\ngen.add_local_controller(\"avr-static\");\ngen.add_local_controller(\"pss-retrofit\", parameter=struct(R=0.01));\nnet.initialize;\nsc = net.add_scenario(\"kick\", Time=[0 10]);\nsc.add_offset(gen.s_tag, \"Eq\", 0.1, 0);    % initial-value disturbance at t = 0\nsol = net.simulate(\"kick\");\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Sect. 5.4, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).\n- T. Ishizaki, T. Sadamoto, J. Imura, H. Sandberg, and K. H. Johansson, \"Retrofit\n  control: Localization of controller design and implementation,\" *Automatica*, vol. 95,\n  pp. 336–346, 2018, doi:\n  [10.1016/j.automatica.2018.05.033](https://doi.org/10.1016/j.automatica.2018.05.033).\n- T. Sadamoto, A. Chakrabortty, T. Ishizaki, and J. Imura, \"Retrofit control of\n  wind-integrated power systems,\" *IEEE Trans. Power Syst.*, vol. 33, no. 3, pp.\n  2804–2815, 2018, doi:\n  [10.1109/TPWRS.2017.2750411](https://doi.org/10.1109/TPWRS.2017.2750411).\n- H. Sasahara, T. Ishizaki, T. Sadamoto, T. Masuta, Y. Ueda, H. Sugihara, N. Yamaguchi,\n  and J. Imura, \"Damping performance improvement for PV-integrated power grids via\n  retrofit control,\" *Control Eng. Pract.*, vol. 84, pp. 92–101, 2019, doi:\n  [10.1016/j.conengprac.2018.11.004](https://doi.org/10.1016/j.conengprac.2018.11.004).\n- T. Ishizaki, T. Kawaguchi, H. Sasahara, and J. Imura, \"Retrofit control with\n  approximate environment modeling,\" *Automatica*, vol. 107, pp. 442–453, 2019, doi:\n  [10.1016/j.automatica.2019.06.010](https://doi.org/10.1016/j.automatica.2019.06.010).\n- T. Ishizaki, H. Sasahara, M. Inoue, T. Kawaguchi, and J. Imura, \"Modularity-in-design\n  of dynamical network systems: Retrofit control approach,\" *IEEE Trans. Autom.\n  Control*, vol. 66, no. 11, pp. 5205–5220, 2021, doi:\n  [10.1109/TAC.2020.3035631](https://doi.org/10.1109/TAC.2020.3035631).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 10,
        "Total": 34
      },
      "MethodCount": {
        "Own": 14,
        "Total": 35
      },
      "path": "./database/GUILDAobject/controller.pss.Retrofit.js",
      "Image": ""
    },
    {
      "Name": "CsvNetHandler",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_VersionSupport",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_VersionSupport/@CsvNetHandler/CsvNetHandler.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "v3 CSV import and export of networks (static methods only).",
      "Desc": "The methods are wrappers of the v4 API and warn GUILDA:Deprecated:CsvNetHandlerImport\nor GUILDA:Deprecated:CsvNetHandlerExport:\n\n- `CsvNetHandler.import(path, net, Initialize=tf)` calls\n  `PowerNetwork.import(path, Network=net, Initialize=tf)`\n- `CsvNetHandler.export(net, ModelName, savepath=d)` calls\n  `net.export(fullfile(d, \"@\"+ModelName))`",
      "SeeAlso": [
        "PowerNetwork.import",
        "PowerNetwork.export"
      ],
      "Examples": "```matlab\nnet = CsvNetHandler.import(path);\n```",
      "Citations": "",
      "Deprecated": "Use PowerNetwork.import and net.export instead.",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 0
      },
      "MethodCount": {
        "Own": 3,
        "Total": 4
      },
      "path": "./database/GUILDAsystem/CsvNetHandler.js",
      "Image": ""
    },
    {
      "Name": "DrawerGUILDA",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "The GUILDA app: tabs for the usual work, the network diagram, the run log and the script.",
      "Desc": "GUILDA.launch_gui creates one in a new uifigure, with one HistoryGUILDA for the whole app:\nevery action is a line of MATLAB code run by that history, so the log shows the code and\n\"Export script\" writes a script that repeats the session (HistoryGUILDA.export_script).\nEvery model GUI and result GUI opened from the app uses the same history. All the text of\nthe app is in English.\n\n- Start screen (without a network): Empty network (`net = PowerNetwork();`), Sample network\n  (a list of the classes of `_GUILDAobject/+network`, `net = network.IEEE14bus();`), Model\n  folder (`net = PowerNetwork.import(\"<path>\");`) and MATPOWER case\n  (`net = PowerNetwork.import_matpower(\"<case>\");`). The choice runs through the history,\n  so it is the first line of the script. With a network (GUILDA.launch_gui(net)) the\n  history holds it as `net` and the script header says so.\n- Top: a tab bar across the whole width (toggle buttons): Model, Power flow, OPF, CPF,\n  Time simulation, Linearization.\n- Left half: a two-line info strip (counts of buses, branches and components, the stale\n  state and the last run; then what the colors of the diagram mean) with the toggle\n  \"Display options\", the network diagram G, and under it the run log\n  (HistoryGUILDA.attach_view, 130 px high; \"Hide log\" collapses it) with \"Export script\".\n  \"Display options\" shows the control panel of the diagram (G.show_controls) to the right\n  of the diagram; its changes only set properties of G and are not logged.\n- Right half: the panel of the active tab.\n\nEach tab has a diagram of its own, in a panel of its own in the left half; only the panel\nof the active tab is shown, and only its diagram runs the flow animation. A run of the\nhistory that ended (Changed) marks every tab out of date: the active tab gets its hook\nf_changed and its diagram is drawn again; a hidden tab gets both on its next show, and a\ntab switch without a run in between draws nothing. These drawings are not logged. What a diagram shows depends on\nits tab (the hook f_diagram of the tab), and the hook f_legend of the tab writes what its\ncolors mean in the info strip; a click on an element is passed to the hook f_click of the\ntab. In the model tab a click shows the element in the model GUI (DrawerModelGUI) and the\nelement shown is selected in the diagram, also after a navigation in the model GUI\n(TargetChanged). The diagram fits itself to its panel (plot_diagram).\n\nThe window is built hidden and shown once its first tab is drawn. In a visible window the\ndrawing after a run follows by a short timer, so the GUI that ran the code responds first.\n\nEach tab is a set of private files registered in private/tab_list.m. Its build function\nfills the panel of the tab on its first show and returns its hooks; it gets the tab API, a\nstruct with the helpers of the frame (run code with a progress dialog, a stale banner with\na button that runs `net.initialize();`). The frame never changes to fill a tab. The\ncontract is documented in notes/launch-gui.md and in private/tab_list.m.\n\nThe colors are the fixed light palette of the GUILDA GUIs (tools.gui_palette).",
      "SeeAlso": [
        "GUILDA.launch_gui",
        "HistoryGUILDA",
        "DrawerModelGUI",
        "DrawerResultGUI",
        "GraphNetDiagram"
      ],
      "Examples": "```matlab\nh = GUILDA.launch_gui();                     % start screen\nh = GUILDA.launch_gui(network.IEEE9bus());   % with a network\ndisp(h.history.get_script())                 % the code of the session\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_listener",
          "Type": ""
        }
      ],
      "PropertyCount": {
        "Own": 13,
        "Total": 13
      },
      "MethodCount": {
        "Own": 33,
        "Total": 34
      },
      "path": "./database/GUILDAsystem/DrawerGUILDA.js",
      "Image": ""
    },
    {
      "Name": "DrawerModelGUI",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "GUI of one model: breadcrumb, class, tag, Docs link, stale state, child tables, parameters and pages.",
      "Desc": "LayerPackage.launch_gui creates one, in a new uifigure or in a given container (uifigure,\nuipanel, uitab or uigridlayout), so that it can be embedded in another app. The layout\nfollows the size of the container:\n\n- Header (logo blue band over a lime line): the breadcrumb from the root to the model,\n  whose links show those models in the same container (render); then the tag, the class,\n  a Docs button that opens the class reference (GUILDA.doc(\"class\", ...)) and the stale\n  state (`sct_stale`: each stale tag with its first message).\n- Add buttons (Tag \"add\", in the color of the kind) above the child tables: + Bus,\n  + Branch, + Controller (add_global_controller) and + Scenario for a PowerNetwork,\n  + Component for a Bus, + Controller (add_local_controller) for a Component and a\n  LocalController (added to its component), and each event (+ Fault, + Trip,\n  + Open branch, + Offset, + Input) for a Scenario. The tooltip names the method. A\n  button opens the option form of the method (DrawerOptionDialog.ask) and runs the code\n  it returns.\n- Child tables (left column, 300 px): the children of one kind at a time (a drop-down\n  \"Bus (14)\", \"Branch (20)\", ...) in a compact table with the columns of\n  DrawerTagPicker.element_table and a search field. A click on a row shows that model in\n  the same container; the context menu \"Open in new window\" opens it in a new uifigure\n  (with the same history) and \"Remove\" removes it after a confirmation. Each set of\n  columns has a table of its own (Tag \"children\" on the one shown). The element tables\n  are kept until the history has a new entry; the kind and the search of a model are\n  kept for its next render. A model with add buttons and no children gets a column as\n  wide as the buttons; a model with neither leaves it to the body.\n- Body (one uihtml, Tag \"body\", drawn by private/model_body.html from its Data): the tabs\n  Parameter (one editable table per container of a_Parameter, titled by its s_tag; only\n  for a model with a_Parameter, not for a Scenario), then the tables of gui_content. A\n  container of one row whose parameters are all scalars is a vertical Name/Value table\n  (full names), two such tables side by side; any other container is a table with one\n  column per parameter. Every table fits its columns to the header and the contents and\n  scrolls sideways. An edited cell is written as code, e.g.\n  `net.a_Bus{1}.tab_parameter.powerflow.V = 1.02;`; on an error the table goes back to\n  the stored values and an alert shows the message. The rows of the event tables of\n  a Scenario have the context menu \"Remove event\" (Scenario.remove_event). The tab of\n  the same title stays selected from one model to the next.\n\nA render writes the new model into the components kept from the first render (the body\ngets one Data), so that moving between models stays fast.\n\nEvery action is a line of MATLAB code run by the history (HistoryGUILDA.run), so it is\nlogged and get_script reproduces it. The code reaches each model from the root variable of\nthe history: `net` for a network (e.g. `net.a_Bus{3}.a_Component{1}`), otherwise a name\nof the class of the root (`bus`, `branch`, `comp`, `con`, `gcon`). After an action the GUI\nis drawn again (also after a failed one, which may have changed part of the model), and\nafter a successful one the event ModelChanged is notified. Each render that shows another\nmodel than before (the breadcrumb, a child table, or render called by an app) notifies\nTargetChanged, so that an app can follow the model shown (GUILDA.launch_gui selects it in\nits network diagram). A failed action shows its error\nin an alert (a warning on a hidden figure). Its colors are set on every component, so the\nMATLAB theme does not change them; a new uifigure gets the light theme where uifigure has\na Theme property (R2025a and later).\n\nThe parent, children and pages are protected members of the model, which a class outside\nthe model hierarchy cannot read; launch_gui passes `f_model`, made inside LayerPackage, to read them.",
      "SeeAlso": [
        "LayerPackage.launch_gui",
        "LayerPackage.gui_content"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nh = net.a_Bus{1}.launch_gui();   % new window\nh.render(net.a_Branch{1});       % show another model in the same window\ndisp(h.history.get_script())     % the code of the actions done in the GUI\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_target",
          "Type": "LayerPackage"
        }
      ],
      "PropertyCount": {
        "Own": 7,
        "Total": 7
      },
      "MethodCount": {
        "Own": 13,
        "Total": 14
      },
      "path": "./database/GUILDAsystem/DrawerModelGUI.js",
      "Image": ""
    },
    {
      "Name": "DrawerOptionDialog",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Option form of one method, generated from functionSignatures.json, that writes the call as code.",
      "Desc": "The form has one row per input of the method in `_GUILDAsystem/resources/functionSignatures.json`\n(or, for a method missing there, `_GUILDAsystem/_auxiliary/resources/functionSignatures.json`)\n(GUILDA.update_keymap(Signature=true) writes it from the arguments blocks), except obj and\nthe inputs in Exclude.\n\nLayout (`_GUILDAsystem/resources/gui_forms.json`): the required and positional inputs come\nfirst, then the main options, then collapsible groups, closed when the form opens (e.g.\n\"Limits\", \"OPF\", \"Graph\", \"Advanced\"). The entry of a signature lists its main options and\nits groups with their members in order; options it does not list go to \"Advanced\". It can\nalso give English labels and units (`labels`), show options only for some values of another\noption (`visible`, e.g. the OPF options of initialize only for Method=\"OPF\"), and name the\nclass whose property defaults are the defaults of options built from its properties\n(`propertyDefaults`, for `opt.?GraphNetDiagram`). A signature missing from the file is\ngrouped by the names of its options (`_fallback`: OPF*, Stability*, the limits Pmin/Vmax/...,\nthe graph layout names DX/DY/Shape/Path/Offset/MarkerSize/Color, Parent/PlotFcn/Format);\nevery other option is a main option. The fields of a group are created when it is opened\nfirst, so a large form opens fast. An option hidden by `visible` is left out of the call.\n\nThe field of an input follows its \"type\":\n\n- `choices=<expression>`: a dropdown of the values of the expression. An expression on\n  `obj` is evaluated on the object of the call when the History that holds it is given.\n  Tags of the elements of a network (`obj.a_Bus`, `a_Branch`, `a_Component`,\n  `a_LocalController`, `a_GlobalController`, `a_Scenario`) get a text field with the tags\n  (`B001, B002`; commas, spaces or `|` separate them) and a \"Select...\" button that opens\n  DrawerTagPicker.pick with one row per element (an input whose type has \"scalar\" keeps its\n  dropdown next to the button and takes one tag). Other tag lists of the object give a list\n  in which several can be selected. A default of several values (`Default:\n  [\"Bus\",\"Component\",\"Branch\"]`) also gives such a list. Without History, or when the\n  expression cannot be evaluated, it gives a text field.\n  Choices that refer to another input of the method, by its name\n  (`obj.a_PowerNetwork.get_element(unit).sv_u` of Scenario.add_input) or by its default when\n  that is a property of the object (`obj.s_unit`, the default of Unit of EventInput.edit),\n  are evaluated for the current value of that input, and again only when it changes: the\n  dropdown or list takes the new items and keeps the values still among them. While that\n  input is empty or cannot be read, it has no items and the hint \"Select unit first\".\n- a model key (`choices=...GUILDA.keymap(\"Component\")...`): the dropdown of the keys and a\n  \"Select...\" button with the key table (DrawerTagPicker.key_table).\n- `logical`: a checkbox; a dropdown of \"\", \"true\" and \"false\" when the default is written\n  in words, where \"\" leaves the option out.\n- a numeric class: a text field for a number or a numeric array (`[0.1 0.02]`).\n- `string` or `char`: a text field, written as a string literal.\n- anything else (table, cell, struct, function handle, no class): a field for a MATLAB\n  expression, inserted into the code as it is.\n\nEvery field shows its default value (the `Default: <expression>.` at the end of the\npurpose, evaluated, on the object of the call too: a default from GUILDA.config shows the\ncurrent setting; `Default: obj.s_status` shows the value of the object). Special numbers\nare shown in words: NaN as \"auto\" (as \"none\" when the purpose says that NaN means none,\ne.g. \"NaN for none\"), Inf and -Inf as \"none\" when the purpose says so (\"Inf: none\"), else\nas Inf and -Inf; \"\" as an empty field. The field takes these words back. A default written\nin words (e.g. \"the Solver of the analysis that Method runs\") leaves the field empty with\na muted hint beside it. A default of alternatives of which one refers to another input\n(`Default: From.Time, else [0, 10].` of PowerNetwork.add_scenario) shows the first that\nevaluates for the current value of that input, and follows it while the field is unchanged:\n[0 10] while From is empty, the Time of From when From is a variable of the History\nfollowed only by properties and numeric indices (`sc`, `net.a_Scenario{2}`; nothing else is\nevaluated, so no method runs), else an empty field with the words as its hint. Left as\nshown, the option is not written (`sc = net.add_scenario();`). The unit of a purpose that\nstarts with `[pu]` is shown after the label. A field changed from its default is\nhighlighted and gets a reset button (↺). The tooltip is the purpose.\n\nValue gives initial values by input name, written as MATLAB code text (`\"B003\"`, `0.5`,\n`true`, `[\"B001\", \"B002\"]`): the field shows them instead of the default. The call still\ncompares with the default, so an option given this way is written while it differs from\nthe default and left out when it equals it; a required input is always written.\n\nget_code writes the call: the output variables, the object, the required inputs in order,\nthen only the visible options whose value differs from the default. An invalid value shows\na message in the form and get_code returns \"\", so no callback throws an error.\n\nPicker: the tables are built when \"Select...\" is pressed, from the network of the call\n(the root variable of Object when it is a network, else the network of the object), and\nonly the elements that the choices list are shown. The local controllers of\nComponent.remove_local_controller are those of the component of the call, so their tags\nare unique there. A trip (Scenario.add_trip, EventTrip.edit) names its units by tag only:\nwhen a tag chosen names several elements of the network, the form says so.\n\ngui_forms.json \"pick\" gives an input a \"Select...\" button. A list of element kinds is for an\ninput without choices that takes tags (`\"pick\": {\"LoadBus\": [\"Bus\"]}` of the CPF), and needs\nthe network of the call. An object `{\"table\": \"<expression on obj>\"}` is for an input with\nchoices (a list or a dropdown, which then becomes a text field with the tags, as for the\nelements), and needs no network: the button is shown whenever the entry is there, and the\nexpression is evaluated on the object of the call only when the button is pressed. It gives a\ntable with a Tag column; its other columns are shown beside the tags. One row is taken for an\ninput of type \"scalar\", several otherwise. When the expression fails or gives no rows, an\nalert (a warning in a hidden window) says so and the field stays as it is. The target of\nResultLIN.get_contribution, get_reduced_matrix and plot_reduced_matrix lists so the elements\nof the result (Kind \"element\") and their classes (Kind \"class\").",
      "SeeAlso": [
        "HistoryGUILDA",
        "DrawerTagPicker",
        "GUILDA.update_keymap",
        "GUILDA.config"
      ],
      "Examples": "```matlab\nfig = uifigure();\ndlg = DrawerOptionDialog(\"Bus.add_component\", fig, Object=\"net.a_Bus{3}\", Output=\"comp\");\ns_code = dlg.get_code()   % comp = net.a_Bus{3}.add_component(\"gen-park\");  (first key)\ndlg = DrawerOptionDialog(\"PowerNetwork.simulate\", fig, Object=\"net\", Output=\"res\", Value=struct(\"s_scenario\", \"\"\"case1\"\"\"));\ns_code = dlg.get_code()   % res = net.simulate(\"case1\");\ns_code = DrawerOptionDialog.ask(fig, \"PowerNetwork.calculate_powerflow\", Object=\"net\", Output=\"res_pf\");\nh = HistoryGUILDA();\nh.set_variable(\"net\", network.IEEE9bus());\ns_code = DrawerOptionDialog.ask(fig, \"PowerNetwork.remove_bus\", Object=\"net\", History=h);   % bus tags, with Select...\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_object",
          "Type": ""
        },
        {
          "Name": "a_network",
          "Type": "PowerNetwork"
        },
        {
          "Name": "a_history",
          "Type": ""
        }
      ],
      "PropertyCount": {
        "Own": 12,
        "Total": 12
      },
      "MethodCount": {
        "Own": 16,
        "Total": 17
      },
      "path": "./database/GUILDAsystem/DrawerOptionDialog.js",
      "Image": ""
    },
    {
      "Name": "DrawerResultGUI",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@DrawerResultGUI/DrawerResultGUI.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "GUI of an analysis result: header, the methods of the result as buttons, and a view area.",
      "Desc": "ResultBase.launch_gui creates one, in a new uifigure or in a given container (uifigure,\nuipanel, uitab or uigridlayout), so that it can be embedded in another app.\n\n- Header (logo blue band over a lime line): the variable of the result, its class, the\n  success state (l_success), a Docs button that opens the class reference\n  (GUILDA.doc(\"class\", ...)), the toggle \"Display options\" and a summary line (network,\n  solver, flag, elapsed time).\n- Method list: the methods of the result in the two functionSignatures.json files\n  (`_GUILDAsystem/resources` and `_GUILDAsystem/_auxiliary/resources`; entries\n  \"<class>.<method>\" of the class and of its superclasses) with the prefixes plot_, disp_\n  and get_ and the method export, as buttons in the groups Plot, Display, Get and Export.\n  A button shows a readable label (plot_voltage: \"Voltage\", get_lmp: \"LMP\", export:\n  \"Export to file\") and the method in its tooltip. The list comes from the files only, so\n  a result class needs no GUI code.\n- View area: the tabs Plot (a panel the plot_* methods draw in), Text (the text of the\n  disp_* methods, the values of the get_* methods and the file of export) and Log (the\n  log of the history, HistoryGUILDA.attach_view, drawn when the tab is first opened).\n- Default view on open, not logged (it changes no variable of the history): the Text tab\n  shows the summary (disp_summary, or the display of the result) and the Plot tab the\n  first plot_* method of the list with its defaults.\n- While \"Display options\" is pressed, the control panel of the last plot that returned a\n  GraphBase (G.show_controls) stands right of the plot panel. Its changes only set\n  properties of the graph and are not logged: they change no variable, and the script\n  draws the plots with their defaults.\n- A plot that animates starts playing once it is drawn in a visible window, as if its\n  Play button had been pressed (autoplay; never under matlab -batch or in a hidden\n  window): the first output graph of the call with a playback bar gets G.play(), so one\n  timer plays (ResultODE.plot_diagram: G plays and its linked side chart G_chart\n  follows). A chart whose time only moves a cursor has no bar and does not play\n  (plot_trajectory, ResultOPF.plot_iteration). This holds for the\n  first plot of the default view too. It does not block the window, and stops when the\n  window closes, when another plot replaces it, or with Pause of the playback bar.\n  Network diagrams run their flow animation (FlowAnimation). The control panel of\n  \"Display options\" belongs to the first graph output (for [G, G_chart]: G).\n\nA button runs its method as a line of MATLAB code through the history (HistoryGUILDA.run),\non the result variable of its workspace. A method with options first asks for them\n(DrawerOptionDialog.ask; Parent and the file of export are not asked); a method without\noptions runs at once. The code is what the log and the script show:\n\n- plot_*: `G = res.plot_voltage(Quantity=\"angle\", Parent=h_parent);` with the outputs named\n  as in the signature (`[G, G_chart] = res.plot_diagram(Parent=h_parent);`). Before\n  each run the GUI sets h_parent of the workspace to its plot panel and clears the panel.\n  The history gets the entry `h_parent = [];` once, before the first plot of any result\n  GUI, so the exported script draws every plot in a new figure.\n- disp_*: `s_text = res.disp_bus(Unit=\"SI\");` and `disp(s_text)`; the Text tab shows\n  s_text without hyperlinks.\n- get_*: `tab = res.get_lmp();`; the Text tab shows each output.\n- export: `s_file = res.export(\"<path>\", Table=\"branch\");`. The path comes from uiputfile\n  when the figure is visible, otherwise it is a file of tempdir (no user can answer).\n\nA failed run stays in the log (not in the script); the Text tab shows its message, and an\nalert too when the figure is visible. The colors are the fixed light palette of the\nGUILDA GUIs (tools.gui_palette).",
      "SeeAlso": [
        "ResultBase.launch_gui",
        "HistoryGUILDA",
        "DrawerOptionDialog",
        "DrawerModelGUI"
      ],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nh = res.launch_gui();            % new window, with HistoryGUILDA(Echo=true)\nh.history.get_script()           % the code of the buttons pressed\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_target",
          "Type": "ResultBase"
        }
      ],
      "PropertyCount": {
        "Own": 8,
        "Total": 8
      },
      "MethodCount": {
        "Own": 7,
        "Total": 8
      },
      "path": "./database/GUILDAsystem/DrawerResultGUI.js",
      "Image": ""
    },
    {
      "Name": "DrawerTagPicker",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/DrawerTagPicker.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Searchable table picker of tags and model keys, with the element tables it shows.",
      "Desc": "The picker shows one row per element in a uitable, with the columns that tell elements\napart (the bus of a component, its position on the bus, its class), and a search box\nabove it. The user only searches and chooses: the tables are built from the network when\nthe picker opens, never in advance.\n\n- element_table(net, s_kind): one row per element of one kind, in a single pass over the\n  network (no struct(net, false), no copies). The columns by kind:\n\n| Kind | Columns |\n|---|---|\n| Bus | Tag, Index, Type (\"slack\", \"PV\" or \"PQ\"), Components (number connected) |\n| Branch | Tag, Index, From, To (bus tags), Class |\n| Component | Tag, Bus (tag), BusIndex, Position (1, 2, ... on the bus), Class, Key |\n| LocalController | Tag, Component, Bus, Class, Role (\"avr\", \"pss\", \"governor\", \"local\"), Parent (the AVR of a PSS, else \"\") |\n| GlobalController | Tag, Class, Units (number of controlled components) |\n| Scenario | Tag, Time (\"[t0, tend]\"), Description |\n\n  Text columns are string, counts and indices double. A network without elements of the\n  kind gives a table with these columns and no rows.\n- key_table(s_category): one row per model key of GUILDA.keymap(s_category), sorted by\n  Key, with the columns Key, Class and Description (the first help line of the class). It\n  is kept for the MATLAB session and rebuilt when the classes of the key map change.\n- pick(h_parent_figure, tab, ...): a modal window with the search box, the table and the\n  buttons Select and Cancel. It returns the values of one column of\n  the chosen rows (\"Tag\", or \"Key\" for a key table), or strings(1,0) on cancel.\n\nThe search matches every word typed (separated by spaces) case-insensitively against the\ntext of all the columns of a row; a row is shown when it contains all the words. With\nMultiple=true the rows chosen stay chosen while the search hides them. In single mode a\ndouble click on a row chooses it at once.\n\nOne hidden picker window is kept per parent figure and reused: a new call swaps the data\nof its table, so the second opening costs only the new data. The window is recreated when\nit was deleted and is deleted with its parent.",
      "SeeAlso": [
        "DrawerOptionDialog",
        "GUILDA.keymap",
        "DrawerGUILDA"
      ],
      "Examples": "```matlab\nnet = network.IEEE68bus();\ntab = DrawerTagPicker.element_table(net, \"Component\")   % Tag, Bus, BusIndex, Position, Class, Key\nfig = uifigure();\nsv_tag = DrawerTagPicker.pick(fig, tab, Title=\"Component to remove\")\nsv_tag = DrawerTagPicker.pick(fig, DrawerTagPicker.element_table(net, \"Bus\"), Multiple=true, Selected=[\"B001\", \"B002\"])\ns_key = DrawerTagPicker.pick(fig, DrawerTagPicker.key_table(\"Component\"), Column=\"Key\")\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 0
      },
      "MethodCount": {
        "Own": 5,
        "Total": 6
      },
      "path": "./database/GUILDAsystem/DrawerTagPicker.js",
      "Image": ""
    },
    {
      "Name": "EventBase",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary, matlab.mixin.Copyable",
      "Superclasses": [
        "auxiliary",
        "matlab.mixin.Copyable"
      ],
      "Ancestors": [
        "auxiliary",
        "matlab.mixin.Copyable",
        "handle"
      ],
      "Subclasses": [
        "EventFault",
        "EventInput",
        "EventOffset",
        "EventOpenBranch",
        "EventTrip"
      ],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@EventBase/EventBase.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the events of a Scenario: one fault, trip, branch opening, offset or input.",
      "Desc": "An event is one disturbance of a scenario. Each subclass belongs to one add_* method of\nScenario and takes the same arguments in its constructor:\n\n| Class | Scenario method | Table | Tag |\n|---|---|---|---|\n| EventFault | add_fault | tab_event | Fault<n> |\n| EventTrip | add_trip | tab_event | Parallel<n> |\n| EventOpenBranch | add_open_branch | tab_event | Parallel<n> |\n| EventOffset | add_offset | tab_offset | Tag, default offset<n> |\n| EventInput | add_input | tab_input | Tag, default input<n> |\n\nThe add_* methods return the added event. Its properties are read-only: change them with\n`ev.edit(Name=Value)`, whose options are those of the add_* method. After an edit, the\nscenario checks all its events again (against its network); when a check fails, the\nevent gets back its values and the error is thrown. An event not in a scenario is only\nchecked by its arguments blocks.\n\nThe constructors are public and need no network, so events can be made first and copied\ninto a new scenario with `net.add_scenario(tag, Event={...})`. They are checked when they\nare added. The tables tab_event, tab_offset and tab_input of the scenario are built from\nits events (Scenario.a_Event).",
      "SeeAlso": [
        "Scenario",
        "PowerNetwork.add_scenario",
        "EventFault",
        "EventTrip",
        "EventOpenBranch",
        "EventOffset",
        "EventInput"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nsc = net.add_scenario(\"case1\", Time=[0, 20]);\nev = sc.add_fault(\"B008\", [0.10, 0.17]);        % EventFault, tag Fault001\nev.edit(Time=[0.10, 0.20]);                     % sc.tab_event shows the new end\nsc2 = net.add_scenario(\"case2\", Event={EventFault(\"B008\", [0.1, 0.17]), EventOpenBranch(\"EL003\", 0.17)});\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_Scenario",
          "Type": "Scenario"
        }
      ],
      "PropertyCount": {
        "Own": 4,
        "Total": 4
      },
      "MethodCount": {
        "Own": 5,
        "Total": 6
      },
      "path": "./database/GUILDAsystem/EventBase.js",
      "Image": ""
    },
    {
      "Name": "EventFault",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "EventBase",
      "Superclasses": [
        "EventBase"
      ],
      "Ancestors": [
        "EventBase",
        "auxiliary",
        "matlab.mixin.Copyable",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@EventFault/EventFault.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Ground fault on buses, or on branches, from t_start to t_end (Scenario.add_fault).",
      "Desc": "A bus fault (\"BG\", the default) holds the voltage of the bus at 0. A branch fault needs\nStatus and Point: \"3LG\" grounds one circuit, \"6LG\" all circuits, at Point along the\nbranch (0 < Point < 1, from the from end 0 to the to end 1). The targets are all buses or\nall branches. In tab_event the fault has two rows per target with its tag Fault<n>:\n(t_start, Status, Point) and (t_end, \"none\", Point).\n\nThe constructor checks only the types and sizes; the targets, the time span and Status\nand Point are checked when the event is added to a scenario.",
      "SeeAlso": [
        "EventBase",
        "Scenario.add_fault"
      ],
      "Examples": "```matlab\nev = sc.add_fault(\"B008\", [0.10, 0.17]);\nev.edit(Target=\"EL003\", Status=\"3LG\", Point=0.3);\nsc2 = net.add_scenario(\"case2\", Event={EventFault(\"B008\", [0.1, 0.17])});\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 6,
        "Total": 8
      },
      "MethodCount": {
        "Own": 3,
        "Total": 6
      },
      "path": "./database/GUILDAsystem/EventFault.js",
      "Image": ""
    },
    {
      "Name": "EventInput",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "EventBase",
      "Superclasses": [
        "EventBase"
      ],
      "Ancestors": [
        "EventBase",
        "auxiliary",
        "matlab.mixin.Copyable",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Values added to inputs of a component from t_start to t_end (Scenario.add_input).",
      "Desc": "The value is a constant (one number per input, or one for all) or a time series: a\nmatrix [t, v_1, ..., v_n] or a table with the variables Time and the input names (see\nScenario.add_input). It is stored as a constant column (s_method \"\") or as the matrix of\nthe series with its interpolation s_method (\"zoh\", \"foh\" or \"spline\"; \"foh\" when not\ngiven). In tab_input the input is one row. Its tag is Tag, or input<n> when Tag is\nempty. The constructor and edit check the form of the value\n(GUILDA:EventInput:InvalidInputTable, MethodWithoutSeries); the component, the input names,\nthe number of values and the series are checked when the event is added to a scenario.",
      "SeeAlso": [
        "EventBase",
        "Scenario.add_input"
      ],
      "Examples": "```matlab\nev = sc.add_input(\"B002SG1\", \"Pmech\", 0.05, [1, 1.5]);\nev.edit(Value=[0, 0; 2, 0.02], Time=[1, 3]);      % a ramp; Method back to \"foh\"\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 7,
        "Total": 9
      },
      "MethodCount": {
        "Own": 4,
        "Total": 7
      },
      "path": "./database/GUILDAsystem/EventInput.js",
      "Image": ""
    },
    {
      "Name": "EventOffset",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "EventBase",
      "Superclasses": [
        "EventBase"
      ],
      "Ancestors": [
        "EventBase",
        "auxiliary",
        "matlab.mixin.Copyable",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Offset of the states of a component at one time (Scenario.add_offset).",
      "Desc": "The values are added to the states at the time (to the initial states when it is the\nstart of the simulation). In tab_offset the offset is one row. Its tag is Tag, or\noffset<n> when Tag is empty; it names the column of output.phases. The component, the\nstate names and the number of values are checked when the event is added to a scenario.",
      "SeeAlso": [
        "EventBase",
        "Scenario.add_offset"
      ],
      "Examples": "```matlab\nev = sc.add_offset(\"B001SG1\", [\"delta\"; \"omega\"], [0.1; 0], 0);\nev.edit(Value=[0.2; 0]);\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 6,
        "Total": 8
      },
      "MethodCount": {
        "Own": 3,
        "Total": 6
      },
      "path": "./database/GUILDAsystem/EventOffset.js",
      "Image": ""
    },
    {
      "Name": "EventOpenBranch",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "EventBase",
      "Superclasses": [
        "EventBase"
      ],
      "Ancestors": [
        "EventBase",
        "auxiliary",
        "matlab.mixin.Copyable",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@EventOpenBranch/EventOpenBranch.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Opening of branches at time t (Scenario.add_open_branch).",
      "Desc": "\"6open\" (the default) opens all circuits: the branch is left out of the bus admittance\nmatrix. \"3open\" opens one circuit. The branches stay open until the end of the\nsimulation. In tab_event the opening has one row per branch with its tag Parallel<n>:\n(t, Status). The branches and the time are checked when the event is added to a\nscenario.",
      "SeeAlso": [
        "EventBase",
        "Scenario.add_open_branch"
      ],
      "Examples": "```matlab\nev = sc.add_open_branch(\"EL003\", 0.17);\nev.edit(Status=\"3open\");\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 7
      },
      "MethodCount": {
        "Own": 3,
        "Total": 6
      },
      "path": "./database/GUILDAsystem/EventOpenBranch.js",
      "Image": ""
    },
    {
      "Name": "EventTrip",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "EventBase",
      "Superclasses": [
        "EventBase"
      ],
      "Ancestors": [
        "EventBase",
        "auxiliary",
        "matlab.mixin.Copyable",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@EventTrip/EventTrip.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Trip of components, global controllers or local controllers at time t (Scenario.add_trip).",
      "Desc": "A tripped unit is disconnected at t and stays disconnected until the end of the\nsimulation (its states are NaN in the result). In tab_event the trip has one row per unit\nwith its tag Parallel<n>: (t, \"open\"). The units and the time are checked when the event\nis added to a scenario.",
      "SeeAlso": [
        "EventBase",
        "Scenario.add_trip"
      ],
      "Examples": "```matlab\nev = sc.add_trip(\"B003LPQ2\", 1);\nev.edit(Time=1.5);\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 4,
        "Total": 6
      },
      "MethodCount": {
        "Own": 3,
        "Total": 6
      },
      "path": "./database/GUILDAsystem/EventTrip.js",
      "Image": ""
    },
    {
      "Name": "GlobalController",
      "Origin": "System",
      "Folder": "_GUILDAsystem",
      "Category": "",
      "Type": "PowerSystemModel",
      "Model": "GlobalController",
      "Parent": "PowerSystemModel",
      "Superclasses": [
        "PowerSystemModel"
      ],
      "Ancestors": [
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "controller.agc.broadcast_PI_AGC"
      ],
      "Package": "",
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Abstract class of a controller that acts on several components of a network, such as an AGC.",
      "Desc": "A global controller is a dynamical system with state $x$, input $u$ and output $y$. It\nobserves the controlled components (`controlledUnits`) by the names in `sv_u` and the\nvoltages of all buses (its port V), and its outputs drive inputs of those components or of\ntheir local controllers. Subclasses in the\n`controller` package define the static model functions (`fcn_dx`, `fcn_y`, `fcn_Mass`), their Jacobians and the\nvariable names. A global controller is built for a network and added with\n`PowerNetwork.add_global_controller` from its model key `key` (e.g. \"agc-PI\").\n\n- Owns its parameters (one row per controlled unit), its equations (through its\n  subclass) and its equilibrium. Its parent is the network.\n- The components it acts on, `controlledUnits`, are associations fixed by its\n  constructor, which receives the network only to look them up. While the controller is\n  on the network, its units cannot be removed or replaced, nor their buses removed.\n- Input signals `sv_u`: for each controlled unit, in the order of `controlledUnits`, the\n  outputs `sv_y` of the unit of these names, or its states `sv_x` (an output is read when\n  both have the name, as for a local controller): u = [sv_u of unit 1; sv_u of unit 2; ...].\n  `iv_obsY` / `iv_obsX` hold where each input is read. A tripped unit gives 0.\n- Port V: the voltages of all buses [Vre1; Vim1; Vre2; ...] in the order of `a_Bus`. The\n  flow of a branch is not an input: the controller computes it from V and the branch data.\n- Output signals `sv_y`, one set per controlled unit in the same order: an output goes to\n  every local controller of the unit (nested ones included) that has an input of that name,\n  and then not to the component; the controller input receives the sum of what it reads\n  without the global controller (an output or a state of the component, the output of a\n  nested controller, or its equilibrium) and the output. Otherwise the output is added to\n  the input of that name of the component. These connections are the rows \"global\" of\n  the connection map (`net.get_variable_map`); `PowerNetwork.add_global_controller`\n  shows them, and an edit of the local controllers of a unit that changes them\n  (`Component.add_local_controller`, `remove_local_controller`) shows what changed as\n  an INFO message.\n  For example, `controller.agc.broadcast_PI_AGC` reads the speed \"omega\" of each\n  generator and adds to its input \"Pmech\".\n- The outputs must be 0 at the equilibrium (net.initialize checks it), as they add to\n  inputs whose equilibrium is already set.\n- Unlike a `LocalController`: no nested controller. It does not own its units and is not a\n  child of any bus.\n- Created only by `PowerNetwork.add_global_controller` (the constructors of the concrete\n  classes are accessible only from `PowerNetwork`), so a controller is always on a\n  network. Only the network sets `a_PowerNetwork` (`SetAccess`; add_global_controller\n  logs the attachment as a \"Topology\" edit), and `PowerNetwork.remove_global_controller`\n  deletes the controller.\n- The handles `f_*` @(t,x,V,u) bind param and omega0; `set_odefcn` builds them,\n  called by `initialize` when they are stale (`sct_stale.odefcn`, or a network\n  frequency other than `r_odefcnHz`).\n- Stale tags (`sct_stale`): `equilibrium` (its dynamics, its addition to the network)\n  and `odefcn` (its dynamics, its attachment). `initialize`, called last by\n  PowerNetwork.initialize, rebuilds them; the equilibrium is also recomputed whenever\n  that initialize found anything stale, since it may read the controlled units.",
      "SeeAlso": [
        "PowerNetwork.add_global_controller",
        "controller.agc.broadcast_PI_AGC",
        "LocalController"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\ng1  = net.a_Bus{1}.a_Component{1};\ng2  = net.a_Bus{2}.a_Component{1};\nagc = net.add_global_controller(\"agc-PI\", {g1, g2}, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));\nnet.initialize();\nsys = agc.get_sys();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_PowerNetwork",
          "Type": "PowerNetwork"
        }
      ],
      "PropertyCount": {
        "Own": 20,
        "Total": 26
      },
      "MethodCount": {
        "Own": 13,
        "Total": 23
      },
      "path": "./database/GUILDAsystem/GlobalController.js",
      "Image": "./database/images/GlobalController.svg"
    },
    {
      "Name": "GraphBase",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [
        "GraphChart",
        "GraphMatrix",
        "GraphNetDiagram",
        "GraphSpringBase"
      ],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Abstract base class of the graphs of GUILDA: every plot_* returns a graph object.",
      "Desc": "A graph draws data in one or more axes (panels) and keeps every later change in one\nplace: the data and the time shown, the appearance of each element, and, in a free\nlayout, its position. The same code then serves a picture and an animation.\n\n- Data: `set_data(sct_data)` replaces the data (the same contract as the data of the\n  constructor of the subclass) and keeps the appearance of the elements that still\n  exist (matched by tag and kind).\n- Time: `set_time(t)` shows the sample nearest to t; `animate` plays the samples and\n  `export_video` writes them to a video. Graphs joined by `link` follow `set_time`\n  (each at the nearest sample of its own times). The samples are times in seconds\n  unless the data names them: the optional fields `s_sampleName` (e.g. \"Step\") and\n  `sv_sampleText` (one text per sample, e.g. \"Step 12 (λ = 0.734)\") of the data of\n  every graph are shown in the playback bar and in the titles that show the\n  time. rv_t then holds the values of these samples (e.g. the step numbers), which\n  must still be nondecreasing; set_time(t), animate and export_video take them as they\n  take times (TimeStep is then a step of the sample values).\n- Elements: `tab_element` lists the elements (Tag, Kind, Index). Their appearance is held\n  in public vector properties of the subclass, one row per element of a kind (e.g.\n  NodeColor). `set_style(sr_tag, Name=Value)` writes the same vectors by tag, so the two\n  forms stay in sync, and only the changed elements are drawn again.\n- Positions: `set_position(sr_tag, rm_xy)` moves elements of a free layout\n  (GraphNetDiagram) and `get_layout()` returns the drawn positions in the\n  form of net.get_layout, so that net.set_layout(G.get_layout()) saves them. Other graphs\n  raise an error.\n- `reset_style(sr_tag)` returns the appearance of those elements (all with no argument)\n  to the defaults of the data.\n- Clicks: a click on an element raises the event ElementClicked and calls\n  ElementClickedFcn as fcn(G, data), with data a GraphEventData (Tag, Kind, Index).\n- Time changes: after set_time has drawn a graph (also a graph moved by link, and every\n  frame of animate and export_video), it raises the event TimeChanged and calls\n  TimeChangedFcn as fcn(G, data), with data a GraphTimeEventData (Time, Index of the\n  sample shown), e.g. to write a title or styles per time. build and set_data raise\n  nothing. A set_time called from these callbacks leaves the graphs of the set_time\n  that is running as they are, so a callback that moves a linked graph does not loop.\n- Selection: `select(sr_tag)` adds tags to Selection and `clear_selection()` empties it.\n  The selected elements (every element with a selected tag) are drawn with an overlay in\n  SelectionColor; the overlay does not change the appearance vectors, so clearing it\n  shows the appearance set before. The selection stays through set_time and set_data\n  (tags that disappear are dropped).\n\nHook contract of a subclass (protected methods):\n\n- `load_data(sct_data)`: check the data, store it, set rv_t (1 x n_t), call\n  load_sample_label(sct_data) (the optional sample name and texts) and set the vector\n  properties of the appearance to the defaults of the data. It draws nothing: sct_plt is\n  empty while it runs, so the setters of the vector properties must not draw then.\n- `create_scene()`: draw the fixed parts in ax and create every graphics object of the\n  elements in sct_plt, with the appearance of the vector properties. Called after the\n  axes are set and after load_data, and again by the subclass when a property changes\n  the fixed parts. Called by set_data, sct_pltPrevious holds the drawing before, whose\n  objects it may reuse when they still fit the new data.\n- `update_scene(k)`: draw sample k (i_time is already k): move the graphics objects and\n  show the time, e.g. in the title or with a cursor line.\n- `apply_style(iv_element)`: draw again the appearance of the elements of the rows\n  iv_element of tab_element from the vector properties. The setters of the vector\n  properties call it with the changed rows once sct_plt exists.\n- `tab = element_table()`: the element table of the current data (columns Tag, Kind,\n  Index); tab_element returns it.\n- `sct_map = style_properties()`: for each kind, the set_style options that apply and the\n  vector property each writes, e.g. sct_map.node.Color = \"NodeColor\". A kind with no\n  options maps to struct().\n- `apply_selection()`: delete the previous selection overlay and draw a new one for the\n  elements whose tag is in Selection, in SelectionColor, at the positions shown. The\n  overlay must not take clicks (PickableParts \"none\"). The base calls it after\n  update_scene (build, set_time, set_data) and when Selection or SelectionColor changes;\n  a subclass that calls create_scene or update_scene itself (e.g. in a property setter)\n  calls it afterwards.\n\nClicks: create_scene sets the ButtonDownFcn of the graphics objects of each element (or\nuses another hit test, such as the data tips) so that a click calls the protected\n`click_element(i_row)` of the base with the row of the element in tab_element.\n\nThe constructor of a subclass loads its data, then calls build(opt, n_panel, rv_grid)\nwith its Name-Value options: build sets ax with make_axes(opt.Parent, n_panel, rv_grid),\ncopies the other options to the properties, calls create_scene and shows the first\nsample. Parent is a container (figure, uifigure, uipanel, uitab, uigridlayout; a tiled\nlayout of rv_grid = [n_row n_col] tiles, default one column, is made in it and the\nn_panel axes fill it row by row), an axes or uiaxes (single-panel graphs only; a graph\nwith several panels stops with GUILDA:GraphBase:ParentNeedsContainer), or empty (a new\nfigure).\n\nPlayback bar: a graph whose drawing changes with its two or more samples (see\nhas_playback; a chart whose time only moves a cursor has none) gets a bar below its axes\nwhen they are made in a container (a new figure, or the container given by Parent; not\nwhen Parent is an axes). The bar has a Play/Pause button, a time slider,\nthe text of the sample shown (sample_text) and a dropdown of the playback speed\n(0.1x to 10x, the same as PlaySpeed; another value of PlaySpeed shows as an item of its\nown). The axes keep the space above it. The bar follows set_time (also through link),\nset_data (the slider takes the new samples; the bar appears or goes when the number of\nsamples crosses two) and animate. Play (or `G.play()`) plays the samples from the one\nshown (from the first when the last is shown) by a timer, so MATLAB stays usable:\nPlaySpeed times real time (one sample value per second at 1 for samples named by the\ndata). Pause (or `G.pause()`), closing the figure, deleting the axes or deleting the\ngraph stops the timer and deletes it. As for FlowAnimation of GraphNetDiagram, no timer\nis made in matlab -batch or for a figure that is not visible: Play then does nothing\n(the slider still works). While a playback runs (also a blocking animate), the button\nshows Pause and Play starts nothing more.\nexport_video and exportgraphics of the axes do not show the bar.\n\nControls: `G.show_controls()` puts a panel of controls next to the axes (or in a given\ncontainer, e.g. a cell of a GUI) and `G.hide_controls()` removes it. The panel is made\nfrom the declaration `control_list()` of the subclass (one row per control: a property\nand its widget) and only sets these properties: a change in the panel sets the\nproperty, and a change of the property (by code, set_style or another panel) updates\nthe panel. The time is in the playback bar, not in the panel. No plot_* shows the panel\nby itself.\n\n`prepare_frame(r_dt)` (protected) is called by export_video before each frame with the\ntime between frames [s], and with NaN after the last one; the default does nothing.\n`sample_text(k, s_format)` (protected) is the text of sample k for a title or the panel:\nthe text of the data, the sample name and value, or sprintf(s_format, rv_t(k)).\n\nThe protected static helpers set_arrow, place_label, resolve_overlap, write_frame and\nrange_map (sizes and widths normalized into a range) are shared by the subclasses (the\nprivate functions of a class folder are not visible to its subclasses).",
      "SeeAlso": [
        "GraphSpringBase",
        "GraphNetDiagram",
        "GraphChart",
        "GraphEventData",
        "GraphTimeEventData"
      ],
      "Examples": "```matlab\nG = net.plot_spring_model();\nG.set_style([\"B001\", \"B002\"], Color=\"r\", MarkerSize=20);\nG.NodeColor(3, :) = [0 0.5 0];       % the same as set_style by tag\nG.tab_element                         % Tag, Kind, Index of every element\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 24,
        "Total": 24
      },
      "MethodCount": {
        "Own": 41,
        "Total": 42
      },
      "path": "./database/GUILDAsystem/GraphBase.js",
      "Image": ""
    },
    {
      "Name": "GraphChart",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "GraphBase",
      "Superclasses": [
        "GraphBase"
      ],
      "Ancestors": [
        "GraphBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Chart of analysis results: panels of lines, bars and marker sets.",
      "Desc": "A chart has one or more panels (axes, one above the other, or in a grid: rv_grid) and a\nlist of series. A series is drawn in one panel: a set of lines, a set of bars or a set\nof markers. Every line, every bar and every marker set is an element of tab_element\nwith its own tag, so set_style, the vector properties, select and the clicks work on\neach of them. On the panels marked as time panels, set_time(t) draws a vertical cursor\nat t (none before the first set_time), so that a chart linked to a GraphSpring2D or\nGraphNetDiagram follows its animation. A time panel whose x is not the time (e.g. a PV\ncurve against lambda, one point per step) takes a marker cursor instead (s_cursor\n\"marker\"): set_time puts a marker on each line and marker set at its point of the\nsample. A chart without time panels ignores set_time (TimeChanged still fires, e.g. to\nwrite a title per time; see GraphBase), unless a series is shown by sample (iv_sample)\nor a panel has a title per sample. A 3D panel (l_3d) draws lines and marker sets in x,\ny and z (e.g. P, Q and |V| per bus), and its time cursor is the marker cursor.\n\nThe data (constructor and set_data) is a struct with the fields:\n\n- `sct_panel` (1 x n_panel struct, optional; one panel when missing): per panel\n  - `s_title`, `s_xlabel`, `s_ylabel`, `s_zlabel`: title and axis labels (\"\" none;\n    s_zlabel for a 3D panel); s_title may also be one title per sample (1 x n_t), shown\n    with the sample;\n  - `rv_xlim`, `rv_ylim`, `rv_zlim`: axis limits ([] automatic, from the data in x, y and\n    z);\n  - `s_xscale`, `s_yscale`: \"linear\" (default) or \"log\";\n  - `l_time`: true for a time panel (default false);\n  - `l_3d`: true for a 3D panel (default false): its series are lines and marker sets\n    with rm_z, drawn in view(3); no bars and no reference lines. Drag the axes (or use\n    the rotate button of the axes toolbar) to turn it; clicks on the lines still raise\n    ElementClicked. A new drawing (set_data) keeps the view the user turned it to;\n  - `s_cursor`: cursor of a time panel, \"line\" (default of a 2D panel; a vertical line\n    at x = t) or \"marker\" (a marker in the color of the element at (rv_x(k), rm_y(k,\n    column)), or (rv_x(k), rm_y(k, column), rm_z(k, column)) in a 3D panel, of each line\n    and marker set of the panel, for sample k; their rm_y must have one row per sample\n    of rv_t). A 3D time panel takes \"marker\" only (its default there; \"line\" is an\n    error, GUILDA:GraphChart:Panel3D);\n  - `l_grid`: grid lines (default true);\n  - `s_legendLocation`: location of the legend (default \"best\"); \"none\" hides it.\n- `sct_series` (1 x n_series struct): per series\n  - `i_panel`: panel of the series (default 1);\n  - `s_type`: \"line\" (default), \"bar\" or \"marker\";\n  - `rv_x` (n_x): x values, or `sv_x` (n_x): category names (drawn at x = 1..n_x with\n    these tick labels; all series of a panel with categories must have the same ones).\n    Default x = 1..n_x;\n  - `rm_y` (n_x x n_col): y values, one column per line or marker set (e.g. time x\n    lines); a bar series has one column, one bar per row. NaN leaves a gap;\n  - `rm_z` (n_x x n_col, optional, default []): z values of a line or marker series of a\n    3D panel, the size of rm_y; required in a 3D panel and an error in a 2D panel\n    (GUILDA:GraphChart:Panel3D);\n  - `sv_tag`: tags of the elements, one per column (line, marker) or per bar (bar;\n    default sv_x);\n  - `sv_legend`: legend entries, one per column (line, marker; default sv_tag; \"\"\n    leaves the element out of the legend), or one for a bar series (default \"\": none);\n  - `rm_color`: initial colors (1 x 3 for all, or one row per element; a color name or\n    \"#RRGGBB\" for all); NaN rows (default) use the color order of the axes;\n  - `r_lineWidth` (default 1), `s_lineStyle` (default \"-\"), `s_marker` (default \"none\"\n    for a line, \"o\" for a marker set), `r_markerSize` (default 6): initial values;\n  - `iv_sample` (n_x, optional, lines and marker sets): the sample (index in rv_t) of\n    each row. The series then shows only the rows of the sample shown, e.g. the\n    eigenvalues of one section of ResultLIN.plot_eigenvalue; set_time(t) changes them\n    (in a 3D panel too).\n- `sct_refline` (struct array, optional): reference lines, e.g. a limit value. Per line\n  `i_panel` (default 1), `s_axis` (\"x\" a vertical line, \"y\" a horizontal line; default\n  \"y\"), `r_value`, `s_label` (default \"\"), `rv_color` (default [0.85 0.33 0.10]) and\n  `s_lineStyle` (default \"--\"). They are part of the fixed drawing, not elements.\n- `rv_t` (1 x n_t) [s] (optional, default 0): the times that set_time chooses from (or\n  the values of other samples, e.g. steps, with s_sampleName).\n- `s_sampleName`, `sv_sampleText` (optional): the name of the samples (e.g. \"Step\") and\n  the text of each sample (1 x n_t), shown in the playback bar instead of the time (see\n  GraphBase).\n- `s_title` (optional): title of the whole chart, on the tiled layout (with an axes as\n  Parent, on the axes when its panel has no title).\n- `rv_grid` (1 x 2, optional, default [n_panel 1]): rows and columns of the tiled layout,\n  [n_row n_col] with at least n_panel tiles. The panels fill the tiles row by row (in a\n  2 x 2 grid, panel 2 is at the top right); the tiles after the last panel stay empty.\n\nThe bar series of a panel are drawn as one grouped bar chart. set_data takes the same\nstruct with the same number of panels and the same rv_grid (the axes are made once);\nit keeps the appearance of the elements by tag and kind.\n\nElements: one row per line (\"line\"), per bar (\"bar\") and per marker set (\"marker\"), in\nthe order of the series and of their columns (bars). Index is the row of the element\nin the vector properties, which hold one row per element in this order. set_style\noptions by kind:\n\n| Kind | Options |\n|---|---|\n| line | Color, Label, LineWidth, LineStyle, Marker, MarkerSize, Visible |\n| marker | Color, Label, Marker, MarkerSize, Visible |\n| bar | Color, Visible |\n\nLabel is the legend entry (\"\" leaves it out). A hidden bar keeps its place in the\ngroup. The rows of a kind that has no such option are kept but not used. Changing a\nvector property changes the existing graphics objects only. A click on a line, a marker\nset or a bar raises ElementClicked; a selected line or marker set gets a wide line or\nring under it, a selected bar an outline, in SelectionColor.\n\nThe data tip of a line or marker set starts with the name of the element: its legend\nentry (SeriesLabel), or its tag when the entry is \"\". The data tip of a bar starts with\nthe tag of the bar. The next rows are the X and Y values (and Z in a 3D panel), labeled\nwith s_xlabel, s_ylabel and s_zlabel of the panel (\"X\", \"Y\" and \"Z\" when these are \"\").\nThe cursors, the reference lines and the selection overlay take no clicks and no data\ntips.\n\nThe playback bar below the axes (see GraphBase) is shown when the drawing of the chart\nchanges with the time: two or more samples and a series with iv_sample or a title per\nsample (has_playback). A chart whose time only moves a cursor (a time panel, e.g.\nResultODE.plot_trajectory) has no bar: set_time, animate, export_video, link and the bar\nof a linked graph move its cursor.\nshow_controls has no controls: the appearance is per element.\n\nParent: a container gives a tiled layout of rv_grid with one axes per panel; a\nsingle-panel chart also draws in an axes or uiaxes (see GraphBase).",
      "SeeAlso": [
        "GraphBase",
        "ResultODE.plot_trajectory"
      ],
      "Examples": "```matlab\nsct = struct();\nsct.rv_t = 0:0.01:2;\nsct.sct_panel  = struct(\"s_xlabel\", \"t [s]\", \"s_ylabel\", \"y\", \"l_time\", true);\nsct.sct_series = struct(\"rv_x\", sct.rv_t, \"rm_y\", [sin(sct.rv_t); cos(sct.rv_t)].', ...\n                        \"sv_tag\", [\"s\"; \"c\"]);\nG = GraphChart(sct);\nG.set_style(\"s\", Color=\"r\", LineWidth=2);   % the same as G.SeriesColor(1, :) = [1 0 0] ...\nG.set_time(1.0);                           % cursor at t = 1\n```\n\nA 3D panel: lines in (x, y, z), e.g. (P, Q, |V|) of buses (rv_x is per series: one series\nper bus when their P differ), with a marker at the point of each sample.\n\n```matlab\nrv_t = 0:0.1:1;\nsct = struct(\"rv_t\", rv_t);\nsct.sct_panel  = struct(\"s_xlabel\", \"P [pu]\", \"s_ylabel\", \"Q [pu]\", \"s_zlabel\", \"|V| [pu]\", ...\n                        \"l_3d\", true, \"l_time\", true);       % s_cursor \"marker\" by default\nsct.sct_series = struct(\"rv_x\", rv_t, \"rm_y\", [0.3*rv_t; 0.1*rv_t].', ...\n                        \"rm_z\", [1 - 0.2*rv_t.^2; 1 - 0.1*rv_t.^2].', \"sv_tag\", [\"B1\"; \"B2\"]);\nG = GraphChart(sct);\nG.set_time(0.5);                           % markers at (rv_x(6), rm_y(6, :), rm_z(6, :))\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 12,
        "Total": 26
      },
      "MethodCount": {
        "Own": 11,
        "Total": 39
      },
      "path": "./database/GUILDAsystem/GraphChart.js",
      "Image": ""
    },
    {
      "Name": "GraphEventData",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "event.EventData, auxiliary",
      "Superclasses": [
        "event.EventData",
        "auxiliary"
      ],
      "Ancestors": [
        "event.EventData",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/GraphEventData.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Data of the event ElementClicked of a graph: the element that was clicked.",
      "Desc": "A graph (GraphBase) raises ElementClicked and calls its ElementClickedFcn as\nfcn(G, data) with this object when an element is clicked. The fields are those of the\nrow of the element in G.tab_element.",
      "SeeAlso": [
        "GraphBase"
      ],
      "Examples": "```matlab\nG = net.plot_diagram();\nG.ElementClickedFcn = @(G, data) disp(data.Tag + \" (\" + data.Kind + \")\");\naddlistener(G, \"ElementClicked\", @(G, data) G.select(data.Tag));\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 3,
        "Total": 3
      },
      "MethodCount": {
        "Own": 1,
        "Total": 2
      },
      "path": "./database/GUILDAsystem/GraphEventData.js",
      "Image": ""
    },
    {
      "Name": "GraphMatrix",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "GraphBase",
      "Superclasses": [
        "GraphBase"
      ],
      "Ancestors": [
        "GraphBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphMatrix/GraphMatrix.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Matrix whose rows and columns are named variables: the pattern, the magnitude or the values.",
      "Desc": "The graph draws one matrix per sample (e.g. a Jacobian at several times) with the\nnames of the variables as tick labels and thin separator lines between the groups of\nrows and of columns (e.g. the owner of each variable). It is built from data only.\n\nThe data (constructor and set_data) is a struct with the fields:\n\n- `c_matrix` (1 x n_t cell): the matrix of each sample, n_row x n_col real (double or\n  logical, sparse allowed). Every sample has the same size.\n- `rv_t` (1 x n_t) [s]: the times of the samples, finite and nondecreasing. It may be\n  left out for one sample (t = 0).\n- `sv_rowName` (n_row), `sv_colName` (n_col): the names of the rows and columns.\n- `sv_rowGroup` (n_row), `sv_colGroup` (n_col): the group (owner tag) of each row and\n  column, nonempty. The rows of a group need not be next to each other.\n- `s_title`, `s_rowLabel`, `s_colLabel` (optional, default \"\"): the title and the\n  labels of the axes.\n- `l_frame` (optional, default false): a box around each block of a group that is\n  both a row group and a column group (the diagonal blocks of a square matrix).\n- `l_valueText` (optional, default false): the values of the sample shown are written\n  in their cells (\"%.3g\"; the entries above Tolerance, when there are at most 900).\n- `l_groupTicks` (optional, default false): one tick label per block of a group (its\n  tag, at the middle of the block) instead of the names of the rows and columns.\n- `l_cellGrid` (optional, default false): a thin line around every cell.\n- `s_pattern` (optional): \"dot\" (default: a dot per entry above Tolerance) or \"circle\"\n  (a red filled circle per entry above Tolerance and a hollow circle per zero entry).\n- `s_sampleName`, `sv_sampleText` (optional): the name of the samples (e.g. \"Section\")\n  and the text of each sample (1 x n_t), shown in the title and the playback bar\n  instead of the time (see GraphBase).\n\nDisplay:\n\n- `\"pattern\"` (default): a dot at every entry with |value| > Tolerance.\n- `\"magnitude\"`: an image colored by log10|value|, with a colorbar; the entries with\n  |value| <= Tolerance are blank.\n- `\"value\"`: an image of the signed values with a diverging colormap (blue negative,\n  red positive) and a colorbar; the entries with |value| <= Tolerance are blank.\n\nNaN entries are not drawn. `ColorLimits` sets the limits of the colorbar: of\nlog10|value| for \"magnitude\" and of the value for \"value\". A NaN limit (default\n[NaN NaN]) is automatic: over the entries above Tolerance of all samples, [min max] of\nlog10|value| for \"magnitude\" and [-m m] (m the largest |value|) for \"value\".\n\nThe tick labels are the names. When they would overlap (e.g. 300 variables in a small\naxes), only every k-th name is shown, with k the smallest step that fits; the labels are\nchosen again when the figure is resized. A data tip on the matrix shows the row name,\nthe column name, their groups and the value of the sample shown.\n\nTime: set_time(t) shows the sample nearest to t, and the title shows its time or its\nsample text (not for data of one sample at t = 0 without a text).\n\nElements: one row per group of rows (Kind \"rowgroup\") and per group of columns (Kind\n\"colgroup\"), in the order of their first row or column; the Tag is the group. A group of\nrows has a horizontal line before each block of its rows (the first one on the edge of\nthe axes), a group of columns a vertical line before each block of its columns.\n`select(tag)` highlights the rows and the columns of the group; a data tip on a\nseparator line is a click on its group (ElementClicked). A click on any cell of the\nmatrix (a dot, an empty cell: a transparent image covers them all) or a data tip on it\n(the data cursor mode, which the graph turns on, makes a click a data tip) sets\nClickedCell to [row column] and is a click on the group of its row. set_style options by kind:\n\n| Kind | Options |\n|---|---|\n| rowgroup | Color, LineWidth |\n| colgroup | Color, LineWidth |\n\nshow_controls shows Display, ColorLimits (with an Auto checkbox; disabled for\n\"pattern\") and Tolerance; for two or more samples the time is in the playback bar below\nthe axes (see GraphBase).\n\nParent: a container gives a tiled layout with one axes; an axes or uiaxes is used\ndirectly (see GraphBase).",
      "SeeAlso": [
        "GraphBase",
        "GraphChart",
        "GraphNetDiagram"
      ],
      "Examples": "```matlab\nsct = struct();\nsct.rv_t        = [0 1];\nsct.c_matrix    = {sparse([1 2 0; 0 -3 4; 5 0 6]), sparse([1 0 0; 0 -2 4; 5 0 7])};\nsct.sv_rowName  = [\"delta\"; \"omega\"; \"V\"];\nsct.sv_colName  = [\"delta\"; \"omega\"; \"V\"];\nsct.sv_rowGroup = [\"G1\"; \"G1\"; \"B1\"];\nsct.sv_colGroup = [\"G1\"; \"G1\"; \"B1\"];\nG = GraphMatrix(sct, Display=\"value\");\nG.set_style(\"G1\", Color=\"r\", LineWidth=2);   % the separators of G1 (rows and columns)\nG.select(\"B1\");                              % highlight the rows and columns of B1\nG.set_time(1);                               % the second sample\nG.show_controls();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 8,
        "Total": 22
      },
      "MethodCount": {
        "Own": 10,
        "Total": 39
      },
      "path": "./database/GUILDAsystem/GraphMatrix.js",
      "Image": ""
    },
    {
      "Name": "GraphNetDiagram",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "GraphBase",
      "Superclasses": [
        "GraphBase"
      ],
      "Ancestors": [
        "GraphBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/GraphNetDiagram.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Single-line diagram of a network: buses, components and branches, in 2D or 3D.",
      "Desc": "The diagram is built from data only: a snapshot of the network (struct(net, false)) and\nthe state to show. It never reads or changes a network. net.plot_diagram draws the\nequilibrium of the network, ResultPF.plot_diagram the power flow solution and\nResultODE.plot_diagram every output time of a simulation. The colors\nof the branches and of the links (the lines between a component and its bus) follow\nColorMode, the widths of the branches follow BranchWidthMode, the sizes of the buses and\ncomponents MarkerSizeMode and the heights of the buses BusHeightMode. Changing a\nproperty updates the drawing; hovering over an element shows its values.\n\nEvery value drawn by color can be read. The data tip of an element (hover, or a click in\nthe data cursor mode) has, under its tag, one line \"<name> = <value>\" after a square of\nits color: the value that colors it at the sample shown (BusColorData of a bus; the\nquantity of ColorMode, or BranchColorData and LinkColorData under \"user\", of a branch\nand a link; ComponentColorData or the value of ColorMode of a component), written with\n%.5g, e.g. \"LMP [cost/pu] = 3901.6\". The name is the colorbar label: ColorbarLabel, or\nwith \"\" the quantity of ColorMode (\"|I| [pu]\", \"Loss [pu]\", ...), or \"color\" when there\nis none (\"user\"). The line is there even when the tip lists the same quantity below (|I|\nof the \"from\" end with \"I\", P_loss with \"Loss\"): it is always the colored value, named as\nthe colorbar. An element without a finite color value (NaN) has no such line.\n\nDimension chooses the drawing. \"2D\" (default) draws flat symbols, lines and markers\nwithout lighting: a bar bus is a line segment, a point bus and a component a marker, a\nbranch and a link a polyline, and a transformer two overlapping circles near the \"from\"\nend. \"3D\" draws solids (boxes, tubes, spheres, cones) with lighting and arrow cones.\nBoth put each bus at its height (BusHeightMode; 0 for \"none\"), a branch climbs linearly\nalong its path between the heights of its ends, and a component and its link stay at\nthe height of its bus. The first drawing looks from the top; a later drawing (Dimension,\nBusHeightMode, set_position, set_data) keeps the view the user rotated to. When the 3D\ndrawing gets heights (the first drawing too) while it looks from the top, it turns to\nan oblique view (azimuth -37.5, elevation 30), and back to the top when the heights go\naway in that view.\n\nSizes and widths are in points (pt), as LineWidth and MarkerSize of MATLAB, so they do\nnot depend on the coordinates. The value of the quantity of BranchWidthMode is mapped\nlinearly onto BranchWidthRange (default [1 4] pt) from its smallest value to its 95th\npercentile over the branches and all samples of the state, leaving out the top outliers\nas the automatic ColorLimits do: the top 5 % take the largest width (with fewer than 20\nvalues, or a 95th percentile equal to the smallest value, the scale goes to the largest\nvalue). The value of MarkerSizeMode is mapped from its smallest to its largest value\nonto MarkerSizeRange (default [5 10] pt; buses and components each on their own scale).\nOne scale for all samples gives the same pt per unit at every time; set_data computes it\nagain from the new state. A mode of \"none\", or a quantity with one value or no value\n(the topology), gives the middle of the range, and a NaN value the minimum. The links\nare LinkWidth wide. In 3D, 1 pt is span/400 in coordinates (span: the larger side of the\nbox of the bus centers).\n\nIn 2D, dots (small triangles) move along the branches and links in the direction of the\nflow of FlowMode: \"P\" (default), \"Q\" (the flow (X_from - X_to)/2 of the powers into a\nbranch at its two ends, and the injection of a component), \"I\" (the larger |I| of the\ntwo ends, or |I| of a component, in the direction of P) or \"none\" (no dots). A dot\nmoves at FlowSpeed*d0*|q|/q_max per second (d0: the median length of the branch paths;\nq_max: the largest |q| over the branches, links and all samples), and the dots of an\nelement are 0.25*d0 apart, so the speed shows the flow. An element with no flow or a\nflow below 1e-3*q_max has no dots. The dots follow the sample shown (set_time) and the\nheights of the paths, and are white with a thin dark edge. With FlowAnimation\ntrue (default) a timer moves them about 25 times per second while the 2D figure is\nvisible; it is not made in a hidden figure (show the figure, then set FlowAnimation =\ntrue again) nor with matlab -batch, and it stops with FlowAnimation = false, \"3D\",\nFlowMode \"none\", the figure closed, cla, or delete(G). Without it the dots stay where\nthey are, so a still image shows the direction too. export_video moves them by the\ntime between its frames. BranchDirection and LinkDirection are the signs of the flow\n(the cones of 3D point the same way; with FlowMode \"none\", the voltage angles and P).\n\nThe layout comes from the graph parameters of the snapshot (notes/graph-layout.md): the\ncenter X, Y, Shape and Length of each bus (a bar is centered at X, Y), the bend points\nPath, the attachments FromOffset, ToOffset and Style of each branch (\"transformer\": a\nsymbol at the \"from\" end), and the position DX, DY, the bend points Path and the\nattachment Offset of each component, relative to the center of its bus. A branch or a\nlink meets a bar on its center line, at its offset (NaN: the nearest bend point\nprojected onto the bar, or the center). The buses without a position are placed by\ntools.layout_place_buses near their neighbours (the buses with one never move); a\ncomponent without a position is placed around its bus. These positions stay in the\ngraph: nothing is written to the network. set_position moves a bus or a component in\nthe drawing (never in the model); the components of a moved bus move with it.\nget_layout returns the drawn positions, and net.set_layout(G.get_layout()) saves them.\n\nThe state is a struct with the fields:\n\n- `rv_t` (1 x n_t) [s]: times of the samples (or the values of other samples, e.g. the\n  steps of a continuation power flow, with s_sampleName).\n- `cm_Vbus` (n_bus x n_t) [pu]: bus voltage phasors, in the a_Bus order of the snapshot.\n- `cm_Icomp` (n_comp x n_t) [pu]: current phasors injected by the components into their\n  buses, bus by bus in the a_Bus order and in the a_Component order of each bus.\n- `c_Ybranch`, `iv_Ybranch` (optional) [pu]: the admittance matrices of the branches of\n  each sample: c_Ybranch{m} is 2 x 2 x n_branch (page k: branch k of the snapshot) and\n  iv_Ybranch (n_t values) the position in c_Ybranch of each sample, e.g. the branch\n  states of the phases of a simulation (ResultODE.plot_diagram).\n- `s_sampleName`, `sv_sampleText` (optional): the name of the samples (e.g. \"Step\") and\n  the text of each sample (1 x n_t), shown in the title and in the playback bar instead\n  of the time (see GraphBase).\n\nset_time(t) shows the sample nearest to t. The current injection of a bus is the sum of\nthe currents of its components (NaN, a tripped unit, counts as 0), and the branch\ncurrents come from the bus voltages and the admittance matrix of each branch: of\nc_Ybranch at that sample when the state has it, else the field cm_Y of the branch in\nthe snapshot. The stored state sct_state also holds them as cm_Ibranch (2 n_branch x\nn_t: the currents into the branch at its from and to ends).\n\n- `ColorMode`: \"I\" (current), \"P\" (active power), \"Q\" (reactive power), \"Loss\" (the\n  active-power loss Re(S_from + S_to) of each branch, charging and tap included), \"none\",\n  or \"user\" (the values set in BusColorData, ComponentColorData, BranchColorData and\n  LinkColorData are kept). With \"I\", \"P\" and \"Q\" a component takes the color of the\n  value of its link. While a colormap is in use (not \"none\", and an element has a finite\n  color value) a component without a value (\"Loss\", a tripped unit, a NaN row of \"user\")\n  is black; with \"none\" the components keep their class colors. ComponentColor rows\n  override both.\n- `BusColorMode`: \"none\" (default), \"V\" (|V| [pu]) or \"angle\" (the angle of V in\n  degrees, as in the data tip of a bus). With \"V\" or \"angle\" the buses are colored by\n  that quantity at the sample shown (BusColorData, written again at every sample) on the\n  colormap, and the quantity takes the colorbar: its label is \"|V| [pu]\" or \"∠V [deg]\"\n  (or ColorbarLabel) and the automatic limits are the smallest and the largest value\n  over the buses and all samples. The colors of ColorMode are not drawn meanwhile: the\n  branches, links and components have no color value (as with ColorMode \"none\"; the\n  components keep their class colors), since one colorbar cannot show two quantities.\n  ColorMode keeps its value and colors them again when BusColorMode is \"none\". The data\n  tip and the \"value\" label of a bus show the line of its color value.\n- `ColorLimits`: [NaN NaN] (default) takes the limits from the data of all samples,\n  leaving out the top outliers: with m the 95th percentile of |value| over the branches,\n  the links and all samples (nearest rank), [0, m] for a magnitude (\"I\", \"Loss\") and\n  [-m, m] for a signed quantity (\"P\", \"Q\"; the injections of the components are\n  signed); the 5th to 95th percentiles with \"user\". Values beyond take the end colors.\n  With fewer than 20 values, or a percentile of 0, the largest (smallest) value is used.\n  With BusColorMode \"V\" or \"angle\", the smallest to the largest bus value instead.\n  A numeric [cmin cmax] fixes them.\n  Limits closer than 1e-6 of their size (a field constant up to rounding) are shown as\n  c(1 -/+ 1e-3) around their middle c, so that the colorbar ticks stay readable.\n- `BranchWidthMode`: \"P\", \"Q\" (|P_from - P_to|/2, |Q_from - Q_to|/2: the flow\n  of active or reactive power through the branch), \"I\" (the larger current of its two\n  ends), \"G\", \"B\", \"Y\" (conductance, susceptance, magnitude of the series admittance of\n  the branch), \"Ysvd\" (default: largest singular value of the admittance matrix of the\n  branch) or \"none\". The widths are on one scale from the smallest value to the 95th\n  percentile over all samples, so the top 5 % take the largest width.\n- `MarkerSizeMode`: \"none\" (default), \"P\", \"Q\" or \"S\" (|P|, |Q|, |P + jQ| of the\n  injection of a component, and of the sum of the components of a bus).\n- `BusHeightMode`: \"V\" (|V|), \"angle\" (angle of V), \"Vimag\" (imaginary part of V), \"P\",\n  \"Q\" (power injections) or \"none\". In 2D the height is the value. In 3D it is scaled\n  about the reference value (1 pu for \"V\", 0 for the others) so that the values of all\n  samples and the reference span a quarter of the drawing, and the heights are drawn\n  readable: a light floor with a grid below the lowest value of all samples, the\n  shadows of the bars, branches and links on it, a thin post from each bus down to it,\n  a translucent reference plane labeled with its value (\"|V| = 1\"), and a z axis with\n  the values and the quantity (\"|V| [pu]\", \"∠V [rad]\", \"Im V [pu]\", \"P [pu]\", \"Q\n  [pu]\"). The floor and the scale are the same at every sample (set_time), so the posts\n  compare across times. None of these can be clicked or has a data tip. \"none\" draws\n  none of them.\n- `LabelMode`: \"bus\" (default: the tags of the buses), \"tag\" (the tags of the buses and\n  components), \"value\" (the tags and the values: ∠V and |V| of a bus, P and Q of a\n  component, and the line \"<name>=<value>\" of its color value with the name and format\n  of the data tip, when it is finite; branches have no labels; when the color value of\n  a bus is |V| or ∠V (BusColorMode \"V\" or \"angle\", or ColorMode \"user\" with a\n  ColorbarLabel that starts with \"|V|\" or \"∠V\", spaces ignored), the label has only\n  that line and not the fixed \"|V|=\" or \"∠V=\" line, so |V| is written once), \"user\" (the texts set in\n  BusLabel and ComponentLabel are kept) or \"none\". With \"bus\", \"tag\" and \"value\" the\n  labels are written again at every sample; the \"value\" labels also follow\n  BusColorData, ComponentColorData, ColorbarLabel and ColorMode set from outside (e.g.\n  in a TimeChangedFcn), row by row for the color values. In 2D, labels that overlap are\n  moved apart vertically and the axes take them in. The labels are laid out again\n  whenever the limits or the pixel size of the axes change (a GUI setting the limits or\n  resizing its panels, a resized figure, a hidden tab shown): limits set from outside\n  then stay.\n- `TitleFormat`: with more than one sample, the title is sprintf(TitleFormat, t) at every\n  sample, with t the time of the sample shown (default \"t = %.2f s\"); for samples named\n  by the state (s_sampleName, sv_sampleText) the title is the text of the sample\n  instead. With \"\" the title is never written, so a title set by title(G.ax, ...) stays.\n- `ColorbarLabel`: label of the colorbar; it stays when the diagram is drawn again. With\n  \"\" (default) the label is the quantity of ColorMode: \"|I| [pu]\", \"P [pu]\", \"Q [pu]\" or\n  \"Loss [pu]\" (none for \"user\"). It is also the name of the color value in the data tips\n  and the \"value\" labels (\"color\" when there is none).\n\nA title set by title(G.ax, ...) also stays when the diagram is drawn again (Dimension,\nset_position, set_data, or in 3D BusHeightMode and LinkWidth). The colorbar is shown\nonly when an element has a color value (none for the topology). The axes fit the\ndrawing (and in 2D its labels) with a padding of 3% of its larger side.\n\nThe elements of tab_element are the buses (kind \"bus\"), the components (\"component\",\ntheir full tags), the branches (\"branch\") and the links (\"link\", the tag of their\ncomponent). set_style sets Color of every kind, Label and MarkerSize of buses and\ncomponents and LineWidth of branches. A color set by Color (the vectors BusColor,\nComponentColor, BranchColor and LinkColor, NaN rows: none) stays over the color of the\ncolor data and of ColorMode at every sample. A size set by MarkerSize or LineWidth (the\nvectors BusMarkerSize, ComponentMarkerSize and BranchLineWidth in pt, NaN rows: none)\nstays over the size of MarkerSizeMode and the width of BranchWidthMode, without being\nmapped onto the range. These vectors change the graphics objects that are drawn and\nnever draw the diagram again. A click on an element (or its data tip in the data cursor\nmode) raises ElementClicked; a selected element is marked by a ring or a wide line in\nSelectionColor. The callbacks of the graphics objects hold the diagram by a weak\nreference, so a saved figure (savefig, a Live Editor output) does not save the diagram.\n\nset_data takes the state; with the extra field sct_network (a new snapshot) it also sets\nthe network again, keeping the positions, appearance and selection of the elements by\ntag (net.plot_diagram(Graph=G) uses it). A state of NaN draws the topology only: the\nhover shows tags and parameters, and the arrows are hidden.",
      "SeeAlso": [
        "GraphBase",
        "PowerNetwork.plot_diagram",
        "ResultPF.plot_diagram",
        "ResultODE.plot_diagram"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.initialize();\nG = net.plot_diagram();\nG.ColorMode = \"P\";\nG.BusColorMode = \"V\";                   % the buses by |V| (it takes the colorbar)\nG.BusColorMode = \"none\";                % the branches by P again\nG.BusHeightMode = \"V\";\nG.MarkerSizeMode = \"P\";\nG.BranchWidthRange = [0.5 6];\nG.LabelMode = \"value\";\nG.ColorLimits = [0 2];                  % fixed; [NaN NaN] is automatic again\nG.FlowMode = \"Q\";\nG.FlowSpeed = 2;\nG.Dimension = \"3D\";\nG.set_style(\"B001\", Color=\"r\");\nG.set_position(\"B001\", [0.1, 0.9]);\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 75,
        "Total": 89
      },
      "MethodCount": {
        "Own": 53,
        "Total": 79
      },
      "path": "./database/GUILDAsystem/GraphNetDiagram.js",
      "Image": ""
    },
    {
      "Name": "GraphSpring2D",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "GraphSpringBase",
      "Superclasses": [
        "GraphSpringBase"
      ],
      "Ancestors": [
        "GraphSpringBase",
        "GraphBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphSpring2D/GraphSpring2D.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Spring-mass picture of a power system on the phasor plane.",
      "Desc": "Each node is drawn at its phasor (Re V, Im V) over a polar grid up to RMax: the buses\nand the own nodes of components, joined by coil springs (branches and the reactances\nto the own nodes) whose loops have the same small radius SpringAmplitude (0.02 pu) on\nevery spring. At each arrow node the active power P points along the tangent\n(counterclockwise for P > 0) and the reactive-current magnitude Iq along the radius.\nDashed circles of radius |E| mark the nodes whose |E| is constant. Value labels are\npushed apart when they overlap. The radius labels lie on the 165 degree ray, between the\nangle labels. The tick labels of the grid are thinned out so that none overlaps another\n(angle labels every 30, 60 or 90 degrees, then the radius labels from the outermost), and\na label that touches a node, a spring or an arrow of the sample is hidden. They lie below\nthe data and are chosen again when the axes change size, limits or font size and at each\nsample; a tick label hidden by the user stays hidden. ShowTickLabel = false hides all of\nthem (e.g. for a picture whose grid only shows the scale). See GraphSpringBase for the\ndata and the common properties and methods.",
      "SeeAlso": [
        "GraphBase",
        "GraphSpringBase",
        "GraphSpring3D"
      ],
      "Examples": "```matlab\nG = GraphSpring2D(sct_data);                 % sct_data: see GraphSpringBase\nG.RotationScale = 0;                         % remove the common rotation\nG.animate(Speed=0.5);\nG.export_video(\"swing.mp4\");\nG.set_style(\"B001\", Color=\"r\", MarkerSize=20);\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 2,
        "Total": 34
      },
      "MethodCount": {
        "Own": 4,
        "Total": 39
      },
      "path": "./database/GUILDAsystem/GraphSpring2D.js",
      "Image": ""
    },
    {
      "Name": "GraphSpring3D",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "GraphSpringBase",
      "Superclasses": [
        "GraphSpringBase"
      ],
      "Ancestors": [
        "GraphSpringBase",
        "GraphBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphSpring3D/GraphSpring3D.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Spring-mass picture of a power system on the surface z = log|V|.",
      "Desc": "Each node with phasor $V = |V| e^{j\\theta}$ sits at\n$(|V|\\cos\\theta, |V|\\sin\\theta, \\log|V|)$ on a translucent surface of revolution that\nruns from RMin to RMax, with contour circles of constant |V|, a polar grid on the floor\nand a pillar on the z axis. |V| below RMin is drawn at RMin (a bus at |V| = 0 sits at\nthe bottom) and |V| above RMax at RMax. Rods join the axis to the component nodes, 3D\ncoils join the nodes, and the nodes are spheres (cones for the marker \"v\"). At each\narrow node the active power P points along the circle of constant |V| and the\nreactive-current magnitude Iq along the surface away from the axis. Dashed circles of\nradius |E| lie on the surface. Nothing is drawn outside the axes: an arrow whose tip\nwould leave them is shortened along its direction, and what still sticks out (half of\na node at the bottom, a coil at a face) is pressed onto the faces of the box. The\ncamera is fixed so that the picture keeps its size for any azimuth. See GraphSpringBase\nfor the data and the common properties\nand methods. show_controls adds SurfaceAlpha (View) to the controls of GraphSpringBase.\n\nDefaults that differ from GraphSpring2D: ShowLabel and ShowValue are false,\nSpringTurns is 1/0.09 turns per pu of length and the coil radius SpringAmplitude is\n0.013 pu (0.02 pu in 2D).",
      "SeeAlso": [
        "GraphBase",
        "GraphSpringBase",
        "GraphSpring2D"
      ],
      "Examples": "```matlab\nG = GraphSpring3D(sct_data, View=[-30 40]);   % sct_data: see GraphSpringBase\nG.set_time(2.5);\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 5,
        "Total": 37
      },
      "MethodCount": {
        "Own": 5,
        "Total": 39
      },
      "path": "./database/GUILDAsystem/GraphSpring3D.js",
      "Image": ""
    },
    {
      "Name": "GraphSpringBase",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "GraphBase",
      "Superclasses": [
        "GraphBase"
      ],
      "Ancestors": [
        "GraphBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [
        "GraphSpring2D",
        "GraphSpring3D"
      ],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphSpringBase/GraphSpringBase.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Abstract base class of the spring-mass pictures of a power system (GraphSpring2D, GraphSpring3D).",
      "Desc": "The nodes are voltage phasors: the buses, and the own nodes of components such as the\ninternal voltage E' of a synchronous machine. The springs are the branches and the\nreactances between a bus and the own node of its component. At chosen nodes a pair of\narrows shows the active power P (tangential) and the reactive-current magnitude Iq\n(radial). GraphSpring2D draws the phasor plane and GraphSpring3D puts the nodes on the\nsurface z = log|V|.\n\nThe constructor of a subclass takes the data as a struct (one sample for a picture,\nseveral for an animation):\n\n- `rv_t` (1 x n_t) [s]: times (or the values of other samples, e.g. the steps of a\n  continuation power flow, with s_sampleName).\n- `sv_node` (n_node x 1): node tags; `sv_kind` (n_node x 1): \"bus\" or \"component\".\n- `cm_V` (n_node x n_t) [pu]: node phasors over time.\n- `im_edge` (2 x n_edge): node indices of each spring; `sv_edge` (n_edge x 1): their\n  tags (optional).\n- `iv_arrow` (n_arrow x 1): the node of each arrow pair; `rm_P`, `rm_Iq`\n  (n_arrow x n_t) [pu]: active power and reactive-current magnitude (optional).\n- `sv_marker` (MATLAB marker; \"v\" is a cone in 3D, other markers are spheres),\n  `rv_size` (NaN: default of the kind), `sv_color` (\"\": default of the kind; a color\n  name or \"#RRGGBB\") and `rv_circle` [pu] (radius of a dashed |E| circle; NaN: none;\n  hidden at the samples where the phasor of its node is NaN), n_node x 1 each (optional).\n- `s_sampleName`, `sv_sampleText` (optional): the name of the samples (e.g. \"Step\") and\n  the text of each sample (1 x n_t), shown in the title and in the playback bar instead\n  of the time (see GraphBase).\n\nThe appearance fields set the initial values of the vector properties NodeMarker,\nNodeSize and NodeColor; after that the vector properties are the appearance (sct_data\nkeeps the other fields). The elements of tab_element are the nodes (kind \"node\", tag\nsv_node), the springs (\"edge\", tag sv_edge; \"E1\", \"E2\", ... when not given) and the\narrow pairs (\"arrow\", the tag of their node). set_style sets Color, Label, Marker,\nMarkerSize and Visible of a node and Color, LineWidth and Visible of a spring; the\narrows have no options. The positions are the phasors: set_position and get_layout are errors. A\nclick on a node or a spring raises ElementClicked; a selected node gets a ring and a\nselected spring a wide line in SelectionColor.\n\nThe common rotation of the buses is removed by `RotationScale`: the angle reference at\nsample k is $\\bar\\theta_1 + (1-s)(\\bar\\theta_k - \\bar\\theta_1)$, where\n$\\bar\\theta_k$ is the mean of the unwrapped bus angles and s is RotationScale. s = 1\nkeeps the actual rotation (only the initial mean is removed), s = 0 removes it at every\nsample. Changing a property redraws the current sample.\n\nshow_controls shows ShowLabel, ShowValue and ShowLegend (Label), RotationScale,\nArrowScaleP and ArrowScaleQ (View); with two or more samples the time is in the\nplayback bar below the axes (see GraphBase).\n\nThe coils of the springs have the radius SpringAmplitude in pu, the same on every spring\nwhatever its length; a spring shorter than SpringAmplitude/0.06 gets a radius of 6 % of\nits length so that its loops do not overlap.",
      "SeeAlso": [
        "GraphBase",
        "GraphSpring2D",
        "GraphSpring3D",
        "PowerNetwork.plot_spring_model",
        "ResultODE.plot_spring_model",
        "ResultPF.plot_spring_model"
      ],
      "Examples": "```matlab\nsct.rv_t    = 0;\nsct.sv_node = [\"B1\"; \"B2\"; \"G1\"];\nsct.sv_kind = [\"bus\"; \"bus\"; \"component\"];\nsct.cm_V    = [1; 0.98*exp(-0.2j); 1.05*exp(0.3j)];\nsct.im_edge = [1 2; 1 3]';\nG = GraphSpring2D(sct);\nG.ArrowScaleP = 0.5;\nG.set_style(\"G1\", Color=\"r\", MarkerSize=20);   % the same as G.NodeColor(3, :) = [1 0 0] ...\n```\n\nThe data of a network or of an analysis result is assembled by\nPowerNetwork.plot_spring_model (the equilibrium), ResultODE.plot_spring_model (all\noutput times, for animate and export_video) and ResultPF.plot_spring_model (the buses).",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 18,
        "Total": 32
      },
      "MethodCount": {
        "Own": 10,
        "Total": 39
      },
      "path": "./database/GUILDAsystem/GraphSpringBase.js",
      "Image": ""
    },
    {
      "Name": "GraphTimeEventData",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "event.EventData, auxiliary",
      "Superclasses": [
        "event.EventData",
        "auxiliary"
      ],
      "Ancestors": [
        "event.EventData",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/GraphTimeEventData.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Data of the event TimeChanged of a graph: the sample it shows after set_time.",
      "Desc": "A graph (GraphBase) raises TimeChanged and calls its TimeChangedFcn as fcn(G, data) with\nthis object after set_time has drawn it (also when it moves with a linked graph, and at\nevery frame of animate and export_video). Time is G.rv_t(Index), the time of the sample\nshown, which is the sample nearest to the time asked for.",
      "SeeAlso": [
        "GraphBase",
        "GraphBase.set_time"
      ],
      "Examples": "```matlab\nG = res.plot_trajectory();\nG.TimeChangedFcn = @(G, data) title(G.ax(1), sprintf(\"t = %.2f s (sample %d)\", data.Time, data.Index));\naddlistener(G, \"TimeChanged\", @(G, data) disp(data.Time));\nG.set_time(1.0);\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 2,
        "Total": 2
      },
      "MethodCount": {
        "Own": 1,
        "Total": 2
      },
      "path": "./database/GUILDAsystem/GraphTimeEventData.js",
      "Image": ""
    },
    {
      "Name": "HistoryGUILDA",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/HistoryGUILDA.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Run log of a GUI: runs code strings in a private workspace and exports them as a script.",
      "Desc": "Every GUI action is a line of MATLAB code. run evaluates that code string itself, in a\nworkspace that belongs to this object, and records it as one entry of tab_entry. The code\nstring is the only source of the action, so get_script returns exactly what the GUI ran:\n\n- Variables assigned by the code stay in the workspace for the next runs\n  (`res_pf = net.calculate_powerflow();` makes `res_pf` available). set_variable and\n  get_variable read and write them from outside.\n- Entries are never removed: model edits accumulate. A failed entry stays in the log with\n  its error message but is left out of the script.\n- attach_view draws the log in a container of a uifigure: `[mark] Label → Detail` and the\n  `>> code` lines of each entry, redrawn on the event Changed. A double click on a `>>`\n  line opens the file of the method it calls when it can be found.\n\nThe code runs in a private function whose only variables are varargin and varargout: the\nworkspace variables are unpacked into it, the code is evaluated with evalc, and every\nvariable except varargin and varargout is packed back. So the code can use any variable\nname except varargin and varargout. A failed run does not change the workspace.",
      "SeeAlso": [
        "DrawerOptionDialog",
        "DrawerModelGUI"
      ],
      "Examples": "```matlab\nh = HistoryGUILDA(Header=\"Built in the GUI\");\nh.run(\"Model\", \"New network\", \"net = PowerNetwork();\");\nh.run(\"Model\", \"Add a bus\", \"net.add_bus();\");\ndisp(h.get_script())\nh.export_script(\"build_net.m\")\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 4,
        "Total": 4
      },
      "MethodCount": {
        "Own": 10,
        "Total": 11
      },
      "path": "./database/GUILDAsystem/HistoryGUILDA.js",
      "Image": ""
    },
    {
      "Name": "LayerPackage",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "other",
      "Model": "",
      "Parent": "handle",
      "Superclasses": [
        "handle"
      ],
      "Ancestors": [
        "handle"
      ],
      "Subclasses": [
        "Parameter",
        "PowerSystemModel",
        "Scenario"
      ],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/LayerPackage.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Abstract base class for layer hierarchy management in GUILDA.",
      "Desc": "It centralizes parent/children relationships, tag handling, and what is out of date:\neach layer keeps, per stale tag, the reasons it is stale; only PowerNetwork.initialize\nbrings the layers up to date, and the analyses check them. The network, buses,\nbranches, components, controllers (through PowerSystemModel), the scenarios and the\nParameter containers derive from it. `launch_gui` shows any layer (DrawerModelGUI) with the\npages of `gui_content`.\n\n`doc` (the class reference page) is a method of PowerSystemModel and auxiliary, not of\nLayerPackage: Parameter and Scenario inherit from both auxiliary and LayerPackage, so a\ndoc defined here too would make them fail with MATLAB:class:methodAmbiguous.\n\nStale state:\n\n- `sct_stale` holds one field per stale tag of the class, each a string column of\n  messages (why that part is out of date); an empty column means up to date. The\n  constructor of each class creates its own fields with the message \"initialize has\n  not been run\": PowerNetwork `powerflow` and `odefcn` (the network frequency);\n  Component, LocalController and GlobalController `equilibrium` and `odefcn`; Bus and\n  Branch have none. Each class appends to and clears only its own fields.\n- An edit calls `log_edit(log, tag)` on the edited layer (the owner for a Parameter\n  container), which calls the hook `handle_edit` with that layer on every layer from\n  there up to the top. The default does nothing; each class appends the message\n  (\"<tag of the edited layer>: <log>\", \"<container tag>/<owner tag>: <log>\" for a\n  parameter) to its own fields for the edits that make them stale.\n- Each analysis reads the stale tags it needs (the network, and the components and\n  controllers it uses) and stops with its own error (e.g. GUILDA:PowerNetwork:SimulateStale),\n  naming up to three different messages; it rebuilds nothing.\n- `sct_stale` has public GetAccess (Hidden) because the DebugScript tests, which are\n  scripts, read it.\n\nTags: `s_tag` identifies the layer within the layer structure. A tag must be a valid\nMATLAB variable name (isvarname: a letter first, then letters, digits and underscores, at\nmost namelengthmax characters, not a keyword), because tags name OPF constraints and\nstruct fields; any other tag stops with GUILDA:LayerPackage:InvalidTag. A tag that\nalready exists among the siblings is renamed with a number suffix (checked again). A\nrename is an edit with the tag \"Tag\", which makes nothing stale. Tags are permanent\nIDs, so the tags of existing child layers do not follow: after renaming bus B002 to BX,\nits component B002SG1 keeps its tag and a component added later is BXSG1.",
      "SeeAlso": [
        "PowerSystemModel",
        "Parameter"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.disp_tree();            % hierarchy of the layers below the network\nnet.a_Bus{1}.doc();         % class reference page of the first bus\nnet.a_Bus{1}.tab_parameter.powerflow.V = 1.02;\nnet.sct_stale               % powerflow: \"powerflow/B001: edit V: 1.06 -> 1.02\"\nnet.initialize();           % brings every layer up to date\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 6,
        "Total": 6
      },
      "MethodCount": {
        "Own": 12,
        "Total": 12
      },
      "path": "./database/GUILDAsystem/LayerPackage.js",
      "Image": ""
    },
    {
      "Name": "LocalController",
      "Origin": "System",
      "Folder": "_GUILDAsystem",
      "Category": "",
      "Type": "PowerSystemModel",
      "Model": "LocalController",
      "Parent": "PowerSystemModel",
      "Superclasses": [
        "PowerSystemModel"
      ],
      "Ancestors": [
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "controller.avr.abstract",
        "controller.avr.Static",
        "controller.governor.abstract",
        "controller.governor.Static",
        "controller.local_LQR",
        "controller.pss.abstract",
        "controller.pss.Retrofit"
      ],
      "Package": "",
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Abstract class of a controller attached to one component, such as an AVR, a PSS, a governor or an LQR.",
      "Desc": "A local controller is a dynamical system with state $x$, input $u$ and output $y$.\nIt observes the component it is attached to (directly, or through the controllers\nabove it) by the names of its input signals sv_u: a name in sv_y of the component reads that\noutput, otherwise a name in sv_x reads that state (an output is read when both have\nthe name). The reserved inputs \"Xall\" / \"Yall\" observe all the states / all the\noutputs. An input of the name of an output of a nested controller (e.g. Vpss) reads\nthat output; other inputs stay at the equilibrium. The output signals sv_y of the controller\ndrive the inputs of the same name of the component (or of the controller above it); an\ninput event or a global controller on such an input of the component adds to them.\nThe parent voltage V is available to it.\n\nRole in the model:\n\n- Owns its parameters, its equations (through its subclass), its equilibrium and at most\n  one nested controller (the PSS under an AVR). Its parent is a component, or the AVR\n  for a PSS. A PSS observes the same component as its AVR, and its output Vpss drives\n  the AVR input of that name.\n- Gives no current to the network (no `fcn_I`). It receives the parent voltage V in its\n  functions, but does not own the voltage or the frequency, and is not a child of the\n  bus.\n- Built and attached by `Component.add_local_controller` from its model key `key` (the\n  constructors of the concrete classes are accessible only from `Component`), which\n  sets `a_Component` (`SetAccess`), resolves the observed inputs and logs a \"Topology\"\n  edit, so a controller is always on a component of a network. A controller attaches\n  to one parent at a time. A removed or replaced controller is deleted.\n- Differs from `Component` on purpose: no `fcn_I`, the output function is `fcn_y`, and\n  the Jacobians are required. Inputs named X or Y are not allowed.\n- `resolve_observe` (called by `Component.add_local_controller` on attachment) expands\n  \"Xall\" / \"Yall\" (`sr_reserved`) and sets where each input sv_u(k) is read on the observed component: iv_obsY(k) is its\n  index in sv_y, iv_obsX(k) its index in sv_x, and both are 0 for an input that is not\n  observed (its equilibrium value, or the output of a nested controller of the same name).\n- The handles `f_*` @(t,x,V,u) bind param and omega0 (there is no f_I);\n  `set_odefcn` builds them, called by `initialize` when they are stale\n  (`sct_stale.odefcn`, or a network frequency other than `r_odefcnHz`).\n- Stale tags (`sct_stale`): `equilibrium` (its dynamics, a nested controller, its\n  attachment) and `odefcn` (its dynamics, its attachment). The component recomputes the\n  equilibria of its controllers when one of them is stale (Component.set_equilibrium\n  stores the outputs of their get_equilibrium), then calls `initialize(true)`, with\n  which each controller clears its own tag.\n\nSubclasses in the `controller` package define the static model functions (`fcn_dx`,\n`fcn_y`, `fcn_Mass`), their Jacobians and the variable names. A concrete class has a\nmodel key `key` (e.g. \"avr-ST1\"), with which `Component.add_local_controller` builds and\nattaches it, and a role `s_role` that says where it goes (an \"avr\" or \"local\"\ncontroller and a \"governor\" on the component, a \"pss\" under the AVR).\nThe two top-level controllers of a component drive different inputs.",
      "SeeAlso": [
        "Component.add_local_controller",
        "controller.avr.AVR_ST1",
        "controller.pss.PSS1",
        "controller.governor.IEEJ_LPT1",
        "controller.local_LQR"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\ngen = net.a_Bus{1}.a_Component{1};\navr = gen.add_local_controller(\"avr-ST1\");\npss = gen.add_local_controller(\"pss-PSS1\");   % the PSS is attached under the AVR\nnet.initialize();\navr.rv_Xequilibrium\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_Component",
          "Type": "Component"
        },
        {
          "Name": "a_LocalController",
          "Type": "LocalController"
        }
      ],
      "PropertyCount": {
        "Own": 25,
        "Total": 31
      },
      "MethodCount": {
        "Own": 26,
        "Total": 36
      },
      "path": "./database/GUILDAsystem/LocalController.js",
      "Image": "./database/images/LocalController.svg"
    },
    {
      "Name": "MethodBase",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [
        "MethodFsolve",
        "MethodGradient",
        "MethodLevenbergMarquardt",
        "MethodNewtonRaphson"
      ],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Abstract base class of the solvers of a nonlinear equation F(x) = 0.",
      "Desc": "MethodNewtonRaphson, MethodLevenbergMarquardt, MethodGradient and MethodFsolve inherit\nit. Give the equation and the options as Name-Value arguments of the constructor (the\npublic properties), then call solve. Each subclass sets its own defaults in its\nconstructor.\n\n- Convergence: the largest |F(x)| is at most `ConvTol` (MethodGradient: the largest\n  |r(x)|, see its help).\n- `solve` returns `[x, flag, output, rm_history, rv_step]`. flag is 1 converged, 0\n  `MaxIter` reached, -2 diverged or no solution. output has the fields iterations,\n  algorithm, residual (largest |F|) and message; the message is printed unless `Display`\n  is \"none\". flag -1: stopped by the live display of the power flow (PlotFcn).\n- When flag is 0 or -2 and the largest |F| is not finite or above 1e10 [pu]\n  (`r_diverged`), the message says that the iteration diverged.\n- Without `Jac`, the Jacobian is computed by central differences (tools.fd_jacobian)\n  with the step `Increment`.",
      "SeeAlso": [
        "MethodNewtonRaphson",
        "MethodLevenbergMarquardt",
        "MethodGradient",
        "MethodFsolve",
        "SolverPF"
      ],
      "Examples": "```matlab\nnrm = MethodNewtonRaphson(Fcn=@(x) [x(1)^2 + x(2) - 2; x(2)^3 - 1], InitVal=[0.5; 0.5]);\n[x, flag, output] = nrm.solve();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 9,
        "Total": 9
      },
      "MethodCount": {
        "Own": 6,
        "Total": 7
      },
      "path": "./database/GUILDAsystem/MethodBase.js",
      "Image": ""
    },
    {
      "Name": "MethodDynamic",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Power flow by virtual bus dynamics that settle at the solution (ode15s).",
      "Desc": "Each bus gets M*theta'' + D*theta' = dP and M*V'' + D*V' = dQ/V (the active power and\nreactive current mismatches); the slack angle and voltage and the PV voltages are fixed.\nPower-flow specific: it takes the bus admittance matrix and the power flow conditions of\nthe buses.\n\n- The integration stops when the largest |dP| (non-slack) and |dQ| (PQ) is at most\n  Tolerance (flag 1), on voltage collapse (a PQ voltage below 0.01 pu) or phase angle\n  instability (|theta| beyond 5 turns) (flag -2), or at the virtual time 1e4 (flag 0).\n  With flag 0 or -2 otherwise, a largest mismatch above 1e10 [pu] (MethodBase.r_diverged)\n  or not finite gives the message \"diverged\".\n  With Damper 1, the virtual time to converge is usually below 1000 and up to about\n  3500 near the loading limit.\n- The ODE tolerances follow Tolerance: AbsTol = min(Tolerance, 1e-5) and\n  RelTol = min(100*Tolerance, 1e-4).\n- The initial voltages are the columns Varg0, V0 of PFcondition when it has them, the\n  flat start otherwise (angle 0 and magnitude 1, the set V at PV and slack buses).\n- output: iterations (number of ODE steps), algorithm, residual (largest mismatch at the\n  end), message. flag -1: stopped by the live display of the power flow (PlotFcn).",
      "SeeAlso": [
        "SolverPF",
        "MethodGradient"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nY   = net.get_admittance_matrix().Variables;\ntab = tools.vcellfun(@(b) b.get_pf_condition, net.a_Bus);\n[cv_V, flag] = MethodDynamic(Y=Y, PFcondition=tab).solve();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 7,
        "Total": 7
      },
      "MethodCount": {
        "Own": 2,
        "Total": 3
      },
      "path": "./database/GUILDAsystem/MethodDynamic.js",
      "Image": ""
    },
    {
      "Name": "MethodFsolve",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "MethodBase",
      "Superclasses": [
        "MethodBase"
      ],
      "Ancestors": [
        "MethodBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodFsolve/MethodFsolve.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "fsolve solver of a nonlinear equation F(x) = 0 (needs Optimization Toolbox).",
      "Desc": "solve checks Optimization Toolbox first (tools.require_toolbox) and stops with\nGUILDA:require_toolbox:Unavailable without it. With Jac, fsolve uses that Jacobian\n(SpecifyObjectiveGradient); without it, the finite differences of fsolve.\n\n- ConvTol^2 is passed as FunctionTolerance (a tolerance on the sum of squares |F|^2) and\n  as OptimalityTolerance (on the first-order optimality |J'F|), MaxIter as MaxIterations\n  of fsolve; 0 for ConvTol, MaxIter or MaxFunEvals keeps the fsolve defaults.\n- flag: 1 when fsolve succeeded (exitflag > 0) and the largest |F| is at most ConvTol\n  (1e-6, the fsolve default FunctionTolerance, when ConvTol is 0); 0 when fsolve stopped\n  at MaxIterations or MaxFunctionEvaluations (exitflag 0); -2 otherwise.\n- output: the fields of MethodBase and exitflag (the exitflag of fsolve).",
      "SeeAlso": [
        "MethodBase",
        "SolverPF",
        "MethodNewtonRaphson"
      ],
      "Examples": "```matlab\nfs = MethodFsolve(Fcn=@(x) x.^2 - 4, Jac=@(x) diag(2*x), InitVal=1);\n[x, flag, output] = fs.solve();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 4,
        "Total": 13
      },
      "MethodCount": {
        "Own": 2,
        "Total": 7
      },
      "path": "./database/GUILDAsystem/MethodFsolve.js",
      "Image": ""
    },
    {
      "Name": "MethodGradient",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "MethodBase",
      "Superclasses": [
        "MethodBase"
      ],
      "Ancestors": [
        "MethodBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodGradient/MethodGradient.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Gradient iteration x = x + StepSize*d(x) that drives a mismatch to zero.",
      "Desc": "Fcn returns the step direction d(x) and, as an optional second output, the mismatch r(x)\nthat is tested for convergence (d(x) itself when there is no second output). The\niteration converges when max|r(x)| <= ConvTol; a non-finite d or r stops it as\ndiverged. Fcn may return NaN to mark a point outside its domain. The convergence is\nlinear: many cheap iterations instead of the few Jacobian solves of MethodNewtonRaphson.\n\nThe power flow (Solver=\"gradient\") uses it with x = [theta; V] of the buses,\nd = [dP; dQ./V] and r = [dP; dQ] (the slack values and the PV voltages kept fixed).",
      "SeeAlso": [
        "MethodBase",
        "SolverPF",
        "MethodNewtonRaphson"
      ],
      "Examples": "```matlab\nmg = MethodGradient(Fcn=@(x) [1; 2] - x, InitVal=[0; 0], StepSize=0.5);\n[x, flag] = mg.solve();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 10
      },
      "MethodCount": {
        "Own": 2,
        "Total": 7
      },
      "path": "./database/GUILDAsystem/MethodGradient.js",
      "Image": ""
    },
    {
      "Name": "MethodLevenbergMarquardt",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "MethodBase",
      "Superclasses": [
        "MethodBase"
      ],
      "Ancestors": [
        "MethodBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodLevenbergMarquardt/MethodLevenbergMarquardt.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Levenberg-Marquardt solver of a nonlinear equation F(x) = 0.",
      "Desc": "Each step solves (J'J + mu*I) dx = -J'F with the Jacobian J of Jac. A step that reduces\n|F| is taken and mu is divided by 10; otherwise mu is multiplied by 10 and the step is\ntried again. mu starts at 1e-6 times the largest column norm^2 of J, so near a regular\nsolution the steps are Newton steps. Converged when max|F(x)| <= ConvTol; when mu\nexceeds 1e20 without a decrease of |F| the iteration stops at a local minimum of |F|. Without Jac, the Jacobian is computed by\ncentral differences (see MethodBase).",
      "SeeAlso": [
        "MethodBase",
        "SolverPF",
        "MethodNewtonRaphson"
      ],
      "Examples": "```matlab\nlm = MethodLevenbergMarquardt(Fcn=@(x) x.^2 - 4, Jac=@(x) diag(2*x), InitVal=1);\n[x, flag] = lm.solve();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 9
      },
      "MethodCount": {
        "Own": 2,
        "Total": 7
      },
      "path": "./database/GUILDAsystem/MethodLevenbergMarquardt.js",
      "Image": ""
    },
    {
      "Name": "MethodNewtonRaphson",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "MethodBase",
      "Superclasses": [
        "MethodBase"
      ],
      "Ancestors": [
        "MethodBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodNewtonRaphson/MethodNewtonRaphson.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Newton-Raphson solver of a nonlinear equation F(x) = 0.",
      "Desc": "The power flow (Solver=\"newton\") uses it, and the continuation power flow uses it as its\ncorrector. Give the equation and the options as Name-Value arguments of the constructor\n(they are the public properties), then call solve (see MethodBase for the outputs).\nWithout Jac the Jacobian is computed by central differences with step Increment; giving\nJac is usually faster. Fcn may be a symbolic expression (needs Symbolic Math Toolbox);\nGUILDA itself always passes function handles.\n\n- Iterates x = x - StepSize * (J(x) \\ F(x)) until the largest |F(x)| is at most ConvTol.\n- A singular J(x) gives the minimum norm step (lsqminnorm) instead, without a warning.\n- flag -2: the largest |F(x)| is not finite or above 1e10 [pu] (MethodBase.r_diverged), or\n  x is not finite (diverged), or the step is at the rounding level of x\n  (at most 10*eps(max(1, max|x|))) while |F| > ConvTol (no solution, e.g. the minimum\n  norm steps of an island without a slack bus).\n- A call that does not take flag warns GUILDA:MethodNewtonRaphson:MaxIteration when\n  MaxIter is reached.",
      "SeeAlso": [
        "MethodBase",
        "SolverPF",
        "SolverCPF",
        "MethodLevenbergMarquardt"
      ],
      "Examples": "```matlab\nnrm = MethodNewtonRaphson(Fcn=@(x) [x(1)^2 + x(2) - 2; x(2)^3 - 1], InitVal=[0.5; 0.5]);\n[x, flag, output] = nrm.solve();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 10
      },
      "MethodCount": {
        "Own": 3,
        "Total": 8
      },
      "path": "./database/GUILDAsystem/MethodNewtonRaphson.js",
      "Image": ""
    },
    {
      "Name": "network.GUILDAlogo",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/GUILDAlogo.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Demonstration network whose diagram reads as the letters GUILDA.",
      "Desc": "It is not a real grid and has no published source: its buses carry diagram positions\n(X, Y) and its lines bend points (Path), so that plot_diagram draws the letters G, U, I,\nL, D and A, and the dispatch is chosen so that the branch currents spread over the whole\ncolormap. It is the network of the animation on the Home tab of the documentation site.\nIt has 44 buses, 49 branches (46 pi lines and 3 pi_transformer), 8 generators and 18\nloads; 60 Hz, 100 MVA base. It is built with add_bus, add_branch and add_component and\nis initialized by the constructor.\n\nLayout:\n\n- Buses 1-8 form G (an arc with its bar), 9-15 U, 16-22 I (with serifs), 23-27 L, 28-35\n  D and 36-42 A. Curves are bend points of the lines.\n- Ties join the letters (G-U at mid-height and at the bottom, U-I, I-L, L-D and D-A on\n  the baseline, D-A also from the bow of D to the crossbar of A), and a backbone of two\n  long lines runs below the letters from the bottom of G to L and on to the right foot of\n  A. With D (straight stroke and bow) and A (legs and crossbar), the network has 6\n  independent loops.\n- Buses 43 (left of G) and 44 (right of A) are generator buses behind step-up\n  transformers; the stem of I is a transformer too.\n\nModels:\n\n- Generators: gen-park at buses 43 (slack, V = 1.04), 17, 36 and 44, gen-1axis at buses\n  1 and 23, gen-2axis at buses 15 and 31, with the default controllers (Static AVR and\n  governor). Their data are row NGT2 of the generator parameter.csv on each machine\n  rating (100 to 500 MVA): the reactances divided and M and D multiplied by the rating.\n- Loads: load-impedance at 18 buses, P from 0.2 to 1.5 pu and Q = 0.3 P.\n- Lines: R about X/10 (X/20 for the backbone), X from 0.025 to 0.16 pu, C from 0.01\n  to 0.25 pu; transformers: X from 0.018 to 0.04 pu, tap 1.\n\nOperating point: the voltages are 0.957-1.040 pu, and the larger end current of the\nbranches spreads from 0.02 to 2.0 pu, close to evenly, so that the default\nColorMode \"I\" of plot_diagram shows the whole colormap. Linearization: one eigenvalue\nof get_sys(Type=\"ODE\") is 0 (the common rotor angle, as no bus voltage is fixed); all\nthe others have a negative real part. A three-phase fault of 50 ms on a bus settles.",
      "SeeAlso": [
        "network.Tutorial10bus",
        "network.IEEE14bus",
        "ResultPF.plot_diagram"
      ],
      "Examples": "Draw the power flow with the flow dots, and simulate a fault at bus 26:\n\n```matlab\nnet = network.GUILDAlogo();\nres = net.calculate_powerflow();\nG   = res.plot_diagram(LabelMode=\"none\", BranchWidthMode=\"I\");\nsc  = net.add_scenario(\"fault\", Time=[0, 10]);\nsc.add_fault(\"B026\", [1, 1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 20
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.GUILDAlogo.js",
      "Image": ""
    },
    {
      "Name": "network.IEEE14bus",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEE14bus/IEEE14bus.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEE 14-bus test system (MATPOWER case14).",
      "Desc": "The IEEE 14-bus system represents a part of the American Electric Power\nSystem and is a standard test case for power flow, stability and\ncontingency analysis. It has 14 buses, 20 branches (16 lines and 4\ntransformers in case14), 5 generators and 12 loads on a 100 MVA base.\n\nBus types:\n\n- Slack bus: bus 1\n- PV buses: buses 2, 3, 6 and 8\n- PQ buses: the other buses\n\nData:\n\nThe power-flow and OPF data are those of MATPOWER case14: line constants\n(`C = b/2` at each end), transformer taps, loads, the bus shunt, bus voltage\nlimits 0.94-1.06, generator limits and the gencost (`HP = c2*100^2`,\n`fP = c1*100`). GUILDA-specific choices:\n\n- Every generator (the compensators at buses 3, 6 and 8 too) is a gen-park\n  model with the same dynamic parameters; case14 has no dynamic data.\n- Bus 7 has a load with zero power, so a load can be changed there.\n- Loads have no OPF cost (`HP = fP = 0`); a fixed load's cost would only add a constant.\n- Branch 7-9 (a transformer winding in case14, tap 1) is a pi line.\n\nDiagram:\n\n```\n                          LL             LL\n                          |              |\n                (13) ===========       ===== (14)\n                      |   |   |         | |\n            LL        |   |   └---------┘ └------------┐\n            |         |   |                            |\n     (12) =====       |   |        LL      LL          |\n           | |        |   |        |       |           |\n           | └--------┘   | (11) =====   ===== (10)    |\n           |              |       | |     | |          |\n           └----------┐   |   ┌---┘ └-----┘ └-----┐    |\n                      |   |   |                   |    |   ┌-- LL\n                      |   |   |                   |    |   |\n                     =========== (6)       (9) ==============\n                      |   |   |                 |   |      | ┌-----------┐\n                      SC  |   LL               ///  |      | |           |\n                         ~~~                       ~~~    ~~~~~ (7)     === (8)\n                          |                         |       |            |\n  SG               LL --┐ |                         |       |            SC\n  |                     | |                     ============== (4)\n===== (1)              ======= (5)               |  |  |    |\n | |                    | | |                    |  |  |    LL\n | └--------------------┘ | └--------------------┘  |  |\n └----------┐  ┌----------┘                         |  |\n            |  |  ┌---------------------------------┘  |\n            |  |  |                                    |\n            |  |  |                       ┌------------┘\n           ========= (2)                  |\n            |  |  |                       |\n            SG LL |                       |\n                  └-------------------┐   |\n                                      |   |\n                                      |   |\n                                     ======= (3)\n                                      |   |\n                                      SC  LL\n\n\n< symbol >       < name >\n  --, | :   Transmission Line\n   ~~~  :   Transformer\n   SG   :   Synchronous Generator\n   SC   :   Synchronous Compensator\n   LL   :   Load\n   ===  :   Bus\n   (.)  :   Bus Number\n   ///  :   Shunt (bus)\n```",
      "SeeAlso": [
        "network.IEEE14bus_NoTap",
        "network.IEEE14bus_lossless",
        "PowerNetwork.import_matpower"
      ],
      "Examples": "Run the power flow and simulate a fault at bus 8:\n\n```matlab\nnet = network.IEEE14bus();\nres = net.calculate_powerflow();\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B008\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "- R. D. Zimmerman, C. E. Murillo-Sánchez, and R. J. Thomas, \"MATPOWER: Steady-state\n  operations, planning, and analysis tools for power systems research and education,\"\n  *IEEE Trans. Power Syst.*, vol. 26, no. 1, pp. 12–19, 2011, doi:\n  [10.1109/TPWRS.2010.2051168](https://doi.org/10.1109/TPWRS.2010.2051168).\n- University of Washington, \"Power Systems Test Case Archive: 14 bus power flow test\n  case,\" [https://labs.ece.uw.edu/pstca/](https://labs.ece.uw.edu/pstca/) (accessed\n  2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEE14bus.js",
      "Image": ""
    },
    {
      "Name": "network.IEEE14bus_lossless",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEE14bus_lossless/IEEE14bus_lossless.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEE 14-bus test system (MATPOWER case14) without branch resistance.",
      "Desc": "The IEEE 14-bus system represents a part of the American Electric Power\nSystem and is a standard test case for power flow, stability and\ncontingency analysis. It has 14 buses, 20 branches (16 lines and 4\ntransformers in case14), 5 generators and 12 loads on a 100 MVA base.\n\nBus types:\n\n- Slack bus: bus 1\n- PV buses: buses 2, 3, 6 and 8\n- PQ buses: the other buses\n\nData:\n\nThe data are those of network.IEEE14bus with the resistance `R` of every\nbranch set to 0, so the network has no real-power loss. The other data are\nkept on purpose:\n\n- Line charging `C` and the bus shunt (bus 9, `Bshunt = 0.19`) stay; they are\n  pure susceptances and take no real power. Every bus has `Gshunt = 0`.\n- The transformer taps (4-7, 4-9, 5-6) stay.\n- Bus voltages, loads, generator limits and costs are those of network.IEEE14bus.\n\nWith these data the generator outputs sum exactly to the loads.\n\nDiagram:\n\n```\n                          LL             LL\n                          |              |\n                (13) ===========       ===== (14)\n                      |   |   |         | |\n            LL        |   |   └---------┘ └------------┐\n            |         |   |                            |\n     (12) =====       |   |        LL      LL          |\n           | |        |   |        |       |           |\n           | └--------┘   | (11) =====   ===== (10)    |\n           |              |       | |     | |          |\n           └----------┐   |   ┌---┘ └-----┘ └-----┐    |\n                      |   |   |                   |    |   ┌-- LL\n                      |   |   |                   |    |   |\n                     =========== (6)       (9) ==============\n                      |   |   |                 |   |      | ┌-----------┐\n                      SC  |   LL               ///  |      | |           |\n                         ~~~                       ~~~    ~~~~~ (7)     === (8)\n                          |                         |       |            |\n  SG               LL --┐ |                         |       |            SC\n  |                     | |                     ============== (4)\n===== (1)              ======= (5)               |  |  |    |\n | |                    | | |                    |  |  |    LL\n | └--------------------┘ | └--------------------┘  |  |\n └----------┐  ┌----------┘                         |  |\n            |  |  ┌---------------------------------┘  |\n            |  |  |                                    |\n            |  |  |                       ┌------------┘\n           ========= (2)                  |\n            |  |  |                       |\n            SG LL |                       |\n                  └-------------------┐   |\n                                      |   |\n                                      |   |\n                                     ======= (3)\n                                      |   |\n                                      SC  LL\n\n\n< symbol >       < name >\n  --, | :   Transmission Line\n   ~~~  :   Transformer\n   SG   :   Synchronous Generator\n   SC   :   Synchronous Compensator\n   LL   :   Load\n   ===  :   Bus\n   (.)  :   Bus Number\n   ///  :   Shunt (bus)\n```",
      "SeeAlso": [
        "network.IEEE14bus",
        "network.IEEE14bus_NoTap"
      ],
      "Examples": "Run the power flow and simulate a fault at bus 8:\n\n```matlab\nnet = network.IEEE14bus_lossless();\nres = net.calculate_powerflow();\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B008\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "- R. D. Zimmerman, C. E. Murillo-Sánchez, and R. J. Thomas, \"MATPOWER: Steady-state\n  operations, planning, and analysis tools for power systems research and education,\"\n  *IEEE Trans. Power Syst.*, vol. 26, no. 1, pp. 12–19, 2011, doi:\n  [10.1109/TPWRS.2010.2051168](https://doi.org/10.1109/TPWRS.2010.2051168).\n- University of Washington, \"Power Systems Test Case Archive: 14 bus power flow test\n  case,\" [https://labs.ece.uw.edu/pstca/](https://labs.ece.uw.edu/pstca/) (accessed\n  2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEE14bus_lossless.js",
      "Image": ""
    },
    {
      "Name": "network.IEEE14bus_NoTap",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEE14bus_NoTap/IEEE14bus_NoTap.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEE 14-bus test system (MATPOWER case14) with every transformer tap set to 1.",
      "Desc": "The IEEE 14-bus system represents a part of the American Electric Power\nSystem and is a standard test case for power flow, stability and\ncontingency analysis. It has 14 buses, 20 branches (16 lines and 4\ntransformers in case14), 5 generators and 12 loads on a 100 MVA base.\n\nBus types:\n\n- Slack bus: bus 1\n- PV buses: buses 2, 3, 6 and 8\n- PQ buses: the other buses\n\nData:\n\nThis is network.IEEE14bus with the transformers 4-7, 4-9 and 5-6 modeled at\ntap 1 (plain series impedance, phase 0). All other data are those of\nnetwork.IEEE14bus. For the full case14 data, including the off-nominal taps\n0.978, 0.969 and 0.932, use network.IEEE14bus.\n\nDiagram:\n\n```\n                          LL             LL\n                          |              |\n                (13) ===========       ===== (14)\n                      |   |   |         | |\n            LL        |   |   └---------┘ └------------┐\n            |         |   |                            |\n     (12) =====       |   |        LL      LL          |\n           | |        |   |        |       |           |\n           | └--------┘   | (11) =====   ===== (10)    |\n           |              |       | |     | |          |\n           └----------┐   |   ┌---┘ └-----┘ └-----┐    |\n                      |   |   |                   |    |   ┌-- LL\n                      |   |   |                   |    |   |\n                     =========== (6)       (9) ==============\n                      |   |   |                 |   |      | ┌-----------┐\n                      SC  |   LL               ///  |      | |           |\n                         ~~~                       ~~~    ~~~~~ (7)     === (8)\n                          |                         |       |            |\n  SG               LL --┐ |                         |       |            SC\n  |                     | |                     ============== (4)\n===== (1)              ======= (5)               |  |  |    |\n | |                    | | |                    |  |  |    LL\n | └--------------------┘ | └--------------------┘  |  |\n └----------┐  ┌----------┘                         |  |\n            |  |  ┌---------------------------------┘  |\n            |  |  |                                    |\n            |  |  |                       ┌------------┘\n           ========= (2)                  |\n            |  |  |                       |\n            SG LL |                       |\n                  └-------------------┐   |\n                                      |   |\n                                      |   |\n                                     ======= (3)\n                                      |   |\n                                      SC  LL\n\n\n< symbol >       < name >\n  --, | :   Transmission Line\n   ~~~  :   Transformer\n   SG   :   Synchronous Generator\n   SC   :   Synchronous Compensator\n   LL   :   Load\n   ===  :   Bus\n   (.)  :   Bus Number\n   ///  :   Shunt (bus)\n```",
      "SeeAlso": [
        "network.IEEE14bus",
        "network.IEEE14bus_lossless"
      ],
      "Examples": "Run the power flow and simulate a fault at bus 8:\n\n```matlab\nnet = network.IEEE14bus_NoTap();\nres = net.calculate_powerflow();\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B008\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "- R. D. Zimmerman, C. E. Murillo-Sánchez, and R. J. Thomas, \"MATPOWER: Steady-state\n  operations, planning, and analysis tools for power systems research and education,\"\n  *IEEE Trans. Power Syst.*, vol. 26, no. 1, pp. 12–19, 2011, doi:\n  [10.1109/TPWRS.2010.2051168](https://doi.org/10.1109/TPWRS.2010.2051168).\n- University of Washington, \"Power Systems Test Case Archive: 14 bus power flow test\n  case,\" [https://labs.ece.uw.edu/pstca/](https://labs.ece.uw.edu/pstca/) (accessed\n  2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEE14bus_NoTap.js",
      "Image": ""
    },
    {
      "Name": "network.IEEE39Bus",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEE39Bus/IEEE39Bus.m",
      "Line": 2,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEE 39-bus test system (New England 10-machine) without controllers.",
      "Desc": "The 39-bus, 10-machine New England system.\nIt has 39 buses, 46 branches (34 lines and 12 transformers), 10 generators and\n19 loads; 60 Hz.\n\nBus types:\n\n- Slack bus: bus 31\n- PV buses: bus 30 and buses 32 to 39\n- PQ buses: buses 1 to 29\n\nData:\n\n- Lines are pi lines with the line charging given at each end (`C = b/2`);\n  transformers are two_winding_transformer branches with `C = 0` and their tap.\n- Generators are gen-2axis models; `M = 2H` with `H` on the system base (the\n  frequency deviation `omega` of gen-2axis is in pu) and `D = 2`.\n- Loads are load-power models. The buses without a generator or a load have a\n  load-power model with `P = Q = 0`.\n- The diagram layout (net.plot_diagram) follows Figure 1 of I. Hiskens, \"IEEE PES\n  Task Force on Benchmark Systems for Stability Controls: Report on the 39-bus\n  system (New England Reduced Model)\", 2013. The loads with `P = Q = 0`, which the\n  figure does not show, are short stubs at free places of their buses.\n\nA constant-power load cannot be supplied at the low voltages of a bus fault, so\n`net.simulate` with `add_fault` stops at the start of the fault (no consistent\ninitial condition, GUILDA:SolverODE:InitialConditionFailed). For a fault, replace\nthe loads with load-impedance first (second example).",
      "SeeAlso": [
        "network.IEEE68bus",
        "network.IEEE9bus"
      ],
      "Examples": "```matlab\nnet = network.IEEE39Bus();\nres = net.calculate_powerflow();\n```\n```matlab\nnet = network.IEEE39Bus();\nfor b = 1:numel(net.a_Bus)\n    c = net.a_Bus{b}.a_Component;\n    for k = 1:numel(c)\n        if isa(c{k}, \"component.load.power\") && any(c{k}.tab_parameter.powerflow{1, [\"P\",\"Q\"]} ~= 0)\n            net.a_Bus{b}.replace_component(c{k}.s_tag, \"load-impedance\");\n        end\n    end\nend\nnet.initialize();\nsc = net.add_scenario(\"fault\");\nsc.add_fault(\"B016\", [1, 1.05]);\nres = net.simulate(\"fault\");\n```",
      "Citations": "- I. Hiskens, \"IEEE PES Task Force on Benchmark Systems for Stability Controls: Report\n  on the 39-bus system (New England Reduced Model),\" Tech. Rep., 2013,\n  [https://cmte.ieee.org/pes-psdp/?p=331](https://cmte.ieee.org/pes-psdp/?p=331).\n- T. Athay, R. Podmore, and S. Virmani, \"A practical method for the direct analysis of\n  transient stability,\" *IEEE Trans. Power App. Syst.*, vol. PAS-98, no. 2, pp. 573–584,\n  1979, doi: [10.1109/TPAS.1979.319407](https://doi.org/10.1109/TPAS.1979.319407).\n- M. A. Pai, *Energy Function Analysis for Power System Stability*. Boston, MA, USA:\n  Kluwer Academic, 1989, doi:\n  [10.1007/978-1-4613-1635-0](https://doi.org/10.1007/978-1-4613-1635-0).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 20
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEE39Bus.js",
      "Image": ""
    },
    {
      "Name": "network.IEEE68bus",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEE68bus/IEEE68bus.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEE 68-bus test system (NETS-NYPS 16-machine), with AVRs and PSSs on request.",
      "Desc": "The 68-bus, 16-machine reduced model of the New England Test System (NETS) and\nthe New York Power System (NYPS) with three neighbouring areas, from B. Pal and\nB. Chaudhuri, \"Robust Control in Power Systems\", Springer, 2005.\nIt is a standard benchmark for inter-area oscillations and wide-area control.\nIt has 68 buses, 83 branches (64 lines and 19 transformers), 16 generators and\n35 loads; 60 Hz, 100 MVA base.\n\nBus types:\n\n- Slack bus: bus 16\n- PV buses: buses 1 to 15\n- PQ buses: buses 17 to 68\n\nData:\n\nThe values are those of the v2 CSV files (kept in `archive/IEEE68bus`); only the\nformat is converted:\n\n- Branches with tap 0 in the v2 file are pi lines; the others are pi_transformer\n  branches with the v2 tap and phase. The line charging is given at each end\n  (`C = b/2`), as in the v2 files.\n- Generators are gen-1axis models with the v2 generator_1axis data (`M`, `D`, `Xd`,\n  `Xq`, `Xd_p`, `Td_p`), as network.build used them.\n- Loads are load-impedance models (constant impedance at the power-flow solution).\n- By default (`LocalController=false`) each generator keeps the Static AVR and governor\n  (`avr-static`, `gov-static`), which hold `Vfield` and `Pmech` at their equilibrium.\n  With `LocalController=true` each generator has an AVR and a PSS\n  (`local_controller/avr-ST1`, `local_controller/pss-PSS1`):\n  - The v2 AVR sadamoto2019 (`Ka`, `Te`) is controller.avr.AVR_ST1 with `kap = Ka`,\n    `tap = Te`, `ttr = 0` (no transducer lag) and `kst = tst = 0`.\n  - The AVRs have the limiter on (`Limiter = 1`) with `Vap_max = 5`, `Vap_min = -5`\n    [pu], which the v2 data does not have. +-5 pu is the field voltage limit of the\n    static exciters in the 68-bus data: generator 9 of the PST v3 `data16m.m`\n    (G. Rogers and J. Chow, Power System Toolbox), all 16 machines of the SNL PSTess\n    `data16m.m`, and the SEXS of generator 9 in the PSS/E dyr file of the IEEE PES\n    Task Force benchmark. The equilibrium field voltages (1.03 to 2.43 pu) are inside\n    the limits, so the equilibrium and the linearization do not depend on them.\n  - Setting `Limiter` to false on every AVR reproduces the v2/v3 results without\n    limits (see the examples).\n  - The v2 PSS (`Kpss`, `Tpss`, `TL1p`, `TL1`, `TL2p`, `TL2`) has the transfer function\n    `Kpss/Tpss * Tpss*s/(1+Tpss*s) * (1+TL1p*s)/(1+TL1*s) * (1+TL2p*s)/(1+TL2*s)`,\n    which is controller.pss.PSS1 with `kpss = Kpss/Tpss`, `tWS = Tpss`, `tn1 = TL1p`,\n    `td1 = TL1`, `tn2 = TL2p`, `td2 = TL2`.\n- The diagram layout (bus `X`, `Y`, `Shape`, `Length`, branch `Path`, `FromOffset`,\n  `ToOffset`, `Style` and component `DX`, `DY`, `Shape`, `Offset`) follows Figure 1 of\n  A. K. Singh and B. C. Pal, \"IEEE PES Task Force on Benchmark Systems for Stability\n  Controls: Report on the 68-Bus, 16-Machine, 5-Area System\", ver. 3.3, 2013. The figure\n  draws some double circuits as two lines and the branch 63-58 as a line from bus 64;\n  the layout draws each branch of this network once.\n- The v2 files have no voltage limits, base voltages or OPF data; these are the\n  GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost `HP = fP = 1` for\n  generators and 0 for loads).\n- `archive/IEEE68bus` also has data that network.build did not use (generator_park,\n  avr_IEEE_ST1, excitation); they are not part of this network.\n\nWith the Static AVRs and governors only (`LocalController=false`, the default) the\nequilibrium is unstable: one real eigenvalue is about +0.13 1/s. With the AVRs and PSSs\n(`LocalController=true`) it is stable; the largest real part apart from the zero mode\nof the common angle is about -0.0051 1/s.",
      "SeeAlso": [
        "controller.avr.AVR_ST1",
        "controller.pss.PSS1",
        "network.IEEE9bus"
      ],
      "Examples": "Run the power flow and simulate a fault at bus 1, with the AVRs and PSSs:\n\n```matlab\nnet = network.IEEE68bus(LocalController=true);\nres = net.calculate_powerflow();\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B001\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```\n\nSwitch the AVR limiters off to reproduce the v2/v3 results:\n\n```matlab\nnet = network.IEEE68bus(LocalController=true);\nfor i = 1:16\n    avr = net.a_Bus{i}.a_Component{1}.avr;\n    avr.tab_parameter.dynamics.Limiter = false;\nend\nnet.initialize();\n```",
      "Citations": "- B. Pal and B. Chaudhuri, *Robust Control in Power Systems*. New York, NY, USA:\n  Springer, 2005, doi: [10.1007/b136490](https://doi.org/10.1007/b136490).\n- A. K. Singh and B. C. Pal, \"IEEE PES Task Force on Benchmark Systems for Stability\n  Controls: Report on the 68-bus, 16-machine, 5-area system,\" ver. 3.3, Tech. Rep.,\n  2013, [https://cmte.ieee.org/pes-psdp/?p=331](https://cmte.ieee.org/pes-psdp/?p=331).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEE68bus.js",
      "Image": ""
    },
    {
      "Name": "network.IEEE9bus",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEE9bus/IEEE9bus.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEE 9-bus test system (WSCC 3-machine), with AVRs and PSSs on request.",
      "Desc": "The 9-bus, 3-machine system of the Western System Coordinating Council, as it\nwas used in the simulator that preceded GUILDA (network.IEEE9bus_past of\nGUILDA v2). It has 9 buses, 9 branches (6 lines and 3 transformers),\n3 generators and 3 loads; 60 Hz, 100 MVA base.\n\nBus types:\n\n- Slack bus: bus 1\n- PV buses: buses 2 and 3\n- PQ buses: the other buses\n\nData:\n\nThe values are those of the v2 CSV files (kept in `archive/IEEE9bus_past`); only\nthe format is converted:\n\n- Lines are pi lines and transformers pi_transformer branches (tap 1); the line\n  charging is given at each end (`C = b/2`), as in the v2 files.\n- Generators are gen-1axis models. Their `M`, `D` and reactances are the values of\n  the earlier simulator, not the textbook (Anderson & Fouad) machine data.\n- Loads are load-impedance models (constant impedance at the power-flow solution).\n- By default (`LocalController=false`) each generator keeps the Static AVR and governor\n  (`avr-static`, `gov-static`), which hold `Vfield` and `Pmech` at their equilibrium.\n  With `LocalController=true` each generator has an AVR and a PSS\n  (`local_controller/avr-ST1`, `local_controller/pss-PSS1`):\n  - The v2 AVR sadamoto2019 (`Ka`, `Te`) is controller.avr.AVR_ST1 with `kap = Ka`,\n    `tap = Te`, `ttr = 0` (no transducer lag), `kst = tst = 0` and no limits\n    (`Vap_max = Inf`, `Vap_min = -Inf`, `Limiter = 1`).\n  - The v2 PSS (`Kpss`, `Tpss`, `TL1p`, `TL1`, `TL2p`, `TL2`) has the transfer function\n    `Kpss/Tpss * Tpss*s/(1+Tpss*s) * (1+TL1p*s)/(1+TL1*s) * (1+TL2p*s)/(1+TL2*s)`,\n    which is controller.pss.PSS1 with `kpss = Kpss/Tpss`, `tWS = Tpss`, `tn1 = TL1p`,\n    `td1 = TL1`, `tn2 = TL2p`, `td2 = TL2`.\n- The v2 files have no voltage limits, base voltages or OPF data; these are the\n  GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost `HP = fP = 1` for\n  generators and 0 for loads).\n\nDiagram:\n\n```\n             (2)          (7)        (8)        (9)          (3)\n     SG ---=====--~~~--=======-----=====-----=======--~~~--=====--- SG\n                           |          |          |\n                           |          LL         |\n                           |                     |\n                       LL ===== (5)        (6) ===== LL\n                           |                     |\n                           └-------┐     ┌-------┘\n                                   |     |\n                                  ======== (4)\n                                      |\n                                     ~~~\n                                      |\n                                    ===== (1)\n                                      |\n                                      SG\n\n< symbol >       < name >\n  --, | :   Transmission Line\n   ~~~  :   Transformer\n   SG   :   Synchronous Generator\n   LL   :   Load\n   ===  :   Bus\n   (.)  :   Bus Number\n```",
      "SeeAlso": [
        "controller.avr.AVR_ST1",
        "controller.pss.PSS1",
        "network.IEEE68bus"
      ],
      "Examples": "Run the power flow and simulate a fault at bus 7:\n\n```matlab\nnet = network.IEEE9bus();      % Static AVRs and governors only\nres = net.calculate_powerflow();\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B007\", [1,1.05]);\nsol = net.simulate(\"fault\");\n\n% With the AVRs and PSSs\nnet = network.IEEE9bus(LocalController=true);\n```",
      "Citations": "- P. M. Anderson and A. A. Fouad, *Power System Control and Stability*, 2nd ed.\n  Piscataway, NJ, USA: IEEE Press / Wiley-Interscience, 2003, doi:\n  [10.1109/9780470545577](https://doi.org/10.1109/9780470545577).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEE9bus.js",
      "Image": ""
    },
    {
      "Name": "network.IEEJ_EAST10",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEJ_EAST10/IEEJ_EAST10.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEJ EAST 10-machine standard model, with a peak and a night power-flow section.",
      "Desc": "The EAST 10-machine model of the Institute of Electrical Engineers of Japan (IEEJ)\nfor the 50 Hz loop system, from the IEEJ report on standard power system models\n(http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html, section 4.2, tables 4.1\nto 4.3 and appendices 1 and 2) and its Y-method input data.\nIt has 47 buses, 100 branches (78 line circuits and 22 transformers), 10 generators\nand 12 loads; 50 Hz, 1000 MVA base. As in table 4.1, each circuit of a line is one\nbranch, and each transformer card is one branch.\n\nBus types:\n\n- Slack bus: bus 3 (peak), bus 6 (night)\n- PV buses: the other buses of 1 to 10\n- PQ buses: buses 11 to 47; buses 18, 19, 38 to 47 have loads\n\nData:\n\n- A line card has 2 circuits; each circuit is a branch.pi with the per-circuit `r`,\n  `x` and `C = y = Y/2` of the card. The circuits of the `k`-th line card (in the order\n  of the data) are the branches `EL(2k-1)` and `EL(2k)`, so one circuit can be opened\n  with a Scenario (add_open_branch). Parallel cards stay separate (for example cards 17 and 117 from bus\n  12 to 13 are EL013 to EL016). The bus voltages and angles are the same as with one\n  branch of `r/2`, `x/2`, `2*y` per card (difference below 1e-14).\n- A transformer card is a branch.pi_transformer with `tap = 1/t`, `t` being TAPR.\n- Every branch has `circuit = 1` (column `circuit` of `branch/parameter.csv`): a line\n  branch is one circuit, and a transformer is taken as one bank (the data give no bank\n  count).\n- Generators use the source PG and Vset; the PG of the slack bus and QG are not used.\n  `baseMVA` is the rating of table 4.2.\n- The generators are gen-park models. The source model LGT=4 has one damper in each\n  axis, the standard constants of appendix table 1.1 selected by NGT (2 thermal,\n  6 nuclear, 8 hydro), and no saturation data. The conversions are:\n  - `M` (machine MVA base) and all reactances are moved to the 1000 MVA system base\n    by `GMVA/1000`.\n  - The table gives short-circuit time constants; the open-circuit ones are\n    `Td_p = Td'*Xd/Xd'`, `Td_pp = Td''*Xd'/Xd''`, `Tq_pp = Tq''*Xq/Xq''`.\n  - `Xq_p = Xq` removes the q-axis transient circuit, which LGT=4 does not have: `Ed`\n    stays 0, and `Tq_p = 1` has no effect.\n  - `D = 0`: the DG field of the source is blank.\n  - The armature time constant `Ta` has no counterpart in gen-park and is not used.\n- By default (`LocalController=false`) every generator keeps the Static AVR and governor\n  (`avr-static`, `gov-static`), which hold `Vfield` and `Pmech` at their equilibrium.\n  `LocalController=true` adds the AVRs and governors below.\n- The AVR is the rotating-exciter model LAT=1 of appendix figure 1.1, as\n  controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`, `Vap_max = 100`,\n  `Vap_min = -100`, `tex = 0.02`, `aex1 = 0.01`, `aex2 = bex = 0`, `tst = 0.5`,\n  `kst = 0.1`. `Vap` is the output of the first lag, with its +-100 limit, and\n  `0.02*dVfld/dt = -0.01*Vfld + Vap` is the exciter `100/(1 + 2*s)`, so the linear part\n  is the same. The field voltage setting EFS/100 of the figure is part of `Vref` here.\n  The limit `0 <= EF <= 4` of LAT=1 is `Vfld_max = 4`, `Vfld_min = 0`. The equilibrium\n  field voltages are inside it (1.54 to 2.26 at peak, 1.40 to 2.21 at night).\n  `Limiter = 1` applies both limits; set it to false to ignore them.\n- The source's PSS variant LAT=102 is not part of the base case and is not included.\n- The governors are those of table 4.2 and appendix figure 1.2, in\n  `local_controller/gov-LPT1` and `local_controller/gov-LPT4`:\n  controller.governor.IEEJ_LPT1 for the thermal and nuclear machines (LPT=1) and\n  controller.governor.IEEJ_LPT4 for the hydro machines G3 and G5 (LPT=4), with the\n  constants of the figure. `Prate` is the rated MW of table 4.2 divided by 1000, and\n  `PLM` is 5, or -10 (load-limit operation) for G2 and G7. At night G3 and G5 are\n  pumping with locked governors (LPT=0), so they have the Static governor and constant\n  `Pmech`. `Governor=false` (with `LocalController=true`) gives every generator the Static\n  governor, and `LocalController=false` keeps the Static AVR and governor on every\n  generator, whatever `Governor` is.\n- Loads are load-ZIP models with the default parameters, which are the voltage\n  characteristic of the source model NLT=2: constant-current P (constant impedance below\n  0.7 pu) and constant-impedance Q. The frequency characteristics of NLT=2, 4 %/Hz (P)\n  and -2 %/Hz (Q), are not represented: the load power does not depend on the frequency.\n- The source has no bus coordinates, voltage limits, base voltages or OPF data; these\n  are the GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost\n  `HP = fP = 1` for generators and 0 for loads).\n\nComparison with the report:\n\n- The power flow matches figure 4.3 within one unit of the last printed digit for all\n  the values read from it (174 per section: bus voltages and angles, generator\n  outputs, loads and line flows), for example G3 at 5.632+j1.437 (peak) and G6 at\n  6.586+j1.866 (night); see `+PF/README.md` of each section folder below.\n- With the AVRs and governors (`LocalController=true`) both equilibria are stable: the largest\n  real part apart from the zero mode of the common angle is `-0.0086` (peak, real) and\n  `-0.061 +- 2.90i` (night). With the AVRs only (`Governor=false`) both are stable too,\n  apart from the zero modes of the common angle and frequency: `-0.064 +- 1.52i` (peak)\n  and `-0.084 +- 2.74i` (night). With the Static AVRs and governors only (`LocalController=false`,\n  the default) each section has an unstable real eigenvalue: `0.033` (peak) and `0.100`\n  (night).\n- The long-period oscillation is about 2.0 s (peak) and 2.2 s (night) with governors,\n  2.0 s and 2.3 s without; the report states about 2 s and 3 s for its model.\n- The verification against the report is in `_GUILDAverification/IEEJ_EAST10_peak/`\n  and `_GUILDAverification/IEEJ_EAST10_night/`, one folder per section: `+PF` compares\n  the input data with the Y-method data and the power flow with figure 4.3, and\n  `+TimeResponse` compares the dynamic parameters with the source and the fault cases\n  of table 4.3 (21 at peak, 23 at night) with the report. See the README.md of each\n  folder for the criterion and the measured agreement.",
      "SeeAlso": [
        "controller.avr.AVR_DC1",
        "controller.governor.IEEJ_LPT1",
        "controller.governor.IEEJ_LPT4",
        "component.generator.park",
        "network.IEEE68bus"
      ],
      "Examples": "Run the power flow of the night section, and simulate a fault at bus 36 at peak with the\nAVRs and governors:\n\n```matlab\nnet = network.IEEJ_EAST10(Section=\"night\");\nres = net.calculate_powerflow();\nnet = network.IEEJ_EAST10(LocalController=true);\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B036\", [1,1.07]);\nsol = net.simulate(\"fault\");\n```\n\nFault at bus 36 for 70 ms, then open one circuit of the line from bus 36 to 17\n(card 36) for good, with the AVRs and without governors:\n\n```matlab\nnet  = network.IEEJ_EAST10(LocalController=true, Governor=false);\nsc   = net.add_scenario(\"fault-open\", Time=[0,20]);\nsc.add_fault(\"B036\", [0,0.07]);\nsc.add_open_branch(\"EL065\", 0.07);\nsol  = net.simulate(\"fault-open\", Tolerance=1e-6, AbsoluteTolerance=1e-6);\n```",
      "Citations": "- 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,\n  電気学会技術報告 第754号, 1999.\n- 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,\n  [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)\n  (accessed 2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEJ_EAST10.js",
      "Image": ""
    },
    {
      "Name": "network.IEEJ_EAST30",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEJ_EAST30/IEEJ_EAST30.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEJ EAST 30-machine standard model (peak and night sections), exciters and governors on request.",
      "Desc": "The EAST 30-machine power system model of the Institute of Electrical Engineers of\nJapan (IEEJ), a reduction of the 50 Hz system with long-period swings, from the IEEJ\ntechnical report on standard power system models:\nhttp://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html (section 4.4, tables 4.6 to\n4.9, appendices 1 and 2). It has 107 buses, 191 branches (136 line circuits and 55\ntransformers), 30 generators and 31 loads; 50 Hz, 1000 MVA base. `Section` selects\nthe peak (daytime, heavy load) or the night (light load, pumping) power-flow section.\n\nBus types:\n\n- Slack bus: the bus tagged `B3010`\n- PV buses: the other 29 generator buses\n- PQ buses: the other 77 buses\n\nBuses:\n\nThe report numbers its nodes sparsely. The buses are numbered consecutively in the\norder of the data, and each bus tag is `B` + the node, so `B3104` is node 3104.\nGenerator nodes come first: buses 1 to 8 are nodes 2001 to 2008 and buses 9 to 30 are\nnodes 3001 to 3022. `bus/parameter.csv` lists the others.\n\nData:\n\nThe values come from the Y-method data cards of the report (format in its appendix 2).\nThe conversions are:\n\n- Lines (T cards): pi branches, one per circuit, with the card values `ZR`, `ZX` and\n  `C = YC`, where `YC = Y/2` is the charging at each end. Each card has two circuits.\n  These are reduced values, not the report's standard per-km values, and are not\n  normalized. The two circuits of a card are separate parallel branches.\n- Transformers (X cards): pi_transformer branches from `NF` to `NT` with `X = ZX`\n  (one bank on all cards), `R = C = 0` and `tap = 1/TAPR`. The report's 0.14 pu\n  transformer rule does not apply to this model.\n- Every branch has `circuit = 1` (column `circuit` of `branch/parameter.csv`): a line\n  branch is one circuit, and a transformer is one bank.\n- Shunts: `YC` of the N card is `Bshunt` (capacitors at peak, a reactor at night).\n- Loads: `P = -PL`, `Q = -QL`; negative `PL` of the data is kept.\n- Night section: nodes 3016 and 3020 pump with `PG`, `QG` given and no voltage. gen-park\n  buses are PV buses, so their `V` is the voltage at which the power flow gives `QG`.\n- Night section: the node data's `PG` of node 3015 is -0.65, and the slack and `QG`\n  values on the same cards fit -0.75. The report's pumping total (9,270 MW) and its\n  flow diagram agree with -0.65, which is kept; slack `P` is then 1.417 pu, not the\n  1.520 pu on the card.\n- The data have no bus coordinates, voltage limits or OPF data, and these are the\n  GUILDA defaults (`Vmin` 0.5, `Vmax` 1.5, `baseKV` 230, OPF cost `HP = fP = 1` for\n  generators and 0 for loads).\n\nGenerators:\n\nThe report uses LGT=4, a Park model with one damper on each axis, for all machines.\nThey are gen-park models on the system base (reactances times `1000/GMVA`,\n`M = MG*GMVA/1000`, where `MG` is `2H` on `GMVA`):\n\n- d axis: `Xd`, `Xd_p`, `Xd_pp`, with `Td_p = Td'*Xd/Xd'` and `Td_pp = Td''*Xd'/Xd''`\n  from the short-circuit constants, which are the values of the report's table 4.7.\n- q axis: LGT=4 has no `Xq'` or `Tq'`, so the `Xq'`, `Tq'`, `Tqo'` fields of G4 (some\n  filled, some zero) are not used. One q-axis circuit is obtained with `Xq_p = Xq`,\n  which removes the transient q-axis circuit: `Ed` stays 0 and `Tq_p` (1 s, not report\n  data) has no effect. `Tq_pp = Tq''*Xq/Xq''`.\n- `X_ls` is `XL` of G5. At node 2002 it exceeds `Xd''` and `Xq''` in the report too.\n- `D = 0`: the cards give no damping.\n\nExciters:\n\nBy default (`LocalController=false`) every generator keeps the Static AVR and governor\n(`avr-static`, `gov-static`), which hold `Vfield` and `Pmech` at their equilibrium.\n`LocalController=true` adds the rotating-exciter model LAT=1 (report figure A1.1(a)),\nused for all machines, as controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`,\n`Vap_max = 100`, `Vap_min = -100`, `tex = 0.02`, `aex1 = 0.01`, `aex2 = bex = 0`,\n`tst = 0.5`, `kst = 0.1`, `Vfld_max = 4`, `Vfld_min = 0`. The exciter gain\n`100/(1 + 2s)` of the figure is `1/(aex1 + tex*s)`, the first lag with its limit is the\namplifier, and `EF` is limited to 0 to 4 pu as in the figure. `EFS/100` of the figure\nis the steady amplifier output, which AVR_DC1 includes in `Vref`. The field voltages at\nthe equilibrium are 1.20 to 2.19 pu at peak and 1.19 to 2.12 pu at night.\n`Limiter = 1` applies both limits; set it to false to ignore them.\n\nGovernors:\n\n`Governor=true` (with `LocalController=true`) keeps the governor of each machine in\n`local_controller/gov-LPT1` and `local_controller/gov-LPT4`, from `LPT` of its G2 card: LPT=1 (report figure\nA1.2(a), thermal and nuclear) as controller.governor.IEEJ_LPT1 and LPT=4 (figure\nA1.2(c), hydro) as controller.governor.IEEJ_LPT4, with the constants of the figures.\n`Prate` is the rated MW of the G1 card over the 1000 MVA base and `PLM` the governor\nmargin of the G1 card: 5 % for the thermal units, -10 % (load-limit operation) for the\nnuclear units at nodes 2001, 2005, 3001, 3002 and 3017, and 0 for the hydro units.\n\n- Peak: 30 governors, LPT=1 at the 22 thermal and nuclear units and LPT=4 at the eight\n  hydro units (nodes 3012 to 3016 and 3018 to 3020).\n- Night: 22 governors (LPT=1). The eight hydro units all pump (negative `P`), and the\n  night cards give them `LPT = 0`, a locked governor, so they have the Static governor and\n  keep `Pmech` constant.\n\nNot represented (differences from the report):\n\n- The frequency characteristics of the load NLT=2, 4 %/Hz (`P`) and -2 %/Hz (`Q`). The\n  loads are load-ZIP models with the default parameters, which are the voltage\n  characteristic of NLT=2 (`P` constant current above 0.7 pu and constant impedance\n  below, `Q` constant impedance), and their power does not depend on the frequency.\n- The report's variants LAT=2 and LAT=102. PSS1 observes `omega`, not `-Pg`, so\n  it does not match the delta-P PSS of LAT=102.\n- Generator saturation.\n\nWith the exciters, with or without the governors, the equilibrium is stable: apart from\nthe zero eigenvalue of the common angle (and of the common frequency without the\ngovernors, as `D = 0`), the largest real parts are about -0.0086 1/s at peak and\n-0.094 1/s at night with the governors, and -0.11 1/s at peak and -0.12 1/s at night\nwithout them. With the Static AVRs and governors only (`LocalController=false`, the\ndefault), apart from the zero modes of the common angle and frequency, both equilibria\nare unstable. The peak one has a very slow unstable real mode, about +0.00056 1/s (a\ntime constant of about 30 min) in the angles and speeds of the machines, B3007SG1 and\nB2001SG1 most; the other real parts are -0.024 1/s or less. This mode lies close to\nthe zero modes and its eigenvalue is ill-conditioned (accurate to about 1e-4 1/s), but\nit is not a rounding error: it stays the same with a power-flow Tolerance of 1e-12, and\nthe linearized response along it grows at this rate. The night one has two unstable\nreal eigenvalues, about +0.073 and +0.039 1/s.\n\nVerification:\n\nThe comparisons with the report are in `_GUILDAverification/IEEJ_EAST30_peak/` and\n`_GUILDAverification/IEEJ_EAST30_night/` of the repository, one folder per section:\n`+PF/README.md` (network data, generator, exciter and governor constants, and the\npower flow against the flow diagram, fig. 4.17) and `+TimeResponse/README.md` (the\ntransient stability cases of table 4.9, 3LG-O faults), each with its data and script.",
      "SeeAlso": [
        "controller.avr.AVR_DC1",
        "controller.governor.IEEJ_LPT1",
        "controller.governor.IEEJ_LPT4",
        "component.generator.park",
        "network.IEEE68bus"
      ],
      "Examples": "Run the power flow of the night section with the exciters and governors, and simulate a fault at node 3105 cleared by\nopening both circuits of the line 3105-3104 (card 3104, branches `EL047` and `EL048`):\n\n```matlab\nnet = network.IEEJ_EAST30(Section=\"night\", LocalController=true);\nres = net.calculate_powerflow();\nsc  = net.add_scenario(\"fault-open\", Time=[0,10]);\nsc.add_fault(\"B3105\", [1,1.07]);\nsc.add_open_branch([\"EL047\";\"EL048\"], 1.07);\nsol = net.simulate(\"fault-open\");\n```",
      "Citations": "- 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,\n  電気学会技術報告 第754号, 1999.\n- 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,\n  [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)\n  (accessed 2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEJ_EAST30.js",
      "Image": ""
    },
    {
      "Name": "network.IEEJ_WEST10",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEJ_WEST10/IEEJ_WEST10.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEJ WEST 10-machine standard model, with rotating-exciter AVRs and governors on request.",
      "Desc": "The WEST 10-machine model of the standard power system models of the Institute of\nElectrical Engineers of Japan: a longitudinal 60 Hz, 500 kV system that shows the\nlong-period oscillations of the Japanese 60 Hz grid. It has 27 buses, 42 branches\n(32 lines and 10 transformers), 10 generators and 17 loads; 60 Hz, 1000 MVA base.\n`Section` selects the peak (daytime) or the night power-flow section; the generator\nratings and the transformer reactances differ between them.\n\nSource: IEEJ report on the standard models, section 4.3 and appendices 1 and 2,\nhttp://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html, and its input data in the\nformat of the Y-method program of CRIEPI.\n\nBus types (the bus tags `B001` to `B030` are the node numbers of the report; 10, 11\nand 20 do not exist):\n\n- Slack bus: `B030` (generator G10)\n- PV buses: `B021` to `B029` (generators, 1.03 pu), and `B001`, `B009`, `B012` to\n  `B019` (loads, 1.00 pu)\n- PQ buses: `B002` to `B008`\n\nData:\n\n- Lines are pi branches with the per-circuit `R`, `X` of the input data and `C = YC`\n  (the input data give the charging at each end, `YC = Y/2`). A card with two circuits\n  is two branches, named with `_1` and `_2` (e.g. `LINE20_1`, `LINE20_2`), so that one\n  circuit can be opened (Scenario.add_open_branch). The bus voltages and angles are the\n  same as with one branch of `R/2`, `X/2`, `2*C` per card (within 1e-14).\n- Transformers are pi_transformer branches with the input `X` (0.14 pu on the machine\n  rating), `R = 0`, `C = 0`, `tap = 1`, `phase = 0`.\n- Every branch has `circuit = 1` (column `circuit` of `branch/parameter.csv`): a line\n  branch is one circuit, and a transformer is taken as one bank (the data give no bank\n  count).\n- Generators have `P = PG`, `Q = NaN`, and the rating `baseMVA = GMVA` of the section.\n  Reactances and `M` (7 s) are converted from the machine rating to the system base:\n  `X*1000/GMVA`, `M*GMVA/1000`.\n- The buses with a set voltage and no generation hold it with the load (`Q = NaN`). The\n  report treats the reactive support in the same way, as the power factor of the load.\n- The report gives no bus limits or OPF data; these are the GUILDA defaults (`Vmin`\n  0.5, `Vmax` 1.5, OPF cost `HP = fP = 1` for generators and 0 for loads). `baseKV` is\n  500; the report gives no voltage for the generator buses, and the value is not used\n  in any calculation.\n\nGenerators (Y-method `LGT = 4`, standard constants `NGT = 2`, appendix table 1.1):\n\n- They are gen-park models. `LGT = 4` has a field circuit and one damper on each axis,\n  and the standard constants have no q-axis transient values. The q-axis transient\n  circuit of gen-park is removed with `Xq_p = Xq`, which keeps `Ed` at 0; `Tq_p = 1` is\n  not a report value and has no effect then. The q-axis damper is `Xq_pp` with `Tq_pp`.\n- The source gives short-circuit time constants; gen-park uses open-circuit ones:\n  `Td_p = Td'*Xd/Xd'` and `Td_pp = Td''*Xd'/Xd''` (the usual approximations), and\n  `Tq_pp = Tq''*Xq/Xq''`, which is exact for the single q-axis circuit left with\n  `Xq_p = Xq` (`Xq'/Xq''` is the same factor).\n- `D = 0`: the `DG` field of the input data is blank.\n- The armature time constant `Ta` (0.40 s) is not used: GUILDA has no stator transients.\n  The input data have no saturation.\n\nLocal controllers (`LocalController=true`; with false, the default, every generator keeps\nthe Static AVR and governor, `avr-static` and `gov-static`):\n\n- AVRs (Y-method `LAT = 1`, appendix figure 1.1 (a), `local_controller/avr-DC1`): the block\n  diagram is controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2` and the limit\n  `Vap_max = 100`, `Vap_min = -100` on the first lag, then `tex = 0.02`, `aex1 = 0.01`,\n  `aex2 = bex = 0`, which is the source's `100/(1 + 2s)`, the field voltage limit\n  `Vfld_max = 4`, `Vfld_min = 0`, and `kst = 0.1`, `tst = 0.5`. `Vref` takes the place of\n  the field setting `EFS`. The equilibrium field voltages are 2.10 (peak) and 1.64 to\n  1.97 (night). `Limiter = 1` applies both limits; set it to false to ignore them.\n- Governors (`Governor=true`, `local_controller/gov-LPT1`): every generator has `LPT = 1`\n  with the standard constants (appendix figure 1.2 (a)), which is\n  controller.governor.IEEJ_LPT1 with its default constants, `Prate` = the rated output\n  of the input data (0.9 of `GMVA`) / 1000 MVA, and `PLM` = 5 % at peak and 3 % at\n  night. At peak the machines run at their rated output except G10 (servo position\n  0.9975), so the margin of 5 % reaches the servo limit 1.05.\n\nDifferences from the report:\n\n- Loads are load-ZIP models with the default parameters, which are the voltage\n  characteristic of the report's load (`NLT = 2`): constant-current `P`, changing to\n  constant impedance below 0.7 pu, and constant-impedance `Q`. The frequency\n  characteristic of `NLT = 2`, 3.33 %/Hz for `P`, is not represented: the load power\n  does not depend on the frequency.\n\nComparison with the report:\n\n- The power flow matches the flow diagrams of figure 4.10 within one unit of the last\n  printed digit (bus voltages and angles, generator outputs, slack power, load\n  reactive power and line flows), except two values that look like misprints of the\n  figure: at peak the flow from bus 2 to 3 is printed 1.428 (GUILDA 1.4824), and at\n  night G7 is printed 3.600+j1.472 while the Y-method data give PG = 3.00 (GUILDA\n  3.000+j1.427). See `+PF/README.md` of each section folder below.\n- Without governors the equilibrium is stable with the AVRs (largest real part -0.14 at\n  peak and -0.091 at night, apart from the zero modes of the common angle and\n  frequency) and unstable without them (`LocalController=false`, the default: the Static AVRs and\n  governors only) at peak (real part 0.069); the night one is then stable (largest real\n  part -0.025). With the governors\n  the least damped modes are of 1.5 s at peak, which is slightly unstable (real part\n  +0.0011), and of 2.1 s at night, with almost no damping (real part -0.0009). The\n  slowest swing modes are of 2.5 s (peak) and 2.1 s (night) with governors, and 2.9 s\n  and 2.3 s without. The report gives periods of about 3 s (peak) and 2.5 s (night).\n- The verification against the report is in `_GUILDAverification/IEEJ_WEST10_peak/`\n  and `_GUILDAverification/IEEJ_WEST10_night/`, one folder per section: `+PF` compares\n  the input data with the Y-method data and the power flow with figure 4.10, and\n  `+TimeResponse` compares the dynamic parameters with the source and the transient\n  stability cases of table 4.5 (13 per section) with the report. See the README.md of\n  each folder for the criterion and the latest agreement.\n  The report states that its case C at peak is stable with `NLT = 2` and not with\n  constant-impedance loads; here it is out of step with the load-ZIP loads too.\n\nSimulation: runs without an event stay at the equilibrium (both sections, with and\nwithout governors, over 60 s), and a fault at `B003` at peak completes with the default\nsettings and with `Tolerance` 1e-6 and `AbsoluteTolerance` 1e-8. Out-of-step runs can\nstop the solver (flag -1) once the angles are large.",
      "SeeAlso": [
        "controller.avr.AVR_DC1",
        "controller.governor.IEEJ_LPT1",
        "component.generator.park",
        "Scenario"
      ],
      "Examples": "Run the power flow of the night section and simulate case E of table 4.5 (with the AVRs\nand governors): a fault at\nbus 4 for 70 ms, then one circuit of line 50 opened for good:\n\n```matlab\nnet   = network.IEEJ_WEST10(Section=\"night\", LocalController=true);\nres   = net.calculate_powerflow();\nsc    = net.add_scenario(\"fault-open\", Time=[0,20]);\nsc.add_fault(\"B004\", [0.1,0.17]);\nsc.add_open_branch(\"LINE50_1\", 0.17);\nsol   = net.simulate(\"fault-open\");\n```",
      "Citations": "- 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,\n  電気学会技術報告 第754号, 1999.\n- 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,\n  [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)\n  (accessed 2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEJ_WEST10.js",
      "Image": ""
    },
    {
      "Name": "network.IEEJ_WEST30",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@IEEJ_WEST30/IEEJ_WEST30.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "IEEJ WEST 30-machine standard power system model, with AVRs and governors on request.",
      "Desc": "The WEST 30-machine model of the Institute of Electrical Engineers of Japan (IEEJ),\nsection 4.5 of the report at http://www2.iee.or.jp/~pes/model/kikan/kikan_mokuji.html\nIt is a longitudinal 60 Hz system with long-period oscillations, reduced from a real\nsystem. It has 115 buses, 129 branches (99 lines and 30 transformers), 30 generators\nand two power-flow sections, peak and night; 1000 MVA base.\n\nBus types:\n\n- Slack bus: bus 15 (node 3150)\n- PV buses: the other generator buses, buses 1 to 30\n- PQ buses: buses 31 to 115\n\nData:\n\nThe values are converted from the Y-method data of the report (files `s` of `west30p`\nand `west30n`), with the card format of its appendix 2. The folders `peak/` and\n`night/` have the same layout.\n\n- The sparse node numbers map to consecutive buses: nodes 3010 to 3300 (generators)\n  are buses 1 to 30, nodes 1010 to 1550 are buses 31 to 85, and nodes 2010 to 2300\n  are buses 86 to 115. The bus tag keeps the node number, for example `B3010`.\n- Lines are `pi` branches. A card gives `R`, `X` and `YC = Y/2` per circuit and the\n  number of circuits `n`, so `R/n`, `X/n` and `C = YC*n`.\n  The branch has `circuit = n` (column `circuit` of `branch/parameter.csv`): 36 lines\n  have 2 circuits and 63 have 1.\n- Transformers are `pi_transformer` branches with `R = 0`. All have one bank and tap 1.\n  They have `circuit = 1`.\n- The node value `YC` is the bus shunt `Bshunt`: positive for capacitors, negative\n  for shunt reactors.\n- Generators are gen-park models, with data on the machine MVA of each section, which\n  is converted to the system base: `M = MG*GMVA/1000`, reactances times `1000/GMVA`.\n  The damping `D` is 0 as in the data.\n- The time constants of the data are short-circuit values. The open-circuit values of\n  gen-park are `Td_p = Td'*Xd/Xd'`, `Td_pp = Td''*Xd'/Xd''`, `Tq_pp = Tq''*Xq/Xq''`.\n- The report uses LGT = 4: a field and one damper in the d-axis, one damper in the\n  q-axis, with no `Xq'` or `Tq'`. Its machine table does not list them, and the values\n  in those fields of the cards are unused by this model. gen-park reduces to it with\n  `Xq_p = Xq` exactly, which decouples `Ed`. `Tq_p = 1` is not report data and has no\n  effect at `Xq_p = Xq`.\n- Armature resistance and air-gap saturation of the Y-method model are not modeled;\n  the cards give `TA` and the negative- and zero-sequence reactances, which are unused.\n- The AVR is the rotating-exciter model LAT = 1 of Fig. A1.1 with its constants, which\n  is controller.avr.AVR_DC1 with `ttr = 0`, `kap = 1`, `tap = 0.2`, `tex = 0.02`,\n  `aex1 = 0.01`, `aex2 = 0`, `tst = 0.5`, `kst = 0.1`, `Vap_max = 100`, `Vap_min = -100`:\n  the exciter `100/(1+2s)` is `1/(0.01+0.02s)`, and `Vref` holds the report's offset\n  `EFS/100`. The report's field limit is `Vfld_max = 4`, `Vfld_min = 0`; the field\n  voltages of the equilibrium are 1.02 to 2.03 pu, inside it. The regulator limit is\n  shifted by `EFS/100`. `Limiter = 1` applies both limits; set it to false to ignore\n  them.\n- The governors are those of the G2 cards: LPT = 1 (thermal and nuclear) is\n  controller.governor.IEEJ_LPT1 and LPT = 3 (hydro) controller.governor.IEEJ_LPT3, with\n  the standard constants of the report (NPT = 0), which are the defaults of the classes.\n  `Prate` is the rated MW of the G1 card over the base (`GMW/1000`) and `PLM` [%] the\n  governor margin of the card; it is negative (load-limit operation) for the machines at\n  buses 7, 16, 26 and 30. At peak the machines at buses 2, 8, 14, 24 and 25 are LPT = 3\n  and the others LPT = 1. At night the pumping machines at buses 8, 14, 24 and 25 have a\n  locked governor (LPT = 0), which is the Static governor here, the machine at bus 2 is LPT = 3\n  and the others LPT = 1. The data is in `local_controller/gov-LPT1` and\n  `local_controller/gov-LPT3`. With `Governor=false` every machine has the Static\n  governor and keeps `Pmech` at its equilibrium; `LocalController=false` (the default) adds neither AVRs nor governors: every\n  generator keeps the Static AVR and governor (`avr-static`, `gov-static`).\n- The report's load is NLT = 2: P is constant current down to 0.7 pu and constant\n  impedance below it, with 3.33 %/Hz frequency dependence; Q is constant impedance.\n  Loads here are load-ZIP models with the default parameters, which have this voltage\n  characteristic; the frequency dependence is not represented.\n- In the night section the pumping machines at nodes 3080, 3140, 3240 and 3250\n  (buses 8, 14, 24, 25; -2,620 MW) are PQ nodes with `Q = 0`. A generator bus is always\n  a PV bus here, so their bus `V` is the voltage of the solution with these nodes as PQ,\n  which gives the same power flow with `Q` about 0.\n- The data has no bus coordinates, voltage limits, base voltages or OPF data; these\n  are the GUILDA defaults (OPF cost `HP = fP = 1` for generators and 0 for loads).\n\n- The data has no initial voltages: the power flow starts from the flat start (or the\n  last solution, WarmStart). With the default Tolerance (1e-8) the equilibrium of both\n  sections drifts by at most a few 1e-12 in 10 s of simulate without events.\n\nThe power flow gives the generation and load totals of table 4.10 of the report and\nagrees with its flow diagrams within their rounding, in both sections.\n\nWith the governors the night equilibrium is stable (largest real part -0.061, apart\nfrom the zero mode of the common angle) and the peak one is slightly unstable: a mode\nof 1.6 s has the real part +0.005. Without the governors the peak equilibrium is\nunstable, with a growing oscillation of 0.27 Hz (real part 0.14), and the night one is\nstable (largest real part -0.049, apart from the zero modes of the common angle and\nfrequency). These are with `LocalController=true`. With the Static AVRs and governors\nonly (`LocalController=false`, the default) both are unstable: the largest real\neigenvalues are about +0.20 1/s at peak and +0.18 1/s at night.\n\nThe comparisons with the report are in `_GUILDAverification/IEEJ_WEST30_peak/` and\n`_GUILDAverification/IEEJ_WEST30_night/` of the repository, one folder per section:\n`+PF/README.md` (network data, generator, exciter and governor constants, and the\npower flow against the flow diagram, fig. 4.24) and `+TimeResponse/README.md` (the\ntransient stability cases of table 4.13), each with its reference, data, script and\nmeasured agreement.",
      "SeeAlso": [
        "controller.avr.AVR_DC1",
        "controller.governor.IEEJ_LPT1",
        "controller.governor.IEEJ_LPT3",
        "component.generator.park",
        "component.load.ZIP",
        "Scenario"
      ],
      "Examples": "Run the power flow of the night section and simulate case B of table 4.13 (with the AVRs\nand governors): a fault at\nnode 1220 for 70 ms, cleared by opening one circuit of the line to node 1240 (EL042):\n\n```matlab\nnet = network.IEEJ_WEST30(Section=\"night\", LocalController=true);\nres = net.calculate_powerflow();\nsc  = net.add_scenario(\"fault-open\", Time=[0,10]);\nsc.add_fault(\"B1220\", [0.1,0.17]);\nsc.add_open_branch(\"EL042\", 0.17);\nsol = net.simulate(\"fault-open\");\n```",
      "Citations": "- 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,\n  電気学会技術報告 第754号, 1999.\n- 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,\n  [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)\n  (accessed 2026-11-25).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.IEEJ_WEST30.js",
      "Image": ""
    },
    {
      "Name": "network.TEST31bus",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@TEST31bus/TEST31bus.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "31-bus test system with 10 generators.",
      "Desc": "It has 31 buses, 34 branches, 10 generators (gen-park) and 29 loads\n(load-power) on a 100 MVA base. The bus names\nin the diagram (510, 530, ...) are given with the GUILDA bus numbers in\nparentheses.\n\nDiagram:\n\n```\n                                         510 (8)\n                                          ||\n                                      ┌---||---┐\n                                      |   ||   |\n                                      LL       |\n                                               |\n                                               |\n                           530 (9)   520 (10)  |  500 (11)          320 (12)      340 (13)           330 (14)          350 (15)\n                             ||         ||     └---||                  ||-------------||----------------||----------------||\n                         ┌---||---------||---------||------------------||             ||                ||                ||\n                         |   ||         ||---┐     ||---┐          ┌---||---┐         ||---┐        ┌---||        ┌-------||---┐            100 (3)\n                         |                   |          |          |        |              |        |             |            |               ||\n                         LL                  LL         LL         LL       |              LL       LL            |            LL              ||-----SG\n                                                                            | ┌---LL                              |                            ||\n                                                                            | |                                   |                            ||\n                                                                310 (16) =======                                  |               110 (17)     ||\n                                                                            |                                     |                  ||        ||-----SG\n                                                                            |                                     |         ┌--------||--------||\n                                                                            | ┌---LL                              |         |    ┌---||        ||\n                                                                            | |                                   |         |    |             ||\n                                                                         ======= 300 (18)             360 (19)    |         |    LL            ||-----SG\n                                       250 (20)          260 (7)          |   |                         ||        |         |                  ||\n                                         ||               ||--------------┘   └-------------------------||--------┘         |                  ||\n                                    ┌----||---------------||         370 (21)                           ||---┐              |     ┌------------||\n                                    |    ||---┐           ||            ||                                   |              |     |            ||-----SG\n                                    |         |           ||------------||---┐                               LL             |     |            ||\n                                    |         LL          ||            ||   |                                              |     |            ||\n                                    |                     ||---┐             LL                         1311 (1)            |     |       ┌----||--------------------┐\n                                    |                          |                                         ||                 |     |       |    ||------┐             |\n                                    |                          LL                                 ┌------||----SG           |     |       LL           |             |\n                                    |                                                             |      ||                 |     |                    |         ========= 170 (30)\n                                    |                                                             |                         |     |                    |             |  |\n                                    |                                             130 (5) ============================================                 |             |  LL\n                                    |                                                       |           |            |            |            ||------┘             |\n         2412 (2)    240 (6)        |                                                       |           |            |            |            ||                    |\n              ||        ||          |                                                       |           |            |            |            ||                 ======= 180 (31)\n        SC----||--------||----------┘                                                       |           |            |            |            ||-----SG             |\n              ||        ||                                                                  |           |            |            |            ||                    |\n                        ||----┐                                                             |           |            |            └------------||                    LL\n                        ||    |                                                             |           |            |                         ||\n           270 (22)     ||    LL   230 (23)   220 (24)    210 (25)   200 (26)    150 (27)   |           |            |                         ||-----SG\n              ||        ||          ||          ||          ||          ||          ||      |           |            |                         ||\n         ┌----||--------||----------||----------||----------||----------||----------||------┘           |            |                    ┌----||\n         |    ||        ||          ||---┐      ||---┐      ||---┐      ||---┐      ||---┐              |            |                    |    ||\n         LL                              |           |           |           |           |   140 (28) =====        ===== 160 (29)         |    ||-----SG\n                                         LL          LL          LL          LL          LL             |            |                    LL   ||\n                                                                                                        |            |                         ||\n                                                                                                        LL           LL                        ||\n< symbol >         < name >                                                                                                                    ||-----SG\n   --, |   :   Transmission Line                                                                                                               ||\n                                                                                                                                               ||\n    >>                                                                                                                                        120 (4)\n    >>     :   Transformer\n    >>\n\n    SG     :   Synchronous Generator\n    SC     :   Synchronous Compensator\n    LL     :   Load\n  ===, ||  :   Bus\n    (.)    :   Bus Number\n```",
      "SeeAlso": [
        "network.IEEE14bus"
      ],
      "Examples": "Run the power flow and simulate a rotor-angle offset of the generator at bus 1:\n\n```matlab\nnet = network.TEST31bus();\nres = net.calculate_powerflow();\nsc  = net.add_scenario(\"offset\");\nsc.add_offset(\"B001SG1\", \"delta\", 0.1, 1);\nsol = net.simulate(\"offset\");\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.TEST31bus.js",
      "Image": ""
    },
    {
      "Name": "network.Tutorial10bus",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/Tutorial10bus.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "10-bus network that contains every registered model class, to try each feature on one network.",
      "Desc": "It has 10 buses, 10 branches (one of each branch class at least), 5 generators (one\nof each generator class), 4 loads (one of each load class), every local controller class\nand an AGC over four generators; 60 Hz, 100 MVA base. Buses 1-5 are generator buses\nbehind a step-up branch; buses 6-10 form a ring. Bus 6 has no component (a non-unit\nbus, eliminated in get_sys(Type=\"ODE\")). The network is built with add_bus, add_branch,\nadd_component, add_local_controller and add_global_controller and is initialized by\nthe constructor.\n\nBuses and models (generator parameters: rows of the generator parameter.csv; line and\nload data: network.IEEE9bus):\n\n| Bus  | Type  | Component                    | Local controllers                       |\n|------|-------|------------------------------|-----------------------------------------|\n| B001 | slack | gen-park (NGT2), V = 1.04    | avr-DC1 (kap 20) + pss-PSS1, gov-LPT1   |\n| B002 | PV    | gen-2axis (NGT6), P = 1.63   | avr-ST1 (kap 2), gov-LPT3               |\n| B003 | PV    | gen-1axis (NGT8), P = 0.85   | local-LQR (Input \"Vfield\"), gov-LPT4    |\n| B004 | PV    | gen-classical (NGT2), P = 0.5| pss-retrofit (under the Static AVR)     |\n| B005 | PV    | gen-droop (NGT8), P = 0.3    | none                                    |\n| B006 | PQ    | none (empty bus)             |                                         |\n| B007 | PQ    | load-impedance, -1.25 - 0.5j |                                         |\n| B008 | PQ    | load-power, -0.9 - 0.3j      |                                         |\n| B009 | PQ    | load-ZIP, -1.0 - 0.35j       |                                         |\n| B010 | PQ    | load-current, -0.5 - 0.15j   |                                         |\n\nThe global controller agc-PI (default gains) controls the generators at buses 1-4;\nits `Pmech` output goes to the `Pmech` input of each generator, beside the governor\noutput (get_variable_map shows the routing in its connection map).\n\nBranches:\n\n| From-To | Class                   | Data                                  |\n|---------|-------------------------|---------------------------------------|\n| 1-6     | pi_transformer          | X 0.0576                              |\n| 2-7     | two_winding_transformer | X 0.0625                              |\n| 3-8     | pi_transformer          | X 0.0586, Tap 0.98                    |\n| 4-9     | T                       | R 0.005, X 0.05, C 0.04               |\n| 5-10    | pi                      | R 0.005, X 0.05, C 0.02               |\n| 6-7     | pi                      | R 0.01, X 0.085, C 0.088              |\n| 7-8     | pi                      | R 0.0085, X 0.072, C 0.0745           |\n| 8-9     | T                       | R 0.0119, X 0.1008, C 0.209           |\n| 9-10    | pi                      | R 0.017, X 0.092, C 0.079             |\n| 10-6    | pi                      | R 0.032, X 0.161, C 0.153             |\n\nNotes:\n\n- Controller placement: an AVR, the PSS and local-LQR drive `Vfield`, and the governors,\n  the PSS and the AGC observe `omega`. gen-droop has no `omega` (no output), so it has no\n  controller and is not under the AGC; gen-classical keeps its Static AVR and governor, has\n  pss-retrofit, and is under the AGC. local-LQR drives `Vfield` only, so that the governor and the AGC keep `Pmech`.\n- Linearization: all the finite eigenvalues of `get_ss(\"ODE\")` and `get_ss(\"DAE\")` agree. One eigenvalue is 0 (to rounding): the mode of the common angle\n  of all the rotors, as no bus voltage is fixed. All the others have a negative real part.\n- Simulation: a three-phase fault on bus 8 for 50 ms settles. A fault on another bus\n  stops at the start of the fault, because the constant-power load at bus 8 cannot be\n  supplied at the fault voltages (see load-power).\n- pss-retrofit goes only under the Static AVR, so it is on gen-classical, which keeps its\n  Static AVR and governor. Vfield has no effect on gen-classical, so its gain K is 0 and\n  Vpss stays 0: it is there to cover the key.\n- Not included: component.ConstSource.power (legacy class without a model key; it cannot\n  be created).",
      "SeeAlso": [
        "network.Tutorial3bus",
        "network.IEEE9bus",
        "GUILDA.keymap",
        "PowerNetwork.get_variable_map"
      ],
      "Examples": "Initialize, linearize and simulate a fault at bus 8:\n\n```matlab\nnet = network.Tutorial10bus();\nnet.initialize;\nsys = net.get_sys(Type=\"ODE\");\ne   = eig(sys.A);\nsc  = net.add_scenario(\"fault\", Time=[0,10]);\nsc.add_fault(\"B008\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 20
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.Tutorial10bus.js",
      "Image": ""
    },
    {
      "Name": "network.Tutorial3bus",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/Tutorial3bus.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "3-bus network for the GUILDA tutorial.",
      "Desc": "It has 3 buses, 2 pi lines (1-2 and 2-3), 2 generators (gen-park) at buses 1\nand 2 and a constant-power load (load-power, 3 pu) at bus 3. The network is\nbuilt with add_bus, add_branch and add_component and is initialized by the\nconstructor.",
      "SeeAlso": [
        "network.Txt3Bus",
        "PowerNetwork.add_bus",
        "PowerNetwork.add_branch"
      ],
      "Examples": "Simulate a fault at bus 3:\n\n```matlab\nnet = network.Tutorial3bus();\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B003\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 20
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.Tutorial3bus.js",
      "Image": ""
    },
    {
      "Name": "network.Tutorial6bus",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/Tutorial6bus.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "6-bus network of four classical generators for the spring-mass picture of the tutorial.",
      "Desc": "It has 6 buses, 5 lossless lines and 4 classical generators (gen-classical) at buses\n1-4; buses 5 and 6 have no component. The generators at buses 3 and 4 have a negative\nactive power: they run as synchronous motors. The network has no governor, AVR or\nload; 50 Hz, 100 MVA base. It is built with add_bus, add_branch and add_component and\nis initialized by the constructor.\n\n| Bus  | Type  | Component                          | M  | D | Xd = Xq |\n|------|-------|------------------------------------|----|---|---------|\n| B001 | slack | gen-classical, V = 0.9             | 10 | 5 | 0.20    |\n| B002 | PV    | gen-classical, P = 1.0, V = 1.3    | 8  | 5 | 0.20    |\n| B003 | PV    | gen-classical, P = -0.7, V = 1.289197 | 6  | 5 | 0.25    |\n| B004 | PV    | gen-classical, P = -0.8, V = 1.010786 | 6  | 5 | 0.25    |\n| B005 | PQ    | none                               |    |   |         |\n| B006 | PQ    | none                               |    |   |         |\n\nLines (pi, R = 0, C = 0): 1-5 X 0.35, 2-5 X 0.20, 5-6 X 0.20, 3-6 X 0.30, 4-6 X 0.35.\nA generator is a PV source in GUILDA, so the voltages at buses 3 and 4 are those of the\noperating point with Q = 0.8 at bus 3 and Q = -0.2 at bus 4. The slack generator at\nbus 1 supplies P = 0.5 (the lines are lossless).",
      "SeeAlso": [
        "network.Tutorial3bus",
        "network.Tutorial10bus",
        "ResultODE.plot_spring_model"
      ],
      "Examples": "Generators 3 and 4 take 0.1 pu more from t = 1 s, without governors:\n\n```matlab\nnet = network.Tutorial6bus();\nsc  = net.add_scenario(\"step\", Time=[0, 20]);\nsc.add_input(\"B003SG1\", \"Pmech\", -0.1, [1, 20]);\nsc.add_input(\"B004SG1\", \"Pmech\", -0.1, [1, 20]);\nres = net.simulate(\"step\");\nG = res.plot_spring_model();\nG.animate();\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 20
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.Tutorial6bus.js",
      "Image": ""
    },
    {
      "Name": "network.Txt3Bus",
      "Origin": "Object",
      "Folder": "_GUILDAobject/+network",
      "Category": "network",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerNetwork",
      "Superclasses": [
        "PowerNetwork"
      ],
      "Ancestors": [
        "PowerNetwork",
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "network",
      "File": "_GUILDAobject/+network/@Txt3Bus/Txt3Bus.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "3-bus system of the GUILDA textbook.",
      "Desc": "The system of \"Systems Control Engineering of Power Systems - System Mathematics\nand MATLAB Simulation -\" (2022). It has 3 buses, 2 pi lines, 2 generators\n(gen-1axis) at buses 1 and 3 and a constant-impedance load (load-impedance) at\nbus 2, on a 100 MVA base.",
      "SeeAlso": [
        "network.Tutorial3bus"
      ],
      "Examples": "Run the power flow and simulate a fault at bus 2:\n\n```matlab\nnet = network.Txt3Bus();\nres = net.calculate_powerflow();\nsc  = net.add_scenario(\"fault\");\nsc.add_fault(\"B002\", [1,1.05]);\nsol = net.simulate(\"fault\");\n```",
      "Citations": "- 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学\n  ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),\n  計測自動制御学会 編, コロナ社, 2022, Example 2.1, ISBN 978-4-339-03384-7,\n  [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 21
      },
      "MethodCount": {
        "Own": 1,
        "Total": 49
      },
      "path": "./database/GUILDAobject/network.Txt3Bus.js",
      "Image": ""
    },
    {
      "Name": "Parameter",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary, LayerPackage",
      "Superclasses": [
        "auxiliary",
        "LayerPackage"
      ],
      "Ancestors": [
        "auxiliary",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@Parameter/Parameter.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Parameter container for LayerPackage-derived objects.",
      "Desc": "It stores the parameters of one group of its owner as a table (`tab_parameter`): one\nrow (a GlobalController: one row per controlled unit, named by the unit), one column\nper parameter. Writing the table checks it against the stored one, stores it, and\nreports each changed column with log_edit (tag: the group, e.g. \"dynamics\"; log:\n\"edit <name>: <old> -> <new>\"), so the owner layer and the layers above it mark what\nthe edit makes stale. `s_lastEdited` is the name of the parameter of that edit, for the\nlayers that tell parameters of one group apart (PowerNetwork: baseMVA and Hz).\nA container made with a check function (`f_validate`, the graph parameters of the buses,\nbranches and components) also checks the values: a wrong value stops the write, whether\nit comes from add_*, a direct table write, the GUI or net.set_layout, and nothing is stored.",
      "SeeAlso": [
        "LayerPackage"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nbus = net.a_Bus{1};\nbus.tab_parameter                  % parameters of the bus as a table\nbus.tab_parameter.powerflow.V = 1.02;\nnet.sct_stale.powerflow            % the edit makes the power flow of the network stale\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_cls",
          "Type": "LayerPackage"
        }
      ],
      "PropertyCount": {
        "Own": 7,
        "Total": 10
      },
      "MethodCount": {
        "Own": 1,
        "Total": 11
      },
      "path": "./database/GUILDAsystem/Parameter.js",
      "Image": ""
    },
    {
      "Name": "PowerNetwork",
      "Origin": "System",
      "Folder": "_GUILDAsystem",
      "Category": "",
      "Type": "PowerSystemModel",
      "Model": "PowerNetwork",
      "Parent": "PowerSystemModel",
      "Superclasses": [
        "PowerSystemModel"
      ],
      "Ancestors": [
        "PowerSystemModel",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "network.GUILDAlogo",
        "network.IEEE14bus",
        "network.IEEE14bus_lossless",
        "network.IEEE14bus_NoTap",
        "network.IEEE39Bus",
        "network.IEEE68bus",
        "network.IEEE9bus",
        "network.IEEJ_EAST10",
        "network.IEEJ_EAST30",
        "network.IEEJ_WEST10",
        "network.IEEJ_WEST30",
        "network.TEST31bus",
        "network.Tutorial10bus",
        "network.Tutorial3bus",
        "network.Tutorial6bus",
        "network.Txt3Bus"
      ],
      "Package": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Root of the model: holds the buses, branches and global controllers of one grid and runs the analyses.",
      "Desc": "- Owns the topology (which buses, branches and global controllers exist), the system\n  base in `tab_parameter.base` (Hz, baseMVA) and the solver objects `solver_*`.\n- Every analysis starts here: the method reads its settings from a solver object, hands\n  the network to it and returns a result object.\n- Not where the numbers are: bus voltages belong to `Bus`, the model equations to\n  `Component` and the controllers, the numerical methods to the Solver classes.\n- Results are returned, never stored in the network. The one exception: `initialize`\n  writes the equilibrium into the buses, components and controllers.\n- Top of the object tree, with no parent. It is the parent of its buses, branches,\n  global controllers and scenarios; only the network sets their back references\n  (`Bus.a_PowerNetwork`, `Branch.a_PowerNetwork`, `Branch.a_Bus`,\n  `GlobalController.a_PowerNetwork`, `Scenario.a_PowerNetwork`). The remove methods\n  delete the buses, branches, global controllers and scenarios they take out.\n- Every edit is reported to the network's `handle_edit` (`LayerPackage.log_edit`), also\n  before the first initialize. It keeps at most one slack bus, and marks the stale tag\n  `powerflow` (`sct_stale`) for the edits that change the power flow: baseMVA, buses and\n  branches added, removed or replaced, bus parameters (powerflow, dynamics), the slack\n  bus, components connected, replaced or removed, branch dynamics and component\n  powerflow parameters. A Hz edit marks its stale tag `odefcn` (the function handles of\n  every model; the edit does not reach them). The components and controllers mark\n  their own stale tags.\n- `initialize` brings every layer up to date; the analyses only read the stale tags\n  they need and stop with their own error (GUILDA:PowerNetwork:SimulateStale,\n  SolverCPF:Stale, and PowerSystemModel:Stale of get_sys), naming the\n  reasons, until it has run.\n\nA network is built by adding buses (`add_bus`) and branches (`add_branch`); the\ncomponents (generators, loads, ...) are added to the buses (`Bus.add_component`) and\nlocal controllers to the components. The network runs the analyses:\n\n- power flow (`calculate_powerflow`), power flow with the inputs of the components held\n  (`calculate_fixed_input_powerflow`) and optimal power flow (`calculate_optimal_powerflow`)\n- the data of the power flow and the OPF (`get_pf_condition`, `get_opf_condition`)\n- continuation power flow (`calculate_continuation_powerflow`)\n- equilibrium (`initialize`), time simulation (`simulate`) of the scenarios it holds\n  (`add_scenario`, `remove_scenario`, `a_Scenario`)\n- linearization and eigenvalue analysis (`get_sys`)\n- network diagrams (`plot_diagram`, the black-and-white `plot_single_line_diagram`) and their layout (`get_layout`, `set_layout`), spring-mass pictures of the equilibrium\n  (`plot_spring_model`), the signal connections of the controllers\n  (`disp_connection`) and CSV / MATPOWER import and export\n\nEach analysis runs a solver object stored in a `solver_*` property; a subclass of the\nnetwork may replace it with a subclass of the solver. `solver_PF` keeps no settings\n(they are in GUILDA.setting), only the warm start solution; the other solvers hold\nstored defaults, kept between runs. Name-Value options of a call override the settings\nfor that call only. Results are returned (calculate_powerflow and initialize: in the\nform of their Format option) and never stored in the network or the solver.\n\nThe scenarios (`a_Scenario`) are created by `add_scenario` and deleted by\n`remove_scenario`; their tags share the name space of the other children, but they are\nnot model data and do not make the equilibrium stale.\n\nThe parameters of the network (`tab_parameter.base`):\n\n- `Hz` [Hz]: nominal frequency. Models read it with get_Hz() and receive it as omega0.\n  Set by the constructor (GUILDA.config(\"PowerSystemModel\",\"Hz\")), by writing the table and by\n  import. An edit marks the stale tag `odefcn` of the network: initialize only\n  rebuilds the function handles (each model compares the frequency it was built with).\n- `baseMVA` [MVA]: system base of all per-unit values (default 100). Stored per-unit\n  values are not converted when it changes. Set by the constructor, by writing the\n  table, import and import_matpower. An edit makes the power flow stale.\n\nPower-flow settings are parameters of the buses (`tab_parameter.powerflow`: V, Varg)\nand the components (`tab_parameter.powerflow`: P, Q). OPF limits and costs are in\n`tab_parameter.operation` and `tab_parameter.OPF` of the buses, components and\nbranches; user-defined costs and constraints are the options Cost and Constraint of\n`calculate_optimal_powerflow` and `build_opf_problem`.",
      "SeeAlso": [
        "Bus",
        "Branch",
        "Component",
        "GlobalController",
        "Scenario",
        "network.IEEE9bus"
      ],
      "Examples": "```matlab\nnet = PowerNetwork(\"ThreeBus\");\nnet.add_bus(V=1.0, Varg=0);\nnet.add_bus(V=1.0);\nnet.add_bus();\nnet.add_branch(\"pi\", [1,2], R=0.010, X=0.085);\nnet.add_branch(\"pi\", [2,3], R=0.017, X=0.092);\nnet.a_Bus{1}.add_component(\"gen-park\", P=0.0);\nnet.a_Bus{2}.add_component(\"gen-park\", P=0.5);\nnet.a_Bus{3}.add_component(\"load-power\", P=-0.5, Q=0);\nnet.a_Bus{1}.l_isSlack = true;\n\nres = net.calculate_powerflow();          % ResultPF\nnet.initialize();                         % equilibrium for the dynamic analyses\nsc  = net.add_scenario(\"fault\", Time=[0,10]);\nsc.add_fault(\"B003\", [1,1.05]);\nsim = net.simulate(\"fault\");              % ResultODE\nres = net.get_sys();                      % ResultLIN: linear model in res.A, res.B, ...\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_Bus",
          "Type": "Bus"
        },
        {
          "Name": "a_Branch",
          "Type": "Branch"
        },
        {
          "Name": "a_GlobalController",
          "Type": "GlobalController"
        },
        {
          "Name": "a_Scenario",
          "Type": "Scenario"
        }
      ],
      "PropertyCount": {
        "Own": 14,
        "Total": 20
      },
      "MethodCount": {
        "Own": 63,
        "Total": 73
      },
      "path": "./database/GUILDAsystem/PowerNetwork.js",
      "Image": "./database/images/PowerNetwork.svg"
    },
    {
      "Name": "PowerSystemModel",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "PowerSystemModel",
      "Model": "",
      "Parent": "LayerPackage",
      "Superclasses": [
        "LayerPackage"
      ],
      "Ancestors": [
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [
        "Branch",
        "Bus",
        "Component",
        "GlobalController",
        "LocalController",
        "PowerNetwork"
      ],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Base class of the classes that constitute the power system model.",
      "Desc": "PowerNetwork, Bus, Branch, Component, LocalController and GlobalController derive from\nit. It separates the classes that make up the power system model from those intended\nfor analysis assistance:\n\n- Classes that constitute the power system model inherit from PowerSystemModel.\n- Classes intended for analysis assistance inherit from auxiliary.\n\nWhat is out of date is kept by each layer (LayerPackage: `sct_stale`); only\nPowerNetwork.initialize brings it up to date. get_Hz gives every model the nominal\nfrequency of its network.",
      "SeeAlso": [
        "auxiliary",
        "LayerPackage",
        "Parameter"
      ],
      "Examples": "",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_Parameter",
          "Type": "Parameter"
        }
      ],
      "PropertyCount": {
        "Own": 3,
        "Total": 8
      },
      "MethodCount": {
        "Own": 4,
        "Total": 13
      },
      "path": "./database/GUILDAsystem/PowerSystemModel.js",
      "Image": ""
    },
    {
      "Name": "ProgressGUILDA",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@ProgressGUILDA/ProgressGUILDA.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Progress display of an analysis: a dialog, one line per step in the Command Window, or nothing.",
      "Desc": "The analyses create one per run from their Progress option: net.calculate_powerflow,\nnet.calculate_fixed_input_powerflow, net.calculate_continuation_powerflow,\nnet.calculate_optimal_powerflow and net.simulate. The mode is\n\n- \"dialog\": a dialog that opens only when the run lasts 0.5 s or longer, so a short run\n  shows nothing. It shows the last text given to update; while the run gives no new text,\n  the bar keeps moving (a timer redraws it every 0.25 s). Inside the GUILDA app\n  (GUILDA.launch_gui) it is a uiprogressdlg of the app window, otherwise a waitbar. It\n  closes when the object is deleted (the analyses delete it with onCleanup, also on an\n  error). Under matlab -batch \"dialog\" shows nothing.\n- \"disp\": update prints each new text as one line in the Command Window (the time\n  simulation prints its text bar instead).\n- \"none\": nothing.\n\ntrue and false are taken as \"dialog\" and \"none\". For the time simulation, SolverODE.solve\npasses OutputFcn and Events to the MATLAB ode object; they show the time reached and stop\nthe integration when the run takes longer than timelimit.",
      "SeeAlso": [
        "SolverODE",
        "SolverPF",
        "SolverCPF",
        "SolverOPF"
      ],
      "Examples": "",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 19,
        "Total": 19
      },
      "MethodCount": {
        "Own": 9,
        "Total": 10
      },
      "path": "./database/GUILDAsystem/ProgressGUILDA.js",
      "Image": ""
    },
    {
      "Name": "ResultBase",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [
        "ResultCPF",
        "ResultLIN",
        "ResultODE",
        "ResultOPF",
        "ResultPF"
      ],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 1,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Abstract base class for the results of analyses (power flow, OPF, CPF, time simulation, linearization).",
      "Desc": "An analysis method net.verb_noun() returns [result, flag, output]; the result object\nalso keeps flag and output, the settings actually used and the elapsed time, so the\nresult alone is enough to check the outcome. A result stores what the analysis computed\nand the settings it used (`options`: the analysis method merges its section of\nGUILDA.setting, and for the continuation power flow the LoadBus of net.solver_CPF, with\nthe Name-Value options of the call; get_sys keeps the options of its call). Model data\nstays with its owner. ResultPF, ResultOPF and ResultODE are built from data and a struct\nsnapshot of the network (struct(net, false)); they keep its tag (s_network) and refer to\nno network object. ResultPF, ResultOPF and ResultODE keep the snapshot (sct_network).\nResultCPF and ResultLIN refer to the analysed network\n(a_PowerNetwork, not a copy; the network may have been edited after the analysis) and\nkeep its tag; they do not copy bus, branch or component data. export\nis part of the contract: a subclass overrides it when it writes files; otherwise it stops\nwith the error GUILDA:ResultBase:Unsupported. Figures are drawn by the plot_* methods of\neach subclass (ResultPF.plot_voltage, ResultOPF.plot_dispatch, ResultCPF.plot_pvcurve,\nResultODE.plot_trajectory, ResultLIN.plot_eigenvalue).\nlaunch_gui shows a result in a GUI that runs its plot_*, disp_*, get_* and export\nmethods from buttons and logs them as code (DrawerResultGUI).",
      "SeeAlso": [
        "ResultPF",
        "ResultOPF",
        "ResultCPF",
        "ResultLIN",
        "ResultODE"
      ],
      "Examples": "Every analysis of a network returns a subclass of ResultBase:\n```matlab\nnet = network.IEEE14bus();\nnet.initialize();\n[result, flag, output] = net.calculate_powerflow();\nresult.l_success     % true when the analysis succeeded\nresult.options       % settings used for this run\nresult.r_elapsed     % elapsed time [s]\nresult.plot_voltage();\nh = result.launch_gui();   % the methods of the result as buttons\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_PowerNetwork",
          "Type": "PowerNetwork"
        }
      ],
      "PropertyCount": {
        "Own": 8,
        "Total": 8
      },
      "MethodCount": {
        "Own": 5,
        "Total": 6
      },
      "path": "./database/GUILDAsystem/ResultBase.js",
      "Image": ""
    },
    {
      "Name": "ResultCPF",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "ResultBase",
      "Superclasses": [
        "ResultBase"
      ],
      "Ancestors": [
        "ResultBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Result of net.calculate_continuation_powerflow.",
      "Desc": "Holds the load parameter lambda and the bus voltages at each point of the traced path,\nand the nose point (maximum loading). The loads of options.LoadBus are scaled by\n(1 + lambda). It holds computed values only; the settings of the buses and components\nstay with the network. plot_pvcurve draws the PV curves, get_point gives the operating\npoint of a step. export writes the path as a table (CSV, Excel): tab_path.\n\nWith the option Limits (see SolverCPF), `tab_switch` lists the PV buses switched to PQ\nat Qmin/Qmax of their generators: lambda and Step (index in rv_lambda) of the switch\npoint, Bus, Limit (\"Qmin\"/\"Qmax\") and Bound (the fixed Q [pu]). `tab_stop` has one row\nwhen a \"V\" or \"S\" limit ended the path: lambda and Step of the last point, Class (\"Bus\"\nor \"Branch\"), Object (tag), Limit (\"Vmin\", \"Vmax\", \"Smax\") and Bound [pu]. Both have 0\nrows otherwise. When the path stops before the nose, r_lambdaMax is the lambda of the\nstop.\n\nThe operating point of every step is kept for the network diagram, the spring-mass model\nand the linearization along the path: `tab_variable` and `rm_variable` have the layout of\nResultODE (the rows x, Vre, Vim, u, uc of net.get_variable_map(); row k of rm_variable is\nstep k, the index in rv_lambda as r_noseStep), `cm_Icomponent` the current of each\ncomponent and `sct_network` a snapshot struct(net, false). get_point(Step) returns a\npoint for net.get_sys, so net.get_sys({result, [1 result.r_noseStep]}) linearizes at the\nfirst point and at the nose (one section per step). At each step the bus injection is\nsplit to the components as net.initialize splits a power flow solution\n(tools.distribute_power: the components inject their CPF powers, the loads of LoadBus\nscaled by (1 + lambda); the free P of the slack bus and the free Q go to the components\nwith Q = NaN, so a bus switched to PQ keeps its fixed Q), and (x, u) of each component\nand (x, uc) of its local controllers are their get_equilibrium values for that split\n(with UseInternalState, x of a component is its CPF state and u its rv_Uequilibrium).\nThe local controllers get the state x of the component at the step as the fourth\nargument of get_equilibrium, and an input observed on the component takes the value of\nthe component at the step. Their design (e.g. the gain K of local-LQR and pss-retrofit,\nwith the equilibrium it was designed at) stays as net.initialize made it, so for such\ncontrollers the point of a later step is not exactly an equilibrium of the controller\n(see their help). The global controllers keep their equilibrium values. Values of\na model whose get_equilibrium stops at a step (a limit of its range) are NaN at that\nstep. Step 1 is the equilibrium of net.initialize.\n\nVoltage stability: `rv_sigmaMin` is, at each step, the smallest singular value of the\nfinite-difference Jacobian J of the CPF equations with respect to the unknowns, without\nthe lambda column. The equations are the P and Q mismatches of the buses [pu] (with\nUseInternalState, also the state equations of the components), the unknowns |V| and\ntheta of the buses (with UseInternalState, also the states of the components). At the\nsaddle-node nose J is singular, so sigma_min = 0 there. It has no physical unit and no\nabsolute threshold: near the nose it falls roughly like sqrt(lambda_max - lambda), so\nread it against its first value, or read lambda_max - lambda instead. It jumps where\nLimits \"Q\" switches a PV bus to PQ, and a path stopped by a \"V\" or \"S\" limit ends with\na value far from 0 (Löf et al., IEEE Trans. Power Systems 7(1), 1992; Gao, Morison,\nKundur, IEEE Trans. Power Systems 7(4), 1992; see plot_stability_index). `tab_weakbus` ranks the buses at the nose: Participation is |V| of each\nbus in the right singular vector of that singular value (largest 1), dVdLambda the\naverage d|V|/dlambda [pu] from the first point to the nose (NaN when the nose is the\nfirst point). `r_marginP` [pu] is r_lambdaMax times the initial active power of every\ncomponent actually scaled by (1 + lambda) (power drawn minus power generated): the\ncomponents of LoadBus, and with UseInternalState every component. With\nUseInternalState the CPF scales every component, the generators included, so the sum\nis the power drawn minus the power generated over the whole network, which is minus\nthe network losses: r_marginP is then usually negative. With UseInternalState, x of a\ncomponent at a step is its CPF state and u is its equilibrium input rv_Uequilibrium\n(the CPF equations hold u fixed).\n\nPlots of the steps: every plot below takes the steps as its samples (rv_t = 1 ...\nn_step, named \"Step\", with the text \"Step k (λ = ...)\"; lambda is not monotonic past the\nnose), so G1.link(G2) keeps them in step with each other and with\nnet.get_sys({result, steps}).plot_eigenvalue / plot_eigenvalue_path (the sections of\nthat ResultLIN are the step numbers). G.set_time(k) shows step k; on a curve against\nlambda it puts a marker at step k. G.animate() and G.export_video(file) play one frame\nper step.\n\n- plot_pvcurve: |V| of the buses against lambda, the nose marked.\n- plot_diagram: network diagram (GraphNetDiagram) of each step from cm_Vbus,\n  cm_Icomponent and sct_network.\n- plot_spring_model: spring-mass picture (GraphSpring2D/3D) of each step from\n  tab_variable, rm_variable, cm_Icomponent and sct_network.\n- plot_stability_index: rv_sigmaMin against lambda, and the participation of the weak\n  buses at the nose (tab_weakbus).\n- plot_pqv: P, Q and |V| of the buses as 3D lines over the steps (P + jQ = V conj(Y V)).\n- plot_generator: P, Q or the Q margin (to the nearer of Qmin, Qmax) of the generators\n  (components with Q = NaN in powerflow) against lambda, the switches of tab_switch\n  marked.\n- plot_branch: P, |S|, loading |S|/Smax or the loss of the branches (or the total loss)\n  against lambda.\n\nplot_diagram, plot_spring_model, plot_stability_index, plot_generator and plot_branch\ndraw the PV curves with them by default (PVCurve true, buses PVBus) and return the PV\nchart as a second output G_pv, linked: on the right (1/3 of the width) of the diagram\nand the spring-mass picture, as an extra panel on top of the lambda-axis charts (G_pv =\nG). PVCurve=false draws the plot alone.\n\nThe plots other than plot_pvcurve read the data of the steps; a result without it (a\nResultCPF built by hand) stops with GUILDA:ResultCPF:NoStepData.\n\n`rm_x` is the CPF_Result.x_sol of v3: its rows are [|V|; angle V] of each bus (followed\nby the component states when options.UseInternalState is true), and lambda in the last\nrow. `rm_xPredicted` is the CPF_Result.x_prd of v3 in the same layout.",
      "SeeAlso": [
        "SolverCPF",
        "ResultBase"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.initialize();\n[result, flag] = net.calculate_continuation_powerflow(LoadBus=[\"B009\",\"B014\"]);\nresult.r_lambdaMax       % maximum loading (nose of the PV curve)\nresult = net.calculate_continuation_powerflow(LoadBus=[\"B009\",\"B014\"], Limits=\"all\");\nresult.tab_switch        % PV buses switched to PQ at their Q limits\nresult.tab_stop          % voltage or branch limit that ended the path\nresult.tab_nose          % bus voltages at the nose\nresult.tab_weakbus       % buses ranked by their participation at the nose\nx = result.get_point(result.r_noseStep);          % point for net.get_sys(x)\nlin = net.get_sys({result, [1 result.r_noseStep]});   % one section per step\nresult.plot_pvcurve(Bus=\"all\");  % PV curves of every bus\n[G, G_pv] = result.plot_diagram();   % network diagram of each step, PV curves on the right\nG.set_time(result.r_noseStep);    % both at the nose\nresult.plot_pqv();                % P-Q-V paths of the load buses\nresult.plot_generator(Quantity=\"Qmargin\");\nlin.plot_eigenvalue_path();       % eigenvalues over the two steps\nresult.export(\"cpf.csv\");\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 18,
        "Total": 26
      },
      "MethodCount": {
        "Own": 13,
        "Total": 17
      },
      "path": "./database/GUILDAsystem/ResultCPF.js",
      "Image": ""
    },
    {
      "Name": "ResultLIN",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "ResultBase",
      "Superclasses": [
        "ResultBase"
      ],
      "Ancestors": [
        "ResultBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Result of get_sys.",
      "Desc": "Holds the linear model of a layer at one or more points (time sections), as connected by\nSolverLIN.solve from the linear blocks of its model objects. For the network (output.s_layer \"PowerNetwork\") it is\nthe unreduced linear DAE\n\n```\nrm_E dx/dt = rm_Axx x + rm_Axv v + rm_Bx u\n         0 = rm_Avx x + rm_Avv v + rm_Bv u\n```\n\nwhere x are the states, v = [Vre1; Vim1; Vre2; ...] the bus voltages and u the inputs,\nall in the order of the variable map tab_variable (= net.get_variable_map() at the time\nof the analysis). The algebraic equations are the current balance of each bus,\n0 = (Y v - I of the components), in the order of v. The values are deviations from the\npoint rv_point. Y is the admittance matrix of the model, also at a point inside a fault.\nget_ss returns the model of a Type (\"ODE\": the bus voltages eliminated, or \"DAE\"),\nget_contribution the part of elements in the DAE (a ResultLIN of its own, below),\nget_mode the modes (eigenvalue,\nfrequency, damping ratio, dominant owner and participation), get_participation the\nparticipation of the states and of the buses in the modes, and plot_eigenvalue draws the\neigenvalue map. get_eigenvalue and get_eigenvector return the eigenvalues and\neigenvectors in the order of get_mode, get_kernel the kernel of the Jacobian of the DAE\n(the rotation of the phases of each island), get_reduced_matrix the Jacobian with the\nvariables of chosen elements eliminated (Schur complement), and disp_summary and\ndisp_mode display the result and its modes. plot_matrix draws a matrix of the model by\ngroups of variables; plot_kernel, plot_participation, plot_eigenvector,\nplot_contribution and plot_reduced_matrix draw the kernel, the participation, the\neigenvectors, the shares of the elements in an eigenvalue and the reduced matrix on the\nnetwork diagram (the participation, eigenvectors and shares with the mode picked on the\neigenvalue map).\n\nThe properties A, B, C, D, E, StateName, InputName and OutputName hold one linear model\n(E dx/dt = A x + B u, y = C x + D u) with the names of the states, inputs and outputs, as\nin a state-space (ss) object, without the Control System Toolbox: get_ss(Type) with the\nInput, Output and Port of get_sys. They are computed from the DAE when read, and\nType chooses the model: its default is the Type of get_sys, and setting it (res.Type =\n\"DAE\") switches all of them. They are empty when get_ss stops (flag false, or \"ODE\" with\na singular Avv); get_ss gives the reason.\n\nForm chooses the view of A ... E (also an option of get_ss and of get_sys; res.Form =\n\"absorbed\" switches A ... OutputName like Type):\n\n- \"descriptor\" (default): E holds the time constants (the mass matrix of the models).\n- \"absorbed\": E^-1 multiplied into the rows of the states in A and B; E is the identity\n  there and zero on the bus variables (and on a state without a time constant, whose\n  row is kept). Derived from the descriptor model, so every result has it; the\n  eigenvalues and the transfer function do not change.\n- \"hessian\": the energy-function form (Nishino et al. 2025, eqs. (21)-(30)), only for a\n  result of net.get_sys(Form=\"hessian\"), which calls get_hessian of every component\n  and local controller at the point of each section. Over z = [x; theta; V] (Port\n  \"PI\"), E_h dz/dt = H z + B_h u with E_h = -blkdiag(inv(R), 0) and\n  H = [Hxx Hxv; Hvx Hvv + Hvv_net]: dx/dt = -R (Hxx x + Hxv v) and the balance\n  0 = Hvx x + (Hvv + Hvv_net) v, where w = sum of w_dev = dU/dv = -[P; Q/V] of the\n  devices plus w_net = [P; Q/V] of the power from each bus into the network, and\n  Hvv_net its exact Jacobian. H is the Hessian of the energy function (symmetric) when\n  the model is lossless. \"PQ\" follows by dV = V drho, dQ = V d(Q/V) (H -> T H T,\n  T = diag(1, V)). B_h is the descriptor B with its state rows times E_h E^-1, and C, D\n  are those of the descriptor model (the same variables); the inputs are constants of\n  the point in the energy function. Equal to the descriptor DAE with its state rows\n  times E_h E^-1 where the bus balance holds (the equilibrium, a simulation point; the\n  I dV terms of the devices cancel in the bus sum). Port \"I\" stops with\n  GUILDA:ResultLIN:HessianPort. rv_asymmetry is the asymmetry of Hvv + Hvv_net of each\n  section (the loss: branch resistances, conductances, impedance and current loads).\n  The descriptor data is kept, so Form switches back.\n\nA result of comp.get_sys, bus.get_sys, con.get_sys or gc.get_sys (output.s_layer\n\"Component\", \"Bus\", \"LocalController\" or \"GlobalController\") holds the port model of the\nlayer in A ... OutputName (see PowerSystemModel.get_sys), the point rv_point and the\nblocks rm_Axx, rm_Axv (the voltage inputs), rm_Bx (the other inputs of tab_variable)\nand rm_E. get_ss returns that model, and Type and Port do not apply.\n\nTime sections: get_sys({sim, rv_t}) with several times, or a matrix of points (one per\ncolumn), gives one section per time or column; the equilibrium and a vector give one.\nrv_t holds the time of each section (the times of {sim, rv_t}, 1:n for a matrix, NaN\notherwise), and Index (default 1) chooses the section that rv_point, rm_Axx ... rm_E,\nsct_model and A ... OutputName show: res.Index = 3 switches all of them. get_ss,\nget_mode, plot_eigenvalue and the analysis methods (get_eigenvalue ... disp_mode) take\nIndex (default res.Index); all but plot_eigenvalue also take Time (the section of the nearest time), and Index \"all\" returns every section\n(get_eigenvalue: a table; get_mode and the other getters: a struct array, whose tab_mode\nare one table by vertcat). plot_eigenvalue of several sections draws all of them in one chart whose\nset_time shows the section nearest to a time (Index is the section shown first), so it\nlinks with the graphs of the simulation, and plot_eigenvalue_path draws the largest\nreal part and the smallest damping ratio over the sections, marking the first unstable\none. flag is true only when every section\nis usable; output.lv_flag, sv_issue, sv_message and rv_rcond_Avv describe each section,\nand the scalar fields (message, s_issue, rcond_Avv, sv_faultBus) the whole run. A\nresult of the network keeps a snapshot of it, sct_network = struct(net, false).\n\nA contribution result: res.get_contribution(target) returns a ResultLIN with every\nsection of res whose sections hold the part of the targets in the connected model (the\nterms of those elements), with sv_target the targets. Its Type is \"DAE\" only (an \"ODE\"\nstops with GUILDA:ResultLIN:ContributionDAE) and it has no Form \"hessian\"; the parts of\nall the elements sum to the DAE of res in every section. Its methods compute on the\npart: on a contribution result (sv_target nonempty) the numbers are of the part alone\nand have no meaning for the whole system.\n\n- `tab_variable` has one row per variable with Index, Kind, Role, Owner, Name, Label, Bus\n  and Equilibrium: the leading rows x, Vre, Vim, u, uc of the variable map of the layer (for\n  a controller: its x, the voltages and its uc), the order of rv_point.\n- `sct_model` holds the connected model (field sct_sys: the descriptor model over\n  [x; v] with its outputs, from SolverLIN.solve) and, for the network, the admittance\n  matrix, the bus voltages at the point and the names of the bus currents: used by the\n  coordinates of get_ss(\"DAE\") and its Output option; sct_sys also holds the terms of\n  each element (sct_term) and their classes (tab_owner) for get_contribution. The\n  result holds computed values only; the network is not changed.",
      "SeeAlso": [
        "SolverLIN",
        "ResultBase",
        "PowerSystemModel.get_sys"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.initialize();\n[result, flag] = net.get_sys();\neig(full(result.rm_Axx))          % Jacobian blocks of the unreduced DAE\neig(result.A, result.E)           % model of result.Type (the Type of get_sys)\nresult.Type = \"DAE\";              % A ... OutputName are now the DAE\nsct = result.get_ss(\"ODE\", Format=\"struct\");   % reduced model as a struct\nsys = result.get_ss(\"ODE\");       % ss object (Control System Toolbox)\nres_gen = result.get_contribution(\"component.generator.abstract\");   % part of the generators in the DAE (a ResultLIN)\nres_gen.A                                    % that part of the DAE in the section shown\nsct = result.get_mode(MinFrequency=0.1);     % oscillatory modes: sct.tab_mode, participation, shapes\nsct = result.get_participation();            % participation by state and by bus (tab_bus)\nresult.plot_eigenvalue();                    % eigenvalue map\nresult.disp_summary();                       % sizes, status, modes and kernel\nsct = result.get_kernel();                   % rotation of the angles: rm_right, rm_left, tab_phase\nsct = result.get_reduced_matrix([\"Component\",\"LocalController\"]);   % seen from the buses\nresult.Form = \"absorbed\";  eig(result.A)     % E^-1 multiplied in\n\nresH = net.get_sys(Type=\"DAE\", Port=\"PI\", Form=\"hessian\");   % energy-function form (supported devices only)\nresH.rv_asymmetry                            % asymmetry of Hvv + Hvv_net (0 when lossless)\nresH.Form = \"descriptor\";                    % the Jacobian of the same result\n\nsc = net.add_scenario(\"fault\");  sc.add_fault(\"B008\", [1,1.05]);\nsim = net.simulate(\"fault\", Time=[0,5]);\nres = net.get_sys({sim, [0.5, 2, 4]});       % three time sections\nres.Index = 2;  eig(res.A, res.E)            % the section at t = 2\nsys = res.get_ss(Time=4, Format=\"struct\");   % the section nearest to t = 4\ntab = vertcat(res.get_mode(Index=\"all\").tab_mode);   % modes of every section, with Time and Index\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 29,
        "Total": 37
      },
      "MethodCount": {
        "Own": 33,
        "Total": 38
      },
      "path": "./database/GUILDAsystem/ResultLIN.js",
      "Image": ""
    },
    {
      "Name": "ResultODE",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "ResultBase",
      "Superclasses": [
        "ResultBase"
      ],
      "Ancestors": [
        "ResultBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Result of net.simulate.",
      "Desc": "Holds the time response of the bus voltages, currents and powers, of the states and\ninputs of the components and controllers, and of their outputs. It is built from data\nonly: the trajectories of the solver, the variable map and the output functions of the\nrun, a struct snapshot of the network (sct_network = struct(net, false)) and the solver\ninformation. It keeps no reference to the network: its methods (get_trajectory, plot_trajectory,\nget_point, export, judge_out_of_step, odeResults) work after the network is edited or\ndeleted.\nflag is 1 when the simulation reached the end time, 2 when it stopped by StopOnOutOfStep\n(output.outOfStep holds the stop), 0 when it stopped by TimeLimit and -1 when the solver\nstopped early; then the trajectories end at output.tEnd. When the first phase could not\nbe solved, they have no time points.\n\nThe trajectory is stored once, in the order of the variable map of the network\n(rm_variable, columns = rows of tab_variable): the states of the components with their\nlocal controllers, the states of the global controllers, the bus voltages, the inputs\nof the components and the inputs of the controllers. odeResults is a view of it per bus and component, and get_point gives\nthe values at a time, for example for net.get_sys({sim, t}). get_trajectory returns a\ntrajectory of the buses or components as a table (one column per bus or component, also\nrelative to the center of inertia) and plot_trajectory draws it, plot_spring_model an animated spring-mass\npicture of the phasors and plot_diagram a 3D network diagram of every output time.\nplot_pqv draws the path of each bus in (P, Q, |V|) as a 3D line over the output times.\nexport writes all trajectories as a table (CSV, Excel) or as a MAT-file.\njudge_out_of_step judges the rotor angles (stable, out of step).\n\n- `tab_variable` has one row per variable with Index, Kind (\"x\" | \"Vre\" | \"Vim\" | \"u\" |\n  \"uc\"), Role, Owner, Name, Label, Bus and Equilibrium: the leading rows of\n  net.get_variable_map() (its rows y and yc, the signals, are in tab_output).\n- In `rm_variable` the states and inputs of a tripped unit are NaN while it is tripped\n  (u of a component, uc of a local controller, u of a global controller). The inputs u\n  are the inputs applied to the components (steady value, outputs of the controllers and\n  event inputs), the inputs uc those applied to the controllers.\n- `rm_I` holds the columns B1 Ireal, B1 Iimag, B2 Ireal, ... They are not variables of the\n  map; odeResults.Bus(i).I and .PQ are made from them.\n- `rm_Icomponent` holds the current each component injects into its bus (its f_I at each\n  time, positive into the bus): Ireal, Iimag of each component in the order of sv_bus and\n  c_component. It is NaN while the component is tripped. At each time the currents of\n  the components of a bus add up to its rm_I (Y V) within the tolerance of the solver\n  (the residual of the current balance), except at a faulted bus during the fault: rm_I\n  there also holds the fault current.\n- `tab_output` has the rows y (outputs of the components) and yc (outputs of the\n  controllers) of the variable map, with the columns of tab_variable. `rm_output` holds\n  their trajectories, computed by the constructor from the output functions of the\n  blocks at each time (t from the start of the phase, as the solver). The outputs of a\n  tripped unit (its states are NaN) are NaN.\n- `odeResults` has the fields t (time [s], column), Bus(i).V (table Vreal, Vimag),\n  Bus(i).I (Ireal, Iimag), Bus(i).PQ (P, Q), Bus(i).Component(j).X (states, columns named\n  by sv_x), Bus(i).Component(j).U (inputs, columns named by sv_u),\n  Bus(i).Component(j).Y (outputs, columns named by sv_y) and Bus(i).Component(j).I (the\n  current of the component: Ireal, Iimag of rm_Icomponent). Bus(i) follows net.a_Bus and\n  Component(j) follows a_Component of the bus. The states and outputs of the local and\n  global controllers are in rm_variable and rm_output only.\n- `sct_branchY` holds the admittance matrix of each branch at each time of rv_t, in the\n  branch states of the phase (opened circuits, a fault inside the branch): iv_Y picks\n  the set of matrices c_Ybranch of each time. plot_diagram computes the branch flows\n  from it, so an opened branch carries no current (\"6open\") or the current of the\n  circuits left (\"3open\"), and a faulted branch the currents of its two ends into the\n  fault.\n- At a boundary between two phases the time appears twice in rv_t and odeResults: the\n  end of one phase, then the start of the next (see get_point).",
      "SeeAlso": [
        "SolverODE",
        "Scenario",
        "ResultBase",
        "PowerNetwork.get_variable_map"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.initialize();\nsc = net.add_scenario(\"fault\");\nsc.add_fault(\"B008\", [1, 1.05]);\n[result, flag] = net.simulate(\"fault\");\nr = result.odeResults;               % r.t, r.Bus(i).V, r.Bus(i).Component(j).X, ...\nx = result.get_point(2);             % all variables at t = 2, in variable-map order\ntab = result.get_trajectory(\"omega\");          % t and one column per generator\nresult.plot_trajectory(Quantity=\"omega\");       % the same columns as a figure\nresult.export(\"sim.mat\");\nverdict = result.judge_out_of_step();   % \"stable\" / \"out-of-step\" / \"incomplete\"\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 14,
        "Total": 22
      },
      "MethodCount": {
        "Own": 15,
        "Total": 19
      },
      "path": "./database/GUILDAsystem/ResultODE.js",
      "Image": ""
    },
    {
      "Name": "ResultOPF",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "ResultBase",
      "Superclasses": [
        "ResultBase"
      ],
      "Ancestors": [
        "ResultBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Result of net.calculate_optimal_powerflow.",
      "Desc": "Holds the optimal bus values, the injection of every connection into its bus (components\nand branch ends), the branch flows, the optimal cost, the Lagrange multipliers and the\nsolved optimization problem. The columns of the tables depend on the method: \"AC OPF\"\nhas voltages, P, Q and currents, \"DC OPF\" has Varg, V (= 1) and P, \"ELD\" has P only\n(branches are ignored and their values are NaN). It is built from data only: the\nsolution of SolverOPF.solve, a snapshot of the network (struct(net, false), kept as\nsct_network) and the solver information. It keeps no reference to the network, so a\nlater edit of the network does not change it; the OPF settings (tab_parameter.OPF /\n.operation) stay with the network. plot_dispatch draws the component outputs\nand, for \"DC OPF\" and \"AC OPF\", the bus voltages. export writes the bus, connection or\nbranch table (CSV, Excel). disp_summary (get_summary as a struct), disp_binding and get_lmp show what the solution\nis made of (the binding constraints and the nodal prices with their components);\nplot_lmp draws the prices on the network diagram, and plot_iteration the iterations of\nan \"AC OPF\" (sct_iteration) as a chart.\n\n- `tab_bus`: row names = bus tags. \"AC OPF\": Varg [rad], V [pu], P, Q (injections into\n  the network) [pu], Vphasor, Iphasor [pu]; \"DC OPF\": Varg, V, P; \"ELD\": P.\n- `tab_cub`: rows are the components of each bus (row name \"<component>\"), then the\n  branch ends at the bus (\"<branch>_<bus>\"). \"AC OPF\": Iphasor, P, Q [pu]; \"DC OPF\" and\n  \"ELD\": P (NaN for branch ends in \"ELD\").\n- The branch-end rows of `tab_cub` and `tab_branch` are computed from the solved bus\n  voltages (the problem has no branch variables).\n- `tab_branch`: row names = branch tags. \"from\" is br.a_Bus{1}, \"to\" is br.a_Bus{2};\n  values flow into the branch at each end, as in ResultPF.tab_branch. \"AC OPF\": Pfrom,\n  Qfrom, Pto, Qto, Ifrom, Ito, Ploss, Qloss; \"DC OPF\" and \"ELD\": Pfrom, Pto, Ploss (NaN\n  in \"ELD\").\n- `lambda` is the fifth output of solve of the Optimization Toolbox.\n  lambda.Constraints.balancedP_<bus> (balancedP in \"ELD\") is the change of the optimal\n  cost per unit of injection at the bus, so the nodal price of active power (cost per\n  unit of load) is -lambda.Constraints.balancedP_<bus>; balancedQ_<bus> (\"AC OPF\") is\n  the same for reactive power. Branch limits are in lambda.Constraints.Pmax_<branch>_<bus>\n  and Qmax_<branch>_<bus> (two values: P <= Pmax, -P <= Pmax), Imax_<branch>_<bus>,\n  Smax_<branch>_<bus>, VargMax1_<branch> and VargMax2_<branch>; the bound multipliers of\n  the buses and components are in lambda.Variables.<tag>.Lower/Upper.\n- `OPFprob` is the solved problem: built by SolverOPF.build_problem, or the Problem given to calculate_optimal_powerflow.\n- `sct_iteration` holds the iterations of fmincon (\"AC OPF\"), recorded at every run\n  through the OutputFcn of fmincon (next to PlotFcn): Iteration (1 x n, the iteration\n  numbers), Fval (objective), ConstrViolation (largest constraint violation) and X (a\n  struct by variable name of the problem, each variable's values as columns, one per\n  iteration). It is an empty struct for linprog and quadprog (\"ELD\", \"DC OPF\"), which\n  have no OutputFcn.\n- `sct_stability` holds the outer iterations of a stability-constrained \"AC OPF\"\n  (MinDampingRatio or MaxRealPart of calculate_optimal_powerflow): `tab_iteration`, one\n  row per outer iteration (Iteration, Cost, MinDampingRatio and MaxRealPart of the\n  eigenvalues of get_sys at its solution, CriticalMode: the modes that got linearized\n  constraints, those near the MinDampingRatio limit from the smallest damping ratio, then\n  those near the MaxRealPart limit only from the largest real part, Step: the trust region\n  [dP dV] [pu] of the next iteration, Flag: the exit flag of its OPF; an OPF that stopped\n  without a solution after the first iteration gives a last row with Cost, MinDampingRatio\n  and MaxRealPart NaN, and the result is then the solution of the row before it), and\n  `tab_mode`, the modes of the last solution (Eigenvalue,\n  Frequency [Hz], DampingRatio (NaN for a real mode), Owner: the tag of the component or\n  controller with the largest participation). It is an empty struct otherwise.\n- `sct_network` is the snapshot of the network at the calculation (struct(net, false)),\n  as in ResultPF; get_lmp reads its branch admittances and bus shunts, plot_lmp draws it.",
      "SeeAlso": [
        "SolverOPF",
        "ResultBase"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\n[result, flag] = net.calculate_optimal_powerflow(Method=\"AC OPF\");\nresult.r_cost            % optimal generation cost\nresult.tab_cub           % P, Q of each component and branch end\nprice = -result.lambda.Constraints.balancedP_B001;   % nodal price at bus B001\nG = result.plot_dispatch();     % bar charts of the solution (GraphChart)\nresult.export(\"opf.csv\", Table=\"cub\");\nresult.disp_summary();   % cost, generation, losses, binding constraints, price range\nsct = result.get_summary();  % the same values as a struct\nresult.get_lmp()         % nodal prices and their energy, congestion and loss components\nresult.plot_lmp();       % nodal prices on the network diagram\nG = result.plot_iteration();   % iterations of the AC OPF (GraphChart)\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 9,
        "Total": 17
      },
      "MethodCount": {
        "Own": 13,
        "Total": 16
      },
      "path": "./database/GUILDAsystem/ResultOPF.js",
      "Image": ""
    },
    {
      "Name": "ResultPF",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "ResultBase",
      "Superclasses": [
        "ResultBase"
      ],
      "Ancestors": [
        "ResultBase",
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Result of net.calculate_powerflow (its default Format \"GUILDAorigin\").",
      "Desc": "Holds the bus voltages, currents and power injections of the solution, the branch flows,\nthe violated operating limits and the voltages at each iteration (or time step of the\n\"dynamic\" method). It is built from data only: the solution table, the bus admittance\nmatrix, a struct snapshot of the network (struct(net, false), no handles) and the\nsolver information. It keeps no reference to the network, so a later edit of the\nnetwork does not change it. The plot_* methods draw the voltage profile, the branch\nflows, the convergence, the network diagram (2D or 3D), a black-and-white single-line diagram for papers and a spring-mass picture of the bus phasors; the disp_* methods print tables, and get_summary returns the values of disp_summary. export writes the bus or\nbranch table (CSV, Excel) or the iteration history (JSON for the GridSpring viewer).\n\n- `tab_bus` has the bus tags as row names.\n- `tab_branch` has the branch tags as row names. \"from\" is the first bus of the branch,\n  \"to\" the second. From, To: the tags of these end buses. Pfrom, Qfrom, Pto, Qto: power flowing into the branch at each end;\n  Ifrom, Ito: current phasors into the branch; Ploss, Qloss: losses of the branch (sum\n  of both ends). The admittance of each branch is the field cm_Y of the branch in the\n  snapshot (Branch.struct adds it from get_admittance_matrix), so every branch class,\n  also one of your own, gets its flows.\n- `cm_Vhistory` has one column per iteration, or per ODE step (\"dynamic\").\n- `tab_violation` records the operating limits (tab_parameter.operation of the\n  snapshot) that the solution violates by more than Tolerance; the power flow itself\n  never applies them, and a violation gives no warning or error. One row per violated\n  limit, 0 rows when none (or when the calculation did not converge):\n  - Class: \"Bus\", \"Component\" or \"Branch\"; Object: its tag.\n  - Limit: the violated limit, e.g. \"Vmin\", \"Vmax\" (bus), \"Pmin\", \"Pmax\", \"Qmin\",\n    \"Qmax\" (component), \"Pmax\", \"Qmax\", \"Smax\", \"Imax\", \"Vargmax\" (branch).\n  - Value: the solution value (bus V; component P, Q as initialize gives them; for a\n    branch the larger of its two ends of |P|, |Q|, |S|, |I|, and |Varg_from - Varg_to|).\n  - Bound: the limit; Excess: |Value - Bound|.\n- `tab_PFcondition`, `cm_Y` and `sct_network` are the data the result was built from.",
      "SeeAlso": [
        "SolverPF",
        "ResultBase",
        "PowerNetwork.calculate_powerflow"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\n[result, flag, output] = net.calculate_powerflow();\nresult.tab_bus           % Varg, V, P, Q, Vphasor, Iphasor of each bus\nresult.tab_branch        % flows and losses of each branch\nresult.tab_violation     % violated operating limits (0 rows when none)\nresult.disp_summary();           % outcome, sums, |V| range, violations\nsct = result.get_summary();      % the same values as a struct\nresult.disp_bus(Unit=\"SI\");      % bus table in kV, MW, Mvar\nresult.disp_branch(Sort=\"loss\"); % branch flows, largest loss first\nresult.disp_violation();         % violated operating limits by kind\nresult.plot_voltage();           % voltage profile with Vmin / Vmax\nresult.plot_branch(Quantity=\"loading\");   % |S| / Smax of each branch\nresult.plot_convergence(Bus=\"B014\");       % largest residual and |V| per iteration\nresult.plot_diagram(BusColorMode=\"V\", ColorMode=\"none\");  % buses colored by |V|, P flow dots\nresult.plot_single_line_diagram();  % black-and-white single-line diagram for a paper\nresult.plot_spring_model();      % spring-mass picture of the bus phasors\nresult.export(\"pf.csv\", Table=\"branch\");\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 8,
        "Total": 16
      },
      "MethodCount": {
        "Own": 21,
        "Total": 25
      },
      "path": "./database/GUILDAsystem/ResultPF.js",
      "Image": ""
    },
    {
      "Name": "Scenario",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary, LayerPackage",
      "Superclasses": [
        "auxiliary",
        "LayerPackage"
      ],
      "Ancestors": [
        "auxiliary",
        "LayerPackage",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": true,
      "Hidden": false,
      "Summary": "Simulation scenario: the time, the timed disturbances and a description of one time simulation.",
      "Desc": "A scenario holds its disturbances as events (a_Event, in the order added), and the\nsimulation time (Time, default [0, 10]) and a description. It holds data only, no\nfunction handles and no settings of the solver (GUILDA.setting, or the Name-Value options\nof net.simulate).\n\nEach event is an object of a subclass of EventBase: add_fault (EventFault), add_trip\n(EventTrip), add_open_branch (EventOpenBranch), add_offset (EventOffset) and add_input\n(EventInput) add one and return it. Change an event with `ev.edit(Name=Value)` (the\noptions of its add_* method): all events are checked again, and a failing edit is\nundone. remove_event(tag) removes events. The three tables are built from the events:\n\n- tab_event: faults and parallel events (trips, branch openings), one row per change of\n  the state of one target (Tag, Target, Time, Status, Point). A fault has two rows per\n  target that share its tag: the start and the return to \"none\". A trip or opening has\n  one row per target: it lasts to the end of the simulation. The tags are Fault001,\n  Fault002, ... and Parallel001, ...; they are given by the scenario, not by the user.\n- tab_offset: offsets of the states at one time (Tag, TimeSpan, OffsetUnit, OffsetState,\n  OffsetValue).\n- tab_input: inputs added to a component over a time span (Tag, TimeSpan, InputUnit,\n  InputName, InputValue, InputMethod).\n\nA scenario is a child of one network: `sc = net.add_scenario(tag)` creates it\n(net.a_Scenario, sc.a_PowerNetwork) and `net.remove_scenario(tag)` deletes it. Its tag\nshares the name space of the buses, branches and global controllers of the network: a\ntag in use gets a number suffix (LayerPackage). `net.add_scenario(tag, From=sc)` copies\nthe events and settings of another scenario, of this or another network, and\n`net.add_scenario(tag, Event={...})` copies events made with their constructors.\nEvents refer to buses, branches, components and controllers by tag. All events are\nchecked when an event is added or edited, and again at the start of each simulation against\nthe network as it is then. Scenarios are not model data: adding, renaming, editing or\nremoving them makes nothing stale (log_edit does nothing).\n\nRun it by its tag with `net.simulate(tag)` (over Time) or `net.simulate(tag, Time=[t0,\ntend], Name=Value)`: the simulation is split into phases where the state of the\ndisturbances does not change.\n\nEvents:\n\n| Kind | Tag | Target | Status | Point |\n|---|---|---|---|---|\n| fault | Fault<n> | bus | \"BG\", then \"none\" at the end | NaN |\n| fault | Fault<n> | branch | \"3LG\" (one circuit) or \"6LG\" (all circuits), then \"none\" | 0 < Point < 1 |\n| parallel | Parallel<n> | component, global or local controller | \"open\" | NaN |\n| parallel | Parallel<n> | branch | \"3open\" (one circuit) or \"6open\" (all circuits) | NaN |\n\n- The state of a target at time t is the Status of its last row with Time <= t; faults\n  and parallel events are counted apart. Without rows a target is not faulted (\"none\")\n  and connected. At one time the end of one fault is applied before the start of the\n  next, so two faults of one target may touch ([1 2] and [2 3]); two faults of one\n  target that overlap, and two parallel events of one target, are an error\n  (GUILDA:Scenario:OverlappingEvents).\n- Point is the position of a branch fault from the from end (0) to the to end (1). A\n  fault at an end of a branch is a fault of the bus (add_fault(bus, ...)).\n- A fault end at or after the end of the simulation (Inf too) keeps the state to the\n  end of the run: the rows stay in the table, and Time of a later run may reach them.\n- The admittance matrix of each phase is net.get_admittance_matrix(BranchStatus=...) of\n  the branch states of the phase (the table of Branch.get_admittance_matrix: a branch\n  with a fault and an opening at once gets one combined matrix). A branch opened with\n  \"6open\" is left out of the matrix; a bus fault holds the bus voltage at 0. Opening\n  branches, or grounding all their circuits (\"6LG\"), so that a part of the network is\n  left without any component is an error (GUILDA:PowerNetwork:OpenBranchIsland). A part\n  with components is simulated as an island; a constant-power load cut off from all\n  generators usually makes the phase fail (flag = -1).\n- A tripped component, global controller or local controller has NaN states in the\n  result from its trip to the end of the run. An input whose source is tripped (the observed component, the local\n  controller that drives it, or a global controller) takes its equilibrium value, as if\n  the source were not connected; the other sources of the input stay. A tripped AVR thus\n  keeps the field voltage of the generator at its equilibrium; a loss of excitation is\n  modelled by an input, e.g. add_input(gen, \"Vfield\", -Vfield0, [t1, t2]). The local\n  controllers of a tripped local controller keep running.\n\nOffsets and inputs:\n\n- An offset applies at its time (TimeSpan t_start). An input lasts from t_start to t_end\n  (TimeSpan [t_start, t_end], t_start < t_end).\n- An input value is a constant (one number per input name, or one for all) or a time\n  series [t, v_1, ..., v_n] (or a table with the variables Time and the input names), t\n  from t_start, starting at 0 and increasing. The series is interpolated by InputMethod:\n  \"zoh\" (hold the last point), \"foh\" (linear, the default) or \"spline\"; after its last\n  point it keeps the last value. A \"zoh\" series with many points makes the run slower.\n- Offsets and inputs on the same unit are summed over the active disturbances.\n\nThe tag of an event names its column in output.phases. It is unique within the\nscenario; t1, t2, Properties, Row, Variables, an empty tag, NoAction followed by digits,\nand Fault or Parallel followed by digits are reserved for offsets and inputs.",
      "SeeAlso": [
        "PowerNetwork.add_scenario",
        "PowerNetwork.remove_scenario",
        "PowerNetwork.simulate",
        "ResultODE",
        "EventBase"
      ],
      "Examples": "A fault on bus B008 for 70 ms, then the branch EL003 opened until the end:\n\n```matlab\nnet = network.IEEE14bus();\nnet.initialize();\nsc = net.add_scenario(\"case1\", Time=[0, 20], Description=\"fault B008, EL003 opened\");\nev = sc.add_fault(\"B008\", [0.10, 0.17]);        % EventFault, tag Fault001\nsc.add_open_branch(\"EL003\", 0.17);              % Parallel001\n[result, flag] = net.simulate(\"case1\", Progress=\"none\");\nsc.tab_event                                    % three rows\nev.edit(Time=[0.10, 0.20]);                     % a longer fault\nsc.remove_event(ev.s_tag);\n```\n\nOne circuit of the branch EL003 grounded at 30 % from its from end, then that circuit\nopened (EL003 has the default 2 circuits):\n\n```matlab\nsc3 = net.add_scenario(\"case3\", Time=[0, 20]);\nsc3.add_fault(\"EL003\", [0.10, 0.17], Status=\"3LG\", Point=0.3);   % Fault001\nsc3.add_open_branch(\"EL003\", 0.17, Status=\"3open\");              % Parallel001\n[result, flag] = net.simulate(\"case3\", Progress=\"none\");\n```\n\nA trip of the AVR of a generator: the field voltage stays at its equilibrium. A loss of\nexcitation is an input that cancels it:\n\n```matlab\nnet68 = network.IEEE68bus();\ngen = net68.a_Bus{1}.a_Component{1};\nsc4 = net68.add_scenario(\"avr\", Time=[0, 10]);\nsc4.add_trip(gen.avr.s_tag, 1);                                % the AVR\nVfield0 = gen.rv_Uequilibrium(gen.sv_u == \"Vfield\");\nsc4.add_input(gen.s_tag, \"Vfield\", -Vfield0, [1, 10]);          % field voltage 0\n```\n\nOther disturbances, and a copy for another network:\n\n```matlab\nsc2 = net.add_scenario(\"steps\");\nsc2.add_offset(\"B001SG1\", \"delta\", 0.1, 0);\nsc2.add_input(\"B002SG1\", \"Pmech\", [0, 0; 0.5, 0.005], [1, 1.5]);   % ramp, then held\nresult = net.simulate(sc2.s_tag);\nother = network.IEEE14bus();\nother.add_scenario(\"case1\", From=sc);         % sc stays in net\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [
        {
          "Name": "a_PowerNetwork",
          "Type": "PowerNetwork"
        },
        {
          "Name": "a_Event",
          "Type": "EventBase"
        }
      ],
      "PropertyCount": {
        "Own": 11,
        "Total": 14
      },
      "MethodCount": {
        "Own": 20,
        "Total": 28
      },
      "path": "./database/GUILDAsystem/Scenario.js",
      "Image": ""
    },
    {
      "Name": "SolverCPF",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/SolverCPF.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Solver of the continuation power flow (CPF).",
      "Desc": "Starting from the equilibrium found by net.initialize, it scales the loads of LoadBus by\n(1 + lambda) and traces the power flow solution with a predictor-corrector method past\nthe maximum loading point (the nose of the PV curve). net.solver_CPF holds one. The\nsettings are the ContinuationPowerFlow section of GUILDA.setting\n(GUILDA.config(\"ContinuationPowerFlow\")); the solver keeps only the condition of its\nnetwork, LoadBus (kept between runs). Name-Value options of\nnet.calculate_continuation_powerflow override both for that call only; neither the\nsolver nor the settings file is changed: the call passes its options as they are, and\nthe settings without an option (CorrectorMaxIteration, CorrectorStepSize, Increment) are\nread from GUILDA.config where solve uses them. Results are returned as a ResultCPF.\n\n- The power the components of the `LoadBus` buses draw is multiplied by (1 + lambda).\n- `StepSize` multiplies the tangent at the first step and the secant from the previous\n  step afterwards. The trace stops before `MaxIteration` when lambda falls below 0 after\n  the nose.\n- With `UseInternalState` true, the generator powers follow their state equations\n  (getCompPQ) and all loads are scaled; when false, the components inject their\n  equilibrium powers. True stops with GUILDA:build_layout:MissingGetCompPQ if a component\n  has no getCompPQ.\n- `Limits` applies the operating limits (tab_parameter.operation) along the path; Inf\n  and NaN limits are none. \"Q\": a PV bus whose generators (the components with Q = NaN\n  in powerflow) leave the sum of their Qmin/Qmax becomes a PQ bus with Q fixed at that\n  bound (never back to PV; not with UseInternalState, not the slack bus). \"V\": the trace\n  stops where the voltage of a bus reaches Vmin or Vmax. \"S\": it stops where the larger\n  |S| of the two ends of a branch reaches Smax. The switches are in\n  ResultCPF.tab_switch, the stop in ResultCPF.tab_stop; nothing is written to the model.\n- The Newton-Raphson corrector takes CorrectorMaxIteration and CorrectorStepSize, and\n  the predictor and the corrector the numerical Jacobian step Increment, from the\n  ContinuationPowerFlow section of GUILDA.setting.\n- Each Name-Value option of net.calculate_continuation_powerflow is also the key of the\n  setting (LoadBus: the property).\n- After the trace, the operating point of every step (states and inputs of the components\n  and local controllers for the bus injection of the step, split as net.initialize\n  splits a power flow solution) and the voltage stability information (smallest singular\n  value of the power flow Jacobian at each step, weak buses at the nose, loading margin)\n  are computed into the ResultCPF (tab_variable, rm_variable, cm_Icomponent,\n  rv_sigmaMin, tab_weakbus, r_marginP; see ResultCPF). Only pure model functions\n  (get_equilibrium, f_Y) are called for them.\n- `PlotFcn` (live display): \"pvcurve\" draws |V| of every bus against lambda and extends\n  the lines at each step (one reused figure); a function handle is called at the\n  starting point (\"init\"), each step (\"iter\") and the end (\"done\") as\n  stop = f(x, optimValues, state), x the complex bus voltages, optimValues.iteration\n  (step), .lambda and .correctorIterations; a true stop ends the path there.\n  result.plot_pvcurve() draws the PV curves after the analysis.",
      "SeeAlso": [
        "ResultCPF",
        "PowerNetwork.calculate_continuation_powerflow"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.initialize();\nnet.solver_CPF.LoadBus = [\"B009\",\"B014\"];       % condition of this network, kept between runs\nresult = net.calculate_continuation_powerflow();\nresult = net.calculate_continuation_powerflow(StepSize=0.1, Verbose=true);   % this call only\nresult = net.calculate_continuation_powerflow(Limits=\"all\");   % Q limits, stop at V / S limits\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 1
      },
      "MethodCount": {
        "Own": 11,
        "Total": 12
      },
      "path": "./database/GUILDAsystem/SolverCPF.js",
      "Image": ""
    },
    {
      "Name": "SolverLIN",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@SolverLIN/SolverLIN.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Connector of the linearization (get_sys of every layer).",
      "Desc": "get_sys (PowerSystemModel.get_sys) collects the linear blocks of the model objects of a\nlayer (get_linear_matrix) and builds the port of the layer from its variable map; solve\nconnects them along the variable map and returns the connected descriptor model (the DAE), from which get_sys\nmakes a ResultLIN. reduce eliminates the algebraic variables of a DAE (the bus voltages\nof the network): the model of Type \"ODE\". The connector reads only its arguments: no\nnetwork and no model object. It holds no settings: the defaults of the options of\nget_sys (Type, Port, PlotFcn) are the ApproximateLinearization section of GUILDA.setting\n(GUILDA.config(\"ApproximateLinearization\")), and an option of a call overrides them for that call\nonly.\n\n- `Type` is the model of the network: \"ODE\" (the DAE with the bus voltages eliminated,\n  SolverLIN.reduce) or \"DAE\" (the connected model, with the voltages as algebraic\n  variables and a singular E).\n- The point (the first argument of get_sys, not a setting) is [] for the equilibrium\n  (set by net.initialize, the default); a vector of the values in the order of the\n  leading rows of layer.get_variable_map() (x, Vre, Vim, u, uc; for a controller x, Vre, Vim,\n  uc; point_vector), every value used as given; or {sim, t}: the state of the simulation result sim at time t\n  (sim.get_point(t); at a phase boundary the value after the event, or\n  {sim, t, \"before\"} for the value before it). {sim, rv_t} with several times, or a\n  matrix with one point per column, gives one time section per time or column\n  (ResultLIN.rv_t, ResultLIN.Index). It sets the variables only: the\n  admittance matrix stays the one of the model, also at a time inside a fault. The model\n  is not changed.\n- `Port` sets how each bus is written in the DAE (get_ss(\"DAE\") and get_sys with Type\n  \"DAE\"): the bus variables v and the current balance w. \"PI\": v = [theta, V],\n  w = [P, Q/V]; \"PQ\": v = [theta, log V], w = [P, Q]; \"I\": v = [Vre, Vim],\n  w = [-Iim, Ire]. The computation stays in Vre, Vim; the port changes the result only.\n  \"ODE\" does not use it.\n- `Form` is the view of the matrices (ResultLIN.Form): \"descriptor\", \"absorbed\" or\n  \"hessian\", the energy-function form that get_sys builds from get_hessian of the\n  devices and solve assembles with the network part (network, Port \"PI\" or \"PQ\").\n- `PlotFcn` (live display) is \"none\" only (tools.check_plotfcn);\n  result.plot_eigenvalue() draws the eigenvalue map.",
      "SeeAlso": [
        "ResultLIN",
        "PowerSystemModel.get_sys"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.initialize();\nres = net.get_sys();                 % Type of GUILDA.setting (\"ODE\")\nres = net.get_sys(Type=\"DAE\");       % this call only\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 0,
        "Total": 0
      },
      "MethodCount": {
        "Own": 5,
        "Total": 6
      },
      "path": "./database/GUILDAsystem/SolverLIN.js",
      "Image": ""
    },
    {
      "Name": "SolverODE",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/SolverODE.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Solver of the time simulation (net.simulate).",
      "Desc": "net.solver_ODE holds one. It holds no settings: net.simulate passes its Name-Value\noptions, whose defaults are the TimeSimulation section of GUILDA.setting, as they are to\nsolve; neither the solver nor the settings file is changed. The solver is purely\nnumerical: net.build_simulation_data gathers the data of a run (the blocks with their\nfunction handles, the variable and connection maps, the admittance, the equilibrium, the\nphases with the disturbances as positions, the initial value) and solve reads only that\ndata, never the network or its models. It returns the raw trajectories, from which\nnet.simulate makes a ResultODE or the struct of Format=\"struct\". The DAE of the network\nis integrated phase by phase: a phase is a time interval in which the set of active\ndisturbances (Scenario) does not change. Each phase is solved with the MATLAB ode\nobject (Solver, Tolerance, AbsoluteTolerance, MaxStep, InitialStep, SeparateComplexParts).\n\n- Tolerance and AbsoluteTolerance are the RelativeTolerance and AbsoluteTolerance of ode\n  (RelTol and AbsTol of odeset).\n- MaxStep and InitialStep are set in the SolverOptions of the ode object when they are\n  not NaN; NaN keeps the default of the Solver. Other options of the solver are not\n  accepted.\n- `TimeLimit` is checked at each solver step. When it is exceeded, the simulation stops\n  at the time reached, and the result has flag = 0 (\"stopped by TimeLimit\").",
      "SeeAlso": [
        "ResultODE",
        "Scenario",
        "PowerNetwork.simulate"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.initialize();\nsc = net.add_scenario(\"fault\");\nsc.add_fault(\"B008\", [1, 1.05]);\nresult = net.simulate(\"fault\", Solver=\"ode23t\", Progress=\"none\");  % this call only\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 1,
        "Total": 1
      },
      "MethodCount": {
        "Own": 17,
        "Total": 18
      },
      "path": "./database/GUILDAsystem/SolverODE.js",
      "Image": ""
    },
    {
      "Name": "SolverOPF",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/SolverOPF.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Solver of the optimal power flow (net.calculate_optimal_powerflow).",
      "Desc": "net.solver_OPF holds one. It stores no settings: the settings of each run are the\nOptimalPowerFlow section of GUILDA.setting (GUILDA.config(\"OptimalPowerFlow\")), with the\nName-Value options of the call applied to that call only (the arguments block of\nPowerNetwork.calculate_optimal_powerflow), which passes its options as they are;\noptimoption reads the settings without an option (<Solver><option>) from GUILDA.config.\nCost, Constraint, DefaultCost and ReferenceBus are options of the call only. The solver\nkeeps only the warm start.\nIt never reads the network: net.build_opf_problem collects the data of the buses,\ncomponents and branches from tab_parameter as three tables (tags as row names),\nresolves ReferenceBus \"auto\" to a bus tag and passes the base (baseMVA, Hz);\nbuild_problem builds the optimization problem from these data. net.calculate_optimal_powerflow\nruns three stages: net.build_opf_problem builds the problem, solve solves the built (or\ngiven) problem from its initial point without building it again and returns the\nsolution, and the caller builds the ResultOPF.\n\n- `Method`: \"ELD\" (economic load dispatch, branches ignored), \"DC OPF\" (DC approximation:\n  |V| = 1, no losses, b_ij = 1/(X*tap) as in MATPOWER) or \"AC OPF\" (AC power flow\n  equations). The variables are those of the buses (Varg and V; Varg in \"DC OPF\") and\n  the components (P and Q; P in \"DC OPF\" and \"ELD\"). The flows at the branch ends are\n  expressions of the bus voltages (I = -Y*V, S = V*conj(I) with the 2x2 admittance\n  matrix of each branch), used in the power balance P_i(V, Varg) = sum of the component\n  P of bus i (Q likewise) and in the branch limits Pmax_, Qmax_, Imax_, Smax_ (each end)\n  and VargMax1_, VargMax2_.\n- `Solver` \"auto\" uses the solver that solve chooses for the problem: linprog, quadprog\n  or fmincon. Tolerance is the OptimalityTolerance of the solver; Verbose=true passes\n  Display=\"iter\" to the solver, Verbose=false Display=\"none\".\n- `PlotFcn` (live display, fmincon only): display keys of the PlotFcn option of fmincon,\n  key = name without \"optimplot\" (\"fval\", \"constrviolation\", \"fvalconstr\",\n  \"firstorderopt\", \"stepsize\", \"funccount\", \"x\"), or a function handle\n  stop = f(x, optimValues, state) passed to fmincon as it is. linprog and quadprog\n  (\"ELD\", \"DC OPF\") have no PlotFcn: a value other than \"none\" stops with\n  GUILDA:SolverOPF:PlotFcnUnsupported. result.plot_dispatch() draws the result.\n- `Cost` and `Constraint` are function handles @(v, p) applied to the whole network.\n  v holds the variables by tag: v.Component.(tag).P, .Q (\"AC OPF\");\n  v.Bus.(tag).Varg, .V (\"AC OPF\"); v.Branch.(tag).Pfrom, .Pto, .Vargfrom, .Vargto\n  (+ Qfrom, Qto, Ifrom_re, Ifrom_im, Ito_re, Ito_im, Vfrom, Vto in \"AC OPF\"; flows\n  into the branch). Bus and branch variables do not exist in \"ELD\". p holds p.Method\n  and p.base (baseMVA, Hz). Cost returns a scalar added to the objective; Constraint\n  returns struct(name1, constraint1, ...), and field <name> becomes\n  prob.Constraints.<name> and result.lambda.Constraints.<name>.\n- The \"AC OPF\" starts from the bus voltages of the last solved \"AC OPF\" when the call\n  option WarmStart of calculate_optimal_powerflow is true and it was solved for the same\n  bus tags (in the same order), and from the flat start otherwise: angle 0 and\n  magnitude 1, with the set V at PV and slack buses and the set angle at the slack bus.\n  build_problem returns the flat start; solve applies the warm start to the bus and\n  branch-end values of the initial point. \"DC OPF\" starts from the angles of the same\n  start. A given InitialPoint is used as it is. net.reset_solver() discards the\n  kept voltages.\n- The problem is built at every call (no cache); net.build_opf_problem builds the same\n  problem without solving it.\n- disp_formulation shows the general form of the problem of each Method (objective,\n  constraints and their names), with the counts of a built problem.\n- A default limit of one object is removed by setting it to Inf (-Inf for a lower\n  bound) in its tab_parameter.operation: Vmin, Vmax (bus); Pmin, Pmax, Qmin, Qmax\n  (component); Pmax, Qmax, Vargmax, Imax, Smax (branch, where NaN also means none).",
      "SeeAlso": [
        "ResultOPF",
        "PowerNetwork.calculate_optimal_powerflow",
        "PowerNetwork.build_opf_problem"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nresult = net.calculate_optimal_powerflow(Method=\"DC OPF\");            % this call only\nresult = net.calculate_optimal_powerflow(Method=\"ELD\", Verbose=true);\nresult = net.calculate_optimal_powerflow(Method=\"DC OPF\", ReferenceBus=\"none\");   % no fixed angle\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 2,
        "Total": 2
      },
      "MethodCount": {
        "Own": 12,
        "Total": 13
      },
      "path": "./database/GUILDAsystem/SolverOPF.js",
      "Image": ""
    },
    {
      "Name": "SolverPF",
      "Origin": "System",
      "Folder": "_GUILDAsystem/_auxiliary",
      "Category": "",
      "Type": "auxiliary",
      "Model": "",
      "Parent": "auxiliary",
      "Superclasses": [
        "auxiliary"
      ],
      "Ancestors": [
        "auxiliary",
        "handle"
      ],
      "Subclasses": [],
      "Package": "",
      "File": "_GUILDAsystem/_auxiliary/@SolverPF/SolverPF.m",
      "Line": 1,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "Summary": "Solver of the power flow calculation (net.calculate_powerflow).",
      "Desc": "net.solver_PF holds one. It does only the numerics: solve takes the bus admittance\nmatrix, the power flow conditions of the buses and the settings of the run, builds the\npower equations and runs the Method class. It never reads the network:\nnet.calculate_powerflow selects the slack bus, assembles the inputs, notifies a failure\n(WhenFailed) and builds the output in the requested Format. It stores no numerical\nsettings: the settings of each run are the PowerFlowCalculation section of\nGUILDA.setting (GUILDA.config(\"PowerFlowCalculation\")), with the Name-Value options of\nthe call applied to that call only (the arguments block of\nPowerNetwork.calculate_powerflow).\n\n- `Solver`: the algorithm that solves the power equations (see the table). Every\n  solver except \"fsolve\" runs on MATLAB alone; \"fsolve\" needs Optimization Toolbox.\n\n  | Solver                | Class (algorithm)                                       | MaxIteration NaN (auto)    |\n  |-----------------------|---------------------------------------------------------|----------------------------|\n  | \"newton\"              | MethodNewtonRaphson (analytic Jacobian)                 | 50                         |\n  | \"gradient\"            | MethodGradient (theta += alpha*dP, V += alpha*dQ./V)    | 1e6                        |\n  | \"levenberg-marquardt\" | MethodLevenbergMarquardt (analytic Jacobian)            | 100                        |\n  | \"fsolve\"              | MethodFsolve (fsolve, analytic Jacobian)                | 400                        |\n  | \"dynamic\"             | MethodDynamic (virtual bus dynamics, ode15s)            | not used                   |\n\n- `Tolerance` [pu]: every method converges when the largest P/Q mismatch is at most\n  Tolerance (\"newton\", \"levenberg-marquardt\" and \"fsolve\" also count the set |V| and\n  slack angle residuals). \"fsolve\" also passes Tolerance^2 as FunctionTolerance and OptimalityTolerance of fsolve and\n  checks the mismatch after fsolve stops. \"dynamic\" tightens its ODE tolerances with it.\n- `WarmStart`: true starts from the last converged solution, kept by the solver, when\n  it was solved for the same bus tags (in the same order); false, a different bus list\n  or no kept solution is the flat start: angle 0 and magnitude 1, with\n  the set V at PV and slack buses and the set angle at the slack bus. \"gradient\" and\n  \"dynamic\" always start the fixed values (slack angle and voltage, PV voltages) at\n  their set values. A run from the kept solution that ends with flag 0 (MaxIteration) or\n  -2 (diverged) is solved once more from the flat start (a kept solution near the nose\n  point can make Newton's method diverge on a much lighter load). flag, output,\n  cm_Vhistory and rv_step are those of the second run, output.message ends with a\n  sentence that says so, and Verbose=true prints one line; there is no warning. flag -1\n  (stopped by PlotFcn) is not retried. The kept solution changes only on convergence.\n- The optional columns `V0` [pu] and `Varg0` [rad] of the power flow conditions (the 3rd\n  argument of solve) give the initial voltage V0.*exp(1j*Varg0), before WarmStart and the\n  flat start; both or neither (GUILDA:SolverPF:InvalidInitialVoltage), finite values only.\n- The solver keeps only the last converged solution and its bus tags (the warm start).\n  The power equations are built at every call. net.reset_solver() discards the kept\n  solution.\n- Settings of one method, named <Solver><option>: NewtonStepSize (StepSize of\n  MethodNewtonRaphson), GradientStepSize (alpha of MethodGradient; NaN uses\n  0.5/(max|Y_ii|*Vmax^2), Vmax the largest set bus voltage or 1), FsolveUseParallel and\n  FsolveMaxFunctionEvaluations (fsolve; NaN keeps the fsolve default). NaN is the\n  automatic value of every setting that has one (MaxIteration too).\n  \"gradient\" converges linearly: it needs thousands of iterations on 10-bus networks.\n- For \"newton\", a singular Jacobian (an island without a slack bus) gives minimum norm\n  steps. A non-slack bus without branches has no determined voltage: every method\n  returns flag -2 without solving. \"gradient\" fixes the slack angle and voltage and the\n  PV voltages, and updates the angle only at PV buses.\n- `Verbose` (Display \"iter\" or \"none\" of the Method class): true prints one line per iteration for \"newton\", \"gradient\"\n  and \"levenberg-marquardt\" (the fsolve display for \"fsolve\"), and the final message.\n- Outputs of solve: the complex bus voltages, flag, output, the voltages at each\n  iteration (cm_Vhistory) and the iteration numbers or virtual times (rv_step).\n- flag: 1 converged, 0 MaxIteration reached (for \"dynamic\", its virtual time limit),\n  -1 stopped by PlotFcn, -2 diverged or no solution found; the Method classes set flag\n  and output (see MethodBase).\n- `PlotFcn` (live display, every Solver): \"residual\" draws one bar per power equation\n  (two per bus: P, or the angle at the slack bus; Q, or |V| at PV and slack buses) with\n  its |residual| at the iterate, on a log scale with Tolerance as a line, in one reused\n  figure updated during the iterations (\"dynamic\": along the virtual time). A function\n  handle is called at every iterate as stop = f(x, optimValues, state): x the complex\n  bus voltages, optimValues.iteration, .fval (residuals), .residual (largest |residual|)\n  and, for \"dynamic\", .time (virtual time); state \"init\", \"iter\" or \"done\". A true stop\n  ends the calculation with flag -1. \"none\" leaves the calculation as it is.\n- solve takes the Name-Value options of net.calculate_powerflow as they are (Solver,\n  Tolerance, MaxIteration, Verbose, WarmStart, PlotFcn, Progress). The settings without an option\n  (<Solver><option>) are read from GUILDA.config where they are used.\n- `Progress` (progress display of the iteration, through f_iter of the Method class next\n  to PlotFcn): \"dialog\", \"disp\", \"none\", true or false (see ProgressGUILDA), or a\n  ProgressGUILDA made by the caller (net.calculate_powerflow makes one before it gathers\n  the data). A struct without the field shows nothing (\"none\").",
      "SeeAlso": [
        "ResultPF",
        "PowerNetwork.calculate_powerflow",
        "MethodNewtonRaphson",
        "MethodGradient",
        "MethodLevenbergMarquardt",
        "MethodFsolve",
        "MethodDynamic",
        "MethodBase"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nres = net.calculate_powerflow();                                       % GUILDA.setting\nres = net.calculate_powerflow(Solver=\"dynamic\", Verbose=true);         % this call only\nres = net.calculate_powerflow(WarmStart=false);                        % flat start\n% the solver alone: admittance matrix, conditions and settings assembled by the caller\ntab = tools.vcellfun(@(b) b.get_pf_condition, net.a_Bus);\ntab_Y = net.get_admittance_matrix;\nsct = struct(\"Solver\",\"newton\",\"Tolerance\",1e-8,\"MaxIteration\",NaN,\"Verbose\",false, ...\n    \"WarmStart\",false,\"PlotFcn\",\"none\");\ncv_V = net.solver_PF.solve(tab_Y{:,:}, tab, sct);\ntab.V0 = abs(cv_V); tab.Varg0 = angle(cv_V);                         % initial voltage\ncv_V = net.solver_PF.solve(tab_Y{:,:}, tab, sct);\n```",
      "Citations": "",
      "Deprecated": "",
      "Documented": true,
      "References": [],
      "PropertyCount": {
        "Own": 2,
        "Total": 2
      },
      "MethodCount": {
        "Own": 4,
        "Total": 5
      },
      "path": "./database/GUILDAsystem/SolverPF.js",
      "Image": ""
    }
  ],
  "tree": [
    {
      "Name": "System",
      "Kind": "folder",
      "Path": "_GUILDAsystem",
      "Children": [
        {
          "Name": "+tools",
          "Kind": "folder",
          "Path": "_GUILDAsystem/+tools",
          "Children": [
            {
              "Name": "arrayfun.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/arrayfun.m",
              "Children": []
            },
            {
              "Name": "cell2var.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/cell2var.m",
              "Children": []
            },
            {
              "Name": "cellfun.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/cellfun.m",
              "Children": []
            },
            {
              "Name": "check_plotfcn.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/check_plotfcn.m",
              "Children": []
            },
            {
              "Name": "complex2matrix.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/complex2matrix.m",
              "Children": []
            },
            {
              "Name": "complex2vec.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/complex2vec.m",
              "Children": []
            },
            {
              "Name": "darrayfun.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/darrayfun.m",
              "Children": []
            },
            {
              "Name": "dcellfun.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/dcellfun.m",
              "Children": []
            },
            {
              "Name": "delete_layers.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/delete_layers.m",
              "Children": []
            },
            {
              "Name": "distribute_power.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/distribute_power.m",
              "Children": []
            },
            {
              "Name": "fd_jacobian.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/fd_jacobian.m",
              "Children": []
            },
            {
              "Name": "gui_palette.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/gui_palette.m",
              "Children": []
            },
            {
              "Name": "harrayfun.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/harrayfun.m",
              "Children": []
            },
            {
              "Name": "hcellfun.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/hcellfun.m",
              "Children": []
            },
            {
              "Name": "heaviside.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/heaviside.m",
              "Children": []
            },
            {
              "Name": "is_ui_container.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/is_ui_container.m",
              "Children": []
            },
            {
              "Name": "l2norm.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/l2norm.m",
              "Children": []
            },
            {
              "Name": "layout_convert_columns.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/layout_convert_columns.m",
              "Children": []
            },
            {
              "Name": "layout_mustBePath.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/layout_mustBePath.m",
              "Children": []
            },
            {
              "Name": "layout_parse_path.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/layout_parse_path.m",
              "Children": []
            },
            {
              "Name": "layout_place_buses.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/layout_place_buses.m",
              "Children": []
            },
            {
              "Name": "linear_modes.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/linear_modes.m",
              "Children": []
            },
            {
              "Name": "matrix_polar_transform.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/matrix_polar_transform.m",
              "Children": []
            },
            {
              "Name": "mustBeKeyOf.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/mustBeKeyOf.m",
              "Children": []
            },
            {
              "Name": "network_to_mpc.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/network_to_mpc.m",
              "Children": []
            },
            {
              "Name": "next_tag_number.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/next_tag_number.m",
              "Children": []
            },
            {
              "Name": "require_toolbox.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/require_toolbox.m",
              "Children": []
            },
            {
              "Name": "resolve_options.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/resolve_options.m",
              "Children": []
            },
            {
              "Name": "spring_model_data.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/spring_model_data.m",
              "Children": []
            },
            {
              "Name": "structfun.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/structfun.m",
              "Children": []
            },
            {
              "Name": "value_text.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/value_text.m",
              "Children": []
            },
            {
              "Name": "varrayfun.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/varrayfun.m",
              "Children": []
            },
            {
              "Name": "vcellfun.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/vcellfun.m",
              "Children": []
            },
            {
              "Name": "vec2complex.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/+tools/vec2complex.m",
              "Children": []
            }
          ]
        },
        {
          "Name": "@Branch",
          "Kind": "folder",
          "Path": "_GUILDAsystem/@Branch",
          "Children": [
            {
              "Name": "Branch.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Branch/Branch.m",
              "Children": [],
              "Class": "Branch"
            },
            {
              "Name": "get_opf_condition.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Branch/get_opf_condition.m",
              "Children": [],
              "Class": "Branch",
              "Method": "get_opf_condition"
            },
            {
              "Name": "gui_content.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Branch/gui_content.m",
              "Children": [],
              "Class": "Branch",
              "Method": "gui_content"
            },
            {
              "Name": "initialize.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Branch/initialize.m",
              "Children": [],
              "Class": "Branch",
              "Method": "initialize"
            },
            {
              "Name": "struct.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Branch/struct.m",
              "Children": [],
              "Class": "Branch",
              "Method": "struct"
            }
          ]
        },
        {
          "Name": "@Bus",
          "Kind": "folder",
          "Path": "_GUILDAsystem/@Bus",
          "Children": [
            {
              "Name": "private",
              "Kind": "folder",
              "Path": "_GUILDAsystem/@Bus/private",
              "Children": [
                {
                  "Name": "controlling_gcon.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@Bus/private/controlling_gcon.m",
                  "Children": [],
                  "Class": "Bus"
                }
              ]
            },
            {
              "Name": "add_component.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/add_component.m",
              "Children": [],
              "Class": "Bus",
              "Method": "add_component"
            },
            {
              "Name": "Bus.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/Bus.m",
              "Children": [],
              "Class": "Bus"
            },
            {
              "Name": "get_opf_condition.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/get_opf_condition.m",
              "Children": [],
              "Class": "Bus",
              "Method": "get_opf_condition"
            },
            {
              "Name": "get_pf_condition.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/get_pf_condition.m",
              "Children": [],
              "Class": "Bus",
              "Method": "get_pf_condition"
            },
            {
              "Name": "get_variable_map.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/get_variable_map.m",
              "Children": [],
              "Class": "Bus",
              "Method": "get_variable_map"
            },
            {
              "Name": "gui_content.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/gui_content.m",
              "Children": [],
              "Class": "Bus",
              "Method": "gui_content"
            },
            {
              "Name": "initialize.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/initialize.m",
              "Children": [],
              "Class": "Bus",
              "Method": "initialize"
            },
            {
              "Name": "remove_component.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/remove_component.m",
              "Children": [],
              "Class": "Bus",
              "Method": "remove_component"
            },
            {
              "Name": "replace_component.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/replace_component.m",
              "Children": [],
              "Class": "Bus",
              "Method": "replace_component"
            },
            {
              "Name": "set_equilibrium.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Bus/set_equilibrium.m",
              "Children": [],
              "Class": "Bus",
              "Method": "set_equilibrium"
            }
          ]
        },
        {
          "Name": "@Component",
          "Kind": "folder",
          "Path": "_GUILDAsystem/@Component",
          "Children": [
            {
              "Name": "private",
              "Kind": "folder",
              "Path": "_GUILDAsystem/@Component/private",
              "Children": [
                {
                  "Name": "check_controller_slots.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@Component/private/check_controller_slots.m",
                  "Children": [],
                  "Class": "Component"
                },
                {
                  "Name": "equilibrium_depth_first.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@Component/private/equilibrium_depth_first.m",
                  "Children": [],
                  "Class": "Component"
                },
                {
                  "Name": "gc_routes.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@Component/private/gc_routes.m",
                  "Children": [],
                  "Class": "Component"
                },
                {
                  "Name": "is_static_controller.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@Component/private/is_static_controller.m",
                  "Children": [],
                  "Class": "Component"
                },
                {
                  "Name": "Jacobi_dx_num.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@Component/private/Jacobi_dx_num.m",
                  "Children": [],
                  "Class": "Component"
                },
                {
                  "Name": "Jacobi_I_num.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@Component/private/Jacobi_I_num.m",
                  "Children": [],
                  "Class": "Component"
                },
                {
                  "Name": "Jacobi_Y_num.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@Component/private/Jacobi_Y_num.m",
                  "Children": [],
                  "Class": "Component"
                }
              ]
            },
            {
              "Name": "add_local_controller.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/add_local_controller.m",
              "Children": [],
              "Class": "Component",
              "Method": "add_local_controller"
            },
            {
              "Name": "Component.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/Component.m",
              "Children": [],
              "Class": "Component"
            },
            {
              "Name": "get_hessian.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/get_hessian.m",
              "Children": [],
              "Class": "Component",
              "Method": "get_hessian"
            },
            {
              "Name": "get_linear_matrix.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/get_linear_matrix.m",
              "Children": [],
              "Class": "Component",
              "Method": "get_linear_matrix"
            },
            {
              "Name": "get_spring_node.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/get_spring_node.m",
              "Children": [],
              "Class": "Component",
              "Method": "get_spring_node"
            },
            {
              "Name": "get_variable_map.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/get_variable_map.m",
              "Children": [],
              "Class": "Component",
              "Method": "get_variable_map"
            },
            {
              "Name": "gui_content.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/gui_content.m",
              "Children": [],
              "Class": "Component",
              "Method": "gui_content"
            },
            {
              "Name": "handle_edit.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/handle_edit.m",
              "Children": [],
              "Class": "Component",
              "Method": "handle_edit"
            },
            {
              "Name": "initialize.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/initialize.m",
              "Children": [],
              "Class": "Component",
              "Method": "initialize"
            },
            {
              "Name": "move_local_controllers.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/move_local_controllers.m",
              "Children": [],
              "Class": "Component",
              "Method": "move_local_controllers"
            },
            {
              "Name": "pack_hessian.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/pack_hessian.m",
              "Children": [],
              "Class": "Component",
              "Method": "pack_hessian"
            },
            {
              "Name": "remove_local_controller.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/remove_local_controller.m",
              "Children": [],
              "Class": "Component",
              "Method": "remove_local_controller"
            },
            {
              "Name": "set_equilibrium.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/set_equilibrium.m",
              "Children": [],
              "Class": "Component",
              "Method": "set_equilibrium"
            },
            {
              "Name": "set_input.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/set_input.m",
              "Children": [],
              "Class": "Component",
              "Method": "set_input"
            },
            {
              "Name": "set_odefcn.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/set_odefcn.m",
              "Children": [],
              "Class": "Component",
              "Method": "set_odefcn"
            },
            {
              "Name": "validate.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@Component/validate.m",
              "Children": [],
              "Class": "Component",
              "Method": "validate"
            }
          ]
        },
        {
          "Name": "@GlobalController",
          "Kind": "folder",
          "Path": "_GUILDAsystem/@GlobalController",
          "Children": [
            {
              "Name": "get_hessian.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@GlobalController/get_hessian.m",
              "Children": [],
              "Class": "GlobalController",
              "Method": "get_hessian"
            },
            {
              "Name": "get_linear_matrix.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@GlobalController/get_linear_matrix.m",
              "Children": [],
              "Class": "GlobalController",
              "Method": "get_linear_matrix"
            },
            {
              "Name": "get_option.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@GlobalController/get_option.m",
              "Children": [],
              "Class": "GlobalController",
              "Method": "get_option"
            },
            {
              "Name": "get_variable_map.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@GlobalController/get_variable_map.m",
              "Children": [],
              "Class": "GlobalController",
              "Method": "get_variable_map"
            },
            {
              "Name": "GlobalController.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@GlobalController/GlobalController.m",
              "Children": [],
              "Class": "GlobalController"
            },
            {
              "Name": "gui_content.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@GlobalController/gui_content.m",
              "Children": [],
              "Class": "GlobalController",
              "Method": "gui_content"
            },
            {
              "Name": "handle_edit.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@GlobalController/handle_edit.m",
              "Children": [],
              "Class": "GlobalController",
              "Method": "handle_edit"
            },
            {
              "Name": "initialize.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@GlobalController/initialize.m",
              "Children": [],
              "Class": "GlobalController",
              "Method": "initialize"
            },
            {
              "Name": "set_odefcn.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@GlobalController/set_odefcn.m",
              "Children": [],
              "Class": "GlobalController",
              "Method": "set_odefcn"
            }
          ]
        },
        {
          "Name": "@LocalController",
          "Kind": "folder",
          "Path": "_GUILDAsystem/@LocalController",
          "Children": [
            {
              "Name": "private",
              "Kind": "folder",
              "Path": "_GUILDAsystem/@LocalController/private",
              "Children": [
                {
                  "Name": "check_nested_slot.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@LocalController/private/check_nested_slot.m",
                  "Children": [],
                  "Class": "LocalController"
                }
              ]
            },
            {
              "Name": "add_local_controller.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/add_local_controller.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "add_local_controller"
            },
            {
              "Name": "driven_inputs.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/driven_inputs.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "driven_inputs"
            },
            {
              "Name": "get_equilibrium_at.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/get_equilibrium_at.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "get_equilibrium_at"
            },
            {
              "Name": "get_hessian.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/get_hessian.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "get_hessian"
            },
            {
              "Name": "get_linear_matrix.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/get_linear_matrix.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "get_linear_matrix"
            },
            {
              "Name": "get_option.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/get_option.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "get_option"
            },
            {
              "Name": "get_variable_map.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/get_variable_map.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "get_variable_map"
            },
            {
              "Name": "gui_content.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/gui_content.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "gui_content"
            },
            {
              "Name": "handle_edit.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/handle_edit.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "handle_edit"
            },
            {
              "Name": "initialize.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/initialize.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "initialize"
            },
            {
              "Name": "LocalController.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/LocalController.m",
              "Children": [],
              "Class": "LocalController"
            },
            {
              "Name": "observed_component.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/observed_component.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "observed_component"
            },
            {
              "Name": "parent_equilibrium.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/parent_equilibrium.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "parent_equilibrium"
            },
            {
              "Name": "remove_local_controller.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/remove_local_controller.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "remove_local_controller"
            },
            {
              "Name": "resolve_observe.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/resolve_observe.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "resolve_observe"
            },
            {
              "Name": "resolve_ports.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/resolve_ports.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "resolve_ports"
            },
            {
              "Name": "set_inputs.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/set_inputs.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "set_inputs"
            },
            {
              "Name": "set_odefcn.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/set_odefcn.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "set_odefcn"
            },
            {
              "Name": "validate.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@LocalController/validate.m",
              "Children": [],
              "Class": "LocalController",
              "Method": "validate"
            }
          ]
        },
        {
          "Name": "@PowerNetwork",
          "Kind": "folder",
          "Path": "_GUILDAsystem/@PowerNetwork",
          "Children": [
            {
              "Name": "private",
              "Kind": "folder",
              "Path": "_GUILDAsystem/@PowerNetwork/private",
              "Children": [
                {
                  "Name": "all_controllers.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/all_controllers.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "element_list.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/element_list.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "elements_below.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/elements_below.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "mustBeDampingRatioOrNaN.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/mustBeDampingRatioOrNaN.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "mustBeFiniteOrNaN.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/mustBeFiniteOrNaN.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "mustBeHandleOrEmpty.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/mustBeHandleOrEmpty.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "mustBeIntegerOrNaN.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/mustBeIntegerOrNaN.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "mustBePositiveIntegerOrNaN.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/mustBePositiveIntegerOrNaN.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "mustBePositiveOrNaN.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/mustBePositiveOrNaN.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "mustBeProgress.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/mustBeProgress.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "read_scenarios.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/read_scenarios.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "scenario_hint.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/scenario_hint.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "simulateFcn_blocks.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/simulateFcn_blocks.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "simulateFcn_check.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/simulateFcn_check.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "simulateFcn_check_islands.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/simulateFcn_check_islands.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "simulateFcn_mustBeNonnegativeOrNaN.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/simulateFcn_mustBeNonnegativeOrNaN.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "simulateFcn_mustBeScenarioOf.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/simulateFcn_mustBeScenarioOf.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "simulateFcn_print_phases.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/simulateFcn_print_phases.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "simulateFcn_stop_condition.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/simulateFcn_stop_condition.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "simulateFcn_struct_result.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/simulateFcn_struct_result.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "stability_gradient.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/stability_gradient.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "stability_modes.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/stability_modes.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "stability_point.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/stability_point.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                },
                {
                  "Name": "write_scenarios.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/@PowerNetwork/private/write_scenarios.m",
                  "Children": [],
                  "Class": "PowerNetwork"
                }
              ]
            },
            {
              "Name": "add_branch.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/add_branch.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "add_branch"
            },
            {
              "Name": "add_bus.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/add_bus.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "add_bus"
            },
            {
              "Name": "add_global_controller.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/add_global_controller.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "add_global_controller"
            },
            {
              "Name": "add_scenario.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/add_scenario.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "add_scenario"
            },
            {
              "Name": "build_opf_problem.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/build_opf_problem.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "build_opf_problem"
            },
            {
              "Name": "build_simulation_data.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/build_simulation_data.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "build_simulation_data"
            },
            {
              "Name": "calculate_continuation_powerflow.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/calculate_continuation_powerflow.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "calculate_continuation_powerflow"
            },
            {
              "Name": "calculate_fixed_input_powerflow.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/calculate_fixed_input_powerflow.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "calculate_fixed_input_powerflow"
            },
            {
              "Name": "calculate_optimal_powerflow.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/calculate_optimal_powerflow.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "calculate_optimal_powerflow"
            },
            {
              "Name": "calculate_powerflow.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/calculate_powerflow.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "calculate_powerflow"
            },
            {
              "Name": "disp_connection.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/disp_connection.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "disp_connection"
            },
            {
              "Name": "disp_powerflow.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/disp_powerflow.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "disp_powerflow"
            },
            {
              "Name": "disp_summary.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/disp_summary.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "disp_summary"
            },
            {
              "Name": "export.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/export.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "export"
            },
            {
              "Name": "get_admittance_matrix.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/get_admittance_matrix.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "get_admittance_matrix"
            },
            {
              "Name": "get_element.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/get_element.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "get_element"
            },
            {
              "Name": "get_element_table.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/get_element_table.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "get_element_table"
            },
            {
              "Name": "get_layout.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/get_layout.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "get_layout"
            },
            {
              "Name": "get_opf_condition.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/get_opf_condition.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "get_opf_condition"
            },
            {
              "Name": "get_parameter.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/get_parameter.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "get_parameter"
            },
            {
              "Name": "get_pf_condition.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/get_pf_condition.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "get_pf_condition"
            },
            {
              "Name": "get_variable_map.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/get_variable_map.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "get_variable_map"
            },
            {
              "Name": "gui_content.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/gui_content.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "gui_content"
            },
            {
              "Name": "handle_edit.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/handle_edit.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "handle_edit"
            },
            {
              "Name": "import.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/import.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "import"
            },
            {
              "Name": "import_matpower.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/import_matpower.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "import_matpower"
            },
            {
              "Name": "initialize.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/initialize.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "initialize"
            },
            {
              "Name": "plot_diagram.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/plot_diagram.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "plot_diagram"
            },
            {
              "Name": "plot_single_line_diagram.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/plot_single_line_diagram.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "plot_single_line_diagram"
            },
            {
              "Name": "plot_spring_model.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/plot_spring_model.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "plot_spring_model"
            },
            {
              "Name": "PowerNetwork.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
              "Children": [],
              "Class": "PowerNetwork"
            },
            {
              "Name": "remove_branch.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/remove_branch.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "remove_branch"
            },
            {
              "Name": "remove_bus.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/remove_bus.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "remove_bus"
            },
            {
              "Name": "remove_global_controller.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/remove_global_controller.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "remove_global_controller"
            },
            {
              "Name": "remove_scenario.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/remove_scenario.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "remove_scenario"
            },
            {
              "Name": "reset_solver.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/reset_solver.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "reset_solver"
            },
            {
              "Name": "set_layout.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/set_layout.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "set_layout"
            },
            {
              "Name": "set_parameter.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/set_parameter.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "set_parameter"
            },
            {
              "Name": "simulate.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/@PowerNetwork/simulate.m",
              "Children": [],
              "Class": "PowerNetwork",
              "Method": "simulate"
            }
          ]
        },
        {
          "Name": "_auxiliary",
          "Kind": "folder",
          "Path": "_GUILDAsystem/_auxiliary",
          "Children": [
            {
              "Name": "@auxiliary",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@auxiliary",
              "Children": [
                {
                  "Name": "auxiliary.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@auxiliary/auxiliary.m",
                  "Children": [],
                  "Class": "auxiliary"
                },
                {
                  "Name": "doc.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@auxiliary/doc.m",
                  "Children": [],
                  "Class": "auxiliary",
                  "Method": "doc"
                }
              ]
            },
            {
              "Name": "@DrawerGUILDA",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private",
                  "Children": [
                    {
                      "Name": "analyze_highlight.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/analyze_highlight.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "draw_network.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/draw_network.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_analysis_diagram.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_analysis_diagram.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_analysis_legend.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_analysis_legend.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_analysis_panel.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_analysis_panel.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_cpf_build.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_cpf_build.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_cpf_diagram.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_cpf_diagram.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_cpf_value.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_cpf_value.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_lin_build.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_lin_build.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_list.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_list.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_model_build.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_build.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_model_click.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_click.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_model_diagram.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_diagram.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_model_select.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_select.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_model_show.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_show.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_opf_build.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_opf_build.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_opf_diagram.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_opf_diagram.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_pf_build.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_pf_build.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_pf_diagram.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_pf_diagram.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_sim_action.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_action.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_sim_build.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_build.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_sim_diagram.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_diagram.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_sim_legend.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_legend.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    },
                    {
                      "Name": "tab_sim_refresh.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_refresh.m",
                      "Children": [],
                      "Class": "DrawerGUILDA"
                    }
                  ]
                },
                {
                  "Name": "build_main.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/build_main.m",
                  "Children": [],
                  "Class": "DrawerGUILDA",
                  "Method": "build_main"
                },
                {
                  "Name": "build_start.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/build_start.m",
                  "Children": [],
                  "Class": "DrawerGUILDA",
                  "Method": "build_start"
                },
                {
                  "Name": "call_hook.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/call_hook.m",
                  "Children": [],
                  "Class": "DrawerGUILDA",
                  "Method": "call_hook"
                },
                {
                  "Name": "DrawerGUILDA.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
                  "Children": [],
                  "Class": "DrawerGUILDA"
                },
                {
                  "Name": "on_history_changed.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/on_history_changed.m",
                  "Children": [],
                  "Class": "DrawerGUILDA",
                  "Method": "on_history_changed"
                },
                {
                  "Name": "redraw.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/redraw.m",
                  "Children": [],
                  "Class": "DrawerGUILDA",
                  "Method": "redraw"
                },
                {
                  "Name": "run_code.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/run_code.m",
                  "Children": [],
                  "Class": "DrawerGUILDA",
                  "Method": "run_code"
                },
                {
                  "Name": "show_tab.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/show_tab.m",
                  "Children": [],
                  "Class": "DrawerGUILDA",
                  "Method": "show_tab"
                },
                {
                  "Name": "stale_banner.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/stale_banner.m",
                  "Children": [],
                  "Class": "DrawerGUILDA",
                  "Method": "stale_banner"
                }
              ]
            },
            {
              "Name": "@DrawerModelGUI",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private",
                  "Children": [
                    {
                      "Name": "body_data.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/body_data.m",
                      "Children": [],
                      "Class": "DrawerModelGUI"
                    },
                    {
                      "Name": "build_frame.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/build_frame.m",
                      "Children": [],
                      "Class": "DrawerModelGUI"
                    },
                    {
                      "Name": "clear_gui.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/clear_gui.m",
                      "Children": [],
                      "Class": "DrawerModelGUI"
                    },
                    {
                      "Name": "edit_parameter.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/edit_parameter.m",
                      "Children": [],
                      "Class": "DrawerModelGUI"
                    },
                    {
                      "Name": "set_changed.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/set_changed.m",
                      "Children": [],
                      "Class": "DrawerModelGUI"
                    },
                    {
                      "Name": "show_alert.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/show_alert.m",
                      "Children": [],
                      "Class": "DrawerModelGUI"
                    },
                    {
                      "Name": "update_header.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/update_header.m",
                      "Children": [],
                      "Class": "DrawerModelGUI"
                    },
                    {
                      "Name": "update_navigation.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/update_navigation.m",
                      "Children": [],
                      "Class": "DrawerModelGUI"
                    },
                    {
                      "Name": "update_stale.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/update_stale.m",
                      "Children": [],
                      "Class": "DrawerModelGUI"
                    }
                  ]
                },
                {
                  "Name": "DrawerModelGUI.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
                  "Children": [],
                  "Class": "DrawerModelGUI"
                },
                {
                  "Name": "model_expression.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/model_expression.m",
                  "Children": [],
                  "Class": "DrawerModelGUI",
                  "Method": "model_expression"
                },
                {
                  "Name": "render.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/render.m",
                  "Children": [],
                  "Class": "DrawerModelGUI",
                  "Method": "render"
                },
                {
                  "Name": "run_code.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/run_code.m",
                  "Children": [],
                  "Class": "DrawerModelGUI",
                  "Method": "run_code"
                }
              ]
            },
            {
              "Name": "@DrawerOptionDialog",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private",
                  "Children": [
                    {
                      "Name": "close_dialog.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/close_dialog.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    },
                    {
                      "Name": "code_strings.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/code_strings.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    },
                    {
                      "Name": "eval_depend.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/eval_depend.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    },
                    {
                      "Name": "eval_text.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/eval_text.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    },
                    {
                      "Name": "field_baseline.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/field_baseline.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    },
                    {
                      "Name": "hint_text.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/hint_text.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    },
                    {
                      "Name": "number_text.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/number_text.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    },
                    {
                      "Name": "parse_tags.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/parse_tags.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    },
                    {
                      "Name": "refresh_depend.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/refresh_depend.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    },
                    {
                      "Name": "tags_text.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/tags_text.m",
                      "Children": [],
                      "Class": "DrawerOptionDialog"
                    }
                  ]
                },
                {
                  "Name": "ask.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/ask.m",
                  "Children": [],
                  "Class": "DrawerOptionDialog",
                  "Method": "ask"
                },
                {
                  "Name": "build_form.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/build_form.m",
                  "Children": [],
                  "Class": "DrawerOptionDialog",
                  "Method": "build_form"
                },
                {
                  "Name": "draw_field.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/draw_field.m",
                  "Children": [],
                  "Class": "DrawerOptionDialog",
                  "Method": "draw_field"
                },
                {
                  "Name": "DrawerOptionDialog.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
                  "Children": [],
                  "Class": "DrawerOptionDialog"
                },
                {
                  "Name": "form_event.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/form_event.m",
                  "Children": [],
                  "Class": "DrawerOptionDialog",
                  "Method": "form_event"
                },
                {
                  "Name": "get_code.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/get_code.m",
                  "Children": [],
                  "Class": "DrawerOptionDialog",
                  "Method": "get_code"
                }
              ]
            },
            {
              "Name": "@DrawerResultGUI",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@DrawerResultGUI",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerResultGUI/private",
                  "Children": [
                    {
                      "Name": "read_signatures.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerResultGUI/private/read_signatures.m",
                      "Children": [],
                      "Class": "DrawerResultGUI"
                    }
                  ]
                },
                {
                  "Name": "autoplay.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerResultGUI/autoplay.m",
                  "Children": [],
                  "Class": "DrawerResultGUI",
                  "Method": "autoplay"
                },
                {
                  "Name": "DrawerResultGUI.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerResultGUI/DrawerResultGUI.m",
                  "Children": [],
                  "Class": "DrawerResultGUI"
                },
                {
                  "Name": "render.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerResultGUI/render.m",
                  "Children": [],
                  "Class": "DrawerResultGUI",
                  "Method": "render"
                },
                {
                  "Name": "run_method.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerResultGUI/run_method.m",
                  "Children": [],
                  "Class": "DrawerResultGUI",
                  "Method": "run_method"
                },
                {
                  "Name": "show_log.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerResultGUI/show_log.m",
                  "Children": [],
                  "Class": "DrawerResultGUI",
                  "Method": "show_log"
                },
                {
                  "Name": "show_plot_controls.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerResultGUI/show_plot_controls.m",
                  "Children": [],
                  "Class": "DrawerResultGUI",
                  "Method": "show_plot_controls"
                }
              ]
            },
            {
              "Name": "@DrawerTagPicker",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@DrawerTagPicker",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/private",
                  "Children": [
                    {
                      "Name": "picker_event.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/private/picker_event.m",
                      "Children": [],
                      "Class": "DrawerTagPicker"
                    }
                  ]
                },
                {
                  "Name": "DrawerTagPicker.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/DrawerTagPicker.m",
                  "Children": [],
                  "Class": "DrawerTagPicker"
                },
                {
                  "Name": "element_table.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/element_table.m",
                  "Children": [],
                  "Class": "DrawerTagPicker",
                  "Method": "element_table"
                },
                {
                  "Name": "key_table.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/key_table.m",
                  "Children": [],
                  "Class": "DrawerTagPicker",
                  "Method": "key_table"
                },
                {
                  "Name": "pick.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/pick.m",
                  "Children": [],
                  "Class": "DrawerTagPicker",
                  "Method": "pick"
                }
              ]
            },
            {
              "Name": "@EventBase",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@EventBase",
              "Children": [
                {
                  "Name": "apply_edit.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventBase/apply_edit.m",
                  "Children": [],
                  "Class": "EventBase",
                  "Method": "apply_edit"
                },
                {
                  "Name": "copyElement.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventBase/copyElement.m",
                  "Children": [],
                  "Class": "EventBase",
                  "Method": "copyElement"
                },
                {
                  "Name": "EventBase.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventBase/EventBase.m",
                  "Children": [],
                  "Class": "EventBase"
                }
              ]
            },
            {
              "Name": "@EventFault",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@EventFault",
              "Children": [
                {
                  "Name": "edit.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventFault/edit.m",
                  "Children": [],
                  "Class": "EventFault",
                  "Method": "edit"
                },
                {
                  "Name": "EventFault.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventFault/EventFault.m",
                  "Children": [],
                  "Class": "EventFault"
                },
                {
                  "Name": "table_rows.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventFault/table_rows.m",
                  "Children": [],
                  "Class": "EventFault",
                  "Method": "table_rows"
                }
              ]
            },
            {
              "Name": "@EventInput",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@EventInput",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@EventInput/private",
                  "Children": [
                    {
                      "Name": "normalize_input.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@EventInput/private/normalize_input.m",
                      "Children": [],
                      "Class": "EventInput"
                    }
                  ]
                },
                {
                  "Name": "edit.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventInput/edit.m",
                  "Children": [],
                  "Class": "EventInput",
                  "Method": "edit"
                },
                {
                  "Name": "EventInput.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
                  "Children": [],
                  "Class": "EventInput"
                },
                {
                  "Name": "table_rows.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventInput/table_rows.m",
                  "Children": [],
                  "Class": "EventInput",
                  "Method": "table_rows"
                }
              ]
            },
            {
              "Name": "@EventOffset",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@EventOffset",
              "Children": [
                {
                  "Name": "edit.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventOffset/edit.m",
                  "Children": [],
                  "Class": "EventOffset",
                  "Method": "edit"
                },
                {
                  "Name": "EventOffset.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m",
                  "Children": [],
                  "Class": "EventOffset"
                },
                {
                  "Name": "table_rows.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventOffset/table_rows.m",
                  "Children": [],
                  "Class": "EventOffset",
                  "Method": "table_rows"
                }
              ]
            },
            {
              "Name": "@EventOpenBranch",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@EventOpenBranch",
              "Children": [
                {
                  "Name": "edit.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventOpenBranch/edit.m",
                  "Children": [],
                  "Class": "EventOpenBranch",
                  "Method": "edit"
                },
                {
                  "Name": "EventOpenBranch.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventOpenBranch/EventOpenBranch.m",
                  "Children": [],
                  "Class": "EventOpenBranch"
                },
                {
                  "Name": "table_rows.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventOpenBranch/table_rows.m",
                  "Children": [],
                  "Class": "EventOpenBranch",
                  "Method": "table_rows"
                }
              ]
            },
            {
              "Name": "@EventTrip",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@EventTrip",
              "Children": [
                {
                  "Name": "edit.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventTrip/edit.m",
                  "Children": [],
                  "Class": "EventTrip",
                  "Method": "edit"
                },
                {
                  "Name": "EventTrip.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventTrip/EventTrip.m",
                  "Children": [],
                  "Class": "EventTrip"
                },
                {
                  "Name": "table_rows.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@EventTrip/table_rows.m",
                  "Children": [],
                  "Class": "EventTrip",
                  "Method": "table_rows"
                }
              ]
            },
            {
              "Name": "@GraphBase",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@GraphBase",
              "Children": [
                {
                  "Name": "animate.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/animate.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "animate"
                },
                {
                  "Name": "build.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/build.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "build"
                },
                {
                  "Name": "clear_selection.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/clear_selection.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "clear_selection"
                },
                {
                  "Name": "click_element.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/click_element.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "click_element"
                },
                {
                  "Name": "control_list.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/control_list.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "control_list"
                },
                {
                  "Name": "export_video.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/export_video.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "export_video"
                },
                {
                  "Name": "get_layout.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/get_layout.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "get_layout"
                },
                {
                  "Name": "GraphBase.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
                  "Children": [],
                  "Class": "GraphBase"
                },
                {
                  "Name": "has_playback.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/has_playback.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "has_playback"
                },
                {
                  "Name": "hide_controls.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/hide_controls.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "hide_controls"
                },
                {
                  "Name": "link.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/link.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "link"
                },
                {
                  "Name": "load_sample_label.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/load_sample_label.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "load_sample_label"
                },
                {
                  "Name": "make_axes.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/make_axes.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "make_axes"
                },
                {
                  "Name": "pause.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/pause.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "pause"
                },
                {
                  "Name": "place_bar.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/place_bar.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "place_bar"
                },
                {
                  "Name": "place_label.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/place_label.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "place_label"
                },
                {
                  "Name": "play.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/play.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "play"
                },
                {
                  "Name": "play_bar.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/play_bar.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "play_bar"
                },
                {
                  "Name": "prepare_frame.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/prepare_frame.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "prepare_frame"
                },
                {
                  "Name": "range_map.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/range_map.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "range_map"
                },
                {
                  "Name": "refresh_bar.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/refresh_bar.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "refresh_bar"
                },
                {
                  "Name": "refresh_controls.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/refresh_controls.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "refresh_controls"
                },
                {
                  "Name": "reset_style.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/reset_style.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "reset_style"
                },
                {
                  "Name": "resolve_overlap.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/resolve_overlap.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "resolve_overlap"
                },
                {
                  "Name": "sample_text.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/sample_text.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "sample_text"
                },
                {
                  "Name": "select.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/select.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "select"
                },
                {
                  "Name": "set_arrow.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/set_arrow.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "set_arrow"
                },
                {
                  "Name": "set_data.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/set_data.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "set_data"
                },
                {
                  "Name": "set_position.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/set_position.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "set_position"
                },
                {
                  "Name": "set_style.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/set_style.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "set_style"
                },
                {
                  "Name": "set_time.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/set_time.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "set_time"
                },
                {
                  "Name": "show_controls.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/show_controls.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "show_controls"
                },
                {
                  "Name": "unlink.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/unlink.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "unlink"
                },
                {
                  "Name": "write_frame.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphBase/write_frame.m",
                  "Children": [],
                  "Class": "GraphBase",
                  "Method": "write_frame"
                }
              ]
            },
            {
              "Name": "@GraphChart",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@GraphChart",
              "Children": [
                {
                  "Name": "apply_selection.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/apply_selection.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "apply_selection"
                },
                {
                  "Name": "apply_style.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/apply_style.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "apply_style"
                },
                {
                  "Name": "control_list.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/control_list.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "control_list"
                },
                {
                  "Name": "create_scene.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/create_scene.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "create_scene"
                },
                {
                  "Name": "element_table.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/element_table.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "element_table"
                },
                {
                  "Name": "GraphChart.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
                  "Children": [],
                  "Class": "GraphChart"
                },
                {
                  "Name": "has_playback.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/has_playback.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "has_playback"
                },
                {
                  "Name": "load_data.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/load_data.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "load_data"
                },
                {
                  "Name": "refresh_legend.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/refresh_legend.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "refresh_legend"
                },
                {
                  "Name": "style_properties.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/style_properties.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "style_properties"
                },
                {
                  "Name": "update_scene.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphChart/update_scene.m",
                  "Children": [],
                  "Class": "GraphChart",
                  "Method": "update_scene"
                }
              ]
            },
            {
              "Name": "@GraphMatrix",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix",
              "Children": [
                {
                  "Name": "apply_selection.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix/apply_selection.m",
                  "Children": [],
                  "Class": "GraphMatrix",
                  "Method": "apply_selection"
                },
                {
                  "Name": "apply_style.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix/apply_style.m",
                  "Children": [],
                  "Class": "GraphMatrix",
                  "Method": "apply_style"
                },
                {
                  "Name": "control_list.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix/control_list.m",
                  "Children": [],
                  "Class": "GraphMatrix",
                  "Method": "control_list"
                },
                {
                  "Name": "create_scene.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix/create_scene.m",
                  "Children": [],
                  "Class": "GraphMatrix",
                  "Method": "create_scene"
                },
                {
                  "Name": "element_table.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix/element_table.m",
                  "Children": [],
                  "Class": "GraphMatrix",
                  "Method": "element_table"
                },
                {
                  "Name": "GraphMatrix.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix/GraphMatrix.m",
                  "Children": [],
                  "Class": "GraphMatrix"
                },
                {
                  "Name": "load_data.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix/load_data.m",
                  "Children": [],
                  "Class": "GraphMatrix",
                  "Method": "load_data"
                },
                {
                  "Name": "style_properties.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix/style_properties.m",
                  "Children": [],
                  "Class": "GraphMatrix",
                  "Method": "style_properties"
                },
                {
                  "Name": "update_scene.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphMatrix/update_scene.m",
                  "Children": [],
                  "Class": "GraphMatrix",
                  "Method": "update_scene"
                }
              ]
            },
            {
              "Name": "@GraphNetDiagram",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private",
                  "Children": [
                    {
                      "Name": "draw_arrow_cone.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/draw_arrow_cone.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "draw_cone.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/draw_cone.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "draw_cuboid.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/draw_cuboid.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "draw_cuboid_horizontal.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/draw_cuboid_horizontal.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "draw_cuboid_vertical.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/draw_cuboid_vertical.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "draw_edge_tube.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/draw_edge_tube.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "draw_sphere.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/draw_sphere.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "not_draw.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/not_draw.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "plot_edge.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/plot_edge.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "plot_node.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/plot_node.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    },
                    {
                      "Name": "set_graphics_color.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/private/set_graphics_color.m",
                      "Children": [],
                      "Class": "GraphNetDiagram"
                    }
                  ]
                },
                {
                  "Name": "apply_selection.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/apply_selection.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "apply_selection"
                },
                {
                  "Name": "apply_style.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/apply_style.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "apply_style"
                },
                {
                  "Name": "color_limits.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/color_limits.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "color_limits"
                },
                {
                  "Name": "color_of_values.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/color_of_values.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "color_of_values"
                },
                {
                  "Name": "color_percentile.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/color_percentile.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "color_percentile"
                },
                {
                  "Name": "color_readout.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/color_readout.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "color_readout"
                },
                {
                  "Name": "color_values.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/color_values.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "color_values"
                },
                {
                  "Name": "control_list.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/control_list.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "control_list"
                },
                {
                  "Name": "create_scene.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/create_scene.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "create_scene"
                },
                {
                  "Name": "diagram_geometry.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/diagram_geometry.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "diagram_geometry"
                },
                {
                  "Name": "draw_diagram_2d.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/draw_diagram_2d.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "draw_diagram_2d"
                },
                {
                  "Name": "draw_graph_network.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/draw_graph_network.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "draw_graph_network"
                },
                {
                  "Name": "element_table.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/element_table.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "element_table"
                },
                {
                  "Name": "fit_axes.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/fit_axes.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "fit_axes"
                },
                {
                  "Name": "flow_paths.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/flow_paths.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "flow_paths"
                },
                {
                  "Name": "flow_timer.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/flow_timer.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "flow_timer"
                },
                {
                  "Name": "flow_values.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/flow_values.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "flow_values"
                },
                {
                  "Name": "get_layout.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/get_layout.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "get_layout"
                },
                {
                  "Name": "GraphNetDiagram.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/GraphNetDiagram.m",
                  "Children": [],
                  "Class": "GraphNetDiagram"
                },
                {
                  "Name": "hover_branch.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/hover_branch.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "hover_branch"
                },
                {
                  "Name": "hover_bus.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/hover_bus.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "hover_bus"
                },
                {
                  "Name": "hover_component.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/hover_component.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "hover_component"
                },
                {
                  "Name": "load_data.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/load_data.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "load_data"
                },
                {
                  "Name": "make_component_labels.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/make_component_labels.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "make_component_labels"
                },
                {
                  "Name": "prepare_frame.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/prepare_frame.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "prepare_frame"
                },
                {
                  "Name": "reflect_arrow_forward.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/reflect_arrow_forward.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "reflect_arrow_forward"
                },
                {
                  "Name": "reflect_color_mode.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/reflect_color_mode.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "reflect_color_mode"
                },
                {
                  "Name": "reflect_node_label.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/reflect_node_label.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "reflect_node_label"
                },
                {
                  "Name": "set_network.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/set_network.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "set_network"
                },
                {
                  "Name": "set_position.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/set_position.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "set_position"
                },
                {
                  "Name": "set_powerflow.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/set_powerflow.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "set_powerflow"
                },
                {
                  "Name": "size_values.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/size_values.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "size_values"
                },
                {
                  "Name": "step_flow.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/step_flow.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "step_flow"
                },
                {
                  "Name": "style_properties.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/style_properties.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "style_properties"
                },
                {
                  "Name": "update_color_scale.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/update_color_scale.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "update_color_scale"
                },
                {
                  "Name": "update_flow.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/update_flow.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "update_flow"
                },
                {
                  "Name": "update_heights.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/update_heights.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "update_heights"
                },
                {
                  "Name": "update_scale.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/update_scale.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "update_scale"
                },
                {
                  "Name": "update_scene.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/update_scene.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "update_scene"
                },
                {
                  "Name": "update_sizes.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/update_sizes.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "update_sizes"
                },
                {
                  "Name": "validate.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphNetDiagram/validate.m",
                  "Children": [],
                  "Class": "GraphNetDiagram",
                  "Method": "validate"
                }
              ]
            },
            {
              "Name": "@GraphSpring2D",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@GraphSpring2D",
              "Children": [
                {
                  "Name": "apply_style.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpring2D/apply_style.m",
                  "Children": [],
                  "Class": "GraphSpring2D",
                  "Method": "apply_style"
                },
                {
                  "Name": "create_scene.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpring2D/create_scene.m",
                  "Children": [],
                  "Class": "GraphSpring2D",
                  "Method": "create_scene"
                },
                {
                  "Name": "draw_sample.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpring2D/draw_sample.m",
                  "Children": [],
                  "Class": "GraphSpring2D",
                  "Method": "draw_sample"
                },
                {
                  "Name": "GraphSpring2D.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpring2D/GraphSpring2D.m",
                  "Children": [],
                  "Class": "GraphSpring2D"
                }
              ]
            },
            {
              "Name": "@GraphSpring3D",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@GraphSpring3D",
              "Children": [
                {
                  "Name": "apply_style.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpring3D/apply_style.m",
                  "Children": [],
                  "Class": "GraphSpring3D",
                  "Method": "apply_style"
                },
                {
                  "Name": "control_list.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpring3D/control_list.m",
                  "Children": [],
                  "Class": "GraphSpring3D",
                  "Method": "control_list"
                },
                {
                  "Name": "create_scene.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpring3D/create_scene.m",
                  "Children": [],
                  "Class": "GraphSpring3D",
                  "Method": "create_scene"
                },
                {
                  "Name": "draw_sample.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpring3D/draw_sample.m",
                  "Children": [],
                  "Class": "GraphSpring3D",
                  "Method": "draw_sample"
                },
                {
                  "Name": "GraphSpring3D.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpring3D/GraphSpring3D.m",
                  "Children": [],
                  "Class": "GraphSpring3D"
                }
              ]
            },
            {
              "Name": "@GraphSpringBase",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase",
              "Children": [
                {
                  "Name": "apply_selection.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase/apply_selection.m",
                  "Children": [],
                  "Class": "GraphSpringBase",
                  "Method": "apply_selection"
                },
                {
                  "Name": "control_list.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase/control_list.m",
                  "Children": [],
                  "Class": "GraphSpringBase",
                  "Method": "control_list"
                },
                {
                  "Name": "element_table.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase/element_table.m",
                  "Children": [],
                  "Class": "GraphSpringBase",
                  "Method": "element_table"
                },
                {
                  "Name": "get_layout.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase/get_layout.m",
                  "Children": [],
                  "Class": "GraphSpringBase",
                  "Method": "get_layout"
                },
                {
                  "Name": "GraphSpringBase.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase/GraphSpringBase.m",
                  "Children": [],
                  "Class": "GraphSpringBase"
                },
                {
                  "Name": "load_data.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase/load_data.m",
                  "Children": [],
                  "Class": "GraphSpringBase",
                  "Method": "load_data"
                },
                {
                  "Name": "set_position.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase/set_position.m",
                  "Children": [],
                  "Class": "GraphSpringBase",
                  "Method": "set_position"
                },
                {
                  "Name": "style_properties.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase/style_properties.m",
                  "Children": [],
                  "Class": "GraphSpringBase",
                  "Method": "style_properties"
                },
                {
                  "Name": "update_scene.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@GraphSpringBase/update_scene.m",
                  "Children": [],
                  "Class": "GraphSpringBase",
                  "Method": "update_scene"
                }
              ]
            },
            {
              "Name": "@HistoryGUILDA",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/private",
                  "Children": [
                    {
                      "Name": "eval_workspace.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/private/eval_workspace.m",
                      "Children": [],
                      "Class": "HistoryGUILDA"
                    },
                    {
                      "Name": "open_line.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/private/open_line.m",
                      "Children": [],
                      "Class": "HistoryGUILDA"
                    },
                    {
                      "Name": "render_view.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/private/render_view.m",
                      "Children": [],
                      "Class": "HistoryGUILDA"
                    }
                  ]
                },
                {
                  "Name": "attach_view.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/attach_view.m",
                  "Children": [],
                  "Class": "HistoryGUILDA",
                  "Method": "attach_view"
                },
                {
                  "Name": "export_script.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/export_script.m",
                  "Children": [],
                  "Class": "HistoryGUILDA",
                  "Method": "export_script"
                },
                {
                  "Name": "get_script.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/get_script.m",
                  "Children": [],
                  "Class": "HistoryGUILDA",
                  "Method": "get_script"
                },
                {
                  "Name": "get_variable.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/get_variable.m",
                  "Children": [],
                  "Class": "HistoryGUILDA",
                  "Method": "get_variable"
                },
                {
                  "Name": "HistoryGUILDA.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/HistoryGUILDA.m",
                  "Children": [],
                  "Class": "HistoryGUILDA"
                },
                {
                  "Name": "run.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/run.m",
                  "Children": [],
                  "Class": "HistoryGUILDA",
                  "Method": "run"
                },
                {
                  "Name": "set_variable.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/set_variable.m",
                  "Children": [],
                  "Class": "HistoryGUILDA",
                  "Method": "set_variable"
                }
              ]
            },
            {
              "Name": "@LayerPackage",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@LayerPackage",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/private",
                  "Children": [
                    {
                      "Name": "snapshot.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/private/snapshot.m",
                      "Children": [],
                      "Class": "LayerPackage"
                    },
                    {
                      "Name": "tag_key.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/private/tag_key.m",
                      "Children": [],
                      "Class": "LayerPackage"
                    }
                  ]
                },
                {
                  "Name": "attach_tag.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/attach_tag.m",
                  "Children": [],
                  "Class": "LayerPackage",
                  "Method": "attach_tag"
                },
                {
                  "Name": "disp_tree.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/disp_tree.m",
                  "Children": [],
                  "Class": "LayerPackage",
                  "Method": "disp_tree"
                },
                {
                  "Name": "gui_content.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/gui_content.m",
                  "Children": [],
                  "Class": "LayerPackage",
                  "Method": "gui_content"
                },
                {
                  "Name": "handle_edit.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/handle_edit.m",
                  "Children": [],
                  "Class": "LayerPackage",
                  "Method": "handle_edit"
                },
                {
                  "Name": "launch_gui.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/launch_gui.m",
                  "Children": [],
                  "Class": "LayerPackage",
                  "Method": "launch_gui"
                },
                {
                  "Name": "LayerPackage.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/LayerPackage.m",
                  "Children": [],
                  "Class": "LayerPackage"
                },
                {
                  "Name": "log_edit.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/log_edit.m",
                  "Children": [],
                  "Class": "LayerPackage",
                  "Method": "log_edit"
                },
                {
                  "Name": "string.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/string.m",
                  "Children": [],
                  "Class": "LayerPackage",
                  "Method": "string"
                },
                {
                  "Name": "struct.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/struct.m",
                  "Children": [],
                  "Class": "LayerPackage",
                  "Method": "struct"
                },
                {
                  "Name": "table.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@LayerPackage/table.m",
                  "Children": [],
                  "Class": "LayerPackage",
                  "Method": "table"
                }
              ]
            },
            {
              "Name": "@MethodBase",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@MethodBase",
              "Children": [
                {
                  "Name": "eval_jacobian.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodBase/eval_jacobian.m",
                  "Children": [],
                  "Class": "MethodBase",
                  "Method": "eval_jacobian"
                },
                {
                  "Name": "make_output.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodBase/make_output.m",
                  "Children": [],
                  "Class": "MethodBase",
                  "Method": "make_output"
                },
                {
                  "Name": "MethodBase.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
                  "Children": [],
                  "Class": "MethodBase"
                },
                {
                  "Name": "print_iter.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodBase/print_iter.m",
                  "Children": [],
                  "Class": "MethodBase",
                  "Method": "print_iter"
                },
                {
                  "Name": "set_options.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodBase/set_options.m",
                  "Children": [],
                  "Class": "MethodBase",
                  "Method": "set_options"
                }
              ]
            },
            {
              "Name": "@MethodDynamic",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@MethodDynamic",
              "Children": [
                {
                  "Name": "MethodDynamic.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
                  "Children": [],
                  "Class": "MethodDynamic"
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodDynamic/solve.m",
                  "Children": [],
                  "Class": "MethodDynamic",
                  "Method": "solve"
                }
              ]
            },
            {
              "Name": "@MethodFsolve",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@MethodFsolve",
              "Children": [
                {
                  "Name": "MethodFsolve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodFsolve/MethodFsolve.m",
                  "Children": [],
                  "Class": "MethodFsolve"
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodFsolve/solve.m",
                  "Children": [],
                  "Class": "MethodFsolve",
                  "Method": "solve"
                }
              ]
            },
            {
              "Name": "@MethodGradient",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@MethodGradient",
              "Children": [
                {
                  "Name": "MethodGradient.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodGradient/MethodGradient.m",
                  "Children": [],
                  "Class": "MethodGradient"
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodGradient/solve.m",
                  "Children": [],
                  "Class": "MethodGradient",
                  "Method": "solve"
                }
              ]
            },
            {
              "Name": "@MethodLevenbergMarquardt",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@MethodLevenbergMarquardt",
              "Children": [
                {
                  "Name": "MethodLevenbergMarquardt.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodLevenbergMarquardt/MethodLevenbergMarquardt.m",
                  "Children": [],
                  "Class": "MethodLevenbergMarquardt"
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodLevenbergMarquardt/solve.m",
                  "Children": [],
                  "Class": "MethodLevenbergMarquardt",
                  "Method": "solve"
                }
              ]
            },
            {
              "Name": "@MethodNewtonRaphson",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@MethodNewtonRaphson",
              "Children": [
                {
                  "Name": "has_symbolic.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodNewtonRaphson/has_symbolic.m",
                  "Children": [],
                  "Class": "MethodNewtonRaphson",
                  "Method": "has_symbolic"
                },
                {
                  "Name": "MethodNewtonRaphson.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodNewtonRaphson/MethodNewtonRaphson.m",
                  "Children": [],
                  "Class": "MethodNewtonRaphson"
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@MethodNewtonRaphson/solve.m",
                  "Children": [],
                  "Class": "MethodNewtonRaphson",
                  "Method": "solve"
                }
              ]
            },
            {
              "Name": "@Parameter",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@Parameter",
              "Children": [
                {
                  "Name": "Parameter.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Parameter/Parameter.m",
                  "Children": [],
                  "Class": "Parameter"
                }
              ]
            },
            {
              "Name": "@PowerSystemModel",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@PowerSystemModel",
              "Children": [
                {
                  "Name": "doc.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@PowerSystemModel/doc.m",
                  "Children": [],
                  "Class": "PowerSystemModel",
                  "Method": "doc"
                },
                {
                  "Name": "get_Hz.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@PowerSystemModel/get_Hz.m",
                  "Children": [],
                  "Class": "PowerSystemModel",
                  "Method": "get_Hz"
                },
                {
                  "Name": "get_sys.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@PowerSystemModel/get_sys.m",
                  "Children": [],
                  "Class": "PowerSystemModel",
                  "Method": "get_sys"
                },
                {
                  "Name": "PowerSystemModel.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
                  "Children": [],
                  "Class": "PowerSystemModel"
                }
              ]
            },
            {
              "Name": "@ProgressGUILDA",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@ProgressGUILDA",
              "Children": [
                {
                  "Name": "dialogFcn.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ProgressGUILDA/dialogFcn.m",
                  "Children": [],
                  "Class": "ProgressGUILDA",
                  "Method": "dialogFcn"
                },
                {
                  "Name": "disp_header.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ProgressGUILDA/disp_header.m",
                  "Children": [],
                  "Class": "ProgressGUILDA",
                  "Method": "disp_header"
                },
                {
                  "Name": "disp_init.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ProgressGUILDA/disp_init.m",
                  "Children": [],
                  "Class": "ProgressGUILDA",
                  "Method": "disp_init"
                },
                {
                  "Name": "dispFcn.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ProgressGUILDA/dispFcn.m",
                  "Children": [],
                  "Class": "ProgressGUILDA",
                  "Method": "dispFcn"
                },
                {
                  "Name": "Events.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ProgressGUILDA/Events.m",
                  "Children": [],
                  "Class": "ProgressGUILDA",
                  "Method": "Events"
                },
                {
                  "Name": "ProgressGUILDA.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ProgressGUILDA/ProgressGUILDA.m",
                  "Children": [],
                  "Class": "ProgressGUILDA"
                },
                {
                  "Name": "time_keeper.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ProgressGUILDA/time_keeper.m",
                  "Children": [],
                  "Class": "ProgressGUILDA",
                  "Method": "time_keeper"
                },
                {
                  "Name": "update.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ProgressGUILDA/update.m",
                  "Children": [],
                  "Class": "ProgressGUILDA",
                  "Method": "update"
                }
              ]
            },
            {
              "Name": "@ResultBase",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@ResultBase",
              "Children": [
                {
                  "Name": "error_unsupported.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultBase/error_unsupported.m",
                  "Children": [],
                  "Class": "ResultBase",
                  "Method": "error_unsupported"
                },
                {
                  "Name": "export.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultBase/export.m",
                  "Children": [],
                  "Class": "ResultBase",
                  "Method": "export"
                },
                {
                  "Name": "is_success.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultBase/is_success.m",
                  "Children": [],
                  "Class": "ResultBase",
                  "Method": "is_success"
                },
                {
                  "Name": "launch_gui.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultBase/launch_gui.m",
                  "Children": [],
                  "Class": "ResultBase",
                  "Method": "launch_gui"
                },
                {
                  "Name": "ResultBase.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
                  "Children": [],
                  "Class": "ResultBase"
                }
              ]
            },
            {
              "Name": "@ResultCPF",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@ResultCPF",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/private",
                  "Children": [
                    {
                      "Name": "check_step_data.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/private/check_step_data.m",
                      "Children": [],
                      "Class": "ResultCPF"
                    },
                    {
                      "Name": "pair_pvcurve.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/private/pair_pvcurve.m",
                      "Children": [],
                      "Class": "ResultCPF"
                    },
                    {
                      "Name": "step_sample.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/private/step_sample.m",
                      "Children": [],
                      "Class": "ResultCPF"
                    }
                  ]
                },
                {
                  "Name": "export.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/export.m",
                  "Children": [],
                  "Class": "ResultCPF",
                  "Method": "export"
                },
                {
                  "Name": "get_point.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/get_point.m",
                  "Children": [],
                  "Class": "ResultCPF",
                  "Method": "get_point"
                },
                {
                  "Name": "plot_branch.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_branch.m",
                  "Children": [],
                  "Class": "ResultCPF",
                  "Method": "plot_branch"
                },
                {
                  "Name": "plot_diagram.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_diagram.m",
                  "Children": [],
                  "Class": "ResultCPF",
                  "Method": "plot_diagram"
                },
                {
                  "Name": "plot_generator.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_generator.m",
                  "Children": [],
                  "Class": "ResultCPF",
                  "Method": "plot_generator"
                },
                {
                  "Name": "plot_pqv.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_pqv.m",
                  "Children": [],
                  "Class": "ResultCPF",
                  "Method": "plot_pqv"
                },
                {
                  "Name": "plot_pvcurve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_pvcurve.m",
                  "Children": [],
                  "Class": "ResultCPF",
                  "Method": "plot_pvcurve"
                },
                {
                  "Name": "plot_spring_model.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_spring_model.m",
                  "Children": [],
                  "Class": "ResultCPF",
                  "Method": "plot_spring_model"
                },
                {
                  "Name": "plot_stability_index.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_stability_index.m",
                  "Children": [],
                  "Class": "ResultCPF",
                  "Method": "plot_stability_index"
                },
                {
                  "Name": "ResultCPF.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
                  "Children": [],
                  "Class": "ResultCPF"
                }
              ]
            },
            {
              "Name": "@ResultLIN",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@ResultLIN",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private",
                  "Children": [
                    {
                      "Name": "bus_variables.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/bus_variables.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "contribution_part.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/contribution_part.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "datatip_wrap.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/datatip_wrap.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "default_port.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/default_port.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "eigen_sorted.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/eigen_sorted.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "mode_diagram.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/mode_diagram.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "mustBeSection.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/mustBeSection.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "section_diagram.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/section_diagram.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "section_eigenvalues.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/section_eigenvalues.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "section_list.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/section_list.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "section_model.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/section_model.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "sorted_modes.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/sorted_modes.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "state_owner.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/state_owner.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    },
                    {
                      "Name": "target_owner.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/private/target_owner.m",
                      "Children": [],
                      "Class": "ResultLIN"
                    }
                  ]
                },
                {
                  "Name": "disp_mode.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/disp_mode.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "disp_mode"
                },
                {
                  "Name": "disp_summary.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/disp_summary.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "disp_summary"
                },
                {
                  "Name": "get_contribution.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/get_contribution.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "get_contribution"
                },
                {
                  "Name": "get_eigenvalue.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/get_eigenvalue.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "get_eigenvalue"
                },
                {
                  "Name": "get_eigenvector.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/get_eigenvector.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "get_eigenvector"
                },
                {
                  "Name": "get_kernel.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/get_kernel.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "get_kernel"
                },
                {
                  "Name": "get_mode.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/get_mode.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "get_mode"
                },
                {
                  "Name": "get_participation.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/get_participation.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "get_participation"
                },
                {
                  "Name": "get_reduced_matrix.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/get_reduced_matrix.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "get_reduced_matrix"
                },
                {
                  "Name": "get_ss.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/get_ss.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "get_ss"
                },
                {
                  "Name": "plot_contribution.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_contribution.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "plot_contribution"
                },
                {
                  "Name": "plot_eigenvalue.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_eigenvalue.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "plot_eigenvalue"
                },
                {
                  "Name": "plot_eigenvalue_path.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_eigenvalue_path.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "plot_eigenvalue_path"
                },
                {
                  "Name": "plot_eigenvector.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_eigenvector.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "plot_eigenvector"
                },
                {
                  "Name": "plot_kernel.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_kernel.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "plot_kernel"
                },
                {
                  "Name": "plot_matrix.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_matrix.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "plot_matrix"
                },
                {
                  "Name": "plot_participation.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_participation.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "plot_participation"
                },
                {
                  "Name": "plot_reduced_matrix.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_reduced_matrix.m",
                  "Children": [],
                  "Class": "ResultLIN",
                  "Method": "plot_reduced_matrix"
                },
                {
                  "Name": "ResultLIN.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
                  "Children": [],
                  "Class": "ResultLIN"
                }
              ]
            },
            {
              "Name": "@ResultODE",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@ResultODE",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/private",
                  "Children": [
                    {
                      "Name": "center_of_inertia.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultODE/private/center_of_inertia.m",
                      "Children": [],
                      "Class": "ResultODE"
                    },
                    {
                      "Name": "draw_with_chart.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultODE/private/draw_with_chart.m",
                      "Children": [],
                      "Class": "ResultODE"
                    },
                    {
                      "Name": "output_trajectory.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultODE/private/output_trajectory.m",
                      "Children": [],
                      "Class": "ResultODE"
                    },
                    {
                      "Name": "simulator_columns.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultODE/private/simulator_columns.m",
                      "Children": [],
                      "Class": "ResultODE"
                    }
                  ]
                },
                {
                  "Name": "build_view.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/build_view.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "build_view"
                },
                {
                  "Name": "columns_of.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/columns_of.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "columns_of"
                },
                {
                  "Name": "export.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/export.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "export"
                },
                {
                  "Name": "get_point.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/get_point.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "get_point"
                },
                {
                  "Name": "get_trajectory.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/get_trajectory.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "get_trajectory"
                },
                {
                  "Name": "judge_out_of_step.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/judge_out_of_step.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "judge_out_of_step"
                },
                {
                  "Name": "plot_diagram.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/plot_diagram.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "plot_diagram"
                },
                {
                  "Name": "plot_pqv.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/plot_pqv.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "plot_pqv"
                },
                {
                  "Name": "plot_spring_model.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/plot_spring_model.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "plot_spring_model"
                },
                {
                  "Name": "plot_trajectory.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/plot_trajectory.m",
                  "Children": [],
                  "Class": "ResultODE",
                  "Method": "plot_trajectory"
                },
                {
                  "Name": "ResultODE.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
                  "Children": [],
                  "Class": "ResultODE"
                }
              ]
            },
            {
              "Name": "@ResultOPF",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@ResultOPF",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/private",
                  "Children": [
                    {
                      "Name": "binding_table.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/private/binding_table.m",
                      "Children": [],
                      "Class": "ResultOPF"
                    },
                    {
                      "Name": "branch_ends.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/private/branch_ends.m",
                      "Children": [],
                      "Class": "ResultOPF"
                    },
                    {
                      "Name": "diagram_state.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/private/diagram_state.m",
                      "Children": [],
                      "Class": "ResultOPF"
                    }
                  ]
                },
                {
                  "Name": "disp_binding.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/disp_binding.m",
                  "Children": [],
                  "Class": "ResultOPF",
                  "Method": "disp_binding"
                },
                {
                  "Name": "disp_summary.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/disp_summary.m",
                  "Children": [],
                  "Class": "ResultOPF",
                  "Method": "disp_summary"
                },
                {
                  "Name": "export.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/export.m",
                  "Children": [],
                  "Class": "ResultOPF",
                  "Method": "export"
                },
                {
                  "Name": "get_lmp.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/get_lmp.m",
                  "Children": [],
                  "Class": "ResultOPF",
                  "Method": "get_lmp"
                },
                {
                  "Name": "get_summary.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/get_summary.m",
                  "Children": [],
                  "Class": "ResultOPF",
                  "Method": "get_summary"
                },
                {
                  "Name": "is_success.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/is_success.m",
                  "Children": [],
                  "Class": "ResultOPF",
                  "Method": "is_success"
                },
                {
                  "Name": "plot_dispatch.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/plot_dispatch.m",
                  "Children": [],
                  "Class": "ResultOPF",
                  "Method": "plot_dispatch"
                },
                {
                  "Name": "plot_iteration.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/plot_iteration.m",
                  "Children": [],
                  "Class": "ResultOPF",
                  "Method": "plot_iteration"
                },
                {
                  "Name": "plot_lmp.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/plot_lmp.m",
                  "Children": [],
                  "Class": "ResultOPF",
                  "Method": "plot_lmp"
                },
                {
                  "Name": "ResultOPF.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
                  "Children": [],
                  "Class": "ResultOPF"
                }
              ]
            },
            {
              "Name": "@ResultPF",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@ResultPF",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/private",
                  "Children": [
                    {
                      "Name": "branch_flow.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultPF/private/branch_flow.m",
                      "Children": [],
                      "Class": "ResultPF"
                    },
                    {
                      "Name": "bus_data.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultPF/private/bus_data.m",
                      "Children": [],
                      "Class": "ResultPF"
                    },
                    {
                      "Name": "bus_index.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultPF/private/bus_index.m",
                      "Children": [],
                      "Class": "ResultPF"
                    },
                    {
                      "Name": "history_residual.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultPF/private/history_residual.m",
                      "Children": [],
                      "Class": "ResultPF"
                    },
                    {
                      "Name": "pick_rows.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultPF/private/pick_rows.m",
                      "Children": [],
                      "Class": "ResultPF"
                    },
                    {
                      "Name": "rows_to_table.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultPF/private/rows_to_table.m",
                      "Children": [],
                      "Class": "ResultPF"
                    },
                    {
                      "Name": "show_text.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultPF/private/show_text.m",
                      "Children": [],
                      "Class": "ResultPF"
                    },
                    {
                      "Name": "violation_table.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@ResultPF/private/violation_table.m",
                      "Children": [],
                      "Class": "ResultPF"
                    }
                  ]
                },
                {
                  "Name": "disp_branch.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/disp_branch.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "disp_branch"
                },
                {
                  "Name": "disp_bus.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/disp_bus.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "disp_bus"
                },
                {
                  "Name": "disp_summary.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/disp_summary.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "disp_summary"
                },
                {
                  "Name": "disp_violation.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/disp_violation.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "disp_violation"
                },
                {
                  "Name": "export.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/export.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "export"
                },
                {
                  "Name": "get_summary.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/get_summary.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "get_summary"
                },
                {
                  "Name": "plot_branch.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/plot_branch.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "plot_branch"
                },
                {
                  "Name": "plot_convergence.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/plot_convergence.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "plot_convergence"
                },
                {
                  "Name": "plot_diagram.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/plot_diagram.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "plot_diagram"
                },
                {
                  "Name": "plot_single_line_diagram.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/plot_single_line_diagram.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "plot_single_line_diagram"
                },
                {
                  "Name": "plot_spring_model.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/plot_spring_model.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "plot_spring_model"
                },
                {
                  "Name": "plot_voltage.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/plot_voltage.m",
                  "Children": [],
                  "Class": "ResultPF",
                  "Method": "plot_voltage"
                },
                {
                  "Name": "ResultPF.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
                  "Children": [],
                  "Class": "ResultPF"
                }
              ]
            },
            {
              "Name": "@Scenario",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@Scenario",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/private",
                  "Children": [
                    {
                      "Name": "blank_record.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@Scenario/private/blank_record.m",
                      "Children": [],
                      "Class": "Scenario"
                    },
                    {
                      "Name": "checkValueCount.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@Scenario/private/checkValueCount.m",
                      "Children": [],
                      "Class": "Scenario"
                    },
                    {
                      "Name": "empty_disturbances.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@Scenario/private/empty_disturbances.m",
                      "Children": [],
                      "Class": "Scenario"
                    },
                    {
                      "Name": "get_record.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@Scenario/private/get_record.m",
                      "Children": [],
                      "Class": "Scenario"
                    },
                    {
                      "Name": "validate_disturbance.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@Scenario/private/validate_disturbance.m",
                      "Children": [],
                      "Class": "Scenario"
                    },
                    {
                      "Name": "validate_events.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@Scenario/private/validate_events.m",
                      "Children": [],
                      "Class": "Scenario"
                    }
                  ]
                },
                {
                  "Name": "add_fault.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/add_fault.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "add_fault"
                },
                {
                  "Name": "add_from_json_struct.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/add_from_json_struct.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "add_from_json_struct"
                },
                {
                  "Name": "add_input.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/add_input.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "add_input"
                },
                {
                  "Name": "add_offset.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/add_offset.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "add_offset"
                },
                {
                  "Name": "add_open_branch.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/add_open_branch.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "add_open_branch"
                },
                {
                  "Name": "add_trip.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/add_trip.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "add_trip"
                },
                {
                  "Name": "compile.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/compile.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "compile"
                },
                {
                  "Name": "gui_content.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/gui_content.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "gui_content"
                },
                {
                  "Name": "insert_event.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/insert_event.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "insert_event"
                },
                {
                  "Name": "log_edit.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/log_edit.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "log_edit"
                },
                {
                  "Name": "remove_event.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/remove_event.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "remove_event"
                },
                {
                  "Name": "Scenario.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
                  "Children": [],
                  "Class": "Scenario"
                },
                {
                  "Name": "to_json_struct.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/to_json_struct.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "to_json_struct"
                },
                {
                  "Name": "validate.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@Scenario/validate.m",
                  "Children": [],
                  "Class": "Scenario",
                  "Method": "validate"
                }
              ]
            },
            {
              "Name": "@SolverCPF",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@SolverCPF",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private",
                  "Children": [
                    {
                      "Name": "build_layout.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private/build_layout.m",
                      "Children": [],
                      "Class": "SolverCPF"
                    },
                    {
                      "Name": "correct.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private/correct.m",
                      "Children": [],
                      "Class": "SolverCPF"
                    },
                    {
                      "Name": "correct_at.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private/correct_at.m",
                      "Children": [],
                      "Class": "SolverCPF"
                    },
                    {
                      "Name": "limit_set.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private/limit_set.m",
                      "Children": [],
                      "Class": "SolverCPF"
                    },
                    {
                      "Name": "limit_values.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private/limit_values.m",
                      "Children": [],
                      "Class": "SolverCPF"
                    },
                    {
                      "Name": "live_pvcurve.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private/live_pvcurve.m",
                      "Children": [],
                      "Class": "SolverCPF"
                    },
                    {
                      "Name": "operating_points.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private/operating_points.m",
                      "Children": [],
                      "Class": "SolverCPF"
                    },
                    {
                      "Name": "pf_equation.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private/pf_equation.m",
                      "Children": [],
                      "Class": "SolverCPF"
                    },
                    {
                      "Name": "predict.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/private/predict.m",
                      "Children": [],
                      "Class": "SolverCPF"
                    }
                  ]
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/solve.m",
                  "Children": [],
                  "Class": "SolverCPF",
                  "Method": "solve"
                },
                {
                  "Name": "SolverCPF.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverCPF/SolverCPF.m",
                  "Children": [],
                  "Class": "SolverCPF"
                }
              ]
            },
            {
              "Name": "@SolverLIN",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@SolverLIN",
              "Children": [
                {
                  "Name": "check_point.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverLIN/check_point.m",
                  "Children": [],
                  "Class": "SolverLIN",
                  "Method": "check_point"
                },
                {
                  "Name": "point_vector.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverLIN/point_vector.m",
                  "Children": [],
                  "Class": "SolverLIN",
                  "Method": "point_vector"
                },
                {
                  "Name": "reduce.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverLIN/reduce.m",
                  "Children": [],
                  "Class": "SolverLIN",
                  "Method": "reduce"
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverLIN/solve.m",
                  "Children": [],
                  "Class": "SolverLIN",
                  "Method": "solve"
                },
                {
                  "Name": "SolverLIN.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverLIN/SolverLIN.m",
                  "Children": [],
                  "Class": "SolverLIN"
                }
              ]
            },
            {
              "Name": "@SolverODE",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@SolverODE",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/private",
                  "Children": [
                    {
                      "Name": "CalculateInitialCondition.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverODE/private/CalculateInitialCondition.m",
                      "Children": [],
                      "Class": "SolverODE"
                    },
                    {
                      "Name": "makeODE.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverODE/private/makeODE.m",
                      "Children": [],
                      "Class": "SolverODE"
                    },
                    {
                      "Name": "phase_points.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverODE/private/phase_points.m",
                      "Children": [],
                      "Class": "SolverODE"
                    }
                  ]
                },
                {
                  "Name": "build_index.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/build_index.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "build_index"
                },
                {
                  "Name": "getNextPhase.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/getNextPhase.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "getNextPhase"
                },
                {
                  "Name": "getODEFunction.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/getODEFunction.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "getODEFunction"
                },
                {
                  "Name": "getODEJacobian.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/getODEJacobian.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "getODEJacobian"
                },
                {
                  "Name": "initial_condition.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/initial_condition.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "initial_condition"
                },
                {
                  "Name": "is_false_index_error.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/is_false_index_error.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "is_false_index_error"
                },
                {
                  "Name": "is_numerical_failure.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/is_numerical_failure.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "is_numerical_failure"
                },
                {
                  "Name": "phase_result.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/phase_result.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "phase_result"
                },
                {
                  "Name": "set_admittance.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/set_admittance.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "set_admittance"
                },
                {
                  "Name": "set_equations.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/set_equations.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "set_equations"
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/solve.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "solve"
                },
                {
                  "Name": "solve_differential.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/solve_differential.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "solve_differential"
                },
                {
                  "Name": "SolverODE.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/SolverODE.m",
                  "Children": [],
                  "Class": "SolverODE"
                },
                {
                  "Name": "use_dense.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverODE/use_dense.m",
                  "Children": [],
                  "Class": "SolverODE",
                  "Method": "use_dense"
                }
              ]
            },
            {
              "Name": "@SolverOPF",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@SolverOPF",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/private",
                  "Children": [
                    {
                      "Name": "apply.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/private/apply.m",
                      "Children": [],
                      "Class": "SolverOPF"
                    },
                    {
                      "Name": "branch_flow.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/private/branch_flow.m",
                      "Children": [],
                      "Class": "SolverOPF"
                    },
                    {
                      "Name": "build_branch.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/private/build_branch.m",
                      "Children": [],
                      "Class": "SolverOPF"
                    },
                    {
                      "Name": "build_bus.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/private/build_bus.m",
                      "Children": [],
                      "Class": "SolverOPF"
                    },
                    {
                      "Name": "build_component.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/private/build_component.m",
                      "Children": [],
                      "Class": "SolverOPF"
                    },
                    {
                      "Name": "start_point.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/private/start_point.m",
                      "Children": [],
                      "Class": "SolverOPF"
                    },
                    {
                      "Name": "variables.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/private/variables.m",
                      "Children": [],
                      "Class": "SolverOPF"
                    }
                  ]
                },
                {
                  "Name": "build_problem.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/build_problem.m",
                  "Children": [],
                  "Class": "SolverOPF",
                  "Method": "build_problem"
                },
                {
                  "Name": "disp_formulation.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/disp_formulation.m",
                  "Children": [],
                  "Class": "SolverOPF",
                  "Method": "disp_formulation"
                },
                {
                  "Name": "optimoption.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/optimoption.m",
                  "Children": [],
                  "Class": "SolverOPF",
                  "Method": "optimoption"
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/solve.m",
                  "Children": [],
                  "Class": "SolverOPF",
                  "Method": "solve"
                },
                {
                  "Name": "SolverOPF.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverOPF/SolverOPF.m",
                  "Children": [],
                  "Class": "SolverOPF"
                }
              ]
            },
            {
              "Name": "@SolverPF",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/@SolverPF",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverPF/private",
                  "Children": [
                    {
                      "Name": "live_residual.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverPF/private/live_residual.m",
                      "Children": [],
                      "Class": "SolverPF"
                    },
                    {
                      "Name": "power_equation.m",
                      "Kind": "file",
                      "Path": "_GUILDAsystem/_auxiliary/@SolverPF/private/power_equation.m",
                      "Children": [],
                      "Class": "SolverPF"
                    }
                  ]
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverPF/solve.m",
                  "Children": [],
                  "Class": "SolverPF",
                  "Method": "solve"
                },
                {
                  "Name": "SolverPF.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/@SolverPF/SolverPF.m",
                  "Children": [],
                  "Class": "SolverPF"
                }
              ]
            },
            {
              "Name": "SystemTools",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_auxiliary/SystemTools",
              "Children": [
                {
                  "Name": "msg.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/SystemTools/msg.m",
                  "Children": []
                },
                {
                  "Name": "mustBeSimulationTime.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/SystemTools/mustBeSimulationTime.m",
                  "Children": []
                },
                {
                  "Name": "show_msg.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_auxiliary/SystemTools/show_msg.m",
                  "Children": []
                }
              ]
            },
            {
              "Name": "GraphEventData.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/_auxiliary/GraphEventData.m",
              "Children": [],
              "Class": "GraphEventData"
            },
            {
              "Name": "GraphTimeEventData.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/_auxiliary/GraphTimeEventData.m",
              "Children": [],
              "Class": "GraphTimeEventData"
            }
          ]
        },
        {
          "Name": "_VersionSupport",
          "Kind": "folder",
          "Path": "_GUILDAsystem/_VersionSupport",
          "Children": [
            {
              "Name": "@ContinuationPowerFlowV3",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3",
              "Children": [
                {
                  "Name": "ContinuationPowerFlowV3.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
                  "Children": [],
                  "Class": "ContinuationPowerFlowV3"
                },
                {
                  "Name": "solve.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/solve.m",
                  "Children": [],
                  "Class": "ContinuationPowerFlowV3",
                  "Method": "solve"
                }
              ]
            },
            {
              "Name": "@CsvNetHandler",
              "Kind": "folder",
              "Path": "_GUILDAsystem/_VersionSupport/@CsvNetHandler",
              "Children": [
                {
                  "Name": "CsvNetHandler.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_VersionSupport/@CsvNetHandler/CsvNetHandler.m",
                  "Children": [],
                  "Class": "CsvNetHandler"
                },
                {
                  "Name": "export.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_VersionSupport/@CsvNetHandler/export.m",
                  "Children": [],
                  "Class": "CsvNetHandler",
                  "Method": "export"
                },
                {
                  "Name": "import.m",
                  "Kind": "file",
                  "Path": "_GUILDAsystem/_VersionSupport/@CsvNetHandler/import.m",
                  "Children": [],
                  "Class": "CsvNetHandler",
                  "Method": "import"
                }
              ]
            },
            {
              "Name": "Continuation_Power_Flow.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/_VersionSupport/Continuation_Power_Flow.m",
              "Children": []
            },
            {
              "Name": "Deprecated.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/_VersionSupport/Deprecated.m",
              "Children": []
            },
            {
              "Name": "legacy_output.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/_VersionSupport/legacy_output.m",
              "Children": []
            },
            {
              "Name": "v3_bus_baseMVA.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/_VersionSupport/v3_bus_baseMVA.m",
              "Children": []
            },
            {
              "Name": "v3_cpf_constructor.m",
              "Kind": "file",
              "Path": "_GUILDAsystem/_VersionSupport/v3_cpf_constructor.m",
              "Children": []
            }
          ]
        }
      ]
    },
    {
      "Name": "Object",
      "Kind": "folder",
      "Path": "_GUILDAobject",
      "Children": [
        {
          "Name": "+branch",
          "Kind": "folder",
          "Path": "_GUILDAobject/+branch",
          "Children": [
            {
              "Name": "@pi",
              "Kind": "folder",
              "Path": "_GUILDAobject/+branch/@pi",
              "Children": [
                {
                  "Name": "get_admittance_matrix.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+branch/@pi/get_admittance_matrix.m",
                  "Children": [],
                  "Class": "branch.pi",
                  "Method": "get_admittance_matrix"
                },
                {
                  "Name": "pi.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+branch/@pi/pi.m",
                  "Children": [],
                  "Class": "branch.pi"
                }
              ]
            },
            {
              "Name": "@pi_transformer",
              "Kind": "folder",
              "Path": "_GUILDAobject/+branch/@pi_transformer",
              "Children": [
                {
                  "Name": "get_admittance_matrix.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+branch/@pi_transformer/get_admittance_matrix.m",
                  "Children": [],
                  "Class": "branch.pi_transformer",
                  "Method": "get_admittance_matrix"
                },
                {
                  "Name": "pi_transformer.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+branch/@pi_transformer/pi_transformer.m",
                  "Children": [],
                  "Class": "branch.pi_transformer"
                }
              ]
            },
            {
              "Name": "@T",
              "Kind": "folder",
              "Path": "_GUILDAobject/+branch/@T",
              "Children": [
                {
                  "Name": "get_admittance_matrix.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+branch/@T/get_admittance_matrix.m",
                  "Children": [],
                  "Class": "branch.T",
                  "Method": "get_admittance_matrix"
                },
                {
                  "Name": "T.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+branch/@T/T.m",
                  "Children": [],
                  "Class": "branch.T"
                }
              ]
            },
            {
              "Name": "@two_winding_transformer",
              "Kind": "folder",
              "Path": "_GUILDAobject/+branch/@two_winding_transformer",
              "Children": [
                {
                  "Name": "get_admittance_matrix.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+branch/@two_winding_transformer/get_admittance_matrix.m",
                  "Children": [],
                  "Class": "branch.two_winding_transformer",
                  "Method": "get_admittance_matrix"
                },
                {
                  "Name": "two_winding_transformer.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+branch/@two_winding_transformer/two_winding_transformer.m",
                  "Children": [],
                  "Class": "branch.two_winding_transformer"
                }
              ]
            }
          ]
        },
        {
          "Name": "+component",
          "Kind": "folder",
          "Path": "_GUILDAobject/+component",
          "Children": [
            {
              "Name": "+ConstSource",
              "Kind": "folder",
              "Path": "_GUILDAobject/+component/+ConstSource",
              "Children": [
                {
                  "Name": "@power",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+ConstSource/@power",
                  "Children": [
                    {
                      "Name": "get_dx_constraint.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+ConstSource/@power/get_dx_constraint.m",
                      "Children": [],
                      "Class": "component.ConstSource.power",
                      "Method": "get_dx_constraint"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+ConstSource/@power/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.ConstSource.power",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_linear_matrix.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+ConstSource/@power/get_linear_matrix.m",
                      "Children": [],
                      "Class": "component.ConstSource.power",
                      "Method": "get_linear_matrix"
                    },
                    {
                      "Name": "naming_port.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+ConstSource/@power/naming_port.m",
                      "Children": [],
                      "Class": "component.ConstSource.power",
                      "Method": "naming_port"
                    },
                    {
                      "Name": "power.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+ConstSource/@power/power.m",
                      "Children": [],
                      "Class": "component.ConstSource.power"
                    }
                  ]
                }
              ]
            },
            {
              "Name": "+generator",
              "Kind": "folder",
              "Path": "_GUILDAobject/+component/+generator",
              "Children": [
                {
                  "Name": "@abstract",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+generator/@abstract",
                  "Children": [
                    {
                      "Name": "private",
                      "Kind": "folder",
                      "Path": "_GUILDAobject/+component/+generator/@abstract/private",
                      "Children": [
                        {
                          "Name": "check_key_role.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+component/+generator/@abstract/private/check_key_role.m",
                          "Children": [],
                          "Class": "component.generator.abstract"
                        }
                      ]
                    },
                    {
                      "Name": "abstract.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@abstract/abstract.m",
                      "Children": [],
                      "Class": "component.generator.abstract"
                    },
                    {
                      "Name": "energy_hessian_dq.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@abstract/energy_hessian_dq.m",
                      "Children": [],
                      "Class": "component.generator.abstract",
                      "Method": "energy_hessian_dq"
                    },
                    {
                      "Name": "set_avr.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@abstract/set_avr.m",
                      "Children": [],
                      "Class": "component.generator.abstract",
                      "Method": "set_avr"
                    },
                    {
                      "Name": "set_governor.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@abstract/set_governor.m",
                      "Children": [],
                      "Class": "component.generator.abstract",
                      "Method": "set_governor"
                    },
                    {
                      "Name": "set_pss.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@abstract/set_pss.m",
                      "Children": [],
                      "Class": "component.generator.abstract",
                      "Method": "set_pss"
                    }
                  ]
                },
                {
                  "Name": "@classical",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+generator/@classical",
                  "Children": [
                    {
                      "Name": "classical.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/classical.m",
                      "Children": [],
                      "Class": "component.generator.classical"
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/fcn_dx.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/fcn_I.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/fcn_Y.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/get_hessian.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "get_spring_node.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/get_spring_node.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "get_spring_node"
                    },
                    {
                      "Name": "getCompPQ.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/getCompPQ.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "getCompPQ"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@classical/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.generator.classical",
                      "Method": "Jacobi_Y"
                    }
                  ]
                },
                {
                  "Name": "@droop",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+generator/@droop",
                  "Children": [
                    {
                      "Name": "droop.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/droop.m",
                      "Children": [],
                      "Class": "component.generator.droop"
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/fcn_dx.m",
                      "Children": [],
                      "Class": "component.generator.droop",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/fcn_I.m",
                      "Children": [],
                      "Class": "component.generator.droop",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.generator.droop",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/fcn_Y.m",
                      "Children": [],
                      "Class": "component.generator.droop",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.generator.droop",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_spring_node.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/get_spring_node.m",
                      "Children": [],
                      "Class": "component.generator.droop",
                      "Method": "get_spring_node"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.generator.droop",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.generator.droop",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@droop/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.generator.droop",
                      "Method": "Jacobi_Y"
                    }
                  ]
                },
                {
                  "Name": "@one_axis",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+generator/@one_axis",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/fcn_dx.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/fcn_I.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/fcn_Y.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/get_hessian.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "get_spring_node.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/get_spring_node.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "get_spring_node"
                    },
                    {
                      "Name": "getCompPQ.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/getCompPQ.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "getCompPQ"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.generator.one_axis",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "one_axis.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@one_axis/one_axis.m",
                      "Children": [],
                      "Class": "component.generator.one_axis"
                    }
                  ]
                },
                {
                  "Name": "@park",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+generator/@park",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/fcn_dx.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/fcn_I.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/fcn_Y.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/get_hessian.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "get_spring_node.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/get_spring_node.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "get_spring_node"
                    },
                    {
                      "Name": "getCompPQ.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/getCompPQ.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "getCompPQ"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.generator.park",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "park.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@park/park.m",
                      "Children": [],
                      "Class": "component.generator.park"
                    }
                  ]
                },
                {
                  "Name": "@two_axis",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+generator/@two_axis",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/fcn_dx.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/fcn_I.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/fcn_Y.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/get_hessian.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "get_spring_node.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/get_spring_node.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "get_spring_node"
                    },
                    {
                      "Name": "getCompPQ.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/getCompPQ.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "getCompPQ"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.generator.two_axis",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "two_axis.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+generator/@two_axis/two_axis.m",
                      "Children": [],
                      "Class": "component.generator.two_axis"
                    }
                  ]
                }
              ]
            },
            {
              "Name": "+GFLInverter",
              "Kind": "folder",
              "Path": "_GUILDAobject/+component/+GFLInverter",
              "Children": [
                {
                  "Name": "@abstract",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+GFLInverter/@abstract",
                  "Children": [
                    {
                      "Name": "abstract.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@abstract/abstract.m",
                      "Children": [],
                      "Class": "component.GFLInverter.abstract"
                    }
                  ]
                },
                {
                  "Name": "@Static",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+GFLInverter/@Static",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/fcn_dx.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/fcn_I.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/fcn_Y.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/get_hessian.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "getCompPQ.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/getCompPQ.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "getCompPQ"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "Static.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFLInverter/@Static/Static.m",
                      "Children": [],
                      "Class": "component.GFLInverter.Static"
                    }
                  ]
                }
              ]
            },
            {
              "Name": "+GFMInverter",
              "Kind": "folder",
              "Path": "_GUILDAobject/+component/+GFMInverter",
              "Children": [
                {
                  "Name": "@abstract",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+GFMInverter/@abstract",
                  "Children": [
                    {
                      "Name": "abstract.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@abstract/abstract.m",
                      "Children": [],
                      "Class": "component.GFMInverter.abstract"
                    }
                  ]
                },
                {
                  "Name": "@VSG_classical",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/fcn_dx.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/fcn_I.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/fcn_Y.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/get_hessian.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "get_spring_node.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/get_spring_node.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "get_spring_node"
                    },
                    {
                      "Name": "getCompPQ.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/getCompPQ.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "getCompPQ"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "VSG_classical.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+GFMInverter/@VSG_classical/VSG_classical.m",
                      "Children": [],
                      "Class": "component.GFMInverter.VSG_classical"
                    }
                  ]
                }
              ]
            },
            {
              "Name": "+load",
              "Kind": "folder",
              "Path": "_GUILDAobject/+component/+load",
              "Children": [
                {
                  "Name": "@abstract",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+load/@abstract",
                  "Children": [
                    {
                      "Name": "abstract.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@abstract/abstract.m",
                      "Children": [],
                      "Class": "component.load.abstract"
                    }
                  ]
                },
                {
                  "Name": "@current",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+load/@current",
                  "Children": [
                    {
                      "Name": "current.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/current.m",
                      "Children": [],
                      "Class": "component.load.current"
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/fcn_dx.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/fcn_I.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/fcn_Y.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/get_hessian.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "getCompPQ.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/getCompPQ.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "getCompPQ"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@current/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.load.current",
                      "Method": "Jacobi_Y"
                    }
                  ]
                },
                {
                  "Name": "@impedance",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+load/@impedance",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/fcn_dx.m",
                      "Children": [],
                      "Class": "component.load.impedance",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/fcn_I.m",
                      "Children": [],
                      "Class": "component.load.impedance",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.load.impedance",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/fcn_Y.m",
                      "Children": [],
                      "Class": "component.load.impedance",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.load.impedance",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/get_hessian.m",
                      "Children": [],
                      "Class": "component.load.impedance",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "impedance.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/impedance.m",
                      "Children": [],
                      "Class": "component.load.impedance"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.load.impedance",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.load.impedance",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@impedance/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.load.impedance",
                      "Method": "Jacobi_Y"
                    }
                  ]
                },
                {
                  "Name": "@power",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+load/@power",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/fcn_dx.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/fcn_I.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/fcn_Y.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/get_hessian.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "getCompPQ.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/getCompPQ.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "getCompPQ"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.load.power",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "power.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@power/power.m",
                      "Children": [],
                      "Class": "component.load.power"
                    }
                  ]
                },
                {
                  "Name": "@ZIP",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+component/+load/@ZIP",
                  "Children": [
                    {
                      "Name": "private",
                      "Kind": "folder",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/private",
                      "Children": [
                        {
                          "Name": "zip_admittance.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+component/+load/@ZIP/private/zip_admittance.m",
                          "Children": [],
                          "Class": "component.load.ZIP"
                        },
                        {
                          "Name": "zip_factor.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+component/+load/@ZIP/private/zip_factor.m",
                          "Children": [],
                          "Class": "component.load.ZIP"
                        }
                      ]
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/fcn_dx.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/fcn_I.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "fcn_I"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/fcn_Mass.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/fcn_Y.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "fcn_Y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/get_equilibrium.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/get_hessian.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "getCompPQ.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/getCompPQ.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "getCompPQ"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/Jacobi_dx.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_I.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/Jacobi_I.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "Jacobi_I"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/Jacobi_Y.m",
                      "Children": [],
                      "Class": "component.load.ZIP",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "ZIP.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+component/+load/@ZIP/ZIP.m",
                      "Children": [],
                      "Class": "component.load.ZIP"
                    }
                  ]
                },
                {
                  "Name": "validate.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+component/+load/validate.m",
                  "Children": []
                }
              ]
            }
          ]
        },
        {
          "Name": "+controller",
          "Kind": "folder",
          "Path": "_GUILDAobject/+controller",
          "Children": [
            {
              "Name": "+agc",
              "Kind": "folder",
              "Path": "_GUILDAobject/+controller/+agc",
              "Children": [
                {
                  "Name": "@broadcast_PI_AGC",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC",
                  "Children": [
                    {
                      "Name": "broadcast_PI_AGC.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/broadcast_PI_AGC.m",
                      "Children": [],
                      "Class": "controller.agc.broadcast_PI_AGC"
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.agc.broadcast_PI_AGC",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.agc.broadcast_PI_AGC",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/fcn_y.m",
                      "Children": [],
                      "Class": "controller.agc.broadcast_PI_AGC",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.agc.broadcast_PI_AGC",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.agc.broadcast_PI_AGC",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.agc.broadcast_PI_AGC",
                      "Method": "Jacobi_Y"
                    }
                  ]
                }
              ]
            },
            {
              "Name": "+avr",
              "Kind": "folder",
              "Path": "_GUILDAobject/+controller/+avr",
              "Children": [
                {
                  "Name": "@abstract",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+avr/@abstract",
                  "Children": [
                    {
                      "Name": "abstract.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@abstract/abstract.m",
                      "Children": [],
                      "Class": "controller.avr.abstract"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@abstract/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.avr.abstract",
                      "Method": "get_equilibrium"
                    }
                  ]
                },
                {
                  "Name": "@AVR_DC1",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+avr/@AVR_DC1",
                  "Children": [
                    {
                      "Name": "AVR_DC1.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_DC1/AVR_DC1.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_DC1"
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_DC1/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_DC1",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_DC1/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_DC1",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_DC1/fcn_y.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_DC1",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_DC1/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_DC1",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_DC1/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_DC1",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_DC1/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_DC1",
                      "Method": "Jacobi_Y"
                    }
                  ]
                },
                {
                  "Name": "@AVR_ST1",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+avr/@AVR_ST1",
                  "Children": [
                    {
                      "Name": "AVR_ST1.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_ST1/AVR_ST1.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_ST1"
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_ST1/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_ST1",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_ST1/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_ST1",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_ST1/fcn_y.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_ST1",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_ST1/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_ST1",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_ST1/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_ST1",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@AVR_ST1/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.avr.AVR_ST1",
                      "Method": "Jacobi_Y"
                    }
                  ]
                },
                {
                  "Name": "@Static",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+avr/@Static",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@Static/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.avr.Static",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@Static/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.avr.Static",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@Static/fcn_y.m",
                      "Children": [],
                      "Class": "controller.avr.Static",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@Static/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.avr.Static",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@Static/get_hessian.m",
                      "Children": [],
                      "Class": "controller.avr.Static",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@Static/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.avr.Static",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@Static/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.avr.Static",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "Static.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+avr/@Static/Static.m",
                      "Children": [],
                      "Class": "controller.avr.Static"
                    }
                  ]
                }
              ]
            },
            {
              "Name": "+governor",
              "Kind": "folder",
              "Path": "_GUILDAobject/+controller/+governor",
              "Children": [
                {
                  "Name": "@abstract",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+governor/@abstract",
                  "Children": [
                    {
                      "Name": "private",
                      "Kind": "folder",
                      "Path": "_GUILDAobject/+controller/+governor/@abstract/private",
                      "Children": [
                        {
                          "Name": "rated_power.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+controller/+governor/@abstract/private/rated_power.m",
                          "Children": [],
                          "Class": "controller.governor.abstract"
                        }
                      ]
                    },
                    {
                      "Name": "abstract.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@abstract/abstract.m",
                      "Children": [],
                      "Class": "controller.governor.abstract"
                    },
                    {
                      "Name": "initial_output.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@abstract/initial_output.m",
                      "Children": [],
                      "Class": "controller.governor.abstract",
                      "Method": "initial_output"
                    },
                    {
                      "Name": "initialize.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@abstract/initialize.m",
                      "Children": [],
                      "Class": "controller.governor.abstract",
                      "Method": "initialize"
                    },
                    {
                      "Name": "load_setting.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@abstract/load_setting.m",
                      "Children": [],
                      "Class": "controller.governor.abstract",
                      "Method": "load_setting"
                    },
                    {
                      "Name": "lvg.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@abstract/lvg.m",
                      "Children": [],
                      "Class": "controller.governor.abstract",
                      "Method": "lvg"
                    },
                    {
                      "Name": "servo_rate.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@abstract/servo_rate.m",
                      "Children": [],
                      "Class": "controller.governor.abstract",
                      "Method": "servo_rate"
                    },
                    {
                      "Name": "set_odefcn.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@abstract/set_odefcn.m",
                      "Children": [],
                      "Class": "controller.governor.abstract",
                      "Method": "set_odefcn"
                    }
                  ]
                },
                {
                  "Name": "@IEEJ_LPT1",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1",
                  "Children": [
                    {
                      "Name": "private",
                      "Kind": "folder",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/private",
                      "Children": [
                        {
                          "Name": "mustBePositiveOrNaN.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/private/mustBePositiveOrNaN.m",
                          "Children": [],
                          "Class": "controller.governor.IEEJ_LPT1"
                        },
                        {
                          "Name": "rate.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/private/rate.m",
                          "Children": [],
                          "Class": "controller.governor.IEEJ_LPT1"
                        }
                      ]
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT1",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT1",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/fcn_y.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT1",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT1",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "IEEJ_LPT1.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/IEEJ_LPT1.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT1"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT1",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT1/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT1",
                      "Method": "Jacobi_Y"
                    }
                  ]
                },
                {
                  "Name": "@IEEJ_LPT3",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3",
                  "Children": [
                    {
                      "Name": "private",
                      "Kind": "folder",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/private",
                      "Children": [
                        {
                          "Name": "mustBePositiveOrNaN.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/private/mustBePositiveOrNaN.m",
                          "Children": [],
                          "Class": "controller.governor.IEEJ_LPT3"
                        },
                        {
                          "Name": "rate.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/private/rate.m",
                          "Children": [],
                          "Class": "controller.governor.IEEJ_LPT3"
                        }
                      ]
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT3",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT3",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/fcn_y.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT3",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT3",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "IEEJ_LPT3.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/IEEJ_LPT3.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT3"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT3",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT3/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT3",
                      "Method": "Jacobi_Y"
                    }
                  ]
                },
                {
                  "Name": "@IEEJ_LPT4",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4",
                  "Children": [
                    {
                      "Name": "private",
                      "Kind": "folder",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/private",
                      "Children": [
                        {
                          "Name": "mustBePositiveOrNaN.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/private/mustBePositiveOrNaN.m",
                          "Children": [],
                          "Class": "controller.governor.IEEJ_LPT4"
                        },
                        {
                          "Name": "rate.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/private/rate.m",
                          "Children": [],
                          "Class": "controller.governor.IEEJ_LPT4"
                        }
                      ]
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT4",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT4",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/fcn_y.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT4",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT4",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "IEEJ_LPT4.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/IEEJ_LPT4.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT4"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT4",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@IEEJ_LPT4/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.governor.IEEJ_LPT4",
                      "Method": "Jacobi_Y"
                    }
                  ]
                },
                {
                  "Name": "@Static",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+governor/@Static",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@Static/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.governor.Static",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@Static/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.governor.Static",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@Static/fcn_y.m",
                      "Children": [],
                      "Class": "controller.governor.Static",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@Static/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.governor.Static",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_hessian.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@Static/get_hessian.m",
                      "Children": [],
                      "Class": "controller.governor.Static",
                      "Method": "get_hessian"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@Static/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.governor.Static",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@Static/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.governor.Static",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "Static.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+governor/@Static/Static.m",
                      "Children": [],
                      "Class": "controller.governor.Static"
                    }
                  ]
                }
              ]
            },
            {
              "Name": "+pss",
              "Kind": "folder",
              "Path": "_GUILDAobject/+controller/+pss",
              "Children": [
                {
                  "Name": "@abstract",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+pss/@abstract",
                  "Children": [
                    {
                      "Name": "abstract.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@abstract/abstract.m",
                      "Children": [],
                      "Class": "controller.pss.abstract"
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@abstract/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.pss.abstract",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@abstract/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.pss.abstract",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@abstract/fcn_y.m",
                      "Children": [],
                      "Class": "controller.pss.abstract",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@abstract/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.pss.abstract",
                      "Method": "get_equilibrium"
                    }
                  ]
                },
                {
                  "Name": "@PSS1",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+pss/@PSS1",
                  "Children": [
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@PSS1/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.pss.PSS1",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@PSS1/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.pss.PSS1",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@PSS1/fcn_y.m",
                      "Children": [],
                      "Class": "controller.pss.PSS1",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@PSS1/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.pss.PSS1",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@PSS1/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.pss.PSS1",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@PSS1/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.pss.PSS1",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "PSS1.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@PSS1/PSS1.m",
                      "Children": [],
                      "Class": "controller.pss.PSS1"
                    }
                  ]
                },
                {
                  "Name": "@Retrofit",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/+pss/@Retrofit",
                  "Children": [
                    {
                      "Name": "private",
                      "Kind": "folder",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/private",
                      "Children": [
                        {
                          "Name": "weight.m",
                          "Kind": "file",
                          "Path": "_GUILDAobject/+controller/+pss/@Retrofit/private/weight.m",
                          "Children": [],
                          "Class": "controller.pss.Retrofit"
                        }
                      ]
                    },
                    {
                      "Name": "driven_inputs.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/driven_inputs.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "driven_inputs"
                    },
                    {
                      "Name": "fcn_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/fcn_dx.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "fcn_dx"
                    },
                    {
                      "Name": "fcn_Mass.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/fcn_Mass.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "fcn_Mass"
                    },
                    {
                      "Name": "fcn_y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/fcn_y.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "fcn_y"
                    },
                    {
                      "Name": "get_equilibrium.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/get_equilibrium.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "get_equilibrium"
                    },
                    {
                      "Name": "get_option.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/get_option.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "get_option"
                    },
                    {
                      "Name": "initialize.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/initialize.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "initialize"
                    },
                    {
                      "Name": "Jacobi_dx.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/Jacobi_dx.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "Jacobi_dx"
                    },
                    {
                      "Name": "Jacobi_Y.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/Jacobi_Y.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "Jacobi_Y"
                    },
                    {
                      "Name": "resolve_ports.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/resolve_ports.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "resolve_ports"
                    },
                    {
                      "Name": "Retrofit.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit"
                    },
                    {
                      "Name": "set_inputs.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/set_inputs.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "set_inputs"
                    },
                    {
                      "Name": "set_odefcn.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/+pss/@Retrofit/set_odefcn.m",
                      "Children": [],
                      "Class": "controller.pss.Retrofit",
                      "Method": "set_odefcn"
                    }
                  ]
                }
              ]
            },
            {
              "Name": "@local_LQR",
              "Kind": "folder",
              "Path": "_GUILDAobject/+controller/@local_LQR",
              "Children": [
                {
                  "Name": "private",
                  "Kind": "folder",
                  "Path": "_GUILDAobject/+controller/@local_LQR/private",
                  "Children": [
                    {
                      "Name": "weight.m",
                      "Kind": "file",
                      "Path": "_GUILDAobject/+controller/@local_LQR/private/weight.m",
                      "Children": [],
                      "Class": "controller.local_LQR"
                    }
                  ]
                },
                {
                  "Name": "design_gain.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/design_gain.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "design_gain"
                },
                {
                  "Name": "driven_inputs.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/driven_inputs.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "driven_inputs"
                },
                {
                  "Name": "fcn_dx.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/fcn_dx.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "fcn_dx"
                },
                {
                  "Name": "fcn_Mass.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/fcn_Mass.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "fcn_Mass"
                },
                {
                  "Name": "fcn_y.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/fcn_y.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "fcn_y"
                },
                {
                  "Name": "get_equilibrium.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/get_equilibrium.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "get_equilibrium"
                },
                {
                  "Name": "get_option.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/get_option.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "get_option"
                },
                {
                  "Name": "initialize.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/initialize.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "initialize"
                },
                {
                  "Name": "Jacobi_dx.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/Jacobi_dx.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "Jacobi_dx"
                },
                {
                  "Name": "Jacobi_Y.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/Jacobi_Y.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "Jacobi_Y"
                },
                {
                  "Name": "local_LQR.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/local_LQR.m",
                  "Children": [],
                  "Class": "controller.local_LQR"
                },
                {
                  "Name": "log_change.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/log_change.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "log_change"
                },
                {
                  "Name": "resolve_ports.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/resolve_ports.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "resolve_ports"
                },
                {
                  "Name": "set_inputs.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/set_inputs.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "set_inputs"
                },
                {
                  "Name": "set_odefcn.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+controller/@local_LQR/set_odefcn.m",
                  "Children": [],
                  "Class": "controller.local_LQR",
                  "Method": "set_odefcn"
                }
              ]
            },
            {
              "Name": "validate.m",
              "Kind": "file",
              "Path": "_GUILDAobject/+controller/validate.m",
              "Children": []
            }
          ]
        },
        {
          "Name": "+network",
          "Kind": "folder",
          "Path": "_GUILDAobject/+network",
          "Children": [
            {
              "Name": "@IEEE14bus",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEE14bus",
              "Children": [
                {
                  "Name": "IEEE14bus.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEE14bus/IEEE14bus.m",
                  "Children": [],
                  "Class": "network.IEEE14bus"
                }
              ]
            },
            {
              "Name": "@IEEE14bus_lossless",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEE14bus_lossless",
              "Children": [
                {
                  "Name": "IEEE14bus_lossless.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEE14bus_lossless/IEEE14bus_lossless.m",
                  "Children": [],
                  "Class": "network.IEEE14bus_lossless"
                }
              ]
            },
            {
              "Name": "@IEEE14bus_NoTap",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEE14bus_NoTap",
              "Children": [
                {
                  "Name": "IEEE14bus_NoTap.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEE14bus_NoTap/IEEE14bus_NoTap.m",
                  "Children": [],
                  "Class": "network.IEEE14bus_NoTap"
                }
              ]
            },
            {
              "Name": "@IEEE39Bus",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEE39Bus",
              "Children": [
                {
                  "Name": "IEEE39Bus.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEE39Bus/IEEE39Bus.m",
                  "Children": [],
                  "Class": "network.IEEE39Bus"
                }
              ]
            },
            {
              "Name": "@IEEE68bus",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEE68bus",
              "Children": [
                {
                  "Name": "IEEE68bus.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEE68bus/IEEE68bus.m",
                  "Children": [],
                  "Class": "network.IEEE68bus"
                }
              ]
            },
            {
              "Name": "@IEEE9bus",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEE9bus",
              "Children": [
                {
                  "Name": "IEEE9bus.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEE9bus/IEEE9bus.m",
                  "Children": [],
                  "Class": "network.IEEE9bus"
                }
              ]
            },
            {
              "Name": "@IEEJ_EAST10",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEJ_EAST10",
              "Children": [
                {
                  "Name": "IEEJ_EAST10.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEJ_EAST10/IEEJ_EAST10.m",
                  "Children": [],
                  "Class": "network.IEEJ_EAST10"
                }
              ]
            },
            {
              "Name": "@IEEJ_EAST30",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEJ_EAST30",
              "Children": [
                {
                  "Name": "IEEJ_EAST30.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEJ_EAST30/IEEJ_EAST30.m",
                  "Children": [],
                  "Class": "network.IEEJ_EAST30"
                }
              ]
            },
            {
              "Name": "@IEEJ_WEST10",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEJ_WEST10",
              "Children": [
                {
                  "Name": "IEEJ_WEST10.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEJ_WEST10/IEEJ_WEST10.m",
                  "Children": [],
                  "Class": "network.IEEJ_WEST10"
                }
              ]
            },
            {
              "Name": "@IEEJ_WEST30",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@IEEJ_WEST30",
              "Children": [
                {
                  "Name": "IEEJ_WEST30.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@IEEJ_WEST30/IEEJ_WEST30.m",
                  "Children": [],
                  "Class": "network.IEEJ_WEST30"
                }
              ]
            },
            {
              "Name": "@TEST31bus",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@TEST31bus",
              "Children": [
                {
                  "Name": "TEST31bus.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@TEST31bus/TEST31bus.m",
                  "Children": [],
                  "Class": "network.TEST31bus"
                }
              ]
            },
            {
              "Name": "@Txt3Bus",
              "Kind": "folder",
              "Path": "_GUILDAobject/+network/@Txt3Bus",
              "Children": [
                {
                  "Name": "Txt3Bus.m",
                  "Kind": "file",
                  "Path": "_GUILDAobject/+network/@Txt3Bus/Txt3Bus.m",
                  "Children": [],
                  "Class": "network.Txt3Bus"
                }
              ]
            },
            {
              "Name": "GUILDAlogo.m",
              "Kind": "file",
              "Path": "_GUILDAobject/+network/GUILDAlogo.m",
              "Children": [],
              "Class": "network.GUILDAlogo"
            },
            {
              "Name": "Tutorial10bus.m",
              "Kind": "file",
              "Path": "_GUILDAobject/+network/Tutorial10bus.m",
              "Children": [],
              "Class": "network.Tutorial10bus"
            },
            {
              "Name": "Tutorial3bus.m",
              "Kind": "file",
              "Path": "_GUILDAobject/+network/Tutorial3bus.m",
              "Children": [],
              "Class": "network.Tutorial3bus"
            },
            {
              "Name": "Tutorial6bus.m",
              "Kind": "file",
              "Path": "_GUILDAobject/+network/Tutorial6bus.m",
              "Children": [],
              "Class": "network.Tutorial6bus"
            }
          ]
        }
      ]
    }
  ],
  "validation": {
    "warningCount": 0,
    "errorCount": 0,
    "classes": [
      {
        "ClassName": "auxiliary",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "Branch",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "branch.pi",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "branch.pi_transformer",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "branch.T",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "branch.two_winding_transformer",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "Bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "Component",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.ConstSource.power",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.generator.abstract",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.generator.classical",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.generator.droop",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.generator.one_axis",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.generator.park",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.generator.two_axis",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.GFLInverter.abstract",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.GFLInverter.Static",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.GFMInverter.abstract",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.GFMInverter.VSG_classical",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.load.abstract",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.load.current",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.load.impedance",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.load.power",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "component.load.ZIP",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "ContinuationPowerFlowV3",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.agc.broadcast_PI_AGC",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.avr.abstract",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.avr.AVR_DC1",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.avr.AVR_ST1",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.avr.Static",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.governor.abstract",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.governor.IEEJ_LPT1",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.governor.IEEJ_LPT3",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.governor.IEEJ_LPT4",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.governor.Static",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.local_LQR",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.pss.abstract",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.pss.PSS1",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "controller.pss.Retrofit",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "CsvNetHandler",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "DrawerGUILDA",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "DrawerModelGUI",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "DrawerOptionDialog",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "DrawerResultGUI",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "DrawerTagPicker",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "EventBase",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "EventFault",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "EventInput",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "EventOffset",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "EventOpenBranch",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "EventTrip",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GlobalController",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GraphBase",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GraphChart",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GraphEventData",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GraphMatrix",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GraphNetDiagram",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GraphSpring2D",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GraphSpring3D",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GraphSpringBase",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "GraphTimeEventData",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "HistoryGUILDA",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "LayerPackage",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "LocalController",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "MethodBase",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "MethodDynamic",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "MethodFsolve",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "MethodGradient",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "MethodLevenbergMarquardt",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "MethodNewtonRaphson",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.GUILDAlogo",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEE14bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEE14bus_lossless",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEE14bus_NoTap",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEE39Bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEE68bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEE9bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEJ_EAST10",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEJ_EAST30",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEJ_WEST10",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.IEEJ_WEST30",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.TEST31bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.Tutorial10bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.Tutorial3bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.Tutorial6bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "network.Txt3Bus",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "Parameter",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "PowerNetwork",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "PowerSystemModel",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "ProgressGUILDA",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "ResultBase",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "ResultCPF",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "ResultLIN",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "ResultODE",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "ResultOPF",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "ResultPF",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "Scenario",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "SolverCPF",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "SolverLIN",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "SolverODE",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "SolverOPF",
        "Warnings": [],
        "Errors": []
      },
      {
        "ClassName": "SolverPF",
        "Warnings": [],
        "Errors": []
      }
    ]
  }
};
