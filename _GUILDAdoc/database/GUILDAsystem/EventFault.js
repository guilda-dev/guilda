(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["EventFault"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "EventFault",
  "properties": [
    {
      "Name": "sv_target",
      "Defining": "EventFault",
      "Group": "Fault",
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
      "File": "_GUILDAsystem/_auxiliary/@EventFault/EventFault.m",
      "Line": 23,
      "Summary": "Tags of the faulted buses, or of the faulted branches (repeated ones once).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rr_time",
      "Defining": "EventFault",
      "Group": "Fault",
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
      "File": "_GUILDAsystem/_auxiliary/@EventFault/EventFault.m",
      "Line": 24,
      "Summary": "[t_start, t_end] of the fault.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_status",
      "Defining": "EventFault",
      "Group": "Fault",
      "GetAccess": "public",
      "SetAccess": "EventBase",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"BG\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventFault/EventFault.m",
      "Line": 25,
      "Summary": "\"BG\" (buses), \"3LG\" or \"6LG\" (branches).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_point",
      "Defining": "EventFault",
      "Group": "Fault",
      "GetAccess": "public",
      "SetAccess": "EventBase",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "NaN",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventFault/EventFault.m",
      "Line": 26,
      "Summary": "Fault position along a branch, 0 < r_point < 1 (NaN for buses).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_prefix",
      "Defining": "EventFault",
      "Group": "Kind",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"Fault\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventFault/EventFault.m",
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
      "Defining": "EventFault",
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
      "File": "_GUILDAsystem/_auxiliary/@EventFault/EventFault.m",
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
      "Name": "EventFault",
      "Defining": "EventFault",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "target",
        "time",
        "opt"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
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
      "Signature": "obj = EventFault(target, time, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@EventFault/EventFault.m",
      "Line": 35,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a fault event (not in a scenario).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "table_rows",
      "Defining": "EventFault",
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
      "File": "_GUILDAsystem/_auxiliary/@EventFault/table_rows.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "EventBase",
      "Throws": [],
      "Summary": "Rows of tab_event: per target (t_start, Status, Point) and (t_end, \"none\", Point).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "edit",
      "Defining": "EventFault",
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
          "Name": "Target",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the faulted buses, or of the faulted branches. Default: obj.sv_target."
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
          "Description": "[t_start, t_end] of the fault. Default: obj.rr_time."
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
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "\"BG\" for buses; \"3LG\" or \"6LG\" for branches. Default: obj.s_status."
        },
        {
          "Name": "Point",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Fault position along a branch, 0 < Point < 1 (NaN for buses). Default: obj.r_point."
        }
      ],
      "Outputs": [],
      "Signature": "edit(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@EventFault/edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "EventBase",
      "Throws": [],
      "Summary": "Change the fault: the options of add_fault, each optional (one not given keeps its value).",
      "Desc": "In a scenario, all its events are checked again; when a check fails, the fault gets\nback its values and the error is thrown.",
      "SeeAlso": [],
      "Examples": "```matlab\nev = sc.add_fault(\"B008\", [0.10, 0.17]);\nev.edit(Time=[0.10, 0.20]);\nev.edit(Target=\"EL003\", Status=\"3LG\", Point=0.3);\n```",
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
