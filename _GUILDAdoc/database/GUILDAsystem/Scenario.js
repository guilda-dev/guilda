(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["Scenario"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "Scenario",
  "properties": [
    {
      "Name": "a_PowerNetwork",
      "Defining": "Scenario",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 141,
      "Summary": "Network the scenario belongs to (set by net.add_scenario; never empty).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "PowerNetwork",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_Event",
      "Defining": "Scenario",
      "Group": "Events",
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
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 145,
      "Summary": "Events of the scenario, in the order added (EventFault, EventTrip, EventOpenBranch, EventOffset, EventInput).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "EventBase",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_event",
      "Defining": "Scenario",
      "Group": "Disturbances",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 149,
      "Summary": "Fault and parallel events (Tag, Target, Time, Status, Point), in the order added.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table (n x 5)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_input",
      "Defining": "Scenario",
      "Group": "Disturbances",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 150,
      "Summary": "Input signals over time, one row each (Tag, TimeSpan, InputUnit, InputName, InputValue, InputMethod).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table (n x 6)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_offset",
      "Defining": "Scenario",
      "Group": "Disturbances",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 151,
      "Summary": "Offsets of the initial states, one row each (Tag, TimeSpan, OffsetUnit, OffsetState, OffsetValue).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table (n x 5)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Time",
      "Defining": "Scenario",
      "Group": "Settings",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[0, 10]",
      "Validation": {
        "Class": "double",
        "Size": "(1,2)",
        "Validators": [
          "mustBeSimulationTime"
        ]
      },
      "Unit": "s",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 155,
      "Summary": "Simulation time [t0, tend] of net.simulate(tag); the Time option of the call replaces it for that call.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double (1x2)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Description",
      "Defining": "Scenario",
      "Group": "Settings",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 156,
      "Summary": "Free text describing the scenario.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_parameter",
      "Defining": "Scenario",
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
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 160,
      "Summary": "Empty table: a scenario has no parameters.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "parent",
      "Defining": "Scenario",
      "Group": "Layer structure",
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
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 164,
      "Summary": "Parent in the layer structure: a_PowerNetwork.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "children",
      "Defining": "Scenario",
      "Group": "Layer structure",
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
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 165,
      "Summary": "Children in the layer structure: none.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Ver",
      "Defining": "Scenario",
      "Group": "Version",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "4.0",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 169,
      "Summary": "Version of this class.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
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
      "Line": 63,
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
      "Line": 66,
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
      "Line": 71,
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
      "Name": "Scenario",
      "Defining": "Scenario",
      "Group": "Constructor",
      "Access": "PowerNetwork",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "net",
        "s_tag"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "PowerNetwork",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Parent network."
        },
        {
          "Name": "s_tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tag (renamed with a number when a child of net has it)."
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
          "Description": "New scenario without disturbances."
        }
      ],
      "Signature": "obj = Scenario(net, s_tag)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/Scenario.m",
      "Line": 173,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create an empty scenario of net (net.add_scenario).",
      "Desc": "The parent is set before the tag, so that a tag in use among the children of net\ngets a number suffix.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "remove_event",
      "Defining": "Scenario",
      "Group": "remove",
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
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the events to remove."
        }
      ],
      "Outputs": [],
      "Signature": "remove_event(obj, tag)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/remove_event.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:Scenario:DisturbanceNotFound"
      ],
      "Summary": "Remove events by tag: their rows leave tab_event, tab_offset and tab_input.",
      "Desc": "A removed event is no longer in the scenario (its a_Scenario is []); an unknown tag\nstops with GUILDA:Scenario:DisturbanceNotFound and nothing is removed.",
      "SeeAlso": [],
      "Examples": "```matlab\nev = sc.add_fault(\"B008\", [1, 1.05]);   % two rows of Fault001 in tab_event\nsc.remove_event(ev.s_tag);              % both rows are removed\n```",
      "Deprecated": ""
    },
    {
      "Name": "add_input",
      "Defining": "Scenario",
      "Group": "add",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "unit",
        "name",
        "value",
        "time",
        "opt"
      ],
      "OutputNames": [
        "ev"
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
          "Name": "unit",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tag of the component."
        },
        {
          "Name": "name",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Names of the inputs (e.g. \"Pmech\", \"Vfield\")."
        },
        {
          "Name": "value",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeA(value, [\"double\",\"table\"])"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Constants (one per input or one for all), or a time series [t, v_1, ..., v_n] or table."
        },
        {
          "Name": "time",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "[t_start, t_end] of the input."
        },
        {
          "Name": "Method",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Method, [\"zoh\",\"foh\",\"spline\"])"
          ],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Interpolation of a time series: \"zoh\", \"foh\" or \"spline\". Default: \"foh\"."
        },
        {
          "Name": "Tag",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Tag of the input; \"\" for input<n> (not Fault or Parallel followed by digits)."
        }
      ],
      "Outputs": [
        {
          "Name": "ev",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "EventInput",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The added event (a handle: edit it with ev.edit)."
        }
      ],
      "Signature": "ev = add_input(obj, unit, name, value, time, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/add_input.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add values to inputs of a component from t_start to t_end.",
      "Desc": "The input is an EventInput, returned: change it with ev.edit and remove it with\nremove_event(ev.s_tag). It gives one row in tab_input.\n\nThe value is a constant or a time series:\n\n- Constant: one number per input, or one for all.\n- Time series: a matrix [t, v_1, ..., v_n] with one column per input, or a table with\n  the variables Time and the input names. t is the time since t_start [s]: finite,\n  strictly increasing and starting at 0. Method chooses the interpolation between the\n  points: \"zoh\" (hold the value until the next point), \"foh\" (linear, the default) or\n  \"spline\"; after the last point the last value is kept until t_end. A \"zoh\" series\n  with many points makes the simulation slower.\n\nMethod given for a constant stops with GUILDA:EventInput:MethodWithoutSeries.",
      "SeeAlso": [],
      "Examples": "```matlab\nsc.add_input(\"B002SG1\", [\"Pmech\"; \"Vfield\"], [0.05; 0.01], [1, 1.5]);   % constants\nsc.add_input(\"B002SG1\", \"Pmech\", [0, 0; 2, 0.02], [1, 3]);               % ramp from t = 1 to 3\nsc.add_input(\"B002SG1\", \"Pmech\", [0, 0.1; 1, 0], [1, 3], Method=\"zoh\");  % 0.1 for 1 s, then 0\n```",
      "Deprecated": ""
    },
    {
      "Name": "add_offset",
      "Defining": "Scenario",
      "Group": "add",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "unit",
        "state",
        "value",
        "time",
        "opt"
      ],
      "OutputNames": [
        "ev"
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
          "Name": "unit",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tag of the component."
        },
        {
          "Name": "state",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Names of the states (e.g. \"delta\")."
        },
        {
          "Name": "value",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Offsets, one per state or one for all."
        },
        {
          "Name": "time",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "0",
          "Required": false,
          "Unit": "s",
          "Description": "Time of the offset."
        },
        {
          "Name": "Tag",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Tag of the offset; \"\" for offset<n> (not Fault or Parallel followed by digits)."
        }
      ],
      "Outputs": [
        {
          "Name": "ev",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "EventOffset",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The added event (a handle: edit it with ev.edit)."
        }
      ],
      "Signature": "ev = add_offset(obj, unit, state, value, time, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/add_offset.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add an offset of the states of a component at one time.",
      "Desc": "The values are added to the states at time (to the initial states when time is the\nstart of the simulation). The offset is an EventOffset, returned: change it with ev.edit\nand remove it with remove_event(ev.s_tag). It gives one row in tab_offset.",
      "SeeAlso": [],
      "Examples": "```matlab\nsc.add_offset(\"B001SG1\", [\"delta\"; \"omega\"], [0.1; 0], 0);\n```",
      "Deprecated": ""
    },
    {
      "Name": "add_open_branch",
      "Defining": "Scenario",
      "Group": "add",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "branch",
        "time",
        "opt"
      ],
      "OutputNames": [
        "ev"
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
          "Name": "branch",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the branches (see string(net.a_Branch))."
        },
        {
          "Name": "time",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time of the opening."
        },
        {
          "Name": "Status",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Status, [\"6open\",\"3open\"])"
          ],
          "Default": "\"6open\"",
          "Required": false,
          "Unit": "",
          "Description": "All circuits or one circuit."
        }
      ],
      "Outputs": [
        {
          "Name": "ev",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "EventOpenBranch",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The added event (a handle: edit it with ev.edit)."
        }
      ],
      "Signature": "ev = add_open_branch(obj, branch, time, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/add_open_branch.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add the opening of branches at time t.",
      "Desc": "\"6open\" (the default) opens all circuits: the branch is left out of the bus admittance\nmatrix. \"3open\" opens one circuit. The branches stay open until the end of the\nsimulation. The opening is an EventOpenBranch with a new tag Parallel<n>, returned:\nchange it with ev.edit and remove it with remove_event(ev.s_tag). It gives one row per\nbranch in tab_event: (t, Status). A branch is opened by one parallel event at most.\n\"3open\" needs a branch of two or more circuits (GUILDA:Scenario:SingleCircuit). An\nopening may overlap a fault of the same branch: the two states give one matrix (see\nPowerNetwork.get_admittance_matrix), e.g. \"3open\" during a \"3LG\" fault opens the\nfaulted circuit.",
      "SeeAlso": [],
      "Examples": "```matlab\nsc.add_open_branch([\"EL003\"; \"EL004\"], 0.17);   % open from t = 0.17 to the end\nsc.add_open_branch(\"EL005\", 1, Status=\"3open\");  % one circuit open from t = 1\n```",
      "Deprecated": ""
    },
    {
      "Name": "add_trip",
      "Defining": "Scenario",
      "Group": "add",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "unit",
        "time"
      ],
      "OutputNames": [
        "ev"
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
          "Name": "unit",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of components, global controllers or local controllers."
        },
        {
          "Name": "time",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time of the trip."
        }
      ],
      "Outputs": [
        {
          "Name": "ev",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "EventTrip",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The added event (a handle: edit it with ev.edit)."
        }
      ],
      "Signature": "ev = add_trip(obj, unit, time)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/add_trip.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add a trip of components, global controllers or local controllers at time t.",
      "Desc": "A tripped unit is disconnected at t and stays disconnected until the end of the\nsimulation (its states are NaN in the result). The trip is an EventTrip with a new tag\nParallel<n>, returned: change it with ev.edit and remove it with remove_event(ev.s_tag).\nIt gives one row per unit in tab_event: (t, \"open\"). A unit is tripped by one parallel\nevent at most. An input whose source is tripped takes its equilibrium value (see the\nScenario help). The local controllers under a tripped component or local controller\nkeep running; give them too to stop them.",
      "SeeAlso": [],
      "Examples": "```matlab\nev = sc.add_trip(\"B003LPQ2\", 1);  % Parallel001\nsc.add_trip(\"B001SG1CA1\", 2);     % a local controller (an AVR of IEEE14bus with avr-ST1 added)\n```",
      "Deprecated": ""
    },
    {
      "Name": "add_fault",
      "Defining": "Scenario",
      "Group": "add",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "target",
        "time",
        "opt"
      ],
      "OutputNames": [
        "ev"
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
          "Name": "target",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the faulted buses, or of the faulted branches."
        },
        {
          "Name": "time",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "[t_start, t_end] of the fault."
        },
        {
          "Name": "Status",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Status, [\"BG\",\"3LG\",\"6LG\"])"
          ],
          "Default": "\"BG\"",
          "Required": false,
          "Unit": "",
          "Description": "\"BG\" for buses; \"3LG\" or \"6LG\" for branches (required there)."
        },
        {
          "Name": "Point",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "NaN",
          "Required": false,
          "Unit": "",
          "Description": "Fault position along a branch, 0 < Point < 1 (required for branches, NaN for buses)."
        }
      ],
      "Outputs": [
        {
          "Name": "ev",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "EventFault",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The added event (a handle: edit it with ev.edit)."
        }
      ],
      "Signature": "ev = add_fault(obj, target, time, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/add_fault.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add a ground fault on buses, or on branches, from t_start to t_end.",
      "Desc": "A bus fault (\"BG\", the default) holds the voltage of the bus at 0. A branch fault needs\nStatus and Point: \"3LG\" grounds one circuit, \"6LG\" all circuits, at Point along the\nbranch (0 < Point < 1, from the from end 0 to the to end 1; a fault at an end is a fault\nof that bus). The targets are all buses or all branches.\n\nThe fault is an EventFault with a new tag Fault<n>, returned: change it with ev.edit and\nremove it with remove_event(ev.s_tag). It gives two rows per target in tab_event:\n(t_start, Status, Point) and (t_end, \"none\", Point). Bus rows have Point NaN. Two faults of one target may touch but not overlap. \"3LG\" needs a branch of\ntwo or more circuits (GUILDA:Scenario:SingleCircuit).",
      "SeeAlso": [],
      "Examples": "```matlab\nev = sc.add_fault(\"B008\", [0.10, 0.17]);                          % Fault001\nsc.add_fault(\"EL003\", [0.10, 0.17], Status=\"3LG\", Point=0.3);     % one circuit of EL003\n```",
      "Deprecated": ""
    },
    {
      "Name": "gui_content",
      "Defining": "Scenario",
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
      "File": "_GUILDAsystem/_auxiliary/@Scenario/gui_content.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Pages of the GUI of a scenario: \"Events\", \"Offsets\", \"Inputs\" and \"Settings\", then the pages of LayerPackage.",
      "Desc": "- \"Events\", \"Offsets\", \"Inputs\" (\"table\"): tab_event, tab_offset and tab_input, with the\n  lists of names and the values (constants, time series [t, v]) shown as text; a NaN\n  (the Point of a bus or parallel event) shows as an empty cell.\n- \"Settings\" (\"table\"): Time [s] and Description.\n\nA scenario has no parameters, so the GUI shows no Parameter tab.",
      "SeeAlso": [
        "LayerPackage.launch_gui",
        "LayerPackage.gui_content"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "log_edit",
      "Defining": "Scenario",
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
          "Description": ""
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
          "Description": "What was edited (unused)."
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
          "Description": "Kind of edit (unused)."
        }
      ],
      "Outputs": [],
      "Signature": "log_edit(obj, log, tag)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/log_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Do nothing: a scenario is not model data, so editing it makes nothing stale.",
      "Desc": "Overrides LayerPackage.log_edit, which a rename (set.s_tag) calls: renaming a scenario\nreaches no handle_edit of the network (no stale tag, no revision).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "validate",
      "Defining": "Scenario",
      "Group": "Other",
      "Access": "EventBase, PowerNetwork, Scenario",
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
      "Signature": "validate(obj)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/validate.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:Scenario:ReservedTag",
        "GUILDA:Scenario:DuplicateTag"
      ],
      "Summary": "Check every event against the network of the scenario as it is now.",
      "Desc": "(1) Tags: an offset or input tag is not reserved (GUILDA:Scenario:ReservedTag: t1, t2,\nProperties, Row, Variables, empty, NoAction, Fault or Parallel followed by digits), and\neach tag is used by one event only (GUILDA:Scenario:DuplicateTag). (2) The rows of\ntab_event (validate_events). (3) Each row of tab_offset and tab_input\n(validate_disturbance).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "insert_event",
      "Defining": "Scenario",
      "Group": "insert",
      "Access": "PowerNetwork, Scenario",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "ev",
        "l_keepTag"
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
          "Name": "ev",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "EventBase",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Event not in a scenario."
        },
        {
          "Name": "l_keepTag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Keep the tag of a fault, trip or opening."
        }
      ],
      "Outputs": [],
      "Signature": "insert_event(obj, ev, l_keepTag)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/insert_event.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add an event at the end of a_Event and check all events; on an error it is taken out again.",
      "Desc": "Tags: a fault gets Fault<n> and a trip or a branch opening Parallel<n> (%03d, the largest\nnumber of the prefix in use plus one; trips and openings share the numbers), unless\nl_keepTag keeps its tag (add_scenario From, JSON). An offset or an input keeps its tag,\nand an empty tag becomes offset<n> or input<n> (no zero padding). Then validate checks all\nthe events and tags against the network; when a check fails, the event is removed (its\na_Scenario is [] again) and the error is thrown.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "add_from_json_struct",
      "Defining": "Scenario",
      "Group": "add",
      "Access": "PowerNetwork",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sct"
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
          "Name": "sct",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Decoded content of the file (see to_json_struct)."
        }
      ],
      "Outputs": [],
      "Signature": "add_from_json_struct(obj, sct)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/add_from_json_struct.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:Scenario:InvalidEventRows"
      ],
      "Summary": "Set Time and Description and add the events read from scenario/<tag>.json.",
      "Desc": "sct is the decoded file after the checks of PowerNetwork.import (Format, version 2, known\nfields; Event as a cell of structs Tag, Target, Time, Status, Point; Offset and Input as\ncells of structs, a tag at most once in each). The events keep their tags:\n\n- Event: the rows of one tag are one event. Each target of a fault has two rows, the\n  start and the end (\"none\"), and each target of a parallel event one row; all targets\n  have the same times, start Status and (a fault) Point; otherwise\n  GUILDA:Scenario:InvalidEventRows. Fault<n> is an EventFault; Parallel<n> is an\n  EventTrip when its Status is \"open\", else an EventOpenBranch (the Point of a parallel\n  event is not read).\n- Offset, Input: each row is an EventOffset or EventInput. A missing field is passed as\n  an empty value.\n\nEach event is checked as when added by hand; a failing one stops with the error of the\ncheck.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "to_json_struct",
      "Defining": "Scenario",
      "Group": "to",
      "Access": "PowerNetwork",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "sct"
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
          "Name": "sct",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Struct for jsonencode."
        }
      ],
      "Signature": "sct = to_json_struct(obj)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/to_json_struct.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Content of the file scenario/<tag>.json written by net.export.",
      "Desc": "Fields: Format (\"GUILDAscenario\"), version (2), Description, Time, and Event, Offset and\nInput: one object per row of tab_event, tab_offset and tab_input with the column names\nas fields; an empty table, and empty fields of Offset and Input, are left out. Lists\nare cells, so that jsonencode writes an array also for one element. A constant\nInputValue is an array of numbers; a time series is an object with Time (since t_start)\nand Value (one array per point), and its interpolation is InputMethod. The tag of the\nscenario is the file name only.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "compile",
      "Defining": "Scenario",
      "Group": "Other",
      "Access": "PowerNetwork",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sct_dae",
        "time"
      ],
      "OutputNames": [
        "tab_phase",
        "sct_event"
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
          "Description": "Scenario (checked against its network)."
        },
        {
          "Name": "sct_dae",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Data of the run: tab_variable, sv_bus, sv_branch, sv_comp, sv_lc, sv_gc."
        },
        {
          "Name": "time",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Simulation time [t0, tend]."
        }
      ],
      "Outputs": [
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
          "Description": "Phase table (output.phases)."
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
          "Description": "Data of each phase (n_phase x 1)."
        }
      ],
      "Signature": "[tab_phase, sct_event] = compile(obj, sct_dae, time)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/compile.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Build the phases of one run of the scenario (called by PowerNetwork.build_simulation_data).",
      "Desc": "Checks the disturbances against the network as it is now (validate) and splits the\nsimulation time into phases in which the state of the disturbances does not change. The\nphase boundaries are t0, the times of the rows of tab_event, the times of the offsets,\nthe start and end of the inputs, each point after the first of a time series input with\nInputMethod \"zoh\" (so that the input is constant within a phase) and tend; times outside\n(t0, tend) are not boundaries. Without any disturbance, the run has one disturbance\n\"NoAction\" at t0. The disturbances do not change the time.\n\ntab_phase is output.phases: t1, t2 and one logical column per tag (the tags of\ntab_event, then of tab_offset, then of tab_input; a tag of an offset and an input is one\ncolumn), plus NoAction<k> for a phase k without any active disturbance:\n\n     t1 | t2 | Fault001 | Parallel001 | NoAction3\n    ----+----+----------+-------------+----------\n     0  |  1 |    0     |      0      |    0       <- NoAction1 when no disturbance is active\n     1  | .. |    1     |      0      |    0\n\nA fault tag of tab_event is active in a phase whose start t1 is in [first Time, last\nTime) of its rows, a parallel tag from its Time to the end. The state of a target in a\nphase is the Status of its last row with Time <= t1 (faults and parallel events apart;\nat one time an end row before a start row).\n\nsct_event(k) holds what phase k applies, as positions in the data of the run sct_dae\n(the tags are matched here, the solver matches none):\n  t1, t2          [s] start and end of the phase\n  iv_tripComp     tripped components (positions in sct_dae.c_comp)\n  iv_tripGC       tripped global controllers (positions in sct_dae.c_gc)\n  iv_tripLC       tripped local controllers (positions in sct_dae.c_lc)\n  iv_faultBus     faulted buses (positions in sct_dae.sv_bus)\n  tab_branch      branch states other than the default \"none\": the rows\n                  Target, Status, Point of tab_event that set them, by position in\n                  sct_dae.sv_branch, the fault row of a branch before its parallel row\n                  (build_simulation_data makes the admittance matrix of the phase from it)\n  iv_offset, rv_offset  the state offsets added at the start of the phase: rows x of\n                  sct_dae.tab_variable and their values (offsets that start there; all\n                  active offsets in the first phase)\n  c_input         one row {iv_row, rv_t, rm_v, s_method} per active input: the rows u of\n                  tab_variable, the times from the start of the phase (increasing), the\n                  values (one row per time, one column per row) and the interpolation\n                  (\"foh\", \"spline\"; \"zoh\" and a constant value: one point, the value of\n                  the phase)\n  sr_event        tags of the active disturbances",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "blank_record",
      "Defining": "Scenario",
      "Group": "blank",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "tag",
        "time"
      ],
      "OutputNames": [
        "d"
      ],
      "Arguments": [
        {
          "Name": "tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tag of the disturbance."
        },
        {
          "Name": "time",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "TimeSpan: t_start, or [t_start, t_end]."
        }
      ],
      "Outputs": [
        {
          "Name": "d",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag, TimeSpan, OffsetUnit, OffsetState, OffsetValue, InputUnit, InputName, InputValue, InputMethod."
        }
      ],
      "Signature": "d = blank_record(tag, time)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/private/blank_record.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Offset and input record with only a tag and a time span (the columns of tab_offset and tab_input)",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "checkValueCount",
      "Defining": "Scenario",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "c_lbl",
        "s_value",
        "values",
        "s_name",
        "names"
      ],
      "OutputNames": [],
      "Arguments": [],
      "Outputs": [],
      "Signature": "checkValueCount(c_lbl, s_value, values, s_name, names)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/private/checkValueCount.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:Scenario:ValueCountMismatch"
      ],
      "Summary": "One value per name, or a single value for all the names",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "empty_disturbances",
      "Defining": "Scenario",
      "Group": "empty",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [],
      "OutputNames": [
        "tab_event",
        "tab_offset",
        "tab_input"
      ],
      "Arguments": [],
      "Outputs": [
        {
          "Name": "tab_event",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag, Target, Time, Status, Point."
        },
        {
          "Name": "tab_offset",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag, TimeSpan, OffsetUnit, OffsetState, OffsetValue."
        },
        {
          "Name": "tab_input",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag, TimeSpan, InputUnit, InputName, InputValue, InputMethod."
        }
      ],
      "Signature": "[tab_event, tab_offset, tab_input] = empty_disturbances()",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/private/empty_disturbances.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "The three disturbance tables without rows",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_record",
      "Defining": "Scenario",
      "Group": "get",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "tab",
        "k"
      ],
      "OutputNames": [
        "d"
      ],
      "Arguments": [
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
          "Description": "tab_offset or tab_input."
        },
        {
          "Name": "k",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Row."
        }
      ],
      "Outputs": [
        {
          "Name": "d",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Record (see blank_record)."
        }
      ],
      "Signature": "d = get_record(tab, k)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/private/get_record.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Record of row k of tab_offset or tab_input (the columns of tab_offset and tab_input; the others blank)",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "validate_disturbance",
      "Defining": "Scenario",
      "Group": "validate",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "d",
        "s_scenario",
        "net"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "d",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Record (struct with the columns of tab_offset and tab_input, see blank_record)."
        },
        {
          "Name": "s_scenario",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tag of the scenario (for the messages)."
        },
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Network of the scenario, or []."
        }
      ],
      "Outputs": [],
      "Signature": "validate_disturbance(d, s_scenario, net)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/private/validate_disturbance.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:Scenario:InvalidTimeSpan",
        "GUILDA:Scenario:ZeroLengthTimeSpan",
        "GUILDA:Scenario:UnknownOffsetUnit",
        "GUILDA:Scenario:UnknownOffsetState",
        "GUILDA:Scenario:UnknownInputUnit",
        "GUILDA:Scenario:UnknownInputName",
        "GUILDA:Scenario:InvalidInputSeries"
      ],
      "Summary": "Checks of one offset and input record; with net = [], only those without the network.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "validate_events",
      "Defining": "Scenario",
      "Group": "validate",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "tab",
        "s_scenario",
        "net"
      ],
      "OutputNames": [],
      "Arguments": [
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
          "Description": "Rows of tab_event (Tag, Target, Time, Status, Point)."
        },
        {
          "Name": "s_scenario",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tag of the scenario (for the messages)."
        },
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "PowerNetwork",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Network of the scenario."
        }
      ],
      "Outputs": [],
      "Signature": "validate_events(tab, s_scenario, net)",
      "File": "_GUILDAsystem/_auxiliary/@Scenario/private/validate_events.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:Scenario:UnknownFaultTarget",
        "GUILDA:Scenario:MixedFaultTarget",
        "GUILDA:Scenario:UnknownParallelTarget",
        "GUILDA:Scenario:InvalidEventRows",
        "GUILDA:Scenario:InvalidTimeSpan",
        "GUILDA:Scenario:ZeroLengthTimeSpan",
        "GUILDA:Scenario:InvalidFaultStatus",
        "GUILDA:Scenario:InvalidPoint",
        "GUILDA:Scenario:SingleCircuit",
        "GUILDA:Scenario:OverlappingEvents"
      ],
      "Summary": "Checks of the rows of tab_event against the network (see the Events of the Scenario help).",
      "Desc": "Per tag: the targets are known (a fault: buses or branches, not both; a parallel event:\ncomponents, local or global controllers, or branches), each target of a fault has two\nrows (the start, then the end) with t_start < t_end and each target of a parallel event\none row, and the Status and Point of the rows fit the kind of the target; \"3LG\" and\n\"3open\" need a branch of two or more circuits. Over the table: two faults of one target\ndo not overlap (touching is allowed), and a target has at most one parallel event (it\nlasts to the end of the simulation).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "handle_edit",
      "Defining": "LayerPackage",
      "Group": "handle",
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
          "Description": "Layer on the path from the edited layer to the top."
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
          "Description": "Kind of edit (see log_edit)."
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
          "Description": "Message: tag of the edited layer, \": \", what was edited (see log_edit)."
        }
      ],
      "Outputs": [],
      "Signature": "handle_edit(obj, a_layer, tag, log)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/handle_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Hook for an edit of a_layer, called by log_edit on every layer from the edited",
      "Desc": "layer up to the top. Does nothing here; subclasses override it to append the message\nto their own stale tags (sct_stale).",
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
      "Name": "doc",
      "Defining": "LayerPackage",
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
          "Description": "Layer whose class page is opened."
        }
      ],
      "Outputs": [],
      "Signature": "doc(obj)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/doc.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Open the class reference page of the layer's class.",
      "Desc": "Opens the GUILDA class reference (English page) of class(obj) in the browser, as\nGUILDA.doc(\"class\", class(obj)). doc with a class name (doc PowerNetwork) is\nMATLAB's doc.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet.doc()             % page of the network class\nnet.a_Bus{1}.doc()    % page of the class of the first bus\ndoc(net)              % same as net.doc()\n```",
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
