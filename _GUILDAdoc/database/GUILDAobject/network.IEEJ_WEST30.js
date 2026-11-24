(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["network.IEEJ_WEST30"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "network.IEEJ_WEST30",
  "properties": [
    {
      "Name": "ver",
      "Defining": "network.IEEJ_WEST30",
      "Group": "Data",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "2",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+network/@IEEJ_WEST30/IEEJ_WEST30.m",
      "Line": 115,
      "Summary": "Version of the bundled network data.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_Bus",
      "Defining": "PowerNetwork",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "cell(0,1)",
      "Validation": {
        "Class": "cell",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 98,
      "Summary": "Buses of the network, in the order of the bus index.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "powerflow",
      "Deprecated": ""
    },
    {
      "Name": "a_Branch",
      "Defining": "PowerNetwork",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "cell(0,1)",
      "Validation": {
        "Class": "cell",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 99,
      "Summary": "Branches of the network.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "powerflow",
      "Deprecated": ""
    },
    {
      "Name": "a_GlobalController",
      "Defining": "PowerNetwork",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "cell(0,1)",
      "Validation": {
        "Class": "cell",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 100,
      "Summary": "Global controllers of the network.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "equilibrium of the added controller",
      "Deprecated": ""
    },
    {
      "Name": "a_Scenario",
      "Defining": "PowerNetwork",
      "Group": "Scenarios",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "cell(0,1)",
      "Validation": {
        "Class": "cell",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 103,
      "Summary": "Simulation scenarios (Scenario), in the order created by add_scenario; not model data.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "nothing",
      "Deprecated": ""
    },
    {
      "Name": "solver_PF",
      "Defining": "PowerNetwork",
      "Group": "Solvers",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "SolverPF",
        "Size": "",
        "Validators": [
          "mustBeScalarOrEmpty"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 106,
      "Summary": "Solver of calculate_powerflow (solves from the admittance matrix and the bus conditions the network assembles); keeps the warm start solution, no settings (GUILDA.setting).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "SolverPF ",
      "Stale": "nothing",
      "Deprecated": ""
    },
    {
      "Name": "solver_OPF",
      "Defining": "PowerNetwork",
      "Group": "Solvers",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "SolverOPF",
        "Size": "",
        "Validators": [
          "mustBeScalarOrEmpty"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 107,
      "Summary": "Solver of calculate_optimal_powerflow (returns a ResultOPF); keeps the warm start (bus voltages of the last solved AC OPF), no settings (GUILDA.setting).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "SolverOPF ",
      "Stale": "nothing",
      "Deprecated": ""
    },
    {
      "Name": "solver_CPF",
      "Defining": "PowerNetwork",
      "Group": "Solvers",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "SolverCPF",
        "Size": "",
        "Validators": [
          "mustBeScalarOrEmpty"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 108,
      "Summary": "Solver of calculate_continuation_powerflow (returns a ResultCPF); keeps the condition LoadBus; settings in GUILDA.setting.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "SolverCPF ",
      "Stale": "nothing",
      "Deprecated": ""
    },
    {
      "Name": "solver_ODE",
      "Defining": "PowerNetwork",
      "Group": "Solvers",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "SolverODE",
        "Size": "",
        "Validators": [
          "mustBeScalarOrEmpty"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 109,
      "Summary": "Solver of simulate (returns a ResultODE); no settings (GUILDA.setting).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "SolverODE ",
      "Stale": "nothing",
      "Deprecated": ""
    },
    {
      "Name": "solver_LIN",
      "Defining": "PowerNetwork",
      "Group": "Solvers",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "SolverLIN",
        "Size": "",
        "Validators": [
          "mustBeScalarOrEmpty"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 110,
      "Summary": "Connector of get_sys (SolverLIN.solve; get_sys returns a ResultLIN); no settings (GUILDA.setting).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "SolverLIN ",
      "Stale": "nothing",
      "Deprecated": ""
    },
    {
      "Name": "cv_Vequilibrium",
      "Defining": "PowerNetwork",
      "Group": "Steady State",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": true,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 113,
      "Summary": "Bus voltage phasors at the equilibrium, one per bus.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "cv_Iequilibrium",
      "Defining": "PowerNetwork",
      "Group": "Steady State",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": true,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 114,
      "Summary": "Bus current injections at the equilibrium, one per bus.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_Xequilibrium",
      "Defining": "PowerNetwork",
      "Group": "Steady State",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": true,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 115,
      "Summary": "State equilibrium, in the order of the x rows of get_variable_map.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "parent",
      "Defining": "PowerNetwork",
      "Group": "Layer Structure",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": true,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 118,
      "Summary": "Parent in the layer structure: none (the network is the top).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "children",
      "Defining": "PowerNetwork",
      "Group": "Layer Structure",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": true,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@PowerNetwork/PowerNetwork.m",
      "Line": 119,
      "Summary": "Children in the layer structure: the buses, branches, global controllers and scenarios, then the Parameter object.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_parameter",
      "Defining": "PowerSystemModel",
      "Group": "Parameter",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": true,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 18,
      "Summary": "Parameter table: the a_Parameter tables side by side; writing it writes the changed parameters.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_Parameter",
      "Defining": "PowerSystemModel",
      "Group": "Parameter",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "cell(0,1)",
      "Validation": {
        "Class": "cell",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 21,
      "Summary": "Parameter containers, one per column of tab_parameter (column name: the s_tag of the container).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "Parameter cell array (Nx1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_parameterCache",
      "Defining": "PowerSystemModel",
      "Group": "Parameter",
      "GetAccess": "LayerPackage",
      "SetAccess": "LayerPackage",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": true,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 24,
      "Summary": "tab_parameter built by its getter; [] when an edit (a store or a rename of a container, a new a_Parameter) made it out of date.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_stale",
      "Defining": "LayerPackage",
      "Group": "Stale state",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct()",
      "Validation": {
        "Class": "struct",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/LayerPackage.m",
      "Line": 67,
      "Summary": "Messages per stale tag of the class (string column each; empty: up to date). See the class help.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_notInitialized",
      "Defining": "LayerPackage",
      "Group": "Stale state",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"initialize has not been run\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/LayerPackage.m",
      "Line": 70,
      "Summary": "Initial message of every stale tag.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_tag",
      "Defining": "LayerPackage",
      "Group": "Tag",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/LayerPackage.m",
      "Line": 75,
      "Summary": "User-defined tag of the layer: a valid variable name (isvarname), unique among its siblings (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "IEEJ_WEST30",
      "Defining": "network.IEEJ_WEST30",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "opt"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "Section",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Section, [\"peak\",\"night\"])"
          ],
          "Default": "\"peak\"",
          "Required": false,
          "Unit": "",
          "Description": "Power-flow section: \"peak\" or \"night\"."
        },
        {
          "Name": "LocalController",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "true to add the local controllers (AVRs and governors); false keeps the default Static AVR and governor (avr-static, gov-static) on the generators."
        },
        {
          "Name": "Governor",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "true for the governors of the report beside the AVRs (local_controller/); false gives every generator the Static governor (with LocalController)."
        }
      ],
      "Outputs": [
        {
          "Name": "obj",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "IEEJ_WEST30 network."
        }
      ],
      "Signature": "obj = network.IEEJ_WEST30(Name=Value)",
      "File": "_GUILDAobject/+network/@IEEJ_WEST30/IEEJ_WEST30.m",
      "Line": 119,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create the network from the CSV data of the section in the class folder.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "export",
      "Defining": "PowerNetwork",
      "Group": "Data IO",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "path",
        "opt"
      ],
      "OutputNames": [
        "path"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "path",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Model folder to write (created; its parent must exist)."
        },
        {
          "Name": "Overwrite",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Replace an existing folder."
        },
        {
          "Name": "ClassFile",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Write the class file <name>.m (name = folder name without the leading @). Default: true when the folder name starts with @."
        }
      ],
      "Outputs": [
        {
          "Name": "path",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The written model folder."
        }
      ],
      "Signature": "path = export(obj, path, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/export.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:export:InvalidClassName",
        "GUILDA:export:NoParentFolder",
        "GUILDA:export:FolderExists"
      ],
      "Summary": "Write the network and its scenarios to a model folder.",
      "Desc": "Writes the network to a model folder that PowerNetwork.import reads back:\n  <path>/network/parameter.csv        Hz, baseMVA (net.tab_parameter.base)\n  <path>/bus/parameter.csv            one row per bus, in the order of net.a_Bus\n  <path>/branch/parameter.csv         one row per branch; From/To are bus row numbers\n  <path>/component/<key>/main.csv     one row per component of type <key>\n  <path>/component/<key>/dynamics.csv distinct parameter rows (column ParameterID)\n  <path>/component/<key>/opf.csv      distinct OPF rows (column OpfID)\n  <path>/local_controller/<key>/parameter.csv   one row per local controller of type <key>\n  <path>/local_controller/<key>/option.json     constructor arguments outside the table\n                                      (get_option, e.g. Q and R of an LQR), by FullTag\n  <path>/global_controller/<key>/parameter.csv  one row per controlled component of each\n                                      global controller of type <key> (none without them)\n  <path>/scenario/<tag>.json          one file per scenario of net.a_Scenario (none\n                                      without scenarios)\nThe bus column Slack is 1 for the slack bus. The column FullTag of the bus, branch and\ncomponent tables holds the full tag; the bus column Tag holds its prefix (the tag\nwithout its trailing digits). A scenario file holds Format (\"GUILDAscenario\"), version,\nDescription, Time, and Event, Offset and Input: one object per row of tab_event, tab_offset\nand tab_input with the column names as fields (version 2), empty ones left out;\na time-series InputValue is an object with Time and Value (one array per point).\nEvery local controller is written, the default Static AVR and governor included, so\nlocal_controller/ (made also when there are none) is the full set of local controllers\nof the network. Its columns are Component (full tag of the component, also for a PSS),\nFullTag (full tag of the controller) and the columns of its dynamics table. A global\ncontroller has one row per controlled component, in their order: FullTag (the same on\neach row), Component and the columns of its dynamics table. Equilibria and the values\nthat initialize computes (e.g. the gain of an LQR) are not saved.\nWhen the folder name starts with \"@\" (e.g. \"@MyNet\"), a class file MyNet.m is also\nwritten, so that the folder is a network class (net = MyNet()) when its parent folder\nis on the MATLAB path.\nAn existing folder is an error unless Overwrite=true, which first deletes the network,\nbus, branch, component, local_controller, global_controller and scenario subfolders and\nthe class file written by an earlier export.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet  = network.IEEE14bus;\npath = net.export(fullfile(tempdir, \"@MyIEEE14\"), Overwrite=true);\nnet2 = PowerNetwork.import(path);\n```\n\nSee also PowerNetwork.import",
      "Deprecated": ""
    },
    {
      "Name": "set_layout",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sct_layout",
        "opt"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "sct_layout",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Layout: some of the fields tab_bus, tab_branch, tab_component (tables with the column Tag)."
        },
        {
          "Name": "IgnoreUnknown",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Skip the rows whose tag is not in the network instead of stopping."
        }
      ],
      "Outputs": [],
      "Signature": "set_layout(obj, sct_layout, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/set_layout.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:LayoutUnknownColumn",
        "GUILDA:PowerNetwork:LayoutNoTag",
        "GUILDA:PowerNetwork:LayoutUnknownTag"
      ],
      "Summary": "Write a layout of the network diagrams into the graph parameters of the elements.",
      "Desc": "sct_layout has the form of net.get_layout: the tables tab_bus, tab_branch and\ntab_component, each with the column Tag. Each row is written into the graph parameters\nof the element with that tag (a component by its full tag). Any part can be given: one\nor two of the tables, some of the rows, the column Tag and some of the graph columns;\nwhat is not given stays. The columns From, To and Bus of net.get_layout are read only\nand ignored.\n\nEvery row is checked first, by the same rules as add_bus, add_branch and add_component\n(a bar needs a positive Length, a Path is \"x y; x y\", ...), and nothing is written when\none value is wrong. A tag that is not in the network stops with\nGUILDA:PowerNetwork:LayoutUnknownTag; IgnoreUnknown=true skips such rows instead (to copy\na layout to another network). A table or column that is not part of the layout stops\nwith GUILDA:PowerNetwork:LayoutUnknownColumn. Each write is a graph edit of the element,\nwhich makes nothing stale.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nL = net.get_layout();\nL.tab_bus.Length(L.tab_bus.Shape == \"hbar\") = 0.12;\nnet.set_layout(L);\n\nnet2.set_layout(net.get_layout(), IgnoreUnknown=true);   % the same tags of another network\nnet.set_layout(struct(\"tab_bus\", table(\"B001\", 0.3, 0.6, 'VariableNames', [\"Tag\", \"X\", \"Y\"])));\n```\n\nSee also PowerNetwork.get_layout, PowerNetwork.add_bus, PowerNetwork.add_branch, Bus.add_component",
      "Deprecated": ""
    },
    {
      "Name": "get_layout",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "sct_layout"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        }
      ],
      "Outputs": [
        {
          "Name": "sct_layout",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Layout: fields tab_bus, tab_branch, tab_component (tables with the column Tag)."
        }
      ],
      "Signature": "sct_layout = get_layout(obj)",
      "File": "_GUILDAsystem/@PowerNetwork/get_layout.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the layout of the network diagrams: the graph parameters of all elements by tag.",
      "Desc": "The struct has one table per kind of element, one row per element in the order of\na_Bus, a_Branch and the components bus by bus, with the tag as the column Tag:\n\n- tab_bus: Tag, X, Y, Shape, Length, MarkerSize, Color\n- tab_branch: Tag, From, To (tags of the end buses, read only), Path, FromOffset,\n  ToOffset, Style\n- tab_component: Tag (full tag), Bus (tag of the bus, read only), DX, DY, Shape, Path,\n  Offset, MarkerSize, Color\n\nThe network is not changed. Edit the tables and give them to net.set_layout to write\nthem back; writetable writes each table as a CSV file as it is.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nL = net.get_layout();\nL.tab_bus(L.tab_bus.Shape == \"hbar\", [\"Tag\", \"X\", \"Length\"])\nL.tab_bus.Length(L.tab_bus.Shape == \"hbar\") = 0.12;\nnet.set_layout(L);\n```\n\nSee also PowerNetwork.set_layout, PowerNetwork.plot_diagram",
      "Deprecated": ""
    },
    {
      "Name": "plot_spring_model",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Dimension",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeMember(opt.Dimension, [2, 3])"
          ],
          "Default": "2",
          "Required": false,
          "Unit": "",
          "Description": "2: phasor plane (GraphSpring2D); 3: surface z = log|V| (GraphSpring3D)."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The picture: a GraphSpring2D or GraphSpring3D object."
        }
      ],
      "Signature": "G = plot_spring_model(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/plot_spring_model.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the equilibrium of the network as a spring-mass picture.",
      "Desc": "The nodes are voltage phasors: every bus, and the own node of each component whose class\nreturns one from its Static get_spring_node (the internal voltage of a generator, joined\nto its bus by the machine reactance). The springs are the branches and these reactances.\nArrow pairs show the active power P and the reactive-current magnitude Iq: on each own\nnode, and on each bus with a component without an own node (the bus injection minus the\ncurrents of the own nodes, at the bus voltage). Marker, MarkerSize and Color of the graph\nparameters of the buses and components set the appearance. Dimension=2 draws the phasor\nplane (GraphSpring2D), Dimension=3 the surface z = log|V| (GraphSpring3D).\n\nThe picture shows the equilibrium of initialize: c_Vequilibrium and c_Iequilibrium of the\nbuses, rv_Xequilibrium and rv_Uequilibrium of the components. It needs an up-to-date\nnetwork: before net.initialize(), or after an edit that made a layer stale, it stops with\nGUILDA:PowerNetwork:SpringModelStale (\"Run net.initialize() first\"). To draw the result of\nan analysis, use ResultODE.plot_spring_model (animation) or ResultPF.plot_spring_model.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nG = net.plot_spring_model();               % phasor plane\nG = net.plot_spring_model(Dimension=3);    % on the surface z = log|V|\nG.ShowValue = false;\n```\n\nSee also ResultODE.plot_spring_model, ResultPF.plot_spring_model, GraphSpring2D, GraphSpring3D, Component.get_spring_node",
      "Deprecated": ""
    },
    {
      "Name": "plot_single_line_diagram",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure of 8.5 cm width."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "GraphNetDiagram object of the drawing."
        }
      ],
      "Signature": "G = plot_single_line_diagram(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/plot_single_line_diagram.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the topology as a black-and-white single-line diagram for a paper.",
      "Desc": "The diagram has the 2D layout of plot_diagram (the graph parameters of the elements)\nand the symbols of a single-line diagram, all in black on white: a bus is a thick bar or\ndot, a branch a thin line, a transformer two overlapping circles, a generator (a class\nof component.generator) a circle with a sine inside, a load (component.load) a filled\ntriangle pointing away from its bus, any other component a marker of its Shape. The\nlabels are the bus tags, without a box. There are no colors, colorbar, title, flow dots\nor data-dependent widths, and the axes are hidden with tight limits. No power flow is\nneeded: it draws the topology (plot_diagram with State=\"topology\").\n\nWith Parent empty, a new white figure for one column of a two-column paper is made:\n8.5 cm wide, as high as the layout needs (3 to 12 cm), with labels of 8 pt (smaller\nbeyond 30 buses: 8*sqrt(30/n_bus), at least 5 pt), so that exportgraphics writes it at\nits size. With a Parent the diagram is drawn in it.\nThe returned GraphNetDiagram works as any diagram: a click on an element or its data\ntip selects it, and set_style changes colors and sizes.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nG = net.plot_single_line_diagram();\nexportgraphics(G.ax, \"ieee14.pdf\", ContentType=\"vector\");\nexportgraphics(G.ax, \"ieee14.png\", Resolution=600);\n```\n\nSee also PowerNetwork.plot_diagram, ResultPF.plot_single_line_diagram, GraphNetDiagram",
      "Deprecated": ""
    },
    {
      "Name": "plot_diagram",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "opt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name-Value options; each sets the property of the same name of the GraphNetDiagram."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        },
        {
          "Name": "State",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.State, [\"auto\", \"equilibrium\", \"topology\"])"
          ],
          "Default": "\"auto\"",
          "Required": false,
          "Unit": "",
          "Description": "What is drawn: the equilibrium, the topology, or \"auto\" (see the help)."
        },
        {
          "Name": "Graph",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Existing diagram to draw into; [] for a new one. <@Type> GraphNetDiagram"
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "GraphNetDiagram object of the drawing."
        }
      ],
      "Signature": "G = plot_diagram(obj, opt, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/plot_diagram.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:DiagramGraph"
      ],
      "Summary": "Draw the network diagram of the equilibrium: buses, branches and components.",
      "Desc": "The diagram is a single-line diagram in 2D (lines and markers); Dimension=\"3D\" draws\nsolids with lighting instead. The branch widths follow the admittance of the branches\n(BranchWidthMode \"Ysvd\") in BranchWidthRange, the bus and component sizes MarkerSizeMode\nin MarkerSizeRange (see GraphNetDiagram).\n\nState chooses what is drawn:\n\n- \"auto\" (default): the equilibrium of initialize (c_Vequilibrium of the buses,\n  c_Iequilibrium of the components) when the network is up to date; otherwise, before\n  net.initialize() or after an edit that made a layer stale, the topology only, with an\n  INFO message (GUILDA:PowerNetwork:DiagramTopology).\n- \"equilibrium\": the equilibrium; a network that is not up to date stops with\n  GUILDA:PowerNetwork:DiagramStale (\"Run net.initialize() first\").\n- \"topology\": the buses, branches and components only, with no state (the state is\n  NaN): no colors of values (no colorbar), no heights, no arrows, and the data tips show tags and\n  parameters. It works on a network still being built (no slack bus, a bus without\n  components or branches).\n\nThe diagram is built from a snapshot of the network with the fields of struct(obj, false)\nthat it reads (the tags, classes, bus types and parameter tables of the buses, branches\nand components, and the admittance matrix cm_Y of each branch; much faster than the\nwhole struct) and does not change the network; positions from the automatic layout stay in the drawing. Graph=G draws into an\nexisting diagram instead of a new one: G.set_data takes the new snapshot and state, in\nthe same axes, keeping the positions, set_style settings and selection of the elements\nby tag, and G is returned. The other Name-Value options set the properties of the\nGraphNetDiagram. To draw a power flow solution or a time simulation, use\nResultPF.plot_diagram or ResultODE.plot_diagram.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nG = net.plot_diagram();                       % topology (not initialized yet)\nnet.initialize();\nG = net.plot_diagram(Graph=G);                % the same diagram, now the equilibrium\nG = net.plot_diagram(ColorMode=\"P\", BusHeightMode=\"V\", State=\"equilibrium\");\nG = net.plot_diagram(Dimension=\"3D\");         % solids with lighting\n```\n\nSee also GraphNetDiagram, ResultPF.plot_diagram, ResultODE.plot_diagram, PowerNetwork.plot_spring_model",
      "Deprecated": ""
    },
    {
      "Name": "disp_connection",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "varargout"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Kind",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Kind, [\"local\",\"global\",\"observe\",\"equilibrium\"])"
          ],
          "Default": "[\"local\",\"global\",\"observe\"]",
          "Required": false,
          "Unit": "",
          "Description": "Kinds of connection shown; \"equilibrium\" adds the inputs that keep their equilibrium."
        },
        {
          "Name": "Owner",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "strings(1,0)",
          "Required": false,
          "Unit": "",
          "Description": "Tags of buses, components or controllers to show (with what they hold); empty shows all."
        }
      ],
      "Outputs": [
        {
          "Name": "varargout",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Connection text when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_connection(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/disp_connection.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:DispConnectionOwner"
      ],
      "Summary": "Display the signal connections of the network: each input and the signals that drive it.",
      "Desc": "A command-line view of the connection map of `get_variable_map` (its 4th output,\n`tab_connection`). The inputs are grouped by their owner in the order of the model:\neach bus, its components and their local controllers (depth first), then the global\ncontrollers. Under each owner, every input (Kind \"u\" or \"uc\" of the variable map) is\nlisted first with its sources, then the components or controllers it holds. The tips\nof the tree lines (the heavy lines of `LayerPackage.disp_tree`) tell them apart:\n`┣━━<` / `┗━━<` for an input port, `┣━━o` / `┗━━o` for a held object. Each source is\nmarked by the kind of the connection:\n\n- `local`: an output of a local controller into its parent\n- `global`: an output of a global controller into a unit or its local controllers\n- `observe`: an output or a state of a component read by a controller\n- `equilibrium`: the input keeps its equilibrium value\n\nA source is shown as \"output <name> of <tag>\" (an output y or yc) or \"state <name> of\n<tag>\" (a state x). An input with one source is joined to it by `━━`; an input\nwith several sources is their sum, forked by `━┳`, `┣` and `┗`. An input of a\nglobal controller is shown as \"<name> (<unit tag>)\", one per controlled unit. Owners\nwithout a shown input are left out, and so are the buses without one; a last line counts\nthe connections that the option Kind hides. The bus voltages that controllers read\ndirectly are not connections of the map and are not shown.\n\nThe option Owner restricts the view to the given buses, components or controllers\n(each with what it holds: a bus with its components and their controllers, a component\nwith its controllers): an input is shown when its owner is one of them, or when one of\nits sources is (so a global controller shows the inputs it drives, and a component the\ncontrollers that read it). A shown input always lists all its sources of the shown kinds.\nEach tag is followed by a link to the documentation of its class.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.Tutorial10bus();\nnet.disp_connection()                                  % local, global and observe\nnet.disp_connection(Kind=\"global\")                     % only the global controllers\nnet.disp_connection(Owner=\"B001SG1\")                   % one generator with its controllers\nnet.disp_connection(Owner=\"PowerNetworkAGC1\", Kind=[\"global\",\"observe\"])\ns = net.disp_connection(Kind=[\"local\",\"global\",\"observe\",\"equilibrium\"]);   % as text\n```\n\nSee also PowerNetwork.get_variable_map, LayerPackage.disp_tree",
      "Deprecated": ""
    },
    {
      "Name": "disp_powerflow",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "varargout"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        }
      ],
      "Outputs": [],
      "Signature": "varargout = disp_powerflow(obj)",
      "File": "_GUILDAsystem/@PowerNetwork/disp_powerflow.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Display a steady-state powerflow of the buses.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "```matlab\nnet.disp_powerflow()\n```",
      "Deprecated": ""
    },
    {
      "Name": "disp_summary",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "equilibrium",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Show the equilibrium values."
        },
        {
          "Name": "parameter",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Show the parameters (one table per group)."
        },
        {
          "Name": "bus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Show the bus table."
        },
        {
          "Name": "branch",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Show the branch tables."
        },
        {
          "Name": "component",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Show the component tables."
        }
      ],
      "Outputs": [],
      "Signature": "disp_summary(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/disp_summary.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Display a summary of the network: a list of what it holds, then the tables of its elements.",
      "Desc": "The list has one item per kind of element: the buses by power-flow type (and the slack\nbus), the branches, components and local controllers by model key (with their tags; at\nmost six per key), the global controllers, the scenarios and the state of the\nequilibrium (\"up to date\"; \"out of date\" with the first reason, from the stale tags of\nthe network, components and controllers; \"not computed\" before net.initialize()).\nThen come the tables, each switched by its option:\n\n- bus: one row per bus: Tag, Type (slack/PV/PQ), Component (tags of its components).\n- branch: one table per branch model: Tag, From, To.\n- component: one table per component model: Tag, Bus, Controller (tags of its local\n  controllers, the PSS under an AVR included).\n\nparameter adds after each table one table per parameter group of tab_parameter\n(dynamics, operation, powerflow, OPF, graph, ...), each under the heading \"<kind> -\nparameter <group>\"; a group without parameters is left out. A table wider than 120\ncharacters is printed in parts, each part starting with the column Tag. equilibrium adds\nthe values at the equilibrium:\nEquilibrium (|V| [pu], angle [rad], P, Q [pu] of the bus or component), and for a\ncomponent State and Input. Before net.initialize() (or while a component has no\nequilibrium, e.g. one just added) the equilibrium columns are left out with an INFO\nmessage (GUILDA:PowerNetwork:SummaryNoEquilibrium). The network is not changed.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.disp_summary()\nnet.disp_summary(parameter=false, equilibrium=false)\nnet.disp_summary(bus=false, branch=false, component=false)     % the list only\n```\n\nSee also PowerNetwork.get_element_table, PowerNetwork.get_parameter, PowerNetwork.plot_diagram",
      "Deprecated": ""
    },
    {
      "Name": "set_parameter",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Group",
        "tab"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Group",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Parameter group, e.g. \"powerflow\", \"dynamics\", \"operation\", \"OPF\", \"graph\"."
        },
        {
          "Name": "tab",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Values: row names = tags of the elements, columns = parameters of the group."
        }
      ],
      "Outputs": [],
      "Signature": "set_parameter(obj, Group, tab)",
      "File": "_GUILDAsystem/@PowerNetwork/set_parameter.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:ParameterNoRowNames",
        "GUILDA:PowerNetwork:ParameterUnknownRow",
        "GUILDA:PowerNetwork:ParameterUnknownColumn",
        "GUILDA:PowerNetwork:ParameterClassMismatch"
      ],
      "Summary": "Write one parameter group of many elements from a table: one row per element.",
      "Desc": "tab has the form of net.get_parameter(Group): the row names are the tags of the elements\n(a global controller with one row per unit: \"<controller tag>/<unit tag>\"), the columns\nparameters of the group. Any part can be given: some of the rows and some of the\ncolumns; what is not given stays. Each row is written into tab_parameter.(Group) of its\nelement, as writing that table directly does: each changed value is an edit of the\nelement (e.g. \"powerflow/B005LRX1: edit P: -1.25 -> -1.875\"), which makes the power flow\nor the equilibrium stale as usual, and an unchanged value is no edit.\n\nEvery row is checked before any write, and nothing is written when one is wrong: a\ntable without row names stops with GUILDA:PowerNetwork:ParameterNoRowNames; a row name\nthat is not a tag of an element with the group, with GUILDA:PowerNetwork:ParameterUnknownRow;\na column that the element does not have, with GUILDA:PowerNetwork:ParameterUnknownColumn\n(except in a table of mixed models from get_parameter: its Key column and, in a row, the\nfilled value of a parameter the element does not have, NaN, <missing> or false, are\nskipped);\na column of another class than the stored one (e.g. a string for a number), with\nGUILDA:PowerNetwork:ParameterClassMismatch; a value that the check of the group rejects\n(the graph parameters) stops with the error of that check.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\ntab = net.get_parameter(\"powerflow\", Key=\"load-impedance\");\ntab.P = 1.5*tab.P;  tab.Q = 1.5*tab.Q;                 % all loads x1.5\nnet.set_parameter(\"powerflow\", tab);\n\ntab = net.get_parameter(\"OPF\", Key=\"gen-1axis\");\ntab{:, [\"HP\", \"fP\"]} = [0.02 2; 0.03 1.5; 0.025 1.8];  % quadratic and linear costs\nnet.set_parameter(\"OPF\", tab);\n\ntab = net.get_parameter(\"dynamics\", Key=\"gen-1axis\");\nnet.set_parameter(\"dynamics\", tab(\"B002SG1\", \"D\"));   % one value: D of B002SG1 (unchanged)\n```\n\nSee also PowerNetwork.get_parameter, PowerNetwork.get_element, Parameter",
      "Deprecated": ""
    },
    {
      "Name": "get_parameter",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Group",
        "opt"
      ],
      "OutputNames": [
        "tab"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Group",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Parameter group, e.g. \"powerflow\", \"dynamics\", \"operation\", \"OPF\", \"graph\"."
        },
        {
          "Name": "Key",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "strings(1,0)",
          "Required": false,
          "Unit": "",
          "Description": "Keep the elements of these model keys (e.g. \"gen-1axis\", \"load-impedance\"; none: all)."
        },
        {
          "Name": "Class",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "strings(1,0)",
          "Required": false,
          "Unit": "",
          "Description": "Keep the elements of these classes or their subclasses (isa, e.g. \"Bus\", \"Component\", \"component.load.abstract\"; none: all)."
        },
        {
          "Name": "Owner",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Keep the elements below the element with this tag (\"\": all)."
        }
      ],
      "Outputs": [
        {
          "Name": "tab",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One row per element (row names: tags), one column per parameter of the group."
        }
      ],
      "Signature": "tab = get_parameter(obj, Group, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/get_parameter.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:ParameterGroupNotFound",
        "GUILDA:PowerNetwork:ParameterNoElement"
      ],
      "Summary": "Return one parameter group of many elements as a table: one row per element.",
      "Desc": "Group is a parameter group of tab_parameter: \"powerflow\", \"dynamics\", \"operation\",\n\"OPF\", \"graph\" (buses, branches, components; \"dynamics\" also for the controllers). The\nrows are the elements of the network (buses, branches, components, local controllers,\nglobal controllers, in the order of net.get_element_table) that have the group with at\nleast one parameter, filtered by Key, Class and Owner; the row names are their tags,\nthe columns the parameters, with the values and classes of tab_parameter.(Group). A\nglobal controller whose group has one row per controlled unit gives one row per unit,\nnamed \"<controller tag>/<unit tag>\".\n\nWhen the selected elements have different parameters (e.g. the dynamics of two governor\nmodels, or of an AVR and its PSS), the table has the union of their columns, in the order\nin which they first appear, and a first column Key (string): the model key of the\nelement of each row (its class for an element without a key). A row gets the missing\nvalue of the column for a parameter its element does not have: NaN (double), <missing>\n(string), false (logical). When all selected elements have the same parameters, there\nis no Key column. Elements whose group has no parameters (e.g. the dynamics of a\nconstant-impedance load) are left out.\n\nThe table is a copy: edit it and write it back with net.set_parameter(Group, tab), which\nskips the Key column and the filled values of the parameters an element does not have.\nThe network is not changed.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus(LocalController=true);            % with the AVRs and PSSs\nnet.get_parameter(\"dynamics\", Key=\"gen-1axis\")          % M, D, Xd, ... of the generators\ntab = net.get_parameter(\"powerflow\", Class=\"component.load.abstract\");\ntab.P = 1.5*tab.P;  tab.Q = 1.5*tab.Q;                    % all loads x1.5\nnet.set_parameter(\"powerflow\", tab);\nnet.get_parameter(\"powerflow\", Class=\"Bus\")             % V, Varg of the buses\nnet.get_parameter(\"dynamics\", Owner=\"B001SG1\")          % AVR and PSS: union of the columns, Key column\n```\n\nSee also PowerNetwork.set_parameter, PowerNetwork.get_element_table, Parameter",
      "Deprecated": ""
    },
    {
      "Name": "get_element_table",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "tab"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Kind",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Kind, [\"bus\",\"branch\",\"component\",\"local\",\"global\"])"
          ],
          "Default": "[\"bus\",\"branch\",\"component\",\"local\",\"global\"]",
          "Required": false,
          "Unit": "",
          "Description": "Kinds of the elements to list."
        },
        {
          "Name": "Owner",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Tag of an element: list only the elements below it (\"\": all)."
        }
      ],
      "Outputs": [
        {
          "Name": "tab",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One row per element: Tag, Kind, Key, Class, Role, Bus, Parent, From, To, State, Input, Output (strings)."
        }
      ],
      "Signature": "tab = get_element_table(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/get_element_table.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return a table of the elements of the network, one row per element.",
      "Desc": "Rows: the buses, branches, components (bus by bus), local controllers (component by\ncomponent, depth first: AVR or \"local\" controller, the PSS under it, then the governor)\nand global controllers; the row names are the tags (when no two rows share a tag). The scenarios are not model\nelements and have no row (net.get_element finds them). Every column is a string:\n\n- Tag: tag of the element (net.get_element(Tag) returns it).\n- Kind: \"bus\", \"branch\", \"component\", \"local\" (local controller) or \"global\" (global controller).\n- Key: model key (e.g. \"gen-1axis\", \"avr-ST1\", \"pi\"); \"\" for a bus.\n- Class: class name (e.g. \"component.generator.one_axis\").\n- Role: role of a controller (\"avr\", \"pss\", \"governor\", \"local\", \"agc\", ...); \"\" otherwise.\n- Bus: tag of the bus the element belongs to (a bus: itself; \"\" for a branch and a global controller).\n- Parent: tag of the parent element (a component: its bus; a local controller: its\n  component, or the AVR for a PSS); \"\" for the elements directly under the network.\n- From, To: end buses of a branch; \"\" for the other kinds.\n- State, Input, Output: names of the states, inputs and outputs (sv_x, sv_u, sv_y)\n  joined by \", \"; \"\" for a bus and a branch.\n\nKind keeps the rows of the given kinds. Owner keeps the elements below the element with\nthat tag (its children, their children, ...; not the element itself), e.g. the\ncomponents and controllers of a bus, or the controllers of a generator. The network is\nnot changed.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\ntab = net.get_element_table();\ntab(tab.Kind == \"component\", [\"Tag\", \"Key\", \"Bus\"])\nnet.get_element_table(Kind=\"branch\")                 % From and To of each branch\nnet.get_element_table(Owner=\"B001SG1\")               % the controllers of a generator\nnet.get_element_table(Kind=\"local\").Role             % avr, pss, governor, ...\n```\n\nSee also PowerNetwork.get_element, PowerNetwork.get_parameter, PowerNetwork.disp_summary",
      "Deprecated": ""
    },
    {
      "Name": "get_element",
      "Defining": "PowerNetwork",
      "Group": "Queries and display",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Tag"
      ],
      "OutputNames": [
        "obj_elem"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the elements."
        }
      ],
      "Outputs": [
        {
          "Name": "obj_elem",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The element (one tag) or a cell array of the elements (several tags)."
        }
      ],
      "Signature": "obj_elem = get_element(obj, Tag)",
      "File": "_GUILDAsystem/@PowerNetwork/get_element.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:ElementNotFound",
        "GUILDA:PowerNetwork:ElementAmbiguous"
      ],
      "Summary": "Return the element of the network with the given tag.",
      "Desc": "Looks the tag up among the buses, branches, components, local controllers, global\ncontrollers and scenarios of the network. One tag returns the object; several tags\nreturn a cell array of the objects, in the order of Tag. A tag that no element has stops\nwith GUILDA:PowerNetwork:ElementNotFound, which names it; a tag that two elements share\n(tags are unique only among siblings) stops with GUILDA:PowerNetwork:ElementAmbiguous.\nThe network is not changed.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\ngen = net.get_element(\"B001SG1\");                 % the generator on bus B001\nc   = net.get_element([\"B001\", \"B001SG1CA1\"]);    % {bus, AVR}\nnet.get_element_table(Kind=\"local\")               % the tags of the local controllers\n```\n\nSee also PowerNetwork.get_element_table, PowerNetwork.get_parameter",
      "Deprecated": ""
    },
    {
      "Name": "simulate",
      "Defining": "PowerNetwork",
      "Group": "Simulation",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_scenario",
        "opt"
      ],
      "OutputNames": [
        "result",
        "flag",
        "output"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "s_scenario",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "simulateFcn_mustBeScenarioOf(obj, s_scenario)"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tag of the scenario to run (net.add_scenario)."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [
            "mustBeSimulationTime"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Simulation time [t0, tend] of this call. Default: the Time of the scenario."
        },
        {
          "Name": "Solver",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Solver, [\"ode15s\",\"ode23t\"])"
          ],
          "Default": "GUILDA.config(\"TimeSimulation\", \"Solver\")",
          "Required": false,
          "Unit": "",
          "Description": "Solver of the MATLAB ode object."
        },
        {
          "Name": "Tolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInRange(opt.Tolerance, 1e-15, 1e-3)"
          ],
          "Default": "GUILDA.config(\"TimeSimulation\", \"Tolerance\")",
          "Required": false,
          "Unit": "",
          "Description": "Relative error tolerance."
        },
        {
          "Name": "AbsoluteTolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInRange(opt.AbsoluteTolerance, 1e-15, 1e-3)"
          ],
          "Default": "GUILDA.config(\"TimeSimulation\", \"AbsoluteTolerance\")",
          "Required": false,
          "Unit": "",
          "Description": "Absolute error tolerance."
        },
        {
          "Name": "MaxStep",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositiveOrNaN"
          ],
          "Default": "GUILDA.config(\"TimeSimulation\", \"MaxStep\")",
          "Required": false,
          "Unit": "s",
          "Description": "Largest step of the solver; NaN for the solver default."
        },
        {
          "Name": "InitialStep",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositiveOrNaN"
          ],
          "Default": "GUILDA.config(\"TimeSimulation\", \"InitialStep\")",
          "Required": false,
          "Unit": "s",
          "Description": "First step of each phase; NaN for the solver default."
        },
        {
          "Name": "SeparateComplexParts",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"TimeSimulation\", \"SeparateComplexParts\")",
          "Required": false,
          "Unit": "",
          "Description": "SeparateComplexParts of the ode object (true: \"on\", false: \"off\")."
        },
        {
          "Name": "SampleTime",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "simulateFcn_mustBeNonnegativeOrNaN"
          ],
          "Default": "GUILDA.config(\"TimeSimulation\", \"SampleTime\")",
          "Required": false,
          "Unit": "s",
          "Description": "Interval of the recorded times from the start time (with the start and end of each phase; the progress display does not move during a phase); NaN or 0 for the solver steps."
        },
        {
          "Name": "StopOnOutOfStep",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"TimeSimulation\", \"StopOnOutOfStep\")",
          "Required": false,
          "Unit": "",
          "Description": "Stop the run when a rotor angle from the generator of the slack bus exceeds StopAngle (flag 2)."
        },
        {
          "Name": "StopAngle",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"TimeSimulation\", \"StopAngle\")",
          "Required": false,
          "Unit": "deg",
          "Description": "Threshold of StopOnOutOfStep."
        },
        {
          "Name": "TimeLimit",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"TimeSimulation\", \"TimeLimit\")",
          "Required": false,
          "Unit": "s",
          "Description": "Wall-clock limit of the whole run; Inf for none."
        },
        {
          "Name": "Progress",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeProgress"
          ],
          "Default": "GUILDA.config(\"TimeSimulation\", \"Progress\")",
          "Required": false,
          "Unit": "",
          "Description": "\"dialog\", \"disp\" or \"none\" (true: \"dialog\", false: \"none\")."
        },
        {
          "Name": "Verbose",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"TimeSimulation\", \"Verbose\")",
          "Required": false,
          "Unit": "",
          "Description": "Print the phases and the outcome."
        },
        {
          "Name": "PlotFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "GUILDA.config(\"TimeSimulation\", \"PlotFcn\")",
          "Required": false,
          "Unit": "",
          "Description": "Live display during the run: \"none\" (checked by tools.check_plotfcn; draw the result with result.plot_trajectory())."
        },
        {
          "Name": "Format",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Format, [\"GUILDAorigin\",\"struct\"])"
          ],
          "Default": "\"GUILDAorigin\"",
          "Required": false,
          "Unit": "",
          "Description": "Form of the first output."
        }
      ],
      "Outputs": [
        {
          "Name": "result",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Trajectories: ResultODE (Format \"GUILDAorigin\"; result.odeResults) or a struct that mirrors the model hierarchy, with tables (Format \"struct\")."
        },
        {
          "Name": "flag",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "1 completed, 2 stopped by StopOnOutOfStep, 0 stopped by TimeLimit, -1 stopped by the solver."
        },
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Details: message, tEnd, phases, nPhases, nPhasesDone, isSparse, exception, outOfStep."
        }
      ],
      "Signature": "[result, flag, output] = simulate(obj, s_scenario, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/simulate.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Simulate one scenario of the network over time and return a ResultODE (or a struct).",
      "Desc": "Time simulation of the network from its equilibrium: the DAE of the buses, components\nand controllers is integrated over time, with the disturbances of the scenario\ns_scenario (Scenario: bus faults, unit trips, branch openings, state offsets, input\nchanges). The scenario is chosen by its tag among the scenarios of the network\n(net.add_scenario); a tag that is not one stops with GUILDA:PowerNetwork:ScenarioNotFound,\nwhich lists the tags. A run without disturbance uses a scenario without disturbances.\n\nThe time is the Time of the scenario ([0, 10] unless set), or the Time option of the\ncall. The settings are the TimeSimulation section of GUILDA.setting, the defaults of the\nName-Value options; an option given in the call replaces one setting for this call only\n(the settings file and the scenario are not changed). The options go to net.solver_ODE as\nthey are (Progress true/false as \"dialog\"/\"none\"). A name that is not an option stops\nwith the error of the MATLAB arguments block.\nIt stops with an error naming the remedy when the network is not initialized or was\nedited after net.initialize. flag is 1 when the simulation reached the end time, 0 when\nit stopped by TimeLimit and -1 when the solver stopped early; then result holds the\ntrajectories up to output.tEnd, and a warning GUILDA:PowerNetwork:SimulationIncomplete\ntells it, whether or not flag is requested. To write the result to a file, call\nresult.export(...). The verdict is not computed here: call result.judge_out_of_step().\n\nWith StopOnOutOfStep=true the run stops when the absolute rotor angle delta of a\ngenerator from that of the generator of the slack bus exceeds StopAngle [deg]: flag is\n2, the trajectories end at that time (output.tEnd), output.outOfStep holds Time, Unit,\nReference and Angle, and no warning is given (output.outOfStep is empty otherwise). A\ntripped generator is not compared, and while the reference is tripped the run does not\nstop. A network without such generators stops with GUILDA:PowerNetwork:StopNoRotorAngle.\nWith SampleTime > 0 the times of the result are t0 + k*SampleTime and the start and end\nof each phase (a boundary appears twice), with the values of the solver at those times\n(interpolated); the steps of the solver do not change (use MaxStep), and a run that\nstops early ends at the time it stopped. The progress display does not move during a\nphase with SampleTime. NaN or 0 records the solver steps.\n\nWith Format=\"struct\", result is a struct that mirrors the model hierarchy, for repeated\nruns: result.t (the times, shared by every table), result.a_Bus{i}.V, .I, .P, .Q,\nresult.a_Bus{i}.a_Component{j}.x, .u, .I (the current the component injects),\n.a_LocalController{k}.x, .u (nested as in the model), result.a_GlobalController{k}.x, .u\n(one column <input>_<unit tag> per controlled unit). Each is a table with one variable\nper name, without a Time column; each element has s_tag. The outputs y are not computed\n(use result.rm_output of a ResultODE).",
      "SeeAlso": [],
      "Examples": "```matlab\nnet.initialize();\nsc = net.add_scenario(\"fault\", Time=[0, 10]);\nsc.add_fault(\"B008\", [1, 1.05]);\n[res, flag] = net.simulate(\"fault\", Progress=\"none\", TimeLimit=Inf);\nres.odeResults.Bus(1).Component(1).X.omega    % frequency deviation of a generator\nres.plot_trajectory(Quantity=\"omega\");\n```\n\nThe time and the settings of one call:\n\n```matlab\nres = net.simulate(\"fault\", Time=[0, 20]);                   % sc.Time is not changed\nres = net.simulate(\"fault\", Tolerance=1e-8, MaxStep=0.01);   % this call only\nres = net.simulate(\"fault\", SampleTime=0.01);                % t = 0, 0.01, 0.02, ...\n[res, flag, output] = net.simulate(\"fault\", StopOnOutOfStep=true, StopAngle=180);\noutput.outOfStep                                             % when flag == 2\nGUILDA.setting(\"TimeSimulation\", Tolerance=1e-8)             % every later run\nres.export(\"fault.csv\");\n```\n\nRepeated runs without a ResultODE:\n\n```matlab\nsol = net.simulate(\"fault\", Format=\"struct\");\nplot(sol.t, sol.a_Bus{1}.a_Component{1}.x.omega)\n```\n\nSee also Scenario, ResultODE, SolverODE, PowerNetwork.add_scenario, PowerNetwork.initialize, GUILDA.setting",
      "Deprecated": ""
    },
    {
      "Name": "get_admittance_matrix",
      "Defining": "PowerNetwork",
      "Group": "Called by analyses",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "tab_Ybus2bus",
        "cm_Ybranch"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "BranchStatus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "table(strings(0,1), strings(0,1), zeros(0,1), VariableNames=[\"Target\",\"Status\",\"Point\"])",
          "Required": false,
          "Unit": "",
          "Description": "States of branches with the columns Target, Status, Point (rows of a Scenario's event table can be passed as they are); branches without a row are closed."
        }
      ],
      "Outputs": [
        {
          "Name": "tab_Ybus2bus",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Admittance matrix (complex) with bus tags as row and variable names."
        },
        {
          "Name": "cm_Ybranch",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Admittance matrix of each branch in its state (2 x 2 x n_branch, complex)."
        }
      ],
      "Signature": "[tab_Ybus2bus, cm_Ybranch] = get_admittance_matrix(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/get_admittance_matrix.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:InvalidBranchStatus"
      ],
      "Summary": "Return the bus admittance matrix of the network as a table.",
      "Desc": "Rows and columns are the bus tags in the order of `a_Bus`. The matrix sums the\nadmittance matrices of the branches and the shunt admittances Gshunt + j*Bshunt of\nthe buses, in per unit.\n\nBranchStatus gives the states of branches: a table with the columns Target (branch\ntag), Status and Point; other columns (such as Tag and Time of the event table of a\nScenario) are ignored. Branches without a row are closed, and an empty table gives the\nmatrix of the closed network. A branch takes at most one fault row (Status \"3LG\",\n\"6LG\" or \"none\", with the fault position Point, 0 < Point < 1, from the from end) and\none parallel row (Status \"3open\", \"6open\" or \"close\"; Point is ignored, e.g. NaN). A\nmissing fault row is \"none\" and a missing parallel row \"close\". The two rows of a\nbranch with n circuits combine into one matrix Y(...) = Branch.get_admittance_matrix(\nStatus=..., Point=...):\n\n  fault \\ parallel | close         | 3open                   | 6open\n  none             | Y(\"close\")    | Y(\"3open\")              | Y(\"6open\") = 0\n  3LG at p         | Y(\"3LG\", p)   | Y(\"3open\") (the faulted | Y(\"6open\")\n                   |               | circuit is opened)      |\n  6LG at p         | Y(\"6LG\", p)   | (n-1)/n * Y(\"6LG\", p)   | Y(\"6open\")\n                   |               | (the other circuits     |\n                   |               | stay grounded)          |\n\ncm_Ybranch holds the 2x2 matrix of each branch in its state (pages in the order of\na_Branch, rows and columns in the order of its a_Bus): the matrices summed into the\nnetwork matrix. The time simulation keeps them for the branch flows of ResultODE.\n\nOnly this method and Branch.get_admittance_matrix build the matrix of branch states;\nthe power flow, the linearization and the simulation share them. A wrong table stops\nwith GUILDA:PowerNetwork:InvalidBranchStatus (a Target that is not a branch tag, a\nStatus that is not a branch state, such as \"BG\" or \"open\", or two rows of the same\nkind on one branch); the branch reports a wrong Point (GUILDA:Branch:InvalidPoint) and\n\"3LG\" or \"3open\" on a single-circuit branch (GUILDA:Branch:SingleCircuit).",
      "SeeAlso": [],
      "Examples": "```matlab\ntab_Y = net.get_admittance_matrix();\nY = tab_Y.Variables;\n% one circuit of EL001 grounded at 30 %, all circuits of EL002 open\ntab_state = table([\"EL001\";\"EL002\"], [\"3LG\";\"6open\"], [0.3; NaN], ...\n    VariableNames=[\"Target\",\"Status\",\"Point\"]);\ntab_Yf = net.get_admittance_matrix(BranchStatus=tab_state);\n% the start rows of the events of a scenario, passed as they are\nsc = net.add_scenario(\"case1\");\nsc.add_fault(\"EL003\", [0.10, 0.17], Status=\"3LG\", Point=0.3);\ntab_Yf = net.get_admittance_matrix(BranchStatus=sc.tab_event(sc.tab_event.Time == 0.10, :));\n```\n\nSee also Branch.get_admittance_matrix",
      "Deprecated": ""
    },
    {
      "Name": "get_variable_map",
      "Defining": "PowerNetwork",
      "Group": "Called by analyses",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_form"
      ],
      "OutputNames": [
        "tab",
        "c_idxBus",
        "c_idxGC",
        "tab_connection"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "s_form",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(s_form, [\"table\",\"rows\"])"
          ],
          "Default": "\"table\"",
          "Required": false,
          "Unit": "",
          "Description": "\"rows\" (internal): return the rows without the tables."
        }
      ],
      "Outputs": [
        {
          "Name": "tab",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One row per variable or signal: Index, Kind, Role, Owner, Name, Label, Bus, Equilibrium."
        },
        {
          "Name": "c_idxBus",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "c_idxBus{i}: rows of tab that form a_Bus{i}.get_variable_map(), in its order."
        },
        {
          "Name": "c_idxGC",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "c_idxGC{k}: rows of tab of a_GlobalController{k} (its x, uc, yc)."
        },
        {
          "Name": "tab_connection",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One row per connection: Index, Kind, Source, Target, SourceIndex, TargetIndex."
        }
      ],
      "Signature": "[tab, c_idxBus, c_idxGC, tab_connection] = get_variable_map(obj, s_form)",
      "File": "_GUILDAsystem/@PowerNetwork/get_variable_map.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the variable map (every variable and signal of the network) and the connection map.",
      "Desc": "Variable map of the network: the single definition of the order of the variables and\nsignals of the network model, used by get_sys (ResultLIN blocks and the point), by\nnet.simulate (the order of the DAE vector) and by the other analyses. The order is\n  1. x: states. For each bus in a_Bus, for each component in a_Component, the states of\n     the component and then of its local controllers (depth first: the AVR or \"local\"\n     controller, the PSS attached under the AVR, then the governor, whatever the order\n     of attachment); then the states of each global controller in a_GlobalController\n  2. Vre, Vim: bus voltages of each bus in a_Bus (B1 Vre, B1 Vim, B2 Vre, ...)\n  3. u: inputs sv_u of each component (bus by bus)\n  4. uc: inputs of the controllers: those of the local controllers (bus by bus, component\n     by component, depth first), then those of each global controller, unit by unit\n     (sv_u of unit 1, sv_u of unit 2, ...)\n  5. y: outputs sv_y of each component (bus by bus)\n  6. yc: outputs of the controllers, in the order of 4 (sv_y of each unit for a global\n     controller)\nRows 1-4 are the variables of the DAE (Role \"variable\"); rows 5-6 are signals computed\nfrom them at each evaluation (Role \"signal\"). The rows of the kinds x, Vre, Vim, u and\nuc come first and are the point of the linearization (get_sys), every value used as\ngiven; the linear model eliminates the controller inputs uc through the connection map.\nThe bus current of the simulation\nis not in the map: SolverODE places it after the voltages.\nThe map of a bus or a component (bus.get_variable_map, comp.get_variable_map) is the\nrestriction of this map to its rows, in the same relative order.\nColumns: Index (row number), Kind (\"x\" | \"Vre\" | \"Vim\" | \"u\" | \"uc\" | \"y\" | \"yc\"),\nRole (\"variable\" | \"signal\"), Owner (tag of the component, controller or bus that owns\nthe row), Name (variable or port name, e.g. \"delta\"), Label (tagged name, equal to the\nStateName / InputName / OutputName used by get_sys; an output with the name of a state of\nits owner is \"Y_\" + name; a row of a global controller is labelled\ngc.attach_tag(name + \"_\" + unit tag), as it has one per controlled unit),\nBus (tag of the bus the owner is attached to; \"\" for a global controller),\nEquilibrium (value at the equilibrium set by net.initialize: the stored rv_Xequilibrium,\nc_Vequilibrium, rv_Uequilibrium of the owners, and the outputs y and yc evaluated there\nby their output functions; NaN in every row before net.initialize). The Equilibrium of\nthe leading rows x, Vre, Vim, u, uc is the point of net.get_sys([]).\n\nThe connection map tab_connection is the only place where it is decided which signal\ndrives which input. One row per connection, in the order of the inputs they drive:\n  \"local\"       the output of a local controller into the input of the same name of its\n                parent (the component, or the AVR for a PSS)\n  \"observe\"     an output (before a state of the same name) or a state of a component\n                into an input of a local controller that observes it, or into an input\n                of a global controller that controls it\n  \"equilibrium\" an input without a \"local\" or \"observe\" source keeps its equilibrium\n  \"global\"      an output of a global controller, for each unit: into every local\n                controller of the unit (nested ones included, depth first) that has an\n                input of that name, otherwise into the input of that name of the unit\n                (no row when neither exists: the users of the map report it)\nColumns: Index, Kind, Source and Target (Labels; Source is \"\" for \"equilibrium\"),\nSourceIndex and TargetIndex (Index of the rows in tab; 0 for no source). An input is the\nsum of its sources; the inputs of the components also get the input events of a scenario.\nA table is used so that the map prints as is and can be filtered with the usual\ntable operations (tab(tab.Kind == \"x\", :)); the Label column is the key that links it\nto state-space models and results.\nThe tables are made once, at the end: the bus and component methods return their rows\nwith get_variable_map(\"rows\"), the cell {sm_x; sm_V; sm_u; sm_uc; sm_y; sm_yc} of string\nmatrices with the columns Kind, Owner, Name, Label, Bus, and the connections as a string\nmatrix (Kind, kind and label of the source, kind and label of the target). The rows form\nhas no Equilibrium; only the table form computes it.",
      "SeeAlso": [],
      "Examples": "```matlab\n[tab, ~, ~, tab_connection] = net.get_variable_map();\ntab(tab.Kind == \"x\", [\"Owner\",\"Name\"])\ntab_connection(tab_connection.Kind == \"global\", :)\nx0 = tab.Equilibrium(ismember(tab.Kind, [\"x\",\"Vre\",\"Vim\",\"u\",\"uc\"]));   % the point of the equilibrium\nres = net.get_sys(x0);           % same as net.get_sys()\n```\n\nSee also PowerSystemModel.get_sys, PowerNetwork.simulate, Bus.get_variable_map, Component.get_variable_map",
      "Deprecated": ""
    },
    {
      "Name": "calculate_continuation_powerflow",
      "Defining": "PowerNetwork",
      "Group": "CPF",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "result",
        "flag",
        "output"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "LoadBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "obj.solver_CPF.LoadBus",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the buses whose loads are scaled by (1 + lambda)."
        },
        {
          "Name": "MaxIteration",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive",
            "mustBeInteger"
          ],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"MaxIteration\")",
          "Required": false,
          "Unit": "",
          "Description": "Maximum number of predictor-corrector steps."
        },
        {
          "Name": "Tolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"Tolerance\")",
          "Required": false,
          "Unit": "",
          "Description": "Convergence tolerance of the corrector."
        },
        {
          "Name": "StepSize",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"StepSize\")",
          "Required": false,
          "Unit": "",
          "Description": "Step size of the predictor."
        },
        {
          "Name": "ArcLength",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"ArcLength\")",
          "Required": false,
          "Unit": "",
          "Description": "Arc length of the corrector."
        },
        {
          "Name": "InitialLambda",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"InitialLambda\")",
          "Required": false,
          "Unit": "",
          "Description": "lambda at the starting point."
        },
        {
          "Name": "UseInternalState",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"UseInternalState\")",
          "Required": false,
          "Unit": "",
          "Description": "Solve with the internal states of the generators."
        },
        {
          "Name": "Verbose",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"Verbose\")",
          "Required": false,
          "Unit": "",
          "Description": "Print lambda at each step."
        },
        {
          "Name": "Limits",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"Limits\")",
          "Required": false,
          "Unit": "",
          "Description": "Operating limits along the path: \"Q\", \"V\", \"S\", \"all\" or \"none\" (checked by SolverCPF.solve)."
        },
        {
          "Name": "PlotFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"PlotFcn\")",
          "Required": false,
          "Unit": "",
          "Description": "Live display during the calculation: \"pvcurve\", a function handle or \"none\" (checked by tools.check_plotfcn)."
        },
        {
          "Name": "Progress",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeProgress"
          ],
          "Default": "GUILDA.config(\"ContinuationPowerFlow\", \"Progress\")",
          "Required": false,
          "Unit": "",
          "Description": "\"dialog\", \"disp\" or \"none\" (true: \"dialog\", false: \"none\")."
        },
        {
          "Name": "Export",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeA(opt.Export, [\"logical\",\"string\",\"char\"])"
          ],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Call result.export after the calculation: true or a file name."
        }
      ],
      "Outputs": [
        {
          "Name": "result",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "lambda and bus voltages along the path, and the nose point."
        },
        {
          "Name": "flag",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True when the path passed the nose."
        },
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Details: message, iterations, correctorIterations."
        }
      ],
      "Signature": "[result, flag, output] = calculate_continuation_powerflow(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/calculate_continuation_powerflow.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Trace the PV curve by the continuation power flow and return a ResultCPF.",
      "Desc": "Traces the PV curve of the network by the continuation power flow: starting from the\nequilibrium of net.initialize, the loads of LoadBus are scaled by (1 + lambda) and the\npower flow solution is followed past the maximum loading point (the nose). The\nsettings are the ContinuationPowerFlow section of GUILDA.setting, and the condition\nLoadBus is kept by net.solver_CPF; Name-Value options override them for this call only\n(neither net.solver_CPF nor the settings file is changed).\nOptions not listed below stop with the MATLAB error of an unknown name.\nIt stops with an error naming the remedy when the network is not initialized (or was\nedited after net.initialize) and when LoadBus is empty or names an unknown bus.\n\nName-Value options:\n\n- `LoadBus` — Tags of the buses whose loads are scaled by (1 + lambda) (net.solver_CPF.LoadBus).\n- `MaxIteration` — Maximum number of predictor-corrector steps Default: GUILDA.setting (500).\n- `Tolerance` — Convergence tolerance of the Newton-Raphson corrector. Default: GUILDA.setting (1e-5).\n- `StepSize` — Step size of the predictor. Default: GUILDA.setting (0.5).\n- `ArcLength` — Arc length of the corrector. Default: GUILDA.setting (1e-3).\n- `InitialLambda` — lambda at the starting point. Default: GUILDA.setting (0).\n- `UseInternalState` — Solve with the internal states of the generators. Default: GUILDA.setting (false).\n- `Verbose` — Print lambda at each step. Default: GUILDA.setting (false).\n- `Limits` — Operating limits applied along the path: a subset of \"Q\" (PV to PQ at the Q limits of the generators), \"V\" (stop at Vmin/Vmax of a bus), \"S\" (stop at Smax of a branch), or \"all\" / \"none\". Default: GUILDA.setting (\"none\"). See ResultCPF.tab_switch and tab_stop.\n- `PlotFcn` — Live display during the calculation: \"pvcurve\" draws |V| of every bus against lambda and extends the lines at each step; a function handle is called at the starting point and each step as stop = f(x, optimValues, state) (x the complex bus voltages; optimValues.iteration, .lambda, .correctorIterations; state \"init\", \"iter\", \"done\"), and a true stop ends the path there; \"none\" draws nothing. The PV curves after the calculation: result.plot_pvcurve(). Default: GUILDA.setting (\"none\").\n- `Progress` — Progress display: \"dialog\" (a dialog that opens when the calculation lasts 0.5 s or longer, showing the step and lambda; inside the GUILDA app a dialog of the app window), \"disp\" (one line per step in the Command Window) or \"none\"; true is \"dialog\" and false \"none\". Default: GUILDA.setting (\"dialog\").\n- `Export` — Call result.export after the calculation: true for the default file name, or the file name. Default: false.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet.initialize();\n[res, flag] = net.calculate_continuation_powerflow(LoadBus=[\"B009\",\"B010\"]);\nres.r_lambdaMax          % maximum loading\nres.plot_pvcurve();              % PV curves of the load buses\n```\n\nSee also ResultCPF, SolverCPF",
      "Deprecated": ""
    },
    {
      "Name": "get_pf_condition",
      "Defining": "PowerNetwork",
      "Group": "Power flow",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "varargout"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Display",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Print the bus table."
        }
      ],
      "Outputs": [
        {
          "Name": "varargout",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "sct_PFcondition: struct with the tables Bus and Y."
        }
      ],
      "Signature": "varargout = get_pf_condition(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/get_pf_condition.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:NoBus",
        "GUILDA:PowerNetwork:NoSlackBus"
      ],
      "Summary": "Return the power-flow condition of the network: the data the power flow runs with.",
      "Desc": "Stacks Bus.get_pf_condition of every bus (in the order of a_Bus) and adds the bus\nadmittance matrix. These are the data net.calculate_powerflow passes to net.solver_PF;\nnet.calculate_fixed_input_powerflow takes its slack bus and admittance matrix from them.\n\n- Bus: Type (\"slack\", \"PV\" or \"PQ\"), Varg, V, P, Q (NaN where the type does not set the\n  value); row names = bus tags.\n- Y: the bus admittance matrix as a table, the same as get_admittance_matrix.\n\nThe slack bus is the bus with l_isSlack = true; GUILDA never selects one. A network\nwithout buses stops with GUILDA:PowerNetwork:NoBus, and a network without a slack bus\nwith GUILDA:PowerNetwork:NoSlackBus, which tells how to set one. The network is not\nchanged.\n\nWith Display=true (default) the Bus table is printed (Y is not); with no output\nnothing is returned.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.get_pf_condition();                          % print the bus table\nsct = net.get_pf_condition(Display=false);\nsct.Bus(sct.Bus.Type == \"PV\", :)                 % the PV buses\ncm_Y = sct.Y{:,:};                               % admittance matrix (a_Bus order)\n```\n\nSee also Bus.get_pf_condition, PowerNetwork.calculate_powerflow, PowerNetwork.get_admittance_matrix",
      "Deprecated": ""
    },
    {
      "Name": "calculate_fixed_input_powerflow",
      "Defining": "PowerNetwork",
      "Group": "Power flow",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "result",
        "flag",
        "output"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Solver",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Solver, [\"newton\",\"gradient\",\"levenberg-marquardt\",\"fsolve\",\"dynamic\"])"
          ],
          "Default": "\"newton\"",
          "Required": false,
          "Unit": "",
          "Description": "Algorithm: \"newton\", \"levenberg-marquardt\" or \"fsolve\"."
        },
        {
          "Name": "Tolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"Tolerance\")",
          "Required": false,
          "Unit": "",
          "Description": "Largest residual of a converged solution."
        },
        {
          "Name": "MaxIteration",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeIntegerOrNaN"
          ],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"MaxIteration\")",
          "Required": false,
          "Unit": "",
          "Description": "Maximum number of iterations; NaN for the automatic value."
        },
        {
          "Name": "Verbose",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"Verbose\")",
          "Required": false,
          "Unit": "",
          "Description": "Print the progress of each iteration."
        },
        {
          "Name": "WarmStart",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"WarmStart\")",
          "Required": false,
          "Unit": "",
          "Description": "Start from the held equilibrium."
        },
        {
          "Name": "Progress",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeProgress"
          ],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"Progress\")",
          "Required": false,
          "Unit": "",
          "Description": "\"dialog\", \"disp\" or \"none\" (true: \"dialog\", false: \"none\")."
        },
        {
          "Name": "Format",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Format, [\"V\",\"powerflow(mat)\",\"powerflow(tab)\",\"GUILDAorigin\"])"
          ],
          "Default": "\"GUILDAorigin\"",
          "Required": false,
          "Unit": "",
          "Description": "Form of the first output."
        }
      ],
      "Outputs": [
        {
          "Name": "result",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Solution in the form of Format: a ResultPF (default), bus voltages, or an n-by-4 matrix or table of V, I, P, Q."
        },
        {
          "Name": "flag",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "1 converged, 0 MaxIteration reached, -2 diverged or no solution (see the Method* classes)."
        },
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Solver details; output.message describes the outcome, output.tab_component holds X, U, I of each component."
        }
      ],
      "Signature": "[result, flag, output] = calculate_fixed_input_powerflow(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/calculate_fixed_input_powerflow.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:InitializeFixedInputSolver",
        "GUILDA:PowerNetwork:InitializeInputNotSet",
        "GUILDA:PowerNetwork:InitializeNoSlackGenerator",
        "GUILDA:PowerNetwork:InitializeFixedInputFailed"
      ],
      "Summary": "Calculate the power flow with the inputs of the components held.",
      "Desc": "Solves the equilibrium of the network with the inputs that the components hold\n(rv_Uequilibrium, edited with Component.set_input). The unknowns are the states x and\nthe currents I of every component, the bus voltages V and the Pmech of the first\ngenerator of the slack bus, which balances the power. The equations are f_dx = 0 and\nf_I = I of every component, Kirchhoff's current law Y*V = sum(I) at every bus and the\nreference angle 0 at the slack bus. The V and Varg settings of the slack bus and the\npowerflow settings of the components are not used. Local and global controllers are not\nin the equations. net.initialize(Method=\"FixedInput\") writes the solution and gives the\ncontrollers their equilibria.\n\nThe network is not changed. The slack bus and the admittance matrix come from\nnet.get_pf_condition: a network without a slack bus (l_isSlack) stops with\nGUILDA:PowerNetwork:NoSlackBus. Every component must hold its inputs\n(GUILDA:PowerNetwork:InitializeInputNotSet), and the slack bus needs a generator\n(GUILDA:PowerNetwork:InitializeNoSlackGenerator). A network split into islands has no\nunique solution, so the calculation does not converge (initialize names the islands in\nits error). The values of the options that are left out come from the\nPowerFlowCalculation section of GUILDA.setting. Options not listed below stop with the\nMATLAB error of an unknown name.\n\nName-Value options:\n\n- `Format` — Form of the first output (flag and output stay the 2nd and 3rd outputs). Default: \"GUILDAorigin\".\n  - \"V\": complex bus voltages [pu], a column in net.a_Bus order.\n  - \"powerflow(mat)\": n-by-4 complex double, one row per bus (net.a_Bus order); columns V, I (complex phasors of the voltage and the current injection), P, Q (real injections into the network) [pu].\n  - \"powerflow(tab)\": the same as a table with the variables V, I, P, Q; row names = bus tags.\n  - \"GUILDAorigin\": a ResultPF whose solver is \"FixedInput\" (bus table, branch flows, violated operating limits, the disp_* methods and export).\n- `Solver` — Algorithm: \"newton\", \"levenberg-marquardt\" or \"fsolve\" (\"gradient\" and \"dynamic\" stop with GUILDA:PowerNetwork:InitializeFixedInputSolver). Default: \"newton\".\n- `Tolerance` — Largest residual of a converged solution. Default: GUILDA.setting (1e-8).\n- `MaxIteration` — Maximum number of iterations; NaN for the automatic value (50 \"newton\", 100 \"levenberg-marquardt\", 400 \"fsolve\"). Default: GUILDA.setting (NaN).\n- `Verbose` — Print the progress of each iteration. Default: GUILDA.setting (false).\n- `Progress` — Progress display: \"dialog\" (a dialog that opens when the calculation lasts 0.5 s or longer, showing the iteration; inside the GUILDA app a dialog of the app window), \"disp\" (one line per iteration in the Command Window) or \"none\"; true is \"dialog\" and false \"none\". Default: GUILDA.setting (\"dialog\").\n- `WarmStart` — true starts from the held equilibrium when every component holds one; false, or a component without one, from a power flow that is not written. A run from the held equilibrium that ends with flag 0 or -2 is solved once more from that power flow; flag, output and the history are those of that run, and output.message says so (Verbose=true also prints one line). Default: GUILDA.setting (true).\n\noutput.tab_component is the solution of each component: one row per component (row\nnames = component tags, bus by bus in net.a_Bus order) with the variables Bus (bus tag),\nX (states), U (inputs, with the solved Pmech of the slack generator) and I (current\ninjection, complex phasor) [pu].",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();\nld = net.a_Bus{5}.a_Component{1};\nld.set_input(ld.rv_Uequilibrium/0.95);              % 5 % less load\n[res, flag, output] = net.calculate_fixed_input_powerflow();   % ResultPF\nres.tab_bus               % V, P, Q of each bus at the held inputs\noutput.tab_component      % X, U, I of each component\npf = net.calculate_fixed_input_powerflow(Format=\"powerflow(mat)\", Solver=\"levenberg-marquardt\");\nnet.initialize(Method=\"FixedInput\");                % write the solution\n```\n\nSee also PowerNetwork.initialize, PowerNetwork.calculate_powerflow, Component.set_input, ResultPF",
      "Deprecated": ""
    },
    {
      "Name": "calculate_powerflow",
      "Defining": "PowerNetwork",
      "Group": "Power flow",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "result",
        "flag",
        "output"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Solver",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Solver, [\"newton\",\"gradient\",\"levenberg-marquardt\",\"fsolve\",\"dynamic\"])"
          ],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"Solver\")",
          "Required": false,
          "Unit": "",
          "Description": "Algorithm (see SolverPF)."
        },
        {
          "Name": "Tolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"Tolerance\")",
          "Required": false,
          "Unit": "pu",
          "Description": "Largest P/Q mismatch of a converged solution."
        },
        {
          "Name": "MaxIteration",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeIntegerOrNaN"
          ],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"MaxIteration\")",
          "Required": false,
          "Unit": "",
          "Description": "Maximum number of iterations; NaN for the automatic value."
        },
        {
          "Name": "Verbose",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"Verbose\")",
          "Required": false,
          "Unit": "",
          "Description": "Print the progress of each iteration."
        },
        {
          "Name": "WarmStart",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"WarmStart\")",
          "Required": false,
          "Unit": "",
          "Description": "Start from the last converged solution of this network."
        },
        {
          "Name": "PlotFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "tools.check_plotfcn(opt.PlotFcn, \"calculate_powerflow\", \"residual\")"
          ],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"PlotFcn\")",
          "Required": false,
          "Unit": "",
          "Description": "Live display during the calculation: \"residual\", a function handle or \"none\"."
        },
        {
          "Name": "Progress",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeProgress"
          ],
          "Default": "GUILDA.config(\"PowerFlowCalculation\", \"Progress\")",
          "Required": false,
          "Unit": "",
          "Description": "\"dialog\", \"disp\" or \"none\" (true: \"dialog\", false: \"none\")."
        },
        {
          "Name": "Format",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Format, [\"V\",\"powerflow(mat)\",\"powerflow(tab)\",\"GUILDAorigin\"])"
          ],
          "Default": "\"GUILDAorigin\"",
          "Required": false,
          "Unit": "",
          "Description": "Form of the first output."
        }
      ],
      "Outputs": [
        {
          "Name": "result",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Solution in the form of Format: a ResultPF (default), bus voltages, or an n-by-4 matrix or table of V, I, P, Q."
        },
        {
          "Name": "flag",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "1 converged, 0 MaxIteration reached, -1 stopped by PlotFcn, -2 diverged or no solution (see SolverPF)."
        },
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Solver details; output.message describes the outcome."
        }
      ],
      "Signature": "[result, flag, output] = calculate_powerflow(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/calculate_powerflow.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:PowerflowNotConverged"
      ],
      "Summary": "Calculate the power flow of the network.",
      "Desc": "Calculates the power flow of the network and returns the solution in the form that\nFormat chooses (default: a ResultPF). The settings are the\nPowerFlowCalculation section of GUILDA.setting; Name-Value options override them for\nthis call only (the settings file is not changed). The network assembles the data of\nthe calculation with net.get_pf_condition (the power flow conditions of the buses and the\nadmittance matrix) and net.solver_PF solves it; the solver keeps the last converged\nsolution for the next warm start. The network is not changed. A network without buses\nstops with GUILDA:PowerNetwork:NoBus, and a network without a slack bus (set one with\nbus.l_isSlack = true) with GUILDA:PowerNetwork:NoSlackBus. A calculation that does not converge gives the\nwarning GUILDA:PowerNetwork:PowerflowNotConverged (WhenFailed of GUILDA.setting:\n\"WARN\", \"ERROR\", \"DISP\" or \"NONE\"). Options not listed below stop with the MATLAB\nerror of an unknown name. The options of the call go to net.solver_PF as they are, and\nres.options holds them; the settings without an option (WhenFailed and the settings\n<Solver><option> such as NewtonStepSize) are read from GUILDA.setting where they are used.\n\nName-Value options:\n\n- `Format` — Form of the first output (flag and output stay the 2nd and 3rd outputs). Default: \"GUILDAorigin\".\n  - \"V\": complex bus voltages [pu], a column in net.a_Bus order.\n  - \"powerflow(mat)\": n-by-4 complex double, one row per bus (net.a_Bus order); columns V, I (complex phasors of the voltage and the current injection), P, Q (real injections into the network) [pu].\n  - \"powerflow(tab)\": the same as a table with the variables V, I, P, Q; row names = bus tags.\n  - \"GUILDAorigin\": a ResultPF (bus table, branch flows, violated operating limits, iteration history, plot_voltage, the disp_* methods and export).\n  The other values build no ResultPF (nor the network snapshot it holds).\n- `Solver` — Algorithm: \"newton\", \"gradient\", \"levenberg-marquardt\", \"fsolve\" or \"dynamic\" (see SolverPF). Default: GUILDA.setting.\n- `Tolerance` — [pu] Largest P/Q mismatch of a converged solution, for every method. Default: GUILDA.setting (1e-8).\n- `MaxIteration` — Maximum number of iterations; NaN for the automatic value of the method (see SolverPF). Default: GUILDA.setting (NaN).\n- `Verbose` — Print the progress of each iteration. Default: GUILDA.setting (false).\n- `WarmStart` — true starts from the last converged solution kept by net.solver_PF when it was solved for the same bus tags; false from the flat start (see SolverPF). A run from the kept solution that ends with flag 0 or -2 is solved once more from the flat start; flag, output and the history are those of that run, and output.message says so (Verbose=true also prints one line). Default: GUILDA.setting (true).\n- `Progress` — Progress display: \"dialog\" (a dialog that opens when the calculation lasts 0.5 s or longer, showing the iteration; inside the GUILDA app a dialog of the app window), \"disp\" (one line per iteration in the Command Window) or \"none\"; true is \"dialog\" and false \"none\". Default: GUILDA.setting (\"dialog\").\n- `PlotFcn` — Live display during the calculation (every Solver): \"residual\" draws one bar per power equation (two per bus) with its |residual|, updated during the iterations; a function handle is called at every iterate as stop = f(x, optimValues, state) (x the complex bus voltages; optimValues.iteration, .fval = residuals, .residual = the largest, .time = virtual time for \"dynamic\"; state \"init\", \"iter\", \"done\"), and a true stop ends the calculation with flag -1; \"none\" draws nothing. The figure after the calculation: result.plot_voltage(). Default: GUILDA.setting (\"none\").",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\n[res, flag] = net.calculate_powerflow();                    % ResultPF\nres.tab_bus            % Varg, V, P, Q, Vphasor, Iphasor of each bus\nres.tab_branch         % flows and losses of each branch\nres.plot_voltage();            % voltage profile\nres.export(\"pf.csv\");  % bus table to a file\nV   = net.calculate_powerflow(Format=\"V\", Solver=\"dynamic\");   % complex bus voltages\ntab = net.calculate_powerflow(Format=\"powerflow(tab)\");      % V, I, P, Q of each bus\n```\n\nSee also ResultPF, SolverPF, PowerNetwork.initialize",
      "Deprecated": ""
    },
    {
      "Name": "get_opf_condition",
      "Defining": "PowerNetwork",
      "Group": "OPF",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "varargout"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Display",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Print the tables."
        }
      ],
      "Outputs": [
        {
          "Name": "varargout",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "sct_OPFcondition: struct with the tables Bus, Component and Branch."
        }
      ],
      "Signature": "varargout = get_opf_condition(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/get_opf_condition.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the optimal-power-flow condition of the network: the data the OPF runs with.",
      "Desc": "Stacks Bus.get_opf_condition of every bus (in the order of a_Bus, the components bus by\nbus) and Branch.get_opf_condition of every branch (in the order of a_Branch). These are\nthe tables net.calculate_optimal_powerflow and net.build_opf_problem pass to\nnet.solver_OPF; row names are the tags.\n\n- Bus: Vmin, Vmax, Gshunt, Bshunt, Type, V, Varg.\n- Component: Bus, HP, fP, HQ, fQ, c, P0, Q0, Pmin, Pmax, Qmin, Qmax (a load with infinite\n  bounds is fixed to its powerflow P, Q).\n- Branch: From, To, Y (2x2 admittance matrix per row), X, tap, phase, Pmax, Qmax,\n  Vargmax, Imax, Smax.\n\nWith Display=true (default) the three tables are printed under the headings \"Bus\",\n\"Component\" and \"Branch\", the Branch table without the column Y (the returned table\nkeeps it); with no output nothing is returned.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.get_opf_condition();                               % print the three tables\nsct = net.get_opf_condition(Display=false);\nsct.Component(\"B002SG1\", [\"Pmin\",\"Pmax\"])              % bounds of one generator\n```\n\nSee also Bus.get_opf_condition, Branch.get_opf_condition, PowerNetwork.calculate_optimal_powerflow",
      "Deprecated": ""
    },
    {
      "Name": "build_opf_problem",
      "Defining": "PowerNetwork",
      "Group": "OPF",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "varargout"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Method",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Method, [\"ELD\",\"DC OPF\",\"AC OPF\"])"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"Method\")",
          "Required": false,
          "Unit": "",
          "Description": "Formulation."
        },
        {
          "Name": "Cost",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeHandleOrEmpty"
          ],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "User cost @(v, p) added to the objective; [] for none."
        },
        {
          "Name": "Constraint",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeHandleOrEmpty"
          ],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "User constraints @(v, p) returning struct(name, constraint, ...); [] for none."
        },
        {
          "Name": "DefaultCost",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Add the cost of tab_parameter.OPF of every component."
        },
        {
          "Name": "ReferenceBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"auto\"",
          "Required": false,
          "Unit": "",
          "Description": "Bus with a fixed angle: \"auto\", a bus tag or \"none\"."
        },
        {
          "Name": "validate",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Check that x0 fits the problem."
        }
      ],
      "Outputs": [
        {
          "Name": "varargout",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "prob (the optimproblem), x0 (the initial point as a struct of the variables), then sct_data (the data of the problem: Bus, Component, Branch, base, ReferenceBus)."
        }
      ],
      "Signature": "varargout = build_opf_problem(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/build_opf_problem.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Build the optimization problem of the optimal power flow without solving it.",
      "Desc": "Builds the problem that `net.calculate_optimal_powerflow` solves, so that it can be\ninspected or modified before solving it with\nnet.calculate_optimal_powerflow(Problem=prob, InitialPoint=x0). It is the first step of\ncalculate_optimal_powerflow: the data of the problem are collected here (the tables of\nnet.get_opf_condition, the base and the reference bus, \"auto\" resolved) and\nnet.solver_OPF builds the problem from them (SolverOPF.build_problem). Method defaults\nto the OptimalPowerFlow section of GUILDA.setting; the other options are options of the\ncall only. Options not listed below stop with the MATLAB error of an unknown name.\nWith no output the problem is displayed.\nConstraint names: balancedP_<bus>, balancedQ_<bus> (balancedP in \"ELD\"), VargRef,\nVargMax1_<branch>, VargMax2_<branch>, and at each branch end <branch>_<bus>: Pmax_ and,\nin \"AC OPF\", Qmax_, Imax_, Smax_ (each only when the limit is finite), plus the names\nof Constraint.\nVariables are named by the tags of the buses (Varg, V) and components (P, Q); the\nbranches have none (their flows are expressions of the bus voltages). The initial point\nx0 is the flat start (see SolverOPF).\nThe third output sct_data holds the data the problem was built from:\n\n- `Bus`, `Component`, `Branch` — Tables of net.get_opf_condition (row names = tags).\n- `base` — Base of the network (baseMVA, Hz; p.base of Cost and Constraint).\n- `ReferenceBus` — Bus with a fixed angle: the bus tag (\"auto\" resolved: the slack bus if one is set, else the first bus) or \"none\".\n\nName-Value options:\n\n- `Method` — \"ELD\", \"DC OPF\" or \"AC OPF\". Default: GUILDA.setting (\"AC OPF\").\n- `Cost` — Function handle @(v, p) returning a scalar added to the objective; [] = none. Default: [].\n- `Constraint` — Function handle @(v, p) returning struct(name1, constraint1, ...) added to the problem; [] = none. Default: [].\n- `DefaultCost` — false leaves out the costs of tab_parameter.OPF. Default: true.\n- `ReferenceBus` — Bus with a fixed angle: \"auto\", a bus tag or \"none\". Default: \"auto\".\n- `validate` — Check that the initial point x0 fits the problem. Default: false.",
      "SeeAlso": [],
      "Examples": "```matlab\nprob = net.build_opf_problem(Method=\"DC OPF\");\n[prob, x0] = net.build_opf_problem(Method=\"AC OPF\", validate=true);\n[~, ~, sct_data] = net.build_opf_problem();        % sct_data.ReferenceBus: the bus with a fixed angle\n% Add a constraint and solve the modified problem\n[prob, x0] = net.build_opf_problem(Method=\"DC OPF\");\nprob.Constraints.Cap = prob.Variables.B001SG1 <= 0.4;\nres = net.calculate_optimal_powerflow(Method=\"DC OPF\", Problem=prob, InitialPoint=x0);\n```\n\nSee also PowerNetwork.calculate_optimal_powerflow, SolverOPF.build_problem",
      "Deprecated": ""
    },
    {
      "Name": "calculate_optimal_powerflow",
      "Defining": "PowerNetwork",
      "Group": "OPF",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "result",
        "flag",
        "output"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Method",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Method, [\"ELD\",\"DC OPF\",\"AC OPF\"])"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"Method\")",
          "Required": false,
          "Unit": "",
          "Description": "Formulation."
        },
        {
          "Name": "Solver",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Solver, [\"auto\",\"linprog\",\"quadprog\",\"fmincon\"])"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"Solver\")",
          "Required": false,
          "Unit": "",
          "Description": "Optimization solver."
        },
        {
          "Name": "Tolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositiveOrNaN"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"Tolerance\")",
          "Required": false,
          "Unit": "",
          "Description": "OptimalityTolerance of the solver; NaN for its default."
        },
        {
          "Name": "MaxIteration",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositiveIntegerOrNaN"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"MaxIteration\")",
          "Required": false,
          "Unit": "",
          "Description": "MaxIterations of the solver; NaN for its default."
        },
        {
          "Name": "Verbose",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"Verbose\")",
          "Required": false,
          "Unit": "",
          "Description": "Print the progress of the solver."
        },
        {
          "Name": "WarmStart",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"WarmStart\")",
          "Required": false,
          "Unit": "",
          "Description": "Start \"AC OPF\" from the last solved \"AC OPF\" of this network."
        },
        {
          "Name": "PlotFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"PlotFcn\")",
          "Required": false,
          "Unit": "",
          "Description": "Live display during the calculation (fmincon only; checked by tools.check_plotfcn)."
        },
        {
          "Name": "Progress",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeProgress"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"Progress\")",
          "Required": false,
          "Unit": "",
          "Description": "\"dialog\", \"disp\" or \"none\" (true: \"dialog\", false: \"none\")."
        },
        {
          "Name": "Cost",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeHandleOrEmpty"
          ],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "User cost @(v, p) added to the objective; [] for none."
        },
        {
          "Name": "Constraint",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeHandleOrEmpty"
          ],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "User constraints @(v, p) returning struct(name, constraint, ...); [] for none."
        },
        {
          "Name": "DefaultCost",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Add the cost of tab_parameter.OPF of every component."
        },
        {
          "Name": "ReferenceBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"auto\"",
          "Required": false,
          "Unit": "",
          "Description": "Bus with a fixed angle: \"auto\", a bus tag or \"none\"."
        },
        {
          "Name": "Problem",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "optim.problemdef.OptimizationProblem",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Problem to solve instead of building one. Default: the problem built from the network (build_opf_problem)."
        },
        {
          "Name": "InitialPoint",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Initial point by variable name. Default: the x0 of build_opf_problem."
        },
        {
          "Name": "MinDampingRatio",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeDampingRatioOrNaN"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"MinDampingRatio\")",
          "Required": false,
          "Unit": "",
          "Description": "Lower limit of the damping ratio of the oscillatory modes; NaN for none."
        },
        {
          "Name": "MaxRealPart",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeFiniteOrNaN"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"MaxRealPart\")",
          "Required": false,
          "Unit": "1/s",
          "Description": "Upper limit of the real part of the nonzero eigenvalues; NaN for none."
        },
        {
          "Name": "StabilityMaxIteration",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"StabilityMaxIteration\")",
          "Required": false,
          "Unit": "",
          "Description": "Largest number of outer iterations."
        },
        {
          "Name": "StabilityStep",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"StabilityStep\")",
          "Required": false,
          "Unit": "pu",
          "Description": "Initial trust region [dP dV]; Inf for none."
        },
        {
          "Name": "StabilityMargin",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [
            "mustBeNonnegative",
            "mustBeFinite"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"StabilityMargin\")",
          "Required": false,
          "Unit": "",
          "Description": "Margin [damping ratio, real part] of the linearized constraints."
        },
        {
          "Name": "StabilityBand",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [
            "mustBeNonnegative",
            "mustBeFinite"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"StabilityBand\")",
          "Required": false,
          "Unit": "",
          "Description": "Band [damping ratio, real part] of the critical modes."
        }
      ],
      "Outputs": [
        {
          "Name": "result",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Bus values, connection injections, branch flows, cost and Lagrange multipliers (ResultOPF)."
        },
        {
          "Name": "flag",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "exitflag of solve (positive = solved)."
        },
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Solver details; output.message describes the outcome."
        }
      ],
      "Signature": "[result, flag, output] = calculate_optimal_powerflow(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/calculate_optimal_powerflow.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:StabilityNeedsACOPF",
        "GUILDA:PowerNetwork:StabilityPointFailed"
      ],
      "Summary": "Calculate the optimal power flow of the network and return a ResultOPF.",
      "Desc": "Calculates the optimal power flow of the network: the operating point that minimizes\nthe generation cost (tab_parameter.OPF of the components) under the constraints in\ntab_parameter.operation of the buses, components and branches. The settings are the\nOptimalPowerFlow section of GUILDA.setting; Name-Value options override them for this\ncall only (the settings file is not changed). Cost, Constraint, DefaultCost and\nReferenceBus are options of the call only. The network is not changed.\nThe cost of each component is HP*P^2 + fP*P + HQ*Q^2 + fQ*Q + c (tab_parameter.OPF; Q\nterms in \"AC OPF\" only; the constant c adds to the cost without changing the solution); the default cost of a load is 0. A load keeps the P and Q of\ntab_parameter.powerflow while its Pmin/Pmax (Qmin/Qmax) are infinite; with finite\nbounds it is dispatched within them. A default limit of one object is removed by setting\nit to Inf (-Inf for a lower bound) in its tab_parameter.operation: Vmin, Vmax (bus);\nPmin, Pmax, Qmin, Qmax (component); Pmax, Qmax, Vargmax, Imax, Smax (branch, where NaN\nalso means none). User costs and constraints over the whole network are the options\nCost and Constraint; a problem from net.build_opf_problem, modified by the user, is\nsolved with Problem. The columns startup and shutdown of tab_parameter.OPF\nare reserved: unit commitment is not part of the problem. The variables are V and Varg of\nthe buses and P and Q of the components: the power balance of each bus and the branch\nlimits are written with the branch flows as expressions of V and Varg. \"DC OPF\" uses |V| = 1 and\nthe MATPOWER branch susceptance b = 1/(X*tap) (tap ratio and phase shift at the from\nend). The angle of the ReferenceBus is fixed to its tab_parameter.powerflow Varg;\nl_isSlack is not set. The solver starts from the bus voltages of the last solved\n\"AC OPF\" of the network (WarmStart) or of the flat start (see SolverOPF), and P0, Q0 of\nthe components; branch current and power limits are applied as |I|^2 <= Imax^2 and\nP^2 + Q^2 <= Smax^2 at both ends. Options not listed below stop with the MATLAB error\nof an unknown name. The result is written to a file with result.export.\nThe calculation runs three stages: net.build_opf_problem builds the problem (it collects\nthe tables of net.get_opf_condition, the base and the reference bus, and\nnet.solver_OPF builds the problem from these data only); net.solver_OPF.solve solves\nthe built problem, or the given Problem, without building it again; the ResultOPF is\nbuilt from a snapshot of the network (struct(net, false)) and the solution. res.options holds the Name-Value options\nof the run (Problem and InitialPoint excepted), with ReferenceBus as the bus tag (\"auto\"\nresolved) and base (baseMVA, Hz); the settings without an option (the algorithm and\nthe step tolerances of each solver, <Solver><option>) are read by SolverOPF from\nGUILDA.setting.\n\nStability-constrained OPF (\"AC OPF\" only; MinDampingRatio or MaxRealPart not NaN): the\nsmall-signal limits of the dynamic model of the same network are added. Each outer\niteration solves the OPF, builds the point of get_sys at its solution without writing the\nnetwork (a power flow of the set points of the solution, then get_equilibrium of the\ncomponents and controllers, which return values), and takes the eigenvalues of\nget_sys(point, Type=\"ODE\"): the damping ratio of the oscillatory modes and the real part\nof the nonzero eigenvalues (the zero eigenvalues, e.g. the reference angle, are left out).\nWhen a limit is not met, the modes within StabilityBand of it get constraints linearized at\nthe solution in the set points u (P of the generators whose P bounds differ, except at the\nslack bus of the power flow; V of the generator buses), by forward differences of u; they\nask for the limit with StabilityMargin, replace those of the previous iteration, have a\nslack with a penalty in the objective (so that the OPF goes as far as it can when the\nlimits cannot be met at once; the penalty is not in result.r_cost), and come with a trust\nregion |u - u_k| <= StabilityStep, halved when the violation grows. The network must be\ninitialized (get_sys stops with GUILDA:PowerSystemModel:Stale otherwise) and is not\nchanged. It ends when the limits hold (the flag of the last OPF), or with flag 0 after\nStabilityMaxIteration outer iterations or when the trust region has shrunk to 1/64. When\nthe OPF of an outer iteration after the first stops without a solution (flag <= 0, e.g.\nthe MaxIteration of fmincon), its last iterate is not returned (it may break the power\nbalance and cost less than the optimum): the result is the solution of the previous outer\niteration, the flag is 0, tab_iteration ends with a row of the stopped OPF (Cost and the\nlimits NaN, Flag its exit flag), and the warning GUILDA:PowerNetwork:StabilityOPFFailed\ntells it; when the first OPF stops, the result is that of the plain OPF. INFO\nmessages (GUILDA.setting Message.ShowInfo) tell when the number of zero eigenvalues differs\nfrom the number of islands (GUILDA:PowerNetwork:StabilityZeroEigenvalues, e.g. a frequency\nmode without damping) and when modes cannot be followed at the points of the differences\nand get no constraint in that iteration (GUILDA:PowerNetwork:StabilityModeNotTracked).\nresult.sct_stability holds the outer iterations and the modes of the last solution;\nGUILDA:PowerNetwork:StabilityNeedsACOPF stops \"DC OPF\" and \"ELD\", and\nGUILDA:PowerNetwork:StabilityPointFailed a point that cannot be built (the power flow of\nthe set points, or a get_equilibrium that stops, e.g. at a limit of a controller).\n\nName-Value options:\n\n- `Method` — Formulation: \"ELD\" (economic load dispatch, branches ignored), \"DC OPF\" (DC approximation) or \"AC OPF\" (AC power flow equations). Default: GUILDA.setting (\"AC OPF\").\n- `Solver` — Optimization solver; \"auto\" lets solve choose. Default: GUILDA.setting (\"auto\").\n- `Tolerance` — OptimalityTolerance of the solver; NaN = solver default. Default: GUILDA.setting (NaN).\n- `MaxIteration` — MaxIterations of the solver; NaN = solver default. Default: GUILDA.setting (NaN).\n- `Verbose` — Print the progress of the solver (Display \"iter\"; false: \"none\"). Default: GUILDA.setting (false).\n- `Progress` — Progress display: \"dialog\" (a dialog that opens when the calculation lasts 0.5 s or longer, showing the solver and, for fmincon, the iteration, the cost and the constraint violation; the outer iteration of the stability-constrained OPF; inside the GUILDA app a dialog of the app window), \"disp\" (one line per step in the Command Window) or \"none\"; true is \"dialog\" and false \"none\". Default: GUILDA.setting (\"dialog\").\n- `Cost` — Function handle @(v, p) returning a scalar added to the objective; [] = none. v holds the variables by tag: v.Component.(tag).P/.Q, v.Bus.(tag).Varg/.V, v.Branch.(tag).Pfrom/.Pto/...; p holds p.Method and p.base (see SolverOPF). Default: [].\n- `Constraint` — Function handle @(v, p) returning struct(name1, constraint1, ...); field <name> becomes prob.Constraints.<name> and result.lambda.Constraints.<name>; [] = none. Default: [].\n- `DefaultCost` — false leaves out the costs HP, fP, HQ, fQ, c of tab_parameter.OPF of all components. Default: true.\n- `ReferenceBus` — Bus with a fixed angle: \"auto\" (the slack bus if one is set, else the first bus; the OPF needs no slack bus), a bus tag, or \"none\". Default: \"auto\".\n- `Problem` — optimproblem to solve instead of building one, e.g. from net.build_opf_problem with the same Method, modified by the user; Cost, Constraint, DefaultCost and ReferenceBus are not applied to it. Default: none.\n- `InitialPoint` — Initial point (struct of values by variable name). Default: the x0 of net.build_opf_problem for the same Method; give it when Problem has added variables.\n- `WarmStart` — true starts \"AC OPF\" from the bus voltages of the last solved \"AC OPF\" of this network (kept by net.solver_OPF); false from the flat start (see SolverOPF). Default: GUILDA.setting (false).\n- `MinDampingRatio` — Lower limit of the damping ratio of the oscillatory modes at the solution (stability-constrained OPF); NaN = none. Default: GUILDA.setting (NaN).\n- `MaxRealPart` — [1/s] Upper limit of the real part of the nonzero eigenvalues at the solution; NaN = none. Default: GUILDA.setting (NaN).\n- `StabilityMaxIteration` — Largest number of outer iterations. Default: GUILDA.setting (10).\n- `StabilityStep` — [pu] Initial trust region [dP dV] of the set points; Inf = none for that kind. Default: GUILDA.setting ([0.1 0.02]).\n- `StabilityMargin` — Margin [damping ratio, real part 1/s] that the linearized constraints keep from the limits. Default: GUILDA.setting ([0.005 0.005]).\n- `StabilityBand` — Width [damping ratio, real part 1/s] of the band near a limit whose modes get constraints. Default: GUILDA.setting ([0.02 0.05]).\n- `PlotFcn` — Live display during the calculation, fmincon only (\"AC OPF\"): keys of the plot functions of fmincon, key k for optimplot<k> (\"fval\", \"constrviolation\", \"fvalconstr\", \"firstorderopt\", \"stepsize\", \"funccount\", \"x\"), or a function handle stop = f(x, optimValues, state) passed to fmincon as it is; \"none\" draws nothing. With linprog or quadprog (\"ELD\", \"DC OPF\") a value other than \"none\" stops with GUILDA:SolverOPF:PlotFcnUnsupported. The figure after the calculation: result.plot_dispatch(). Default: GUILDA.setting (\"none\").",
      "SeeAlso": [],
      "Examples": "```matlab\n[res, flag] = net.calculate_optimal_powerflow();            % AC OPF (GUILDA.setting)\nres.tab_bus                                         % Varg, V, P, Q, Vphasor, Iphasor of each bus\nres.r_cost                                          % optimal cost\nres = net.calculate_optimal_powerflow(Method=\"ELD\", Verbose=false);\nres.plot_dispatch();\nres.export(\"opf.csv\");                              % bus table to a file\n% Spinning reserve of two generators; its price is the dual of the named constraint\nres = net.calculate_optimal_powerflow(Method=\"DC OPF\", Constraint=@(v, p) struct(\"Reserve\", ...\n          (2 - v.Component.B001SG1.P) + (2 - v.Component.B002SG1.P) >= 0.5));\nres.lambda.Constraints.Reserve\n% Solve a modified problem\n[prob, x0] = net.build_opf_problem(Method=\"DC OPF\");\nprob.Constraints.Cap = prob.Variables.B001SG1 <= 0.4;\nres = net.calculate_optimal_powerflow(Method=\"DC OPF\", Problem=prob, InitialPoint=x0);\n% Stability-constrained OPF: the smallest damping ratio at the solution at least 0.048\nnet = network.IEEE14bus();\n[res, flag] = net.calculate_optimal_powerflow(Method=\"AC OPF\", MinDampingRatio=0.048);\nres.sct_stability.tab_iteration         % cost, damping ratio and real part of each outer iteration\nres.sct_stability.tab_mode              % modes of the solution\n```\n\nSee also ResultOPF, SolverOPF, PowerNetwork.build_opf_problem",
      "Deprecated": ""
    },
    {
      "Name": "reset_solver",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        }
      ],
      "Outputs": [],
      "Signature": "reset_solver(obj)",
      "File": "_GUILDAsystem/@PowerNetwork/reset_solver.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Restore the default analysis solvers of the network.",
      "Desc": "Replaces solver_PF, solver_OPF, solver_CPF, solver_ODE and solver_LIN with new\nsolver objects, which discards the stored defaults changed on them.",
      "SeeAlso": [
        "SolverPF",
        "SolverOPF",
        "SolverCPF",
        "SolverODE",
        "SolverLIN"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "initialize",
      "Defining": "PowerNetwork",
      "Group": "Initialize",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "rm_pf",
        "flag",
        "output"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Method",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Method, [\"powerflow\",\"OPF\",\"FixedInput\",\"equilibrium\"])"
          ],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "How the operating point is obtained. Default: \"powerflow\"."
        },
        {
          "Name": "Solver",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Algorithm of the analysis. Default: the Solver of the analysis that Method runs (GUILDA.setting)."
        },
        {
          "Name": "Tolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Convergence tolerance. Default: the Tolerance of the analysis that Method runs (GUILDA.setting)."
        },
        {
          "Name": "MaxIteration",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Maximum number of iterations; NaN for the automatic value. Default: the MaxIteration of the analysis that Method runs (GUILDA.setting)."
        },
        {
          "Name": "Verbose",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Print the progress. Default: the Verbose of the analysis that Method runs (GUILDA.setting)."
        },
        {
          "Name": "WarmStart",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Start from the last solution of this network. Default: the WarmStart of the analysis that Method runs (GUILDA.setting)."
        },
        {
          "Name": "PlotFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Live display during the calculation (Method=\"powerflow\" or \"OPF\"). Default: the PlotFcn of the analysis that Method runs (GUILDA.setting)."
        },
        {
          "Name": "Progress",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Progress display (Method=\"powerflow\", \"OPF\" or \"FixedInput\"). Default: \"none\" (initialize)."
        },
        {
          "Name": "Cost",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "User cost @(v, p) added to the objective (Method=\"OPF\"). Default: [] (calculate_optimal_powerflow)."
        },
        {
          "Name": "Constraint",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "User constraints @(v, p) (Method=\"OPF\"). Default: [] (calculate_optimal_powerflow)."
        },
        {
          "Name": "DefaultCost",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Add the cost of tab_parameter.OPF of every component (Method=\"OPF\"). Default: true (calculate_optimal_powerflow)."
        },
        {
          "Name": "ReferenceBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Bus with a fixed angle: \"auto\", a bus tag or \"none\" (Method=\"OPF\"). Default: \"auto\" (calculate_optimal_powerflow)."
        },
        {
          "Name": "Problem",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Problem to solve instead of building one (Method=\"OPF\"). Default: built by calculate_optimal_powerflow."
        },
        {
          "Name": "InitialPoint",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Initial point by variable name (Method=\"OPF\"). Default: chosen by calculate_optimal_powerflow."
        },
        {
          "Name": "MinDampingRatio",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Lower limit of the damping ratio of the oscillatory modes; NaN for none (Method=\"OPF\"). Default: GUILDA.setting (OptimalPowerFlow)."
        },
        {
          "Name": "MaxRealPart",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "1/s",
          "Description": "Upper limit of the real part of the nonzero eigenvalues; NaN for none (Method=\"OPF\"). Default: GUILDA.setting (OptimalPowerFlow)."
        },
        {
          "Name": "StabilityMaxIteration",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Largest number of outer iterations (Method=\"OPF\"). Default: GUILDA.setting (OptimalPowerFlow)."
        },
        {
          "Name": "StabilityStep",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Initial trust region [dP dV]; Inf for none (Method=\"OPF\"). Default: GUILDA.setting (OptimalPowerFlow)."
        },
        {
          "Name": "StabilityMargin",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Margin [damping ratio, real part] of the linearized constraints (Method=\"OPF\"). Default: GUILDA.setting (OptimalPowerFlow)."
        },
        {
          "Name": "StabilityBand",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Band [damping ratio, real part] of the critical modes (Method=\"OPF\"). Default: GUILDA.setting (OptimalPowerFlow)."
        }
      ],
      "Outputs": [
        {
          "Name": "rm_pf",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Operating point: n-by-4 complex double, one row per bus (net.a_Bus order); columns V, I (complex phasors), P, Q (real injections into the network)."
        },
        {
          "Name": "flag",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Success flag of the analysis (positive; a failure stops with an error)."
        },
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Details of the analysis; output.message describes the outcome."
        }
      ],
      "Signature": "[rm_pf, flag, output] = initialize(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/initialize.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:InputEdited",
        "GUILDA:PowerNetwork:InitializeFixedInputIsland",
        "GUILDA:PowerNetwork:InitializeFixedInputFailed",
        "GUILDA:PowerNetwork:InitializeEquilibriumOption",
        "GUILDA:PowerNetwork:InitializeEquilibriumEdited",
        "GUILDA:PowerNetwork:InitializeNotEquilibrium",
        "GUILDA:PowerNetwork:InitializeNoEquilibrium",
        "GUILDA:PowerNetwork:InitializeEquilibriumFailed",
        "GUILDA:PowerNetwork:InputDrivenTwice",
        "GUILDA:PowerNetwork:InitializeEquilibriumSize",
        "GUILDA:PowerNetwork:InitializeModelFailed",
        "GUILDA:PowerNetwork:InitializeModelSize"
      ],
      "Summary": "Bring every layer of the network up to date: the power flow, the equilibria and the function handles.",
      "Desc": "Only initialize brings the layers up to date (LayerPackage `sct_stale`); the analyses\nthat need the equilibrium (simulate, get_sys, the continuation power flow)\nonly check them. It is one of the few analysis methods that change the model. Steps:\n\n1. The operating point is solved when Method is given (\"powerflow\", \"OPF\" or\n   \"FixedInput\"; always\n   solved then) or when the power flow of the network is stale (net.sct_stale.powerflow:\n   edits of baseMVA, the topology, bus and branch parameters, the slack bus or the\n   powerflow parameters of the components; also before the first initialize). It is\n   written with Bus.set_equilibrium, which sets the equilibria of the components and\n   their local controllers.\n2. Every bus initializes its components: stale handles are rebuilt, and an equilibrium\n   that is still stale (an edit of dynamics or of the local controllers) is recomputed\n   from the held V and I. Then each global controller rebuilds its stale handles and\n   computes its equilibrium.\n\nEach layer decides from its own stale tags, so a dynamics-only edit does not solve the\npower flow again, and a Hz edit (net.sct_stale.odefcn) only rebuilds the handles. With\nnothing stale, initialize changes nothing but the equilibria of the global controllers,\nwhich are always recomputed. The stale tags of the network are cleared at the end.\n\nInputs edited with Component.set_input (net.sct_stale.input) are kept only by\nMethod=\"FixedInput\". Without Method, or with Method=\"equilibrium\", initialize stops with\nGUILDA:PowerNetwork:InputEdited; Method=\"powerflow\" or \"OPF\" replaces them with the\nvalues of the solution (INFO GUILDA:PowerNetwork:InputOverwritten).\n\nThe first output is the operating point that was set, for every Method: an n-by-4 complex\ndouble with one row per bus (net.a_Bus order) and the columns V, I (complex phasors of\nthe voltage and the current injection), P, Q (real injections into the network) [pu]\n(for \"OPF\", those of the AC OPF solution). It is the array initialize writes with\nBus.set_equilibrium, so it costs nothing extra. Without a solve it is the held\nequilibrium. For a result object, call net.calculate_powerflow or\nnet.calculate_optimal_powerflow.\n\nName-Value options (listed in the arguments block):\n\n- `Method` — How the operating point is obtained when it is solved. Default:\n  \"powerflow\".\n  - \"powerflow\": net.calculate_powerflow (settings of GUILDA.setting).\n  - \"OPF\": net.calculate_optimal_powerflow with Method=\"AC OPF\" (OptimalPowerFlow section of GUILDA.setting;\n    the AC formulation gives a complete AC operating point).\n  - \"FixedInput\": net.calculate_fixed_input_powerflow, the equilibrium with the inputs\n    of the components held (rv_Uequilibrium, edited with Component.set_input): the\n    states, the bus voltages, the currents and the Pmech of the first generator of the\n    slack bus are solved (the slack bus angle is 0; its V and Varg settings and the\n    powerflow settings of the components are not used). The controllers are not in the\n    equations: they take their equilibria afterwards. Always solved. Every component\n    must hold its inputs (GUILDA:PowerNetwork:InitializeInputNotSet), the slack bus\n    needs a generator, and a network split into islands stops.\n  - \"equilibrium\": never solved; the equilibria the components already hold (from an\n    earlier initialize) are kept, and buses without components get the voltage of\n    Y*V = I. A stale power flow stops with an error: use net.initialize(). It takes no\n    other option (GUILDA:PowerNetwork:InitializeEquilibriumOption).\n- The other options are those of calculate_powerflow (\"powerflow\"),\n  calculate_optimal_powerflow (\"OPF\", except its Method, always \"AC OPF\") and\n  calculate_fixed_input_powerflow (\"FixedInput\"), without Format. Only the given ones\n  are passed, so that analysis applies its defaults (GUILDA.setting) and validates the\n  values; an option it does not take stops with its error (e.g. Cost with\n  Method=\"powerflow\"). `Solver` chooses the algorithm of that analysis, e.g.\n  Solver=\"levenberg-marquardt\" for the power flow or Solver=\"fmincon\" for the OPF;\n  `WarmStart` starts from the last solution of the network (net.solver_PF or\n  net.solver_OPF). Format is not an option: the first output is always the n-by-4\n  array above.\n- `Progress` — Progress display of the analysis (\"dialog\", \"disp\", \"none\", true or\n  false; see calculate_powerflow). Default: \"none\" (initialize), not the setting of the\n  analysis.\n\nWhen the analysis does not succeed (no convergence, an infeasible OPF, or stored\nequilibria that do not satisfy the network equations), initialize stops with an error\nnaming the remedy, and the network keeps its previous equilibrium and stale state. The\npower flow and Method=\"FixedInput\" need a slack bus set with l_isSlack\n(GUILDA:PowerNetwork:NoSlackBus); initialize never sets one. When a later step fails, or\nthe point does not satisfy Y*V = I, the power flow is left stale, and analyses stop\n(e.g. GUILDA:PowerNetwork:SimulateStale) until initialize succeeds.\n\nA network split into islands is a valid equilibrium when the power of each island\nbalances, so a successful initialize only warns (GUILDA:PowerNetwork:NetworkIsland). A\nfailed power flow or OPF on such a network names the islands in its error.\n\nThe models are evaluated at the point that was set, with every Method. A state or input of the wrong size, a model function that returns the wrong size\nand a model function that stops are errors naming the model, and the power flow is left\nstale. A\nresidual of a component, local controller or global controller of 1e-6 or more only\nwarns (GUILDA:PowerNetwork:EquilibriumResidual), because such a model can still be run:\nits states then move without a disturbance.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();                                % power flow\nnet.a_Bus{1}.a_Component{1}.tab_parameter.dynamics.D = 0.1;\nnet.initialize();                                % only the edited generator\nnet.initialize(Method=\"equilibrium\");            % never solves the power flow\npf  = net.initialize(Method=\"powerflow\");          % n-by-4 V, I, P, Q of the point\nV   = pf(:,1);                                   % complex bus voltages\npf  = net.initialize(Method=\"OPF\", Solver=\"fmincon\");   % V, I, P, Q of the AC OPF point\nres = net.calculate_powerflow();                 % ResultPF of the held network data\n```\n\nSee also PowerNetwork.calculate_powerflow, PowerNetwork.calculate_optimal_powerflow, PowerNetwork.calculate_fixed_input_powerflow, PowerNetwork.simulate",
      "Deprecated": ""
    },
    {
      "Name": "remove_scenario",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sr_tag"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "sr_tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the scenarios to remove."
        }
      ],
      "Outputs": [],
      "Signature": "remove_scenario(obj, sr_tag)",
      "File": "_GUILDAsystem/@PowerNetwork/remove_scenario.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:ScenarioNotFound"
      ],
      "Summary": "Remove simulation scenarios by tag and delete them.",
      "Desc": "A variable that holds a removed scenario becomes an invalid handle (isvalid is false).\nA tag that is not a scenario of the network stops with\nGUILDA:PowerNetwork:ScenarioNotFound and nothing is removed. The equilibrium does not\nbecome stale. To keep a copy, add one first: net.add_scenario(tag, From=sc).",
      "SeeAlso": [],
      "Examples": "```matlab\nnet.remove_scenario(\"case1\")\n```\n\nSee also PowerNetwork.add_scenario, Scenario",
      "Deprecated": ""
    },
    {
      "Name": "add_scenario",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_tag",
        "opt"
      ],
      "OutputNames": [
        "sc"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "s_tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeNonzeroLengthText"
          ],
          "Default": "\"CASE\"",
          "Required": false,
          "Unit": "",
          "Description": "Tag of the new scenario; a number is added when a child of the network has it."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [
            "mustBeSimulationTime"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Simulation time [t0, tend]. Default: From.Time, else [0, 10]."
        },
        {
          "Name": "Description",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Free text. Default: From.Description, else \"\"."
        },
        {
          "Name": "From",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "Scenario",
          "Validators": [
            "mustBeScalarOrEmpty"
          ],
          "Default": "Scenario.empty",
          "Required": false,
          "Unit": "",
          "Description": "Scenario to copy the events, Time and Description from (of this or another network)."
        },
        {
          "Name": "Event",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "cell",
          "Validators": [],
          "Default": "{}",
          "Required": false,
          "Unit": "",
          "Description": "Events to copy into the new scenario (EventFault, EventTrip, EventOpenBranch, EventOffset, EventInput), added after those of From."
        }
      ],
      "Outputs": [
        {
          "Name": "sc",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "Scenario",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The new scenario, a child of the network."
        }
      ],
      "Signature": "sc = add_scenario(obj, s_tag, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/add_scenario.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:NotAnEvent"
      ],
      "Summary": "Create a simulation scenario of the network and return it.",
      "Desc": "The new scenario is a child of the network (net.a_Scenario, sc.a_PowerNetwork). Its tag\n(default \"CASE\") shares the name space of the buses, branches and global controllers: a\ntag in use gets a number suffix (case1 -> case1002, as for the other layers) and the new\ntag is shown as INFO; read it from sc.s_tag. Add the disturbances with the methods of the scenario.\n\nFrom=sc0 copies the events (with their tags), Time and Description of the scenario sc0\n(of this or another network); sc0 does not change. Event={ev1, ev2, ...} copies events\nmade with their constructors (EventFault, EventTrip, EventOpenBranch, EventOffset,\nEventInput) after those of From; faults, trips and openings get new tags, offsets and\ninputs keep theirs. The events passed do not change. All events are checked against this\nnetwork: when a check fails, no scenario is created. To move a scenario, copy it and\nremove the original: `net2.add_scenario(tag, From=sc); net1.remove_scenario(tag)`.\n\nScenarios are not model data: the equilibrium does not become stale and nothing is\nlogged as an edit.",
      "SeeAlso": [],
      "Examples": "```matlab\nsc = net.add_scenario(\"case1\", Time=[0, 20]);\nsc.add_fault(\"B008\", [0.10, 0.17]);\nsc.add_open_branch(\"EL003\", 0.17);\nresult = net.simulate(\"case1\");\nother.add_scenario(\"case1\", From=sc);     % a copy in another network\nsc3 = net.add_scenario(Time=[0, 5]);      % tag \"CASE\" (with a number when in use)\nsc2 = net.add_scenario(\"case2\", Event={EventFault(\"B008\", [0.1, 0.17]), EventOpenBranch(\"EL003\", 0.17)});\n```\n\nSee also PowerNetwork.remove_scenario, PowerNetwork.simulate, Scenario",
      "Deprecated": ""
    },
    {
      "Name": "remove_global_controller",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sr_GconTag"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "sr_GconTag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the global controllers to remove."
        }
      ],
      "Outputs": [],
      "Signature": "remove_global_controller(obj, sr_GconTag)",
      "File": "_GUILDAsystem/@PowerNetwork/remove_global_controller.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:GconNotFound"
      ],
      "Summary": "Remove global controllers by tag.",
      "Desc": "The removed controllers are deleted, so a handle to them becomes invalid. A removal makes nothing stale:\nit changes no equilibrium, and simulate and get_sys take the controllers the network\nhas.",
      "SeeAlso": [],
      "Examples": "```matlab\nagc = net.add_global_controller(\"agc-PI\", [\"B001SG1\",\"B002SG1\"]);\nnet.remove_global_controller(agc.s_tag)\n```\n\nSee also PowerNetwork.add_global_controller",
      "Deprecated": ""
    },
    {
      "Name": "remove_branch",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "tag"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the branches to remove."
        }
      ],
      "Outputs": [],
      "Signature": "remove_branch(obj, tag)",
      "File": "_GUILDAsystem/@PowerNetwork/remove_branch.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:BranchNotFound"
      ],
      "Summary": "Remove branches by tag.",
      "Desc": "A tag that is not found is an error, and then nothing is removed. The removed branches\nare deleted, so a handle to them becomes invalid.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet.remove_branch(\"EL001\")\nnet.remove_branch([\"EL001\",\"EL002\"])\n```\n\nSee also PowerNetwork.add_branch, PowerNetwork.remove_bus",
      "Deprecated": ""
    },
    {
      "Name": "remove_bus",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sr_BusTag",
        "opt"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "sr_BusTag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the buses to remove."
        },
        {
          "Name": "RemoveBranches",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Also remove the branches connected to the removed buses."
        }
      ],
      "Outputs": [],
      "Signature": "remove_bus(obj, sr_BusTag, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/remove_bus.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:BusNotFound",
        "GUILDA:PowerNetwork:BusHasControlledUnits",
        "GUILDA:PowerNetwork:BusHasBranches"
      ],
      "Summary": "Remove buses by tag, together with their components.",
      "Desc": "A branch connected to a removed bus would be left with a dangling end, so removing\nsuch a bus is an error unless `RemoveBranches` is true, which removes those branches\ntoo. A bus whose components are controlled by a global controller cannot be removed\nuntil that controller is removed. The removed buses are deleted with their components and\nlocal controllers (and the removed branches), so a handle to them becomes invalid.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet.remove_bus(\"B010\")\nnet.remove_bus(\"B003\", RemoveBranches=true)\n```\n\nSee also PowerNetwork.add_bus, PowerNetwork.remove_branch",
      "Deprecated": ""
    },
    {
      "Name": "add_global_controller",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Key",
        "a_Unit",
        "opt"
      ],
      "OutputNames": [
        "con"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Key",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "char",
          "Validators": [
            "tools.mustBeKeyOf(Key, \"GlobalController\")"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Global controller model key, e.g. \"agc-PI\"."
        },
        {
          "Name": "a_Unit",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Controlled components of this network: Component objects (cell array or one object) or tags."
        },
        {
          "Name": "parameter",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeA(opt.parameter, [\"struct\",\"table\"])"
          ],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Constructor parameters (struct or one-row table of Name=Value); omitted ones use the class defaults."
        }
      ],
      "Outputs": [
        {
          "Name": "con",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Added GlobalController object."
        }
      ],
      "Signature": "con = add_global_controller(obj, Key, a_Unit, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/add_global_controller.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:GconTagInUse",
        "GUILDA:PowerNetwork:GconPorts"
      ],
      "Summary": "Build a global controller from its model key, add it to the network and return it.",
      "Desc": "`Key` is the model key of a global controller class (`keys(GUILDA.keymap(\"GlobalController\"))`\nlists them). `a_Unit` gives the controlled components of this network, as\nComponent objects (a cell array) or as tags. `parameter` gives the parameters of the\nconstructor as a struct (or a one-row table) of Name=Value; omitted fields keep the\nclass defaults. The controller tag is the network tag (for the bundled networks\n\"PowerNetwork\"), the class header and a number, e.g. \"PowerNetworkAGC1\".\n\nEach controlled unit must have the inputs `sv_u` of the controller as outputs or states,\nand each output `sv_y` as an input of the unit or of one of its local controllers. Where\neach output goes is read from the connection map (net.get_variable_map, rows \"global\"):\nto every local controller of the unit (nested ones included) with an input of that\nname, otherwise to the input of the unit. An INFO message lists these connections\n(source -> target, by Label). The addition is a \"Topology\" edit of the controller: its\nown equilibrium and handles are stale until net.initialize(); the power flow is not.",
      "SeeAlso": [],
      "Examples": "```matlab\nagc = net.add_global_controller(\"agc-PI\", [\"B001SG1\",\"B002SG1\"], parameter=struct(kP=100, kI=500));\ng3  = net.a_Bus{3}.a_Component{1};\nagc = net.add_global_controller(\"agc-PI\", {g3});\n```\n\nSee also PowerNetwork.remove_global_controller, GlobalController, controller.agc.broadcast_PI_AGC",
      "Deprecated": ""
    },
    {
      "Name": "add_branch",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Key",
        "from_to",
        "opt"
      ],
      "OutputNames": [
        "bra"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Key",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "char",
          "Validators": [
            "tools.mustBeKeyOf(Key, \"Branch\")"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Branch model key, e.g. \"pi\" or \"pi_transformer\"."
        },
        {
          "Name": "from_to",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "",
          "Validators": [
            "string",
            "double"
          ],
          "Default": "[1,2]",
          "Required": false,
          "Unit": "",
          "Description": "End buses [from, to], as indices of a_Bus or as bus tags."
        },
        {
          "Name": "R",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "0",
          "Required": false,
          "Unit": "pu",
          "Description": "Series resistance."
        },
        {
          "Name": "X",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "1",
          "Required": false,
          "Unit": "pu",
          "Description": "Series reactance."
        },
        {
          "Name": "C",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "0",
          "Required": false,
          "Unit": "pu",
          "Description": "Shunt susceptance at each end (half of the line charging)."
        },
        {
          "Name": "Tap",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "1",
          "Required": false,
          "Unit": "",
          "Description": "Off-nominal tap ratio of a transformer (the lines \"pi\" and \"T\" have none: NaN)."
        },
        {
          "Name": "Phase",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "0 /180*pi",
          "Required": false,
          "Unit": "rad",
          "Description": "Phase shift of a transformer (the lines \"pi\" and \"T\" have none: NaN)."
        },
        {
          "Name": "Circuit",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "2",
          "Required": false,
          "Unit": "",
          "Description": "Number of parallel circuits; R, X and C are for all of them together (one circuit: Circuit*R, Circuit*X, C/Circuit)."
        },
        {
          "Name": "Smax",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "inf",
          "Required": false,
          "Unit": "pu",
          "Description": "Limit of the apparent power at both ends (Inf: none)."
        },
        {
          "Name": "Imax",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "inf",
          "Required": false,
          "Unit": "pu",
          "Description": "Limit of the current at both ends (Inf: none)."
        },
        {
          "Name": "Pmax",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "inf",
          "Required": false,
          "Unit": "pu",
          "Description": "Limit of the active power at both ends (Inf: none)."
        },
        {
          "Name": "Qmax",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "inf",
          "Required": false,
          "Unit": "pu",
          "Description": "Limit of the reactive power at both ends (Inf: none)."
        },
        {
          "Name": "Vargmax",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "90/180*pi",
          "Required": false,
          "Unit": "rad",
          "Description": "Limit of the angle difference between the end buses (Inf: none)."
        },
        {
          "Name": "Path",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "tools.layout_mustBePath"
          ],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Bend points of the line in network diagrams: \"x y; x y\" or an n x 2 matrix (\"\" = none)."
        },
        {
          "Name": "FromOffset",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "nan",
          "Required": false,
          "Unit": "",
          "Description": "Position on the bar of the from bus, from the bar center (NaN = from the first bend point)."
        },
        {
          "Name": "ToOffset",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "nan",
          "Required": false,
          "Unit": "",
          "Description": "Position on the bar of the to bus, from the bar center (NaN = from the last bend point)."
        },
        {
          "Name": "Style",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Style, [\"line\",\"transformer\"])"
          ],
          "Default": "\"line\"",
          "Required": false,
          "Unit": "",
          "Description": "Line style in network diagrams: \"line\" or \"transformer\" (symbol at the from end)."
        }
      ],
      "Outputs": [
        {
          "Name": "bra",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Added Branch object."
        }
      ],
      "Signature": "bra = add_branch(obj, Key, from_to, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/add_branch.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerNetwork:BranchBusIndex",
        "GUILDA:PowerNetwork:BusNotFound",
        "GUILDA:PowerNetwork:BranchSelfLoop",
        "GUILDA:PowerNetwork:BranchZeroImpedance"
      ],
      "Summary": "Add a branch between two buses and return it.",
      "Desc": "`from_to` names the two end buses by their index in `a_Bus` or by their tags. The\nbranch tag is the class header followed by a three-digit number. The addition is\na \"Topology\" edit, which makes the power flow stale.\n\nR, X and C are the values of all circuits of the branch together. `Circuit` (default 2)\nis the number of parallel circuits: it does not change the closed admittance matrix and\nis used by the states that act on one circuit, Branch.get_admittance_matrix(Status=\"3LG\")\nand (Status=\"3open\").\n\nThe end buses must exist and differ, and R and X must not both be 0; otherwise the\nnetwork stays unchanged and an error explains the fix.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet.add_branch(\"pi\", [1,2], R=0.01, X=0.085, C=0.088);\nnet.add_branch(\"pi_transformer\", [\"B004\",\"B007\"], X=0.2091, Tap=0.978);\nnet.add_branch(\"pi\", [2,3], R=0.02, X=0.17, Circuit=1);   % a single-circuit line\nnet.add_branch(\"pi\", [1,3], X=0.1, Path=\"0.2 0.5; 0.4 0.5\");   % with two bend points\n```\n\nSee also PowerNetwork.remove_branch, PowerNetwork.add_bus, Branch",
      "Deprecated": ""
    },
    {
      "Name": "add_bus",
      "Defining": "PowerNetwork",
      "Group": "Model building",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "bus"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "Varg",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "0 /180*pi",
          "Required": false,
          "Unit": "rad",
          "Description": "Voltage angle setting used when the bus is the slack bus."
        },
        {
          "Name": "V",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "1",
          "Required": false,
          "Unit": "pu",
          "Description": "Voltage magnitude setting (slack or PV bus)."
        },
        {
          "Name": "Gshunt",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "0",
          "Required": false,
          "Unit": "pu",
          "Description": "Shunt conductance."
        },
        {
          "Name": "Bshunt",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "0",
          "Required": false,
          "Unit": "pu",
          "Description": "Shunt susceptance."
        },
        {
          "Name": "Vmin",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "0.5",
          "Required": false,
          "Unit": "pu",
          "Description": "Lower limit of the bus voltage magnitude (-Inf: none)."
        },
        {
          "Name": "Vmax",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "1.5",
          "Required": false,
          "Unit": "pu",
          "Description": "Upper limit of the bus voltage magnitude (Inf: none)."
        },
        {
          "Name": "baseKV",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "230",
          "Required": false,
          "Unit": "kV",
          "Description": "Base voltage; stored and exported to MATPOWER, used in no calculation."
        },
        {
          "Name": "baseMVA",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "nan",
          "Required": false,
          "Unit": "MVA",
          "Description": "COMPAT(v3) Ignored; the system base is net.tab_parameter.base.baseMVA."
        },
        {
          "Name": "Tag",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "'B'",
          "Required": false,
          "Unit": "",
          "Description": "Prefix of the bus tag."
        },
        {
          "Name": "FullTag",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Complete bus tag, used instead of Tag and the automatic number (\"\" = automatic)."
        },
        {
          "Name": "X",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "nan",
          "Required": false,
          "Unit": "",
          "Description": "x coordinate of the bus center in network diagrams (NaN = automatic layout)."
        },
        {
          "Name": "Y",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "nan",
          "Required": false,
          "Unit": "",
          "Description": "y coordinate of the bus center in network diagrams (NaN = automatic layout)."
        },
        {
          "Name": "Shape",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Shape, [\"hbar\",\"vbar\",\"circle\",\"square\",\"^\",\"v\",\"<\",\">\",\"none\"])"
          ],
          "Default": "\"square\"",
          "Required": false,
          "Unit": "",
          "Description": "Shape in network diagrams: \"hbar\", \"vbar\" (bars, which need Length) or a marker."
        },
        {
          "Name": "Length",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositiveOrNaN"
          ],
          "Default": "nan",
          "Required": false,
          "Unit": "",
          "Description": "Length of a bar (\"hbar\", \"vbar\"); NaN for the other shapes."
        },
        {
          "Name": "MarkerSize",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositiveOrNaN"
          ],
          "Default": "nan",
          "Required": false,
          "Unit": "",
          "Description": "Marker size in network drawings (NaN = drawer default)."
        },
        {
          "Name": "Color",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Color in network drawings: a MATLAB color name or \"#RRGGBB\" (\"\" = drawer default)."
        }
      ],
      "Outputs": [
        {
          "Name": "bus",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Added Bus object."
        }
      ],
      "Signature": "bus = add_bus(obj, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/add_bus.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add a bus to the network and return it.",
      "Desc": "The bus tag is `Tag` followed by a three-digit number (the largest number in use + 1),\ne.g. \"B001\". `FullTag` gives the complete tag instead, with no automatic number; a\ntag already used in the network is renamed with a number suffix, as for `s_tag`, and\nan Info line shows the change. The tag must be a valid variable name (isvarname, e.g.\n\"Sub_7\", not \"Sub-7\"); any other tag stops with GUILDA:LayerPackage:InvalidTag and no bus\nis added. The addition is a \"Topology\" edit, so the power flow is stale until\n`net.initialize()` runs again.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = PowerNetwork();\nb1  = net.add_bus(V=1.0, Varg=0);\nb2  = net.add_bus(Bshunt=0.1, Vmin=0.9, Vmax=1.1);\nb3  = net.add_bus(FullTag=\"Sub7\");\nb4  = net.add_bus(X=0.5, Y=0.2, Shape=\"hbar\", Length=0.1);   % a bar in network diagrams\n```\n\nThe graph arguments (X to Color) are the layout of the bus in network diagrams; a bar\n(\"hbar\", \"vbar\") needs a positive Length. A wrong value stops before the bus is added.\n\nSee also PowerNetwork.remove_bus, PowerNetwork.add_branch, Bus",
      "Deprecated": ""
    },
    {
      "Name": "build_simulation_data",
      "Defining": "PowerNetwork",
      "Group": "build",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_scenario",
        "time"
      ],
      "OutputNames": [
        "sct_dae",
        "sct_event",
        "rv_x0",
        "tab_phase"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "s_scenario",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "simulateFcn_mustBeScenarioOf(obj, s_scenario)"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tag of the scenario."
        },
        {
          "Name": "time",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [
            "mustBeSimulationTime"
          ],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Simulation time [t0, tend]."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_dae",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Blocks, maps, admittance and equilibrium of the network."
        },
        {
          "Name": "sct_event",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One element per phase, the disturbances as positions."
        },
        {
          "Name": "rv_x0",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Initial value of the variable rows of sct_dae.tab_variable."
        },
        {
          "Name": "tab_phase",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "output.phases: t1, t2, one logical column per disturbance."
        }
      ],
      "Signature": "[sct_dae, sct_event, rv_x0, tab_phase] = build_simulation_data(obj, s_scenario, time)",
      "File": "_GUILDAsystem/@PowerNetwork/build_simulation_data.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "(Hidden) Data of one run of simulate for SolverODE.solve: for tests and debugging.",
      "Desc": "Gathers from the network everything the solver needs, so that SolverODE.solve reads no\nnetwork, bus, branch, component, controller or scenario:\n  1. the checks before a run: stale models and edited inputs (net.initialize() needed)\n  2. the variable map and the connection map (get_variable_map)\n  3. the blocks of the components, local controllers and global controllers: their rows\n     in the map and their f_* function handles (closures with the parameters bound by\n     value), the equilibrium and the admittance matrix with all branches closed\n  4. the phases of the scenario (Scenario.compile): the disturbances as positions\n  5. the islands left by branches that no longer join their buses (opened, or all\n     circuits grounded)\n  6. the admittance matrices of the phases: one call of get_admittance_matrix(\n     BranchStatus=tab_branch) for each distinct set of branch states of the phases,\n     kept in sct_dae.c_Y (c_Y{1}: all branches closed, cm_Y), and the matrices of the\n     branches in each set in sct_dae.c_Ybranch (2 x 2 x n_branch each, for the branch\n     flows of ResultODE); sct_event(k).i_Y is the position of the matrices of phase k\n     in c_Y and c_Ybranch\n  7. the initial value rv_x0: the equilibrium with the offsets and inputs of the first\n     phase\nThe time is required, so that the time of a run is decided only by simulate (a test\npasses sc.Time).",
      "SeeAlso": [],
      "Examples": "```matlab\n[sct_dae, sct_event, rv_x0] = net.build_simulation_data(\"fault\", [0, 10]);\n[sct_sol, flag, output] = net.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options);\n```\n\nSee also PowerNetwork.simulate, SolverODE.solve, Scenario",
      "Deprecated": ""
    },
    {
      "Name": "import_matpower",
      "Defining": "PowerNetwork",
      "Group": "Data IO",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "mpc",
        "opt"
      ],
      "OutputNames": [
        "net"
      ],
      "Arguments": [
        {
          "Name": "mpc",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "MATPOWER case: the struct (baseMVA, bus, gen, branch, optional gencost), the name of a case function on the path (\"case14\"), a .m or .mat case file, or a function handle that returns the struct."
        },
        {
          "Name": "GeneratorModel",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"gen-park\"",
          "Required": false,
          "Unit": "",
          "Description": "Component key of every generator (e.g. \"gen-park\", \"gen-classical\", \"gen-1axis\")."
        },
        {
          "Name": "GeneratorParameter",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "nan",
          "Required": false,
          "Unit": "",
          "Description": "Dynamic parameters of every generator (the parameter argument of add_component); NaN uses the defaults of the model class (first row of its parameter.csv)."
        },
        {
          "Name": "LoadModel",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"load-power\"",
          "Required": false,
          "Unit": "",
          "Description": "Component key of every load."
        },
        {
          "Name": "Hz",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "GUILDA.config(\"PowerSystemModel\",\"Hz\")",
          "Required": false,
          "Unit": "Hz",
          "Description": "Nominal frequency (MATPOWER has none)."
        },
        {
          "Name": "Tag",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag of the network. Default: the case name, or \"PowerNetwork\" for a struct."
        },
        {
          "Name": "Initialize",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Run net.initialize() after building the network."
        }
      ],
      "Outputs": [
        {
          "Name": "net",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The built network."
        }
      ],
      "Signature": "net = PowerNetwork.import_matpower(mpc, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/import_matpower.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:import_matpower:GenBusMissing",
        "GUILDA:import_matpower:BranchBusMissing",
        "GUILDA:import_matpower:IsolatedBus",
        "GUILDA:import_matpower:ReferenceBusEmpty",
        "GUILDA:import_matpower:CaseNotFound",
        "GUILDA:import_matpower:InvalidCaseType",
        "GUILDA:import_matpower:InvalidCaseField",
        "GUILDA:import_matpower:UnsupportedVersion",
        "GUILDA:import_matpower:InvalidCaseColumns",
        "GUILDA:import_matpower:GencostRows",
        "GUILDA:import_matpower:GencostPiecewise",
        "GUILDA:import_matpower:GencostDegree"
      ],
      "Summary": "Build a network from a MATPOWER case.",
      "Desc": "Builds a PowerNetwork from a MATPOWER case (version 2); the inverse of\ntools.network_to_mpc. MATPOWER itself is not needed.\nUnits are converted to per unit on mpc.baseMVA (net.tab_parameter.base.baseMVA) and\nangles to radians. Buses keep the row order of mpc.bus (bus i = net.a_Bus{i}); the\nbus numbers of mpc.bus(:,1) are only used to resolve gen and branch rows.\n  bus     : Gshunt/Bshunt = GS/BS / baseMVA, Vmin/Vmax = VMIN/VMAX, baseKV = BASE_KV,\n            Varg = VA, and V = VG of the first\n            in-service generator of the bus (VM without one). The REF bus (type 3) is\n            the slack bus. Isolated buses (type 4) are not supported.\n  load    : a LoadModel component with P = -PD/baseMVA, Q = -QD/baseMVA (GUILDA\n            injection sign: consumed power is negative) on each bus with nonzero PD or\n            QD. Its OPF cost is 0.\n  gen     : a GeneratorModel component per in-service row (GEN_STATUS > 0), before the\n            load of its bus: P = PG/baseMVA and Q = NaN (the bus is a PV bus),\n            Pmin/Pmax/Qmin/Qmax = PMIN/PMAX/QMIN/QMAX / baseMVA, baseMVA = MBASE, OPF\n            initial values PG/QG / baseMVA. Dynamic parameters are GeneratorParameter.\n  gencost : polynomial costs (MODEL = 2) up to quadratic, c2*Pg^2 + c1*Pg + c0 in MW:\n            HP = c2*baseMVA^2, fP = c1*baseMVA, c = c0, startup/shutdown = STARTUP/SHUTDOWN;\n            rows ng+1:2*ng give HQ and fQ, and their c0 is added to c. Piecewise-linear costs (MODEL = 1)\n            and higher degrees stop with GUILDA:import_matpower:GencostPiecewise and\n            GencostDegree.\n            Without gencost the costs are the add_component defaults.\n  branch  : each in-service row (BR_STATUS > 0) is a \"pi\" line when TAP is 0 or 1 and\n            SHIFT is 0, else a \"pi_transformer\" (tap on the from side, as in MATPOWER):\n            R, X, C = BR_B/2, tap = TAP, phase = SHIFT, Smax = RATE_A/baseMVA (0 = Inf),\n            Vargmax = the tighter of |ANGMIN| and |ANGMAX| (Inf when both are 0 or\n            reach 360 degrees). Imax, Pmax and Qmax are Inf.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = PowerNetwork.import_matpower(\"case14\");              % needs case14.m on the path\nnet = PowerNetwork.import_matpower(mpc, GeneratorModel=\"gen-classical\", Initialize=false);\nmpc2 = tools.network_to_mpc(net);                              % back to MATPOWER\n```\n\nSee also PowerNetwork.import, tools.network_to_mpc",
      "Deprecated": ""
    },
    {
      "Name": "import",
      "Defining": "PowerNetwork",
      "Group": "Data IO",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "path",
        "opt"
      ],
      "OutputNames": [
        "net"
      ],
      "Arguments": [
        {
          "Name": "path",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Model folder (e.g. the folder written by net.export)."
        },
        {
          "Name": "Initialize",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Run net.initialize() after building the network."
        },
        {
          "Name": "Network",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Existing network to add the buses, branches and components to (it is returned). Its Hz and baseMVA are overwritten by network/parameter.csv when the file gives them. Default: a new PowerNetwork tagged with the folder name (without a leading @)."
        }
      ],
      "Outputs": [
        {
          "Name": "net",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The built network."
        }
      ],
      "Signature": "net = PowerNetwork.import(path, Name=Value)",
      "File": "_GUILDAsystem/@PowerNetwork/import.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:import:NotFound",
        "GUILDA:import:InvalidNetwork",
        "GUILDA:import:ControllerSlots",
        "GUILDA:import:UnknownComponent",
        "GUILDA:import:UnknownControllerKey",
        "GUILDA:import:OptionJson",
        "GUILDA:import:MissingFile",
        "GUILDA:import:OldGraphColumns",
        "GUILDA:import:BusRow",
        "GUILDA:import:UnknownID"
      ],
      "Summary": "Build a network and its scenarios from a model folder.",
      "Desc": "Builds a PowerNetwork from a model folder (the layout written by net.export):\n  <path>/network/parameter.csv        Hz, baseMVA of the network (optional)\n  <path>/bus/parameter.csv            one row per bus (V, Varg required)\n  <path>/branch/parameter.csv         one row per branch (Type, From, To required)\n  <path>/component/<key>/main.csv     one row per component of type <key> (Bus, P, Q required)\n  <path>/component/<key>/dynamics.csv parameters referenced by the column ParameterID\n  <path>/component/<key>/opf.csv      OPF settings referenced by the column OpfID\n  <path>/local_controller/<key>/parameter.csv   one row per local controller (optional)\n  <path>/local_controller/<key>/option.json     constructor arguments outside the table, by FullTag (optional)\n  <path>/global_controller/<key>/parameter.csv  one row per controlled component (optional)\n  <path>/scenario/<tag>.json          one scenario per file (optional)\nBuses are numbered by their row; From, To and Bus refer to these numbers.\nA missing network/parameter.csv (folders written before v4) or a missing or NaN value\nkeeps the defaults Hz = GUILDA.config(\"PowerSystemModel\",\"Hz\") and baseMVA = 100.\nThe bus column Slack (optional) marks the slack bus; a bus column baseMVA (v3) is\naccepted and ignored: the system base is net.tab_parameter.base.baseMVA.\nThe column FullTag (optional) of the bus, branch and component tables gives the full\ntag of a row, and the bus column Tag is then not used. A missing column or an empty value\nkeeps the automatic tag (folders written before FullTag), with Tag as the bus prefix.\nA local_controller/ folder is the full set of local controllers of the components of the\nfolder: their controllers from creation (the default Static AVR and governor of a\ngenerator) are removed, and each row is attached with comp.add_local_controller(<key>,\nparameter=<the other columns of the row>) to the component whose full tag is in the\ncolumn Component (the AVR or \"local\" controller first, then the PSS, then the governor),\nthen given the tag of the column FullTag. The values of option.json under the FullTag of\nthe row (arguments outside the table, such as Q and R of an LQR; see\nLocalController.get_option) are added to the parameters; a text array becomes a string\narray and an object {\"re\", \"im\"} a complex number. A component without rows has no controller.\nWithout the folder the components keep their controllers from creation. Each global\ncontroller (rows of the same FullTag in global_controller/<key>/parameter.csv) is added\nafter the local controllers and the slack bus with net.add_global_controller(<key>,\n<its Component column>, parameter=<its option.json values>) and its dynamics table is set\nto the other columns.\nWith Network=obj the buses are added to the existing network obj instead of a new\none; this is how the network classes such as network.IEEE14bus load their folder in\ntheir constructor.\nThe scenarios are added after the controllers, in the order of the file names, by\nnet.add_scenario(<file name>) with the Time, Description and disturbances of the file\n(see net.export); a tag in use gets a number suffix. A file that is not a scenario file\nstops with GUILDA:PowerNetwork:ScenarioJson; unknown fields give the warning\nGUILDA:PowerNetwork:UnknownScenarioField and are ignored.\nEvery table and scenario file is read and checked before the network changes: a wrong\nfile, column or row number leaves obj unchanged. An unknown column gives the warning\nGUILDA:import:UnknownColumn and is ignored (a memo column does not stop the import);\nthe columns of dynamics.csv and of the controller tables depend on the class and are not\nchecked. A controller key that is not in GUILDA.keymap (GUILDA:import:UnknownControllerKey),\na Component that is not a FullTag of the component tables (GUILDA:import:UnknownComponent)\nand rows that do not fit the slots of a component (GUILDA:import:ControllerSlots: two AVR\nor \"local\" controllers, two PSSs, two governors, or a PSS without an AVR) also stop the\nimport before the network changes. The graph\ncolumns of earlier versions (Xaxis, Yaxis, Marker, MidXaxis, MidYaxis) stop the import\nwith GUILDA:import:OldGraphColumns; tools.layout_convert_columns converts such a folder. A later\nfailure, such as an unknown model key, a disturbance whose tag is not in the network or\na failing power flow, can leave obj partly built, so build it again after an error.",
      "SeeAlso": [],
      "Examples": "```matlab\npath = net.export(fullfile(tempdir, \"MyNet\"));\nnet2 = PowerNetwork.import(path);\nnet2.tab_parameter.base      % Hz and baseMVA of net\n```\n\n```matlab\n% in the constructor of a network class next to its CSV folders\nPowerNetwork.import(fileparts(mfilename(\"fullpath\")), Network=obj);\n```\n\nSee also PowerNetwork.export, PowerNetwork.import_matpower",
      "Deprecated": ""
    },
    {
      "Name": "gui_content",
      "Defining": "PowerNetwork",
      "Group": "gui",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "sct_page"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        }
      ],
      "Outputs": [
        {
          "Name": "sct_page",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Pages: fields s_title, s_type and content."
        }
      ],
      "Signature": "sct_page = gui_content(obj)",
      "File": "_GUILDAsystem/@PowerNetwork/gui_content.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Pages of the GUI of a network: \"Summary\" and \"Equilibrium\", then the pages of PowerSystemModel.",
      "Desc": "- \"Summary\" (\"table\"): the numbers of buses, branches, components (over all buses),\n  global controllers and scenarios.\n- \"Equilibrium\" (\"table\"): one row per bus with the columns Tag, Type (`s_bustype`),\n  V (`cv_Vequilibrium`), |V|, ∠V [rad] and I (`cv_Iequilibrium`).",
      "SeeAlso": [
        "LayerPackage.launch_gui",
        "LayerPackage.gui_content"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "handle_edit",
      "Defining": "PowerNetwork",
      "Group": "Called by analyses",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "a_layer",
        "tag",
        "log"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "a_layer",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Edited layer (the owner for a parameter edit)."
        },
        {
          "Name": "tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Kind of edit (see LayerPackage.log_edit)."
        },
        {
          "Name": "log",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Message of the edit."
        }
      ],
      "Outputs": [],
      "Signature": "handle_edit(obj, a_layer, tag, log)",
      "File": "_GUILDAsystem/@PowerNetwork/handle_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Network-wide rules for an edit of any layer of the network (LayerPackage.log_edit),",
      "Desc": "also before the first initialize.\n\n- At most one slack bus: a bus reports bus.l_isSlack = true as a \"Slack\" edit, and the\n  network releases the others.\n- The stale tag powerflow is marked for the edits that change the power flow:\n    the network     base (baseMVA), Topology (buses and branches added, removed or\n                    replaced)\n    a bus           dynamics (shunt), powerflow, Slack, Topology (components connected,\n                    replaced or removed)\n    a branch        dynamics\n    a component     powerflow\n- The stale tag input is marked for an edit of the inputs of a component (set_input):\n  only initialize(Method=\"FixedInput\") keeps them.\n- The stale tag odefcn is marked for a Hz edit of the network (base, told from baseMVA\n  by s_lastEdited of its base container): the edit does not reach the models, whose handles bind\n  the frequency.\nOther edits are ignored here (the components and controllers mark their own tags).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "doc",
      "Defining": "PowerSystemModel",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Model whose class page is opened."
        }
      ],
      "Outputs": [],
      "Signature": "doc(obj)",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/doc.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Open the class reference page of the model's class.",
      "Desc": "Opens the GUILDA class reference (English page) of class(obj) in the browser, as\nGUILDA.doc(\"class\", class(obj)). doc with a class name (doc PowerNetwork) is\nMATLAB's doc.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.doc()                          % page of the network class\nnet.a_Bus{1}.doc()                 % page of the class of the first bus\nnet.a_Bus{1}.a_Component{1}.doc()  % page of the class of its component\ndoc(net)                           % same as net.doc()\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_sys",
      "Defining": "PowerSystemModel",
      "Group": "Linearization",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "point",
        "opt"
      ],
      "OutputNames": [
        "sys",
        "flag",
        "output"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "point",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Point: [] (the equilibrium), a vector in the order of get_variable_map(), a matrix (one point per column), {sim, rv_t} or {sim, rv_t, Side}."
        },
        {
          "Name": "Type",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "GUILDA.config(\"ApproximateLinearization\", \"Type\")",
          "Required": false,
          "Unit": "",
          "Description": "Model of the network: \"ODE\" (the bus voltages eliminated) or \"DAE\" (the connected model)."
        },
        {
          "Name": "Port",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Port, [\"PI\",\"PQ\",\"I\"])"
          ],
          "Default": "GUILDA.config(\"ApproximateLinearization\", \"Port\")",
          "Required": false,
          "Unit": "",
          "Description": "Bus port of \"DAE\" (v, w): \"PI\" ([theta,V], [P,Q/V]), \"PQ\" ([theta,rho], [P,Q]) or \"I\" ([Vre,Vim], [-Iim,Ire])."
        },
        {
          "Name": "PlotFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "GUILDA.config(\"ApproximateLinearization\", \"PlotFcn\")",
          "Required": false,
          "Unit": "",
          "Description": "Live display: \"none\" (checked by tools.check_plotfcn; draw the eigenvalue map with result.plot_eigenvalue())."
        },
        {
          "Name": "Input",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Inputs of the model: \"u\" or Labels (see ResultLIN.get_ss). Default: all inputs."
        },
        {
          "Name": "Output",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Outputs of the model: \"x\", \"V\", \"I\", \"y\" or names (see ResultLIN.get_ss). Default: as in get_ss."
        },
        {
          "Name": "Format",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Format, [\"GUILDAorigin\",\"struct\",\"ss\"])"
          ],
          "Default": "\"GUILDAorigin\"",
          "Required": false,
          "Unit": "",
          "Description": "Form of sys: GUILDAorigin (a ResultLIN), struct or ss (dss)."
        },
        {
          "Name": "Form",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Form, [\"descriptor\",\"absorbed\",\"hessian\"])"
          ],
          "Default": "\"descriptor\"",
          "Required": false,
          "Unit": "",
          "Description": "View of A ... E: \"descriptor\" (E holds the time constants), \"absorbed\" (E^-1 in A and B) or \"hessian\" (the energy-function form; network, Port PI or PQ)."
        }
      ],
      "Outputs": [
        {
          "Name": "sys",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Linear model in the form of Format, with state, input and output names (1 x n_t struct or ss array for several sections)."
        },
        {
          "Name": "flag",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True when the result is usable: all entries are finite and Avv is invertible, in every section."
        },
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "message, s_issue (\"\", \"NotFinite\" or \"SingularAvv\"), l_equilibrium, n_x, n_v, n_u, rcond_Avv, sv_faultBus, s_layer; per section lv_flag, sv_issue, sv_message, rv_rcond_Avv; result (the ResultLIN)."
        }
      ],
      "Signature": "[sys, flag, output] = get_sys(obj, point, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/get_sys.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerSystemModel:NoLinearModel",
        "GUILDA:PowerSystemModel:HessianNetworkOnly",
        "GUILDA:PowerSystemModel:HessianPort",
        "GUILDA:PowerSystemModel:InputEdited",
        "GUILDA:PowerSystemModel:Stale"
      ],
      "Summary": "Linearize the layer and return its linear model.",
      "Desc": "One method for every layer with a linear model: PowerNetwork, Bus, Component (with\nits local controllers), LocalController and GlobalController (Branch has none:\nGUILDA:PowerSystemModel:NoLinearModel). Each model object gives its own linear block\n(get_linear_matrix); get_sys takes the inputs and outputs of the layer (its port) from\nthe variable map, and SolverLIN.solve connects the blocks along it. The linearization needs no\ntoolbox, and the model is not changed.\n\n| Layer | Inputs | Outputs | Bus voltages |\n|---|---|---|---|\n| PowerNetwork | inputs u of the components | outputs y and yc | algebraic: 0 = Y v - I of the components, eliminated for Type \"ODE\" |\n| Bus, Component | V, u, uc | I, y, yc | inputs |\n| LocalController | V of its bus, its inputs | its outputs | inputs |\n| GlobalController | V of all buses, its inputs | its outputs | inputs |\n\nThe names are the Labels of the variable map of the layer (obj.get_variable_map); the\nstates follow its order. The current of a\ncomponent is the component tag with Ire, Iim; that of a bus the bus tag. An input is\nthe sum of its sources in the connection map plus the external input of that name.\n\npoint, the first argument, gives the point: [] (the equilibrium set by net.initialize,\nthe default), a vector of the variables of the layer in the order of the leading rows of\nobj.get_variable_map() (x, Vre, Vim, u, uc; for a controller x, Vre, Vim, uc), or\n{sim, t} (or {sim, t, \"before\"}) for the state of a simulation result at time t\n(PowerNetwork, Bus and Component).\nTime sections: {sim, rv_t} with several times, or a matrix with one point per column,\nlinearizes the layer at each of them; the result holds one section per time or column\n(ResultLIN.rv_t: the times, or 1:n for a matrix; ResultLIN.Index chooses the section),\nand flag is true only when every section is usable (output.lv_flag of each section). Every value of the point is used as given: the\ninputs u of the components and uc of the controllers, whether the connection map drives\nthem or holds them at a setpoint (Vref of an AVR, Pref of a governor). The outputs y and\nyc are evaluated at the point. The point sets the variables only: the\nadmittance matrix stays the one of the model, also inside a fault (reported with an\nINFO message and output.sv_faultBus).\n\nThe layer stops with GUILDA:PowerSystemModel:Stale when net.initialize() is needed: an\nedited dynamics always, an edited network, power flow or equilibrium when the point is the\nequilibrium; with GUILDA:PowerSystemModel:InputEdited when the inputs were edited.\nA point with NaN or Inf stops with GUILDA:SolverLIN:PointNotFinite, and a model that is\nnot finite at the point with GUILDA:SolverLIN:JacobianNotFinite.\n\nFormat chooses the form of sys: \"GUILDAorigin\" (default) is the ResultLIN of the\nlinearization, also when flag is false; its properties A, B, C, D, E, StateName,\nInputName and OutputName hold the model of its Type (the Type of the call) with the\nselected Input and Output. \"struct\" is a struct with these eight fields and \"ss\" a\ndescriptor state-space model (dss, Control System Toolbox): they stop with the error of\nResultLIN.get_ss when flag is false (except \"DAE\" with a singular Avv). With several\nsections, \"struct\" is a 1 x n_t struct array and \"ss\" an ss array (sys(:,:,k) is\nsection k). The ResultLIN of the network (Format \"GUILDAorigin\") keeps a snapshot of it,\nsct_network = struct(net, false).\n\nType chooses the model of the network: \"DAE\" is the connected model, with the bus\nvoltages as algebraic variables (E is singular on their rows), each bus written as the\nport of Port (see ResultLIN.get_ss); \"ODE\" is the model with the bus voltages eliminated (SolverLIN.reduce).\nThe result keeps the DAE, so res.Type switches between them later.\n\nForm chooses the view of A ... E (ResultLIN.Form): \"descriptor\" (default; E holds the\ntime constants), \"absorbed\" (E^-1 multiplied into the state rows) or \"hessian\", the\nenergy-function form of the network: get_sys calls get_hessian of every component, local\ncontroller and global controller at the point of each section, and SolverLIN.solve\nassembles E_h dz/dt = H z over z = [x; theta; V] with E_h = -blkdiag(inv(R), 0) and\nH = [Hxx Hxv; Hvx Hvv + Hvv_net] (see ResultLIN). A class without the form stops with\nits GUILDA:<layer>:HessianNotSupported (the Static AVR and governor have empty blocks).\n\"hessian\" needs the network (GUILDA:PowerSystemModel:HessianNetworkOnly) and Port \"PI\"\nor \"PQ\" (GUILDA:PowerSystemModel:HessianPort). The result keeps the descriptor DAE too.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = net.get_sys();                          % ResultLIN of the network (Type of GUILDA.setting)\neig(res.A, res.E)\nsct = net.get_sys(Type=\"DAE\", Format=\"struct\");\nresV = net.get_sys(Output=\"V\");               % bus voltages as outputs\nsys = net.a_Bus{1}.a_Component{1}.get_sys(Format=\"ss\");   % component, V to I\nres2 = net.get_sys({sim, 1.5});               % at a time of a simulation result\nres3 = net.get_sys(res.rv_point);             % at a vector in the order of net.get_variable_map()\nres4 = net.get_sys({sim, [0.5, 1, 2]});       % three time sections; res4.Index = 2 shows t = 1\nsct4 = net.get_sys({sim, [0.5, 1, 2]}, Format=\"struct\");   % 1 x 3 struct array\nresH = net.get_sys(Type=\"DAE\", Port=\"PI\", Form=\"hessian\");  % energy-function form\n```\n\nSee also ResultLIN, SolverLIN, PowerNetwork.get_variable_map",
      "Deprecated": ""
    },
    {
      "Name": "get_Hz",
      "Defining": "PowerSystemModel",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "Hz"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        }
      ],
      "Outputs": [
        {
          "Name": "Hz",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "Hz",
          "Description": "Nominal frequency."
        }
      ],
      "Signature": "Hz = get_Hz(obj)",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/get_Hz.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Nominal frequency [Hz] of the network the model belongs to.",
      "Desc": "net.tab_parameter.base.Hz. This is the omega0 passed to the model functions (models multiply it by 2*pi).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "log_edit",
      "Defining": "LayerPackage",
      "Group": "log",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "log",
        "tag"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Edited layer (a Parameter container for a parameter edit)."
        },
        {
          "Name": "log",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "What was edited, with the values (e.g. \"edit D: 0.1 -> 0.2\")."
        },
        {
          "Name": "tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Kind of edit: a parameter group (\"dynamics\", \"powerflow\", ...), \"Topology\", \"Slack\" or \"Tag\"."
        }
      ],
      "Outputs": [],
      "Signature": "log_edit(obj, log, tag)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/log_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Report an edit of this layer to every layer up to the top.",
      "Desc": "Calls handle_edit(a_owner, tag, message) on the edited layer and on every layer\nabove it; a_owner is the edited layer (the owner for a Parameter container) and\nmessage is \"<tag of obj>: <log>\", or \"<container tag>/<owner tag>: <log>\" for a\nParameter container (e.g. \"dynamics/B001SG1: edit D: 2 -> 2.1\"). A generated tag\nalready contains the tags of the parents. Each layer appends the message to its own\nstale tags that the edit affects.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "launch_gui",
      "Defining": "LayerPackage",
      "Group": "launch",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "h_container",
        "opt"
      ],
      "OutputNames": [
        "h"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "h_container",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container to fill: uifigure, uipanel, uitab or uigridlayout (default: a new uifigure)."
        },
        {
          "Name": "History",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "HistoryGUILDA",
          "Validators": [],
          "Default": "HistoryGUILDA(Echo=true)",
          "Required": false,
          "Unit": "",
          "Description": "Log that runs and records the actions; its root variable (net, bus, ...) is set when missing."
        }
      ],
      "Outputs": [
        {
          "Name": "h",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "DrawerModelGUI",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The GUI."
        }
      ],
      "Signature": "h = launch_gui(obj, h_container, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/launch_gui.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Show the model in a GUI: breadcrumb, class, tag, Docs button, stale state, child cards and tables.",
      "Desc": "With no container it opens a new uifigure; with a container (uifigure, uipanel, uitab or\nuigridlayout) it fills it, so that the GUI can be embedded in another app. The breadcrumb\nruns from the root to this model, and the cards show its children by kind; a click on\neither shows that model in the same container. The Docs button opens the reference page\nof the class. The add buttons and the Remove item of the card menus add and remove\nmodels (and the disturbances of a Scenario), and the parameter tables are editable; the\nabstract classes provide the other tables (gui_content), so a model class needs no GUI\ncode. A Scenario has no parameter tab, only its pages (Disturbances, Settings).\n\nEvery action runs as a line of MATLAB code in History (HistoryGUILDA.run), from the root\nvariable of the model tree (`net` for a network): the code is logged, and\n`h.history.get_script()` returns a script that repeats the actions. The default history\nprints each `>> code` in the Command Window. See DrawerModelGUI.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nh = net.a_Bus{1}.launch_gui();                % new window\nfig = uifigure();\np = uipanel(uigridlayout(fig, [1 1]));\nh = net.launch_gui(p);                        % embedded in a panel\nhist = HistoryGUILDA();\nh = net.launch_gui(History=hist);             % log the actions in hist\n```",
      "Deprecated": ""
    },
    {
      "Name": "disp_tree",
      "Defining": "LayerPackage",
      "Group": "disp",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sr_ignore"
      ],
      "OutputNames": [
        "varargout"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Root layer object."
        },
        {
          "Name": "sr_ignore",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "[\"Parameter\"]",
          "Required": false,
          "Unit": "",
          "Description": "Class names to ignore in output."
        }
      ],
      "Outputs": [
        {
          "Name": "varargout",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Hierarchy string (text) when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_tree(obj, sr_ignore)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/disp_tree.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Render the hierarchy tree with optional filtering.",
      "Desc": "Displays or returns a text tree of this layer and its descendants.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "string",
      "Defining": "LayerPackage",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "str"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        }
      ],
      "Outputs": [
        {
          "Name": "str",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag string of the layer object."
        }
      ],
      "Signature": "str = string(obj)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/string.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Convert the layer object to a tag string.",
      "Desc": "Returns the tag string representation of this layer object.",
      "SeeAlso": [],
      "Examples": "```matlab\nstr = string(obj);\n```",
      "Deprecated": ""
    },
    {
      "Name": "table",
      "Defining": "LayerPackage",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "tab"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        }
      ],
      "Outputs": [
        {
          "Name": "tab",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Parameter table of the layer."
        }
      ],
      "Signature": "tab = table(obj)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/table.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Convert layer parameters into table format.",
      "Desc": "Returns the parameter table associated with this layer object.",
      "SeeAlso": [],
      "Examples": "```matlab\ntab = table(obj);\n```",
      "Deprecated": ""
    },
    {
      "Name": "attach_tag",
      "Defining": "LayerPackage",
      "Group": "attach",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sm_name_list"
      ],
      "OutputNames": [
        "out"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Target layer object."
        },
        {
          "Name": "sm_name_list",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Base names to be tagged."
        }
      ],
      "Outputs": [
        {
          "Name": "out",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Input names with layer tag suffix."
        }
      ],
      "Signature": "out = attach_tag(obj, sm_name_list)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/attach_tag.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Generate names with layer tag suffix.",
      "Desc": "Appends \"_\" and the tag of this layer to each input name. A generated tag already\ncontains the tags of the parents (B001SG1 on bus B001, B001SG1CA1 under it,\nPowerNetworkAGC1 on the network), which keeps the labels unique within a network.",
      "SeeAlso": [],
      "Examples": "```matlab\n>> net = network.Tutorial10bus();\n>> gen = net.a_Bus{1}.a_Component{1};\n>> gen.attach_tag([\"delta\", \"omega\"])\nans =\n    \"delta_B001SG1\"    \"omega_B001SG1\"\n```",
      "Deprecated": ""
    },
    {
      "Name": "struct",
      "Defining": "LayerPackage",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "l_disp",
        "s_header",
        "sct_visited"
      ],
      "OutputNames": [
        "net",
        "sct_visited"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": ""
        },
        {
          "Name": "l_disp",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Print the properties that cannot be read or copied."
        },
        {
          "Name": "s_header",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"net\"",
          "Required": false,
          "Unit": "",
          "Description": "Path of this layer in the struct, used for messages and repeated objects."
        },
        {
          "Name": "sct_visited",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "",
          "Validators": [
            "mustBeA(sct_visited,\"struct\")"
          ],
          "Default": "struct(\"a_obj\",{cell(0,1)}, \"sv_path\",strings(0,1))",
          "Required": false,
          "Unit": "",
          "Description": "Layers already stored (a_obj) and their paths (sv_path), used by the recursion. The recursion adds the fields sv_tag and d_override (see private/snapshot)."
        }
      ],
      "Outputs": [
        {
          "Name": "net",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Nested struct of the layer."
        },
        {
          "Name": "sct_visited",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Layers stored so far and their paths (with the recursion fields sv_tag and d_override)."
        }
      ],
      "Signature": "[net, sct_visited] = struct(obj, l_disp, s_header, sct_visited)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/struct.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Convert the layer and its descendants to a nested struct.",
      "Desc": "Copies every property of the layer into a struct field (field \"class\" holds the class\nname); child layers become nested structs and an object reached a second time becomes\nthe path where it was first stored. Analysis objects (auxiliary) and other handles are\nnot copied.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    }
  ],
  "events": [],
  "enumeration": [],
  "validation": {
    "Warnings": [],
    "Errors": []
  }
};
})(window);
