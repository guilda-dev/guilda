(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["ResultCPF"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "ResultCPF",
  "properties": [
    {
      "Name": "sv_bus",
      "Defining": "ResultCPF",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 122,
      "Summary": "Bus tags, in the order of the rows of cm_Vbus.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_lambda",
      "Defining": "ResultCPF",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(1,0)",
      "Validation": {
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 123,
      "Summary": "Load parameter lambda at each point of the path (the first point is the equilibrium).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "cm_Vbus",
      "Defining": "ResultCPF",
      "Group": "Result",
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
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 124,
      "Summary": "Bus voltage phasors at each point of the path, one row per bus.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_lambdaMax",
      "Defining": "ResultCPF",
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
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 125,
      "Summary": "Largest lambda on the path (the nose of the PV curve: maximum loading).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_noseStep",
      "Defining": "ResultCPF",
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
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 126,
      "Summary": "Index of the nose point in rv_lambda and the columns of cm_Vbus.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_x",
      "Defining": "ResultCPF",
      "Group": "Result",
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
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 127,
      "Summary": "Full variable vector at each point of the path, lambda in the last row (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_xPredicted",
      "Defining": "ResultCPF",
      "Group": "Result",
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
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 128,
      "Summary": "Predicted points of the predictor-corrector method, in the layout of rm_x (first column NaN).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_switch",
      "Defining": "ResultCPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 129,
      "Summary": "PV buses switched to PQ by Limits \"Q\", one row per switch: lambda, Step, Bus, Limit, Bound (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_stop",
      "Defining": "ResultCPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 130,
      "Summary": "Limit of Limits \"V\" or \"S\" that ended the path (0 or 1 row): lambda, Step, Class, Object, Limit, Bound (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_variable",
      "Defining": "ResultCPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 131,
      "Summary": "Variable map at the calculation (rows x, Vre, Vim, u, uc of net.get_variable_map()): its rows are the columns of rm_variable.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table ((n_x + n_v + n_u + n_uc) x 8)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_variable",
      "Defining": "ResultCPF",
      "Group": "Result",
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
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 132,
      "Summary": "Operating point of each step: row k at step k (index in rv_lambda), column m the variable tab_variable(m,:).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double (n_step x (n_x + n_v + n_u + n_uc))",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "cm_Icomponent",
      "Defining": "ResultCPF",
      "Group": "Result",
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
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 133,
      "Summary": "Current each component injects into its bus at each step: one row per component (network order: sv_bus, then a_Component), one column per step.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "complex double (n_component x n_step)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_network",
      "Defining": "ResultCPF",
      "Group": "Result",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 134,
      "Summary": "Snapshot of the network at the calculation: struct(net, false).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_sigmaMin",
      "Defining": "ResultCPF",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(1,0)",
      "Validation": {
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 135,
      "Summary": "Voltage stability index at each step: smallest singular value of the Jacobian of the CPF equations (unknowns, without lambda); no unit, 0 at the nose, falls like sqrt(lambda_max - lambda) (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_weakbus",
      "Defining": "ResultCPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 136,
      "Summary": "Weak buses at the nose, one row per bus sorted by Participation (descending): Bus, Participation (largest 1), dVdLambda [pu] (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_marginP",
      "Defining": "ResultCPF",
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
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 137,
      "Summary": "Loading margin: r_lambdaMax times the initial active power of every component scaled by (1 + lambda); with UseInternalState that power is minus the network losses, so it is usually negative (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_nose",
      "Defining": "ResultCPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 141,
      "Summary": "Bus voltages at the nose point, one row per bus: V [pu], Varg [rad], Vphasor [pu].",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table (n_bus x 3)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_path",
      "Defining": "ResultCPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 142,
      "Summary": "The path, one row per point: lambda, then V_<bus> [pu] and Varg_<bus> [rad] of each bus.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table (n_step x (1 + 2 n_bus))",
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
      "Name": "export",
      "Defining": "ResultCPF",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "filename"
      ],
      "OutputNames": [
        "s_file"
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
          "Name": "filename",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "string(datetime(\"now\",\"Format\",\"uuMMdd_HHmmss\")) + \"_CPF.csv\"",
          "Required": false,
          "Unit": "",
          "Description": "Output file; its extension selects the format."
        }
      ],
      "Outputs": [
        {
          "Name": "s_file",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Path of the written file."
        }
      ],
      "Signature": "s_file = export(obj, filename)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/export.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "ResultBase",
      "Throws": [
        "GUILDA:ResultCPF:ExportFormat"
      ],
      "Summary": "Write the PV-curve path to a table file.",
      "Desc": "Writes the path (tab_path: lambda, then V_<bus> and Varg_<bus> of each bus, one row per\npoint) to a CSV or Excel file. The format follows the extension of filename (.csv,\n.txt, .xlsx, .xls). A relative filename is relative to the current folder.\ncalculate_continuation_powerflow(..., Export=filename) calls it.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "plot_branch",
      "Defining": "ResultCPF",
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
        "G_pv"
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
            "mustBeMember(opt.Quantity, [\"P\",\"S\",\"loading\",\"loss\"])"
          ],
          "Default": "\"P\"",
          "Required": false,
          "Unit": "",
          "Description": "Value of the lines (see the list)."
        },
        {
          "Name": "Branch",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the branches to draw, or \"all\"; \"\" (default) every branch, or the total loss for \"loss\"."
        },
        {
          "Name": "PVCurve",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Draw the PV curves with the plot (see the help); false: the plot alone."
        },
        {
          "Name": "PVBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Buses of the PV curves: \"\" those of plot_pvcurve (options.LoadBus; every bus when none), \"all\" every bus, or bus tags."
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
          "Description": "The chart (GraphChart), one line per branch."
        },
        {
          "Name": "G_pv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The chart with the PV panel: G itself; [] with PVCurve false or an axes Parent."
        }
      ],
      "Signature": "[G, G_pv] = plot_branch(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_branch.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultCPF:UnknownBranch",
        "GUILDA:ResultCPF:NoLimit"
      ],
      "Summary": "Plot the branch flows along the path.",
      "Desc": "The flows of each step come from the bus voltages cm_Vbus and the admittance matrix\ncm_Y of each branch in the snapshot sct_network: [I_from; I_to] = cm_Y [V_from; V_to],\nS = V conj(I) at each end. Drawn against lambda by Quantity:\n\n- \"P\": P_from, the active power into the branch at its first bus [pu].\n- \"S\": the larger apparent power |S| of the two ends [pu].\n- \"loading\": that apparent power over Smax of the branch (operating limits in the\n  snapshot), with a dotted line at 1; a branch with an infinite or NaN Smax has no line.\n- \"loss\": the active power loss P_from + P_to [pu]: with no Branch given, one line\n  \"total\", the loss of the whole network (the sum over the branches); with Branch, one\n  line per branch.\n\nBranch selects the branches (tags of the branches of sct_network, or \"all\"); with no\nBranch every branch is drawn (for \"loss\": the total). A dashed line marks the nose. The\nsamples of the chart are the steps (rv_t = 1 ... n_step, named \"Step\"): G.set_time(k)\nputs a marker on each line at step k, and G.link(G2) keeps it in step with\nplot_pvcurve, plot_diagram and the other plots of the steps. A result without the\nsnapshot stops with GUILDA:ResultCPF:NoStepData; \"loading\" with no finite Smax stops\nwith GUILDA:ResultCPF:NoLimit.\n\nIt returns the chart G (GraphChart): one line per branch, tagged with the branch tag\n(or \"total\").\n\nWith PVCurve true (default), the PV curves of PVBus (|V| [pu] against lambda, as\nplot_pvcurve, with the nose line) are an extra panel on top of the chart: it shares the\nlambda axis (the x axes of the lambda panels are linked) and is a time panel with the\nmarker cursor, so set_time(k) puts a marker on each PV curve at step k too. Its lines\nare tagged \"V_\" + bus tag (legend: the bus tag) and come after the elements above in\ntab_element, so their tags and rows stay. G_pv is then G. PVCurve false, or an axes or\nuiaxes Parent, draws the chart alone as before (G_pv []). A PVBus tag that is not in\nsv_bus stops with GUILDA:ResultCPF:UnknownBus.",
      "SeeAlso": [
        "ResultPF.plot_branch",
        "ResultCPF.plot_diagram",
        "ResultCPF.plot_pvcurve"
      ],
      "Examples": "```matlab\nres = net.calculate_continuation_powerflow(LoadBus=[\"B009\",\"B014\"]);\nG = res.plot_branch(Quantity=\"S\");\nres.plot_branch(Quantity=\"loss\");                       % total loss\nres.plot_branch(Quantity=\"P\", Branch=[\"B004_B009\", \"B007_B009\"]);\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_generator",
      "Defining": "ResultCPF",
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
        "G_pv"
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
            "mustBeMember(opt.Quantity, [\"P\",\"Q\",\"Qmargin\"])"
          ],
          "Default": "\"Q\"",
          "Required": false,
          "Unit": "",
          "Description": "Value of the lines (see the list)."
        },
        {
          "Name": "Generator",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"all\"",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the generators (components with Q = NaN in powerflow) to draw; \"all\" for every one."
        },
        {
          "Name": "PVCurve",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Draw the PV curves with the plot (see the help); false: the plot alone."
        },
        {
          "Name": "PVBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Buses of the PV curves: \"\" those of plot_pvcurve (options.LoadBus; every bus when none), \"all\" every bus, or bus tags."
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
          "Description": "The chart (GraphChart), one line per generator."
        },
        {
          "Name": "G_pv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The chart with the PV panel: G itself; [] with PVCurve false or an axes Parent."
        }
      ],
      "Signature": "[G, G_pv] = plot_generator(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_generator.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultCPF:NoGenerator",
        "GUILDA:ResultCPF:UnknownGenerator",
        "GUILDA:ResultCPF:NoLimit"
      ],
      "Summary": "Plot the active or reactive power of the generators along the path.",
      "Desc": "The generators are the components with Q = NaN in the powerflow parameters of the\nsnapshot sct_network (the components that take the free Q of their bus, and the free P\nof the slack bus). At each step their power is S = V conj(I), from cm_Vbus and\ncm_Icomponent, drawn against lambda by Quantity:\n\n- \"P\": the active power [pu] of each generator.\n- \"Q\": the reactive power [pu] of each generator.\n- \"Qmargin\": the distance of Q to the nearer of Qmin and Qmax (operating limits of the\n  generator in the snapshot) [pu]; it is 0 at a limit and negative beyond it. A\n  generator with no finite limit (Inf or NaN Qmin and Qmax) has no line; a dotted line\n  marks 0.\n\nA dotted vertical line marks the lambda of each switch of tab_switch (a PV bus fixed at\nQmin or Qmax by Limits \"Q\"), labelled with the bus and the limit, and a dashed line the\nnose. The samples of the chart are the steps (rv_t = 1 ... n_step, named \"Step\"):\nG.set_time(k) puts a marker on each line at step k, and G.link(G2) keeps it in step with\nplot_pvcurve, plot_diagram and the other plots of the steps. A result without the data\nof the steps stops with GUILDA:ResultCPF:NoStepData; Quantity \"Qmargin\" with no finite\nlimit stops with GUILDA:ResultCPF:NoLimit.\n\nIt returns the chart G (GraphChart): one line per generator, tagged with the component\ntag.\n\nWith PVCurve true (default), the PV curves of PVBus (|V| [pu] against lambda, as\nplot_pvcurve, with the nose line) are an extra panel on top of the chart: it shares the\nlambda axis (the x axes of the lambda panels are linked) and is a time panel with the\nmarker cursor, so set_time(k) puts a marker on each PV curve at step k too. Its lines\nare tagged \"V_\" + bus tag (legend: the bus tag) and come after the elements above in\ntab_element, so their tags and rows stay. G_pv is then G. PVCurve false, or an axes or\nuiaxes Parent, draws the chart alone as before (G_pv []). A PVBus tag that is not in\nsv_bus stops with GUILDA:ResultCPF:UnknownBus.",
      "SeeAlso": [
        "ResultCPF.tab_switch",
        "ResultCPF.plot_pvcurve",
        "SolverCPF"
      ],
      "Examples": "```matlab\nres = net.calculate_continuation_powerflow(LoadBus=[\"B009\",\"B014\"], Limits=\"Q\");\nG = res.plot_generator(Quantity=\"Q\");\nres.plot_generator(Quantity=\"Qmargin\", Generator=[\"B002SG1\",\"B003SG1\"]);\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_stability_index",
      "Defining": "ResultCPF",
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
        "G_pv"
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
          "Name": "TopBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBeNonnegative"
          ],
          "Default": "10",
          "Required": false,
          "Unit": "",
          "Description": "Number of weak buses drawn in the lower panel (0: no lower panel)."
        },
        {
          "Name": "PVCurve",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Draw the PV curves with the plot (see the help); false: the plot alone."
        },
        {
          "Name": "PVBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Buses of the PV curves: \"\" those of plot_pvcurve (options.LoadBus; every bus when none), \"all\" every bus, or bus tags."
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
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes when there is one panel; [] for a new figure."
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
          "Description": "The chart (GraphChart): the line \"sigmaMin\", then the bars of the weak buses (and the PV curves)."
        },
        {
          "Name": "G_pv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The chart with the PV panel: G itself; [] with PVCurve false or an axes Parent."
        }
      ],
      "Signature": "[G, G_pv] = plot_stability_index(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_stability_index.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Plot the voltage stability index along the path and the weak buses at the nose.",
      "Desc": "The index is rv_sigmaMin: at each step, the smallest singular value of the Jacobian J of\nthe CPF equations with respect to the unknowns, without the lambda column,\n\n  sigma_min(J) = min over |v| = 1 of |J v|,   J = d f / d [|V|; theta; x]  (lambda fixed).\n\nThe equations f are the P and Q mismatches of the buses [pu] (with UseInternalState,\nalso the state equations of the components), and the unknowns are |V| and theta of the\nbuses (with UseInternalState, also the states of the components), as the corrector\nsolves them (SolverCPF; J by finite differences). At the saddle-node nose J is\nsingular, so sigma_min = 0 there. The participation of a bus is the |V| part of the\nright singular vector of sigma_min, scaled to a largest value of 1 (tab_weakbus at the\nnose).\n\nHow to read it: it has no physical unit and no absolute threshold. Near the nose it\nfalls roughly like sqrt(lambda_max - lambda), so read it against its first value (the\nequilibrium), or read lambda_max - lambda instead. It jumps where Limits \"Q\" switches a\nPV bus to PQ (the equations change). When a \"V\" or \"S\" limit stops the path\n(tab_stop), it ends far from 0: the value at the stop.\n\nSources: P.-A. Löf, T. Smed, G. Andersson, D. J. Hill, \"Fast calculation of a voltage\nstability index\", IEEE Trans. Power Systems 7(1), 1992; B. Gao, G. K. Morison,\nP. Kundur, \"Voltage stability evaluation using modal analysis\", IEEE Trans. Power\nSystems 7(4), 1992.\n\nThe panel of the index draws rv_sigmaMin against lambda, with a dashed line at the nose\n(r_lambdaMax). The lower panel, when tab_weakbus has rows, draws the participation of\nthe buses in the critical mode at the nose (largest 1) as bars, for the TopBus buses of\ntab_weakbus with the largest participation. The samples of the chart are the steps\n(rv_t = 1 ... n_step, named \"Step\"): G.set_time(k) puts a marker on the curve at step\nk, and G.link(G2) keeps it in step with plot_pvcurve, plot_diagram and the other plots\nof the steps. A result without rv_sigmaMin stops with GUILDA:ResultCPF:NoStepData.\n\nWith PVCurve true (default), the PV curves of PVBus (|V| [pu] against lambda, as\nplot_pvcurve, with the nose line) are an extra panel on top of the chart: it shares the\nlambda axis (the x axes of the lambda panels are linked) and is a time panel with the\nmarker cursor, so set_time(k) puts a marker on each PV curve at step k too. Its lines\nare tagged \"V_\" + bus tag (legend: the bus tag) and come after the elements above in\ntab_element, so their tags and rows stay. G_pv is then G. PVCurve false, or an axes or\nuiaxes Parent, draws the chart alone as before (G_pv []). A PVBus tag that is not in\nsv_bus stops with GUILDA:ResultCPF:UnknownBus.\n\nIt returns the chart G (GraphChart): the line \"sigmaMin\", one bar per bus (the bus\ntag), then the PV curves (\"V_\" + bus tag).",
      "SeeAlso": [
        "ResultCPF.rv_sigmaMin",
        "ResultCPF.tab_weakbus",
        "ResultCPF.plot_pvcurve"
      ],
      "Examples": "```matlab\nres = net.calculate_continuation_powerflow(LoadBus=[\"B009\",\"B014\"]);\nG = res.plot_stability_index(TopBus=5);       % PV curves on top, index, weak buses\nres.plot_stability_index(PVCurve=false);      % the index and the weak buses only\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_spring_model",
      "Defining": "ResultCPF",
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
        "G_pv"
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
          "Name": "Dimension",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeMember(opt.Dimension, [2, 3])"
          ],
          "Default": "2",
          "Required": false,
          "Unit": "",
          "Description": "2: phasor plane (GraphSpring2D); 3: surface z = log|V| (GraphSpring3D)."
        },
        {
          "Name": "PVCurve",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Draw the PV curves with the plot (see the help); false: the plot alone."
        },
        {
          "Name": "PVBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Buses of the PV curves: \"\" those of plot_pvcurve (options.LoadBus; every bus when none), \"all\" every bus, or bus tags."
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
          "Description": "The picture: a GraphSpring2D or GraphSpring3D object."
        },
        {
          "Name": "G_pv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The PV chart (GraphChart, plot_pvcurve) on the right, linked to G; [] with PVCurve false or an axes Parent."
        }
      ],
      "Signature": "[G, G_pv] = plot_spring_model(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_spring_model.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the continuation power flow path as a spring-mass picture with every step.",
      "Desc": "The picture holds every step of the path as a sample (rv_t = 1 ... n_step, named\n\"Step\"): G.set_time(k) shows step k, G.animate() plays the steps (one frame per step)\nand G.export_video(file) writes them as a video; the title shows \"Step k (λ = ...)\".\nThe nodes, springs and arrows are those of ResultODE.plot_spring_model\n(tools.spring_model_data): every bus, and the own node of each component whose class\nreturns one from its Static get_spring_node (e.g. the internal voltage of a generator),\nwith the states x and inputs u of the components at each step (tab_variable,\nrm_variable), the bus voltages cm_Vbus and the component currents cm_Icomponent.\nDimension=2 draws the phasor plane (GraphSpring2D), Dimension=3 the surface z = log|V|\n(GraphSpring3D). A component whose values are NaN at a step (its get_equilibrium\nstopped there) has no own node, spring or arrows at that step. G.link(G2) keeps it in\nstep with plot_pvcurve, plot_diagram and the other plots of the steps. A result without\nthe data of the steps stops with GUILDA:ResultCPF:NoStepData.\n\nWith PVCurve true (default), the container (Parent, or a new figure of 1400 x 600 px) is\nsplit: the picture on the left (2/3 of the width) and plot_pvcurve(Bus=PVBus) on the\nright (1/3), linked with G.link(G_pv), so the playback of the picture moves the markers on\nthe PV curves. A uigridlayout Parent gets a borderless uipanel first. PVCurve false, or\nan axes or uiaxes Parent, draws the picture alone as before (G_pv []). A PVBus tag that is\nnot in sv_bus stops with GUILDA:ResultCPF:UnknownBus.",
      "SeeAlso": [
        "ResultODE.plot_spring_model",
        "GraphSpring2D",
        "GraphSpring3D",
        "Component.get_spring_node",
        "ResultCPF.plot_diagram"
      ],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nnet.initialize();\nres = net.calculate_continuation_powerflow(LoadBus=\"B005\");\n[G, G_pv] = res.plot_spring_model(PVBus=\"all\");   % PV curves of every bus on the right\nG.animate();\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_diagram",
      "Defining": "ResultCPF",
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
        "G_pv"
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
          "Name": "opt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name-Value options; each sets the property of the same name of the GraphNetDiagram."
        },
        {
          "Name": "PVCurve",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Draw the PV curves with the plot (see the help); false: the plot alone."
        },
        {
          "Name": "PVBus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Buses of the PV curves: \"\" those of plot_pvcurve (options.LoadBus; every bus when none), \"all\" every bus, or bus tags."
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
          "Description": "GraphNetDiagram object of the drawing."
        },
        {
          "Name": "G_pv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The PV chart (GraphChart, plot_pvcurve) on the right, linked to G; [] with PVCurve false or an axes Parent."
        }
      ],
      "Signature": "[G, G_pv] = plot_diagram(obj, opt, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_diagram.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the continuation power flow path as a network diagram (GraphNetDiagram) with every step.",
      "Desc": "The diagram holds every step of the path as a sample (rv_t = 1 ... n_step, named\n\"Step\"; lambda is not monotonic past the nose): G.set_time(k) shows step k (the first\none, the equilibrium, is shown at first), and the title and the control panel show\n\"Step k (λ = ...)\". G.animate() plays the steps, one frame per step. The bus voltages\ncome from cm_Vbus, the current of each component from cm_Icomponent, and the branch\nflows from these voltages and the admittance matrices of the branches in the snapshot\nsct_network, so the colors, labels and arrows show the operating point of each step.\nG.link(G2) keeps it in step with plot_pvcurve, plot_spring_model and the other plots of\nthe steps. It reads only the stored result. A result without the data of the steps\n(e.g. a ResultCPF built by hand) stops with GUILDA:ResultCPF:NoStepData. The other\nName-Value options set the properties of the GraphNetDiagram.\n\nWith PVCurve true (default), the container (Parent, or a new figure of 1400 x 600 px) is\nsplit: the diagram on the left (2/3 of the width) and plot_pvcurve(Bus=PVBus) on the\nright (1/3), linked with G.link(G_pv), so the playback of the diagram moves the markers on\nthe PV curves. A uigridlayout Parent gets a borderless uipanel first. PVCurve false, or\nan axes or uiaxes Parent, draws the diagram alone as before (G_pv []). A PVBus tag that is\nnot in sv_bus stops with GUILDA:ResultCPF:UnknownBus.",
      "SeeAlso": [
        "ResultODE.plot_diagram",
        "ResultPF.plot_diagram",
        "GraphNetDiagram",
        "ResultCPF.plot_spring_model"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.initialize();\nres = net.calculate_continuation_powerflow(LoadBus=[\"B009\",\"B014\"]);\n[G, G_pv] = res.plot_diagram(ColorMode=\"P\", LabelMode=\"value\");   % PV curves on the right\nG.set_time(res.r_noseStep);       % both at the nose\nG2 = res.plot_diagram(PVCurve=false);   % the diagram alone\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_pqv",
      "Defining": "ResultCPF",
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
          "Name": "Bus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "default_bus(obj)",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the buses to draw; \"all\" for every bus."
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
          "Description": "The chart (GraphChart), one 3D line per bus."
        }
      ],
      "Signature": "G = plot_pqv(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_pqv.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultCPF:UnknownBus"
      ],
      "Summary": "Plot the P-Q-V path of the buses in 3D: P, Q and |V| of each bus at every step.",
      "Desc": "Draws one 3D line per bus through (P, Q, |V|) [pu] of its steps: P + jQ is the total\npower the bus injects into the network, S = V conj(sum of the currents of its\ncomponents), from cm_Vbus and cm_Icomponent; it equals V conj(Y V) of the bus (a load\nbus has negative P). A bus without components has P = Q = 0. By default it draws the\nbuses of plot_pvcurve (options.LoadBus; every bus when it is empty); Bus selects other\nbuses (\"all\" for every bus), and a tag that is not in sv_bus stops with\nGUILDA:ResultCPF:UnknownBus. Drag the axes to turn the view.\n\nThe samples of the chart are the steps (rv_t = 1 ... n_step, named \"Step\", text \"Step k\n(λ = ...)\"): G.set_time(k) puts a marker on each line at its point of step k (none\nbefore the first set_time), and G.link(G2) keeps it in step with the other plots of the\nsteps (plot_pvcurve, plot_diagram, ...). A result without the data of the steps stops\nwith GUILDA:ResultCPF:NoStepData.\n\nIt returns the chart G (GraphChart, one 3D panel): one line per bus, tagged with the\nbus tag.",
      "SeeAlso": [
        "ResultCPF.plot_pvcurve",
        "ResultODE.plot_pqv",
        "GraphChart"
      ],
      "Examples": "```matlab\nres = net.calculate_continuation_powerflow(LoadBus=[\"B009\",\"B014\"]);\nG = res.plot_pqv();\nG.set_time(res.r_noseStep);       % markers at the nose\nres.plot_pqv(Bus=\"all\");\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_pvcurve",
      "Defining": "ResultCPF",
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
          "Name": "Bus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "default_bus(obj)",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the buses to draw; \"all\" for every bus."
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
          "Description": "The chart (GraphChart), one line per bus."
        }
      ],
      "Signature": "G = plot_pvcurve(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/plot_pvcurve.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultCPF:UnknownBus"
      ],
      "Summary": "Plot the PV curves.",
      "Desc": "Draws the PV curves: the voltage magnitude [pu] of each bus against the load parameter\nlambda along the path. A dashed line marks the nose (maximum loading, r_lambdaMax).\nBy default it draws the load buses (options.LoadBus); Bus selects other buses.\nThe only figure of the analysis: calculate_continuation_powerflow draws none (its\nPlotFcn is a live display during the calculation).\n\nIt returns the chart G (GraphChart): one line per bus, tagged with the bus tag. The\nnose line is fixed drawing, not an element. The samples of the chart are the steps\n(rv_t = 1 ... n_step, named \"Step\", text \"Step k (λ = ...)\"): G.set_time(k) puts a\nmarker on each curve at step k (none before the first set_time), and G.link(G2) keeps\nit in step with the other plots of the steps (plot_diagram, plot_spring_model,\nplot_stability_index, plot_generator, plot_branch) and with\nnet.get_sys({res, steps}).plot_eigenvalue / plot_eigenvalue_path.",
      "SeeAlso": [
        "GraphChart",
        "PowerNetwork.calculate_continuation_powerflow"
      ],
      "Examples": "```matlab\nG = res.plot_pvcurve(Bus=\"all\");\nG.set_style(G.tab_element.Tag(1), Color=\"r\", LineWidth=2);\nG.set_time(res.r_noseStep);       % markers at the nose\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_point",
      "Defining": "ResultCPF",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Step",
        "tab_map"
      ],
      "OutputNames": [
        "rv"
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
          "Name": "Step",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Step: an integer from 1 to numel(rv_lambda)."
        },
        {
          "Name": "tab_map",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "obj.tab_variable",
          "Required": false,
          "Unit": "",
          "Description": "Rows to return (a variable map or a part of it)."
        }
      ],
      "Outputs": [
        {
          "Name": "rv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Values in the order of the rows of tab_map (column)."
        }
      ],
      "Signature": "rv = get_point(obj, Step, tab_map)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/get_point.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultCPF:PointStep",
        "GUILDA:ResultCPF:InvalidMap",
        "GUILDA:ResultCPF:UnknownVariable"
      ],
      "Summary": "Get the values of the variable map at a step of the continuation power flow path.",
      "Desc": "Returns the operating point at step Step (the index in rv_lambda, as r_noseStep), in\nthe order of the rows of tab_map (by default the whole tab_variable, so rv is a point\nfor net.get_sys(rv)). tab_map may be any part of tab_variable, e.g. the rows x, Vre,\nVim, u, uc of the variable map of a bus or component of the analysed network\n(bus.get_variable_map(), comp.get_variable_map()); its rows are found by Kind, Owner,\nName and Bus. The other rows of a variable map (the signals y, yc) are not in the result\nand stop with GUILDA:ResultCPF:UnknownVariable. Step must be an integer from 1 to\nnumel(rv_lambda) (GUILDA:ResultCPF:PointStep); there is no interpolation between steps.\nHow the point of a step is made is in the class help (ResultCPF). net.get_sys({result,\nrv_step}) reads the steps rv_step through this method, one section per step.",
      "SeeAlso": [
        "ResultCPF",
        "PowerNetwork.get_variable_map",
        "SolverLIN"
      ],
      "Examples": "```matlab\nresult = net.calculate_continuation_powerflow(LoadBus=\"B014\");\nx0 = result.get_point(1);                     % the equilibrium of net.initialize\nxn = result.get_point(result.r_noseStep);     % the nose\nV  = result.get_point(5, net.a_Bus{14}.get_variable_map());   % rows of one bus\nlin = net.get_sys({result, [1 result.r_noseStep]});          % two sections\n```",
      "Deprecated": ""
    },
    {
      "Name": "ResultCPF",
      "Defining": "ResultCPF",
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
        "sv_bus",
        "rv_lambda",
        "cm_Vbus",
        "rm_x",
        "rm_xPredicted",
        "tab_switch",
        "tab_stop",
        "sct_point"
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
          "Default": "\"SolverCPF\"",
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
          "Description": "Solver details; see ResultBase."
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
          "Name": "sv_bus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "string",
          "Validators": [],
          "Default": "strings(0,1)",
          "Required": false,
          "Unit": "",
          "Description": "Bus tags (rows of cm_Vbus)."
        },
        {
          "Name": "rv_lambda",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "zeros(1,0)",
          "Required": false,
          "Unit": "",
          "Description": "lambda along the path."
        },
        {
          "Name": "cm_Vbus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "zeros(0,0)",
          "Required": false,
          "Unit": "pu",
          "Description": "Bus voltages along the path."
        },
        {
          "Name": "rm_x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "zeros(0,0)",
          "Required": false,
          "Unit": "",
          "Description": "Full variable vector along the path."
        },
        {
          "Name": "rm_xPredicted",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "zeros(0,0)",
          "Required": false,
          "Unit": "",
          "Description": "Predicted points."
        },
        {
          "Name": "tab_switch",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "table()",
          "Required": false,
          "Unit": "",
          "Description": "Switches to PQ (see tab_switch)."
        },
        {
          "Name": "tab_stop",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "table()",
          "Required": false,
          "Unit": "",
          "Description": "Limit that ended the path (see tab_stop)."
        },
        {
          "Name": "sct_point",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Operating points and stability information: fields tab_variable, rm_variable, cm_Icomponent, sct_network, rv_sigmaMin, tab_weakbus, r_marginP (missing ones keep their defaults)."
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
      "Signature": "obj = ResultCPF(net, solver, options, flag, output, elapsed, sv_bus, rv_lambda, cm_Vbus, rm_x, rm_xPredicted, tab_switch, tab_stop, sct_point)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/ResultCPF.m",
      "Line": 146,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a continuation power flow result.",
      "Desc": "Stores the computed values of a continuation power flow.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "check_step_data",
      "Defining": "ResultCPF",
      "Group": "check",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_method",
        "sv_field"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultCPF",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result."
        },
        {
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Method that needs the data (for the message)."
        },
        {
          "Name": "sv_field",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Fields read by the method."
        }
      ],
      "Outputs": [],
      "Signature": "check_step_data(obj, s_method, sv_field)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/private/check_step_data.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultCPF:NoStepData"
      ],
      "Summary": "Stop with GUILDA:ResultCPF:NoStepData when the result lacks the data of the steps.",
      "Desc": "The plots of the steps read the data that net.calculate_continuation_powerflow stores\nfor every step (tab_variable, rm_variable, cm_Icomponent, sct_network, rv_sigmaMin). A\nResultCPF built by hand, or by a solver that does not give them, has empty fields.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "pair_pvcurve",
      "Defining": "ResultCPF",
      "Group": "pair",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt",
        "target"
      ],
      "OutputNames": [
        "G",
        "G_pv"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultCPF",
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
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Options of the calling method: PVCurve, PVBus, Parent."
        },
        {
          "Name": "target",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Chart data (struct) or fcn_graph (function handle) of the plot."
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
          "Description": "The plot (GraphChart, GraphNetDiagram, GraphSpring2D or GraphSpring3D)."
        },
        {
          "Name": "G_pv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The PV chart (GraphChart) linked to G; G itself for a lambda-axis chart; [] without one."
        }
      ],
      "Signature": "[G, G_pv] = pair_pvcurve(obj, opt, target)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/private/pair_pvcurve.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultCPF:UnknownBus"
      ],
      "Summary": "Draw a plot of the steps with the PV curve: on top of a lambda-axis chart, or on the right of a picture.",
      "Desc": "opt holds PVCurve, PVBus and Parent of the calling method. PVBus \"\" takes the buses of\nplot_pvcurve (options.LoadBus; every bus when it is empty), \"all\" every bus; a tag that\nis not in sv_bus stops with GUILDA:ResultCPF:UnknownBus before anything is drawn.\n\n- target a struct (data of a GraphChart whose time panels have lambda as x, from\n  plot_stability_index, plot_generator, plot_branch): the PV curves become panel 1 on\n  top (|V| against lambda, a dashed line at the nose, time panel with the marker\n  cursor), the panels of the data follow it, and the x axes of the lambda panels are\n  linked. The PV series is added after the series of the data, so the elements of the\n  data keep their rows of tab_element; its lines are tagged \"V_\" + bus tag (legend: the\n  bus tag). G_pv is G.\n- target a function handle (fcn_graph(h) draws the picture of plot_diagram or\n  plot_spring_model in a parent h): the container Parent (a new figure of 1400 x 600 px\n  when it is empty; a uigridlayout gets a borderless uipanel first) holds two\n  borderless panels side by side, the picture on the left (2/3 of the width) and\n  plot_pvcurve(Bus=PVBus) on the right (1/3), linked with G.link(G_pv). A drawing that\n  fails removes the panels (and the new figure) it made.\n\nPVCurve false, or an axes or uiaxes Parent, draws the plot alone as before (G_pv []).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "step_sample",
      "Defining": "ResultCPF",
      "Group": "step",
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
        "sct"
      ],
      "Arguments": [
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "ResultCPF",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The result."
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
          "Description": "rv_t (1 x n_step), s_sampleName \"Step\", sv_sampleText (1 x n_step)."
        }
      ],
      "Signature": "sct = step_sample(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultCPF/private/step_sample.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Samples of the plots of a continuation power flow result: the steps 1 ... n_step.",
      "Desc": "The samples are the step numbers (lambda is not monotonic past the nose), named \"Step\",\nwith the text \"Step k (λ = ...)\" of each step. The fields are those of the data of a\nGraphBase subclass (rv_t, s_sampleName, sv_sampleText), so the plots of the steps link\nwith each other and with net.get_sys({result, steps}).plot_eigenvalue (G.link).",
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
