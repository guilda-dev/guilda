(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["ResultPF"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "ResultPF",
  "properties": [
    {
      "Name": "tab_bus",
      "Defining": "ResultPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 57,
      "Summary": "Bus values, one row per bus: Varg [rad], V [pu], P, Q (injections into the network) [pu], Vphasor, Iphasor [pu].",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_branch",
      "Defining": "ResultPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 58,
      "Summary": "Branch flows, one row per branch: From, To (end bus tags), Pfrom, Qfrom, Pto, Qto, Ifrom, Ito, Ploss, Qloss [pu] (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "cm_Vhistory",
      "Defining": "ResultPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 59,
      "Summary": "Bus voltage phasors, one row per bus (tab_bus order), one column per iteration or ODE step (\"dynamic\").",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_step",
      "Defining": "ResultPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 60,
      "Summary": "Iteration numbers, or virtual times (\"dynamic\"), of cm_Vhistory.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_violation",
      "Defining": "ResultPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 61,
      "Summary": "Violated operating limits, one row per limit: Class, Object, Limit, Value, Bound, Excess (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_PFcondition",
      "Defining": "ResultPF",
      "Group": "Data of the calculation",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 64,
      "Summary": "Power flow conditions given to the solver: Type, Varg, V, P, Q of each bus (Bus.get_pf_condition); empty when no power flow was solved.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "cm_Y",
      "Defining": "ResultPF",
      "Group": "Data of the calculation",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 65,
      "Summary": "Bus admittance matrix (tab_bus order).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_network",
      "Defining": "ResultPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 66,
      "Summary": "Snapshot of the network at the calculation: struct(net, false), a nested struct without handles.",
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
      "Name": "export",
      "Defining": "ResultPF",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "filename",
        "opt"
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
          "Default": "string(datetime(\"now\",\"Format\",\"uuMMdd_HHmmss\")) + \"_PowerFlow.csv\"",
          "Required": false,
          "Unit": "",
          "Description": "Output file; its extension selects the format."
        },
        {
          "Name": "Table",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Table,[\"bus\",\"branch\"])"
          ],
          "Default": "\"bus\"",
          "Required": false,
          "Unit": "",
          "Description": "Table written to a CSV or Excel file."
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
      "Signature": "s_file = export(obj, filename, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/export.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "ResultBase",
      "Throws": [
        "GUILDA:ResultPF:ExportFormat",
        "GUILDA:ResultPF:NoNetwork",
        "GUILDA:ResultPF:FileOpen"
      ],
      "Summary": "Write the bus/branch table or the iteration history to a file.",
      "Desc": "Writes the result to a file. The format follows the extension of filename:\n  .csv / .txt / .xlsx / .xls : the bus table (tab_bus) or, with Table=\"branch\", the\n                               branch table (tab_branch); phasors as complex numbers.\n  .json                      : the iteration history for the GridSpring viewer\n                               (https://ta-nish18.github.io/GridSpring/). It uses the\n                               stored power flow conditions (tab_PFcondition) and\n                               admittance matrix (cm_Y).\nA relative filename is relative to the current folder.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "disp_violation",
      "Defining": "ResultPF",
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
          "Name": "Class",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Class, [\"Bus\",\"Component\",\"Branch\"])"
          ],
          "Default": "[\"Bus\",\"Component\",\"Branch\"]",
          "Required": false,
          "Unit": "",
          "Description": "Kinds of object shown."
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
          "Description": "Text when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_violation(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/disp_violation.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Display the violated operating limits of the power flow result.",
      "Desc": "Shows tab_violation grouped by kind (Bus, Component, Branch): for each violated limit\nits object, the limit, the solution value, the bound and the excess. A kind without a\nviolation is left out; without any, one line says so. The power flow never applies the\nlimits (see ResultPF). It reads only the stored result. With one output it returns the\ntext instead of displaying it.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nres.disp_violation()\nres.disp_violation(Class=\"Branch\")\n```\n\nSee also ResultPF.tab_violation, ResultPF.disp_summary",
      "Deprecated": ""
    },
    {
      "Name": "disp_branch",
      "Defining": "ResultPF",
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
          "Name": "Branch",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "strings(1,0)",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the branches to show; empty shows all."
        },
        {
          "Name": "Unit",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Unit, [\"pu\",\"SI\"])"
          ],
          "Default": "\"pu\"",
          "Required": false,
          "Unit": "",
          "Description": "\"pu\", or \"SI\" for MW and Mvar."
        },
        {
          "Name": "Sort",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Sort, [\"tag\",\"loss\",\"loading\"])"
          ],
          "Default": "\"tag\"",
          "Required": false,
          "Unit": "",
          "Description": "\"tag\" keeps the branch order; \"loss\" (Ploss) and \"loading\" sort the largest first."
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
          "Description": "Table text when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_branch(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/disp_branch.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultPF:NoBase"
      ],
      "Summary": "Display the branch flows of the power flow result.",
      "Desc": "One row per branch: its end buses (From = the first bus, To = the second), the power\nflowing into the branch at each end (Pfrom, Qfrom, Pto, Qto), its losses (Ploss,\nQloss) and its loading, the larger |S| of the two ends over Smax of its operating\nlimits (NaN when Smax is infinite or not held). It reads only the stored result. With\nUnit=\"SI\", P and Q are in MW and Mvar (times baseMVA of the network). With one output it\nreturns the text instead of displaying it.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nres.disp_branch()\nres.disp_branch(Sort=\"loss\", Unit=\"SI\")     % largest active power loss first\n```\n\nSee also ResultPF.disp_bus, ResultPF.disp_violation, ResultPF.tab_branch",
      "Deprecated": ""
    },
    {
      "Name": "disp_bus",
      "Defining": "ResultPF",
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
          "Name": "Bus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "strings(1,0)",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the buses to show; empty shows all."
        },
        {
          "Name": "Unit",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Unit, [\"pu\",\"SI\"])"
          ],
          "Default": "\"pu\"",
          "Required": false,
          "Unit": "",
          "Description": "\"pu\", or \"SI\" for kV, MW and Mvar."
        },
        {
          "Name": "Sort",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Sort, [\"tag\",\"V\"])"
          ],
          "Default": "\"tag\"",
          "Required": false,
          "Unit": "",
          "Description": "\"tag\" keeps the bus order; \"V\" sorts by |V|, lowest first."
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
          "Description": "Table text when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_bus(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/disp_bus.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultPF:NoBase"
      ],
      "Summary": "Display the bus values of the power flow result.",
      "Desc": "One row per bus: its type (slack, PV or PQ), the values its power flow condition sets\n(slack: V and Varg; PV: P and V; PQ: P and Q), and the solution |V|, the angle [deg],\nP and Q (injections into the network). It reads only the stored result. With\nUnit=\"SI\", |V| is in kV (times baseKV of the bus) and P, Q in MW and Mvar (times\nbaseMVA of the network); the set values stay in per unit. With one output it returns\nthe text instead of displaying it.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nres.disp_bus()\nres.disp_bus(Bus=[\"B001\",\"B005\"], Unit=\"SI\")\nres.disp_bus(Sort=\"V\")              % lowest |V| first\n```\n\nSee also ResultPF.disp_summary, ResultPF.disp_branch, ResultPF.plot_voltage",
      "Deprecated": ""
    },
    {
      "Name": "get_summary",
      "Defining": "ResultPF",
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
          "Description": "Summary values (see the table of the help)."
        }
      ],
      "Signature": "sct = get_summary(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/get_summary.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the values that disp_summary shows, as a struct.",
      "Desc": "The fields hold the outcome of the calculation, the numbers of buses and branches, the\nsums of the bus injections, the largest and smallest |V| with their buses and the number\nof violated operating limits. The buses with a positive P are the generation, those with\na negative P the load: r_Pgeneration and r_Qgeneration are the sums of P and Q of the\nfirst, r_Pload and r_Qload the sums of -P and -Q of the second (Q of a bus with P = 0\nis in neither), and r_Ploss and r_Qloss the sums of P and Q of all buses. For a result\nthat did not converge (flag <= 0) these sums, the |V| fields and n_violation are NaN\n(the bus tags \"\") as disp_summary leaves them out: the values of the last iterate are\nnot a solution. It reads only the stored result.\n\n| Field | Value |\n| --- | --- |\n| `s_network`, `s_Solver` | Tag of the network; option Solver of the run (\"\" when not held) |\n| `l_success`, `r_flag` | Convergence (flag > 0) and the flag (double) |\n| `n_iteration`, `r_residual`, `r_elapsed` | Iterations, largest residual [pu], elapsed time [s] (NaN when not held) |\n| `n_bus`, `n_slack`, `n_PV`, `n_PQ`, `n_branch` | Numbers of buses by type and of branches |\n| `r_Pgeneration`, `r_Qgeneration` | [pu] Generation (buses with P > 0) |\n| `r_Pload`, `r_Qload` | [pu] Load (buses with P < 0), positive for a consumption |\n| `r_Ploss`, `r_Qloss` | [pu] Losses: sums of P and Q of all buses |\n| `r_Vmax`, `s_VmaxBus`, `r_Vmin`, `s_VminBus` | [pu] Largest and smallest \\|V\\| and their buses |\n| `n_violation` | Number of violated operating limits (rows of tab_violation) |",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nsct = res.get_summary();\nsct.r_Ploss                  % active power losses [pu]\n[sct.r_Vmin, sct.s_VminBus]  % smallest |V| and its bus\n```\n\nSee also ResultPF.disp_summary, ResultPF.tab_bus, ResultPF.tab_violation",
      "Deprecated": ""
    },
    {
      "Name": "disp_summary",
      "Defining": "ResultPF",
      "Group": "disp",
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
      "Signature": "varargout = disp_summary(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/disp_summary.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Display a summary of the power flow result.",
      "Desc": "Shows a title line with the outcome (Solver, converged or not, flag) and one bullet per\nitem: the calculation (iterations, largest residual, elapsed time), the message of the\nsolver, the numbers of buses of each type and of branches, the generation (buses with a\npositive P), the load (buses with a negative P) and the losses (sums over all buses),\neach with P and Q, the largest and smallest |V| with their buses, and the number of\nviolated operating limits (tab_violation). The values are those of get_summary. For a\nresult that did not converge (flag <= 0) the injection sums, |V| and violations are\nleft out, with a bullet saying so: the values of the last iterate are not a solution.\nIt reads only the stored result. With one output it returns the text instead of\ndisplaying it, by the same rule.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nres.disp_summary()\ns = res.disp_summary();      % as text\n```\n\nSee also ResultPF.get_summary, ResultPF.disp_bus, ResultPF.disp_branch, ResultPF.disp_violation",
      "Deprecated": ""
    },
    {
      "Name": "plot_diagram",
      "Defining": "ResultPF",
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
        }
      ],
      "Signature": "G = plot_diagram(obj, opt, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/plot_diagram.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultPF:NoNetworkSnapshot"
      ],
      "Summary": "Draw the power flow solution as a network diagram (GraphNetDiagram; 2D, or Dimension=\"3D\").",
      "Desc": "The bus voltages are Vphasor of tab_bus. The result holds no current of each component,\nso the bus injection P + jQ is split among the components of the bus as initialize\nwould split it (tools.distribute_power with \"baseMVA\": tab_parameter.powerflow of the\nsnapshot, the remainder at the slack bus (l_isSlack of the snapshot) and the split of\nthe bus Q), and each component current is\nconj((P + jQ) / V). The branch flows come from the admittance matrix cm_Y of each branch\nin the snapshot. It reads only the stored result and its network snapshot. The other\nName-Value options set the properties of the GraphNetDiagram.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE14bus().calculate_powerflow();\nG = res.plot_diagram();\nG = res.plot_diagram(ColorMode=\"P\", LabelMode=\"value\");\n```\n\nSee also PowerNetwork.plot_diagram, ResultODE.plot_diagram, GraphNetDiagram, ResultPF.plot_network",
      "Deprecated": ""
    },
    {
      "Name": "plot_spring_model",
      "Defining": "ResultPF",
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
        }
      ],
      "Signature": "G = plot_spring_model(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/plot_spring_model.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultPF:NoSpringData"
      ],
      "Summary": "Draw the power flow solution as a spring-mass picture of the buses.",
      "Desc": "The nodes are the bus voltage phasors (Vphasor of tab_bus) and the springs are the\nbranches. The result holds no states of the components, so there are no own nodes (such\nas the internal voltage of a generator): each bus with a component gets one arrow pair,\nthe active power P and the reactive-current magnitude Iq of its injection (Iphasor) at\nthe bus voltage. Marker, MarkerSize and Color of the graph parameters of the buses set\nthe appearance. Dimension=2 draws the phasor plane (GraphSpring2D), Dimension=3 the\nsurface z = log|V| (GraphSpring3D). It reads only the stored result and its network\nsnapshot. For the own nodes, draw the equilibrium with PowerNetwork.plot_spring_model.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nG = res.plot_spring_model();\nG = res.plot_spring_model(Dimension=3);\n```\n\nSee also PowerNetwork.plot_spring_model, ResultODE.plot_spring_model, GraphSpring2D, GraphSpring3D",
      "Deprecated": ""
    },
    {
      "Name": "plot_network",
      "Defining": "ResultPF",
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
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; a new figure when empty."
        },
        {
          "Name": "Color",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Color, [\"V\",\"angle\"])"
          ],
          "Default": "\"V\"",
          "Required": false,
          "Unit": "",
          "Description": "Node color: |V| [pu] or the angle [deg]."
        },
        {
          "Name": "Arrow",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Arrow, [\"P\",\"Q\",\"none\"])"
          ],
          "Default": "\"P\"",
          "Required": false,
          "Unit": "",
          "Description": "Edge arrows along the P or Q flow, or plain lines."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "GraphNetMap",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Map of the network (tab_element: buses and branches)."
        }
      ],
      "Signature": "G = plot_network(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/plot_network.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultPF:NoNetworkSnapshot"
      ],
      "Summary": "Plot the network with the bus voltages and the branch flows, as a GraphNetMap.",
      "Desc": "Draws the buses as nodes and the branches as edges of a MATLAB graph plot. The node\ncolor is |V| [pu] (Color=\"V\") or the angle [deg] (Color=\"angle\"), with a colorbar.\nWith Arrow=\"P\" or \"Q\", each edge is an arrow in the direction of the active or reactive\npower flow (from the end where the power enters the branch) and its width grows with the\nlarger |P| or |Q| of the two ends; Arrow=\"none\" draws plain lines. The node positions\nare X and Y (the centers) of the graph parameters of the buses in the network snapshot.\nThe buses without a position are placed near their neighbours by\ntools.layout_place_buses, as in PowerNetwork.plot_diagram (the buses with a position\nnever move). It reads only the stored result. The returned map changes its buses and branches by tag\n(set_style, set_position) or by its vector properties (BusColor, BranchLineWidth, ...);\nG.sct_plt.Graph is the graph plot.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE14bus().calculate_powerflow();\nG = res.plot_network();                      % |V| colors, P arrows\nG = res.plot_network(Color=\"angle\", Arrow=\"none\");\nG.set_style(\"B001\", Color=\"r\");\n```\n\nSee also GraphNetMap, ResultPF.plot_voltage, ResultPF.plot_branch, PowerNetwork.plot_diagram",
      "Deprecated": ""
    },
    {
      "Name": "plot_convergence",
      "Defining": "ResultPF",
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
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes without Bus; [] for a new figure."
        },
        {
          "Name": "Bus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "strings(1,0)",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the buses whose |V| is also drawn; empty draws the residual only."
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
          "Description": "The chart (GraphChart): panels residual, then |V| when Bus is given."
        }
      ],
      "Signature": "G = plot_convergence(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/plot_convergence.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultPF:NoHistory"
      ],
      "Summary": "Plot the convergence of the power flow calculation.",
      "Desc": "Draws the largest residual of the power equations at each iterate stored in\ncm_Vhistory, on a log scale, against rv_step: the iteration number, or the virtual time\nfor Solver \"dynamic\". The iteration axis has integer ticks only. The residuals are those the solver checks against Tolerance\n(private power_equation of SolverPF): P, or the angle at the slack bus; Q, or |V| at PV\nand slack buses. They are computed from the stored power flow conditions\n(tab_PFcondition) and admittance matrix (cm_Y). Tolerance is drawn as a dashed\nreference line. With Bus, a second panel shows |V| of those buses at each iterate. It\nreads only the stored result; a result without the conditions (e.g. one of initialize\nwithout a power flow) stops with GUILDA:ResultPF:NoHistory.\n\nIt returns the chart G (GraphChart). Its elements (kind \"line\") are tagged:\n\n- \"Residual\": the largest residual (first panel);\n- the bus tag: |V| of the bus (second panel, with Bus).\n\nFor Solver \"dynamic\" the panels are time panels over the virtual time (G.set_time\ndraws a cursor).",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE14bus().calculate_powerflow(WarmStart=false);\nG = res.plot_convergence();\nG.set_style(\"Residual\", Color=\"k\", LineWidth=2);\nres.plot_convergence(Bus=[\"B001\",\"B014\"]);   % also |V| of two buses\n```\n\nSee also GraphChart, ResultPF.cm_Vhistory, ResultPF.rv_step, SolverPF",
      "Deprecated": ""
    },
    {
      "Name": "plot_branch",
      "Defining": "ResultPF",
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
          "Name": "Quantity",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Quantity, [\"P\",\"Q\",\"S\",\"loading\",\"loss\"])"
          ],
          "Default": "\"P\"",
          "Required": false,
          "Unit": "",
          "Description": "Value of the bars (see the table)."
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
          "Description": "The chart (GraphChart), one bar per branch."
        }
      ],
      "Signature": "G = plot_branch(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/plot_branch.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Plot the branch flows of the power flow result.",
      "Desc": "Draws one bar per branch (tab_branch order, tags on the axis). The bar height by Quantity:\n\n- \"P\": Pfrom, the active power into the branch at its first bus [pu].\n- \"Q\": Qfrom, the reactive power into the branch at its first bus [pu].\n- \"S\": the larger apparent power of the two ends [pu].\n- \"loading\": that apparent power over Smax of the branch (operating limits in the\n  snapshot; no bar when Smax is infinite), with a dashed reference line at 1.\n- \"loss\": Ploss, the active power loss of the branch [pu].\n\nIt reads only the stored result. It returns the chart G (GraphChart) with one element\nper bar (kind \"bar\"), tagged with the branch tag.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE14bus().calculate_powerflow();\nG = res.plot_branch();                   % Pfrom of each branch\nG.set_style(G.tab_element.Tag(1), Color=\"r\");\nres.plot_branch(Quantity=\"loading\");     % |S| / Smax with the line at 1\n```\n\nSee also GraphChart, ResultPF.disp_branch, ResultPF.tab_branch, ResultPF.plot_voltage",
      "Deprecated": ""
    },
    {
      "Name": "plot_voltage",
      "Defining": "ResultPF",
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
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes for one panel; [] for a new figure."
        },
        {
          "Name": "Quantity",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Quantity, [\"magnitude\",\"angle\",\"both\"])"
          ],
          "Default": "\"both\"",
          "Required": false,
          "Unit": "",
          "Description": "Panels drawn: |V|, the angle, or both."
        },
        {
          "Name": "Limit",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Draw the finite Vmin and Vmax of each bus on the magnitude."
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
          "Description": "The chart (GraphChart): panels magnitude, then angle."
        }
      ],
      "Signature": "G = plot_voltage(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/plot_voltage.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Plot the bus voltage profile.",
      "Desc": "Draws the voltage profile of the solution as bar charts, one bar per bus: the voltage\nmagnitude [pu] and the phase angle [deg], in two panels (\"both\") or one. With Limit=true,\nthe operating limits Vmin and Vmax of each bus (tab_parameter.operation in the network\nsnapshot) are drawn on the magnitude as dashed lines over the buses; infinite or missing\nlimits are not drawn. With more than 20 buses, the bus names on the horizontal axis\nare thinned to at most 20 evenly spaced ones and turned vertical; every bus keeps its\nbar. It reads only the stored result. The only figure of the analysis:\ncalculate_powerflow draws none (its PlotFcn is a live display during the calculation).\n\nIt returns the chart G (GraphChart). Its elements are tagged:\n\n- the bus tag: the bar of the bus, in each panel drawn (|V| and angle bars of a bus\n  share the tag, so set_style and select act on both);\n- \"Vmin\", \"Vmax\": the dashed limit lines (kind \"line\"), when drawn.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nG = res.plot_voltage();\nG.set_style(\"B002\", Color=\"r\");              % both bars of bus B002\nG.set_style(\"Vmax\", LineStyle=\"-\");\nres.plot_voltage(Quantity=\"magnitude\", Limit=false);\n```\n\nSee also GraphChart, ResultPF.disp_bus, PowerNetwork.calculate_powerflow",
      "Deprecated": ""
    },
    {
      "Name": "ResultPF",
      "Defining": "ResultPF",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "tab_powerflow",
        "cm_Y",
        "sct_network",
        "sct_solver"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "tab_powerflow",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "table()",
          "Required": false,
          "Unit": "",
          "Description": "Solution, one row per bus: V, I (complex phasors), P, Q [pu]; row names = bus tags (Format \"powerflow(tab)\")."
        },
        {
          "Name": "cm_Y",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "zeros(0,0)",
          "Required": false,
          "Unit": "pu",
          "Description": "Bus admittance matrix (tab_powerflow order)."
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
        },
        {
          "Name": "sct_solver",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Solver information: solver, options, flag, output, elapsed (s or a tic value); optional cm_Vhistory, rv_step, tab_PFcondition."
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
      "Signature": "obj = ResultPF(tab_powerflow, cm_Y, sct_network, sct_solver)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/ResultPF.m",
      "Line": 70,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a power flow result from data.",
      "Desc": "Computes tab_bus, tab_branch and tab_violation from the inputs; no network object\nis read.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "branch_flow",
      "Defining": "ResultPF",
      "Group": "branch",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct_network",
        "tab_bus"
      ],
      "OutputNames": [
        "tab"
      ],
      "Arguments": [
        {
          "Name": "sct_network",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Snapshot of the network (struct(net, false))."
        },
        {
          "Name": "tab_bus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Bus values of the solution (tab_bus of ResultPF)."
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
          "Description": "From, To (bus tags), Pfrom, Qfrom, Pto, Qto, Ifrom, Ito, Ploss, Qloss; row names = branch tags."
        }
      ],
      "Signature": "tab = branch_flow(sct_network, tab_bus)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/private/branch_flow.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "End bus tags, power and current at both ends of each branch of the network snapshot",
      "Desc": "(from = a_Bus{1}, to = a_Bus{2}), from the solved bus voltages and the admittance matrix of each branch\nin the snapshot (field cm_Y, added by Branch.struct; NaN flows without it).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "bus_data",
      "Defining": "ResultPF",
      "Group": "bus",
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
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The ResultPF."
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
          "Description": "Fields sv_tag, sv_type, rv_Vset, rv_Vargset, rv_Pset, rv_Qset, rv_Vmin, rv_Vmax, rv_baseKV (bus order of tab_bus), r_baseMVA."
        }
      ],
      "Signature": "sct = bus_data(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/private/bus_data.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Data of each bus that the disp_ and plot_ methods read from the stored result: tags,",
      "Desc": "types, set values, limits and bases. Values that the result does not hold are NaN or\n\"\" (a result without a snapshot or without power flow conditions).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "bus_index",
      "Defining": "ResultPF",
      "Group": "bus",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "a_end",
        "sv_bus"
      ],
      "OutputNames": [
        "iv"
      ],
      "Arguments": [
        {
          "Name": "a_end",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "cell",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Buses of a branch or component in the snapshot."
        },
        {
          "Name": "sv_bus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Bus tags in tab_bus order."
        }
      ],
      "Outputs": [
        {
          "Name": "iv",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Row of each bus in sv_bus."
        }
      ],
      "Signature": "iv = bus_index(a_end, sv_bus)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/private/bus_index.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Row of each bus of a_end in sv_bus. In the snapshot a bus is the path where it was",
      "Desc": "stored first (\"net.a_Bus{3}\"), or a struct when it was first reached here.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "history_residual",
      "Defining": "ResultPF",
      "Group": "history",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "cm_V",
        "cm_Y",
        "tab_PFcondition"
      ],
      "OutputNames": [
        "rv"
      ],
      "Arguments": [
        {
          "Name": "cm_V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus voltages, one column per iterate."
        },
        {
          "Name": "cm_Y",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus admittance matrix."
        },
        {
          "Name": "tab_PFcondition",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Power flow conditions (Type, Varg, V, P, Q)."
        }
      ],
      "Outputs": [
        {
          "Name": "rv",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu, rad",
          "Description": "Largest |residual| of each column."
        }
      ],
      "Signature": "rv = history_residual(cm_V, cm_Y, tab_PFcondition)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/private/history_residual.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Largest residual of the power equations at each column of cm_V",
      "Desc": "The residuals of private power_equation of SolverPF: P - Pset (the angle - Varg at the\nslack bus) and Q - Qset at PQ buses, |V| - Vset at PV and slack buses.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "pick_rows",
      "Defining": "ResultPF",
      "Group": "pick",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sv_all",
        "sv_given",
        "s_kind"
      ],
      "OutputNames": [
        "iv"
      ],
      "Arguments": [
        {
          "Name": "sv_all",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the rows, in order."
        },
        {
          "Name": "sv_given",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags asked for; empty for all."
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
          "Description": "\"bus\" or \"branch\", for the message."
        }
      ],
      "Outputs": [
        {
          "Name": "iv",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Row numbers, in the order of sv_all."
        }
      ],
      "Signature": "iv = pick_rows(sv_all, sv_given, s_kind)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/private/pick_rows.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultPF:UnknownTag"
      ],
      "Summary": "Rows of the tags sv_given in sv_all (all rows when sv_given is empty); an unknown tag",
      "Desc": "stops with GUILDA:ResultPF:UnknownTag",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "rows_to_table",
      "Defining": "ResultPF",
      "Group": "rows",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "c_row"
      ],
      "OutputNames": [
        "tab"
      ],
      "Arguments": [
        {
          "Name": "c_row",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "cell",
          "Validators": [],
          "Default": "cell(0,4)",
          "Required": false,
          "Unit": "",
          "Description": "One row per violated limit."
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
          "Description": "Columns Class, Object, Limit, Value, Bound, Excess."
        }
      ],
      "Signature": "tab = rows_to_table(c_row)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/private/rows_to_table.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Violation table from the rows {Class, Object, Limit, [Value, Bound]}; 0 rows with the",
      "Desc": "same columns when c_row is empty",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "show_text",
      "Defining": "ResultPF",
      "Group": "show",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "s_text",
        "n_out"
      ],
      "OutputNames": [
        "c_out"
      ],
      "Arguments": [
        {
          "Name": "s_text",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Text of the view."
        },
        {
          "Name": "n_out",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "nargout of the disp_ method."
        }
      ],
      "Outputs": [
        {
          "Name": "c_out",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "cell",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "{} when displayed, {s_text} when returned."
        }
      ],
      "Signature": "c_out = show_text(s_text, n_out)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/private/show_text.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Displays s_text, or returns it when the caller asked for one output (disp_* methods)",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "violation_table",
      "Defining": "ResultPF",
      "Group": "violation",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct_network",
        "tab_bus",
        "tab_branch",
        "r_tol"
      ],
      "OutputNames": [
        "tab"
      ],
      "Arguments": [
        {
          "Name": "sct_network",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Snapshot of the network (struct(net, false)), buses in tab_bus order."
        },
        {
          "Name": "tab_bus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "tab_bus of the ResultPF."
        },
        {
          "Name": "tab_branch",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "tab_branch of the ResultPF (rows in the order of the branches of the snapshot)."
        },
        {
          "Name": "r_tol",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu, rad",
          "Description": "Excess below which a limit counts as met."
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
          "Description": "Columns Class, Object, Limit, Value, Bound, Excess (see ResultPF.tab_violation)."
        }
      ],
      "Signature": "tab = violation_table(sct_network, tab_bus, tab_branch, r_tol)",
      "File": "_GUILDAsystem/_auxiliary/@ResultPF/private/violation_table.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Operating limits (tab_parameter.operation) that the power flow solution violates.",
      "Desc": "One row per violated limit: the solution value is beyond the limit by more than r_tol.\nNaN and infinite limits are none. The limits are read from the network snapshot.\nChecked limits and values:\n\n- Bus: Vmin, Vmax on V.\n- Component: Pmin, Pmax on P and Qmin, Qmax on Q, the powers that initialize would\n  give it (tools.distribute_power with \"baseMVA\", as Bus.set_equilibrium by default:\n  tab_parameter.powerflow, the slack remainder and the split of the bus Q among the\n  components with Q = NaN).\n- Branch: Pmax on the larger |P|, Qmax on the larger |Q|, Smax on the larger |S| and\n  Imax on the larger |I| of the two ends, Vargmax on |Varg_from - Varg_to|.",
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
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nh = res.launch_gui();                        % new window\nfig = uifigure();\nh = res.launch_gui(uipanel(uigridlayout(fig, [1 1])));   % embedded in a panel\nhist = HistoryGUILDA();\nhist.run(\"Power flow\", \"Calculate\", \"net = network.IEEE9bus(); res_pf = net.calculate_powerflow();\");\nh = hist.get_variable(\"res_pf\").launch_gui(History=hist, Variable=\"res_pf\");\nhist.get_script()                            % the power flow and the actions of the GUI\n```\n\nSee also DrawerResultGUI, HistoryGUILDA, DrawerOptionDialog",
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
