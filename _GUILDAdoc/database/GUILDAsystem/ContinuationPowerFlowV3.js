(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["ContinuationPowerFlowV3"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "ContinuationPowerFlowV3",
  "properties": [
    {
      "Name": "CPFBus",
      "Defining": "ContinuationPowerFlowV3",
      "Group": "Options",
      "GetAccess": "public",
      "SetAccess": "public",
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
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 24,
      "Summary": "Tags of the buses whose loads are scaled (LoadBus).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "CPFInitLam",
      "Defining": "ContinuationPowerFlowV3",
      "Group": "Options",
      "GetAccess": "public",
      "SetAccess": "public",
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
      "Unit": "",
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 25,
      "Summary": "lambda at the starting point (InitialLambda).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "CPFMaxIter",
      "Defining": "ContinuationPowerFlowV3",
      "Group": "Options",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "500",
      "Validation": {
        "Class": "",
        "Size": "(1,1)",
        "Validators": [
          "mustBePositive"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 26,
      "Summary": "Maximum number of predictor-corrector steps (MaxIteration).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "CPFStepSize",
      "Defining": "ContinuationPowerFlowV3",
      "Group": "Options",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "0.5",
      "Validation": {
        "Class": "",
        "Size": "(1,1)",
        "Validators": [
          "mustBePositive"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 27,
      "Summary": "Step size of the predictor (StepSize).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "CPFArcL",
      "Defining": "ContinuationPowerFlowV3",
      "Group": "Options",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "10^-3",
      "Validation": {
        "Class": "",
        "Size": "(1,1)",
        "Validators": [
          "mustBePositive"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 28,
      "Summary": "Arc length of the corrector (ArcLength).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "CPFUseInternal",
      "Defining": "ContinuationPowerFlowV3",
      "Group": "Options",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "false",
      "Validation": {
        "Class": "logical",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 29,
      "Summary": "Solve with the internal states of the generators (UseInternalState).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "CPFNet",
      "Defining": "ContinuationPowerFlowV3",
      "Group": "Result",
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
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 32,
      "Summary": "Network to analyse.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "CPF_Result",
      "Defining": "ContinuationPowerFlowV3",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct(\"x_sol\", [], \"x_prd\", [], \"result\", [])",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 33,
      "Summary": "Result of the last solve: x_sol, x_prd and the ResultCPF.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "solve",
      "Defining": "ContinuationPowerFlowV3",
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
      "OutputNames": [
        "sol",
        "sol_pred"
      ],
      "Arguments": [],
      "Outputs": [
        {
          "Name": "sol",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Solutions along the path (full variable layout, lambda in the last row)."
        },
        {
          "Name": "sol_pred",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Predicted points along the path, in the same layout."
        }
      ],
      "Signature": "[sol, sol_pred] = solve(obj)",
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/solve.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Run net.calculate_continuation_powerflow with the v3 options.",
      "Desc": "The result is also stored in CPF_Result.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "ContinuationPowerFlowV3",
      "Defining": "ContinuationPowerFlowV3",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "net",
        "opt"
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
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Network to analyse."
        },
        {
          "Name": "CPFBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the buses whose loads are scaled."
        },
        {
          "Name": "CPFInitLam",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "lambda at the starting point."
        },
        {
          "Name": "CPFMaxIter",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Maximum number of predictor-corrector steps."
        },
        {
          "Name": "CPFStepSize",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Step size of the predictor."
        },
        {
          "Name": "CPFArcL",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Arc length of the corrector."
        },
        {
          "Name": "CPFUseInternal",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Solve with the internal states of the generators."
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
          "Description": "v3 view of the continuation power flow."
        }
      ],
      "Signature": "obj = ContinuationPowerFlowV3(net, Name=Value)",
      "File": "_GUILDAsystem/_VersionSupport/@ContinuationPowerFlowV3/ContinuationPowerFlowV3.m",
      "Line": 37,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create the v3 view for a network with the given v3 options.",
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
