const classData = {
  "ClassName": "PowerSystemModel",
  "properties": [
    {
      "Name": "tab_parameter",
      "Defining": "LayerPackage",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": true,
      "Constant": false,
      "Abstract": true,
      "Hidden": false,
      "Desc": "manage parameter related to any analyis.",
      "Role": "Parameter",
      "Type": "Parameter",
      "Size": "1x1"
    },
    {
      "Name": "parent",
      "Defining": "LayerPackage",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": true,
      "Constant": false,
      "Abstract": true,
      "Hidden": false,
      "Desc": "manage hierarchical structure of layers.",
      "Role": "Layer Structure",
      "Type": "LayerPackage",
      "Size": "1x1"
    },
    {
      "Name": "children",
      "Defining": "LayerPackage",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": true,
      "Constant": false,
      "Abstract": true,
      "Hidden": false,
      "Desc": "manage hierarchical structure of layers.",
      "Role": "Layer Structure",
      "Type": "LayerPackage cell array",
      "Size": "Nx1"
    },
    {
      "Name": "str_editFlag",
      "Defining": "LayerPackage",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Flag to indicate if the layer has been edited.",
      "Role": "Edit Log",
      "Type": "string",
      "Size": "1x1"
    },
    {
      "Name": "tab_editLog",
      "Defining": "LayerPackage",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Log of edits made to the layer, including timestamp, ID, log message, tag, and before/after states.",
      "Role": "Edit Log",
      "Type": "table",
      "Size": "Nx6"
    },
    {
      "Name": "l_managedTag",
      "Defining": "LayerPackage",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Flag to indicate if the layer is managed by the tag system.",
      "Role": "Tag",
      "Type": "logical",
      "Size": "1x1"
    },
    {
      "Name": "str_tag",
      "Defining": "LayerPackage",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "User-defined tag for the layer, used for identification and management within the layer structure.",
      "Role": "Tag",
      "Type": "string",
      "Size": "1x1"
    }
  ],
  "methods": [
    {
      "Name": "PowerSystemModel",
      "Defining": "PowerSystemModel",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "The PowerSystemModel class serves as a base class for classes that constitute the power system model.\nIt is designed to separate classes that make up the power system model from those intended for analysis assistance.\n- Classes that constitute the power system model >> Inherit from PowerSystemModel\n- Classes intended for analysis assistance >> Inherit from auxiliary",
      "Role": "Class Category",
      "Abst": "",
      "DetailsCode": "",
      "Signatures": [],
      "Argin": "",
      "Parameters": [],
      "Argout": "",
      "Returns": [],
      "Examples": [],
      "Option": ""
    },
    {
      "Name": "check_edit",
      "Defining": "LayerPackage",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Checks the layer edit state and warns when edits remain unapplied.",
      "Role": "Edit Log",
      "Abst": "Validate whether the layer has an initialized edit state.",
      "DetailsCode": "",
      "Signatures": [
        "flag = check_edit(obj)"
      ],
      "Argin": "",
      "Parameters": {
        "Name": "obj",
        "Type": "LayerPackage",
        "Description": "Target layer object.",
        "Required": true,
        "Default": "-"
      },
      "Argout": "",
      "Returns": {
        "Name": "flag",
        "Type": "logical scalar",
        "Description": "True when state is initialized."
      },
      "Examples": [],
      "Option": ""
    },
    {
      "Name": "reset_edit",
      "Defining": "LayerPackage",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Resets edit status and clears edit logs recursively.",
      "Role": "Edit Log",
      "Abst": "Initialize edit state for this layer and descendants.",
      "DetailsCode": "",
      "Signatures": [
        "reset_edit(obj)"
      ],
      "Argin": "",
      "Parameters": {
        "Name": "obj",
        "Type": "LayerPackage",
        "Description": "Target layer object.",
        "Required": true,
        "Default": "-"
      },
      "Argout": "",
      "Returns": [],
      "Examples": [],
      "Option": ""
    },
    {
      "Name": "log_edit",
      "Defining": "LayerPackage",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Records an edit event and propagates it to parent layers.",
      "Role": "Edit Log",
      "Abst": "Append a new edit-log record.",
      "DetailsCode": "",
      "Signatures": [
        "log_edit(obj)",
        "log_edit(obj, log, tag, before, after, time, tab)"
      ],
      "Argin": "",
      "Parameters": [
        {
          "Name": "obj",
          "Type": "LayerPackage",
          "Description": "Target layer object.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "log",
          "Type": "string scalar",
          "Description": "Edit message.",
          "Required": false,
          "Default": "\"\""
        },
        {
          "Name": "tag",
          "Type": "string scalar",
          "Description": "Edited field tag.",
          "Required": false,
          "Default": "\"\""
        },
        {
          "Name": "before",
          "Type": "double scalar",
          "Description": "Value before edit.",
          "Required": false,
          "Default": "NaN"
        },
        {
          "Name": "after",
          "Type": "double scalar",
          "Description": "Value after edit.",
          "Required": false,
          "Default": "NaN"
        },
        {
          "Name": "time",
          "Type": "string scalar",
          "Description": "Timestamp for the event.",
          "Required": false,
          "Default": "current time"
        },
        {
          "Name": "tab",
          "Type": "table (1x6)",
          "Description": "Prebuilt edit-log row.",
          "Required": false,
          "Default": "auto-generated"
        }
      ],
      "Argout": "",
      "Returns": [],
      "Examples": [],
      "Option": ""
    },
    {
      "Name": "attach_tag",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Appends this layer tag to each input name.",
      "Role": "Tag",
      "Abst": "Generate names with layer tag suffix.",
      "DetailsCode": "",
      "Signatures": [
        "out = attach_tag(obj, str_name_list)"
      ],
      "Argin": "",
      "Parameters": [
        {
          "Name": "obj",
          "Type": "LayerPackage",
          "Description": "Target layer object.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "str_name_list",
          "Type": "string array",
          "Description": "Base names to be tagged.",
          "Required": true,
          "Default": "-"
        }
      ],
      "Argout": "",
      "Returns": {
        "Name": "out",
        "Type": "string array",
        "Description": "Input names with layer tag suffix."
      },
      "Examples": [
        "```matlab\nout = attach_tag(obj, [\"k\",\"d\"]);\n```"
      ],
      "Option": ""
    },
    {
      "Name": "get_tag",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Returns the layer tag, optionally including parent-layer tags.",
      "Role": "Tag",
      "Abst": "Build tag string with optional hierarchy composition.",
      "DetailsCode": "",
      "Signatures": [
        "out = get_tag(obj)",
        "out = get_tag(obj, l_with_layer, str_split)"
      ],
      "Argin": "",
      "Parameters": [
        {
          "Name": "obj",
          "Type": "LayerPackage",
          "Description": "Target layer object.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "l_with_layer",
          "Type": "logical scalar",
          "Description": "Include parent-layer tags recursively.",
          "Required": false,
          "Default": "false"
        },
        {
          "Name": "str_split",
          "Type": "string scalar",
          "Description": "Delimiter for composed tags.",
          "Required": false,
          "Default": "\"\""
        }
      ],
      "Argout": "",
      "Returns": {
        "Name": "out",
        "Type": "string",
        "Description": "Layer tag string."
      },
      "Examples": [],
      "Option": ""
    },
    {
      "Name": "disp_tree",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Displays or returns a text tree of this layer and its descendants.",
      "Role": "Layer Structure",
      "Abst": "Render the hierarchy tree with optional filtering.",
      "DetailsCode": "",
      "Signatures": [
        "disp_tree(obj)",
        "text = disp_tree(obj, str_space, str_ignore, l_isfirst)"
      ],
      "Argin": "",
      "Parameters": [
        {
          "Name": "obj",
          "Type": "LayerPackage",
          "Description": "Root layer object.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "str_space",
          "Type": "string scalar",
          "Description": "Indentation prefix for recursive rendering.",
          "Required": false,
          "Default": "\"\""
        },
        {
          "Name": "str_ignore",
          "Type": "string array",
          "Description": "Class names to ignore in output.",
          "Required": false,
          "Default": "[\"Parameter\"]"
        },
        {
          "Name": "l_isfirst",
          "Type": "logical scalar",
          "Description": "Whether this call is the root invocation.",
          "Required": false,
          "Default": "true"
        }
      ],
      "Argout": "",
      "Returns": {
        "Name": "text",
        "Type": "string",
        "Description": "Hierarchy string when one output is requested."
      },
      "Examples": [],
      "Option": ""
    },
    {
      "Name": "string",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Desc": "Returns the tag string representation of this layer object.",
      "Role": "Tag",
      "Abst": "Convert the layer object to a tag string.",
      "DetailsCode": "",
      "Signatures": [
        "str = string(obj)"
      ],
      "Argin": "",
      "Parameters": {
        "Name": "obj",
        "Type": "LayerPackage",
        "Description": "Target layer object.",
        "Required": true,
        "Default": "-"
      },
      "Argout": "",
      "Returns": {
        "Name": "str",
        "Type": "string",
        "Description": "Tag string of the layer object."
      },
      "Examples": [
        "```matlab\nstr = string(obj);\n```"
      ],
      "Option": ""
    },
    {
      "Name": "table",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Desc": "Returns the parameter table associated with this layer object.",
      "Role": "Parameter",
      "Abst": "Convert layer parameters into table format.",
      "DetailsCode": "",
      "Signatures": [
        "tab = table(obj)"
      ],
      "Argin": "",
      "Parameters": {
        "Name": "obj",
        "Type": "LayerPackage",
        "Description": "Target layer object.",
        "Required": true,
        "Default": "-"
      },
      "Argout": "",
      "Returns": {
        "Name": "tab",
        "Type": "table",
        "Description": "Parameter table of the layer."
      },
      "Examples": [
        "```matlab\ntab = table(obj);\n```"
      ],
      "Option": ""
    }
  ]
};
