(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["EventOffset"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "EventOffset",
  "properties": [
    {
      "Name": "s_unit",
      "Defining": "EventOffset",
      "Group": "Offset",
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
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m",
      "Line": 18,
      "Summary": "Tag of the component whose states are offset.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_state",
      "Defining": "EventOffset",
      "Group": "Offset",
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
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m",
      "Line": 19,
      "Summary": "Names of the states (e.g. \"delta\").",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_value",
      "Defining": "EventOffset",
      "Group": "Offset",
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
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m",
      "Line": 20,
      "Summary": "Offsets, one per state or one for all.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_time",
      "Defining": "EventOffset",
      "Group": "Offset",
      "GetAccess": "public",
      "SetAccess": "EventBase",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "0",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "s",
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m",
      "Line": 21,
      "Summary": "Time of the offset.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_prefix",
      "Defining": "EventOffset",
      "Group": "Kind",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"offset\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m",
      "Line": 25,
      "Summary": "Prefix of the automatic tag.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_table",
      "Defining": "EventOffset",
      "Group": "Kind",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"offset\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m",
      "Line": 26,
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
      "Name": "EventOffset",
      "Defining": "EventOffset",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "unit",
        "state",
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
      "Signature": "obj = EventOffset(unit, state, value, time, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/EventOffset.m",
      "Line": 30,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create an offset event (not in a scenario).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "table_rows",
      "Defining": "EventOffset",
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
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/table_rows.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "EventBase",
      "Throws": [],
      "Summary": "Row of tab_offset: (Tag, TimeSpan, OffsetUnit, OffsetState, OffsetValue).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "edit",
      "Defining": "EventOffset",
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
          "Name": "State",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Names of the states (e.g. \"delta\"). Default: obj.sv_state."
        },
        {
          "Name": "Value",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Offsets, one per state or one for all. Default: obj.rv_value."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time of the offset. Default: obj.r_time."
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
          "Description": "Tag of the offset (not Fault or Parallel followed by digits). Default: obj.s_tag."
        }
      ],
      "Outputs": [],
      "Signature": "edit(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@EventOffset/edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "EventBase",
      "Throws": [],
      "Summary": "Change the offset: the options of add_offset, each optional (one not given keeps its value).",
      "Desc": "In a scenario, all its events are checked again (the tag too); when a check fails, the\noffset gets back its values and the error is thrown.",
      "SeeAlso": [],
      "Examples": "```matlab\nev = sc.add_offset(\"B001SG1\", \"delta\", 0.1, 0);\nev.edit(Value=0.2, Time=1, Tag=\"kick\");\n```",
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
    },
    {
      "Name": "doc",
      "Defining": "auxiliary",
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
          "Description": "Object whose class page is opened."
        }
      ],
      "Outputs": [],
      "Signature": "doc(obj)",
      "File": "_GUILDAsystem/_auxiliary/@auxiliary/doc.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Open the class reference page of the object's class.",
      "Desc": "Opens the GUILDA class reference (English page) of class(obj) in the browser, as\nGUILDA.doc(\"class\", class(obj)). doc with a class name (doc ResultPF) is MATLAB's\ndoc.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nres = net.calculate_powerflow();\nres.doc()                       % page of ResultPF\ndoc(res)                        % same as res.doc()\nsc = net.add_scenario(\"CASE1\");\nsc.doc()                        % page of Scenario\n```",
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
