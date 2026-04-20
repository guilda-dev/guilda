const classData = {
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
      "Desc": "Callback function executed after parameter changes.",
      "Role": "Edit Log",
      "Type": "function_handle",
      "Size": "1x1"
    },
    {
      "Name": "str_parameter",
      "Defining": "Parameter",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Parameter names managed by this container.",
      "Role": "Parameter",
      "Type": "string",
      "Size": "1xN"
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
      "Desc": "Stashed value used for change comparison.",
      "Role": "Parameter",
      "Type": "any",
      "Size": "1x1"
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
      "Desc": "Parent layer object managed by this container.",
      "Role": "Layer Structure",
      "Type": "LayerPackage",
      "Size": "1x1"
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
      "Desc": "Parameter table generated from dynamic properties.",
      "Role": "Parameter",
      "Type": "table",
      "Size": "1xN (N: number of parameters)"
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
      "Desc": "Parent layer interface for compatibility.",
      "Role": "Layer Structure",
      "Type": "LayerPackage",
      "Size": "1x1"
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
      "Desc": "Parameter class has no children, but the property is kept for interface compatibility.",
      "Role": "Layer Structure",
      "Type": "none",
      "Size": "0x1"
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
      "Desc": "",
      "Role": "",
      "Type": "",
      "Size": ""
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
      "Name": "Parameter",
      "Defining": "Parameter",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "Creates a parameter container for a parent layer.",
      "Role": "Constructor",
      "Abst": "Initialize the parameter container and callback.",
      "DetailsCode": "",
      "Signatures": [
        "obj = Parameter(a_parent, str_tag, CallBackChanged)"
      ],
      "Argin": "",
      "Parameters": [
        {
          "Name": "a_parent",
          "Type": "LayerPackage",
          "Description": "Parent layer object.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "str_tag",
          "Type": "string scalar",
          "Description": "Parameter tag.",
          "Required": false,
          "Default": "\"Parameter\""
        },
        {
          "Name": "CallBackChanged",
          "Type": "function_handle",
          "Description": "Callback executed after parameter changes.",
          "Required": false,
          "Default": "@(varargin) []"
        }
      ],
      "Argout": "",
      "Returns": [],
      "Examples": [],
      "Option": ""
    },
    {
      "Name": "callbackPostSet",
      "Defining": "Parameter",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Desc": "Validates a property after it is changed and logs edits.",
      "Role": "Edit Log",
      "Abst": "Check type consistency and record changes when values differ.",
      "DetailsCode": "",
      "Signatures": [
        "callbackPostSet(obj, name, cls, event)"
      ],
      "Argin": "",
      "Parameters": [
        {
          "Name": "obj",
          "Type": "Parameter",
          "Description": "Target parameter container.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "name",
          "Type": "string scalar",
          "Description": "Property name being updated.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "cls",
          "Type": "string scalar",
          "Description": "Expected class name.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "event",
          "Type": "event data",
          "Description": "Property set event data.",
          "Required": true,
          "Default": "-"
        }
      ],
      "Argout": "",
      "Returns": [],
      "Examples": [],
      "Option": ""
    },
    {
      "Name": "callbackPreSet",
      "Defining": "Parameter",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Desc": "Stores the current value before a property is changed.",
      "Role": "Edit Log",
      "Abst": "Stash the previous property value for later comparison.",
      "DetailsCode": "",
      "Signatures": [
        "callbackPreSet(obj, name, event)"
      ],
      "Argin": "",
      "Parameters": [
        {
          "Name": "obj",
          "Type": "Parameter",
          "Description": "Target parameter container.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "name",
          "Type": "string scalar",
          "Description": "Property name being updated.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "event",
          "Type": "event data",
          "Description": "Property set event data.",
          "Required": true,
          "Default": "-"
        }
      ],
      "Argout": "",
      "Returns": [],
      "Examples": [],
      "Option": ""
    },
    {
      "Name": "add_entry",
      "Defining": "Parameter",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": true,
      "Desc": "Adds dynamic properties and attaches change listeners.",
      "Role": "Parameter",
      "Abst": "Register parameter names, defaults, and validation classes.",
      "DetailsCode": "",
      "Signatures": [
        "add_entry(obj, names, defaults, valids)"
      ],
      "Argin": "",
      "Parameters": [
        {
          "Name": "obj",
          "Type": "Parameter",
          "Description": "Target parameter container.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "names",
          "Type": "string array | cellstr",
          "Description": "Parameter names to register.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "defaults",
          "Type": "cell array",
          "Description": "Default values for each parameter.",
          "Required": true,
          "Default": "-"
        },
        {
          "Name": "valids",
          "Type": "string array | cellstr",
          "Description": "Validation classes for each parameter.",
          "Required": true,
          "Default": "-"
        }
      ],
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
    },
    {
      "Name": "addprop",
      "Defining": "dynamicprops",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Desc": "",
      "Role": "",
      "Abst": "",
      "DetailsCode": "",
      "Signatures": [],
      "Argin": "",
      "Parameters": [],
      "Argout": "",
      "Returns": [],
      "Examples": [],
      "Option": ""
    }
  ]
};
