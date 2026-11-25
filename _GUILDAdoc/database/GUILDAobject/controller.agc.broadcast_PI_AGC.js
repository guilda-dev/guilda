(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["controller.agc.broadcast_PI_AGC"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "controller.agc.broadcast_PI_AGC",
  "properties": [
    {
      "Name": "key",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"agc-PI\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/broadcast_PI_AGC.m",
      "Line": 50,
      "Summary": "Model key that selects this class in `PowerNetwork.add_global_controller`.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_role",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"agc\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/broadcast_PI_AGC.m",
      "Line": 51,
      "Summary": "Role of the controller (automatic generation control).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_x",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"xi\"",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/broadcast_PI_AGC.m",
      "Line": 52,
      "Summary": "Names of the states.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_u",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"omega\"",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/broadcast_PI_AGC.m",
      "Line": 53,
      "Summary": "Names of the inputs, one per controlled generator.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_y",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"Pmech\"",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/broadcast_PI_AGC.m",
      "Line": 54,
      "Summary": "Names of the outputs, one per controlled generator.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_para",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[\"alpha\",\"beta\",\"kP\",\"kI\"]",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/broadcast_PI_AGC.m",
      "Line": 55,
      "Summary": "Names of the dynamic parameters passed to the model functions.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_Mass",
      "Defining": "GlobalController",
      "Group": "Cached function handles",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 74,
      "Summary": "Mass matrix function @(t,x,V,u) with the parameters bound.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_dx",
      "Defining": "GlobalController",
      "Group": "Cached function handles",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 75,
      "Summary": "State equation function @(t,x,V,u) with the parameters bound.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_Y",
      "Defining": "GlobalController",
      "Group": "Cached function handles",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 76,
      "Summary": "Output function @(t,x,V,u) with the parameters bound.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_JacobiDx",
      "Defining": "GlobalController",
      "Group": "Cached function handles",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 77,
      "Summary": "Jacobian function of f_dx.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_JacobiY",
      "Defining": "GlobalController",
      "Group": "Cached function handles",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 78,
      "Summary": "Jacobian function of f_Y.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_PowerNetwork",
      "Defining": "GlobalController",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "PowerNetwork",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 81,
      "Summary": "PowerNetwork the controller belongs to (set by add_global_controller).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "PowerNetwork",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "controlledUnits",
      "Defining": "GlobalController",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 84,
      "Summary": "Controlled components, in the order given to the constructor.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "iv_obsY",
      "Defining": "GlobalController",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,1)",
      "Validation": {
        "Class": "double",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 85,
      "Summary": "Index in sv_y of its unit of each input (0: not read from sv_y), units in order.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "iv_obsX",
      "Defining": "GlobalController",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,1)",
      "Validation": {
        "Class": "double",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 86,
      "Summary": "Index in sv_x of its unit of each input (0: not read from sv_x), units in order.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_odefcnHz",
      "Defining": "GlobalController",
      "Group": "Cached function handles",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "Hz",
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 89,
      "Summary": "Network frequency bound into the f_* handles (empty: never built).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_Xequilibrium",
      "Defining": "GlobalController",
      "Group": "Steady State",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 92,
      "Summary": "State equilibrium (from get_equilibrium, set by PowerNetwork.initialize).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_Uequilibrium",
      "Defining": "GlobalController",
      "Group": "Steady State",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 93,
      "Summary": "Equilibrium of the inputs (the observed outputs or states), one entry per input of each unit.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "parent",
      "Defining": "GlobalController",
      "Group": "Layer Structure",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 96,
      "Summary": "Parent in the layer structure: the network.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "children",
      "Defining": "GlobalController",
      "Group": "Layer Structure",
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
      "File": "_GUILDAsystem/@GlobalController/GlobalController.m",
      "Line": 97,
      "Summary": "Children in the layer structure: none.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_parameter",
      "Defining": "PowerSystemModel",
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
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 18,
      "Summary": "Parameter table: the a_Parameter tables side by side; writing it writes the changed parameters.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_Parameter",
      "Defining": "PowerSystemModel",
      "Group": "Parameter",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "cell(0,1)",
      "Validation": {
        "Class": "cell",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 21,
      "Summary": "Parameter containers, one per column of tab_parameter (column name: the s_tag of the container).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "Parameter cell array (Nx1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_parameterCache",
      "Defining": "PowerSystemModel",
      "Group": "Parameter",
      "GetAccess": "LayerPackage",
      "SetAccess": "LayerPackage",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": true,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 24,
      "Summary": "tab_parameter built by its getter; [] when an edit (a store or a rename of a container, a new a_Parameter) made it out of date.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table",
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
      "Line": 67,
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
      "Line": 70,
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
      "Line": 75,
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
      "Name": "broadcast_PI_AGC",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "Constructor",
      "Access": "PowerNetwork",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "net",
        "tag",
        "varargin",
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
          "Description": "PowerNetwork that contains the controlled generators."
        },
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
          "Description": "Number of the tag; the controller tag is the network tag + \"AGC\" + tag."
        },
        {
          "Name": "varargin",
          "Kind": "Repeating",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Controlled generators, each a generator object or its tag."
        },
        {
          "Name": "alpha",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "1",
          "Required": false,
          "Unit": "pu",
          "Description": "Share of the command for each controlled generator; a scalar applies to all."
        },
        {
          "Name": "beta",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "1",
          "Required": false,
          "Unit": "pu",
          "Description": "Weight of each generator's frequency deviation; a scalar applies to all."
        },
        {
          "Name": "kP",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "100",
          "Required": false,
          "Unit": "pu",
          "Description": "Proportional gain."
        },
        {
          "Name": "kI",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "500",
          "Required": false,
          "Unit": "1/s",
          "Description": "Integral gain."
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
          "Description": "broadcast_PI_AGC object."
        }
      ],
      "Signature": "obj = controller.agc.broadcast_PI_AGC(net, tag, varargin, Name=Value)",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/broadcast_PI_AGC.m",
      "Line": 59,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [
        "GUILDA:broadcast_PI_AGC:InvalidSize"
      ],
      "Summary": "Create the AGC with the tag net tag + \"AGC\" + tag for the generators given after the tag.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "Jacobi_Y",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "Jacobi",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "t",
        "x",
        "V",
        "u",
        "param",
        "omega0"
      ],
      "OutputNames": [
        "Cyx",
        "Dyv",
        "Dyu"
      ],
      "Arguments": [
        {
          "Name": "t",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time (unused)."
        },
        {
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu*s",
          "Description": "Integral `xi` of the weighted frequency deviation."
        },
        {
          "Name": "V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Voltages of all buses `[Vre1; Vim1; Vre2; ...]` (unused)."
        },
        {
          "Name": "u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Frequency deviations `omega` of the controlled generators, one row per unit."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`."
        },
        {
          "Name": "omega0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "Hz",
          "Description": "Nominal frequency (unused)."
        }
      ],
      "Outputs": [
        {
          "Name": "Cyx",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Derivative of `y` with respect to `x`."
        },
        {
          "Name": "Dyv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Derivative of `y` with respect to `V` (`[real; imag]`)."
        },
        {
          "Name": "Dyu",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Derivative of `y` with respect to `u`."
        }
      ],
      "Signature": "[Cyx, Dyv, Dyu] = controller.agc.broadcast_PI_AGC.Jacobi_Y(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/Jacobi_Y.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the Jacobians of the broadcast_PI_AGC output.",
      "Desc": "The derivatives of the output `y` of fcn_y are taken with respect to\nthe state, the voltage, the current and the input.",
      "SeeAlso": [
        "controller.agc.broadcast_PI_AGC.fcn_y",
        "controller.agc.broadcast_PI_AGC.Jacobi_dx"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "Jacobi_dx",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "Jacobi",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "t",
        "x",
        "V",
        "u",
        "param",
        "omega0"
      ],
      "OutputNames": [
        "Axx",
        "Bxv",
        "Bxu"
      ],
      "Arguments": [
        {
          "Name": "t",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time (unused)."
        },
        {
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu*s",
          "Description": "Integral `xi` of the weighted frequency deviation."
        },
        {
          "Name": "V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Voltages of all buses `[Vre1; Vim1; Vre2; ...]` (unused)."
        },
        {
          "Name": "u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Frequency deviations `omega` of the controlled generators, one row per unit."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`."
        },
        {
          "Name": "omega0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "Hz",
          "Description": "Nominal frequency (unused)."
        }
      ],
      "Outputs": [
        {
          "Name": "Axx",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Derivative of `f` with respect to `x`."
        },
        {
          "Name": "Bxv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Derivative of `f` with respect to `V` (`[real; imag]`)."
        },
        {
          "Name": "Bxu",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Derivative of `f` with respect to `u`."
        }
      ],
      "Signature": "[Axx, Bxv, Bxu] = controller.agc.broadcast_PI_AGC.Jacobi_dx(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/Jacobi_dx.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the Jacobians of the broadcast_PI_AGC state equation.",
      "Desc": "The derivatives of the right-hand side `f` of fcn_dx are taken with respect to\nthe state, the voltage, the current and the input.",
      "SeeAlso": [
        "controller.agc.broadcast_PI_AGC.fcn_dx",
        "controller.agc.broadcast_PI_AGC.Jacobi_Y"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_Mass",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "fcn",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "t",
        "x",
        "V",
        "u",
        "param",
        "omega0"
      ],
      "OutputNames": [
        "M"
      ],
      "Arguments": [
        {
          "Name": "t",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time (unused)."
        },
        {
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu*s",
          "Description": "Integral `xi` of the weighted frequency deviation."
        },
        {
          "Name": "V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Voltages of all buses `[Vre1; Vim1; Vre2; ...]` (unused)."
        },
        {
          "Name": "u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Frequency deviations `omega` of the controlled generators, one row per unit."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`."
        },
        {
          "Name": "omega0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "Hz",
          "Description": "Nominal frequency (unused)."
        }
      ],
      "Outputs": [
        {
          "Name": "M",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Mass matrix `M`, one row and column per state."
        }
      ],
      "Signature": "M = controller.agc.broadcast_PI_AGC.fcn_Mass(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/fcn_Mass.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GlobalController",
      "Throws": [],
      "Summary": "Return the mass matrix of the broadcast_PI_AGC state equation.",
      "Desc": "The state equation is `M*dx/dt = f(t, x, V, u)`. The diagonal of `M` holds the time constants [s];\na zero time constant makes the corresponding equation algebraic.",
      "SeeAlso": [
        "controller.agc.broadcast_PI_AGC.fcn_dx"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_y",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "fcn",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "t",
        "x",
        "V",
        "u",
        "param",
        "omega0"
      ],
      "OutputNames": [
        "y"
      ],
      "Arguments": [
        {
          "Name": "t",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time (unused)."
        },
        {
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu*s",
          "Description": "Integral `xi` of the weighted frequency deviation."
        },
        {
          "Name": "V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Voltages of all buses `[Vre1; Vim1; Vre2; ...]` (unused)."
        },
        {
          "Name": "u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Frequency deviations `omega` of the controlled generators, one row per unit."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`."
        },
        {
          "Name": "omega0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "Hz",
          "Description": "Nominal frequency (unused)."
        }
      ],
      "Outputs": [
        {
          "Name": "y",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Mechanical power commands `Pmech`, one row per controlled unit."
        }
      ],
      "Signature": "y = controller.agc.broadcast_PI_AGC.fcn_y(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/fcn_y.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GlobalController",
      "Throws": [],
      "Summary": "Return the output of the broadcast_PI_AGC controller.",
      "Desc": "",
      "SeeAlso": [
        "controller.agc.broadcast_PI_AGC.fcn_dx",
        "controller.agc.broadcast_PI_AGC.Jacobi_Y"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_dx",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "fcn",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "t",
        "x",
        "V",
        "u",
        "param",
        "omega0"
      ],
      "OutputNames": [
        "dx"
      ],
      "Arguments": [
        {
          "Name": "t",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time (unused)."
        },
        {
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu*s",
          "Description": "Integral `xi` of the weighted frequency deviation."
        },
        {
          "Name": "V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Voltages of all buses `[Vre1; Vim1; Vre2; ...]` (unused)."
        },
        {
          "Name": "u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Frequency deviations `omega` of the controlled generators, one row per unit."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Parameter matrix, one row per controlled unit, with columns `[alpha, beta, kP, kI]`."
        },
        {
          "Name": "omega0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "Hz",
          "Description": "Nominal frequency (unused)."
        }
      ],
      "Outputs": [
        {
          "Name": "dx",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Right-hand side `f`, one row per state."
        }
      ],
      "Signature": "dx = controller.agc.broadcast_PI_AGC.fcn_dx(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/fcn_dx.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GlobalController",
      "Throws": [],
      "Summary": "Return the right-hand side of the broadcast_PI_AGC state equation.",
      "Desc": "The state equation is `M*dx/dt = f(t, x, V, u)`, where `M` is given by fcn_Mass.",
      "SeeAlso": [
        "controller.agc.broadcast_PI_AGC.fcn_Mass",
        "controller.agc.broadcast_PI_AGC.fcn_y",
        "controller.agc.broadcast_PI_AGC.Jacobi_dx"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_equilibrium",
      "Defining": "controller.agc.broadcast_PI_AGC",
      "Group": "get",
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
        "rv_Xequilibrium",
        "rv_Uequilibrium"
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
          "Name": "rv_Xequilibrium",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu*s",
          "Description": "Equilibrium integrator state (0)."
        },
        {
          "Name": "rv_Uequilibrium",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Equilibrium frequency deviations (0), one per controlled generator."
        }
      ],
      "Signature": "[rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj)",
      "File": "_GUILDAobject/+controller/+agc/@broadcast_PI_AGC/get_equilibrium.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GlobalController",
      "Throws": [],
      "Summary": "Return the equilibrium of the AGC: zero integrator state and zero frequency deviations.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_hessian",
      "Defining": "GlobalController",
      "Group": "Queries and checks",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "x",
        "V",
        "u"
      ],
      "OutputNames": [
        "sct_hessian"
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
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "obj.rv_Xequilibrium",
          "Required": false,
          "Unit": "",
          "Description": "States (default: the equilibrium)."
        },
        {
          "Name": "V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], obj.controlledUnits{1}.a_Bus.a_PowerNetwork.a_Bus)",
          "Required": false,
          "Unit": "pu",
          "Description": "Voltages of all buses [Vre1; Vim1; ...] (default: the equilibrium)."
        },
        {
          "Name": "u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "obj.rv_Uequilibrium",
          "Required": false,
          "Unit": "",
          "Description": "Inputs (the observed outputs or states of the controlled units)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_hessian",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Fields Hxx, Hxv, Hvx, Hvv, R, StateName, PortName."
        }
      ],
      "Signature": "sct_hessian = get_hessian(obj, x, V, u)",
      "File": "_GUILDAsystem/@GlobalController/get_hessian.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GlobalController:HessianNotSupported"
      ],
      "Summary": "Return the Hessian of the energy function of the global controller at a point.",
      "Desc": "The energy-function form of Component.get_hessian for a global controller. No global\ncontroller supports it yet: this base method stops with\nGUILDA:GlobalController:HessianNotSupported, which names the class, and a class\nsupports the form by overriding get_hessian.",
      "SeeAlso": [
        "Component.get_hessian"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_variable_map",
      "Defining": "GlobalController",
      "Group": "Called by analyses",
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
          "Description": "One row per variable or signal: Index, Kind, Role, Owner, Name, Label, Bus, Equilibrium."
        }
      ],
      "Signature": "tab = get_variable_map(obj)",
      "File": "_GUILDAsystem/@GlobalController/get_variable_map.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the variable map of the global controller.",
      "Desc": "Variable map of the controller: its rows of the map of the network\n(net.get_variable_map(), with the same columns and labels), and the voltages of all buses:\n  1. x: states of the controller\n  2. Vre, Vim of each bus in a_Bus (B1 Vre, B1 Vim, B2 Vre, ...)\n  3. uc: inputs of the controller, unit by unit (sv_u of unit 1, sv_u of unit 2, ...),\n     labelled gc.attach_tag(name + \"_\" + unit tag)\n  4. yc: outputs of the controller, unit by unit (signals), labelled the same way\nThe rows x, Vre, Vim and uc come first: they are the order of the point vector of\ngc.get_sys(point). Index counts from 1 here. The column Equilibrium holds the value of\neach row at the equilibrium set by net.initialize (the stored rv_Xequilibrium,\nc_Vequilibrium of the buses and rv_Uequilibrium, and the outputs evaluated there); it\nis NaN when the equilibrium has not been computed yet. Which outputs and states each\ninput observes, and where each output goes, is in the connection map of the network\n(net.get_variable_map), whose sources and targets are not rows of this map.",
      "SeeAlso": [
        "PowerNetwork.get_variable_map",
        "PowerSystemModel.get_sys"
      ],
      "Examples": "```matlab\ngc  = net.a_GlobalController{1};\ntab = gc.get_variable_map();\ntab(tab.Kind == \"uc\", [\"Name\",\"Label\",\"Equilibrium\"])\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_option",
      "Defining": "GlobalController",
      "Group": "get",
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
          "Description": "Name=Value of the constructor arguments outside the table."
        }
      ],
      "Signature": "sct = get_option(obj)",
      "File": "_GUILDAsystem/@GlobalController/get_option.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the constructor arguments that are not columns of the dynamics table.",
      "Desc": "net.export writes them to global_controller/<key>/option.json and PowerNetwork.import\npasses them back to net.add_global_controller as its parameter. A constructor argument\nof a controller class is either a column of tab_parameter.dynamics (of the same name) or\na field of get_option; any other value is not saved. The base class has none (an empty\nstruct); a class with such arguments overrides it.",
      "SeeAlso": [
        "PowerNetwork.export",
        "PowerNetwork.import"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_linear_matrix",
      "Defining": "GlobalController",
      "Group": "Called by analyses",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "x",
        "V",
        "u"
      ],
      "OutputNames": [
        "sct_block"
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
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "States of the controller."
        },
        {
          "Name": "V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Voltages of all buses [Vre1; Vim1; ...]."
        },
        {
          "Name": "u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Inputs of the controller (sv_u of each unit)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_block",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Fields A, B, C, D, E, StateName, InputName, OutputName."
        }
      ],
      "Signature": "sct_block = get_linear_matrix(obj, x, V, u)",
      "File": "_GUILDAsystem/@GlobalController/get_linear_matrix.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GlobalController:GlobalControllerPort"
      ],
      "Summary": "Get the linear block of the global controller at a point.",
      "Desc": "Returns the linear model of the controller at the states x, the voltages\nV = [Vre1; Vim1; Vre2; ...] of all buses of the network (in the order of a_Bus) and\nthe inputs u (sv_u of each controlled unit, unit by unit), as a struct with the fields\nA, B, C, D, E (E dx/dt = A x + B [V; u], y = C x + D [V; u]) and StateName,\nInputName, OutputName (string columns). The names are the Labels of the variable map of\nthe network (net.get_variable_map): the inputs are the voltages of the buses and the\ninputs (rows \"uc\", one set per unit), the states are the states and the outputs are the\noutputs (rows \"yc\", one set per unit). Where each input is read and which inputs each\noutput drives is in the connection map; get_sys connects the blocks by it\n(SolverLIN.solve).\n\nA controlled unit without the outputs or states sv_u, or an output sv_y that drives no\ninput of the unit or its local controllers, stops with the error\nGUILDA:GlobalController:GlobalControllerPort. The Jacobians are those of the simulation\n(f_JacobiDx, f_JacobiY); a model that returns [] for a block gives zeros, and an empty\nmass matrix is the identity. The model is not changed.",
      "SeeAlso": [
        "PowerSystemModel.get_sys",
        "PowerNetwork.get_variable_map"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "gui_content",
      "Defining": "GlobalController",
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
      "File": "_GUILDAsystem/@GlobalController/gui_content.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Pages of the GUI (launch_gui): the Equilibrium table, then the pages of PowerSystemModel.",
      "Desc": "- \"Equilibrium\" (\"table\"): columns Kind, Name and Value, one row per state\n  (`rv_Xequilibrium`) and per input (`rv_Uequilibrium`). Names are `sv_x` and `sv_u`;\n  when their number differs from that of the values (an input per unit), they are\n  numbered x1, x2, ... and u1, u2, .... Value is text.\n  No rows before the equilibrium is computed; the header shows whether it is stale.",
      "SeeAlso": [
        "LayerPackage.gui_content"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "handle_edit",
      "Defining": "GlobalController",
      "Group": "Called by analyses",
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
          "Description": ""
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
          "Description": "Kind of edit."
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
          "Description": "Message of the edit."
        }
      ],
      "Outputs": [],
      "Signature": "handle_edit(obj, a_layer, tag, log)",
      "File": "_GUILDAsystem/@GlobalController/handle_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Mark the stale tags of the controller for its own edits (LayerPackage.log_edit).",
      "Desc": "dynamics (its tab_parameter.dynamics)   equilibrium, odefcn\n  Topology (its addition to the network)  equilibrium\nEdits of other layers are not the controller's.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_odefcn",
      "Defining": "GlobalController",
      "Group": "Called by analyses",
      "Access": "protected",
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
      "Signature": "set_odefcn(obj)",
      "File": "_GUILDAsystem/@GlobalController/set_odefcn.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Bind the parameters and the network frequency into the f_* function handles.",
      "Desc": "Does nothing when they are up to date: the stale tag odefcn is empty and the network\nfrequency equals r_odefcnHz. Otherwise builds them, clears odefcn and stores the\nfrequency in r_odefcnHz. Called by initialize.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "initialize",
      "Defining": "GlobalController",
      "Group": "Called by analyses",
      "Access": "PowerNetwork",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "l_equilibrium"
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
          "Name": "l_equilibrium",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Compute the equilibrium even when it is not stale."
        }
      ],
      "Outputs": [],
      "Signature": "initialize(obj, l_equilibrium)",
      "File": "_GUILDAsystem/@GlobalController/initialize.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Bring the global controller up to date (PowerNetwork.initialize, after every",
      "Desc": "component).\n\nRebuilds the handles when they are stale (the stale tag odefcn, or a network frequency\nother than r_odefcnHz), and computes the equilibrium\n(get_equilibrium) and stores it when it is stale or l_equilibrium is true (the\nequilibria of the controlled units may have changed in this initialize).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "doc",
      "Defining": "PowerSystemModel",
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
          "Description": "Model whose class page is opened."
        }
      ],
      "Outputs": [],
      "Signature": "doc(obj)",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/doc.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Open the class reference page of the model's class.",
      "Desc": "Opens the GUILDA class reference (English page) of class(obj) in the browser, as\nGUILDA.doc(\"class\", class(obj)). doc with a class name (doc PowerNetwork) is\nMATLAB's doc.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.doc()                          % page of the network class\nnet.a_Bus{1}.doc()                 % page of the class of the first bus\nnet.a_Bus{1}.a_Component{1}.doc()  % page of the class of its component\ndoc(net)                           % same as net.doc()\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_sys",
      "Defining": "PowerSystemModel",
      "Group": "Linearization",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "point",
        "opt"
      ],
      "OutputNames": [
        "sys",
        "flag",
        "output"
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
          "Name": "point",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Point: [] (the equilibrium), a vector in the order of get_variable_map(), a matrix (one point per column), {sim, rv_t} or {sim, rv_t, Side}."
        },
        {
          "Name": "Type",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "GUILDA.config(\"ApproximateLinearization\", \"Type\")",
          "Required": false,
          "Unit": "",
          "Description": "Model of the network: \"ODE\" (the bus voltages eliminated) or \"DAE\" (the connected model)."
        },
        {
          "Name": "Port",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Port, [\"PI\",\"PQ\",\"I\"])"
          ],
          "Default": "GUILDA.config(\"ApproximateLinearization\", \"Port\")",
          "Required": false,
          "Unit": "",
          "Description": "Bus port of \"DAE\" (v, w): \"PI\" ([theta,V], [P,Q/V]), \"PQ\" ([theta,rho], [P,Q]) or \"I\" ([Vre,Vim], [-Iim,Ire])."
        },
        {
          "Name": "PlotFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "GUILDA.config(\"ApproximateLinearization\", \"PlotFcn\")",
          "Required": false,
          "Unit": "",
          "Description": "Live display: \"none\" (checked by tools.check_plotfcn; draw the eigenvalue map with result.plot_eigenvalue())."
        },
        {
          "Name": "Input",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Inputs of the model: \"u\" or Labels (see ResultLIN.get_ss). Default: all inputs."
        },
        {
          "Name": "Output",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Outputs of the model: \"x\", \"V\", \"I\", \"y\" or names (see ResultLIN.get_ss). Default: as in get_ss."
        },
        {
          "Name": "Format",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Format, [\"GUILDAorigin\",\"struct\",\"ss\"])"
          ],
          "Default": "\"GUILDAorigin\"",
          "Required": false,
          "Unit": "",
          "Description": "Form of sys: GUILDAorigin (a ResultLIN), struct or ss (dss)."
        },
        {
          "Name": "Form",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Form, [\"descriptor\",\"absorbed\",\"hessian\"])"
          ],
          "Default": "\"descriptor\"",
          "Required": false,
          "Unit": "",
          "Description": "View of A ... E: \"descriptor\" (E holds the time constants), \"absorbed\" (E^-1 in A and B) or \"hessian\" (the energy-function form; network, Port PI or PQ)."
        }
      ],
      "Outputs": [
        {
          "Name": "sys",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Linear model in the form of Format, with state, input and output names (1 x n_t struct or ss array for several sections)."
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
          "Description": "True when the result is usable: all entries are finite and Avv is invertible, in every section."
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
          "Description": "message, s_issue (\"\", \"NotFinite\" or \"SingularAvv\"), l_equilibrium, n_x, n_v, n_u, rcond_Avv, sv_faultBus, s_layer; per section lv_flag, sv_issue, sv_message, rv_rcond_Avv; result (the ResultLIN)."
        }
      ],
      "Signature": "[sys, flag, output] = get_sys(obj, point, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/get_sys.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerSystemModel:NoLinearModel",
        "GUILDA:PowerSystemModel:HessianNetworkOnly",
        "GUILDA:PowerSystemModel:HessianPort",
        "GUILDA:PowerSystemModel:InputEdited",
        "GUILDA:PowerSystemModel:Stale"
      ],
      "Summary": "Linearize the layer and return its linear model.",
      "Desc": "One method for every layer with a linear model: PowerNetwork, Bus, Component (with\nits local controllers), LocalController and GlobalController (Branch has none:\nGUILDA:PowerSystemModel:NoLinearModel). Each model object gives its own linear block\n(get_linear_matrix); get_sys takes the inputs and outputs of the layer (its port) from\nthe variable map, and SolverLIN.solve connects the blocks along it. The linearization needs no\ntoolbox, and the model is not changed.\n\n| Layer | Inputs | Outputs | Bus voltages |\n|---|---|---|---|\n| PowerNetwork | inputs u of the components | outputs y and yc | algebraic: 0 = Y v - I of the components, eliminated for Type \"ODE\" |\n| Bus, Component | V, u, uc | I, y, yc | inputs |\n| LocalController | V of its bus, its inputs | its outputs | inputs |\n| GlobalController | V of all buses, its inputs | its outputs | inputs |\n\nThe names are the Labels of the variable map of the layer (obj.get_variable_map); the\nstates follow its order. The current of a\ncomponent is the component tag with Ire, Iim; that of a bus the bus tag. An input is\nthe sum of its sources in the connection map plus the external input of that name.\n\npoint, the first argument, gives the point: [] (the equilibrium set by net.initialize,\nthe default), a vector of the variables of the layer in the order of the leading rows of\nobj.get_variable_map() (x, Vre, Vim, u, uc; for a controller x, Vre, Vim, uc), or\n{sim, t} (or {sim, t, \"before\"}) for the state of a simulation result at time t\n(PowerNetwork, Bus and Component).\nTime sections: {sim, rv_t} with several times, or a matrix with one point per column,\nlinearizes the layer at each of them; the result holds one section per time or column\n(ResultLIN.rv_t: the times, or 1:n for a matrix; ResultLIN.Index chooses the section),\nand flag is true only when every section is usable (output.lv_flag of each section). Every value of the point is used as given: the\ninputs u of the components and uc of the controllers, whether the connection map drives\nthem or holds them at a setpoint (Vref of an AVR, Pref of a governor). The outputs y and\nyc are evaluated at the point. The point sets the variables only: the\nadmittance matrix stays the one of the model, also inside a fault (reported with an\nINFO message and output.sv_faultBus).\n\nThe layer stops with GUILDA:PowerSystemModel:Stale when net.initialize() is needed: an\nedited dynamics always, an edited network, power flow or equilibrium when the point is the\nequilibrium; with GUILDA:PowerSystemModel:InputEdited when the inputs were edited.\nA point with NaN or Inf stops with GUILDA:SolverLIN:PointNotFinite, and a model that is\nnot finite at the point with GUILDA:SolverLIN:JacobianNotFinite.\n\nFormat chooses the form of sys: \"GUILDAorigin\" (default) is the ResultLIN of the\nlinearization, also when flag is false; its properties A, B, C, D, E, StateName,\nInputName and OutputName hold the model of its Type (the Type of the call) with the\nselected Input and Output. \"struct\" is a struct with these eight fields and \"ss\" a\ndescriptor state-space model (dss, Control System Toolbox): they stop with the error of\nResultLIN.get_ss when flag is false (except \"DAE\" with a singular Avv). With several\nsections, \"struct\" is a 1 x n_t struct array and \"ss\" an ss array (sys(:,:,k) is\nsection k). The ResultLIN of the network (Format \"GUILDAorigin\") keeps a snapshot of it,\nsct_network = struct(net, false).\n\nType chooses the model of the network: \"DAE\" is the connected model, with the bus\nvoltages as algebraic variables (E is singular on their rows), each bus written as the\nport of Port (see ResultLIN.get_ss); \"ODE\" is the model with the bus voltages eliminated (SolverLIN.reduce).\nThe result keeps the DAE, so res.Type switches between them later.\n\nForm chooses the view of A ... E (ResultLIN.Form): \"descriptor\" (default; E holds the\ntime constants), \"absorbed\" (E^-1 multiplied into the state rows) or \"hessian\", the\nenergy-function form of the network: get_sys calls get_hessian of every component, local\ncontroller and global controller at the point of each section, and SolverLIN.solve\nassembles E_h dz/dt = H z over z = [x; theta; V] with E_h = -blkdiag(inv(R), 0) and\nH = [Hxx Hxv; Hvx Hvv + Hvv_net] (see ResultLIN). A class without the form stops with\nits GUILDA:<layer>:HessianNotSupported (the Static AVR and governor have empty blocks).\n\"hessian\" needs the network (GUILDA:PowerSystemModel:HessianNetworkOnly) and Port \"PI\"\nor \"PQ\" (GUILDA:PowerSystemModel:HessianPort). The result keeps the descriptor DAE too.",
      "SeeAlso": [
        "ResultLIN",
        "SolverLIN",
        "PowerNetwork.get_variable_map"
      ],
      "Examples": "```matlab\nres = net.get_sys();                          % ResultLIN of the network (Type of GUILDA.setting)\neig(res.A, res.E)\nsct = net.get_sys(Type=\"DAE\", Format=\"struct\");\nresV = net.get_sys(Output=\"V\");               % bus voltages as outputs\nsys = net.a_Bus{1}.a_Component{1}.get_sys(Format=\"ss\");   % component, V to I\nres2 = net.get_sys({sim, 1.5});               % at a time of a simulation result\nres3 = net.get_sys(res.rv_point);             % at a vector in the order of net.get_variable_map()\nres4 = net.get_sys({sim, [0.5, 1, 2]});       % three time sections; res4.Index = 2 shows t = 1\nsct4 = net.get_sys({sim, [0.5, 1, 2]}, Format=\"struct\");   % 1 x 3 struct array\nresH = net.get_sys(Type=\"DAE\", Port=\"PI\", Form=\"hessian\");  % energy-function form\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_Hz",
      "Defining": "PowerSystemModel",
      "Group": "get",
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
        "Hz"
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
          "Name": "Hz",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "Hz",
          "Description": "Nominal frequency."
        }
      ],
      "Signature": "Hz = get_Hz(obj)",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/get_Hz.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Nominal frequency [Hz] of the network the model belongs to.",
      "Desc": "net.tab_parameter.base.Hz. This is the omega0 passed to the model functions (models multiply it by 2*pi).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "log_edit",
      "Defining": "LayerPackage",
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
          "Description": "Edited layer (a Parameter container for a parameter edit)."
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
          "Description": "What was edited, with the values (e.g. \"edit D: 0.1 -> 0.2\")."
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
          "Description": "Kind of edit: a parameter group (\"dynamics\", \"powerflow\", ...), \"Topology\", \"Slack\" or \"Tag\"."
        }
      ],
      "Outputs": [],
      "Signature": "log_edit(obj, log, tag)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/log_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Report an edit of this layer to every layer up to the top.",
      "Desc": "Calls handle_edit(a_owner, tag, message) on the edited layer and on every layer\nabove it; a_owner is the edited layer (the owner for a Parameter container) and\nmessage is \"<tag of obj>: <log>\", or \"<container tag>/<owner tag>: <log>\" for a\nParameter container (e.g. \"dynamics/B001SG1: edit D: 2 -> 2.1\"). A generated tag\nalready contains the tags of the parents. Each layer appends the message to its own\nstale tags that the edit affects.",
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
