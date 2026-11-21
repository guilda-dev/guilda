(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["EventBase"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "EventBase",
  "properties": [
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
    },
    {
      "Name": "s_prefix",
      "Defining": "EventBase",
      "Group": "Kind",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": true,
      "Hidden": true,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventBase/EventBase.m",
      "Line": 46,
      "Summary": "Prefix of the automatic tag: \"Fault\", \"Parallel\", \"offset\" or \"input\".",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_table",
      "Defining": "EventBase",
      "Group": "Kind",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": true,
      "Hidden": true,
      "Transient": false,
      "HasDefault": false,
      "DefaultCode": "",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@EventBase/EventBase.m",
      "Line": 47,
      "Summary": "Table the event contributes to: \"event\", \"offset\" or \"input\".",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "edit",
      "Defining": "EventBase",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [],
      "Arguments": [],
      "Outputs": [],
      "Signature": "edit(obj, opt)",
      "File": "_GUILDAsystem/_auxiliary/@EventBase/EventBase.m",
      "Line": 54,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Change the event: the options of its add_* method, each optional (an option not",
      "Desc": "given keeps its value). The scenario of the event checks all its events again;\nwhen a check fails, the event gets back its values and the error is thrown.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "table_rows",
      "Defining": "EventBase",
      "Group": "table",
      "Access": "EventBase, Scenario",
      "Static": false,
      "Abstract": true,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "tab"
      ],
      "Arguments": [],
      "Outputs": [],
      "Signature": "tab = table_rows(obj)",
      "File": "_GUILDAsystem/_auxiliary/@EventBase/EventBase.m",
      "Line": 59,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Rows of the event in its table (s_table), with the columns of that table.",
      "Desc": "",
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
    },
    {
      "Name": "EventBase",
      "Defining": "EventBase",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [],
      "Outputs": [],
      "Signature": "obj = EventBase()",
      "File": "",
      "Line": 0,
      "ImplementedIn": "",
      "Overrides": "",
      "Throws": [],
      "Summary": "",
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
