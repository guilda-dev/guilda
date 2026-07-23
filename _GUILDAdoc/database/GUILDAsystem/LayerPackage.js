(function (root) {
  const data = {
  "schema": {
    "name": "GUILDA class document",
    "version": 2
  },
  "ClassName": "LayerPackage",
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
      "Summary": "",
      "Desc": "manage parameter related to any analyis.",
      "Role": "Parameter",
      "Type": "Parameter",
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
      "Name": "parent",
      "Defining": "LayerPackage",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": true,
      "Constant": false,
      "Abstract": true,
      "Hidden": false,
      "Summary": "",
      "Desc": "manage hierarchical structure of layers.",
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
      "Defining": "LayerPackage",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": true,
      "Constant": false,
      "Abstract": true,
      "Hidden": false,
      "Summary": "",
      "Desc": "manage hierarchical structure of layers.",
      "Role": "Layer Structure",
      "Type": "LayerPackage cell array",
      "Size": "Nx1",
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
      "Name": "validate_tag",
      "Defining": "LayerPackage",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Ensure tag uniqueness among same-layer objects.",
      "Desc": " Validates tag uniqueness within sibling layers and renames on conflicts.",
      "Role": " Tag",
      "Signatures": [
        "str_newtag = validate_tag(obj, str_newtag)"
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
          "Name": "str_newtag",
          "Kind": "",
          "Type": "string scalar",
          "Unit": "",
          "Description": "Candidate tag.",
          "Required": true,
          "Default": "-",
          "Constraints": ""
        }
      ],
      "Returns": {
        "Name": "str_newtag",
        "Type": "string scalar",
        "Unit": "",
        "Description": "Validated unique tag."
      },
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "findchildren",
      "Defining": "LayerPackage",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Retrieve child layers recursively.",
      "Desc": " Collects all descendant layers from the current layer.",
      "Role": " Layer Structure",
      "Signatures": [
        "c = findchildren(obj)"
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
        "Name": "c",
        "Type": "cell array",
        "Unit": "",
        "Description": "Flattened descendant list including self when managed."
      },
      "Examples": [],
      "Notes": "",
      "Throws": "",
      "SeeAlso": [],
      "Since": "",
      "Deprecated": ""
    },
    {
      "Name": "findparent",
      "Defining": "LayerPackage",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": " Retrieve root layer from current object.",
      "Desc": " Finds the top-level parent layer in the hierarchy.",
      "Role": " Layer Structure",
      "Signatures": [
        "p = findparent(obj)"
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
        "Name": "p",
        "Type": "LayerPackage",
        "Unit": "",
        "Description": "Top-level parent layer (or self if root)."
      },
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
      "Name": "LayerPackage",
      "Defining": "LayerPackage",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Hidden": false,
      "Summary": "",
      "Desc": " Abstract base class for layer hierarchy management in GUILDA.\n  It centralizes parent/children relationships, tag handling, and edit logging.",
      "Role": " auxiliary",
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
    "Warnings": [
      "LayerPackage.struct: public method has no Summary or Desc."
    ],
    "Errors": []
  }
};
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["LayerPackage"] = data;
  root.classData = data;
})(window);
