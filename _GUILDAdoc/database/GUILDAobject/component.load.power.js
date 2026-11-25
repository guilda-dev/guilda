(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["component.load.power"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "component.load.power",
  "properties": [
    {
      "Name": "key",
      "Defining": "component.load.power",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"load-power\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+component/+load/@power/power.m",
      "Line": 47,
      "Summary": "Model key that selects this class in `Bus.add_component`.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_x",
      "Defining": "component.load.power",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+component/+load/@power/power.m",
      "Line": 48,
      "Summary": "State names (none).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_u",
      "Defining": "component.load.power",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[\"Pload\",\"Qload\"]",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+component/+load/@power/power.m",
      "Line": 49,
      "Summary": "Input port names.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_y",
      "Defining": "component.load.power",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+component/+load/@power/power.m",
      "Line": 50,
      "Summary": "Output names (none).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_para",
      "Defining": "component.load.power",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+component/+load/@power/power.m",
      "Line": 51,
      "Summary": "Dynamic parameter names (none).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Prefix",
      "Defining": "component.load.power",
      "Group": "Model definition",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"LP\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+component/+load/@power/power.m",
      "Line": 52,
      "Summary": "Short name of the model (the tag starts with \"LPQ\").",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_Bus",
      "Defining": "Component",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "Bus",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 87,
      "Summary": "Bus the component is connected to (set by Bus.add_component and Bus.replace_component).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "Bus",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_LocalController",
      "Defining": "Component",
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
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 90,
      "Summary": "Top-level local controllers, in slot order whatever the attach order: the AVR or \"local\" controller (a PSS hangs under an AVR), then the governor.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "equilibrium",
      "Deprecated": ""
    },
    {
      "Name": "f_Mass",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 93,
      "Summary": "Mass matrix function @(t,x,V,u) with the parameters bound.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_dx",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 94,
      "Summary": "State equation function @(t,x,V,u) with the parameters bound.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_I",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 95,
      "Summary": "Current injection function @(t,x,V,u) with the parameters bound.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_Y",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 96,
      "Summary": "Output function @(t,x,V) with the parameters bound (no input).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_JacobiDx",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 97,
      "Summary": "Jacobian function of f_dx (analytic or numerical).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_JacobiI",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 98,
      "Summary": "Jacobian function of f_I (analytic or numerical).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_JacobiY",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 99,
      "Summary": "Jacobian function of f_Y (analytic or numerical).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_odefcnHz",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 102,
      "Summary": "Network frequency bound into the f_* handles (empty: never built).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_Xequilibrium",
      "Defining": "Component",
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
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 105,
      "Summary": "State equilibrium.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_Uequilibrium",
      "Defining": "Component",
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
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 106,
      "Summary": "Input equilibrium (edited by set_input; held by initialize(Method=\"FixedInput\")).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "c_Iequilibrium",
      "Defining": "Component",
      "Group": "Steady State",
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
      "Unit": "pu",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 107,
      "Summary": "Current injected into the bus at the equilibrium (complex).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "c_Vequilibrium",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 110,
      "Summary": "Terminal voltage at the equilibrium (= a_Bus.c_Vequilibrium).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_Xequilibrium_all",
      "Defining": "Component",
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
      "Unit": "",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 111,
      "Summary": "State equilibrium of the component, then of its controllers depth first (the order of get_variable_map).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_Uoffset",
      "Defining": "Component",
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
      "Unit": "",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 112,
      "Summary": "Offset of each input in simulate: 0 where a local controller drives it (\"local\" in get_variable_map), rv_Uequilibrium elsewhere.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "parent",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 115,
      "Summary": "Parent in the layer structure: the bus.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "children",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 116,
      "Summary": "Children in the layer structure: the local controllers, then the Parameter objects.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "l_hasController",
      "Defining": "Component",
      "Group": "Simulation working data",
      "GetAccess": "Component, SolverODE",
      "SetAccess": "Component, SolverODE",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "false",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 119,
      "Summary": "Whether a local controller is attached.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "iv_CPFX",
      "Defining": "Component",
      "Group": "Continuation Power Flow",
      "GetAccess": "public",
      "SetAccess": "SolverCPF",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,1)",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 122,
      "Summary": "Indices of the states in the CPF variable vector (CPF working data).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_PQ2Bus",
      "Defining": "Component",
      "Group": "Continuation Power Flow",
      "GetAccess": "public",
      "SetAccess": "SolverCPF",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "@(t,V,u) zeros(2,1)",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@Component/Component.m",
      "Line": 123,
      "Summary": "Function of the injected power [P; Q] [pu] used by the CPF (CPF working data).",
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
      "Name": "power",
      "Defining": "component.load.power",
      "Group": "Constructor",
      "Access": "Bus",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "index",
        "~",
        "varargin"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "index",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Number of the tag."
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
          "Description": "Options of Bus.add_component, passed on to Component."
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
          "Description": "Constant-power load object."
        }
      ],
      "Signature": "obj = component.load.power(index, varargin)",
      "File": "_GUILDAobject/+component/+load/@power/power.m",
      "Line": 56,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create the load; called through `Bus.add_component`.",
      "Desc": "`index` is the tag suffix (the tag is the bus tag + `\"LPQ\"+index`). The\n`parameter` argument is ignored, and `varargin` holds the\nname-value options of `add_component`.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_hessian",
      "Defining": "component.load.power",
      "Group": "get",
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
          "Description": "States (none)."
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
          "Description": "Bus voltage [Vre; Vim] (default: the equilibrium)."
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
          "Description": "Fields Hxx, Hxv, Hvx, Hvv, R, StateName, PortName (see Component.get_hessian)."
        }
      ],
      "Signature": "sct_hessian = get_hessian(obj, x, V, u)",
      "File": "_GUILDAobject/+component/+load/@power/get_hessian.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "Component",
      "Throws": [],
      "Summary": "Return the Hessian of the energy function of the load at a point (port \"PI\").",
      "Desc": "See Component.get_hessian for the form w_dev = Hvv v with v = [theta; V] (no states).\nThe load supplies the constant power $P + jQ$ = [Pload, Qload] (negative for a load), and\nits energy function (Nishino et al., IEEJ B 2025, eq. (19)) is\n$U = -P\\theta - Q\\log V$, so $w_\\mathrm{dev} = \\nabla_v U = -[P; Q/V]$ and\n```math\nH_{vv} = \\begin{bmatrix} 0 & 0 \\\\ 0 & Q/V^2 \\end{bmatrix}\n```\n(eq. (27)), symmetric and exact at any point. Hxx, Hxv, R are 0 x 0, 0 x 2, 0 x 0.",
      "SeeAlso": [
        "Component.get_hessian",
        "get_linear_matrix"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_equilibrium",
      "Defining": "component.load.power",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "c_V",
        "c_I",
        "r_P",
        "r_Q"
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
          "Name": "c_V",
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
          "Name": "c_I",
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
          "Name": "r_P",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "real( c_V*conj(c_I) )",
          "Required": false,
          "Unit": "pu",
          "Description": "Active power injected into the bus."
        },
        {
          "Name": "r_Q",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "imag( c_V*conj(c_I) )",
          "Required": false,
          "Unit": "pu",
          "Description": "Reactive power injected into the bus."
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
          "Description": "Equilibrium state in the order of `sv_x`."
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
          "Description": "Steady input in the order of `sv_u`."
        }
      ],
      "Signature": "[rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)",
      "File": "_GUILDAobject/+component/+load/@power/get_equilibrium.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "Component",
      "Throws": [],
      "Summary": "Calculate the steady power of the load from the power flow.",
      "Desc": "Called by `set_equilibrium` with the power-flow solution. The power `[r_P; r_Q]`\nis the steady input `[Pload; Qload]`. The object is not changed.",
      "SeeAlso": [
        "fcn_I"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_Mass",
      "Defining": "component.load.power",
      "Group": "fcn",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
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
          "Description": "State vector in the order of `sv_x`."
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
          "Description": "Bus voltage as `[real; imag]`."
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
          "Description": "Input vector in the order of `sv_u`."
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
          "Description": "Dynamic parameters in the order of `sv_para`."
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
          "Description": "Network frequency (`get_Hz`)."
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
          "Description": "Mass matrix of the state equation."
        }
      ],
      "Signature": "M = fcn_Mass(obj, t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+component/+load/@power/fcn_Mass.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "Component",
      "Throws": [],
      "Summary": "Return the mass matrix of the state equation.",
      "Desc": "The state equation is `M*dx/dt = fcn_dx(...)`.\nThis model has no states: `M` is empty.",
      "SeeAlso": [
        "fcn_dx"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_Y",
      "Defining": "component.load.power",
      "Group": "fcn",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "t",
        "x",
        "V",
        "param",
        "omega0"
      ],
      "OutputNames": [
        "y"
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
          "Description": "State vector in the order of `sv_x`."
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
          "Description": "Bus voltage as `[real; imag]`."
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
          "Description": "Dynamic parameters in the order of `sv_para`."
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
          "Description": "Network frequency (`get_Hz`)."
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
          "Unit": "",
          "Description": "Output vector in the order of `sv_y`."
        }
      ],
      "Signature": "y = fcn_Y(obj, t, x, V, param, omega0)",
      "File": "_GUILDAobject/+component/+load/@power/fcn_Y.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "Component",
      "Throws": [],
      "Summary": "Calculate the output passed to local controllers.",
      "Desc": "Local controllers read the output by the names in `sv_y`.\nThis model has no output: `y` is empty.",
      "SeeAlso": [
        "Jacobi_Y"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_I",
      "Defining": "component.load.power",
      "Group": "fcn",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "t",
        "x",
        "V",
        "u",
        "param",
        "omega0"
      ],
      "OutputNames": [
        "I"
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
          "Description": "State vector in the order of `sv_x`."
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
          "Description": "Bus voltage as `[real; imag]`."
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
          "Description": "Input vector in the order of `sv_u`."
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
          "Description": "Dynamic parameters in the order of `sv_para`."
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
          "Description": "Network frequency (`get_Hz`)."
        }
      ],
      "Outputs": [
        {
          "Name": "I",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Complex current injected into the bus."
        }
      ],
      "Signature": "I = fcn_I(obj, t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+component/+load/@power/fcn_I.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "Component",
      "Throws": [],
      "Summary": "Calculate the current that the component injects into the bus.",
      "Desc": "The current follows the convention of `c_Iequilibrium`: positive into the bus.",
      "SeeAlso": [
        "Jacobi_I"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "fcn_dx",
      "Defining": "component.load.power",
      "Group": "fcn",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
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
          "Description": "State vector in the order of `sv_x`."
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
          "Description": "Bus voltage as `[real; imag]`."
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
          "Description": "Input vector in the order of `sv_u`."
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
          "Description": "Dynamic parameters in the order of `sv_para`."
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
          "Description": "Network frequency (`get_Hz`)."
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
          "Description": "Right side of the state equation in the order of `sv_x`."
        }
      ],
      "Signature": "dx = fcn_dx(obj, t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+component/+load/@power/fcn_dx.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "Component",
      "Throws": [],
      "Summary": "Calculate the right side of the state equation.",
      "Desc": "The state equation is `M*dx/dt = fcn_dx(...)`, with `M` from `fcn_Mass`.\nThe class description gives the equations.\nThis model has no states: `dx` is empty.",
      "SeeAlso": [
        "fcn_Mass",
        "Jacobi_dx"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "Jacobi_I",
      "Defining": "component.load.power",
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
        "Cix",
        "Div",
        "Diu"
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
          "Description": "State vector in the order of `sv_x`."
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
          "Description": "Bus voltage as `[real; imag]`."
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
          "Description": "Input vector in the order of `sv_u`."
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
          "Description": "Dynamic parameters in the order of `sv_para`."
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
          "Description": "Network frequency (`get_Hz`)."
        }
      ],
      "Outputs": [
        {
          "Name": "Cix",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Jacobian of the bus current `[real; imag]` with respect to `x`."
        },
        {
          "Name": "Div",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Jacobian of the bus current `[real; imag]` with respect to `V` `[real; imag]`."
        },
        {
          "Name": "Diu",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Jacobian of the bus current `[real; imag]` with respect to `u`."
        }
      ],
      "Signature": "[Cix, Div, Diu] = component.load.power.Jacobi_I(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+component/+load/@power/Jacobi_I.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Calculate the Jacobians of the bus current.",
      "Desc": "Analytic derivatives of `fcn_I`, with the current split as `[real; imag]`.",
      "SeeAlso": [
        "fcn_I"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "Jacobi_Y",
      "Defining": "component.load.power",
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
        "param",
        "omega0"
      ],
      "OutputNames": [
        "Cyx",
        "Dyv"
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
          "Description": "State vector in the order of `sv_x`."
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
          "Description": "Bus voltage as `[real; imag]`."
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
          "Description": "Dynamic parameters in the order of `sv_para`."
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
          "Description": "Network frequency (`get_Hz`)."
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
          "Description": "Jacobian of `fcn_Y` with respect to `x`."
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
          "Description": "Jacobian of `fcn_Y` with respect to `V` `[real; imag]`."
        }
      ],
      "Signature": "[Cyx, Dyv] = component.load.power.Jacobi_Y(t, x, V, param, omega0)",
      "File": "_GUILDAobject/+component/+load/@power/Jacobi_Y.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Calculate the Jacobians of the output.",
      "Desc": "Analytic derivatives of `fcn_Y` at the given point.",
      "SeeAlso": [
        "fcn_Y"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "Jacobi_dx",
      "Defining": "component.load.power",
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
          "Description": "State vector in the order of `sv_x`."
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
          "Description": "Bus voltage as `[real; imag]`."
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
          "Description": "Input vector in the order of `sv_u`."
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
          "Description": "Dynamic parameters in the order of `sv_para`."
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
          "Description": "Network frequency (`get_Hz`)."
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
          "Description": "Jacobian of `fcn_dx` with respect to `x`."
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
          "Description": "Jacobian of `fcn_dx` with respect to `V` `[real; imag]`."
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
          "Description": "Jacobian of `fcn_dx` with respect to `u`."
        }
      ],
      "Signature": "[Axx, Bxv, Bxu] = component.load.power.Jacobi_dx(t, x, V, u, param, omega0)",
      "File": "_GUILDAobject/+component/+load/@power/Jacobi_dx.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Calculate the Jacobians of the state equation.",
      "Desc": "Analytic derivatives of `fcn_dx` at the given point, used for linearization.",
      "SeeAlso": [
        "fcn_dx"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "getCompPQ",
      "Defining": "component.load.power",
      "Group": "Other",
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
        "u",
        "param"
      ],
      "OutputNames": [
        "PQ"
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
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "States (unused)."
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
          "Unit": "",
          "Description": "Bus voltage (unused)."
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
          "Description": "Input `[Pload; Qload]`."
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
          "Description": "Dynamic parameters (unused)."
        }
      ],
      "Outputs": [
        {
          "Name": "PQ",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Active and reactive power `[P; Q]` injected into the bus."
        }
      ],
      "Signature": "PQ = getCompPQ(obj, x, V, u, param)",
      "File": "_GUILDAobject/+component/+load/@power/getCompPQ.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the power that the load injects into the bus.",
      "Desc": "Used by the continuation power flow (`f_PQ2Bus`). The power is\nthe input `u = [Pload; Qload]`; `x`, `V` and `param` are not used.",
      "SeeAlso": [
        "fcn_I"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "pack_hessian",
      "Defining": "Component",
      "Group": "pack",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "H",
        "R"
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
          "Name": "H",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Hessian (or port-balance Jacobian) over [x; theta; V]."
        },
        {
          "Name": "R",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Matrix R of dx/dt = -R (Hxx x + Hxv v)."
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
      "Signature": "sct_hessian = pack_hessian(obj, H, R)",
      "File": "_GUILDAsystem/@Component/pack_hessian.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Split the Hessian over [x; theta; V] into the blocks of get_hessian and add the names.",
      "Desc": "Shared by the get_hessian overrides: H is (n_x+2) x (n_x+2), ordered [x; theta; V],\nwith the rows of theta and V the Jacobian of w_dev = -[P; Q/V]; R is n_x x n_x.",
      "SeeAlso": [
        "get_hessian"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "gui_content",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/gui_content.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Pages of the GUI (launch_gui): the Equilibrium table, then the pages of PowerSystemModel.",
      "Desc": "- \"Equilibrium\" (\"table\"): columns Kind, Name and Value, one row per state (`sv_x`,\n  `rv_Xequilibrium`), per input (`sv_u`, `rv_Uequilibrium`), then the voltage\n  `c_Vequilibrium` and the current `c_Iequilibrium`. Value is text (complex as a+bj).\n  No rows before the equilibrium is computed; the header shows whether it is stale.",
      "SeeAlso": [
        "LayerPackage.gui_content"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "handle_edit",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/handle_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Mark the stale tags of the component for its own edits (LayerPackage.log_edit).",
      "Desc": "dynamics (its tab_parameter.dynamics)              equilibrium, odefcn\n  Topology (local controller add, replace, remove)   equilibrium\n  input (set_input: rv_Uequilibrium)                 equilibrium\nEdits of other layers, and powerflow edits (the power flow of the network), are not\nthe component's.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_odefcn",
      "Defining": "Component",
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
      "File": "_GUILDAsystem/@Component/set_odefcn.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Bind the parameters and the network frequency into the f_* function handles.",
      "Desc": "Does nothing when they are up to date: the stale tag odefcn is empty and the network\nfrequency equals r_odefcnHz. Otherwise builds them, clears odefcn and stores the\nfrequency in r_odefcnHz. Called by initialize (and by get_sys of a layer without a\nnetwork).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_input",
      "Defining": "Component",
      "Group": "Construction and editing",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "rv_u"
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
          "Name": "rv_u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal",
            "mustBeFinite"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Inputs in the order of sv_u."
        }
      ],
      "Outputs": [],
      "Signature": "set_input(obj, rv_u)",
      "File": "_GUILDAsystem/@Component/set_input.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:Component:InputSize"
      ],
      "Summary": "Set the inputs of the component at the equilibrium (rv_Uequilibrium).",
      "Desc": "The inputs, in the order of sv_u, are held for net.initialize(Method=\"FixedInput\"),\nwhich solves the states, the bus voltages and the currents with these inputs (only the\nPmech of the first generator of the slack bus is solved too). The edit is logged\n(LayerPackage.log_edit, tag \"input\"): it makes the equilibrium of the component stale\nand is listed in net.sct_stale.input, so the analyses (simulate, get_sys,\nthe continuation power flow) and net.initialize() stop until\nnet.initialize(Method=\"FixedInput\") is run. net.initialize(Method=\"powerflow\") or\nMethod=\"OPF\" replaces the edited inputs with the values of their solution.\nA value equal to the held one changes nothing.",
      "SeeAlso": [
        "PowerNetwork.initialize",
        "Component.rv_Uequilibrium"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();\ngen = net.a_Bus{2}.a_Component{1};\nu = gen.rv_Uequilibrium;\nu(1) = u(1) + 0.1;                         % Pmech\ngen.set_input(u);\nnet.initialize(Method=\"FixedInput\");       % the slack generator balances the power\n```",
      "Deprecated": ""
    },
    {
      "Name": "remove_local_controller",
      "Defining": "Component",
      "Group": "Construction and editing",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_tag",
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
          "Name": "s_tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tag (s_tag) of the local controller to remove."
        },
        {
          "Name": "RemoveNested",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Also remove the controller nested in the removed one (the PSS under an AVR)."
        }
      ],
      "Outputs": [],
      "Signature": "remove_local_controller(obj, s_tag, Name=Value)",
      "File": "_GUILDAsystem/@Component/remove_local_controller.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:Component:ControllerHasNested",
        "GUILDA:Component:ControllerNotFound"
      ],
      "Summary": "Remove a local controller from the component by tag.",
      "Desc": "The tag can name a top-level controller (the AVR or \"local\" controller, or the\ngovernor) or the PSS under the AVR; the other top-level controller stays attached.\nAn AVR that still has a PSS feeding it cannot be removed unless `RemoveNested` is true,\nwhich removes the PSS too. Remove the PSS alone by its own tag. The removed controllers\nare deleted, so a handle to them becomes invalid.\nThe removal is a \"Topology\" edit, so the equilibrium of the component becomes stale.\nWhen a global controller controls the component and the edit changes where one of its\noutputs goes (the \"global\" rows of net.get_variable_map), an INFO message\n(GUILDA:Component:GconRouteChanged) lists the outputs that go elsewhere now.",
      "SeeAlso": [
        "Component.add_local_controller",
        "LocalController"
      ],
      "Examples": "```matlab\ngen = net.a_Bus{1}.a_Component{1};\navr = gen.add_local_controller(\"avr-ST1\");\npss = gen.add_local_controller(\"pss-PSS1\");\ngen.remove_local_controller(pss.s_tag);                       % the PSS only\ngen.add_local_controller(\"pss-PSS1\");\ngen.remove_local_controller(avr.s_tag, RemoveNested=true);    % the AVR and its PSS\ngov = gen.add_local_controller(\"gov-LPT1\");\ngen.remove_local_controller(gov.s_tag);                       % the governor\n```",
      "Deprecated": ""
    },
    {
      "Name": "add_local_controller",
      "Defining": "Component",
      "Group": "Construction and editing",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Key",
        "opt"
      ],
      "OutputNames": [
        "con"
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
          "Name": "Key",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "char",
          "Validators": [
            "tools.mustBeKeyOf(Key, \"LocalController\")"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Local controller model key, e.g. \"avr-ST1\" or \"pss-PSS1\"."
        },
        {
          "Name": "parameter",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeA(opt.parameter, [\"struct\",\"table\"])"
          ],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Constructor parameters (struct or one-row table of Name=Value); omitted ones use the class defaults."
        }
      ],
      "Outputs": [
        {
          "Name": "con",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Added LocalController object."
        }
      ],
      "Signature": "con = add_local_controller(obj, Key, Name=Value)",
      "File": "_GUILDAsystem/@Component/add_local_controller.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:Component:NotExtAvr",
        "GUILDA:Component:PssParentKey",
        "GUILDA:Component:InvalidControllerKey",
        "GUILDA:Component:ControllerOutputOverlap",
        "GUILDA:Component:ControllerOutput"
      ],
      "Summary": "Build a local controller (AVR, PSS, governor, LQR, ...) from its model key, attach it to the component and return it.",
      "Desc": "`Key` is the model key of a local controller class (`keys(GUILDA.keymap(\"LocalController\"))`\nlists them). `parameter` gives the parameters of the constructor as a struct\n(or a one-row table) of Name=Value; omitted fields keep the class defaults. The\ncontroller tag is the component tag, the class header and a number, e.g. \"B001SG1CA1\".\nOne controller is added per call.\n\nThe role of the controller class (`s_role`) says where it goes:\n\n- \"avr\": attached to the component (the PSS feeds it)\n- \"pss\": attached to the AVR of the component\n- \"local\": attached to the component in the place of an AVR (e.g. \"local-LQR\")\n- \"governor\": attached to the component beside the AVR or \"local\" controller (it\n  drives Pmech, e.g. \"gov-LPT1\")\n\nA component has two slots for top-level controllers: the AVR or \"local\" controller\n(with the PSS under an AVR), then the governor. a_LocalController lists them in this\norder whatever the order of attachment, and so do the variables (get_variable_map).\nA controller reads the outputs and states of the component it observes by the names\nof its inputs sv_u (\"Xall\" / \"Yall\": all the states / all the outputs), and its outputs\ndrive the inputs of the component of the same name (an input event or a global\ncontroller on such an input adds to them).\nEvery synchronous generator has a Static AVR (\"avr-static\") and a Static governor\n(\"gov-static\") from its creation (controller.avr.Static, controller.governor.Static).\nThey are replaced like any other controller, but without the warning, and are not\ncounted in the numbers of the tags.\nA new AVR or \"local\" controller replaces the attached one. The PSS of an old AVR moves\nto a new AVR, and is deleted when the new controller is not an AVR. A new PSS\nreplaces the attached one, and a new governor the attached governor. Replaced\ncontrollers are deleted, so a handle to them becomes invalid.\nEvery write to a_LocalController is checked against these slots (Component.a_LocalController\nand LocalController.a_LocalController reject any other list: GUILDA:Component:ControllerSlots,\nGUILDA:LocalController:NestedControllerSlot). A generator returns them as gen.avr, gen.pss and\ngen.governor, and gen.set_avr, set_pss and set_governor call this method.\nThe two top-level controllers must drive different inputs: a governor and an AVR or\n\"local\" controller with a common output (e.g. a local_LQR on all the inputs, Pmech\namong them) are rejected with an error, unless the attached one is a default Static:\nit is then removed (a local_LQR on all the inputs takes the place of both Statics).\nA role other than \"avr\", \"pss\", \"local\" or \"governor\" is rejected with an error, and so\nis an output that matches no input of the component (for a PSS, of its AVR), e.g. an\nAVR on a load. A rejected call leaves the component as it was.\nA misspelled input is not an error, because it has the same form as an input left\nunconnected on purpose.\nEach addition is a \"Topology\" edit, so the equilibrium of the component becomes stale.\nWhen a global controller controls the component and the edit changes where one of its\noutputs goes (the \"global\" rows of net.get_variable_map), an INFO message\n(GUILDA:Component:GconRouteChanged) lists the outputs that go elsewhere now.",
      "SeeAlso": [
        "Component.remove_local_controller",
        "LocalController",
        "controller.avr.AVR_ST1",
        "controller.pss.PSS1",
        "controller.governor.IEEJ_LPT1",
        "controller.local_LQR"
      ],
      "Examples": "```matlab\ngen = net.a_Bus{1}.a_Component{1};\navr = gen.add_local_controller(\"avr-ST1\", parameter=struct(kap=30));\npss = gen.add_local_controller(\"pss-PSS1\");                          % under the AVR\ngov = gen.add_local_controller(\"gov-LPT1\", parameter=struct(PLM=5));\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_spring_node",
      "Defining": "Component",
      "Group": "get",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "rm_x",
        "rm_V",
        "rm_I",
        "rm_u",
        "rr_param"
      ],
      "OutputNames": [
        "cv_E",
        "rv_P",
        "rv_Iq",
        "cv_I"
      ],
      "Arguments": [
        {
          "Name": "rm_x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "States (n_x × n_t) in the order of `sv_x`."
        },
        {
          "Name": "rm_V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus voltage (2 × n_t) as `[real; imag]`."
        },
        {
          "Name": "rm_I",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Current attributed to this component (2 × n_t) as `[real; imag]`."
        },
        {
          "Name": "rm_u",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Inputs (n_u × n_t) in the order of `sv_u`."
        },
        {
          "Name": "rr_param",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Dynamic parameters in the order of `sv_para`."
        }
      ],
      "Outputs": [
        {
          "Name": "cv_E",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Complex phasor of the own node (1 × n_t); [] when the component has no own node."
        },
        {
          "Name": "rv_P",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Active power at the node (1 × n_t)."
        },
        {
          "Name": "rv_Iq",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Reactive-current magnitude Q/|node voltage| (1 × n_t)."
        },
        {
          "Name": "cv_I",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Complex current injected into the bus (1 × n_t)."
        }
      ],
      "Signature": "[cv_E, rv_P, rv_Iq, cv_I] = Component.get_spring_node(rm_x, rm_V, rm_I, rm_u, rr_param)",
      "File": "_GUILDAsystem/@Component/get_spring_node.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the own node of the component and the sizes of its arrows for the spring-mass drawings.",
      "Desc": "The spring-mass drawings of a network (`GraphSpring2D`, `GraphSpring3D`) draw the voltage\nphasors as nodes and the lines and machine reactances as springs. This method tells the\ndrawer whether the component has a node of its own (such as the internal voltage of a\nsynchronous generator, joined to its bus by the machine reactance) and gives the active\npower and reactive current that size the arrows of the component.\n\nAll arguments are vectorized over time: column k is time k (n_t columns).\n\nThe base class has no own node: it returns `cv_E = []` and evaluates the power at the bus\nvoltage V with the current `rm_I` attributed to this component by the caller:\nP = real(V.*conj(I)), Iq = imag(V.*conj(I))./abs(V) and `cv_I = I`. A model with its own\nnode overrides this static method, computes its node phasor E and its injected current\nfrom `rm_x`, `rm_V`, `rm_u` and `rr_param` (ignoring `rm_I`) and evaluates the power at E.",
      "SeeAlso": [
        "component.generator.one_axis.get_spring_node",
        "PowerNetwork.plot_spring_model",
        "ResultODE.plot_spring_model"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_linear_matrix",
      "Defining": "Component",
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
          "Description": "States of the component."
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
          "Description": "Bus voltage [Vre; Vim]."
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
          "Description": "Inputs of the component."
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
      "File": "_GUILDAsystem/@Component/get_linear_matrix.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Get the linear block of the component alone at a point.",
      "Desc": "Returns the linear model of the component without its local controllers at the\nstates x, the bus voltage V = [Vre; Vim] and the inputs u, as a struct with the fields\nA, B, C, D, E (E dx/dt = A x + B [V; u], [I; y] = C x + D [V; u]) and StateName,\nInputName, OutputName (string columns). The names are the Labels of the variable map\n(comp.get_variable_map): the inputs are the voltage of the bus and the inputs u, the\nstates are the states, and the outputs are the current [Ire; Iim] (tagged with the\ncomponent) and the outputs y (\"Y_\" + name for an output with the name of a state).\n\nget_sys connects these blocks (SolverLIN.solve); a controller that designs with the\nlinear model of the component alone (controller.local_LQR) calls it directly. The\nJacobians are those of the simulation (f_JacobiDx, f_JacobiI, f_JacobiY); a model that\nreturns [] for a block gives zeros. The model is not changed.",
      "SeeAlso": [
        "PowerSystemModel.get_sys",
        "SolverLIN.solve"
      ],
      "Examples": "```matlab\ncomp = net.a_Bus{1}.a_Component{1};\nV = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];\nS = comp.get_linear_matrix(comp.rv_Xequilibrium, V, comp.rv_Uequilibrium);\neig(S.A, S.E)\n```",
      "Deprecated": ""
    },
    {
      "Name": "validate",
      "Defining": "Component",
      "Group": "Queries and checks",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
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
          "Description": "Struct of tables: dx, I (residuals at the point), Axx, Bxv, ... (absolute differences of each Jacobian block), contract (PASS, FAIL or INFO of each check), inputs (connection source of each input)."
        }
      ],
      "Signature": "flag = validate(obj, l_message)",
      "File": "_GUILDAsystem/@Component/validate.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Check the model functions of the component against the contract of Component.",
      "Desc": "Evaluates the model at the equilibrium, or at a random point of unit V and injected\ncurrent when the equilibrium is not set (the current gives the power of get_equilibrium).\nThe model functions take no bus current, and the output fcn_Y takes no input. A broken model does not stop the check: it is reported as FAIL\nin flag.contract and the values that cannot be computed are NaN. Analytic Jacobians\n(Jacobi_*) are compared with finite differences of fcn_dx, fcn_I and fcn_Y; a component\nwithout them uses those same finite differences, so there is nothing to compare.\n\nget_equilibrium is called as the model requires it, so a model that stores values\nthere (e.g. the loads) stores those of the evaluation point: run net.initialize after\nvalidating a component that has no equilibrium.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "move_local_controllers",
      "Defining": "Component",
      "Group": "Construction and editing",
      "Access": "Bus",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "comp_new"
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
          "Name": "comp_new",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "Component",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Component that receives the controllers."
        }
      ],
      "Outputs": [],
      "Signature": "move_local_controllers(obj, comp_new)",
      "File": "_GUILDAsystem/@Component/move_local_controllers.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Move the local controllers to another component, with the controllers nested in them.",
      "Desc": "Each top-level controller (the AVR or \"local\" controller, and the governor) goes to the\nsame slot of the new component. The default Static controllers (controller.avr.Static,\ncontroller.governor.Static) do not move: they stay on this component, and the new\ncomponent keeps its own defaults in the slots that no moved controller takes (the\ndefaults it loses are deleted). A PSS under the Static AVR moves under the Static AVR of\nthe new component.\n\nCalled by Bus.replace_component, which checks first that the new component suits them.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_equilibrium",
      "Defining": "Component",
      "Group": "Called by analyses",
      "Access": "Bus",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "c_V",
        "c_I",
        "r_P",
        "r_Q",
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
          "Name": "c_V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus voltage phasor."
        },
        {
          "Name": "c_I",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Current injected by the component."
        },
        {
          "Name": "r_P",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "real( c_V*conj(c_I) )",
          "Required": false,
          "Unit": "pu",
          "Description": "Active power injected by the component."
        },
        {
          "Name": "r_Q",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "imag( c_V*conj(c_I) )",
          "Required": false,
          "Unit": "pu",
          "Description": "Reactive power injected by the component."
        },
        {
          "Name": "c_XU",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "cell",
          "Validators": [],
          "Default": "{}",
          "Required": false,
          "Unit": "",
          "Description": "{x, u}: the equilibrium to store as given; {} computes it with get_equilibrium."
        }
      ],
      "Outputs": [],
      "Signature": "set_equilibrium(obj, c_V, c_I, r_P, r_Q, Name=Value)",
      "File": "_GUILDAsystem/@Component/set_equilibrium.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Compute and store the state and input equilibria from the bus voltage and current.",
      "Desc": "Called by Bus.set_equilibrium and initialize. With c_XU = {x, u} (the solution of\ninitialize(Method=\"FixedInput\")) the state and input equilibria are stored as given and\nget_equilibrium is not called. Clears the stale tag equilibrium. The\nequilibria of the local controllers (each nested controller too, depth first) are\nthe outputs of their get_equilibrium(c_V, u, x) (get_equilibrium_at), stored here; the controllers are then\ninitialized with l_equilibrium = true (LocalController.initialize), which clears theirs. Stale handles\nare rebuilt first: a controller may design from them (local_LQR).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "initialize",
      "Defining": "Component",
      "Group": "Called by analyses",
      "Access": "Bus",
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
      "Signature": "initialize(obj)",
      "File": "_GUILDAsystem/@Component/initialize.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Bring the component and its local controllers up to date (PowerNetwork.initialize,",
      "Desc": "through Bus.initialize, after the power flow is written).\n\nRebuilds the handles when they are stale (the stale tag odefcn, or a network frequency\nother than r_odefcnHz). When the equilibrium of the component or of one of its local\ncontrollers is still stale, recomputes it from the held V and I (set_equilibrium; the\npower flow is up to date by then), which initializes the controllers with\nl_equilibrium = true; otherwise the controllers are initialized with false.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_variable_map",
      "Defining": "Component",
      "Group": "Called by analyses",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_form"
      ],
      "OutputNames": [
        "tab",
        "tab_connection"
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
          "Name": "s_form",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(s_form, [\"table\",\"rows\"])"
          ],
          "Default": "\"table\"",
          "Required": false,
          "Unit": "",
          "Description": "\"rows\" (internal): return the rows without the tables."
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
          "Description": "One row per variable or signal: Index, Kind, Role, Owner, Name, Label, Bus, Equilibrium."
        },
        {
          "Name": "tab_connection",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One row per connection: Index, Kind, Source, Target, SourceIndex, TargetIndex."
        }
      ],
      "Signature": "[tab, tab_connection] = get_variable_map(obj, s_form)",
      "File": "_GUILDAsystem/@Component/get_variable_map.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:Component:InputDrivenTwice"
      ],
      "Summary": "Return the variable map of the component and the connections inside it.",
      "Desc": "Variable map of the component: the rows of net.get_variable_map() that belong to it,\nin the same relative order (see PowerNetwork.get_variable_map for the columns):\n  1. x: states of the component, then of its local controllers (depth first: the AVR or\n     \"local\" controller, the PSS attached under the AVR, then the governor)\n  2. Vre, Vim of its bus\n  3. u: inputs of the component\n  4. uc: inputs of its local controllers (depth first)\n  5. y: outputs of the component (signals)\n  6. yc: outputs of its local controllers (signals)\nThe rows of the kinds x, Vre, Vim, u and uc come first: they are the order of the point\nvector of comp.get_sys(point), every value used as given. Index counts from 1 here. The column Equilibrium is\nas in the map of the network (NaN in every row before net.initialize).\ntab_connection lists the connections inside the component: the outputs of the local\ncontrollers into the inputs of the same name of their parent (\"local\"), the outputs and\nstates of the component into the inputs of the controllers that observe them\n(\"observe\"), and the equilibrium of an input without either (\"equilibrium\"). The\nconnections of the global controllers are only in the map of the network.\nget_variable_map(\"rows\") is the form used inside the map: see PowerNetwork.get_variable_map.",
      "SeeAlso": [
        "PowerNetwork.get_variable_map",
        "PowerSystemModel.get_sys"
      ],
      "Examples": "```matlab\n[tab, tab_connection] = net.a_Bus{1}.a_Component{1}.get_variable_map();\ntab(tab.Kind == \"x\", :)\n```",
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
