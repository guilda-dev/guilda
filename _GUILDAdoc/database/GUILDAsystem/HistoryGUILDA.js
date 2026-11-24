(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["HistoryGUILDA"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "HistoryGUILDA",
  "properties": [
    {
      "Name": "tab_entry",
      "Defining": "HistoryGUILDA",
      "Group": "Log",
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
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/HistoryGUILDA.m",
      "Line": 34,
      "Summary": "One row per run: Group, Label, Code, Status (\"run\", \"done\" or \"fail\"), Detail.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_variable",
      "Defining": "HistoryGUILDA",
      "Group": "Workspace",
      "GetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/HistoryGUILDA.m",
      "Line": 37,
      "Summary": "Variables of the workspace the code runs in, by name.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "l_echo",
      "Defining": "HistoryGUILDA",
      "Group": "Workspace",
      "GetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/HistoryGUILDA.m",
      "Line": 38,
      "Summary": "Print \">> code\" and the output of each run in the Command Window.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "logical",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_header",
      "Defining": "HistoryGUILDA",
      "Group": "Workspace",
      "GetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/HistoryGUILDA.m",
      "Line": 39,
      "Summary": "Comment lines at the top of the script.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "attach_view",
      "Defining": "HistoryGUILDA",
      "Group": "attach",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "h_container"
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
          "Description": "The log."
        },
        {
          "Name": "h_container",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "uifigure, uipanel, uitab or uigridlayout of a uifigure."
        }
      ],
      "Outputs": [
        {
          "Name": "h",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The list box of the view. <@Type> matlab.ui.control.ListBox"
        }
      ],
      "Signature": "h = attach_view(obj, h_container)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/attach_view.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:HistoryGUILDA:NotUIContainer"
      ],
      "Summary": "Draw the log in a container of a uifigure and keep it up to date.",
      "Desc": "The view is a uilistbox that fills the container (a uifigure, uipanel or uitab gets a\n1-by-1 grid; in a uigridlayout it takes the next cell). Each entry is a line\n`[mark] Label → Detail` (mark □ none, ▶ \"run\", ✔ \"done\", ✖ \"fail\") followed by its code\nas `>> code` lines, under a `【Group】` heading for each run of consecutive entries of one\nGroup. It is redrawn on the event Changed until it is deleted. A double click on a `>>`\nline opens the file of the method or function it calls first, when that can be found\n(best effort: the class of the receiver is evaluated in the workspace of the log). The\ncolors are the fixed light palette of the GUILDA GUIs (tools.gui_palette).",
      "SeeAlso": [],
      "Examples": "```matlab\nfig = uifigure();\nh_list = h.attach_view(fig);\n```",
      "Deprecated": ""
    },
    {
      "Name": "export_script",
      "Defining": "HistoryGUILDA",
      "Group": "export",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_path"
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
          "Description": "The log."
        },
        {
          "Name": "s_path",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Path of the .m file; an existing file is overwritten."
        }
      ],
      "Outputs": [],
      "Signature": "export_script(obj, s_path)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/export_script.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:HistoryGUILDA:NotMFile",
        "GUILDA:HistoryGUILDA:CannotWrite"
      ],
      "Summary": "Write the script of get_script to a .m file (UTF-8).",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "```matlab\nh.export_script(\"build_net.m\")\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_script",
      "Defining": "HistoryGUILDA",
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
        "s_script"
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
          "Description": "The log."
        }
      ],
      "Outputs": [
        {
          "Name": "s_script",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Script text (lines separated by newline)."
        }
      ],
      "Signature": "s_script = get_script(obj)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/get_script.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "MATLAB script of the entries that ran without an error, in the order they ran.",
      "Desc": "The Header comes first. Each run of consecutive entries of one Group is a `%% <Group>`\nsection, and each entry is its code after a `% <Label>` line. Entries with Status \"fail\"\nor \"run\" are left out, so the script reproduces what the GUI did.",
      "SeeAlso": [],
      "Examples": "```matlab\ndisp(h.get_script())\n```",
      "Deprecated": ""
    },
    {
      "Name": "run",
      "Defining": "HistoryGUILDA",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_group",
        "s_label",
        "s_code"
      ],
      "OutputNames": [
        "l_ok",
        "s_detail"
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
          "Description": "The log."
        },
        {
          "Name": "s_group",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Group of the entry, e.g. the tab name; a section of the script."
        },
        {
          "Name": "s_label",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Short description of the action."
        },
        {
          "Name": "s_code",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "MATLAB code to run (possibly several lines)."
        }
      ],
      "Outputs": [
        {
          "Name": "l_ok",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True when the code ran without an error."
        },
        {
          "Name": "s_detail",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Result summary or error message, with the elapsed time."
        }
      ],
      "Signature": "[l_ok, s_detail] = run(obj, s_group, s_label, s_code)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/run.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Run a code string in the workspace of the log and record it as an entry.",
      "Desc": "The entry is added with Status \"run\", then the code is evaluated with evalc in the private\nworkspace (see HistoryGUILDA). Variables it assigns stay for the next runs. On success the\nStatus is \"done\" and the Detail is the first lines of the Command Window output with the\nelapsed time (without hyperlinks and control characters: evalc wraps a warning in \"[\" char(8)\n... \"]\" char(8), and a control character in the log list makes exportapp of the app fail); on an error the Status is \"fail\", the Detail is the error message, the\nworkspace stays as it was and the error is not rethrown. The event Changed is notified\nwhen the entry is added and when it ends. With Echo the code lines (\">> code\") and the\noutput are also printed in the Command Window.",
      "SeeAlso": [],
      "Examples": "```matlab\n[l_ok, s_detail] = h.run(\"Power flow\", \"Calculate\", \"res_pf = net.calculate_powerflow();\");\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_variable",
      "Defining": "HistoryGUILDA",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_name"
      ],
      "OutputNames": [
        "value"
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
          "Description": "The log."
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
          "Description": "Variable name."
        }
      ],
      "Outputs": [
        {
          "Name": "value",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Value of the variable."
        }
      ],
      "Signature": "value = get_variable(obj, s_name)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/get_variable.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:HistoryGUILDA:UnknownVariable"
      ],
      "Summary": "Value of a variable of the workspace the code runs in.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "```matlab\nh.run(\"Power flow\", \"Calculate\", \"res_pf = net.calculate_powerflow();\");\nres_pf = h.get_variable(\"res_pf\");\n```",
      "Deprecated": ""
    },
    {
      "Name": "set_variable",
      "Defining": "HistoryGUILDA",
      "Group": "set",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_name",
        "value"
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
          "Description": "The log."
        },
        {
          "Name": "s_name",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeValidVariableName"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Variable name (not varargin or varargout)."
        },
        {
          "Name": "value",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Value of the variable."
        }
      ],
      "Outputs": [],
      "Signature": "set_variable(obj, s_name, value)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/set_variable.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:HistoryGUILDA:ReservedName"
      ],
      "Summary": "Set a variable of the workspace the code runs in.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "```matlab\nh.set_variable(\"net\", network.IEEE9bus());\n```",
      "Deprecated": ""
    },
    {
      "Name": "HistoryGUILDA",
      "Defining": "HistoryGUILDA",
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
          "Name": "Echo",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Print \">> code\" and the output of each run in the Command Window."
        },
        {
          "Name": "Header",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "string.empty",
          "Required": false,
          "Unit": "",
          "Description": "Comment lines at the top of the script (\"% \" is added when missing)."
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
          "Description": "The log."
        }
      ],
      "Signature": "obj = HistoryGUILDA(Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/HistoryGUILDA.m",
      "Line": 47,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create an empty log with an empty workspace.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "eval_workspace",
      "Defining": "HistoryGUILDA",
      "Group": "eval",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "varargin"
      ],
      "OutputNames": [
        "varargout"
      ],
      "Arguments": [
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
          "Description": "1: variables by name (struct); 2: code (char)."
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
          "Description": "1: variables after the code (struct); 2: Command Window output of the code (char)."
        }
      ],
      "Signature": "varargout = eval_workspace(varargin)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/private/eval_workspace.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Evaluate code in a workspace of its own: unpack the variables, run the code, pack them back.",
      "Desc": "The only names used here are varargin and varargout, so the code can use every other name\nwithout a collision with a variable of this function. An error of the code propagates to\nthe caller, which keeps its own copy of the variables.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "open_line",
      "Defining": "HistoryGUILDA",
      "Group": "open",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "h"
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
          "Description": "The log."
        },
        {
          "Name": "h",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "List box of the view."
        }
      ],
      "Outputs": [],
      "Signature": "open_line(obj, h)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/private/open_line.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Open in the Editor the file of the method or function that the double-clicked `>>` line calls.",
      "Desc": "The first call `<receiver>.<method>(` of the line is used, with the class of the receiver\nevaluated in the workspace of the log; otherwise the first `<function>(`. Nothing happens when no file is\nfound (best effort).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "render_view",
      "Defining": "HistoryGUILDA",
      "Group": "render",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "h"
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
          "Description": "The log."
        },
        {
          "Name": "h",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "List box of the view."
        }
      ],
      "Outputs": [],
      "Signature": "render_view(obj, h)",
      "File": "_GUILDAsystem/_auxiliary/@HistoryGUILDA/private/render_view.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Redraw a view of attach_view: a line per entry and per code line.",
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
  "events": [
    "Changed"
  ],
  "enumeration": [],
  "validation": {
    "Warnings": [],
    "Errors": []
  }
};
})(window);
