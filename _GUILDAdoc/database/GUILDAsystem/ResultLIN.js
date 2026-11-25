(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["ResultLIN"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "ResultLIN",
  "properties": [
    {
      "Name": "tab_variable",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "table()",
      "Validation": {
        "Class": "table",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 144,
      "Summary": "Variable map at the time of the analysis: the order of the rows and columns of the Jacobian blocks.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_t",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "NaN",
      "Validation": {
        "Class": "double",
        "Size": "(1,:)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 145,
      "Summary": "Time of each section: the times of {sim, rv_t}, 1:n for a matrix of points, NaN for the equilibrium or a vector.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Index",
      "Defining": "ResultLIN",
      "Group": "Section",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 148,
      "Summary": "Section shown by rv_point, rm_Axx ... rm_E, sct_model and A ... OutputName: 1 ... numel(rv_t) (default 1).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_point",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 151,
      "Summary": "Point of the linearization of section Index in the order of tab_variable (the equilibrium when output.l_equilibrium is true).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double (:,1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_Axx",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 152,
      "Summary": "d(dx/dt)/dx: Jacobian of the state equations with respect to the states (section Index).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_Axv",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 153,
      "Summary": "d(dx/dt)/dv: Jacobian of the state equations with respect to the bus voltages (section Index).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_Bx",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 154,
      "Summary": "d(dx/dt)/du: Jacobian of the state equations with respect to the inputs (section Index).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_Avx",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 155,
      "Summary": "Jacobian of the bus current balance (Y v - I) with respect to the states (section Index).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_Avv",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 156,
      "Summary": "Jacobian of the bus current balance (Y v - I) with respect to the bus voltages: Y minus the component terms (section Index).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_Bv",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 157,
      "Summary": "Jacobian of the bus current balance (Y v - I) with respect to the inputs (section Index).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_E",
      "Defining": "ResultLIN",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 158,
      "Summary": "Mass matrix of the state equations (the algebraic equations have none; section Index).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Type",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"ODE\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": [
          "mustBeMember(Type,[\"ODE\",\"DAE\"])"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 161,
      "Summary": "Model of A ... OutputName: \"ODE\" (the bus voltages eliminated) or \"DAE\" (the connected model). Default: the Type of get_sys.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Form",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"descriptor\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": [
          "mustBeMember(Form,[\"descriptor\",\"absorbed\",\"hessian\"])"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 162,
      "Summary": "View of A ... E: \"descriptor\", \"absorbed\" (E^-1 in the dynamic rows) or \"hessian\" (energy-function form, from get_sys(Form=\"hessian\")). Default: the Form of get_sys.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_asymmetry",
      "Defining": "ResultLIN",
      "Group": "Energy function",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 165,
      "Summary": "Asymmetry norm(H - H.', \"fro\")/norm(H, \"fro\") of the bus block H = Hvv + Hvv_net (port PI) of the hessian form of each section: 0 when lossless; NaN without the form.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double (1,:)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "A",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 168,
      "Summary": "State matrix of the model of section Index (E dx/dt = A x + B u, y = C x + D u): get_ss(Type) with the Input and Output of get_sys.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "B",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 169,
      "Summary": "Input matrix of the model.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "C",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 170,
      "Summary": "Output matrix of the model.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "D",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 171,
      "Summary": "Feedthrough matrix of the model.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "E",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 172,
      "Summary": "Mass matrix of the model (singular for \"DAE\").",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "StateName",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 173,
      "Summary": "Names of the states of the model.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string (:,1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "InputName",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 174,
      "Summary": "Names of the inputs of the model.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string (:,1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "OutputName",
      "Defining": "ResultLIN",
      "Group": "Model",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 175,
      "Summary": "Names of the outputs of the model (the network has none by default).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string (:,1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_network",
      "Defining": "ResultLIN",
      "Group": "Data of the calculation",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct()",
      "Validation": {
        "Class": "struct",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 178,
      "Summary": "Snapshot of the network at the linearization: struct(net, false) (the network layer only; otherwise empty).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_target",
      "Defining": "ResultLIN",
      "Group": "Data of the calculation",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(1,0)",
      "Validation": {
        "Class": "string",
        "Size": "(1,:)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 179,
      "Summary": "Targets of a contribution result (get_contribution: its sections are the part of these elements); empty for an ordinary result.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_model",
      "Defining": "ResultLIN",
      "Group": "Model data",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": true,
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
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 182,
      "Summary": "Data of get_ss for section Index: the connected model sct_sys and, for the network, cm_Y, cv_V, sv_I (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "c_section",
      "Defining": "ResultLIN",
      "Group": "Sections",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "{struct()}",
      "Validation": {
        "Class": "cell",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 185,
      "Summary": "Connected model of each section (SolverLIN.solve; for the network also cm_Y, cv_V, sv_I).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_point",
      "Defining": "ResultLIN",
      "Group": "Sections",
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
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 186,
      "Summary": "Point of each section (one column per section) in the order of tab_variable.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "i_index",
      "Defining": "ResultLIN",
      "Group": "Sections",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "1",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 187,
      "Summary": "Section of Index.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "c_cache",
      "Defining": "ResultLIN",
      "Group": "Cache",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "{struct()}",
      "Validation": {
        "Class": "cell",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 190,
      "Summary": "Models of A ... OutputName of each section by Type, computed when first read.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "flag",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 39,
      "Summary": "Success or convergence flag (second output): logical, or a numeric exit flag positive on success.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "logical or double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "output",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct()",
      "Validation": {
        "Class": "struct",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 40,
      "Summary": "Solver details, as returned by the analysis (third output).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "options",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct()",
      "Validation": {
        "Class": "struct",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 41,
      "Summary": "Effective settings: the section of GUILDA.setting of the analysis, with the Name-Value options of the call applied.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_solver",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 42,
      "Summary": "Class name of the solver object that ran the analysis.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_elapsed",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "Unit": "s",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 43,
      "Summary": "Elapsed time of the analysis.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_network",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 44,
      "Summary": "Tag of the analysed network at the time of the analysis.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_PowerNetwork",
      "Defining": "ResultBase",
      "Group": "Network",
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
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 47,
      "Summary": "Analysed network: a reference, not a copy (it may have been edited since).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "PowerNetwork (1x1 or empty)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "l_success",
      "Defining": "ResultBase",
      "Group": "Result",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 50,
      "Summary": "True when the analysis succeeded (see is_success).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "logical",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "disp_mode",
      "Defining": "ResultLIN",
      "Group": "disp",
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
          "Description": ""
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
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model whose modes are shown: \"ODE\" or \"DAE\"; the Type of the result when omitted."
        },
        {
          "Name": "MinFrequency",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeNonnegative"
          ],
          "Default": "0",
          "Required": false,
          "Unit": "Hz",
          "Description": "Smallest frequency shown; > 0 keeps the oscillatory modes only."
        },
        {
          "Name": "MaxFrequency",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeNonnegative"
          ],
          "Default": "Inf",
          "Required": false,
          "Unit": "Hz",
          "Description": "Largest frequency shown."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeSection"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section (1 ... numel(rv_t)) or \"all\" (every section); res.Index when omitted."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time: the section whose rv_t is nearest; overrides Index."
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
          "Description": "Text of the table when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_mode(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/disp_mode.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Display the modes of the linear model as a table.",
      "Desc": "Prints the rows of get_mode: one line per mode with its number, the eigenvalue\n(real and imaginary part [1/s]), the frequency [Hz], the damping ratio [%] (\"-\" for a\nreal mode) and the dominant owner (DominantOwner of get_mode), under a title line with\nthe network, the Type, the section and the number of modes. MinFrequency > 0 keeps the\noscillatory modes with a frequency of at least MinFrequency (as in get_mode), and\nMaxFrequency those of at most MaxFrequency.\n\nIndex chooses the section (default res.Index; see ResultLIN), and Time, when given, the\nsection whose time rv_t is nearest to it; Index \"all\" shows every section, the blocks\nseparated by an empty line. With one output it returns the text instead of displaying it.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_mode",
        "ResultLIN.disp_summary"
      ],
      "Examples": "```matlab\nres = network.IEEE9bus().get_sys();\nres.disp_mode()                                   % every mode\nres.disp_mode(MinFrequency=0.1, MaxFrequency=2)   % electromechanical modes\ns = res.disp_mode(Index=\"all\");                   % every section, as text\n```",
      "Deprecated": ""
    },
    {
      "Name": "disp_summary",
      "Defining": "ResultLIN",
      "Group": "disp",
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
          "Description": ""
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeSection"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section (1 ... numel(rv_t)) or \"all\" (every section); res.Index when omitted."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time: the section whose rv_t is nearest; overrides Index."
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
          "Description": "Summary text when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_summary(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/disp_summary.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Display a summary of the linearization result.",
      "Desc": "Shows one block per section: a title line with the network, the layer, the section and\nwhether it is usable (output.lv_flag), and one bullet per item:\n\n- Contribution of (a result of get_contribution only): its targets sv_target. The\n  numbers below are of the part alone and have no meaning for the whole system.\n- Model: the Type and Port of the result (a port model for a layer other than the\n  network), the point (the equilibrium, a given point, or the section at its rv_t: the\n  time of {sim, rv_t}, the column of a matrix of points) and the Form.\n- Energy function (Form \"hessian\" available): the asymmetry rv_asymmetry of the bus\n  block of the section, 0 for a lossless model.\n- Size: the numbers of states n_x, bus variables n_v and inputs n_u.\n- Status: the issue of the section (output.sv_issue, \"none\" when usable) and the\n  reciprocal condition number of Avv (output.rv_rcond_Avv); then its message, if any.\n- Modes: the largest real part of the eigenvalues of get_eigenvalue(Type), the number of\n  unstable modes (real part above 1e-6) and of zero modes (|lambda| up to\n  1e-6*max(1, max|lambda|), as in get_mode); \"not available\" with the reason when the\n  model of the Type cannot be made.\n- Kernel: the dimension of the kernel of the Jacobian of the DAE (get_kernel: one\n  rotation per island), for the network.\n\nIndex chooses the section (default res.Index; see ResultLIN); Index \"all\" shows every\nsection, the blocks separated by an empty line. It reads only the stored result. With\none output it returns the text instead of displaying it.",
      "SeeAlso": [
        "ResultLIN.disp_mode",
        "ResultLIN.get_eigenvalue",
        "ResultLIN.get_kernel",
        "ResultPF.disp_summary"
      ],
      "Examples": "```matlab\nres = network.IEEE9bus().get_sys();\nres.disp_summary()\ns = res.disp_summary(Index=\"all\");   % every section, as text\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_reduced_matrix",
      "Defining": "ResultLIN",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "target",
        "opt"
      ],
      "OutputNames": [
        "sct_reduced"
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
          "Name": "target",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [
            "mustBeNonempty"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags and class (or package) names of the elements whose variables are eliminated."
        },
        {
          "Name": "State",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.State, [\"settled\",\"fixed\"])"
          ],
          "Default": "\"settled\"",
          "Required": false,
          "Unit": "",
          "Description": "Dynamic states of the targets: \"settled\" (eliminated, E dx/dt = 0) or \"fixed\" (held at the point, removed)."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeSection"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section (1 ... numel(rv_t)) or \"all\" (a struct array, one per section); res.Index when omitted."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time: the section whose rv_t is nearest; overrides Index."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_reduced",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "rm_value (the reduced matrix), sv_row, sv_column (names of the kept variables), sv_eliminated (all target variables), sv_held (the held states), s_state (1 x n_t for Index \"all\")."
        }
      ],
      "Signature": "sct_reduced = get_reduced_matrix(obj, target, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/get_reduced_matrix.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NetworkOnly",
        "GUILDA:ResultLIN:SingularReduction"
      ],
      "Summary": "Get the Jacobian of the DAE with the variables of elements eliminated (Schur complement).",
      "Desc": "J is the full state matrix A of get_ss(\"DAE\") over [x; v] (the dynamic states and the\nbus variables) in the Port of the result. The variables owned by the elements in target\nare eliminated, the rest r are kept. The row i of the result is the equation of the\nkept variable i (the state equation of a state; for a bus, the balance w of the Port:\nP for theta, Q for rho in \"PQ\"). State chooses how the dynamic states of the targets\nenter (a variable is dynamic when its row of E is not zero, algebraic otherwise):\n\n- \"settled\" (default): every variable x of the targets, the states included, is\n  eliminated by the Schur complement\n\n  ```\n  J_red = Jrr - Jrx / Jxx * Jxr\n  ```\n\n  so the equations of x are held at zero (E dx/dt = 0): the states follow the other\n  variables quasi-statically.\n- \"fixed\": the dynamic states of the targets are held at the point\n  (Delta x = 0): their rows and columns are removed, with no Schur term. Only the\n  algebraic variables a of the targets (the theta, rho of a target bus, or a variable\n  with a zero row of E) are eliminated, by the Schur complement\n\n  ```\n  J_red = Jrr - Jra / Jaa * Jar\n  ```\n\n  which is J(r, r) when the targets have no algebraic variables. The held states are\n  in sv_held.\n\ntarget selects elements as in get_contribution: tags (the Owner column of the variable\nmap, or the tag of a bus) and class names, a class taking every element of that class or\nof its subclasses and a package every class in it; a target that matches no element\nstops with GUILDA:ResultLIN:UnknownTarget. The bus variables (theta, rho, ...) are owned\nby their bus (class \"Bus\"). Eliminating everything but the bus variables, e.g. target\n[\"Component\",\"LocalController\"] (with \"GlobalController\" when the model has one; a class\nwithout elements stops as in get_contribution), gives the reduced admittance-like\nmatrix seen from the buses (縮約アドミタンス): with State \"settled\" the steady-state\ndI/dV (the states follow), with \"fixed\" the instantaneous one (the states held). Elements without\nvariables (branches, components without states) eliminate nothing. A singular Jxx\n(\"settled\") or Jaa (\"fixed\") stops with GUILDA:ResultLIN:SingularReduction.\n\nIndex chooses the section (default res.Index; see ResultLIN), and Time, when given, the\nsection whose time rv_t is nearest to it. Index \"all\" returns a 1 x n_t struct array.\nOnly a result of the network (output.s_layer \"PowerNetwork\") has a DAE with bus\nvariables; another layer stops with GUILDA:ResultLIN:NetworkOnly.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_contribution",
        "ResultLIN.get_ss",
        "ResultLIN.get_kernel"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();\nres = net.get_sys();\nsv_dev = [\"Component\",\"LocalController\"];                  % no global controller here\nsct = res.get_reduced_matrix(sv_dev);                      % steady state: the states follow (\"settled\")\nsct.sv_row                                                 % theta1 ... theta9, rho1 ... rho9\nsctF = res.get_reduced_matrix(sv_dev, State=\"fixed\");      % instantaneous: the states held\nsct = res.get_reduced_matrix(\"controller.avr\");            % the AVRs settled\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_kernel",
      "Defining": "ResultLIN",
      "Group": "get",
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
      "OutputNames": [
        "sct_kernel"
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
          "Name": "Tolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "1e-8",
          "Required": false,
          "Unit": "",
          "Description": "Singular values of J up to Tolerance times the largest are the kernel."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeSection"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section (1 ... numel(rv_t)) or \"all\" (a struct array, one per section); res.Index when omitted."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time: the section whose rv_t is nearest; overrides Index."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_kernel",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "rm_right, rm_left (variables x n_dim), sv_state (variables), tab_phase, n_dim, s_port, s_message (1 x n_t for Index \"all\")."
        }
      ],
      "Signature": "sct_kernel = get_kernel(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/get_kernel.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NetworkOnly"
      ],
      "Summary": "Get the kernel of the Jacobian of the DAE: the rotation of the phases.",
      "Desc": "J is the full state matrix A of get_ss(\"DAE\") over [x; v] (the dynamic states and the\nbus variables), in the Port of the result; for Port \"I\" it is computed in Port \"PQ\",\nwhere a rotation of all phases is a change of the angles only. The kernel is found from\nthe singular values of J: those up to Tolerance times the largest. Both bases are\nreturned (variables x n_dim, the rows in the order of sv_state):\n\n- rm_right: J r = 0. Turning every phase of an island by the same angle (the bus\n  angles theta and the generator angles delta) leaves every equation unchanged, so the\n  right kernel spans these rotations. Each column is the indicator of one island: 1 on\n  its phase variables, 0 elsewhere; the columns are in the order of the first phase\n  variable of each island.\n- rm_left: w' J = 0, the dual basis of the right one: rm_left' * rm_right = I. Its\n  entries are those of the equation rows of the variables (the state equation of a\n  state, the P balance of a bus angle).\n\nA phase variable is a variable whose right-kernel value is 1. tab_phase has one row per\nphase variable: Index (the row of the variable in sv_state), Name, Owner (the tag of the\nbus, or of the component or controller of the state), Kind (\"Bus\", \"Component\",\n\"LocalController\" or \"GlobalController\"), Kernel (the column of the bases), Right (the\nentry of rm_right, 1) and Left (the entry of rm_left at the variable).\n\nA kernel that has no rotation form (it is not spanned by indicators of phase variables)\nis returned as orthonormal bases, with an empty tab_phase; when the left basis cannot be\ndual to the right one (w' r singular), rm_left is orthonormal. s_message says so. A\nJacobian without a kernel (n_dim 0, e.g. a model with an infinite bus) returns empty\nbases and tab_phase, and s_message says so; s_message is \"\" otherwise.\n\nIndex chooses the section (default res.Index; see ResultLIN), and Time, when given, the\nsection whose time rv_t is nearest to it. Index \"all\" returns a 1 x n_t struct array.\nOnly a result of the network (output.s_layer \"PowerNetwork\") has a DAE with bus\nvariables; another layer stops with GUILDA:ResultLIN:NetworkOnly.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_ss",
        "ResultLIN.get_reduced_matrix",
        "ResultLIN.get_mode"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();\nres = net.get_sys();\nsct = res.get_kernel();                  % rotation of the phases\nsct.tab_phase                            % the bus angles and generator angles, Right and Left\nsct.rm_left' * sct.rm_right              % the dual bases: I\nsct.s_message                            % \"\" when the kernel has the rotation form\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_eigenvector",
      "Defining": "ResultLIN",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Type",
        "opt"
      ],
      "OutputNames": [
        "sct_vector"
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
          "Name": "Type",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model: \"ODE\" or \"DAE\"; the Type of the result when omitted."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeSection"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section (1 ... numel(rv_t)) or \"all\" (a struct array, one per section); res.Index when omitted."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time: the section whose rv_t is nearest; overrides Index."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_vector",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "cm_right, cm_left (states x eigenvalues, complex), cv_lambda [1/s], sv_state (states), s_type (1 x n_t for Index \"all\")."
        }
      ],
      "Signature": "sct_vector = get_eigenvector(obj, Type, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/get_eigenvector.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Get the right and left eigenvectors of the linear model.",
      "Desc": "Returns one struct with the eigenvectors of the finite generalized eigenvalues of (A, E)\nof get_ss(Type) as columns, for the eigenvalues cv_lambda (those of get_eigenvalue, in\nthe same order: sorted by the real part, the largest first; each complex pair together,\nIm > 0 first). The rows are the states of the model, named in sv_state (its StateName).\n\n- cm_right: A v = lambda E v, with v normalized so that its entry of largest magnitude\n  is 1 (the mode shape cm_shape of get_mode).\n- cm_left: w' A = lambda w' E (w' is the conjugate transpose), with w normalized so that\n  w' E v = 1 with the right vector v of the same column.\n\nThe vectors of the conjugate eigenvalue of a pair are the conjugates of the vectors of\nthe eigenvalue with Im > 0. s_type is the Type of the model.\n\nIndex chooses the section (default res.Index; see ResultLIN), and Time, when given, the\nsection whose time rv_t is nearest to it. Index \"all\" returns a 1 x n_t struct array.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_eigenvalue",
        "ResultLIN.get_mode"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();\nres = net.get_sys();\nsct = res.get_eigenvector();                        % right and left eigenvectors\nsys = res.get_ss(Format=\"struct\");\nsct.cm_left(:,1)' * sys.E * sct.cm_right(:,1)       % 1\nbar(categorical(sct.sv_state), abs(sct.cm_right(:, 1)))   % shape of the least stable mode\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_eigenvalue",
      "Defining": "ResultLIN",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Type",
        "opt"
      ],
      "OutputNames": [
        "cv_lambda"
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
          "Name": "Type",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model: \"ODE\" or \"DAE\"; the Type of the result when omitted."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeSection"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section (1 ... numel(rv_t)) or \"all\" (a table with the columns Time and Index); res.Index when omitted."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time: the section whose rv_t is nearest; overrides Index."
        }
      ],
      "Outputs": [
        {
          "Name": "cv_lambda",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "1/s",
          "Description": "Eigenvalues (complex column), or a table Time [s], Index, Eigenvalue for Index \"all\"."
        }
      ],
      "Signature": "cv_lambda = get_eigenvalue(obj, Type, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/get_eigenvalue.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Get the eigenvalues of the linear model.",
      "Desc": "Returns a column of the finite generalized eigenvalues of (A, E) of get_ss(Type): the\ninfinite eigenvalues of a singular E (the \"DAE\", whose bus voltages are algebraic) are\nleft out. They are sorted by the real part, the largest (the least stable) first, in the\norder of get_mode: each complex pair is kept together, the eigenvalue with Im > 0 first,\nso that the rows with Im >= 0 are the Eigenvalue column of get_mode. get_eigenvector\nreturns the eigenvectors in the same order.\n\nIndex chooses the section (default res.Index; see ResultLIN), and Time, when given, the\nsection whose time rv_t is nearest to it. Index \"all\" returns a table with the columns\nTime (rv_t of the section), Index and Eigenvalue, one row per eigenvalue of every section.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_eigenvector",
        "ResultLIN.get_mode",
        "ResultLIN.plot_eigenvalue"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();\nres = net.get_sys();\nlambda = res.get_eigenvalue();          % eigenvalues of the Type of the result\nlambda = res.get_eigenvalue(\"DAE\");     % the finite eigenvalues of the DAE\nmax(real(lambda))                       % the largest real part\ntab = res.get_eigenvalue(Index=\"all\");  % every section of a result with time sections\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_contribution",
      "Defining": "ResultLIN",
      "Group": "plot",
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
      "OutputNames": [
        "sct_graph"
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
          "Name": "Quantity",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Quantity, [\"damping\",\"synchronizing\",\"voltage\"])"
          ],
          "Default": "\"damping\"",
          "Required": false,
          "Unit": "",
          "Description": "Quantity: \"damping\" (share in an eigenvalue), \"synchronizing\" (dP/dtheta of the ports) or \"voltage\" (dQ/drho of the ports)."
        },
        {
          "Name": "State",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.State, [\"settled\",\"fixed\"])"
          ],
          "Default": "\"settled\"",
          "Required": false,
          "Unit": "",
          "Description": "Ports of \"synchronizing\" and \"voltage\": states \"settled\" (eliminated) or \"fixed\" (held at the point)."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section shown first (1 ... numel(rv_t)); res.Index when omitted."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_graph",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table (uitable)."
        }
      ],
      "Signature": "sct_graph = plot_contribution(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_contribution.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NetworkOnly",
        "GUILDA:ResultLIN:IndexRange",
        "GUILDA:ResultLIN:PortQuantity"
      ],
      "Summary": "Plot the contribution of each element on the network diagram: its share in the damping of a mode, or the stiffness of its port.",
      "Desc": "The DAE (get_ss(\"DAE\") in the Port of the result) is the sum of the parts of its\nelements, A = sum of A_e (get_contribution: the components, the local and global\ncontrollers, the branches and the buses). plot_contribution draws, from these parts, one\nof three quantities (Quantity) in the figure of plot_participation: the eigenvalue map\n(Type \"DAE\") on the left, the diagram of sct_network on the right and a table below it.\n\n\"damping\" (default): the share of each element in the eigenvalue of the mode picked\n(click an eigenvalue on the map; mode 1, the first row of get_mode(Type=\"DAE\"), first).\nWith the right and left eigenvectors v, w of the DAE (get_eigenvector(\"DAE\"),\nw' E v = 1),\n\n```\nlambda_e = w' A_e v / (w' E v),    sum over the elements of lambda_e = lambda\n```\n\nRe(lambda_e) is the part of the element in the decay rate of the mode: a negative\nvalue adds damping, a positive one removes it (Im(lambda_e), its part in the frequency\n[rad/s], is in the table only). The colors are Re(lambda_e) on a colorbar symmetric\nabout 0: each component with the shares of its local controllers added (its label\n\"Re (with controllers)\" says so), each branch, and each bus by the share of the bus\nitself (its shunt). Global controllers are in the table, which lists Re and Im of every\nelement (their sum lambda in its title) until a bus is clicked, then the elements at\nthat bus.\n\n\"synchronizing\" and \"voltage\" need no mode. Each component, with its local controllers,\nis reduced to the port of its bus: the part A_e of the component and its controllers\n(get_contribution), restricted to their states x and the two variables v of the bus,\nwith x eliminated by the rule of get_reduced_matrix (State \"settled\", default: every x,\nK = Jvv - Jvx / Jxx * Jxv, the states follow (E dx/dt = 0), the steady-state stiffness;\n\"fixed\": the dynamic states held at the point, only the algebraic ones eliminated, the\ninstantaneous stiffness). K is 2 x 2 over the rows of the balance of the bus and the bus\nvariables of the Port:\n\n- \"synchronizing\" = K(1,1) = dP/dtheta, the synchronizing power coefficient of the\n  device: the increase of the power it absorbs from the bus (its injection decreasing)\n  when the bus angle advances. Positive values pull the bus angle back. For a\n  generator, State \"fixed\" (the rotor angle held) gives the classical coefficient\n  E' V cos(delta - theta) / X'.\n- \"voltage\" = K(2,2): dQ/drho = V dQ/dV in Port \"PQ\" (d(Q/V)/dV in Port \"PI\"), the\n  reactive stiffness of the device: how much reactive power it gives when the voltage\n  of its bus falls. Positive values support the voltage.\n\nPort \"I\" has no angle and voltage variables and stops with GUILDA:ResultLIN:PortQuantity.\nThe color of a component is its value and that of a bus the sum over its components\n(NaN without one). Each branch is colored by its own coupling, -(K_ij + K_ji)/2 of its\npart over the variables of its two buses (theta for \"synchronizing\", the second variable\nfor \"voltage\"): the synchronizing (or reactive) coupling it adds between them. The table\nlists the 2 x 2 K of each component (K11 K12; K21 K22). The eigenvalue map is shown for\nreference; a click on it changes nothing.\n\nA result with several sections switches them through the playback bar (the colors and\nthe table follow), starting at Index. Another layer than the network stops with\nGUILDA:ResultLIN:NetworkOnly.\n\nIt returns a struct with Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table\n(uitable).\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_contribution",
        "ResultLIN.get_reduced_matrix",
        "ResultLIN.plot_participation"
      ],
      "Examples": "```matlab\nres = net.get_sys();\nsct = res.plot_contribution();                            % click a mode: which elements damp it\nsct = res.plot_contribution(Quantity=\"synchronizing\", State=\"fixed\");\nsct = res.plot_contribution(Quantity=\"voltage\");          % steady-state reactive stiffness\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_reduced_matrix",
      "Defining": "ResultLIN",
      "Group": "plot",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "target",
        "opt"
      ],
      "OutputNames": [
        "G",
        "tab_coupling"
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
          "Name": "target",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [
            "mustBeNonempty"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags and class (or package) names of the elements whose variables are eliminated (see get_reduced_matrix)."
        },
        {
          "Name": "State",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.State, [\"settled\",\"fixed\"])"
          ],
          "Default": "\"settled\"",
          "Required": false,
          "Unit": "",
          "Description": "Dynamic states of the targets: \"settled\" (eliminated) or \"fixed\" (held at the point)."
        },
        {
          "Name": "Block",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Block, [\"P\",\"Q\"])"
          ],
          "Default": "\"P\"",
          "Required": false,
          "Unit": "",
          "Description": "Block drawn: \"P\" (P balance x theta) or \"Q\" (Q balance x the second bus variable)."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section shown first (1 ... numel(rv_t)); res.Index when omitted."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The diagram (GraphNetDiagram), ColorMode \"user\" with K(i,i) in BusColorData and the couplings as BranchLineWidth."
        },
        {
          "Name": "tab_coupling",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Couplings of the section shown first: Bus1, Bus2, Coupling, Branch."
        }
      ],
      "Signature": "[G, tab_coupling] = plot_reduced_matrix(obj, target, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_reduced_matrix.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NetworkOnly",
        "GUILDA:ResultLIN:IndexRange"
      ],
      "Summary": "Plot the reduced matrix seen from the buses on the network diagram.",
      "Desc": "Computes get_reduced_matrix(target, State) (the Jacobian of the DAE with the variables\nof the targets eliminated) and draws, on the diagram of sct_network (GraphNetDiagram,\nthe topology), its block between the bus variables of Block:\n\n- \"P\" (default): the rows of the P balance and the columns of the bus angles theta (the\n  first bus variable of the Port: theta, or Vre for Port \"I\");\n- \"Q\": the rows of the Q balance and the second bus variable (rho for \"PQ\", V for \"PI\",\n  Vim for \"I\").\n\nWith K that block (buses x buses), each bus is colored by its diagonal entry K(i,i)\n(the self term; colorbar over every section) and labelled \"tag: K(i,i)\"; each branch is\ndrawn with a width from 0.5 pt (no coupling) to 6 pt (the largest coupling over the\nbranches of every section) by the coupling of its end buses, (|K(i,j)| + |K(j,i)|)/2.\nA bus whose variable was eliminated (a target bus) is gray, and the branches to it\ntake the smallest width. The reduction also couples buses that no branch joins (e.g.\nthrough an eliminated bus); the diagram cannot draw them, so tab_coupling lists every\npair of buses with a coupling above 1e-9 times the largest of the section shown first:\nBus1, Bus2, Coupling and Branch (the tags of the branches between them, \"\" when none).\n\ntarget and State are those of get_reduced_matrix: e.g. [\"Component\",\"LocalController\"]\n(with \"GlobalController\" when the model has one) gives the matrix seen from the buses\n(縮約アドミタンス), State \"settled\" (default) the steady-state one and \"fixed\" the\ninstantaneous one. A result with several sections has one sample per section, switched\nby the playback bar (colors, widths and labels follow), starting at Index. Only a result\nof the network has it; another layer stops with GUILDA:ResultLIN:NetworkOnly.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_reduced_matrix",
        "GraphNetDiagram",
        "ResultLIN.plot_kernel"
      ],
      "Examples": "```matlab\nres = net.get_sys();\n[G, tab] = res.plot_reduced_matrix([\"Component\",\"LocalController\"]);   % P block seen from the buses\ntab(tab.Branch == \"\", :)                         % couplings without a branch\nG = res.plot_reduced_matrix(\"Component\", State=\"fixed\", Block=\"Q\");\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_eigenvector",
      "Defining": "ResultLIN",
      "Group": "plot",
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
      "OutputNames": [
        "sct_graph"
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
          "Name": "Side",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Side, [\"right\",\"left\"])"
          ],
          "Default": "\"right\"",
          "Required": false,
          "Unit": "",
          "Description": "Eigenvector: \"right\" (the mode shape) or \"left\"."
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
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model whose modes are used: \"ODE\" or \"DAE\"; the Type of the result when omitted."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section shown first (1 ... numel(rv_t)); res.Index when omitted."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_graph",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table (uitable)."
        }
      ],
      "Signature": "sct_graph = plot_eigenvector(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_eigenvector.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NetworkOnly",
        "GUILDA:ResultLIN:IndexRange"
      ],
      "Summary": "Plot the eigenvector of a mode on the network diagram, with the mode picked on the eigenvalue map.",
      "Desc": "What it shows: the shape of one mode over the network. The right eigenvector v\n(Side \"right\", default; A v = lambda E v, cm_right of get_eigenvector) says how much\nand with which phase each variable swings in the mode: buses of the same color phase\nswing together, buses 180° apart swing against each other. The left eigenvector w\n(Side \"left\"; w' A = lambda w' E, cm_left) says how strongly an input or a disturbance\nin the equation of each variable excites the mode.\n\nDraws the same figure as plot_participation (the eigenvalue map on the left, the\ndiagram of sct_network on the right and a table below it) for the eigenvector of the\nmode picked on the map (mode 1, the first row of get_mode, first).\n\nEach bus shows the entry at its representative variable:\n\n- the angle delta of the first generator at the bus (a state named \"delta\" of a\n  component at the bus, tab_variable.Name), for the left vector the row of its state\n  equation;\n- else the bus angle theta (Type \"DAE\" only; for the left vector the row of the P\n  balance of the bus);\n- else none: the bus is gray (e.g. a load bus of Type \"ODE\").\n\nThe node color is the magnitude of the entry divided by the largest magnitude over the\nrepresentative variables (so 1 at the bus that moves most, colorbar from 0), and the\nlabel \"tag: magnitude∠phase°\" gives the phase relative to that largest entry (0° there;\nbuses swinging against it are near 180°). Clicking a bus (or a component: its bus) lists\nevery state of the bus with the magnitude and phase [deg] of its entry (the vector as\nget_eigenvector normalizes it); the data tip of a bus gives its |entry| / max. Clicking\nan eigenvalue picks its mode, as in plot_participation. Type chooses the model.\nSections switch through the playback bar as in plot_participation; another layer than\nthe network stops with GUILDA:ResultLIN:NetworkOnly.\n\nIt returns a struct with Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table\n(uitable).\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_eigenvector",
        "ResultLIN.plot_participation",
        "ResultLIN.get_mode"
      ],
      "Examples": "```matlab\nres = net.get_sys();\nsct = res.plot_eigenvector();                   % mode shape of the least stable mode\nsct = res.plot_eigenvector(Side=\"left\");\nsct = res.plot_eigenvector(Type=\"DAE\");         % the load buses by their theta\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_participation",
      "Defining": "ResultLIN",
      "Group": "plot",
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
      "OutputNames": [
        "sct_graph"
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
          "Name": "Type",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model whose modes are used: \"ODE\" or \"DAE\"; the Type of the result when omitted."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section shown first (1 ... numel(rv_t)); res.Index when omitted."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_graph",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table (uitable)."
        }
      ],
      "Signature": "sct_graph = plot_participation(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_participation.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NetworkOnly",
        "GUILDA:ResultLIN:IndexRange"
      ],
      "Summary": "Plot the participation of the buses in a mode, picked on the eigenvalue map.",
      "Desc": "What it shows: how much the states at each bus take part in one oscillation or decay\n(a mode) of the linear model. The participation of state k in mode i is\n|w_k (E v)_k| (right and left eigenvectors v, w), normalized so that it sums to 1 over\nthe states; a bus gets the sum over its states (its components and their local\ncontrollers, and its bus variables in Type \"DAE\"), so the bus values of a mode sum to 1\nover the buses (with the global controllers). A bus near 1 is where the mode lives.\n\nOne figure (in Parent) with three parts:\n\n- left: the eigenvalue map of plot_eigenvalue (marker sets \"stable\" and \"unstable\").\n  Clicking an eigenvalue picks the mode of the nearest eigenvalue (or its conjugate) of\n  the modes of get_participation in the section shown, marked by a black ring; its data\n  tip shows lambda, the frequency, the damping ratio and the mode picked. Mode 1, the\n  first row of get_mode (the largest real part), is picked first.\n- right: the diagram of the snapshot sct_network (GraphNetDiagram, the topology), each\n  bus colored by tab_bus.Participation of get_participation in the mode picked\n  (colorbar from 0 to the largest participation of the mode). A bus without states (no\n  component or controller states at it, and no bus variable in Type \"DAE\") is gray\n  (NaN), and so is every bus of a section that has fewer modes. The title gives the mode,\n  its eigenvalue, frequency and damping ratio, the subtitle what the colors are, and the\n  data tip of a bus its participation.\n- below the diagram: a table of the bus clicked on the diagram, with the participation of\n  each state of that bus in the mode picked (a component clicked shows its bus).\n\nType chooses the model, as in get_participation. A result with several sections\n(numel(rv_t) > 1) has one sample per section in both graphs, which are linked\n(G.link): the playback bar of either switches the section of both, and the colors, the\nring and the table follow the mode of the same number in that section. It starts at\nIndex. Only a result of the network has a diagram; another layer stops with\nGUILDA:ResultLIN:NetworkOnly.\n\nIt returns a struct with the parts: Eigenvalue (the GraphChart), Diagram (the\nGraphNetDiagram) and Table (the uitable). A bus clicked is also selected on the diagram\n(Diagram.select). The figure turns on the data cursor mode (the diagram does) and adds\nto its UpdateFcn; the ElementClickedFcn of the two graphs are used by the figure: add\nmore with addlistener(G, \"ElementClicked\", ...).\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_participation",
        "ResultLIN.plot_eigenvalue",
        "ResultLIN.get_mode",
        "GraphNetDiagram"
      ],
      "Examples": "```matlab\nres = net.get_sys();\nsct = res.plot_participation();             % click an eigenvalue, then a bus\nsct.Diagram.BusColorData                    % = tab_bus.Participation(:, 1), NaN without states\nres = net.get_sys({sim, [0.5 1 2]});\nsct = res.plot_participation(Index=2);      % sections switched by the playback bar\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_kernel",
      "Defining": "ResultLIN",
      "Group": "plot",
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
      "OutputNames": [
        "G"
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
          "Name": "Kernel",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "1",
          "Required": false,
          "Unit": "",
          "Description": "Kernel (island) drawn: a column of rm_left of get_kernel."
        },
        {
          "Name": "Label",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Label, [\"none\",\"value\",\"tag\"])"
          ],
          "Default": "\"value\"",
          "Required": false,
          "Unit": "",
          "Description": "Labels: \"value\" (the kernel entries), \"tag\" or \"none\"."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section shown first (1 ... numel(rv_t)); res.Index when omitted."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The diagram (GraphNetDiagram), ColorMode \"user\" with the kernel entries in BusColorData."
        }
      ],
      "Signature": "G = plot_kernel(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_kernel.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NetworkOnly",
        "GUILDA:ResultLIN:IndexRange",
        "GUILDA:ResultLIN:NoKernel",
        "GUILDA:ResultLIN:KernelRange"
      ],
      "Summary": "Plot the left kernel of the Jacobian of the DAE on the network diagram.",
      "Desc": "Draws the diagram of the snapshot sct_network (GraphNetDiagram, the topology: no\nflows) and colors each bus by the entry of the left kernel rm_left of get_kernel at its\nbus angle theta (the row of the P balance of the bus), for the kernel (island) Kernel.\nThe left kernel w (w' J = 0, dual to the rotation of the phases: w' r = 1) weighs the\nequations of the island in its conserved combination; its entries at the phase\nvariables sum to 1 over the island. A bus of another island, or of a section without\nthat kernel, is gray (NaN). The components are drawn without a color value (black while\nthe buses are colored); the entries at their phase variables (the generator angles\ndelta) are written in their labels.\n\nLabel chooses the labels:\n\n- \"value\" (default): each bus \"tag: value\" (the theta entry), and each component\n  with a phase variable in the kernel its delta entry (\"δ value\"; several phase\n  variables are joined); the other components have no label.\n- \"tag\": the tags of the buses and components (LabelMode \"tag\").\n- \"none\": no labels.\n\nThe color limits are [min max] of the theta entries of the kernel over every section,\nso that the colors compare between sections; G.ColorLimits changes them.\n\nA result with several sections (numel(rv_t) > 1) has one sample per section, at the\ntimes rv_t (the section numbers when rv_t is not finite and nondecreasing), switched by\nthe playback bar or G.set_time(t): the colors and labels follow the kernel of each\nsection (the TimeChangedFcn of G). It starts at Index. The section shown first must have\nthe kernel: a section without a kernel of the rotation form stops with\nGUILDA:ResultLIN:NoKernel (with the s_message of get_kernel), and a Kernel beyond its\nislands with GUILDA:ResultLIN:KernelRange. Only a result of the network has a kernel;\nanother layer stops with GUILDA:ResultLIN:NetworkOnly.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_kernel",
        "GraphNetDiagram",
        "ResultLIN.plot_participation"
      ],
      "Examples": "```matlab\nres = net.get_sys();\nG = res.plot_kernel();                    % left kernel of the (first) island\nsct = res.get_kernel();  sct.tab_phase    % the numbers of the colors and labels\nG = res.plot_kernel(Label=\"tag\");\nres = net.get_sys({sim, [0.5 1 2]});\nG = res.plot_kernel(Kernel=2, Index=3);   % second island, from the third section\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_matrix",
      "Defining": "ResultLIN",
      "Group": "plot",
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
      "OutputNames": [
        "G",
        "G_block"
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
          "Name": "Matrix",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Matrix, [\"J\",\"A\",\"B\",\"C\",\"D\",\"E\"])"
          ],
          "Default": "\"A\"",
          "Required": false,
          "Unit": "",
          "Description": "Matrix drawn: \"A\" ... \"E\" of get_ss(Type) or \"J\" (A of get_ss(\"DAE\") over [x; v])."
        },
        {
          "Name": "Display",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Display, [\"pattern\",\"magnitude\"])"
          ],
          "Default": "\"pattern\"",
          "Required": false,
          "Unit": "",
          "Description": "\"pattern\" (nonzero entries) or \"magnitude\" (log10|value|)."
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
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model of \"A\" ... \"E\": \"ODE\" or \"DAE\"; the Type of the result when omitted."
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
          "Default": "default_port(obj)",
          "Required": false,
          "Unit": "",
          "Description": "Bus port of the \"DAE\" (see get_ss); options.Port of the result when omitted."
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
          "Default": "obj.Form",
          "Required": false,
          "Unit": "",
          "Description": "View (see get_ss); res.Form when omitted."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section shown first (1 ... numel(rv_t)); res.Index when omitted."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The matrix (GraphMatrix), elements the groups of the rows (\"rowgroup\") and of the columns (\"colgroup\")."
        },
        {
          "Name": "G_block",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The block clicked (GraphMatrix, Display \"value\"); empty for an axes as Parent."
        }
      ],
      "Signature": "[G, G_block] = plot_matrix(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_matrix.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:IndexRange",
        "GUILDA:ResultLIN:NetworkOnly"
      ],
      "Summary": "Plot a matrix of the linear model by element, and a block of it with its values.",
      "Desc": "What it shows: which variables of the model act on which. Each row is an equation (the\nderivative of a state, or the balance of a bus) and each column a variable; an entry is\nthe coefficient of the column in the row (e.g. A(i, j) = d(dx_i/dt)/dx_j). The\nvariables are grouped by their element (the owner tag: the component, controller or\nbus, tab_variable.Owner; a bus variable of the \"DAE\" belongs to its bus), so a diagonal\nblock is the internal dynamics of one element and an off-diagonal block the coupling of\ntwo elements.\n\nDraws the matrix with GraphMatrix: with Display \"pattern\" (default) a red filled circle\nper nonzero entry and a hollow circle per zero entry, or log10|value| (\"magnitude\").\nThe rows and columns are sorted by element (in the order of the first variable of each\nelement, the order of the model within one); the tick labels are the element tags, one\nat the middle of each element's rows and columns; separator lines run between the\nelements and a box frames each diagonal block. An input or output that is not in\ntab_variable belongs to the group \"(other)\".\n\nMatrix chooses the matrix:\n\n- \"A\" (default), \"B\", \"C\", \"D\", \"E\": the matrix of get_ss(Type) (E dx/dt = A x + B u,\n  y = C x + D u) with the Input and Output of get_sys. An output without a name (the\n  states of \"ODE\") is named y1, y2, ....\n- \"J\": the full Jacobian of the DAE over [x; v], the state matrix A of\n  get_ss(\"DAE\") in Port (the dynamic states, then the bus variables; rows: the state\n  equations, then the bus balance). Only a result of the network (output.s_layer\n  \"PowerNetwork\") has it; another layer stops with GUILDA:ResultLIN:NetworkOnly.\n\nClicking anywhere in a block of the matrix (a circle, an empty cell, or a data tip on\nit: the graph turns on the data cursor mode) shows that block on the right, in G_block\n(GraphMatrix, Display \"value\", a line around each cell): its title is the element tag\n(or \"row tag × column tag\"), its rows and columns the variable names without the tag\n(delta, omega, Eq) and its cells the values. It starts with the first diagonal block; a\ngray line separates the two panels.\nWith an axes as Parent only the matrix is drawn (G_block is empty). G.Display,\nG.Tolerance and G.ColorLimits change the view later. Form chooses the view as in get_ss\n(\"hessian\": the Hessian H of the energy function).\n\nA result with several sections (numel(rv_t) > 1) draws the matrix of every section:\nits samples are the sections at the times rv_t (the section numbers when rv_t is not\nfinite and nondecreasing), switched by the playback bar or G.set_time(t), with the\nsection in the title; the block follows (G and G_block are linked). It starts at\nIndex. A section whose model cannot be formed (e.g. \"ODE\" with a singular Avv) is drawn\nempty (NaN); when no section has it, get_ss stops.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "GraphMatrix",
        "ResultLIN.get_ss",
        "ResultLIN.get_reduced_matrix"
      ],
      "Examples": "```matlab\nres = net.get_sys();\n[G, Gb] = res.plot_matrix();                   % A by element; click a block\nG = res.plot_matrix(Matrix=\"J\", Type=\"DAE\", Display=\"magnitude\");\nG.Tolerance = 1e-8;                             % hide the tiny entries\nG.select(\"B001SG1\");                            % the rows and columns of an element\nres = net.get_sys({sim, [0.5 1 2]});\nG = res.plot_matrix(Index=2);                   % three sections, the second first\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_eigenvalue_path",
      "Defining": "ResultLIN",
      "Group": "plot",
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
      "OutputNames": [
        "G"
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
          "Name": "Type",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model whose eigenvalues are used: \"ODE\" or \"DAE\"; the Type of the result when omitted."
        },
        {
          "Name": "Tolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeNonnegative"
          ],
          "Default": "1e-6",
          "Required": false,
          "Unit": "",
          "Description": "Real part above which a section is unstable."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The chart (GraphChart), lines \"max_real\" and \"min_damping\"."
        }
      ],
      "Signature": "G = plot_eigenvalue_path(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_eigenvalue_path.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:OneSection"
      ],
      "Summary": "Plot the largest real part and the smallest damping ratio of the eigenvalues over the sections.",
      "Desc": "For a result with several sections (numel(rv_t) > 1, e.g. net.get_sys({sim, rv_t})),\ndraws two panels against the sections: the largest real part of the finite generalized\neigenvalues of (A, E) of get_ss(Type) of each section, and the smallest damping ratio\n-Re lambda / |lambda| of its oscillatory modes (|Im lambda| > 1e-6, as in get_mode; NaN\nfor a section without one). A dotted line marks 0 in both panels. The first section\nwhose largest real part exceeds Tolerance is marked by a vertical line in both panels,\nlabeled \"Hopf\" when that eigenvalue is complex (a pair crosses the imaginary axis) and\n\"instability\" when it is real; none when every section is stable.\n\nThe x axis is rv_t when its times are finite and nondecreasing, else the section numbers\n1 ... n_t. Both panels are time panels: set_time(t) draws the cursor at the section\nnearest to t, so the chart links with plot_eigenvalue of the same result and with the\ngraphs of the simulation (G.link). The chart has no playback bar, as its lines do not\nchange with time: only the cursor moves, by set_time, animate and the graphs it is\nlinked to (e.g. the playback bar of plot_eigenvalue).\n\nIt returns the chart G (GraphChart) with two lines: \"max_real\" (panel 1) and\n\"min_damping\" (panel 2). A result with one section is an error.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.plot_eigenvalue",
        "ResultLIN.get_mode",
        "GraphChart"
      ],
      "Examples": "```matlab\nres = net.get_sys({sim, 0:0.05:2});\nG = res.plot_eigenvalue_path();\nG.link(res.plot_eigenvalue());               % the map follows the cursor\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_eigenvalue",
      "Defining": "ResultLIN",
      "Group": "plot",
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
      "OutputNames": [
        "G"
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
          "Name": "Type",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model whose eigenvalues are drawn: \"ODE\" or \"DAE\"; the Type of the result when omitted."
        },
        {
          "Name": "Tolerance",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeNonnegative"
          ],
          "Default": "1e-6",
          "Required": false,
          "Unit": "",
          "Description": "Real part above which an eigenvalue is drawn as unstable."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section shown first (1 ... numel(rv_t)); res.Index when omitted."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The chart (GraphChart), marker sets \"stable\" and \"unstable\"."
        }
      ],
      "Signature": "G = plot_eigenvalue(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/plot_eigenvalue.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:IndexRange"
      ],
      "Summary": "Plot the eigenvalue map.",
      "Desc": "Draws the eigenvalue map of the linear model: the finite generalized eigenvalues of\n(A, E) of get_ss(Type) in the complex plane, with the imaginary axis (the port\nmodel for an object-level result, see ResultLIN). It needs no toolbox.\nEigenvalues with a positive real part (larger than Tolerance) are drawn in red.\nIndex chooses the section shown first (default res.Index; see ResultLIN). The only\nfigure of the analysis besides plot_eigenvalue_path: get_sys draws none (its PlotFcn is\na live display during the linearization).\n\nIt returns the chart G (GraphChart) with two marker sets of filled dots (\".\" markers,\nMarkerSize 16): \"stable\" (the eigenvalues with a real part up to Tolerance, blue) and\n\"unstable\" (red; a set without points when the model is stable). The imaginary axis is fixed drawing, not an element.\nThe subtitle says what the map shows: each eigenvalue lambda is a mode e^(lambda t) of\nthe linear model; Re lambda < 0 decays (its decay rate), Im lambda / 2 pi is its\nfrequency [Hz], and the damping ratio is -Re lambda / |lambda|.\n\nA result with several sections (numel(rv_t) > 1) gives a chart of every section: its\nsamples are the sections, at the times rv_t (the section numbers when rv_t is not\nfinite and nondecreasing), and G.set_time(t) shows the eigenvalues of the section\nnearest to t, with the section in the title (also in the panel of show_controls). It\nstarts at Index. The axis limits hold the eigenvalues of every section, so that\nG.animate() and a link to the graphs of the same simulation (G.link(S)) show the\neigenvalues move.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "GraphChart",
        "ResultLIN.get_ss",
        "ResultLIN.plot_eigenvalue_path"
      ],
      "Examples": "```matlab\nG = res.plot_eigenvalue();\nG.set_style(\"unstable\", MarkerSize=12);\nres = net.get_sys({sim, 0:0.1:2});           % sections along a simulation\nG = res.plot_eigenvalue();\nG.link(sim.plot_spring_model());             % the eigenvalues follow the animation\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_participation",
      "Defining": "ResultLIN",
      "Group": "get",
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
      "OutputNames": [
        "sct_part"
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
          "Name": "Type",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model whose modes are used: \"ODE\" or \"DAE\"; the Type of the result when omitted."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeSection"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section (1 ... numel(rv_t)) or \"all\" (a struct array, one per section); res.Index when omitted."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time: the section whose rv_t is nearest; overrides Index."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_part",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "rm_value (states x modes), cv_lambda [1/s], sv_state, sv_owner, tab_bus (Bus, Participation), tab_global (Owner, Participation), s_type (1 x n_t for Index \"all\")."
        }
      ],
      "Signature": "sct_part = get_participation(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/get_participation.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Get the participation of the states and of the buses in the modes of the linear model.",
      "Desc": "Returns one struct for the modes of get_mode (the same calculation and the same order:\none of each complex pair, sorted by the real part, the largest first):\n\n- rm_value: states x modes, the participation |w_k (E v)_k| of state k (left and right\n  eigenvectors w, v) normalized to sum 1 in each mode (rm_participation of get_mode).\n- cv_lambda: the eigenvalues of the columns [1/s] (the Eigenvalue column of get_mode).\n- sv_state, sv_owner: the names of the rows (StateName) and their owners (the tag of the\n  component or controller, of tab_variable.Owner; the bus tag for a bus variable of the\n  \"DAE\").\n- tab_bus: one row per bus of the model, in the order of the buses: Bus (the tag) and\n  Participation (buses x modes), the sum of the participation of the states at the bus\n  (the states of its components and of their local controllers, by the column Bus of\n  tab_variable, and the bus variables of the \"DAE\").\n- tab_global: one row per owner of the states that belong to no bus (the global\n  controllers): Owner and Participation (owners x modes); no rows without them.\n- s_type: the Type of the model.\n\nThe columns of tab_bus.Participation and tab_global.Participation of a mode sum to 1\ntogether. A mode whose participation is all zero gives NaN.\n\nIndex chooses the section (default res.Index; see ResultLIN), and Time, when given, the\nsection whose time rv_t is nearest to it. Index \"all\" returns a 1 x n_t struct array.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_mode",
        "ResultLIN.get_eigenvector"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();\nres = net.get_sys();\nsct = res.get_participation();\nsct.tab_bus                                        % participation of each bus\nbar(categorical(sct.tab_bus.Bus), sct.tab_bus.Participation(:, 1))   % in the least stable mode\nsct = res.get_participation(Type=\"DAE\", Index=\"all\");\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_mode",
      "Defining": "ResultLIN",
      "Group": "get",
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
      "OutputNames": [
        "sct_mode"
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
          "Name": "Type",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model whose modes are returned: \"ODE\" or \"DAE\"; the Type of the result when omitted."
        },
        {
          "Name": "MinFrequency",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeNonnegative"
          ],
          "Default": "0",
          "Required": false,
          "Unit": "Hz",
          "Description": "Smallest frequency kept; > 0 keeps the oscillatory modes only."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeSection"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section (1 ... numel(rv_t)) or \"all\" (a struct array, tab_mode with the columns Time and Index); res.Index when omitted."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time: the section whose rv_t is nearest; overrides Index."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_mode",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "tab_mode (Eigenvalue, Frequency [Hz], DampingRatio, DominantOwner), rm_participation, cm_shape (states x modes), sv_state, sv_owner (states), s_type (1 x n_t for Index \"all\")."
        }
      ],
      "Signature": "sct_mode = get_mode(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/get_mode.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Get the modes of the linear model: eigenvalues, frequencies, damping ratios and owners.",
      "Desc": "Returns one struct. Its table tab_mode has one row per mode of get_ss(Type): the finite\ngeneralized eigenvalues of (A, E), one of each complex pair (the one with Im > 0), as in\nthe stability-constrained OPF (calculate_optimal_powerflow, sct_stability.tab_mode,\nwhich leaves out the zero eigenvalues). The infinite eigenvalues of a singular E (the\n\"DAE\", whose bus voltages are algebraic) are not modes. The rows are sorted by the real\npart, the largest (the least stable) first.\n\n- Eigenvalue: the eigenvalue lambda [1/s] (complex).\n- Frequency: |Im lambda| / (2 pi) [Hz].\n- DampingRatio: -Re lambda / |lambda| for an oscillatory mode (|Im lambda| > 1e-6), NaN\n  for a real mode.\n- DominantOwner: the owner (component or controller tag, of tab_variable.Owner; the bus\n  tag for a bus variable of the \"DAE\") of the states with the largest participation in\n  the mode, the participation summed over the states of each owner.\n\nMinFrequency > 0 keeps the oscillatory modes with Frequency >= MinFrequency only.\nThe other fields hold, for the modes of the rows (columns) and the states of the model\n(rows, in the order of StateName):\n\n- rm_participation: the participation |w_k (E v)_k| of state k (left and right\n  eigenvectors w, v), normalized to sum 1 in each mode (get_participation sums it by\n  bus).\n- cm_shape: the mode shape, the right eigenvector v normalized so that its entry of\n  largest magnitude is 1.\n- sv_state, sv_owner: the names of the states (StateName) and their owners.\n- s_type: the Type of the model.\n\nIndex chooses the section (default res.Index; see ResultLIN), and Time, when given, the\nsection whose time rv_t is nearest to it. Index \"all\" returns a 1 x n_t struct array\nwhose tab_mode has the columns Time (rv_t of the section) and Index first, so that\nvertcat(sct.tab_mode) is one table of the modes of every section.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "ResultLIN.get_participation",
        "ResultLIN.plot_eigenvalue",
        "ResultLIN.get_ss",
        "PowerNetwork.calculate_optimal_powerflow"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();\nres = net.get_sys();\nsct = res.get_mode();                            % every mode\nsct.tab_mode\nsct = res.get_mode(MinFrequency=0.1);            % oscillatory modes only\nbar(categorical(sct.sv_state), sct.rm_participation(:, 1));   % participation in the first mode\nsct = res.get_mode(Index=\"all\");                 % every section of a result with time sections\ntab = vertcat(sct.tab_mode);                     % one table, with Time and Index\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_contribution",
      "Defining": "ResultLIN",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "target"
      ],
      "OutputNames": [
        "res_e",
        "sct_mask"
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
          "Name": "target",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [
            "mustBeNonempty"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags and class (or package) names of the elements; several are summed."
        }
      ],
      "Outputs": [
        {
          "Name": "res_e",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Part of the targets: a result with every section (Type \"DAE\"), sv_target the targets."
        },
        {
          "Name": "sct_mask",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Entries the targets change, one per section (1 x n_t): A, B, C, D, E (logical), StateName, InputName, OutputName."
        }
      ],
      "Signature": "[res_e, sct_mask] = get_contribution(obj, target)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/get_contribution.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NotFinite"
      ],
      "Summary": "Get the part of elements in the DAE, as a result of its own.",
      "Desc": "The DAE of the result (get_ss(\"DAE\") with the Input, Output and Port of get_sys)\nis the sum of the parts of its elements: the components, the local and global\ncontrollers, the branches and the buses. get_contribution returns the part of the\nelements in target, summed, as a ResultLIN res_e with every section of the result: the\nsame rv_t, Index, variable map, points, options (Input, Output, Port), output and\nsct_network, each section holding the part of the connected model (the terms of the\ntargets over [x; v]). So res_e.A ... res_e.OutputName are the part in the Port of the\nresult for section res_e.Index, res_e.get_ss(\"DAE\", Index=k) the part in section k, and\nthe parts of all the elements sum to the DAE in every section. res_e.sv_target holds the\ntargets.\n\nres_e is a part of a DAE, not a model of its own: its Type is \"DAE\" and cannot be\n\"ODE\" (setting it, get_ss(\"ODE\") or a method with Type \"ODE\" stops with\nGUILDA:ResultLIN:ContributionDAE), and it has no Form \"hessian\". Form \"absorbed\" works.\nThe other methods compute on the matrices of the part (eigenvalues, modes,\nparticipation, kernel, reduction, contribution and the plots); on a contribution result\nthe numbers are of the part alone and have no meaning for the whole system.\n\nsct_mask is a 1 x n_t struct array, one per section: the fields A, B, C, D and E as\nlogical matrices, true where the targets change the entry, with StateName, InputName\nand OutputName. sct_mask(res_e.Index) is the section shown by res_e.\n\nA term belongs to the element that owns its equation row:\n\n- A state row belongs to the owner of the state, with every term of it: the terms\n  through its inputs too (B_con C_gen of a controller that reads a component belongs to\n  the controller).\n- A row of the current balance of a bus is split: the current terms of each component\n  belong to that component, and the admittance matrix Y to the branches (each its\n  2-by-2 stamp) and to the bus (its shunt).\n- An output row belongs to the owner of the output: a state to its owner, a bus voltage\n  to the bus, an output y or yc to its component or controller, and a bus current\n  (Y v) to the branches and buses as in Y.\n\ntarget is a string array of tags (the Owner column of the variable map, or the tag of a\nbranch or bus) and class names. A class name takes every element of that class or of\nits subclasses (e.g. \"LocalController\", \"component.generator.abstract\"); a package\nname takes every class in it (e.g. \"controller.avr\"). A target that matches no element\nstops with GUILDA:ResultLIN:UnknownTarget. The parts are a deviation model like the\nDAE. The result of a component, bus or controller has no algebraic variables: the\nparts split its port model in the same way. A section that is not usable keeps its\nissue (get_ss of it stops as for the result) and its mask has empty fields.",
      "SeeAlso": [
        "ResultLIN.get_ss",
        "ResultLIN.plot_contribution",
        "SolverLIN.solve",
        "PowerSystemModel.get_sys"
      ],
      "Examples": "```matlab\nres = net.get_sys();\nres_g = res.get_contribution(\"B001SG1\");                % one generator\nres_g.A                                                 % its part of the DAE\n[res_avr, msk] = res.get_contribution(\"controller.avr\");\nspy(msk(res_avr.Index).A)                               % the entries the AVRs change\nres_avr.Index = 2;                                      % another section (sct_mask(2))\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_ss",
      "Defining": "ResultLIN",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Type",
        "opt"
      ],
      "OutputNames": [
        "sys"
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
          "Name": "Type",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "obj.Type",
          "Required": false,
          "Unit": "",
          "Description": "Model: \"ODE\" (the bus voltages eliminated) or \"DAE\" (the connected model); the Type of the result when omitted."
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
          "Default": "default_port(obj)",
          "Required": false,
          "Unit": "",
          "Description": "Bus port of \"DAE\" (v, w): \"PI\" ([theta,V], [P,Q/V]), \"PQ\" ([theta,rho], [P,Q]) or \"I\" ([Vre,Vim], [-Iim,Ire]); options.Port of the result when omitted."
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
          "Description": "Inputs of the model: \"u\" or Labels. Default: all inputs."
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
          "Description": "Outputs of the model: \"x\", \"V\", \"I\", \"y\" or names. Default: as described for each algorithm."
        },
        {
          "Name": "Format",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Format, [\"ss\",\"struct\"])"
          ],
          "Default": "\"ss\"",
          "Required": false,
          "Unit": "",
          "Description": "Form of the model: \"ss\" (dss; needs the Control System Toolbox) or \"struct\" (A, B, C, D, E and names)."
        },
        {
          "Name": "Index",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "obj.Index",
          "Required": false,
          "Unit": "",
          "Description": "Section of the model (1 ... numel(rv_t)); res.Index when omitted."
        },
        {
          "Name": "Time",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": false,
          "Unit": "s",
          "Description": "Time: the section whose rv_t is nearest; overrides Index."
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
          "Default": "obj.Form",
          "Required": false,
          "Unit": "",
          "Description": "View: \"descriptor\", \"absorbed\" (E^-1 in the dynamic rows) or \"hessian\" (energy-function form); res.Form when omitted."
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
          "Description": "Linear model in the form of Format, with StateName, InputName and OutputName."
        }
      ],
      "Signature": "sys = get_ss(obj, Type, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/get_ss.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:ContributionDAE",
        "GUILDA:ResultLIN:IndexRange"
      ],
      "Summary": "Get the linear model of a Type (ODE / DAE).",
      "Desc": "Returns the linear model of the result (E dx/dt = A x + B u, y = C x + D u). Format\nchooses its form: \"ss\" (default) is a descriptor state-space model (dss) with\nStateName, InputName and OutputName and needs the Control System Toolbox; \"struct\" is\na struct with the fields A, B, C, D, E, StateName, InputName, OutputName (string\ncolumns) and needs no toolbox. For the network, \"ODE\" and \"DAE\" put the states of the\nglobal controllers first, then the components. Use StateName to find a state.\n\n- \"DAE\": the connected model of the result: the bus voltages are algebraic variables\n  (E is zero on their rows and columns), and their equations are the current balance\n  of each bus. Port chooses how each bus is written as a port, the bus variables v\n  (columns) and the balance w (rows): \"PI\" v = [theta, V], w = [P, Q/V]; \"PQ\"\n  v = [theta, rho] (rho = log V), w = [P, Q]; \"I\" v = [Vre, Vim], w = [-Iim, Ire]. The\n  states are named theta, V, rho, Vre, Vim + bus number. Outputs: the dynamic states.\n- \"ODE\": the DAE with the bus voltages eliminated (SolverLIN.reduce). States: the\n  dynamic states. Inputs: the inputs u. Outputs: the states, in their order, without\n  output names. Port does not apply.\n\nInput and Output select the channels of the model; without them the channels are the\nones above. The states and their order do not change. Output takes these kinds and\nnames, in any mix, and the outputs follow the given order (a repeated one is kept once):\n\n- \"x\": all states of the model, in the order of sys.StateName (for \"DAE\", the dynamic\n  states).\n- \"V\": the bus voltages Vre, Vim of each bus (also in \"DAE\", whatever the Port).\n- \"I\": the currents Ire, Iim that the components inject at each bus (Y v).\n- \"y\": the outputs of the components and of the local and global controllers (rows y\n  and yc of the variable map). An output with the name of a state of its owner is\n  \"Y_\" + name.\n- a name: Label of net.get_variable_map() for x, V and y, or a name of the kind \"I\" as\n  in the OutputName of that kind.\n\nInput takes \"u\" (all inputs) or Labels of the inputs, and the inputs follow the given\norder. An unknown name stops with GUILDA:ResultLIN:UnknownInput; an unknown Output name\nstops with GUILDA:ResultLIN:UnknownOutput.\n\nFor a result of comp.get_sys, bus.get_sys, con.get_sys or gc.get_sys, get_ss returns the\nport model (voltages in, currents and outputs out); Input and Output take names of its\ninputs and outputs, and Type and Port do not apply.\n\nIndex chooses the section (default res.Index; see ResultLIN), and Time, when given, the\nsection whose time rv_t is nearest to it.\n\nForm chooses the view (default res.Form; see ResultLIN): \"descriptor\", \"absorbed\"\n(E^-1 in the state rows; every result) or \"hessian\" (the energy-function form of a\nresult of net.get_sys(Form=\"hessian\"), Port \"PI\" or \"PQ\" for \"DAE\"; \"ODE\" eliminates its\nbus variables, E = -inv(R)). \"hessian\" stops with GUILDA:ResultLIN:NoHessianForm\nwithout the form, GUILDA:ResultLIN:HessianPort with Port \"I\" and\nGUILDA:ResultLIN:NetworkOnly for a port model; \"absorbed\" with\nGUILDA:ResultLIN:SingularE when the time constants of the states are not invertible.\n\nA section that is not usable (output.sv_issue of the section) stops with an error that repeats the message of the section (output.sv_message):\nGUILDA:ResultLIN:NotFinite for every Type, and GUILDA:ResultLIN:SingularAvv for \"ODE\",\nwhich eliminates the bus voltages. \"DAE\" keeps them and still works.\n\nOn a contribution result (sv_target nonempty, see get_contribution) the numbers are of\nthe part alone and have no meaning for the whole system.",
      "SeeAlso": [
        "PowerSystemModel.get_sys",
        "SolverLIN.reduce",
        "ResultLIN.Type",
        "ResultLIN.plot_eigenvalue"
      ],
      "Examples": "```matlab\nres = net.get_sys();\nsysO = res.get_ss(\"ODE\");                     % ss (Control System Toolbox)\nsysD = res.get_ss(\"DAE\");\neig(sysO.A, sysO.E)\nsysV = res.get_ss(\"ODE\", Output=\"V\");         % bus voltages as outputs\nsct  = res.get_ss(\"ODE\", Format=\"struct\");    % matrices and names, no toolbox\nsct3 = res.get_ss(Index=3, Format=\"struct\");  % section 3 of a result with time sections\nsctA = res.get_ss(\"ODE\", Form=\"absorbed\", Format=\"struct\");   % E = I\n```",
      "Deprecated": ""
    },
    {
      "Name": "ResultLIN",
      "Defining": "ResultLIN",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "net",
        "solver",
        "options",
        "flag",
        "output",
        "elapsed",
        "tab_variable",
        "rm_point",
        "sys_section",
        "rv_t",
        "sct_network"
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
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Analysed network; see ResultBase."
        },
        {
          "Name": "solver",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "\"SolverLIN\"",
          "Required": false,
          "Unit": "",
          "Description": "Solver object or its class name; see ResultBase."
        },
        {
          "Name": "options",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Effective settings; see ResultBase."
        },
        {
          "Name": "flag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Success or convergence flag; see ResultBase."
        },
        {
          "Name": "output",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Solver details (n_x, n_v, s_layer, lv_flag, sv_issue, sv_message, ...); see ResultBase."
        },
        {
          "Name": "elapsed",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "NaN",
          "Required": false,
          "Unit": "s",
          "Description": "Elapsed time or tic value; see ResultBase."
        },
        {
          "Name": "tab_variable",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "table()",
          "Required": false,
          "Unit": "",
          "Description": "Variable map (leading rows)."
        },
        {
          "Name": "rm_point",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "zeros(0,1)",
          "Required": false,
          "Unit": "",
          "Description": "Point of each section (columns) in the order of tab_variable."
        },
        {
          "Name": "sys_section",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Connected model (SolverLIN.solve) of each section: a struct (one section) or a 1 x n_t cell; for the network also cm_Y, cv_V, sv_I."
        },
        {
          "Name": "rv_t",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [],
          "Default": "NaN(1, size(rm_point, 2))",
          "Required": false,
          "Unit": "",
          "Description": "Time of each section."
        },
        {
          "Name": "sct_network",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Snapshot of the network: struct(net, false)."
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
          "Description": "The result object."
        }
      ],
      "Signature": "obj = ResultLIN(net, solver, options, flag, output, elapsed, tab_variable, rm_point, sys_section, rv_t, sct_network)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m",
      "Line": 194,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a linearization result.",
      "Desc": "Stores the computed values of a linearization: the connected model of\nSolverLIN.solve of each section and its point.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "bus_variables",
      "Defining": "ResultLIN",
      "Group": "bus",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "k"
      ],
      "OutputNames": [
        "sv_bv",
        "sv_bvBus",
        "iv_kind"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result (of the network)."
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
          "Description": "Section."
        }
      ],
      "Outputs": [
        {
          "Name": "sv_bv",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Names of the bus variables (StateName of get_ss(\"DAE\"))."
        },
        {
          "Name": "sv_bvBus",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Bus tag of each."
        },
        {
          "Name": "iv_kind",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "1 or 2."
        }
      ],
      "Signature": "[sv_bv, sv_bvBus, iv_kind] = bus_variables(obj, k)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/bus_variables.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Bus variables of the DAE of section k: their names, buses and kinds, as get_ss orders",
      "Desc": "them (every bus for the first kind, then for the second): kind 1 is theta (Vre for Port\n\"I\"), kind 2 the second variable (rho for \"PQ\", V for \"PI\", Vim for \"I\"). Used by\nplot_reduced_matrix and plot_contribution.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "contribution_part",
      "Defining": "ResultLIN",
      "Group": "contribution",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "S",
        "sv_selected"
      ],
      "OutputNames": [
        "S_part"
      ],
      "Arguments": [
        {
          "Name": "S",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Connected model of a section (with sct_term)."
        },
        {
          "Name": "sv_selected",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Owners of the part."
        }
      ],
      "Outputs": [
        {
          "Name": "S_part",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Connected model of the part."
        }
      ],
      "Signature": "S_part = contribution_part(S, sv_selected)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/contribution_part.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Part of elements in one section: the connected model S (a section of c_section) with",
      "Desc": "only the terms of the owners sv_selected (sct_term of SolverLIN.solve), summed.\n\nThe fields A ... E (and, for the network, cm_Y) are those of the terms of the owners; the\nother fields (names, sizes, the bus voltages cv_V, tab_owner) are those of S. sct_term\nkeeps the terms of the owners, so that the part of a part is again a sum of terms; the\nenergy-function blocks (sct_hessian) are left out. sv_selected marks the part for\nsection_model (the outputs that are a state or a bus voltage). Used by get_contribution\nand plot_contribution.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "datatip_wrap",
      "Defining": "ResultLIN",
      "Group": "datatip",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "fig",
        "h_owner",
        "fcn_text"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "fig",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Figure of the plot."
        },
        {
          "Name": "h_owner",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Graphics object of the plot (its panel or axes) that the wrapper belongs to."
        },
        {
          "Name": "fcn_text",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "txt = fcn_text(event, txt_before): the text of the data tip."
        }
      ],
      "Outputs": [],
      "Signature": "datatip_wrap(fig, h_owner, fcn_text)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/datatip_wrap.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add to the data tips of a figure: wrap the UpdateFcn of its data cursor mode.",
      "Desc": "The diagram and the matrix graphs turn on the data cursor mode of their figure, so a\nclick on a graphics object makes a data tip (and calls the UpdateFcn) instead of its\nButtonDownFcn. The wrapper calls the UpdateFcn set before (the text of the graph, which\nalso reports the click) and then fcn_text(event, txt) for the text shown, so that the\nmode figures of ResultLIN pick a mode from a data tip on an eigenvalue. The color value\nof an element of a diagram is written by GraphNetDiagram itself. A figure already wrapped for h_owner (the first in the chain) is not wrapped\nagain; a wrapper whose h_owner was deleted passes the text on unchanged.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "default_port",
      "Defining": "ResultLIN",
      "Group": "default",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
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
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result."
        }
      ],
      "Outputs": [
        {
          "Name": "str",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "\"PI\", \"PQ\" or \"I\"."
        }
      ],
      "Signature": "str = default_port(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/default_port.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Port of the result (options.Port), \"PQ\" when it has none: the default Port of get_ss and plot_matrix",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "eigen_sorted",
      "Defining": "ResultLIN",
      "Group": "eigen",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "A",
        "E"
      ],
      "OutputNames": [
        "cv_lambda",
        "cm_right",
        "cm_left"
      ],
      "Arguments": [
        {
          "Name": "A",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "State matrix (n x n)."
        },
        {
          "Name": "E",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Mass matrix (n x n); singular for a DAE."
        }
      ],
      "Outputs": [
        {
          "Name": "cv_lambda",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Eigenvalues, sorted by the real part (largest first)."
        },
        {
          "Name": "cm_right",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Right eigenvectors (columns): A v = lambda E v."
        },
        {
          "Name": "cm_left",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Left eigenvectors (columns): w' A = lambda w' E."
        }
      ],
      "Signature": "[cv_lambda, cm_right, cm_left] = eigen_sorted(A, E)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/eigen_sorted.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Finite generalized eigenvalues of (A, E) in the order of get_mode, each complex pair",
      "Desc": "together (Im > 0 first), with the right eigenvectors (entry of largest magnitude 1, the\ncm_shape of get_mode) and the left eigenvectors (w' E v = 1 with that v)\n\nThe eigenvalues come from the same eig call as tools.linear_modes, so the modes of\nget_mode are the rows of cv_lambda with Im >= -1e-6 and in the same order; the\npartner of a pair (Im lambda > 1e-6) follows it and is its conjugate, with the conjugate\nvectors (A and E are real).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "mode_diagram",
      "Defining": "ResultLIN",
      "Group": "mode",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt",
        "sct_spec"
      ],
      "OutputNames": [
        "sct_graph"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result (of the network)."
        },
        {
          "Name": "opt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Options of the method: Type, Index, Parent."
        },
        {
          "Name": "sct_spec",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "What is shown (see above)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_graph",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table (uitable)."
        }
      ],
      "Signature": "sct_graph = mode_diagram(obj, opt, sct_spec)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/mode_diagram.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Figure of the eigenvalue map, the network diagram and a table, with the mode picked on",
      "Desc": "the map (plot_participation, plot_eigenvector, plot_contribution).\n\nLayout in a borderless uipanel of opt.Parent: the eigenvalue map of plot_eigenvalue on\nthe left, the diagram of section_diagram on the right and a table below it. Mode 1 (the\nfirst row of get_mode) is picked first. Picking a mode on the map: a data tip on an\neigenvalue (a click while the data cursor mode of the figure is on, which the diagram\nturns on) or a click on its marker set (ElementClicked, with the CurrentPoint of the\naxes) picks the mode whose eigenvalue or its conjugate is nearest, marked by a black\nring (Tag GUILDA:ResultLIN:PickedMode); the data tip shows lambda, f, zeta and the mode.\nClicking a bus (or a component or link: its bus), also by its data tip, selects it and\nfills the table with the rows at that bus, without drawing the colors again; its data\ntip (GraphNetDiagram) shows its color value under the name s_colorbar. The colors,\ntheir limits and the ring are drawn only when the mode or the section changes (ColorLimits is set only when it changes). With\nseveral sections the two graphs are linked and the TimeChangedFcn of the diagram shows\nthe mode of the same number in the new section.\n\nsct_spec.fcn_section(sv_bus, sv_comp, sv_branch) returns the data of every section\n(1 x n_t struct), in the orders of the diagram:\n\n- cv_lambda (modes): the eigenvalue of each mode;\n- rm_bus (buses x modes): the color value of each bus (NaN: gray);\n- sm_busLabel (buses x modes, or empty): the label of each bus (LabelMode \"user\"),\n  else the bus tags;\n- rm_comp (components x modes, or empty), rm_branch (branches x modes, or empty): the\n  color values of the components and branches (empty: none);\n- sv_row, sv_rowBus (rows), rm_row (rows x modes): the rows of the table, their bus\n  (\"\": no bus) and their values: one column for one name in sv_column, else the\n  magnitude and phase in degrees, or the real and imaginary parts with\n  sct_spec.l_cartesian true.\n- sm_compLabel (components x modes, optional): the label of each component.\n\nWith sct_spec.l_modeFree true the values do not depend on a mode: the data has one\ncolumn (rm_bus, rm_comp, rm_branch, sm_*Label) and rm_row has one column per name in\nsv_column; the eigenvalue map is shown for reference and picks nothing.\n\nOther fields of sct_spec: s_name (start of the title), s_colorbar (label),\ns_explain (what the colors are: the subtitle of the diagram), s_limit (\"zero\": [0 max] of the mode shown;\n\"symmetric\": [-m m]), sv_column (names of the value columns of the table), l_tableAll\n(true: the table shows every row until a bus is clicked), l_cartesian (optional: Re and\nIm of complex rows), l_modeFree and s_quantity (optional: the name of a mode-free\nquantity, in the titles).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "mustBeSection",
      "Defining": "ResultLIN",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "v"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "v",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Value of the option Index."
        }
      ],
      "Outputs": [],
      "Signature": "mustBeSection(v)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/mustBeSection.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:IndexForm"
      ],
      "Summary": "Index of the methods of ResultLIN that take every section: a positive integer or \"all\"",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "section_diagram",
      "Defining": "ResultLIN",
      "Group": "section",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_name",
        "c_opt",
        "s_explain"
      ],
      "OutputNames": [
        "G",
        "sv_bus",
        "sv_comp",
        "sv_text"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result (of the network, with sct_network)."
        },
        {
          "Name": "s_name",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "What is shown, the start of the title (e.g. \"Left kernel 1\")."
        },
        {
          "Name": "c_opt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "cell",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name-Value options of GraphNetDiagram (Parent included)."
        },
        {
          "Name": "s_explain",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Subtitle: what the colors are, one line per row (\"\": none)."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The diagram (GraphNetDiagram)."
        },
        {
          "Name": "sv_bus",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Bus tags in the order of the diagram (a_Bus of the snapshot)."
        },
        {
          "Name": "sv_comp",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Full component tags in the order of the diagram."
        },
        {
          "Name": "sv_text",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Title of each section (s_name alone for one section)."
        }
      ],
      "Signature": "[G, sv_bus, sv_comp, sv_text] = section_diagram(obj, s_name, c_opt, s_explain)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/section_diagram.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NetworkOnly"
      ],
      "Summary": "Diagram of the snapshot sct_network with one sample per section (plot_kernel and",
      "Desc": "plot_participation): the topology (a state of NaN), the colors and labels set by the\ncaller (\"user\").\n\nThe samples are rv_t when its times are finite and nondecreasing, else the section\nnumbers; with more than one section their text (\"<s_name>, section k of n, t = ...\") is\nthe title and the text of the playback bar. With s_explain, it is the subtitle (what the\ncolors are). The data tip of an element shows its color value under the name of\nthe colorbar (ColorbarLabel of c_opt; GraphNetDiagram writes it).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "section_eigenvalues",
      "Defining": "ResultLIN",
      "Group": "section",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_type"
      ],
      "OutputNames": [
        "c_e",
        "rv_sample",
        "sv_text"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result."
        },
        {
          "Name": "s_type",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "\"ODE\" or \"DAE\"."
        }
      ],
      "Outputs": [
        {
          "Name": "c_e",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "cell",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Finite eigenvalues of each section (column vectors)."
        },
        {
          "Name": "rv_sample",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Sample of each section for the chart."
        },
        {
          "Name": "sv_text",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Text of each section."
        }
      ],
      "Signature": "[c_e, rv_sample, sv_text] = section_eigenvalues(obj, s_type)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/section_eigenvalues.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Finite eigenvalues of every section and the samples of a chart over the sections",
      "Desc": "(plot_eigenvalue and plot_eigenvalue_path of a result with several sections).\n\nThe samples are rv_t when its times are finite and nondecreasing (so that the chart\nlinks with the graphs of the same simulation), else the section numbers 1 ... n_t.\nsv_text is the text of each section for the chart (\"section k of n, t = ...\").",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "section_list",
      "Defining": "ResultLIN",
      "Group": "section",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "iv_section"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result."
        },
        {
          "Name": "opt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Options of the method with the field Index and, when given, Time."
        }
      ],
      "Outputs": [
        {
          "Name": "iv_section",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Sections, in order."
        }
      ],
      "Signature": "iv_section = section_list(obj, opt)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/section_list.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:IndexRange"
      ],
      "Summary": "Sections chosen by the options Index and Time of a method of ResultLIN: Time (the section",
      "Desc": "whose rv_t is nearest) overrides Index; Index \"all\" gives every section",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "section_model",
      "Defining": "ResultLIN",
      "Group": "section",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "S",
        "s_issue",
        "s_message",
        "Type",
        "opt"
      ],
      "OutputNames": [
        "sys"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result (variable map, options, layer)."
        },
        {
          "Name": "S",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Connected model of the section, or a part of it."
        },
        {
          "Name": "s_issue",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Issue of the section (\"\", \"NotFinite\", \"SingularAvv\")."
        },
        {
          "Name": "s_message",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Message of the section."
        },
        {
          "Name": "Type",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "\"ODE\" or \"DAE\"."
        },
        {
          "Name": "opt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Port, Form, and optionally Input and Output (as get_ss)."
        }
      ],
      "Outputs": [
        {
          "Name": "sys",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "A, B, C, D, E, StateName, InputName, OutputName."
        }
      ],
      "Signature": "sys = section_model(obj, S, s_issue, s_message, Type, opt)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/section_model.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:NotFinite",
        "GUILDA:ResultLIN:NetworkOnly",
        "GUILDA:ResultLIN:UnknownOutput",
        "GUILDA:ResultLIN:SingularAvv",
        "GUILDA:ResultLIN:NoHessianForm",
        "GUILDA:ResultLIN:HessianPort",
        "GUILDA:ResultLIN:SingularE",
        "GUILDA:ResultLIN:UnknownInput"
      ],
      "Summary": "Model of one section as a struct: the connected model S (a section of c_section, or the",
      "Desc": "part of elements in it, contribution_part) written as get_ss writes it (Type, Port, Form,\nInput, Output of opt). get_ss, get_contribution and plot_contribution use it, so that a\npart of a section is written without a ResultLIN of its own.\n\nA part (S with the field sv_selected) keeps of the outputs that are a state or a bus\nvoltage (identity rows of the DAE, not terms of the elements) only those of its owners.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "sorted_modes",
      "Defining": "ResultLIN",
      "Group": "sorted",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_type",
        "k"
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
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result."
        },
        {
          "Name": "s_type",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Type of the model: \"ODE\" or \"DAE\"."
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
          "Description": "Section."
        }
      ],
      "Outputs": [
        {
          "Name": "sct",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "lambda, frequency, zeta, l_osc, owner (modes), rm_participation, cm_shape (states x modes), sv_state, sv_owner (states)."
        }
      ],
      "Signature": "sct = sorted_modes(obj, s_type, k)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/sorted_modes.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Modes of section k of the model s_type, as in get_mode: tools.linear_modes sorted by the",
      "Desc": "real part (largest first), with the mode shapes normalized (get_mode, get_participation)",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "state_owner",
      "Defining": "ResultLIN",
      "Group": "state",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sv_state"
      ],
      "OutputNames": [
        "sv_owner"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultLIN",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result."
        },
        {
          "Name": "sv_state",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "StateName of the model."
        }
      ],
      "Outputs": [
        {
          "Name": "sv_owner",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag of the owner of each state."
        }
      ],
      "Signature": "sv_owner = state_owner(obj, sv_state)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/state_owner.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Owner of each state of a model of the result: tab_variable.Owner by Label; a bus variable",
      "Desc": "of the \"DAE\" (after the dynamic states, all buses for the first variable, then for the\nsecond) is owned by its bus",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "target_owner",
      "Defining": "ResultLIN",
      "Group": "target",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "tab_owner",
        "target"
      ],
      "OutputNames": [
        "sv_select"
      ],
      "Arguments": [
        {
          "Name": "tab_owner",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Owner and Class of each element (sct_sys.tab_owner of a section)."
        },
        {
          "Name": "target",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags and class (or package) names."
        }
      ],
      "Outputs": [
        {
          "Name": "sv_select",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the selected elements."
        }
      ],
      "Signature": "sv_select = target_owner(tab_owner, target)",
      "File": "_GUILDAsystem/_auxiliary/@ResultLIN/private/target_owner.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultLIN:UnknownTarget"
      ],
      "Summary": "Tags of the elements that target names: a tag, a class (with its subclasses) or a",
      "Desc": "package (get_contribution, get_reduced_matrix)",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "launch_gui",
      "Defining": "ResultBase",
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
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Log that runs and records the actions (default: a new HistoryGUILDA(Echo=true))."
        },
        {
          "Name": "Variable",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeValidVariableName"
          ],
          "Default": "\"res\"",
          "Required": false,
          "Unit": "",
          "Description": "Name of the result in the workspace of History."
        }
      ],
      "Outputs": [
        {
          "Name": "h",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "DrawerResultGUI",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The GUI."
        }
      ],
      "Signature": "h = launch_gui(obj, h_container, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/launch_gui.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultBase:OtherVariable"
      ],
      "Summary": "Show the result in a GUI: header, the plot_, disp_, get_ and export methods as buttons, and a view area.",
      "Desc": "With no container it opens a new uifigure; with a container (uifigure, uipanel, uitab or\nuigridlayout) it fills it, so that the GUI can be embedded in another app. The buttons\nare the methods of the result in functionSignatures.json, grouped as Plot, Display, Get\nand Export, so a result class needs no GUI code. A method with options asks for them in\na dialog (DrawerOptionDialog.ask); plots are drawn in the plot panel, and the text of\ndisp_* and the values of get_* are shown in the text area. See DrawerResultGUI.\n\nEvery action runs as a line of MATLAB code in History (HistoryGUILDA.run) on the result\nvariable Variable of its workspace (set to this result when the workspace has no such\nvariable): the code is logged, and `h.history.get_script()` returns a script that repeats\nthe actions, drawing the plots in new figures. The default history prints each `>> code`\nin the Command Window; its script needs the result in the workspace as Variable.",
      "SeeAlso": [
        "DrawerResultGUI",
        "HistoryGUILDA",
        "DrawerOptionDialog"
      ],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nh = res.launch_gui();                        % new window\nfig = uifigure();\nh = res.launch_gui(uipanel(uigridlayout(fig, [1 1])));   % embedded in a panel\nhist = HistoryGUILDA();\nhist.run(\"Power flow\", \"Calculate\", \"net = network.IEEE9bus(); res_pf = net.calculate_powerflow();\");\nh = hist.get_variable(\"res_pf\").launch_gui(History=hist, Variable=\"res_pf\");\nhist.get_script()                            % the power flow and the actions of the GUI\n```",
      "Deprecated": ""
    },
    {
      "Name": "export",
      "Defining": "ResultBase",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "varargin"
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
          "Description": ""
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
          "Description": "Output file, then Name-Value export options defined by the result class."
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
          "Description": "Path of the written file (defined by the result class)."
        }
      ],
      "Signature": "varargout = export(obj, varargin)",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/export.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Write the result to a file.",
      "Desc": "Writes the result to a file. Each result class defines the file formats and\nName-Value options. A result class without an export stops with\nGUILDA:ResultBase:Unsupported.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "error_unsupported",
      "Defining": "ResultBase",
      "Group": "error",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_method"
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
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name of the unsupported method (\"export\")."
        }
      ],
      "Outputs": [],
      "Signature": "error_unsupported(obj, s_method)",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/error_unsupported.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultBase:Unsupported"
      ],
      "Summary": "Error for an unsupported method of the contract (export).",
      "Desc": "Stops with GUILDA:ResultBase:Unsupported for a method of the export\ncontract that this result class does not provide.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "is_success",
      "Defining": "ResultBase",
      "Group": "is",
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
        "l"
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
          "Name": "l",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True when the analysis succeeded."
        }
      ],
      "Signature": "l = is_success(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/is_success.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Decide whether flag means success.",
      "Desc": "Success test behind l_success: a logical flag as it is, a numeric flag when\npositive (as for exitflag of fsolve or fmincon). Override it when an analysis\nuses another convention.",
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
