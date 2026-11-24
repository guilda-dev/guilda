(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["controller.pss.Retrofit"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "controller.pss.Retrofit",
  "properties": [
    {
      "Name": "key",
      "Defining": "controller.pss.Retrofit",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"pss-retrofit\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 89,
      "Summary": "Model key that selects this class in `Component.add_local_controller`.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_role",
      "Defining": "controller.pss.Retrofit",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"pss\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 90,
      "Summary": "Role in Component.add_local_controller (\"pss\": under the AVR of the component).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_x",
      "Defining": "controller.pss.Retrofit",
      "Group": "Signals",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(0,1)",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 94,
      "Summary": "Names of the states: \"hat_\" + the states of the generator (set on attachment).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_u",
      "Defining": "controller.pss.Retrofit",
      "Group": "Signals",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"Xall\"",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 95,
      "Summary": "Names of the observed signals (\"Xall\": all the states of the generator).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_y",
      "Defining": "controller.pss.Retrofit",
      "Group": "Signals",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"Vpss\"",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 96,
      "Summary": "Names of the outputs: the Vpss input of the AVR.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_para",
      "Defining": "controller.pss.Retrofit",
      "Group": "Signals",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(0,1)",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 97,
      "Summary": "Names of the parameters (none).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Q",
      "Defining": "controller.pss.Retrofit",
      "Group": "Design weights",
      "GetAccess": "public",
      "SetAccess": "public",
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
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 101,
      "Summary": "State weight of the LQR (nx-by-nx; a vector is the diagonal, empty the identity).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "equilibrium, odefcn",
      "Deprecated": ""
    },
    {
      "Name": "R",
      "Defining": "controller.pss.Retrofit",
      "Group": "Design weights",
      "GetAccess": "public",
      "SetAccess": "public",
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
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 102,
      "Summary": "Input weight of the LQR (1-by-1; empty is 1).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "equilibrium, odefcn",
      "Deprecated": ""
    },
    {
      "Name": "K",
      "Defining": "controller.pss.Retrofit",
      "Group": "Design results",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,0)",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 106,
      "Summary": "Feedback gain K in Vpss = -K*(x - hat_x) (1-by-nx).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sys_design",
      "Defining": "controller.pss.Retrofit",
      "Group": "Design results",
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
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 107,
      "Summary": "Linear model of the generator used to compute K (ss).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_Component",
      "Defining": "LocalController",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "Component, LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 77,
      "Summary": "Parent: the component, or the AVR for a PSS (set by Component.add_local_controller).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "Component or LocalController",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_LocalController",
      "Defining": "LocalController",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "cell(0,1)",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 80,
      "Summary": "Nested controller (the PSS under an AVR), 0x1 or 1x1.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "equilibrium",
      "Deprecated": ""
    },
    {
      "Name": "f_Mass",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 83,
      "Summary": "Mass matrix function @(t,x,V,u) with the parameters bound.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_dx",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 84,
      "Summary": "State equation function @(t,x,V,u) with the parameters bound.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_Y",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 85,
      "Summary": "Output function @(t,x,V,u) with the parameters bound.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_JacobiDx",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 86,
      "Summary": "Jacobian function of f_dx.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_JacobiY",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 87,
      "Summary": "Jacobian function of f_Y.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "l_hasController",
      "Defining": "LocalController",
      "Group": "Simulation working data",
      "GetAccess": "public",
      "SetAccess": "SolverODE",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "false",
      "Validation": {
        "Class": "logical",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 90,
      "Summary": "Whether a nested controller is attached.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "iv_obsY",
      "Defining": "LocalController",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 93,
      "Summary": "Index in sv_y of the observed component of each input (0: not read from sv_y).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "iv_obsX",
      "Defining": "LocalController",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 94,
      "Summary": "Index in sv_x of the observed component of each input (0: not read from sv_x).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sr_reserved",
      "Defining": "LocalController",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[\"Xall\",\"Yall\"]",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 100,
      "Summary": "Reserved input names: all the states sv_x / all the outputs sv_y of the component.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_odefcnHz",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 103,
      "Summary": "Network frequency bound into the f_* handles (empty: never built).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_Xequilibrium",
      "Defining": "LocalController",
      "Group": "Steady State",
      "GetAccess": "public",
      "SetAccess": "Component, LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 106,
      "Summary": "State equilibrium (the output of get_equilibrium, stored by Component.set_equilibrium).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_Uequilibrium",
      "Defining": "LocalController",
      "Group": "Steady State",
      "GetAccess": "public",
      "SetAccess": "Component, LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 107,
      "Summary": "Input equilibrium (the output of get_equilibrium, stored by Component.set_equilibrium).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "c_Vequilibrium",
      "Defining": "LocalController",
      "Group": "Steady State",
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
      "Unit": "pu",
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 111,
      "Summary": "Voltage equilibrium of the parent.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "c_Iequilibrium",
      "Defining": "LocalController",
      "Group": "Steady State",
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
      "Unit": "pu",
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 112,
      "Summary": "Current equilibrium of the parent.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "parent",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 116,
      "Summary": "Parent in the layer structure: the component, or the AVR for a PSS.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "children",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/LocalController.m",
      "Line": 117,
      "Summary": "Children in the layer structure: the nested controller.",
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
      "Name": "Retrofit",
      "Defining": "controller.pss.Retrofit",
      "Group": "Constructor",
      "Access": "Component",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "tag",
        "opt"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
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
          "Description": "Tag suffix; the controller tag is \"CP\" + tag."
        },
        {
          "Name": "Q",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "State weight: nx-by-nx matrix or its diagonal (default: identity)."
        },
        {
          "Name": "R",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Input weight: scalar (default: 1)."
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
          "Description": "Retrofit object."
        }
      ],
      "Signature": "obj = controller.pss.Retrofit(tag, Name=Value)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Retrofit.m",
      "Line": 111,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a retrofit stabilizer with the tag \"CP\" + tag.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_option",
      "Defining": "controller.pss.Retrofit",
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
          "Description": "Q and R."
        }
      ],
      "Signature": "sct = get_option(obj)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/get_option.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "Return Q and R, the constructor arguments outside the dynamics table.",
      "Desc": "The weights as stored: a vector given is its diagonal matrix, and empty is the default\n(it stays empty). The gain K, sys_design, the state names and the equilibrium are not\nreturned: they follow from the generator when initialize runs. net.export writes these\nvalues to option.json.",
      "SeeAlso": [
        "LocalController.get_option",
        "PowerNetwork.export"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "driven_inputs",
      "Defining": "controller.pss.Retrofit",
      "Group": "driven",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "comp"
      ],
      "OutputNames": [
        "sv_in"
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
          "Name": "comp",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The component, or the AVR for a PSS, the controller is to be attached to."
        }
      ],
      "Outputs": [
        {
          "Name": "sv_in",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Names of the driven inputs of comp (\"Vpss\")."
        }
      ],
      "Signature": "sv_in = driven_inputs(obj, comp)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/driven_inputs.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [
        "GUILDA:Retrofit:ParentNotStatic"
      ],
      "Summary": "Names of the inputs of comp (the component, or the AVR for a PSS) that the",
      "Desc": "controller drives once attached to it: Vpss of the AVR. Stops unless comp is the\nStatic AVR. Component.add_local_controller calls it before anything changes (on\nattachment, and for the PSS that moves to a new AVR), so that a rejected call leaves\nthe generator as it was.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_inputs",
      "Defining": "controller.pss.Retrofit",
      "Group": "set",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sv_name"
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
          "Name": "sv_name",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Names of the observed signals."
        }
      ],
      "Outputs": [],
      "Signature": "set_inputs(obj, sv_name)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/set_inputs.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "The observed signals with \"Xall\" expanded: the states of the generator",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "resolve_ports",
      "Defining": "controller.pss.Retrofit",
      "Group": "resolve",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "comp"
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
          "Name": "comp",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "Component",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Generator the controller observes."
        }
      ],
      "Outputs": [],
      "Signature": "resolve_ports(obj, comp)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/resolve_ports.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "The states: one copy \"hat_\" + name for each state of the generator",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_odefcn",
      "Defining": "controller.pss.Retrofit",
      "Group": "Called by analyses",
      "Access": "Component, LocalController",
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
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/set_odefcn.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [
        "GUILDA:Retrofit:SingularMass",
        "GUILDA:Retrofit:WeightSize"
      ],
      "Summary": "Design K and build the f_* handles (initialize). Does nothing when they are up to",
      "Desc": "date: the stale tag odefcn is empty and the network frequency equals r_odefcnHz.\n\nThe handles bind the handles f_dx and f_JacobiDx of the generator, which the generator\n(the component above) rebuilds first, so a network Hz edit rebuilds them here too.\nWhen the equilibrium of the controller is up to date, K is designed at the equilibrium\nof the generator (also after a Hz edit, which keeps the equilibrium). Otherwise the\ngain and A_d are zero until net.initialize.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "initialize",
      "Defining": "controller.pss.Retrofit",
      "Group": "Called by analyses",
      "Access": "Component, LocalController",
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
          "Description": "The generator has just set the equilibrium."
        }
      ],
      "Outputs": [],
      "Signature": "initialize(obj, l_equilibrium)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/initialize.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "Bring the controller up to date (LocalController.initialize), designing the gain K",
      "Desc": "when the generator has just set the equilibrium.\n\nWith l_equilibrium = true (Component.set_equilibrium, during net.initialize) the\nhandles, which bind K and the equilibrium, are marked stale; LocalController.initialize\nthen clears the stale tag equilibrium and set_odefcn designs K and rebuilds them.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "Jacobi_Y",
      "Defining": "controller.pss.Retrofit",
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
          "Description": "Time."
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
          "Unit": "",
          "Description": "Compensator states hat_x."
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
          "Description": "Terminal voltage of the generator [real; imag]."
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
          "Unit": "",
          "Description": "Observed states x of the generator."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Gain K, A_d, E, the equilibrium input u0 and the handles of the generator."
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
          "Description": "Nominal frequency of the network."
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
          "Description": "Jacobian with respect to hat_x (K)."
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
          "Description": "Jacobian with respect to V (zero)."
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
          "Description": "Jacobian with respect to the observed states (-K)."
        }
      ],
      "Signature": "[Cyx, Dyv, Dyu] = controller.pss.Retrofit.Jacobi_Y(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Jacobi_Y.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "Jacobian of the output equation: `K`, 0 and `-K`.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "Jacobi_dx",
      "Defining": "controller.pss.Retrofit",
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
          "Description": "Time."
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
          "Unit": "",
          "Description": "Compensator states hat_x."
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
          "Description": "Terminal voltage of the generator [real; imag]."
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
          "Unit": "",
          "Description": "Observed states x of the generator."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Gain K, A_d, E, the equilibrium input u0 and the handles of the generator."
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
          "Description": "Nominal frequency of the network."
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
          "Description": "Jacobian with respect to hat_x (A_d)."
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
          "Description": "Jacobian with respect to V (df/dV of the generator)."
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
          "Description": "Jacobian with respect to the observed states (df/dx - A_d)."
        }
      ],
      "Signature": "[Axx, Bxv, Bxu] = controller.pss.Retrofit.Jacobi_dx(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/Jacobi_dx.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "Jacobian of the state equation: `A_d`, `df/dV` and `df/dx - A_d` at (x, V, u*).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_Mass",
      "Defining": "controller.pss.Retrofit",
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
          "Description": "Time."
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
          "Unit": "",
          "Description": "Compensator states hat_x."
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
          "Description": "Terminal voltage of the generator [real; imag]."
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
          "Unit": "",
          "Description": "Observed states x of the generator."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Gain K, A_d, E, the equilibrium input u0 and the handles of the generator."
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
          "Description": "Nominal frequency of the network."
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
          "Description": "Mass matrix E (nx-by-nx)."
        }
      ],
      "Signature": "M = controller.pss.Retrofit.fcn_Mass(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/fcn_Mass.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "Mass matrix: the mass matrix E of the generator.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_y",
      "Defining": "controller.pss.Retrofit",
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
          "Description": "Time."
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
          "Unit": "",
          "Description": "Compensator states hat_x."
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
          "Description": "Terminal voltage of the generator [real; imag]."
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
          "Unit": "",
          "Description": "Observed states x of the generator."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Gain K, A_d, E, the equilibrium input u0 and the handles of the generator."
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
          "Description": "Nominal frequency of the network."
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
          "Description": "Vpss, the Vpss input of the AVR."
        }
      ],
      "Signature": "y = controller.pss.Retrofit.fcn_y(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/fcn_y.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "Output equation `Vpss = -K (x - hat_x)`.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_dx",
      "Defining": "controller.pss.Retrofit",
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
          "Description": "Time."
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
          "Unit": "",
          "Description": "Compensator states hat_x, in the order of the states of the generator."
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
          "Description": "Terminal voltage of the generator [real; imag]."
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
          "Unit": "",
          "Description": "Observed states x of the generator."
        },
        {
          "Name": "param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Gain K, A_d, E, the equilibrium input u0 and the handles of the generator."
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
          "Description": "Nominal frequency of the network."
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
          "Description": "Right-hand side, one row per state."
        }
      ],
      "Signature": "dx = controller.pss.Retrofit.fcn_dx(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/fcn_dx.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "State equation of the compensator: `f(x, V, u*) - A_d (x - hat_x)` (multiplied by E in fcn_Mass).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_equilibrium",
      "Defining": "controller.pss.Retrofit",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "V",
        "u",
        "x"
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
        },
        {
          "Name": "V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Complex terminal voltage of the generator at the point (unused)."
        },
        {
          "Name": "u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Input of the generator at the point (unused)."
        },
        {
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "State of the generator at the point, in the order of its sv_x."
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
          "Unit": "",
          "Description": "State hat_x at the point: the state of the generator."
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
          "Unit": "",
          "Description": "Observed signals at the point: the state of the generator."
        }
      ],
      "Signature": "[rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u, x)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/get_equilibrium.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LocalController",
      "Throws": [],
      "Summary": "Return the controller at the point: hat_x = x and the observed signals = x, the state of the generator there.",
      "Desc": "Only the arguments are read: nothing is stored and K is not designed here (initialize\ndesigns it after the equilibrium is set). At another point than the equilibrium of\nnet.initialize (a step of the continuation power flow, a point of the\nstability-constrained OPF), K, A_d and u* stay as designed at that equilibrium, so the\ncompensator moves there: E dhat_x/dt = f(x, V, u*) is not 0 when u differs from u*.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "weight",
      "Defining": "controller.pss.Retrofit",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "W",
        "s_name"
      ],
      "OutputNames": [
        "W"
      ],
      "Arguments": [
        {
          "Name": "W",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Weight as given: a matrix, its diagonal or empty."
        },
        {
          "Name": "s_name",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name of the weight (\"Q\" or \"R\"), for the error message."
        }
      ],
      "Outputs": [
        {
          "Name": "W",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Weight matrix, or empty."
        }
      ],
      "Signature": "W = weight(W, s_name)",
      "File": "_GUILDAobject/+controller/+pss/@Retrofit/private/weight.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:Retrofit:WeightShape"
      ],
      "Summary": "A vector is the diagonal of the weight (set.Q, set.R)",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_equilibrium_at",
      "Defining": "LocalController",
      "Group": "Internal helpers",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": true,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "V",
        "u",
        "x"
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
        },
        {
          "Name": "V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Complex terminal voltage of the component at the point."
        },
        {
          "Name": "u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Input of the component at the point, in the order of its sv_u."
        },
        {
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "State of the observed component at the point, in the order of its sv_x."
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
          "Unit": "",
          "Description": "State of the controller at the point, in the order of sv_x."
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
          "Unit": "",
          "Description": "Input of the controller at the point, in the order of sv_u."
        }
      ],
      "Signature": "[rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium_at(obj, V, u, x)",
      "File": "_GUILDAsystem/@LocalController/get_equilibrium_at.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Call get_equilibrium(V, u, x); a subclass with get_equilibrium(obj, V, u) is called with three arguments.",
      "Desc": "Component.set_equilibrium, the continuation power flow (operating points of the steps)\nand the stability-constrained OPF (stability_point) call the controllers through this,\nso a user-defined controller without the fourth argument keeps working. Only the error\nMATLAB:TooManyInputs of this call itself selects the three-argument form; an error\ninside get_equilibrium is raised as it is.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "resolve_observe",
      "Defining": "LocalController",
      "Group": "Construction and attachment",
      "Access": "Component, LocalController",
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
      "Signature": "resolve_observe(obj)",
      "File": "_GUILDAsystem/@LocalController/resolve_observe.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:LocalController:ReservedInputNames"
      ],
      "Summary": "Expand the reserved inputs \"Xall\" / \"Yall\" and find where each input is read on",
      "Desc": "the observed component (iv_obsY / iv_obsX), for this controller and the\ncontrollers nested in it. An input name found in both sv_y and sv_x is read\nfrom sv_y.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "remove_local_controller",
      "Defining": "LocalController",
      "Group": "Construction and attachment",
      "Access": "Component, LocalController",
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
      "Signature": "remove_local_controller(obj)",
      "File": "_GUILDAsystem/@LocalController/remove_local_controller.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Detach the nested controller (Component.add_local_controller, when an AVR is replaced; Component.remove_local_controller)",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "add_local_controller",
      "Defining": "LocalController",
      "Group": "Construction and attachment",
      "Access": "Component, LocalController",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "a_Controller"
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
          "Name": "a_Controller",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "LocalController",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Nested controller (the PSS)."
        }
      ],
      "Outputs": [],
      "Signature": "add_local_controller(obj, a_Controller)",
      "File": "_GUILDAsystem/@LocalController/add_local_controller.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Attach a nested controller (the PSS under an AVR; Component.add_local_controller).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "observed_component",
      "Defining": "LocalController",
      "Group": "Internal helpers",
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
        "comp"
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
          "Name": "comp",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Observed Component."
        }
      ],
      "Signature": "comp = observed_component(obj)",
      "File": "_GUILDAsystem/@LocalController/observed_component.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "The component the controller observes: its parent, or for a nested",
      "Desc": "controller (e.g. a PSS under an AVR) the component above them",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "gui_content",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/gui_content.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Pages of the GUI (launch_gui): the Equilibrium table, then the pages of PowerSystemModel.",
      "Desc": "- \"Equilibrium\" (\"table\"): columns Kind, Name and Value, one row per state (`sv_x`,\n  `rv_Xequilibrium`), per input (`sv_u`, `rv_Uequilibrium`), then the voltage\n  `c_Vequilibrium` and the current `c_Iequilibrium` of the parent. Value is text\n  (complex as a+bj).\n  No rows before the equilibrium is computed; the header shows whether it is stale.",
      "SeeAlso": [
        "LayerPackage.gui_content"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "handle_edit",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/handle_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Mark the stale tags of the controller for its own edits (LayerPackage.log_edit).",
      "Desc": "dynamics (its tab_parameter.dynamics, or a property of the controller itself,\n            e.g. Q, R, V0 of local_LQR)   equilibrium, odefcn\n  Topology (a nested controller)          equilibrium\nEdits of other layers are not the controller's.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_hessian",
      "Defining": "LocalController",
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
          "Default": "[real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]",
          "Required": false,
          "Unit": "pu",
          "Description": "Voltage [Vre; Vim] of the parent."
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
          "Description": "Inputs (default: the equilibrium)."
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
      "File": "_GUILDAsystem/@LocalController/get_hessian.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:LocalController:HessianNotSupported"
      ],
      "Summary": "Return the Hessian of the energy function of the local controller at a point (port \"PI\").",
      "Desc": "The same form as Component.get_hessian: with the deviations x of the states and\nv = [theta; V] of the bus of the parent component,\n  dx/dt = -R (Hxx x + Hxv v),   w_dev = Hvx x + Hvv v,\nand a struct with the fields Hxx (n_x x n_x), Hxv (n_x x 2), Hvx (2 x n_x),\nHvv (2 x 2), R (n_x x n_x), StateName and PortName (theta and V of the bus). A local\ncontroller injects no current, so its w_dev is zero; its inputs u are constants of the\npoint.\n\nThis base method stops with GUILDA:LocalController:HessianNotSupported, which names\nthe class; a class supports the form by overriding get_hessian. The stateless default\ncontrollers controller.governor.Static and controller.avr.Static return empty blocks,\nso the default generators support the form.",
      "SeeAlso": [
        "Component.get_hessian"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_variable_map",
      "Defining": "LocalController",
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
      "File": "_GUILDAsystem/@LocalController/get_variable_map.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the variable map of the local controller.",
      "Desc": "Variable map of the controller: its rows of the map of its component\n(comp.get_variable_map(), with the same columns and labels), and the voltage of the bus:\n  1. x: states of the controller\n  2. Vre, Vim of the bus of its component\n  3. uc: inputs of the controller\n  4. yc: outputs of the controller (signals)\nThe rows x, Vre, Vim and uc come first: they are the order of the point vector of\ncon.get_sys(point). Index counts from 1 here. The column Equilibrium holds the value of\neach row at the equilibrium set by net.initialize (the stored rv_Xequilibrium,\nc_Vequilibrium and rv_Uequilibrium, and the outputs evaluated there); it is NaN when\nthe equilibrium has not been computed yet. Where each input is read is in the\nconnection map of the component (comp.get_variable_map), whose sources are not rows of\nthis map.",
      "SeeAlso": [],
      "Examples": "```matlab\navr = net.a_Bus{1}.a_Component{1}.avr;    % a generator with an AVR\ntab = avr.get_variable_map();\nres = avr.get_sys(tab.Equilibrium(tab.Role == \"variable\"));   % same as avr.get_sys()\n```\n\nSee also Component.get_variable_map, PowerSystemModel.get_sys",
      "Deprecated": ""
    },
    {
      "Name": "get_linear_matrix",
      "Defining": "LocalController",
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
          "Description": "Voltage [Vre; Vim] of the bus of its component."
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
          "Description": "Inputs of the controller."
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
      "File": "_GUILDAsystem/@LocalController/get_linear_matrix.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Get the linear block of the local controller at a point.",
      "Desc": "Returns the linear model of the controller at the states x, the voltage V = [Vre; Vim]\nof the bus of its component and the inputs u, as a struct with the fields A, B, C, D, E\n(E dx/dt = A x + B [V; u], y = C x + D [V; u]) and StateName, InputName, OutputName\n(string columns). The names are the Labels of the variable map of the component\n(comp.get_variable_map): the inputs are the voltage of the bus and the inputs (rows\n\"uc\"), the states are the states and the outputs are the outputs (rows \"yc\"; \"Y_\" +\nname for an output with the name of a state).\n\nget_sys connects the blocks (SolverLIN.solve). The Jacobians are those of the\nsimulation (f_JacobiDx, f_JacobiY); a model that returns [] for a block gives zeros.\nThe model is not changed.",
      "SeeAlso": [
        "PowerSystemModel.get_sys",
        "Component.get_linear_matrix"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "validate",
      "Defining": "LocalController",
      "Group": "Queries and checks",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "l_message"
      ],
      "OutputNames": [
        "flag"
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
          "Name": "l_message",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Print the comparison."
        }
      ],
      "Outputs": [
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
          "Description": "Struct of tables: dx (residual at the equilibrium), Axx, Bxu, ... (absolute differences of each Jacobian block), contract (PASS or FAIL of each check), inputs (connection source of each input)."
        }
      ],
      "Signature": "flag = validate(obj, l_message)",
      "File": "_GUILDAsystem/@LocalController/validate.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:LocalController:InputEdited",
        "GUILDA:LocalController:Stale"
      ],
      "Summary": "Check the model functions of the controller against the contract of LocalController.",
      "Desc": "The network must be initialized: the check is made at the equilibrium. A broken model does not stop the\ncheck: it is reported as FAIL in flag.contract and the values that cannot be computed\nare NaN. flag.inputs shows where each input is read, so a misspelled input name\nappears as \"equilibrium (not connected)\".",
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
      "SeeAlso": [],
      "Examples": "```matlab\nres = net.get_sys();                          % ResultLIN of the network (Type of GUILDA.setting)\neig(res.A, res.E)\nsct = net.get_sys(Type=\"DAE\", Format=\"struct\");\nresV = net.get_sys(Output=\"V\");               % bus voltages as outputs\nsys = net.a_Bus{1}.a_Component{1}.get_sys(Format=\"ss\");   % component, V to I\nres2 = net.get_sys({sim, 1.5});               % at a time of a simulation result\nres3 = net.get_sys(res.rv_point);             % at a vector in the order of net.get_variable_map()\nres4 = net.get_sys({sim, [0.5, 1, 2]});       % three time sections; res4.Index = 2 shows t = 1\nsct4 = net.get_sys({sim, [0.5, 1, 2]}, Format=\"struct\");   % 1 x 3 struct array\nresH = net.get_sys(Type=\"DAE\", Port=\"PI\", Form=\"hessian\");  % energy-function form\n```\n\nSee also ResultLIN, SolverLIN, PowerNetwork.get_variable_map",
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
