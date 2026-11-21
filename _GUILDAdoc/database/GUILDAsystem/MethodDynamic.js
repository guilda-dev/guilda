(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["MethodDynamic"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "MethodDynamic",
  "properties": [
    {
      "Name": "Y",
      "Defining": "MethodDynamic",
      "Group": "Settings",
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
        "Class": "double",
        "Size": "(:,:)",
        "Validators": []
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
      "Line": 34,
      "Summary": "Bus admittance matrix (complex, in the bus order of PFcondition).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "PFcondition",
      "Defining": "MethodDynamic",
      "Group": "Settings",
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
        "Class": "table",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
      "Line": 35,
      "Summary": "Power flow conditions of the buses (rows of Bus.get_pf_condition).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Mass",
      "Defining": "MethodDynamic",
      "Group": "Settings",
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
        "Validators": [
          "mustBeNonnegative"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
      "Line": 36,
      "Summary": "Mass M of the virtual bus dynamics (0: first order).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Damper",
      "Defining": "MethodDynamic",
      "Group": "Settings",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "1",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": [
          "mustBePositive"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
      "Line": 37,
      "Summary": "Damping D of the virtual bus dynamics (with Mass 0, it only scales the virtual time).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "foh_PQ",
      "Defining": "MethodDynamic",
      "Group": "Settings",
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
        "Validators": [
          "mustBeNonnegative"
        ]
      },
      "Unit": "s",
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
      "Line": 38,
      "Summary": "Ramp time of the specified P and Q (0: step).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Tolerance",
      "Defining": "MethodDynamic",
      "Group": "Settings",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "1e-8",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": [
          "mustBePositive"
        ]
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
      "Line": 39,
      "Summary": "Largest P/Q mismatch for convergence.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_iter",
      "Defining": "MethodDynamic",
      "Group": "Live display",
      "GetAccess": "MethodDynamic, SolverPF",
      "SetAccess": "MethodDynamic, SolverPF",
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
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
      "Line": 43,
      "Summary": "Called at each ODE step as stop = f_iter(Y, t, state) (Y = [theta; omega; V; u], t the virtual time, state \"init\", \"iter\" or \"done\"; PlotFcn and Progress of SolverPF); [] for none. A true stop ends solve with flag -1.",
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
      "Defining": "MethodDynamic",
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
        "cv_Vbus",
        "flag",
        "output",
        "cm_Vhistory",
        "rv_step"
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
          "Name": "cv_Vbus",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Complex bus voltages at the end of the integration."
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
          "Description": "1 converged, 0 virtual time limit reached, -2 voltage collapse, angle instability or integration failure."
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
          "Description": "Details: iterations, algorithm, residual, message."
        },
        {
          "Name": "cm_Vhistory",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Complex bus voltages at each ODE step (n_bus x n_step)."
        },
        {
          "Name": "rv_step",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Virtual times of the ODE steps."
        }
      ],
      "Signature": "[cv_Vbus, flag, output, cm_Vhistory, rv_step] = solve(obj)",
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/solve.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Integrate the virtual bus dynamics until they settle at the power flow solution (see the",
      "Desc": "class help). cm_Vhistory holds the bus voltages at each ODE step (n_bus x n_step),\nrv_step the virtual times.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "MethodDynamic",
      "Defining": "MethodDynamic",
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
          "Name": "opt",
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
          "Name": "obj",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Virtual bus dynamics."
        }
      ],
      "Signature": "obj = MethodDynamic(opt)",
      "File": "_GUILDAsystem/_auxiliary/@MethodDynamic/MethodDynamic.m",
      "Line": 47,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create the virtual bus dynamics; the Name-Value options are the public properties.",
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
