(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["DrawerOptionDialog"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "DrawerOptionDialog",
  "properties": [
    {
      "Name": "s_signature",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 98,
      "Summary": "Method, e.g. \"Bus.add_component\".",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_object",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 99,
      "Summary": "Object expression of the call, e.g. \"net.a_Bus{3}\".",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_output",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 100,
      "Summary": "Output variables of the call (\"\" for none).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_field",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 101,
      "Summary": "One element per field: input, widget, default, display, group, row and handles (see build_form).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_group",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 102,
      "Summary": "One element per group: name, header button, open, fields.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "c_visible",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 103,
      "Summary": "Conditions of gui_forms.json \"visible\": struct of names and when.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "cell",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_grid",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 104,
      "Summary": "Grid of the form.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.container.GridLayout",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_message",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 105,
      "Summary": "Label of the message of an invalid value.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.control.Label",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_object",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 106,
      "Summary": "Object of the call, or [] without History.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_network",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 107,
      "Summary": "Network the pickers list the elements of, or [].",
      "Desc": "",
      "SeeAlso": [],
      "Type": "PowerNetwork",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_history",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 108,
      "Summary": "HistoryGUILDA of the call, or [], to read the variable in an expression field that other fields refer to.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_resize",
      "Defining": "DrawerOptionDialog",
      "Group": "Form",
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
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 109,
      "Summary": "Called with the height of the form after it changes (set by ask), or [].",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "get_code",
      "Defining": "DrawerOptionDialog",
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
        "s_code"
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
          "Description": "The form."
        }
      ],
      "Outputs": [
        {
          "Name": "s_code",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "One line of MATLAB code, or \"\" while a value is invalid."
        }
      ],
      "Signature": "s_code = get_code(obj)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/get_code.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Code of the call for the current values of the form; \"\" while a value is invalid.",
      "Desc": "The code is `<outputs> = <Object>.<method>(<required inputs>, Name=Value, ...);` with the\nrequired inputs in order and only the visible options whose value differs from the default\n(or the GUILDA.config setting for the analysis methods). Tags are written as `\"B001\"` (one)\nor `[\"B001\", \"B002\"]` (several). \"auto\" (or the word of gui_forms.json for NaN) and \"none\"\nin a number field are written as the number they stand for (NaN, Inf or -Inf). An optional positional input is written when it\nor a later one is changed. The fields of a group that was never opened keep their default.\nA field changed from its default is highlighted and shows its reset button. When a value is\ninvalid (not a number, an unknown tag, or a required input left empty), the form shows the\nmessage, the field is highlighted and \"\" is returned; nothing is thrown, so the fields call\nit on every change.",
      "SeeAlso": [],
      "Examples": "```matlab\ns_code = dlg.get_code()   % e.g. comp = net.a_Bus{3}.add_component(\"gen-park\", P=0.5);\n```",
      "Deprecated": ""
    },
    {
      "Name": "DrawerOptionDialog",
      "Defining": "DrawerOptionDialog",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "s_signature",
        "h_container",
        "opt"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "s_signature",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Method in functionSignatures.json, e.g. \"Bus.add_component\"."
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
        },
        {
          "Name": "Object",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Object expression of the call, e.g. \"net.a_Bus{3}\"."
        },
        {
          "Name": "Output",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Output variables of the call, e.g. \"res_pf\" (\"\" for none)."
        },
        {
          "Name": "Exclude",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "string.empty",
          "Required": false,
          "Unit": "",
          "Description": "Inputs left out of the form, e.g. \"Parent\"."
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
          "Description": "Log whose workspace holds the root variable of Object, to evaluate the choices and defaults on the object."
        },
        {
          "Name": "Value",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Initial values by input name, as MATLAB code text, e.g. struct(\"s_scenario\", \"\"\"case1\"\"\")."
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
          "Description": "The form."
        }
      ],
      "Signature": "obj = DrawerOptionDialog(s_signature, h_container, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/DrawerOptionDialog.m",
      "Line": 113,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [
        "GUILDA:DrawerOptionDialog:NoObject",
        "GUILDA:DrawerOptionDialog:NotUIContainer"
      ],
      "Summary": "Create the option form of a method in a container of a uifigure.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "form_event",
      "Defining": "DrawerOptionDialog",
      "Group": "form",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_event",
        "k"
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
          "Description": "The form."
        },
        {
          "Name": "s_event",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "\"change\", \"reset\", \"select\" or \"toggle\"."
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
          "Description": "Index of the field (of the group for \"toggle\"; 0 for none)."
        }
      ],
      "Outputs": [],
      "Signature": "form_event(obj, s_event, k)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/form_event.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Handle an event of the form: a changed field, a reset, a Select... button or a group header.",
      "Desc": "- \"change\": a field changed (k = 0 when the form is drawn).\n- \"reset\": field k goes back to its default.\n- \"select\": field k opens DrawerTagPicker.pick with the table of its elements or keys, built\n  now from the network of the call, and takes the tags chosen (nothing on cancel).\n- \"toggle\": group k opens or closes; its fields are drawn when it opens first.\n\nA change, reset or selection of field k first evaluates again the choices and defaults of\nthe fields that refer to it (refresh_depend: e.g. the input names of the unit of\nScenario.add_input, or the Time of add_scenario from its From). Every event then applies the conditions of gui_forms.json \"visible\" (a hidden field is left\nout of the call), lays out the rows (the shown fields in order; the hidden ones and the\nfields of a closed group in one row of height 0), calls get_code (highlight, reset buttons and message) and passes the height\nof the form to f_resize (the dialog of ask).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "draw_field",
      "Defining": "DrawerOptionDialog",
      "Group": "draw",
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
          "Description": "The form."
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
          "Description": "Index of the field."
        }
      ],
      "Outputs": [],
      "Signature": "draw_field(obj, k)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/draw_field.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the row of one field: its label, its widget, and the Select... button or a hint (a default in words, the hint of gui_forms.json, or \"Select unit first\").",
      "Desc": "The label is the name (or the label of gui_forms.json) with the unit, e.g. \"P [pu]\", and a\nstar for a required input. The widget shows sct_field(k).shown and has the input name as\nits Tag. The reset button is drawn by get_code when the field is first changed.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_form",
      "Defining": "DrawerOptionDialog",
      "Group": "build",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "h_container",
        "sv_exclude",
        "history",
        "sct_value"
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
          "Description": "The form."
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
        },
        {
          "Name": "sv_exclude",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Inputs left out of the form."
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
          "Description": "HistoryGUILDA that holds the root variable of the Object expression, or []."
        },
        {
          "Name": "sct_value",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Initial values by input name, as MATLAB code text."
        }
      ],
      "Outputs": [],
      "Signature": "build_form(obj, h_container, sv_exclude, history, sct_value)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/build_form.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:DrawerOptionDialog:UnknownSignature",
        "GUILDA:DrawerOptionDialog:InvalidValue",
        "GUILDA:DrawerOptionDialog:UnknownValue"
      ],
      "Summary": "Read the signature and gui_forms.json, set up one field per input and draw the form.",
      "Desc": "With a history, the object of the call is evaluated in its workspace (the root variable of\nthe Object expression), and the choices and defaults are evaluated on it. The fields of\nsct_value (code text by input name) are shown instead of the defaults; the baseline of\nget_code stays the default. The rows are: the title, the required and positional inputs,\nthe main options, then a header row and the rows of each group. The fields of the main\noptions are drawn here; those of a group when it is opened first (draw_field).\n\nA field (sct_field) holds: name, kind (required, ordered, namevalue), widget (tags,\ntagtext, choice, flag, logical, number, string, expression), baseline (the default as a\nvalue of the widget), shown (the value shown first), s_base (the text of the default in a\ntext field), s_default, s_purpose, s_label, s_unit, s_hint (a default in words), items,\ns_pick (\"\", \"element\" or \"key\"), sv_kind (element kinds), s_category (key category),\nl_multiple, r_auto, s_auto (the word for r_auto), r_none, s_note (a hint of gui_forms.json), s_group, i_row, the handles (h, h_label, h_extra, h_reset),\nl_built, l_visible, l_shown and l_changed, and for choices or a default that refer to other\ninputs (refer_args, refresh_depend): s_choices and sv_default (the expressions with\narg.<name>), sv_depend (the inputs referred to) and s_wait (\"Select unit first\").",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "ask",
      "Defining": "DrawerOptionDialog",
      "Group": "Other",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_parent_figure",
        "s_signature",
        "opt"
      ],
      "OutputNames": [
        "s_code"
      ],
      "Arguments": [
        {
          "Name": "h_parent_figure",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "uifigure the dialog belongs to, or [] for none."
        },
        {
          "Name": "s_signature",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Method in functionSignatures.json, e.g. \"Bus.add_component\"."
        },
        {
          "Name": "Object",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Object expression of the call, e.g. \"net.a_Bus{3}\"."
        },
        {
          "Name": "Output",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Output variables of the call, e.g. \"res_pf\" (\"\" for none)."
        },
        {
          "Name": "Exclude",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "string.empty",
          "Required": false,
          "Unit": "",
          "Description": "Inputs left out of the form, e.g. \"Parent\"."
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
          "Description": "Log whose workspace holds the root variable of Object (see DrawerOptionDialog)."
        },
        {
          "Name": "Value",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Initial values by input name, as MATLAB code text (see DrawerOptionDialog)."
        }
      ],
      "Outputs": [
        {
          "Name": "s_code",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Code of the call, or \"\" when the dialog was canceled."
        }
      ],
      "Signature": "s_code = DrawerOptionDialog.ask(h_parent_figure, s_signature, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/ask.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Ask for the options of a method in a modal dialog and return the code of the call; \"\" on cancel.",
      "Desc": "The dialog has the form of DrawerOptionDialog and the buttons Run and Cancel (Tags\n\"dialog_run\" and \"dialog_cancel\"). Run returns the code of get_code; while a value is\ninvalid it only shows the message and the dialog stays open. Cancel or closing the window\nreturns \"\". The dialog is centered on the parent figure and is hidden when the parent is\nhidden. Its height follows the form (no blank space above the buttons), up to 640 px, and\ngrows when a group is opened; a longer form scrolls. The code is not run here: pass it to\nHistoryGUILDA.run.\n\nOne hidden dialog window is kept per parent figure (one more for no parent) and reused, as\nthe picker of DrawerTagPicker.pick does. It keeps the forms of its last calls (up to 8, by\nsignature, Object, Output and Exclude): a call with the same ones refreshes the form drawn\nbefore (values, defaults and choices on the object of now; the groups closed again) instead\nof drawing it again, so the second opening costs only the new values. A form whose fields\nneed other widgets now (e.g. other choices) is drawn again. Between calls the window is\nhidden and has no name; it is deleted with its parent.\n\nA visible dialog waits for the user, with no time limit, in uiwait steps of 1 s that read\nUserData again, so a button pressed before the wait (its uiresume came too early) is not lost;\nhiding the dialog while it waits ends it as a cancel. A hidden dialog (hidden parent) or one in\n`matlab -batch` has no user: it waits at most 10 s for a program (a test) to press its\nbuttons and then returns \"\" as a cancel, so it never blocks indefinitely.",
      "SeeAlso": [],
      "Examples": "```matlab\ns_code = DrawerOptionDialog.ask(fig, \"Bus.add_component\", Object=\"net.a_Bus{3}\", Output=\"comp\", History=h);\nif s_code ~= \"\"\n    h.run(\"Model\", \"Add a component\", s_code);\nend\n```",
      "Deprecated": ""
    },
    {
      "Name": "close_dialog",
      "Defining": "DrawerOptionDialog",
      "Group": "close",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_fig",
        "s_code"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "h_fig",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Figure of the dialog."
        },
        {
          "Name": "s_code",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Code of get_code (\"\" while invalid), or missing for a cancel."
        }
      ],
      "Outputs": [],
      "Signature": "close_dialog(h_fig, s_code)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/close_dialog.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "End the wait of DrawerOptionDialog.ask with the code of the call, or with \"\" for a cancel (missing).",
      "Desc": "An empty code means an invalid value: the form already shows why and the dialog stays open.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "code_strings",
      "Defining": "DrawerOptionDialog",
      "Group": "code",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sv_text"
      ],
      "OutputNames": [
        "s_code"
      ],
      "Arguments": [
        {
          "Name": "sv_text",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Strings."
        }
      ],
      "Outputs": [
        {
          "Name": "s_code",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Code text."
        }
      ],
      "Signature": "s_code = code_strings(sv_text)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/code_strings.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "MATLAB code of a string array: \"B001\" for one, [\"B001\", \"B002\"] for several, strings(1,0) for none.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "eval_depend",
      "Defining": "DrawerOptionDialog",
      "Group": "eval",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sv_expr",
        "sv_depend",
        "sct_field",
        "history",
        "a_object"
      ],
      "OutputNames": [
        "value",
        "l_ok",
        "s_wait"
      ],
      "Arguments": [
        {
          "Name": "sv_expr",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Alternatives of the expression, with `arg.<name>` for the inputs."
        },
        {
          "Name": "sv_depend",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Names of the inputs it refers to."
        },
        {
          "Name": "sct_field",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Fields of the form (sct_field of build_form; one not made yet counts as empty)."
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
          "Description": "HistoryGUILDA of the call, or []."
        },
        {
          "Name": "a_object",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Object of the call (obj in the expression), or []."
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
          "Description": "Value of the first alternative that evaluates ([] for none)."
        },
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
          "Description": "True when an alternative was evaluated."
        },
        {
          "Name": "s_wait",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "\"Select <label> first\" while it cannot be evaluated, else \"\"."
        }
      ],
      "Signature": "[value, l_ok, s_wait] = eval_depend(sv_expr, sv_depend, sct_field, history, a_object)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/eval_depend.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Value of a choices or default expression that refers to other inputs of the method, for their current values.",
      "Desc": "The expression names each input it refers to as `arg.<name>` (build_form writes it so).\nThe current value of each such field is read from its widget (or the value shown first\nwhile it is not drawn): the selected tag or tags, the text of a string field, the number of\na number field (\"auto\" and \"none\" as the numbers they stand for), and for an expression\nfield the default when its text is the default, else a variable of the history followed\nonly by properties and numeric indices (`sc`, `net.a_Scenario{2}`); nothing else is\nevaluated, so no method runs. The alternatives in sv_expr (`From.Time`, `[0, 10]`) are\ntried in order and the first that evaluates gives the value. While a field it refers to is\nempty or cannot be read, nothing is evaluated and s_wait asks for that field.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "eval_text",
      "Defining": "DrawerOptionDialog",
      "Group": "eval",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "s_expr",
        "obj",
        "arg"
      ],
      "OutputNames": [
        "value",
        "l_ok"
      ],
      "Arguments": [
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
          "Description": "Expression (string, possibly empty)."
        },
        {
          "Name": "obj",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Object the expression may use as obj ([]: none)."
        },
        {
          "Name": "arg",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Values of other inputs by name, used as arg.<name>."
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
          "Description": "Value of the expression ([] when it cannot be evaluated)."
        },
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
          "Description": "True when the expression was evaluated."
        }
      ],
      "Signature": "[value, l_ok] = eval_text(s_expr, obj, arg)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/eval_text.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Value of an expression of functionSignatures.json (a default or a choices list), if it can be evaluated here.",
      "Desc": "The expression is evaluated in this function, whose only variables for it are obj and arg\n(the values of other inputs of the method, `arg.unit`, see eval_depend): an expression on\nanother variable, or on obj when it is not given, fails and gives l_ok = false.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "field_baseline",
      "Defining": "DrawerOptionDialog",
      "Group": "field",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct",
        "default",
        "l_default"
      ],
      "OutputNames": [
        "sct"
      ],
      "Arguments": [
        {
          "Name": "sct",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The field (sct_field of build_form): widget, items, kind, s_default, r_auto, r_none, s_auto."
        },
        {
          "Name": "default",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Value of the default."
        },
        {
          "Name": "l_default",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True when the default was evaluated."
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
          "Description": "The field with baseline, s_base (and items, s_hint) set."
        }
      ],
      "Signature": "sct = field_baseline(sct, default, l_default)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/field_baseline.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "The default of a field as a value of its widget (baseline) and as the text of a text field (s_base).",
      "Desc": "build_form calls it for every field; form_event again for a number, string or expression\nfield whose default refers to another input (`Default: From.Time, else [0, 10]`) when that\ninput changes. A choice field without a default listed in its items gets \"\" as its first\nitem (which leaves the option out), except a required input, which takes its first item.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "hint_text",
      "Defining": "DrawerOptionDialog",
      "Group": "hint",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct"
      ],
      "OutputNames": [
        "s_text"
      ],
      "Arguments": [
        {
          "Name": "sct",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "The field (sct_field of build_form)."
        }
      ],
      "Outputs": [
        {
          "Name": "s_text",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Text of the hint label."
        }
      ],
      "Signature": "s_text = hint_text(sct)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/hint_text.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Text of the muted hint beside a field: a request for the input its choices need, the default in words, or the hint of gui_forms.json.",
      "Desc": "\"Select unit first\" while the choices of the field wait for another input (s_wait); else\n\"default: <words>\" for a default in words, shortened (\"from GUILDA.setting\" for a setting,\nthe value of \"true (calculate_optimal_powerflow)\", at most 24 characters); else the hint of\ngui_forms.json \"labels\"; else \"\".",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "number_text",
      "Defining": "DrawerOptionDialog",
      "Group": "number",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "value",
        "r_auto",
        "r_none",
        "s_auto"
      ],
      "OutputNames": [
        "s_text"
      ],
      "Arguments": [
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
          "Description": "Number or numeric array (double, or [] for none)."
        },
        {
          "Name": "r_auto",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Value shown as \"auto\" (NaN), or [] when the field has none."
        },
        {
          "Name": "r_none",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Value shown as \"none\" (NaN, Inf or -Inf), or [] when the field has none."
        },
        {
          "Name": "s_auto",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Word shown for r_auto, e.g. \"auto\"."
        }
      ],
      "Outputs": [
        {
          "Name": "s_text",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Text of the field."
        }
      ],
      "Signature": "s_text = number_text(value, r_auto, r_none, s_auto)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/number_text.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Text of a number field for a value: \"auto\" (or s_auto) or \"none\" for the special values of the field, else mat2str.",
      "Desc": "A value equal to r_auto (NaN where NaN means automatic), or a vector of only NaN such as\nColorLimits [NaN NaN], is s_auto (\"auto\", or the word of gui_forms.json \"labels\" for NaN,\ne.g. \"bus\"), one equal to r_none\n(NaN, Inf or -Inf where it means no limit) is \"none\"; [] is \"\". get_code reads the words back.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "parse_tags",
      "Defining": "DrawerOptionDialog",
      "Group": "parse",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "s_text"
      ],
      "OutputNames": [
        "sv_tag"
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
          "Description": "Text of the field, e.g. \"B001, B002\" or [\"B001\", \"B002\"]."
        }
      ],
      "Outputs": [
        {
          "Name": "sv_tag",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tags in the order typed (strings(1,0) for none)."
        }
      ],
      "Signature": "sv_tag = parse_tags(s_text)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/parse_tags.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Tags typed in a tag field: separated by commas, semicolons, spaces or |, quotes and brackets ignored.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "refresh_depend",
      "Defining": "DrawerOptionDialog",
      "Group": "refresh",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct_field",
        "sv_changed",
        "history",
        "a_object"
      ],
      "OutputNames": [
        "sct_field"
      ],
      "Arguments": [
        {
          "Name": "sct_field",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Fields of the form (sct_field of build_form)."
        },
        {
          "Name": "sv_changed",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Names of the inputs changed."
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
          "Description": "HistoryGUILDA of the call, or []."
        },
        {
          "Name": "a_object",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Object of the call, or []."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_field",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The fields with their items, defaults, values and hints updated."
        }
      ],
      "Signature": "sct_field = refresh_depend(sct_field, sv_changed, history, a_object)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/refresh_depend.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Evaluate again the choices and defaults of the fields that refer to the inputs changed, and of the fields that refer to those.",
      "Desc": "A dropdown or list takes the new items and keeps the values still among them (a dropdown\nelse takes its first item); while an input it refers to is empty, it has no items and its\nhint says \"Select <label> first\". A number, string or expression field whose default refers\nto another input (`From.Time, else [0, 10]`) takes the new default, and shows it while the\nfield still shows the old one; when no alternative evaluates, the field is empty with the\ndefault in words as its hint. Only these fields are evaluated, so a change of another field\ncosts nothing. A field not drawn yet takes the new value as the value it shows first.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "tags_text",
      "Defining": "DrawerOptionDialog",
      "Group": "tags",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sv_tag"
      ],
      "OutputNames": [
        "s_text"
      ],
      "Arguments": [
        {
          "Name": "sv_tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags."
        }
      ],
      "Outputs": [
        {
          "Name": "s_text",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tags separated by \", \"."
        }
      ],
      "Signature": "s_text = tags_text(sv_tag)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerOptionDialog/private/tags_text.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Text of a tag field for tags: \"B001, B002\" (\"\" for none).",
      "Desc": "",
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
