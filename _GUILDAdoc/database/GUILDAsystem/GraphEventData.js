(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["GraphEventData"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "GraphEventData",
  "properties": [
    {
      "Name": "Tag",
      "Defining": "GraphEventData",
      "Group": "SetAccess = private",
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
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/GraphEventData.m",
      "Line": 18,
      "Summary": "Tag of the element.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Kind",
      "Defining": "GraphEventData",
      "Group": "SetAccess = private",
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
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/GraphEventData.m",
      "Line": 19,
      "Summary": "Kind of the element (e.g. \"bus\", \"node\").",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Index",
      "Defining": "GraphEventData",
      "Group": "SetAccess = private",
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
        "Class": "double",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/GraphEventData.m",
      "Line": 20,
      "Summary": "Position of the element in the vectors of its kind.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "GraphEventData",
      "Defining": "GraphEventData",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "s_tag",
        "s_kind",
        "i_index"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
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
          "Description": "Tag of the element."
        },
        {
          "Name": "s_kind",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Kind of the element."
        },
        {
          "Name": "i_index",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Position in the vectors of its kind."
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
          "Description": "The event data."
        }
      ],
      "Signature": "obj = GraphEventData(s_tag, s_kind, i_index)",
      "File": "_GUILDAsystem/_auxiliary/GraphEventData.m",
      "Line": 24,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Event data of a clicked element.",
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
