(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["DrawerModelGUI"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "DrawerModelGUI",
  "properties": [
    {
      "Name": "a_target",
      "Defining": "DrawerModelGUI",
      "Group": "Display",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
      "Line": 70,
      "Summary": "Model shown.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "LayerPackage",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_container",
      "Defining": "DrawerModelGUI",
      "Group": "Display",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
      "Line": 71,
      "Summary": "Container the GUI fills (uifigure, uipanel, uitab or uigridlayout).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.container",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "history",
      "Defining": "DrawerModelGUI",
      "Group": "Display",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
      "Line": 72,
      "Summary": "Log that runs and records the actions of the GUI as code.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "HistoryGUILDA",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_model",
      "Defining": "DrawerModelGUI",
      "Group": "Model access",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
      "Line": 75,
      "Summary": "Reads the parent, children and pages of a model: @(o) struct(\"parent\", \"children\", \"pages\").",
      "Desc": "",
      "SeeAlso": [],
      "Type": "function_handle",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_root",
      "Defining": "DrawerModelGUI",
      "Group": "Model access",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
      "Line": 76,
      "Summary": "Variable of the history that holds the root model, e.g. \"net\".",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "m_cache",
      "Defining": "DrawerModelGUI",
      "Group": "Model access",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
      "Line": 77,
      "Summary": "Child tables kept between renders of the same model and element tables kept until the next run (update_navigation).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "containers.Map",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "m_ui",
      "Defining": "DrawerModelGUI",
      "Group": "Model access",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
      "Line": 78,
      "Summary": "Components kept between renders, by name (build_frame); empty before the first render.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "containers.Map",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "render",
      "Defining": "DrawerModelGUI",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "a_target"
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
          "Name": "a_target",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "LayerPackage",
          "Validators": [],
          "Default": "obj.a_target",
          "Required": false,
          "Unit": "",
          "Description": "Model to show (default: the one shown)."
        }
      ],
      "Outputs": [],
      "Signature": "render(obj, a_target)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/render.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Show a model: write the GUI of a_target into the components drawn in the container.",
      "Desc": "An app that embeds the GUI calls it to switch the model; the breadcrumb, the child tables\nand the actions call it too. A deleted model shows a message instead. When a_target is\nanother model than the one shown before, TargetChanged is notified after the drawing.\n\nThe components are built once (build_frame) and kept: a render writes the header texts\nand the child table into them, and writes a property only when its value changes, since\nevery write is sent to the figure. The add buttons of a kind of model and the child table\nare made on their first use and detached from the grid when not needed, to be attached\nagain by a later render. The Parameter tab and the pages are one uihtml (the body), whose\nData (body_data) is sent once per render, only when it changed; the tab of the same title\nstays selected.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nh = net.launch_gui();\nh.render(net.a_Bus{2});\n```",
      "Deprecated": ""
    },
    {
      "Name": "DrawerModelGUI",
      "Defining": "DrawerModelGUI",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "a_target",
        "h_container",
        "f_model",
        "history"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "a_target",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "LayerPackage",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Model to show (a PowerSystemModel or a Scenario)."
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
          "Description": "uifigure, uipanel, uitab or uigridlayout; [] opens a new uifigure."
        },
        {
          "Name": "f_model",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Reader of the parent, children and pages (made by LayerPackage.launch_gui)."
        },
        {
          "Name": "history",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "HistoryGUILDA",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Log that runs the actions; its root variable must be the root of a_target."
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
          "Description": "The GUI."
        }
      ],
      "Signature": "obj = DrawerModelGUI(a_target, h_container, f_model, history)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/DrawerModelGUI.m",
      "Line": 87,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [
        "GUILDA:DrawerModelGUI:OtherRoot",
        "GUILDA:DrawerModelGUI:NotUIContainer"
      ],
      "Summary": "Create the GUI of a model in a container (a new uifigure when empty).",
      "Desc": "The root model (the end of the parents) is the variable of the history named after\nits class (net, bus, branch, comp, con, gcon); it is set when the history has none.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "run_code",
      "Defining": "DrawerModelGUI",
      "Group": "run",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_label",
        "s_code",
        "opt"
      ],
      "OutputNames": [
        "l_ok"
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
          "Description": "The GUI."
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
          "Description": "Label of the entry of the history, also the title of the alert."
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
          "Description": "MATLAB code of the action."
        },
        {
          "Name": "Confirm",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Question asked before the run (\"\": none)."
        },
        {
          "Name": "Render",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Draw the GUI again after the run."
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
        }
      ],
      "Signature": "l_ok = run_code(obj, s_label, s_code, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/run_code.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Run the code of an action through the history, then draw the GUI again and notify ModelChanged.",
      "Desc": "With Confirm, a visible figure first asks the question (uiconfirm) and a cancel runs\nnothing; a hidden figure or `matlab -batch` has nobody to ask and runs the code. The\nGUI is drawn again after the run, also after a failed one (a failed run may have changed\npart of a handle model); Render=false leaves the redraw to the caller. A failed run shows\nits error in an alert (a warning on a hidden figure). ModelChanged is notified after a\nsuccessful run.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "model_expression",
      "Defining": "DrawerModelGUI",
      "Group": "model",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "a_model",
        "a_chain"
      ],
      "OutputNames": [
        "s_expr"
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
          "Description": "The GUI."
        },
        {
          "Name": "a_model",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Model in the tree of the root."
        },
        {
          "Name": "a_chain",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "cell",
          "Validators": [],
          "Default": "{}",
          "Required": false,
          "Unit": "",
          "Description": "Models from the root to a_model ({}: read through the parents)."
        }
      ],
      "Outputs": [
        {
          "Name": "s_expr",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Expression, e.g. \"net.a_Bus{3}\"."
        }
      ],
      "Signature": "s_expr = model_expression(obj, a_model, a_chain)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/model_expression.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:DrawerModelGUI:OtherRoot",
        "GUILDA:DrawerModelGUI:NotInTree"
      ],
      "Summary": "MATLAB expression of a model from the root variable of the history, e.g. \"net.a_Bus{3}.a_Component{1}\".",
      "Desc": "Each step from the root is the list of the parent that holds the model (a_Bus, a_Branch,\na_GlobalController, a_Scenario, a_Component or a_LocalController) and its index there.\nA model whose root is not the root variable of the history has no expression (an error).\nThe models from the root to a_model (a_chain, as render finds them) save reading the\nparents again.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "body_data",
      "Defining": "DrawerModelGUI",
      "Group": "body",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "a_target",
        "sct_page",
        "s_expr",
        "s_selected"
      ],
      "OutputNames": [
        "sct_data"
      ],
      "Arguments": [
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
          "Description": "Model shown."
        },
        {
          "Name": "sct_page",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Pages of gui_content: fields s_title, s_type and content."
        },
        {
          "Name": "s_expr",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Expression of the model shown (\"\": not editable, a model outside the tree of the history)."
        },
        {
          "Name": "s_selected",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Title of the tab chosen before (\"\": the first tab)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_data",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Data of the uihtml."
        }
      ],
      "Signature": "sct_data = body_data(a_target, sct_page, s_expr, s_selected)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/body_data.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Data of the body of the model GUI (model_body.html): the Parameter tab and the pages of gui_content.",
      "Desc": "The body is one uihtml (Tag \"body\"), so that a render sends all its tables in one message\ninstead of writing each uitable (a uitable write costs the figure 40-60 ms). Fields:\n\n- tabs (cell): one struct per tab with title and type:\n  - \"parameter\" (a model with a_Parameter, not a Scenario): message (the note on the Docs)\n    and panels, one per container of a_Parameter, in its order: tag, index (in\n    a_Parameter), vertical, editable and table. A container of one row whose parameters\n    are all scalars (numeric, logical or string) is vertical: one row per parameter with\n    its full name and the column Value; two such panels stand side by side. Any other\n    container has one column per parameter.\n  - \"table\" (a page of gui_content): table, and events (true for an event table of a\n    Scenario in the tree of the history, whose rows can be removed).\n  - any other type: message \"Unknown page type: ...\".\n- table: cols, kinds (per column: number, logical, text, or fixed for a value that is not\n  edited in a cell), rows (a cell of rows, each a cell of texts, or logicals for the\n  logical cells), rownames, and rowkinds (the kind of each row of a vertical table).\n- selected: the title of the tab shown (s_selected when the model has it, else the first).\n- color: the colors of tools.gui_palette as \"#RRGGBB\".\n\nNumbers are written with 6 significant digits (complex as a+bi, several columns as a\nrow vector); a NaN is \"NaN\".",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_frame",
      "Defining": "DrawerModelGUI",
      "Group": "build",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_container",
        "m_ui"
      ],
      "OutputNames": [],
      "Arguments": [
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
          "Description": "Container of the GUI."
        },
        {
          "Name": "m_ui",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Components kept between renders (the drawer's, emptied here). <@Type> containers.Map"
        }
      ],
      "Outputs": [],
      "Signature": "build_frame(h_container, m_ui)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/build_frame.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Build the components that every render keeps: the grid, the header, the left column with the child table, and the body.",
      "Desc": "The grid drawn before in the container is removed first (clear_gui); a uigridlayout\ncontainer keeps its cell for the new grid. The handles go into m_ui by name:\n\n- grid: the grid of the GUI (Tag \"DrawerModelGUI\"), header on top, left column and body below.\n- crumb, crumb_links, crumb_last: the breadcrumb grid, its links with their \"›\" ([link, sep]\n  per row, made by update_header as needed) and the label of the model shown.\n- tag, class, docs, stale: the second row of the header.\n- left: the left column (add buttons over the child table); add:<key> the grid of the add\n  buttons of one kind of model (made by render as needed).\n- nav, kind, search, menu, open, remove: the drop-down, the search field, the context menu\n  of the child tables and its items (Remove and the callbacks are made by\n  update_navigation); child_tables, children: the tables of the children, one per set of\n  columns, and the one shown (made by update_navigation).\n- body: the uihtml of the Parameter tab and the pages (model_body.html; render writes its\n  Data, body_data).\n- spare: every part that a render may detach from the grid and attach again, removed with\n  the grid by clear_gui.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "clear_gui",
      "Defining": "DrawerModelGUI",
      "Group": "clear",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_container",
        "m_ui"
      ],
      "OutputNames": [
        "h_layout"
      ],
      "Arguments": [
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
          "Description": "Container of the GUI."
        },
        {
          "Name": "m_ui",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Components kept between renders (build_frame). <@Type> containers.Map"
        }
      ],
      "Outputs": [
        {
          "Name": "h_layout",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Layout of the grid removed in a uigridlayout container ([] when there is none)."
        }
      ],
      "Signature": "h_layout = clear_gui(h_container, m_ui)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/clear_gui.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Remove the GUI drawn in the container: its grid, the parts kept aside for later renders and their context menus.",
      "Desc": "Only the grid of the GUI (Tag \"DrawerModelGUI\") is removed: an app may keep other\ncomponents in the container. The context menus of the tables belong to the figure, so\nthey are removed separately. m_ui is emptied.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "edit_parameter",
      "Defining": "DrawerModelGUI",
      "Group": "edit",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_body",
        "sct_edit",
        "a_target",
        "h_stale",
        "s_expr",
        "f_run"
      ],
      "OutputNames": [
        "l_restore"
      ],
      "Arguments": [
        {
          "Name": "h_body",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "uihtml of the body (for the alert)."
        },
        {
          "Name": "sct_edit",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Edit sent by the page: fields index, var, row and value."
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
          "Description": "Model shown."
        },
        {
          "Name": "h_stale",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Label of the stale state."
        },
        {
          "Name": "s_expr",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Expression of the model shown."
        },
        {
          "Name": "f_run",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "run_code of the GUI."
        }
      ],
      "Outputs": [
        {
          "Name": "l_restore",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True when the body must show the stored values again (an error)."
        }
      ],
      "Signature": "l_restore = edit_parameter(h_body, sct_edit, a_target, h_stale, s_expr, f_run)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/edit_parameter.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:DrawerModelGUI:NotANumber"
      ],
      "Summary": "Write an edited cell of the Parameter tab as code through the history; restore the body on an error.",
      "Desc": "The cell (sct_edit from model_body.html: index of the container in a_Parameter, var,\nrow and value, a text or a logical) is put into a copy of the table of the container:\na number column takes the text as a number (several numbers for a row vector, \"NaN\" for\nNaN), a logical column true or false, a string column the text. Each changed variable is\none line on tab_parameter of the model, e.g. `net.a_Bus{1}.tab_parameter.powerflow.V = 1.02;`\n(a row index `(2)` in a table of several rows). Parameter.set.tab_parameter checks, logs\nand marks what is stale. On an error, or a text that is not a value of the column, an\nalert shows the message and l_restore asks the caller to send the stored values again.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_changed",
      "Defining": "DrawerModelGUI",
      "Group": "set",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h",
        "varargin"
      ],
      "OutputNames": [],
      "Arguments": [
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
          "Description": "Component."
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
          "Description": "Property name, then its value."
        }
      ],
      "Outputs": [],
      "Signature": "set_changed(h, varargin)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/set_changed.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Set the properties of a component whose values differ from the ones given (name-value pairs).",
      "Desc": "Every set property of a UI component is sent to the figure, also with the same value;\nwriting only the changed ones keeps a render that changes little cheap. Text-like values\n(char, string, on/off) are compared as strings.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "show_alert",
      "Defining": "DrawerModelGUI",
      "Group": "show",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h",
        "s_message",
        "s_title"
      ],
      "OutputNames": [],
      "Arguments": [
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
          "Description": "Component of the figure."
        },
        {
          "Name": "s_message",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Message."
        },
        {
          "Name": "s_title",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Title of the alert."
        }
      ],
      "Outputs": [],
      "Signature": "show_alert(h, s_message, s_title)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/show_alert.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Show an error message in an alert of the figure of h; a hidden figure gets a warning instead.",
      "Desc": "uialert needs a visible figure (it errors on a hidden one, e.g. in tests).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "update_header",
      "Defining": "DrawerModelGUI",
      "Group": "update",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "m_ui",
        "drawer",
        "a_chain"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "m_ui",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Components of the GUI (build_frame). <@Type> containers.Map"
        },
        {
          "Name": "drawer",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "DrawerModelGUI that renders a model of the breadcrumb."
        },
        {
          "Name": "a_chain",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Models from the root to the one shown. <@Type> cell"
        }
      ],
      "Outputs": [],
      "Signature": "update_header(m_ui, drawer, a_chain)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/update_header.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Write the header of the model shown: breadcrumb, then tag, class, Docs button and stale state.",
      "Desc": "- Breadcrumb (Tag \"breadcrumb\"): the models from the root to the one shown, joined by \"›\".\n  Each of them but the last is a link that renders its model. The links are kept between\n  renders; the ones not needed are hidden in columns of width 0, without the Tag.\n- Docs (Tag \"docs\"): opens the reference page of the class, GUILDA.doc(\"class\", class).\n- Stale state (Tag \"stale\"): see update_stale.\nA property is written only when its value changes, which spares the drawing of the figure.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "update_navigation",
      "Defining": "DrawerModelGUI",
      "Group": "update",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "m_ui",
        "drawer",
        "a_children",
        "s_expr",
        "s_owner",
        "f_run",
        "m_cache"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "m_ui",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Components of the GUI (build_frame). <@Type> containers.Map"
        },
        {
          "Name": "drawer",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "DrawerModelGUI that renders the clicked model."
        },
        {
          "Name": "a_children",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Children of the model shown, without Parameter containers (not empty). <@Type> cell"
        },
        {
          "Name": "s_expr",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Expression of the model shown, e.g. \"net.a_Bus{1}\" (\"\": outside the tree of the history, without actions). <@Type> string"
        },
        {
          "Name": "s_owner",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Expression of the component that holds a local controller shown (\"\" for none). <@Type> string"
        },
        {
          "Name": "f_run",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "run_code of the GUI: @(s_label, s_code, Name, Value). <@Type> function_handle"
        },
        {
          "Name": "m_cache",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Cache of the tables (the drawer's, a containers.Map). <@Type> containers.Map"
        }
      ],
      "Outputs": [],
      "Signature": "update_navigation(m_ui, drawer, a_children, s_expr, s_owner, f_run, m_cache)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/update_navigation.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Child table: the children of the model, one kind at a time, in a compact searchable table.",
      "Desc": "The kinds come in the order Bus, Branch, Component, LocalController, GlobalController,\nScenario (then any other model), without the Parameter containers. A drop-down (Tag\n\"kind\") chooses the kind (\"Bus (14)\"), a search field (Tag \"search\") keeps the rows whose\ntext contains it (any column, ignoring case), and the table (Tag \"children\") lists the\nchildren of that kind, one row each. A click on a row renders that child. The context menu\nof a row has \"Open in new window\" (a new uifigure with the same history) and \"Remove\",\nwhich runs the remove_* method of the parent (of the component for a local controller)\nafter a confirmation. The components are made once (build_frame); a render writes their\nitems, data and callbacks.\n\nThe columns come from DrawerTagPicker.element_table of the network (the root variable of\nthe history): Bus Tag, Type, Components; Branch Tag, From, To, Class; Component Tag,\nClass, Key; LocalController Tag, Role, Class; GlobalController Tag, Class, Units; Scenario\nTag, Time, Description. Its rows are matched to the children by tag (local controllers\nwithin the rows of the component shown and of the controller shown as their Parent, since\ntheir tags are unique among siblings only); a model outside a network, or rows that do\nnot match, get the columns Tag and Class instead.\n\nm_cache keeps:\n- the element table of each kind (\"element_<kind>\") until the history has a new entry or\n  the network changes, so that the children of every bus or component come from one table;\n- the table of each kind of the model shown (\"table_<kind>\", built when the kind is first\n  shown) and the kind chosen and the search text, for the next render of the same model\n  without a run in between (e.g. the app showing its model tab again).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "update_stale",
      "Defining": "DrawerModelGUI",
      "Group": "update",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_stale",
        "a_target"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "h_stale",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Label of the stale state."
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
          "Description": "Model shown."
        }
      ],
      "Outputs": [],
      "Signature": "update_stale(h_stale, a_target)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerModelGUI/private/update_stale.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Write the stale state of the model into the label: each stale tag with its first message.",
      "Desc": "A stale model is shown in the warning colors; \"Stale: none\" in the note color of the header.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    }
  ],
  "events": [
    "ModelChanged",
    "TargetChanged"
  ],
  "enumeration": [],
  "validation": {
    "Warnings": [],
    "Errors": []
  }
};
})(window);
