(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["DrawerTagPicker"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "DrawerTagPicker",
  "properties": [],
  "methods": [
    {
      "Name": "pick",
      "Defining": "DrawerTagPicker",
      "Group": "Other",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_parent_figure",
        "tab",
        "opt"
      ],
      "OutputNames": [
        "sv_tag"
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
          "Description": "uifigure the window belongs to, or [] for none."
        },
        {
          "Name": "tab",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Rows to choose from, e.g. DrawerTagPicker.element_table(net, \"Bus\")."
        },
        {
          "Name": "Multiple",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Whether several rows can be chosen."
        },
        {
          "Name": "Selected",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "strings(1,0)",
          "Required": false,
          "Unit": "",
          "Description": "Values of Column chosen when the window opens."
        },
        {
          "Name": "Title",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"Select\"",
          "Required": false,
          "Unit": "",
          "Description": "Title of the window."
        },
        {
          "Name": "Column",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"Tag\"",
          "Required": false,
          "Unit": "",
          "Description": "Column whose values are returned (\"Key\" for a key table)."
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
          "Description": "Values of Column of the chosen rows, in the order of tab; strings(1,0) on cancel."
        }
      ],
      "Signature": "sv_tag = DrawerTagPicker.pick(h_parent_figure, tab, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/pick.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:DrawerTagPicker:NoColumn"
      ],
      "Summary": "Show a table in a modal picker window with a search box and return the values chosen; strings(1,0) on cancel.",
      "Desc": "The window shows tab in a uitable, one row per element, under a search box that filters\nthe rows as the user types (every word, case-insensitive, over all the columns). Select\n(Tag \"picker_ok\") returns the values of the column Column of the chosen rows, in the order\nof tab; Cancel (Tag \"picker_cancel\") or closing the window returns strings(1,0). In single mode a double\nclick on a row chooses it at once. With Multiple=true the rows chosen stay chosen while the\nsearch hides them. Selected preselects the rows whose Column value is in it (values that\nare not in the table are ignored).\n\nOne hidden window is kept per parent figure (one more for no parent) and reused: a call\nonly swaps the data, title and mode, so the second opening is fast. The window is created\nagain when it was deleted, and is deleted with its parent figure.\n\nA visible window waits for the user (uiwait). A hidden window (hidden parent) or one in\n`matlab -batch` has no user: it waits at most 10 s for a program (a test) to press its\nbuttons and then returns strings(1,0) as a cancel, so it never blocks indefinitely.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE68bus();\nfig = uifigure();\nsv_tag = DrawerTagPicker.pick(fig, DrawerTagPicker.element_table(net, \"Component\"), Title=\"Component\")\nsv_tag = DrawerTagPicker.pick(fig, DrawerTagPicker.element_table(net, \"Bus\"), Multiple=true, Selected=\"B001\")\ns_key = DrawerTagPicker.pick(fig, DrawerTagPicker.key_table(\"Component\"), Column=\"Key\")\n```\n\nSee also DrawerTagPicker.element_table, DrawerTagPicker.key_table, DrawerOptionDialog.ask",
      "Deprecated": ""
    },
    {
      "Name": "key_table",
      "Defining": "DrawerTagPicker",
      "Group": "key",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "s_category"
      ],
      "OutputNames": [
        "tab"
      ],
      "Arguments": [
        {
          "Name": "s_category",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(s_category, [\"Component\",\"Branch\",\"LocalController\",\"GlobalController\"])"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Model category of GUILDA.keymap."
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
          "Description": "One row per key: Key, Class, Description (strings)."
        }
      ],
      "Signature": "tab = DrawerTagPicker.key_table(s_category)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/key_table.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return one row per model key of a category: the key, its class and the first help line of the class.",
      "Desc": "The rows are the keys of GUILDA.keymap(s_category), sorted by Key. Description is the\nfirst comment line of the class file (its H1 line). The table is kept for the MATLAB\nsession, because reading the class files is slow; it is rebuilt when the classes of the\nkey map change (after GUILDA.update_keymap finds a new model class).",
      "SeeAlso": [],
      "Examples": "```matlab\ntab = DrawerTagPicker.key_table(\"Component\")      % Key, Class, Description\ns_key = DrawerTagPicker.pick(fig, tab, Column=\"Key\", Title=\"Component type\");\n```\n\nSee also DrawerTagPicker.pick, GUILDA.keymap",
      "Deprecated": ""
    },
    {
      "Name": "element_table",
      "Defining": "DrawerTagPicker",
      "Group": "element",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "net",
        "s_kind"
      ],
      "OutputNames": [
        "tab"
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
          "Description": "Network whose elements are listed."
        },
        {
          "Name": "s_kind",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(s_kind, [\"Bus\",\"Branch\",\"Component\",\"LocalController\",\"GlobalController\",\"Scenario\"])"
          ],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Kind of the elements."
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
          "Description": "One row per element; the columns of the kind (see DrawerTagPicker)."
        }
      ],
      "Signature": "tab = DrawerTagPicker.element_table(net, s_kind)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/element_table.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return one row per element of one kind of the network, with the columns that tell them apart.",
      "Desc": "The table is read in a single pass over the layers of the network (handles only: no\nstruct(net, false), no copies). The columns by kind are listed in the help of\nDrawerTagPicker; for example, a component row gives its bus, the index of that bus, its\nposition among the components of the bus, its class and its model key.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE68bus();\ntab = DrawerTagPicker.element_table(net, \"Component\");\ntab(tab.Bus == \"B001\", :)       % the components of B001 in the order of the bus\ntab = DrawerTagPicker.element_table(net, \"LocalController\");\ntab(tab.Role == \"pss\", [\"Tag\", \"Component\", \"Parent\"])\n```\n\nSee also DrawerTagPicker.pick, DrawerTagPicker.key_table",
      "Deprecated": ""
    },
    {
      "Name": "DrawerTagPicker",
      "Defining": "DrawerTagPicker",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [],
      "Outputs": [],
      "Signature": "obj = DrawerTagPicker()",
      "File": "",
      "Line": 0,
      "ImplementedIn": "",
      "Overrides": "",
      "Throws": [],
      "Summary": "",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "picker_event",
      "Defining": "DrawerTagPicker",
      "Group": "picker",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_fig",
        "s_event",
        "value"
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
          "Description": "Figure of the picker."
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
          "Description": "\"search\", \"select\", \"double\", \"ok\" or \"cancel\"."
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
          "Description": "search: the text typed; select: Selection of the uitable (rows shown); double: the row double-clicked; else []."
        }
      ],
      "Outputs": [],
      "Signature": "picker_event(h_fig, s_event, value)",
      "File": "_GUILDAsystem/_auxiliary/@DrawerTagPicker/private/picker_event.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Handle an event of the picker window of DrawerTagPicker.pick: search, selection, double click, choose or cancel.",
      "Desc": "The state of the call is the appdata \"sct_state\" of the window: the table, the text\nsearched per row, the values returned, the rows chosen (lv_selected, over all rows), the\nrows shown (iv_shown), whether the window is open for the user (l_open: pick sets it once\nthe window is filled, and other events are ignored before) and, once answered, l_done and\nsv_result. The selection of the uitable\nis over the rows shown; lv_selected keeps the rows chosen that the search hides. The\ncomponents are those of the appdata \"sct_handle\" (kept by pick when it made the window).",
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
