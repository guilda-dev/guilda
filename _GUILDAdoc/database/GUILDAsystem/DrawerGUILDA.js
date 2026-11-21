(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["DrawerGUILDA"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "DrawerGUILDA",
  "properties": [
    {
      "Name": "history",
      "Defining": "DrawerGUILDA",
      "Group": "App",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 58,
      "Summary": "Log that runs and records every action of the app as code.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "HistoryGUILDA",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "G",
      "Defining": "DrawerGUILDA",
      "Group": "App",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 59,
      "Summary": "Network diagram of the active tab ([] before its first drawing).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "GraphNetDiagram",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_figure",
      "Defining": "DrawerGUILDA",
      "Group": "App",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 60,
      "Summary": "Figure of the app.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.Figure",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_tab",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 63,
      "Summary": "Tabs (tab_list) with h_button, h_panel, l_built, the hooks f_show, f_changed, f_diagram, f_legend, f_click, and n_changed (n_change at its last f_changed), the diagram h_diagram, G, n_drawn (n_change at its drawing), l_flow (its FlowAnimation while hidden), a_click, s_error (of its drawing) and l_controls (its control panel has controls).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_active",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 64,
      "Summary": "Key of the active tab (\"\" before the main layout).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_root",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 65,
      "Summary": "Grid of the figure: the tab bar over the body.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.container.GridLayout",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_info",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 66,
      "Summary": "Info strip over the diagram (two lines).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.control.Label",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_toggle",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 67,
      "Summary": "Toggle \"Display options\".",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.control.StateButton",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_diagram",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 68,
      "Summary": "Panel of the diagrams (Tag \"diagram\"); its grid holds one panel per tab.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.container.Panel",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_side",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 69,
      "Summary": "Grid of the diagram panel and, in its second column, the control panels of the diagrams.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.container.GridLayout",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_listener",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 70,
      "Summary": "Listener of the history (Changed).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "event.listener",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "n_change",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 71,
      "Summary": "Number of the ended runs of the history; a diagram drawn at a smaller number is out of date.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_timer",
      "Defining": "DrawerGUILDA",
      "Group": "Layout",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 72,
      "Summary": "Single-shot timer (0.05 s) of the drawing after a run in a visible figure.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "timer",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "DrawerGUILDA",
      "Defining": "DrawerGUILDA",
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
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Network to work on; [] shows the start screen. <@Type> PowerNetwork"
        },
        {
          "Name": "Visible",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "matlab.lang.OnOffSwitchState",
          "Validators": [],
          "Default": "\"on\"",
          "Required": false,
          "Unit": "",
          "Description": "Visibility of the figure."
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
          "Description": "The app."
        }
      ],
      "Signature": "obj = DrawerGUILDA(net, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/DrawerGUILDA.m",
      "Line": 76,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [
        "GUILDA:DrawerGUILDA:NotNetwork"
      ],
      "Summary": "Create the app in a new uifigure: the start screen, or the main layout with net.",
      "Desc": "Called by GUILDA.launch_gui. Visible=false builds the app in a hidden figure (tests).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "stale_banner",
      "Defining": "DrawerGUILDA",
      "Group": "stale",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "h_grid",
        "i_row",
        "s_group"
      ],
      "OutputNames": [
        "h_banner"
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
          "Name": "h_grid",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "matlab.ui.container.GridLayout",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Grid of the tab."
        },
        {
          "Name": "i_row",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Row of the banner in h_grid."
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
          "Description": "Group of the initialize entry."
        }
      ],
      "Outputs": [
        {
          "Name": "h_banner",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Grid layout of the banner. <@Type> matlab.ui.container.GridLayout"
        }
      ],
      "Signature": "h_banner = stale_banner(obj, h_grid, i_row, s_group)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/stale_banner.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Banner in a row of a grid that asks for net.initialize() while the network is stale.",
      "Desc": "The banner (Tag \"stale_banner\") spans all columns of row i_row of h_grid. While the\nnetwork is stale it shows the stale tags (Tag \"stale_text\") and the button\n\"Run initialize\" (Tag \"initialize\"), which runs `net.initialize();` through the history\n(initialize shows its own progress, so the app opens no progress dialog); otherwise the\nheight of the row is 0. It is updated on every event Changed of the history until it is\ndeleted.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "run_code",
      "Defining": "DrawerGUILDA",
      "Group": "run",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_group",
        "s_label",
        "s_code",
        "opt"
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
          "Description": ""
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
          "Description": "Group of the entry (a section of the script)."
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
          "Description": "Label of the entry."
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
          "Description": "MATLAB code to run."
        },
        {
          "Name": "Progress",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Message of the progress dialog (\"\": none)."
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
          "Description": "Result summary or error message (HistoryGUILDA.run)."
        }
      ],
      "Signature": "[l_ok, s_detail] = run_code(obj, s_group, s_label, s_code, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/run_code.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Run code through the history, with a progress dialog for a long run; a failure shows an alert.",
      "Desc": "With Progress, an indeterminate uiprogressdlg without a cancel button shows the message\nwhile the code runs (only on a visible figure outside matlab -batch). A failed run shows\nits message in a uialert on a visible figure; the log keeps it in any case.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "on_history_changed",
      "Defining": "DrawerGUILDA",
      "Group": "on",
      "Access": "private",
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
      "Signature": "on_history_changed(obj)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/on_history_changed.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Follow the history: when an entry ends, update the tabs and draw the diagram again.",
      "Desc": "On the start screen, an entry that ends with a network in `net` replaces it with the main\nlayout. Afterwards each ended entry (done or failed: a failed run may have changed part of\nthe network) marks all tabs out of date (n_change), calls the hook f_changed of the\nactive tab and then redraw, which draws its diagram. A hidden tab gets f_changed and its\ndrawing on its next show (show_tab). In a visible figure (outside matlab -batch) redraw\nruns from a single-shot timer (h_timer, 0.05 s) right after the run, so the GUI that ran\nthe code draws itself first, and the runs ended before the timer fires are drawn once; a\nhidden figure (tests) draws at once.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "redraw",
      "Defining": "DrawerGUILDA",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "l_force"
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
          "Name": "l_force",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Draw the diagram of the active tab even when it is up to date."
        }
      ],
      "Outputs": [],
      "Signature": "redraw(obj, l_force)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/redraw.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Write the info strip for the active tab, draw its diagram when it is out of date, and show the controls of the diagram. Nothing is logged.",
      "Desc": "Each tab draws into a panel of its own (Tag \"diagram_<key>\", made on its first drawing) in\nthe grid of h_diagram. Its diagram is drawn when the history ended a run since its last\ndrawing (n_drawn < n_change) or with l_force (f_redraw of the tab API); otherwise it is\nshown as it is. The hook f_diagram of the tab draws it; without it, draw_network draws\nnet.plot_diagram(State=\"auto\") with no selection. When the hook returns another diagram,\nthe click listener of the tab moves to it; [] means no diagram. An error of the drawing is\nshown in the info strip. obj.G is the diagram of the active tab.\n\nThe first line of the info strip shows the counts of buses, branches and components, the\nstale state of the network and the last entry of the history. The second line says what\nthe colors of the diagram mean: the hook f_legend of the tab, or by default the legend of\ndraw_network (branch currents, or the topology while the network is stale).\n\nWhile the toggle \"Display options\" is pressed, the second column of h_side (230 px) holds\nthe control panel of the diagram of the active tab (G.show_controls, made once per\ndiagram and kept through its drawings; those of the other tabs are hidden); its changes are\nnot logged. A diagram without declared controls keeps the column at 0 px and the info\nstrip says so. Otherwise that column is 0 px wide and the control panels are removed.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "call_hook",
      "Defining": "DrawerGUILDA",
      "Group": "call",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_hook",
        "varargin"
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
          "Name": "s_hook",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name of the hook."
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
          "Description": "Arguments of the hook."
        }
      ],
      "Outputs": [],
      "Signature": "call_hook(obj, s_hook, varargin)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/call_hook.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Call a hook of the active tab (f_show, f_click) when the tab has it.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "show_tab",
      "Defining": "DrawerGUILDA",
      "Group": "show",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_key"
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
          "Name": "s_key",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Key of the tab (tab_list)."
        }
      ],
      "Outputs": [],
      "Signature": "show_tab(obj, s_key)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/show_tab.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Make a tab active: press its button, show its panel and its diagram (building the tab on",
      "Desc": "its first show), call its hook f_show and draw its diagram when it is out of date.\n\nA built tab that missed runs of the history while hidden gets its hook f_changed first,\nonce, before its panel is shown. Only the button, panel and diagram panel of the tab left\nand of the tab shown change. The\ndiagram of the tab left stops its flow animation (its FlowAnimation is kept and given back\non its next show). The build function of the tab (tab_list) gets the tab API (see\ntab_list) and returns the hooks; a hook it leaves out stays [].",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_main",
      "Defining": "DrawerGUILDA",
      "Group": "build",
      "Access": "private",
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
      "Signature": "build_main(obj)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/build_main.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the main layout in place of the start screen and show the model tab.",
      "Desc": "Left half, from top to bottom: the info strip (Tag \"info\", two lines) with the toggle\n\"Display options\" (Tag \"diagram_controls\"); the diagram panel (Tag \"diagram\") in the first\ncolumn of h_side, whose second column (0 px while the toggle is off) holds the control\npanel of the diagram; the header of the log with \"Hide log\" (Tag \"log_toggle\") and\n\"Export script\" (Tag \"export\"); the run log (130 px, 0 when hidden). The diagram gets all\nthe height left; its panel holds a grid in which each tab draws into a panel of its own\n(redraw). Right half: one hidden uipanel per tab (Tag \"tab_<key>\"), all in the\nsame cell; show_tab builds and shows them.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_start",
      "Defining": "DrawerGUILDA",
      "Group": "build",
      "Access": "private",
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
      "Signature": "build_start(obj)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/build_start.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the start screen: the four ways to get a network, each run as code through the history.",
      "Desc": "- Empty network (Tag \"start_empty\"): `net = PowerNetwork();`.\n- Sample network: the classes of `_GUILDAobject/+network` (folders @Name and files Name.m)\n  in a drop-down (Tag \"start_sample\"); Load (Tag \"start_sample_load\") runs\n  `net = network.<Name>();`.\n- Model folder: a model folder (Tag \"start_folder\", Browse... opens uigetdir when the\n  figure is visible); Load (Tag \"start_folder_load\") runs `net = PowerNetwork.import(\"<path>\");`.\n- MATPOWER case: a case name or a .m/.mat file (Tag \"start_matpower\", Browse... opens uigetfile);\n  Load (Tag \"start_matpower_load\") runs `net = PowerNetwork.import_matpower(\"<case>\");`.\n\nThe loads run with a progress dialog. When the run ends with a network in `net`, the\nhistory listener (on_history_changed) replaces the start screen with the main layout; a\nfailed run shows its message under the choices (Tag \"start_message\").",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "analyze_highlight",
      "Defining": "DrawerGUILDA",
      "Group": "analyze",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "history",
        "s_call",
        "s_variable",
        "res_opened",
        "h_run",
        "h_analyze"
      ],
      "OutputNames": [
        "l_new",
        "res"
      ],
      "Arguments": [
        {
          "Name": "history",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "History of the app."
        },
        {
          "Name": "s_call",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Start of the code of the call of the tab."
        },
        {
          "Name": "s_variable",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Result variable, e.g. \"res_pf\"."
        },
        {
          "Name": "res_opened",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Result last opened from the tab, or []."
        },
        {
          "Name": "h_run",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Run button of the tab."
        },
        {
          "Name": "h_analyze",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Analyze result button of the tab."
        }
      ],
      "Outputs": [
        {
          "Name": "l_new",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "A new result is unopened (Analyze result is highlighted)."
        },
        {
          "Name": "res",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The result variable when it holds a scalar ResultBase, else []."
        }
      ],
      "Signature": "[l_new, res] = analyze_highlight(history, s_call, s_variable, res_opened, h_run, h_analyze)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/analyze_highlight.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Style Run and Analyze result of a tab: Analyze result is the filled primary button while a new result is unopened.",
      "Desc": "The result is the variable s_variable of the history. It is new while it is a scalar\nResultBase, the last ended entry of the history whose code starts with s_call (the call\nof the tab, e.g. \"[res_pf, flag_pf] = net.calculate_powerflow(\") is done, and it is not\nres_opened (the result last opened from the tab). Then Analyze result is filled with the\nlogo blue, bold with white text, and Run takes the plain style of the other buttons; else\nRun is the filled one and Analyze result plain. Analyze result is enabled while the\nvariable holds a scalar ResultBase. Only properties that change are set.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "draw_network",
      "Defining": "DrawerGUILDA",
      "Group": "draw",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "G",
        "h_parent",
        "net",
        "l_clear"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "G",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram shown, or []."
        },
        {
          "Name": "h_parent",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the diagram."
        },
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "PowerNetwork",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Network to draw."
        },
        {
          "Name": "l_clear",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Clear the selection."
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
          "Description": "Diagram drawn; [] for a network without buses (a note is shown instead). <@Type> GraphNetDiagram"
        }
      ],
      "Signature": "G = draw_network(G, h_parent, net, l_clear)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/draw_network.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw net.plot_diagram(State=\"auto\") in the diagram panel: into G when it is a diagram shown there, else anew.",
      "Desc": "Into an existing GraphNetDiagram, plot_diagram(Graph=G) keeps the positions, styles and\nselection of the elements by tag; otherwise the panel is emptied and a new diagram is\ndrawn in it. A network without buses gets a note instead and G is []. The INFO message of a topology drawing (a stale network) is not printed: the\ninfo strip of the app shows the stale state. The branches and links are colored by their\ncurrent (ColorMode \"I\", ColorbarLabel \"Branch current |I| [pu]\"), and no title is written.\nThe default drawing of the tabs (redraw) and the model tab use it.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_analysis_diagram",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "G",
        "h_parent",
        "history",
        "f_draw"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "G",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram of the tab, or []."
        },
        {
          "Name": "h_parent",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram panel of the tab."
        },
        {
          "Name": "history",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "History of the app (net and the result variables)."
        },
        {
          "Name": "f_draw",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "@(G, h_parent, history) returning the GraphNetDiagram drawn."
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
          "Description": "Diagram drawn, or [] (draw_network for a network without buses). <@Type> GraphNetDiagram"
        }
      ],
      "Signature": "G = tab_analysis_diagram(G, h_parent, history, f_draw)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_analysis_diagram.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Diagram of an analysis tab: drawn by f_draw in the diagram panel of the tab, or the default one on an error.",
      "Desc": "f_draw gets the diagram of the tab and draws into it (Graph=G) or anew in h_parent (see\ntab_pf_diagram). The INFO messages of the drawing are not printed. On any error of f_draw\nthe panel is emptied and the default diagram (draw_network) is drawn instead.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_analysis_legend",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "history",
        "s_variable",
        "s_class",
        "s_after",
        "s_before"
      ],
      "OutputNames": [
        "s_legend"
      ],
      "Arguments": [
        {
          "Name": "history",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "History of the app."
        },
        {
          "Name": "s_variable",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Result variable of the tab, e.g. \"res_pf\"."
        },
        {
          "Name": "s_class",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Class of the result, e.g. \"ResultPF\"."
        },
        {
          "Name": "s_after",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Legend after a run."
        },
        {
          "Name": "s_before",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Legend before a run."
        }
      ],
      "Outputs": [
        {
          "Name": "s_legend",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One line for the info strip."
        }
      ],
      "Signature": "s_legend = tab_analysis_legend(history, s_variable, s_class, s_after, s_before)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_analysis_legend.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Legend of the diagram of an analysis tab: s_after while the result variable holds a result of s_class, else s_before.",
      "Desc": "The hook f_legend of the CPF tab (tab_list); it follows the same rule as its diagram\nfunction (the LoadBus buses of the last run selected).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_analysis_panel",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel",
        "sct_app",
        "sct_spec"
      ],
      "OutputNames": [
        "sct_hook"
      ],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
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
          "Description": "s_signature, sv_output ([result, flag]), s_label (log), l_banner, sv_exclude, f_value (@(net) struct of DrawerOptionDialog Value), s_note, sct_extra (0 or 1: s_signature, s_title, s_text and s_tag of the button, s_label)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_hook",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Hook f_changed (the diagram hooks are added by the tab)."
        }
      ],
      "Signature": "sct_hook = tab_analysis_panel(h_panel, sct_app, sct_spec)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_analysis_panel.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Panel of an analysis tab: Run, Analyze result and the status of the last run over the option form of its method.",
      "Desc": "The analysis tabs (pf, opf, cpf, lin) call it from their build functions. From top to bottom:\n\n- the stale banner (sct_spec.l_banner; tabs that need the equilibrium),\n- the title of the tab,\n- the buttons Run (Tag \"run\"), which runs dlg.get_code() through the history (no progress\n  dialog of the app: the analysis shows its own), and Analyze result (Tag \"analyze\"), and the status line (Tag\n  \"status\") next to them: the flag and the elapsed time of the last run, or its error,\n- the form DrawerOptionDialog(s_signature, Object=\"net\", Output=sv_output, History=<app>),\n  with the initial values of f_value(net) (DrawerOptionDialog Value),\n- an optional second form sct_extra of another method on net (e.g. net.initialize of the\n  power flow tab): a heading with its button (Tag s_tag) on the same line, then the form\n  (panel Tag \"form_<s_tag>\", no outputs); the button runs its code the same way,\n- the note of the tab (Tag \"note\", a hint on the inputs; \"\" leaves no row).\n\nEvery row takes the height of its content (\"fit\"): a form is a 1x1 grid (Tag \"form\" or\n\"form_<s_tag>\") whose row fits the grid of the DrawerOptionDialog, so the rows below follow\nthe form when a group opens or closes. The space left stays under the last row; the panel\nscrolls when the forms are taller than the tab.\n\nThe latest result overwrites the variable sv_output(1) of the history (one per tab).\nAnalyze result is enabled while that variable holds a ResultBase. While the result of the\nlast run is new (not opened from the tab yet; analyze_highlight), Analyze result is the\nfilled logo-blue button with bold white text, Run takes the plain style and the status\nline ends with \"open Analyze result\"; opening the result, or a failed run, puts the two\nbuttons back. It opens\nres.launch_gui(History=<app>, Variable=sv_output(1)) in a new window (a uifigure as\nvisible as the app; Tag \"result_gui\"), so the actions of the result GUI go to the same log\nand script. Opening it is not logged: it changes no variable, and a script that opens\nwindows would not repeat the analysis.\n\nThe form is built for the network `net` of the history and built again when `net`\nbecomes another network (the choices and defaults on obj, e.g. LoadBus). The hook\nf_changed follows the history: the status and the Run and Analyze result buttons. The\nstate is in h_panel.UserData (net, dlg, h_form, dlg_extra, h_form_extra, h_status, h_run,\nh_analyze, res_opened: the result last opened).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_cpf_build",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel",
        "sct_app"
      ],
      "OutputNames": [
        "sct_hook"
      ],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_hook",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Hooks of the tab (see tab_list)."
        }
      ],
      "Signature": "sct_hook = tab_cpf_build(h_panel, sct_app)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_cpf_build.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "CPF tab: calculate_continuation_powerflow, with the stale banner.",
      "Desc": "The panel is tab_analysis_panel with the form of\nPowerNetwork.calculate_continuation_powerflow; the latest result overwrites res_cpf and\nflag_cpf of the history. While net.solver_CPF.LoadBus is empty, LoadBus starts with the\nbuses that have a load (component.load.*), so the form runs as it is. The diagram is\ntab_cpf_diagram.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_cpf_diagram",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "G",
        "h_parent",
        "history"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "G",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram of the tab, or []."
        },
        {
          "Name": "h_parent",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram panel of the tab."
        },
        {
          "Name": "history",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "History of the app."
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
          "Description": "Diagram drawn. <@Type> GraphNetDiagram"
        }
      ],
      "Signature": "G = tab_cpf_diagram(G, h_parent, history)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_cpf_diagram.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Diagram of the CPF tab: net.plot_diagram(State=\"auto\"), with the LoadBus buses of res_cpf selected after a run.",
      "Desc": "It draws into the diagram of the tab (Graph=G) when there is one, else anew in h_parent.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_cpf_value",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "net"
      ],
      "OutputNames": [
        "sct_value"
      ],
      "Arguments": [
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "PowerNetwork",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Network of the form."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_value",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "DrawerOptionDialog Value: LoadBus, or no field."
        }
      ],
      "Signature": "sct_value = tab_cpf_value(net)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_cpf_value.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Initial LoadBus of the CPF form: the buses with a load (component.load.*) while net.solver_CPF.LoadBus is empty.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_lin_build",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel",
        "sct_app"
      ],
      "OutputNames": [
        "sct_hook"
      ],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_hook",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Hooks of the tab (see tab_list)."
        }
      ],
      "Signature": "sct_hook = tab_lin_build(h_panel, sct_app)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_lin_build.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Linearization tab: get_sys, with the stale banner.",
      "Desc": "The panel is tab_analysis_panel with the form of PowerSystemModel.get_sys; the latest result\noverwrites res_lin and flag_lin of the history. The point input keeps its default [] (the\nequilibrium of net.initialize). The diagram is the default one (draw_network: the\nequilibrium, or the topology while stale).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_list",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [],
      "OutputNames": [
        "sct_tab"
      ],
      "Arguments": [],
      "Outputs": [
        {
          "Name": "sct_tab",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "s_key, s_title (tab bar), s_group (history group) and f_build of each tab."
        }
      ],
      "Signature": "sct_tab = tab_list()",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_list.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "The tabs of the GUILDA app, in the order of the tab bar: the only place they are registered.",
      "Desc": "Each tab is a set of private files of DrawerGUILDA named after its key, tab_<key>_*.m.\nIts build function `sct_hook = tab_<key>_build(h_panel, sct_app)` is called on the first\nshow of the tab. It fills h_panel (a uipanel of the right half of the app) and returns its\nhooks, a struct whose fields are all optional:\n\n- `f_show()`: the tab became the active tab (also right after the build). It runs on\n  every switch, so it should be cheap: redraw only what a run changed while the tab was\n  hidden (f_changed sees that the panel of the tab is hidden).\n- `f_changed()`: entries of the history ended (done or failed). The active tab gets it\n  after each entry, before its diagram is drawn again; a hidden tab gets it once on its\n  next show, while its panel is still hidden (before f_show).\n- `G = f_diagram(G, h_parent)`: draw the diagram of the tab. Each tab has a diagram of\n  its own: G is the diagram the hook returned last ([] before the first one) and h_parent\n  the diagram panel of the tab, which only the hook draws into (its UserData is free for\n  the hook). The frame calls it while the tab is active, when a run of the history ended\n  since the last drawing (also on the show of a tab that was hidden then) and on\n  f_redraw; a tab switch without a run in between does not call it. Return the diagram\n  drawn: G itself (e.g. net.plot_diagram(Graph=G, ...), which reuses the graphics objects\n  and keeps the positions, styles and selection; the fastest), or a new one drawn in\n  h_parent after delete(h_parent.Children) (e.g. net.plot_diagram(Parent=h_parent)), or\n  [] for no diagram (the panel shows what the hook drew in it). Without the hook the\n  frame draws net.plot_diagram(State=\"auto\") with no selection (draw_network). The\n  drawing is not logged. The diagram fits itself to its panel; the frame does not change\n  its limits. The diagrams show the network at the equilibrium (or its topology while\n  stale) with the conditions of the tab selected; a result is viewed in the Analyze result\n  window, not in the diagram.\n- `s_legend = f_legend()`: what the colors and selection of the diagram of the tab mean,\n  one line for the info strip (e.g. \"Bus colors: slack red, PV blue, PQ gray.\"), called\n  after each drawing while the tab is active. Without it the frame writes the legend of\n  draw_network.\n- `f_click(data)`: an element of the diagram of the tab was clicked (data:\n  GraphEventData with Tag, Kind and Index).\n\nsct_app, the tab API, holds:\n\n- `app`: the DrawerGUILDA (read app.G, the diagram of the active tab, app.history, app.h_figure).\n- `history`: the HistoryGUILDA of the app; `history.get_variable(\"net\")` is the network.\n- `s_title`: the title of the tab (tab bar).\n- `s_group`: the group of the entries of the tab (a section of the script).\n- `[l_ok, s_detail] = f_run(s_label, s_code, Progress=s_message)`: run code through the\n  history in the group of the tab. With Progress, an indeterminate uiprogressdlg without\n  cancel shows s_message while it runs (visible figure only). Code that runs an analysis\n  passes no Progress: the analysis shows its own progress dialog (ProgressGUILDA) in the\n  app figure (Tag \"GUILDA:app\"), and two dialogs in one figure would both stay open. A\n  failure shows an alert (visible figure only); the log keeps it in any case.\n- `h_banner = f_stale_banner(h_grid, i_row)`: a banner in row i_row of the uigridlayout\n  h_grid (all columns). While the network is stale it shows the stale tags and the button\n  \"Run initialize\", which runs `net.initialize();` through the history; otherwise the\n  row height is 0. It follows the history by itself.\n- `f_redraw()`: draw the diagram of the active tab again now (e.g. after the tab changed\n  what it highlights).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_model_build",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel",
        "sct_app"
      ],
      "OutputNames": [
        "sct_hook"
      ],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_hook",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Hooks f_show, f_changed, f_diagram and f_click."
        }
      ],
      "Signature": "sct_hook = tab_model_build(h_panel, sct_app)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_build.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Model tab: the model GUI of the element selected in the diagram.",
      "Desc": "The panel holds net.launch_gui(<panel>, History=<history of the app>), a DrawerModelGUI\nthat shows the network first. Its state is in h_panel.UserData: the GUI, the network it\nshows and its listeners. A click on the diagram shows the element (tab_model_click); the\nelement shown is selected in the diagram after each drawing, after a navigation in the\nmodel GUI (TargetChanged) and after its actions (ModelChanged) (tab_model_select).\n\nIt is also the hook f_changed: when `net` of the history is another network than the one\nshown (e.g. `net = network.IEEE14bus();` from the start screen or the log), the GUI is\nbuilt again for it. A run that ends while the tab is hidden marks the GUI out of date\n(l_stale), and the hook f_show (tab_model_show) draws it again on the next show; a show\nwithout a run in between draws nothing.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_model_click",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "data",
        "h_panel"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "data",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "GraphEventData of the click (Tag, Kind, Index)."
        },
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab (UserData: the model GUI and its network)."
        }
      ],
      "Outputs": [],
      "Signature": "tab_model_click(data, h_panel)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_click.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Show the clicked element of the diagram in the model GUI: a bus, a branch or a component (also its link).",
      "Desc": "The element is found by its tag in the network of the model GUI; the model GUI then\nnotifies TargetChanged, which selects it in the diagram.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_model_diagram",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "G",
        "h_parent",
        "h_panel",
        "history"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "G",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram shown, or []."
        },
        {
          "Name": "h_parent",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the diagram."
        },
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab (UserData: the model GUI)."
        },
        {
          "Name": "history",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "History of the app."
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
          "Description": "Diagram drawn. <@Type> GraphNetDiagram"
        }
      ],
      "Signature": "G = tab_model_diagram(G, h_parent, h_panel, history)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_diagram.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Diagram of the model tab: net.plot_diagram(State=\"auto\") with the element of the model GUI selected.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_model_select",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "G",
        "a_target",
        "net"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "G",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram, or [] before the first one."
        },
        {
          "Name": "a_target",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Model shown in the model GUI."
        },
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
          "Description": "Network of the model GUI."
        }
      ],
      "Outputs": [],
      "Signature": "tab_model_select(G, a_target, net)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_select.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Select in the diagram the element of the model shown: a bus, a branch or a component.",
      "Desc": "A local controller selects its component (searched through the controllers of every\ncomponent, nested ones included). The network, a global controller or a scenario has no\nelement: the selection is cleared.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_model_show",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab (UserData: the model GUI and l_stale)."
        }
      ],
      "Outputs": [],
      "Signature": "tab_model_show(h_panel)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_model_show.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Hook f_show of the model tab: draw the model GUI again when a run ended while the tab was hidden.",
      "Desc": "The model GUI draws itself after its own actions; a run from another tab or the log while\nthe model tab is hidden marks it out of date (l_stale, tab_model_build).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_opf_build",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel",
        "sct_app"
      ],
      "OutputNames": [
        "sct_hook"
      ],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_hook",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Hooks of the tab (see tab_list)."
        }
      ],
      "Signature": "sct_hook = tab_opf_build(h_panel, sct_app)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_opf_build.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "OPF tab: calculate_optimal_powerflow.",
      "Desc": "The panel is tab_analysis_panel with the form of PowerNetwork.calculate_optimal_powerflow;\nthe latest result overwrites res_opf and flag_opf of the history. The diagram is\ntab_opf_diagram (the components with a cost selected, before and after a run).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_opf_diagram",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "G",
        "h_parent",
        "history"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "G",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram of the tab, or []."
        },
        {
          "Name": "h_parent",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram panel of the tab."
        },
        {
          "Name": "history",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "History of the app."
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
          "Description": "Diagram drawn. <@Type> GraphNetDiagram"
        }
      ],
      "Signature": "G = tab_opf_diagram(G, h_parent, history)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_opf_diagram.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Diagram of the OPF tab: the network at the equilibrium with the components that have a cost selected.",
      "Desc": "net.plot_diagram(State=\"auto\") with the components that have a cost in\ntab_parameter.OPF (HP, fP, HQ or fQ not 0) selected, into the diagram of the tab (Graph=G)\nwhile it shows the network (h_parent.UserData \"network\"), else anew in h_parent. A run\ndoes not change the drawing: the result (e.g. its LMP) is viewed in the Analyze result\nwindow.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_pf_build",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel",
        "sct_app"
      ],
      "OutputNames": [
        "sct_hook"
      ],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_hook",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Hooks of the tab (see tab_list)."
        }
      ],
      "Signature": "sct_hook = tab_pf_build(h_panel, sct_app)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_pf_build.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Power flow tab: calculate_powerflow, and the form of net.initialize.",
      "Desc": "The panel is tab_analysis_panel with the form of PowerNetwork.calculate_powerflow; the\nlatest result overwrites res_pf and flag_pf of the history. Under it, the form of\nPowerNetwork.initialize and the button \"Set equilibrium\" (Tag \"pf_initialize\") run\nnet.initialize(...); (no outputs). Its options whose default is written in words (the\nsettings of the analysis that Method runs) start empty and are left out. The diagram is\ntab_pf_diagram (the buses colored by type, before and after a run).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_pf_diagram",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "G",
        "h_parent",
        "history"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "G",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram of the tab, or []."
        },
        {
          "Name": "h_parent",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram panel of the tab."
        },
        {
          "Name": "history",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "History of the app."
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
          "Description": "Diagram drawn. <@Type> GraphNetDiagram"
        }
      ],
      "Signature": "G = tab_pf_diagram(G, h_parent, history)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_pf_diagram.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Diagram of the power flow tab: the network at the equilibrium with the buses colored by type.",
      "Desc": "net.plot_diagram(State=\"auto\") without flow colors and without a colorbar, the buses\ncolored by their power-flow type (Bus.s_bustype): slack red, PV blue, PQ gray. A run does\nnot change the drawing: the result is viewed in the Analyze result window.\n\nThe network is drawn into the diagram of the tab (Graph=G) while it shows the network\n(h_parent.UserData \"network\"), else anew in h_parent.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_sim_action",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "s_action",
        "h_panel",
        "sct_app"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "s_action",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(s_action, [\"add\", \"remove\", \"select\", \"run\", \"analyze\", \"show\"])"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Control."
        },
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab (UserData: the state, see tab_sim_build)."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
        }
      ],
      "Outputs": [],
      "Signature": "tab_sim_action(s_action, h_panel, sct_app)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_action.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Run a control of the time simulation tab: a button, the list or a hook.",
      "Desc": "- \"add\": the form of PowerNetwork.add_scenario in a dialog (DrawerOptionDialog.ask), run\n  as `sc = net.add_scenario(...);`; the new scenario becomes the selection (tab_sim_refresh).\n- \"remove\": `net.remove_scenario(\"<tag>\");` of the selection, after a uiconfirm on a\n  visible figure outside matlab -batch.\n- \"select\": show the scenario selected in the list (model GUI, form, diagram).\n- \"run\": the code of the simulate form, without a progress dialog of the app (simulate\n  shows its own, ProgressGUILDA). The scenario selected\n  is remembered for the result (tab_sim_refresh); a form value that is invalid or a\n  failed run is written in the status line.\n- \"analyze\": `res_ode.launch_gui(History=<history>, Variable=\"res_ode\")` in a new\n  window (a hidden one when the app is hidden); the DrawerResultGUI is kept in the\n  UserData of the button. The result becomes the one opened (res_opened), so Run and\n  Analyze result get their normal styles back.\n- \"show\": the hook f_show. The model GUI is drawn again when a run ended while the tab\n  was hidden (l_stale: the scenario may have been edited elsewhere). The diagram of the\n  tab is its own, so it stays as it is.\n\nNothing but add, remove and run is logged.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_sim_build",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel",
        "sct_app"
      ],
      "OutputNames": [
        "sct_hook"
      ],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_hook",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Hooks f_show, f_changed, f_diagram and f_legend."
        }
      ],
      "Signature": "sct_hook = tab_sim_build(h_panel, sct_app)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_build.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Time simulation tab: the scenarios of the network, the model GUI of the one selected and the simulate form.",
      "Desc": "From top to bottom (Tags in parentheses):\n\n- The stale banner (simulate needs the equilibrium).\n- Scenarios: the list of net.a_Scenario (sim_list) with Add (sim_add, the form of\n  PowerNetwork.add_scenario in a dialog: `sc = net.add_scenario(...);`) and Remove\n  (sim_remove, `net.remove_scenario(\"<tag>\");` after a confirmation on a visible figure).\n  The scenario selected is shown below in its model GUI (sim_scenario_gui:\n  `net.a_Scenario{k}.launch_gui(<panel>, History=<history of the app>)`), which adds and\n  removes the events.\n- Simulation: a heading with Run (sim_run; simulate shows its own progress) and Analyze result\n  (sim_analyze: `res_ode.launch_gui(History=<history>, Variable=\"res_ode\")` in a new\n  window) on the same line, a status line (sim_status) and the form of\n  PowerNetwork.simulate (sim_form, DrawerOptionDialog with `s_scenario` set to the\n  scenario selected, outputs `[res_ode, flag_ode]`).\n\nThe diagram (tab_sim_diagram) shows the network at the equilibrium with the targets of\nthe scenario selected, before and after a run; the result is viewed in the Analyze result\nwindow. The state of the tab is in h_panel.UserData (widgets, the network and scenario\nshown, the model GUI, the form, the last result and the result opened); tab_sim_refresh\nupdates the list after every run of the history (f_changed), and tab_sim_action runs the\nbuttons and the list.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_sim_diagram",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "G",
        "h_parent",
        "h_panel",
        "sct_app"
      ],
      "OutputNames": [
        "G"
      ],
      "Arguments": [
        {
          "Name": "G",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram of the tab, or []."
        },
        {
          "Name": "h_parent",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Diagram panel of the tab."
        },
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab (UserData: the state, see tab_sim_build)."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
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
          "Description": "Diagram drawn ([] for a network without buses). <@Type> GraphNetDiagram"
        }
      ],
      "Signature": "G = tab_sim_diagram(G, h_parent, h_panel, sct_app)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_diagram.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Diagram of the time simulation tab: the network at the equilibrium with the targets of the scenario selected.",
      "Desc": "net.plot_diagram(State=\"auto\") (draw_network) with the targets of the scenario selected:\nthe buses and branches of tab_event (faults, openings), the tripped units and the units\nwith an offset or an input. A local controller marks its component; a global controller\nhas no element. A run does not change the drawing: the result is viewed in the Analyze\nresult window.\n\nA drawing error falls back to draw_network. Nothing is logged.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_sim_legend",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel"
      ],
      "OutputNames": [
        "s_legend"
      ],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab (UserData: the state)."
        }
      ],
      "Outputs": [
        {
          "Name": "s_legend",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One line for the info strip."
        }
      ],
      "Signature": "s_legend = tab_sim_legend(h_panel)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_legend.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Legend of the diagram of the time simulation tab: the targets of the scenario selected.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_sim_refresh",
      "Defining": "DrawerGUILDA",
      "Group": "tab",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_panel",
        "sct_app",
        "s_select"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "h_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panel of the tab (UserData: the state, see tab_sim_build)."
        },
        {
          "Name": "sct_app",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tab API (see tab_list)."
        },
        {
          "Name": "s_select",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "missing",
          "Required": false,
          "Unit": "",
          "Description": "Tag to select (the list selection); missing keeps the rule above."
        }
      ],
      "Outputs": [],
      "Signature": "tab_sim_refresh(h_panel, sct_app, s_select)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerGUILDA/private/tab_sim_refresh.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Update the time simulation tab from the history: the scenario list, the model GUI and form of the selection, the result.",
      "Desc": "The hook f_changed of the tab, also called on the build and when the list selection\nchanges (s_select). The selection is the scenario selected before (followed by object,\nso a renamed scenario stays selected), a scenario that has just been added (also from\nthe model tab or the log), or the first one. The model GUI is built again only when the\nscenario selected or the network changes, and the form of simulate when the selection\nor the list of tags changes (its s_scenario lists the tags); each is built in a new\ncontainer, so a model GUI still running an action draws nothing into the new one.\n\nA ResultODE in `res_ode` of the history, other than the last one seen, that appears\nduring a run of Run is the result of the scenario then selected (s_run_scenario): the\nstatus line names that scenario. The status line and Analyze result follow\n`res_ode` of the history: while the result of the last simulate is new (not opened from\nthe tab yet; analyze_highlight), Analyze result is the filled primary button, Run the\nplain one, and the status line ends with \"open Analyze result\".",
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
