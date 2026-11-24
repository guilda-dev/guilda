(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["ResultBase"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "ResultBase",
  "properties": [
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
      "Name": "ResultBase",
      "Defining": "ResultBase",
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
        "elapsed"
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
          "Description": "Analysed network (kept as a reference) or [] (results built from a snapshot)."
        },
        {
          "Name": "solver",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Solver object that ran the analysis, or its class name."
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
          "Description": "Effective settings of the run."
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
          "Description": "Success or convergence flag."
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
          "Description": "Solver details."
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
          "Description": "Elapsed time, or the value returned by tic at the start of the analysis."
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
      "Signature": "obj = ResultBase(net, solver, options, flag, output, elapsed)",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 54,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Initialize the shared part of a result.",
      "Desc": "Stores the parts shared by every result. Call it from a subclass constructor\nas obj@ResultBase(...).",
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
