(function (root) {
  const data = {
  "schema": {
    "name": "GUILDA class document",
    "version": 2
  },
  "ClassName": "Parameter",
  "properties": [
    {
      "Name": "CallbackChanged",
      "Defining": "Parameter",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "Callback function executed after parameter changes.",
      "Role": "Edit Log",
      "Type": "function_handle",
      "Size": "1x1",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_parameter",
      "Defining": "Parameter",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "Parameter names managed by this container.",
      "Role": "Parameter",
      "Type": "string",
      "Size": "1xN",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "val_stash",
      "Defining": "Parameter",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "Stashed value used for change comparison.",
      "Role": "Parameter",
      "Type": "any",
      "Size": "1x1",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "a_cls",
      "Defining": "Parameter",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "Parent layer object managed by this container.",
      "Role": "Layer Structure",
      "Type": "LayerPackage",
      "Size": "1x1",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_parameter",
      "Defining": "Parameter",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": true,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "Parameter table generated from dynamic properties.",
      "Role": "Parameter",
      "Type": "table",
      "Size": "1xN (N: number of parameters)",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "parent",
      "Defining": "Parameter",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": true,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "Parent layer interface for compatibility.",
      "Role": "Layer Structure",
      "Type": "LayerPackage",
      "Size": "1x1",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "children",
      "Defining": "Parameter",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": true,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "Parameter class has no children, but the property is kept for interface compatibility.",
      "Role": "Layer Structure",
      "Type": "none",
      "Size": "0x1",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "NoData",
      "Defining": "Parameter",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "",
      "Role": "",
      "Type": "",
      "Size": "",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
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
      "Summary": "",
      "Desc": "Flag to indicate if the layer has been edited.",
      "Role": "Edit Log",
      "Type": "string",
      "Size": "1x1",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
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
      "Summary": "",
      "Desc": "Log of edits made to the layer, including timestamp, ID, log message, tag, and before/after states.",
      "Role": "Edit Log",
      "Type": "table",
      "Size": "Nx6",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
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
      "Summary": "",
      "Desc": "Flag to indicate if the layer is managed by the tag system.",
      "Role": "Tag",
      "Type": "logical",
      "Size": "1x1",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
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
      "Summary": "",
      "Desc": "User-defined tag for the layer, used for identification and management within the layer structure.",
      "Role": "Tag",
      "Type": "string",
      "Size": "1x1",
      "Unit": "",
      "Default": "",
      "Constraints": "",
      "Notes": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "Parameter",
      "Defining": "Parameter",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Initialize the parameter container and callback.",
      "Desc": " Creates a parameter container for a parent layer.",
      "Role": " Constructor",
      "Signatures": [
        "obj = Parameter(a_parent, str_tag, CallBackChanged)"
      ],
      "Parameters": [
        {
          "Name": "a_parent",
          "Kind": "",
          "Type": "LayerPackage",
          "Unit": "",
          "Description": "Parent layer object.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "str_tag",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Parameter tag.",
          "Required": false,
          "Default": "\"Parameter\"",
          "Constraints": ""
        },
        {
          "Name": "CallBackChanged",
          "Kind": "",
          "Type": "function_handle",
          "Unit": "",
          "Description": "Callback executed after parameter changes.",
          "Required": false,
          "Default": "@(varargin) []",
          "Constraints": ""
        }
      ],
      "Returns": [],
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "callbackPostSet",
      "Defining": "Parameter",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Summary": " Check type consistency and record changes when values differ.",
      "Desc": " Validates a property after it is changed and logs edits.",
      "Role": " Edit Log",
      "Signatures": [
        "callbackPostSet(obj, name, cls, event)"
      ],
      "Parameters": [
        {
          "Name": "obj",
          "Kind": "",
          "Type": "Parameter",
          "Unit": "",
          "Description": "Target parameter container.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "name",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Property name being updated.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "cls",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Expected class name.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "event",
          "Kind": "",
          "Type": "event data",
          "Unit": "",
          "Description": "Property set event data.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        }
      ],
      "Returns": [],
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "callbackPreSet",
      "Defining": "Parameter",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Summary": " Stash the previous property value for later comparison.",
      "Desc": " Stores the current value before a property is changed.",
      "Role": " Edit Log",
      "Signatures": [
        "callbackPreSet(obj, name, event)"
      ],
      "Parameters": [
        {
          "Name": "obj",
          "Kind": "",
          "Type": "Parameter",
          "Unit": "",
          "Description": "Target parameter container.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "name",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Property name being updated.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "event",
          "Kind": "",
          "Type": "event data",
          "Unit": "",
          "Description": "Property set event data.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        }
      ],
      "Returns": [],
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "add_entry",
      "Defining": "Parameter",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Summary": " Register parameter names, defaults, and validation classes.",
      "Desc": " Adds dynamic properties and attaches change listeners.",
      "Role": " Parameter",
      "Signatures": [
        "add_entry(obj, names, defaults, valids)"
      ],
      "Parameters": [
        {
          "Name": "obj",
          "Kind": "",
          "Type": "Parameter",
          "Unit": "",
          "Description": "Target parameter container.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "names",
          "Kind": "",
          "Type": "string array | cellstr",
          "Unit": "",
          "Description": "Parameter names to register.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "defaults",
          "Kind": "",
          "Type": "cell array",
          "Unit": "",
          "Description": "Default values for each parameter.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "valids",
          "Kind": "",
          "Type": "string array | cellstr",
          "Unit": "",
          "Description": "Validation classes for each parameter.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        }
      ],
      "Returns": [],
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "check_edit",
      "Defining": "LayerPackage",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Validate whether the layer has an initialized edit state.",
      "Desc": " Checks the layer edit state and warns when edits remain unapplied.",
      "Role": " Edit Log",
      "Signatures": [
        "flag = check_edit(obj)"
      ],
      "Parameters": {
        "Name": "obj",
        "Kind": "",
        "Type": "LayerPackage",
        "Unit": "",
        "Description": "Target layer object.",
        "Required": true,
        "Default": "-",
        "Constraints": ""
      },
      "Returns": {
        "Name": "flag",
        "Type": "logical scalar",
        "Unit": "",
        "Description": "True when state is initialized."
      },
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "reset_edit",
      "Defining": "LayerPackage",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Initialize edit state for this layer and descendants.",
      "Desc": " Resets edit status and clears edit logs recursively.",
      "Role": " Edit Log",
      "Signatures": [
        "reset_edit(obj)"
      ],
      "Parameters": {
        "Name": "obj",
        "Kind": "",
        "Type": "LayerPackage",
        "Unit": "",
        "Description": "Target layer object.",
        "Required": true,
        "Default": "-",
        "Constraints": ""
      },
      "Returns": [],
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "log_edit",
      "Defining": "LayerPackage",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Append a new edit-log record.",
      "Desc": " Records an edit event and propagates it to parent layers.",
      "Role": " Edit Log",
      "Signatures": [
        "log_edit(obj)",
        "log_edit(obj, log, tag, before, after, time, tab)"
      ],
      "Parameters": [
        {
          "Name": "obj",
          "Kind": "",
          "Type": "LayerPackage",
          "Unit": "",
          "Description": "Target layer object.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "log",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Edit message.",
          "Required": false,
          "Default": "\"\"",
          "Constraints": ""
        },
        {
          "Name": "tag",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Edited field tag.",
          "Required": false,
          "Default": "\"\"",
          "Constraints": ""
        },
        {
          "Name": "before",
          "Kind": "",
          "Type": "double scalar",
          "Unit": "",
          "Description": "Value before edit.",
          "Required": false,
          "Default": "NaN",
          "Constraints": ""
        },
        {
          "Name": "after",
          "Kind": "",
          "Type": "double scalar",
          "Unit": "",
          "Description": "Value after edit.",
          "Required": false,
          "Default": "NaN",
          "Constraints": ""
        },
        {
          "Name": "time",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Timestamp for the event.",
          "Required": false,
          "Default": "current time",
          "Constraints": ""
        },
        {
          "Name": "tab",
          "Kind": "",
          "Type": "table (1x6)",
          "Unit": "",
          "Description": "Prebuilt edit-log row.",
          "Required": false,
          "Default": "auto-generated",
          "Constraints": ""
        }
      ],
      "Returns": [],
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "struct",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "",
      "Role": "",
      "Signatures": [],
      "Parameters": [],
      "Returns": [],
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "attach_tag",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Generate names with layer tag suffix.",
      "Desc": " Appends this class tag to each input name.",
      "Role": " Tag",
      "Signatures": [
        "out = attach_tag(obj, str_name_list)"
      ],
      "Parameters": [
        {
          "Name": "obj",
          "Kind": "",
          "Type": "LayerPackage",
          "Unit": "",
          "Description": "Target layer object.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "str_name_list",
          "Kind": "",
          "Type": "string array",
          "Unit": "",
          "Description": "Base names to be tagged.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        }
      ],
      "Returns": {
        "Name": "out",
        "Type": "string array",
        "Unit": "",
        "Description": "Input names with layer tag suffix."
      },
      "Examples": [
        ">> obj.attach_tag([\"V\", \"P\"])\nans =\n    [\"V_Tag\", \"P_Tag\"]"
      ],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "get_tag",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Build tag string with optional hierarchy composition.",
      "Desc": " Returns the layer tag, optionally including parent-layer tags.",
      "Role": " Tag",
      "Signatures": [
        "out = get_tag(obj)",
        "out = get_tag(obj, l_with_layer, str_split)"
      ],
      "Parameters": [
        {
          "Name": "obj",
          "Kind": "",
          "Type": "LayerPackage",
          "Unit": "",
          "Description": "Target layer object.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "l_with_layer",
          "Kind": "",
          "Type": "logical scalar",
          "Unit": "",
          "Description": "Include parent-layer tags recursively.",
          "Required": false,
          "Default": "false",
          "Constraints": ""
        },
        {
          "Name": "str_split",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Delimiter for composed tags.",
          "Required": false,
          "Default": "\"\"",
          "Constraints": ""
        }
      ],
      "Returns": {
        "Name": "out",
        "Type": "string",
        "Unit": "",
        "Description": "Layer tag string."
      },
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "disp_tree",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Render the hierarchy tree with optional filtering.",
      "Desc": " Displays or returns a text tree of this layer and its descendants.",
      "Role": " Layer Structure",
      "Signatures": [
        "disp_tree(obj)",
        "text = disp_tree(obj, str_space, str_ignore, l_isfirst)"
      ],
      "Parameters": [
        {
          "Name": "obj",
          "Kind": "",
          "Type": "LayerPackage",
          "Unit": "",
          "Description": "Root layer object.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        },
        {
          "Name": "str_space",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Indentation prefix for recursive rendering.",
          "Required": false,
          "Default": "\"\"",
          "Constraints": ""
        },
        {
          "Name": "str_ignore",
          "Kind": "",
          "Type": "string array",
          "Unit": "",
          "Description": "Class names to ignore in output.",
          "Required": false,
          "Default": "[\"Parameter\"]",
          "Constraints": ""
        },
        {
          "Name": "l_isfirst",
          "Kind": "",
          "Type": "logical scalar",
          "Unit": "",
          "Description": "Whether this call is the root invocation.",
          "Required": false,
          "Default": "true",
          "Constraints": ""
        }
      ],
      "Returns": {
        "Name": "text",
        "Type": "string",
        "Unit": "",
        "Description": "Hierarchy string when one output is requested."
      },
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "string",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Summary": "Convert the layer object to a tag string.",
      "Desc": " Returns the tag string representation of this layer object.",
      "Role": "Tag",
      "Signatures": [
        "str = string(obj)"
      ],
      "Parameters": {
        "Name": "obj",
        "Kind": "",
        "Type": "LayerPackage",
        "Unit": "",
        "Description": "Target layer object.",
        "Required": true,
        "Default": "-",
        "Constraints": ""
      },
      "Returns": {
        "Name": "str",
        "Type": "string",
        "Unit": "",
        "Description": "Tag string of the layer object."
      },
      "Examples": [
        "```matlab\nstr = string(obj);\n```"
      ],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "table",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Summary": "Convert layer parameters into table format.",
      "Desc": " Returns the parameter table associated with this layer object.",
      "Role": "Parameter",
      "Signatures": [
        "tab = table(obj)"
      ],
      "Parameters": {
        "Name": "obj",
        "Kind": "",
        "Type": "LayerPackage",
        "Unit": "",
        "Description": "Target layer object.",
        "Required": true,
        "Default": "-",
        "Constraints": ""
      },
      "Returns": {
        "Name": "tab",
        "Type": "table",
        "Unit": "",
        "Description": "Parameter table of the layer."
      },
      "Examples": [
        "```matlab\ntab = table(obj);\n```"
      ],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "addprop",
      "Defining": "dynamicprops",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": "",
      "Role": "",
      "Signatures": [],
      "Parameters": [],
      "Returns": [],
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    }
  ],
  "validation": {
    "Warnings": [],
    "Errors": [
      "Parameter.Parameter: invalid <@Returns> value: JSON の構文エラーが行 9、列 5 (文字 124) にあります: 追加テキストです。"
    ]
  }
};
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["Parameter"] = data;
  root.classData = data;
})(window);
