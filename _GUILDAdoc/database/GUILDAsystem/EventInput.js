(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["EventInput"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "EventInput",
  "properties": [
    {
      "Name": "s_unit",
      "Defining": "EventInput",
      "Group": "Input",
      "GetAccess": "public",
      "SetAccess": "EventBase",
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
      "File": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
      "Line": 22,
      "Summary": "Tag of the component.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_name",
      "Defining": "EventInput",
      "Group": "Input",
      "GetAccess": "public",
      "SetAccess": "EventBase",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(0,1)",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
      "Line": 23,
      "Summary": "Names of the inputs (e.g. \"Pmech\").",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_value",
      "Defining": "EventInput",
      "Group": "Input",
      "GetAccess": "public",
      "SetAccess": "EventBase",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,1)",
      "Validation": {
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
      "Line": 24,
      "Summary": "Constants (a column: one per input or one for all), or a time series [t, v_1, ..., v_n].",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rr_time",
      "Defining": "EventInput",
      "Group": "Input",
      "GetAccess": "public",
      "SetAccess": "EventBase",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[0, 0]",
      "Validation": {
        "Class": "double",
        "Size": "(1,2)",
        "Validators": []
      },
      "Unit": "s",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
      "Line": 25,
      "Summary": "[t_start, t_end] of the input.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_method",
      "Defining": "EventInput",
      "Group": "Input",
      "GetAccess": "public",
      "SetAccess": "EventBase",
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
      "File": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
      "Line": 26,
      "Summary": "Interpolation of a time series: \"zoh\", \"foh\" or \"spline\"; \"\" for constants.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_prefix",
      "Defining": "EventInput",
      "Group": "Kind",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"input\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
      "Line": 30,
      "Summary": "Prefix of the automatic tag.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_table",
      "Defining": "EventInput",
      "Group": "Kind",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"input\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
      "Line": 31,
      "Summary": "Table the event contributes to.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_tag",
      "Defining": "EventBase",
      "Group": "Identity",
      "GetAccess": "public",
      "SetAccess": "EventBase, Scenario",
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
      "File": "_GUILDAsystem/_auxiliary/@EventBase/EventBase.m",
      "Line": 38,
      "Summary": "Tag in the scenario (Fault<n>, Parallel<n>, or the tag of an offset or input); \"\" until the event is added.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_Scenario",
      "Defining": "EventBase",
      "Group": "Layer structure",
      "GetAccess": "public",
      "SetAccess": "EventBase, Scenario",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventBase/EventBase.m",
      "Line": 42,
      "Summary": "Scenario that holds the event ([] for an event not in a scenario).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "Scenario",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "EventInput",
      "Defining": "EventInput",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "unit",
        "name",
        "value",
        "time",
        "opt"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
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
          "Name": "obj",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The new event."
        }
      ],
      "Signature": "obj = EventInput(unit, name, value, time, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/EventInput.m",
      "Line": 35,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create an input event (not in a scenario).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "table_rows",
      "Defining": "EventInput",
      "Group": "table",
      "Access": "EventBase, Scenario",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
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
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One row."
        }
      ],
      "Signature": "tab = table_rows(obj)",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/table_rows.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "EventBase",
      "Throws": [],
      "Summary": "Row of tab_input: (Tag, TimeSpan, InputUnit, InputName, InputValue, InputMethod).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "edit",
      "Defining": "EventInput",
      "Group": "Other",
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
          "Name": "Unit",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag of the component. Default: obj.s_unit."
        },
        {
          "Name": "Name",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Names of the inputs (e.g. \"Pmech\"). Default: obj.sv_name."
        },
        {
          "Name": "Value",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeA(opt.Value, [\"double\",\"table\"])"
          ],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Constants, or a time series [t, v_1, ..., v_n] or table. Default: obj.rm_value."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "[t_start, t_end] of the input. Default: obj.rr_time."
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
          "Description": "Interpolation of a time series: \"zoh\", \"foh\" or \"spline\". Default: obj.s_method."
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
          "Description": "Tag of the input (not Fault or Parallel followed by digits). Default: obj.s_tag."
        }
      ],
      "Outputs": [],
      "Signature": "edit(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "EventBase",
      "Throws": [],
      "Summary": "Change the input: the options of add_input, each optional (one not given keeps its value).",
      "Desc": "Value given without Method sets the method again from the value (\"foh\" for a time\nseries, none for a constant). Method alone applies to the stored value (a constant stops\nwith GUILDA:EventInput:MethodWithoutSeries). In a scenario, all its events are checked\nagain (the tag too); when a check fails, the input gets back its values and the error is\nthrown.",
      "SeeAlso": [],
      "Examples": "```matlab\nev = sc.add_input(\"B002SG1\", \"Pmech\", [0, 0; 2, 0.02], [1, 3]);\nev.edit(Method=\"zoh\");\nev.edit(Value=0.05, Time=[1, 1.5]);\n```",
      "Deprecated": ""
    },
    {
      "Name": "normalize_input",
      "Defining": "EventInput",
      "Group": "normalize",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "value",
        "sv_name",
        "s_method",
        "c_lbl"
      ],
      "OutputNames": [
        "value",
        "s_method"
      ],
      "Arguments": [
        {
          "Name": "value",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Constants, a time series [t, v_1, ..., v_n], or a table."
        },
        {
          "Name": "sv_name",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Names of the inputs."
        },
        {
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Interpolation given (\"\" for none)."
        },
        {
          "Name": "c_lbl",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "cell",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "{tag, scenario} for the messages."
        }
      ],
      "Outputs": [
        {
          "Name": "value",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Constant column or time series matrix."
        },
        {
          "Name": "s_method",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "\"zoh\", \"foh\", \"spline\", or \"\" for a constant."
        }
      ],
      "Signature": "[value, s_method] = normalize_input(value, sv_name, s_method, c_lbl)",
      "File": "_GUILDAsystem/_auxiliary/@EventInput/private/normalize_input.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:EventInput:InvalidInputTable",
        "GUILDA:EventInput:MethodWithoutSeries"
      ],
      "Summary": "Input value as stored: a constant column, or a time series [t, v_1, ..., v_n] with its method.",
      "Desc": "A table (variables Time and the input names, in any order) becomes the matrix of its\ncolumns in the order of sv_name. A numeric matrix, or a row of 1 + n_name values, is a\nseries; any other numeric value is a constant. A series without a method takes \"foh\"; a\nmethod given for a constant stops with GUILDA:EventInput:MethodWithoutSeries. The values\nof a series are checked by the scenario (validate_disturbance).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "apply_edit",
      "Defining": "EventBase",
      "Group": "apply",
      "Access": "protected",
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
          "Description": "New values by property name."
        }
      ],
      "Outputs": [],
      "Signature": "apply_edit(obj, sct)",
      "File": "_GUILDAsystem/_auxiliary/@EventBase/apply_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Set the properties of sct, check the scenario of the event, and undo them on an error.",
      "Desc": "The common part of the edit methods: the old values of the fields of sct are kept, the\nnew ones set, and Scenario.validate checks all the events of the scenario (with their\ntags) against its network. When a check fails, the old values are set back and the\nerror is thrown. An event not in a scenario is not checked here.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "copyElement",
      "Defining": "EventBase",
      "Group": "Other",
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
        "cp"
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
          "Name": "cp",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The copy."
        }
      ],
      "Signature": "cp = copyElement(obj)",
      "File": "_GUILDAsystem/_auxiliary/@EventBase/copyElement.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Copy of the event (copy(ev)): the same values and tag, not in a scenario (a_Scenario []).",
      "Desc": "",
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
