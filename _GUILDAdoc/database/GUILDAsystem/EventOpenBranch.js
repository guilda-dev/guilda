(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["EventOpenBranch"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "EventOpenBranch",
  "properties": [
    {
      "Name": "sv_branch",
      "Defining": "EventOpenBranch",
      "Group": "Opening",
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
      "File": "_GUILDAsystem/_auxiliary/@EventOpenBranch/EventOpenBranch.m",
      "Line": 19,
      "Summary": "Tags of the opened branches.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_time",
      "Defining": "EventOpenBranch",
      "Group": "Opening",
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
      "File": "_GUILDAsystem/_auxiliary/@EventOpenBranch/EventOpenBranch.m",
      "Line": 20,
      "Summary": "Time of the opening.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_status",
      "Defining": "EventOpenBranch",
      "Group": "Opening",
      "GetAccess": "public",
      "SetAccess": "EventBase",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"6open\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventOpenBranch/EventOpenBranch.m",
      "Line": 21,
      "Summary": "\"6open\" (all circuits) or \"3open\" (one circuit).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_prefix",
      "Defining": "EventOpenBranch",
      "Group": "Kind",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"Parallel\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventOpenBranch/EventOpenBranch.m",
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
      "Defining": "EventOpenBranch",
      "Group": "Kind",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"event\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventOpenBranch/EventOpenBranch.m",
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
      "Name": "EventOpenBranch",
      "Defining": "EventOpenBranch",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "branch",
        "time",
        "opt"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
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
      "Signature": "obj = EventOpenBranch(branch, time, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@EventOpenBranch/EventOpenBranch.m",
      "Line": 30,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a branch opening event (not in a scenario).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "table_rows",
      "Defining": "EventOpenBranch",
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
          "Description": "Tag, Target, Time, Status, Point."
        }
      ],
      "Signature": "tab = table_rows(obj)",
      "File": "_GUILDAsystem/_auxiliary/@EventOpenBranch/table_rows.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "EventBase",
      "Throws": [],
      "Summary": "Rows of tab_event: per branch (t, Status, NaN).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "edit",
      "Defining": "EventOpenBranch",
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
          "Name": "Branch",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the branches (see string(net.a_Branch)). Default: obj.sv_branch."
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
          "Description": "Time of the opening. Default: obj.r_time."
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
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "All circuits or one circuit. Default: obj.s_status."
        }
      ],
      "Outputs": [],
      "Signature": "edit(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@EventOpenBranch/edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "EventBase",
      "Throws": [],
      "Summary": "Change the opening: the options of add_open_branch, each optional (one not given keeps its value).",
      "Desc": "In a scenario, all its events are checked again; when a check fails, the opening gets\nback its values and the error is thrown.",
      "SeeAlso": [],
      "Examples": "```matlab\nev = sc.add_open_branch(\"EL003\", 0.17);\nev.edit(Time=0.2, Status=\"3open\");\n```",
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
