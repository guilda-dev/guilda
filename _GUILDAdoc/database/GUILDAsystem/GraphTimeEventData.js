(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["GraphTimeEventData"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "GraphTimeEventData",
  "properties": [
    {
      "Name": "Time",
      "Defining": "GraphTimeEventData",
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
      "Unit": "s",
      "File": "_GUILDAsystem/_auxiliary/GraphTimeEventData.m",
      "Line": 20,
      "Summary": "Time of the sample shown.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Index",
      "Defining": "GraphTimeEventData",
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
      "File": "_GUILDAsystem/_auxiliary/GraphTimeEventData.m",
      "Line": 21,
      "Summary": "Index of the sample shown (i_time of the graph).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "GraphTimeEventData",
      "Defining": "GraphTimeEventData",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "t",
        "k"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "t",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time of the sample."
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
          "Description": "Index of the sample."
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
      "Signature": "obj = GraphTimeEventData(t, k)",
      "File": "_GUILDAsystem/_auxiliary/GraphTimeEventData.m",
      "Line": 25,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Event data of the sample shown.",
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
