(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["GraphChart"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "GraphChart",
  "properties": [
    {
      "Name": "SeriesColor",
      "Defining": "GraphChart",
      "Group": "Appearance of each element (one row per element, see tab_element)",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0, 3)",
      "Validation": {
        "Class": "double",
        "Size": "(:,3)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 108,
      "Summary": "RGB color of each element; NaN rows: the color order of the axes.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "SeriesLabel",
      "Defining": "GraphChart",
      "Group": "Appearance of each element (one row per element, see tab_element)",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(0, 1)",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 109,
      "Summary": "Legend entry of each line and marker set (\"\": none).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "SeriesLineWidth",
      "Defining": "GraphChart",
      "Group": "Appearance of each element (one row per element, see tab_element)",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0, 1)",
      "Validation": {
        "Class": "double",
        "Size": "(:,1)",
        "Validators": [
          "mustBePositive"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 110,
      "Summary": "Width of each line.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "SeriesMarker",
      "Defining": "GraphChart",
      "Group": "Appearance of each element (one row per element, see tab_element)",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(0, 1)",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 111,
      "Summary": "Marker of each line and marker set.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "SeriesMarkerSize",
      "Defining": "GraphChart",
      "Group": "Appearance of each element (one row per element, see tab_element)",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0, 1)",
      "Validation": {
        "Class": "double",
        "Size": "(:,1)",
        "Validators": [
          "mustBePositive"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 112,
      "Summary": "Marker size of each line and marker set.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "SeriesLineStyle",
      "Defining": "GraphChart",
      "Group": "Appearance of each element (one row per element, see tab_element)",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(0, 1)",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 113,
      "Summary": "Line style of each line.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "SeriesVisible",
      "Defining": "GraphChart",
      "Group": "Appearance of each element (one row per element, see tab_element)",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "false(0, 1)",
      "Validation": {
        "Class": "logical",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 114,
      "Summary": "Show each element.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_data",
      "Defining": "GraphChart",
      "Group": "Data",
      "GetAccess": "protected",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 117,
      "Summary": "Data of the chart with the optional fields filled (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_series",
      "Defining": "GraphChart",
      "Group": "Data",
      "GetAccess": "protected",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 118,
      "Summary": "Element rows: Tag, Kind, Series (index in sct_series), Item (column or bar), Panel.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_colorAuto",
      "Defining": "GraphChart",
      "Group": "Drawing",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0, 3)",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 121,
      "Summary": "Color of each element from the color order of the axes (for NaN rows).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "l_cursor",
      "Defining": "GraphChart",
      "Group": "Drawing",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "false",
      "Validation": {
        "Class": "logical",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 122,
      "Summary": "The time cursor is shown (set_time was called).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "l_firstDraw",
      "Defining": "GraphChart",
      "Group": "Drawing",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "true",
      "Validation": {
        "Class": "logical",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 123,
      "Summary": "The next update_scene follows create_scene in build or set_data.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "PlaySpeed",
      "Defining": "GraphBase",
      "Group": "Time",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "1",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": [
          "mustBePositive",
          "mustBeFinite"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 135,
      "Summary": "Playback speed relative to real time, of the Play button of the playback bar and of animate without Speed.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "ElementClickedFcn",
      "Defining": "GraphBase",
      "Group": "Interaction",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 139,
      "Summary": "Function called as fcn(G, data) when an element is clicked (data: GraphEventData); [] for none.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "function_handle",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "TimeChangedFcn",
      "Defining": "GraphBase",
      "Group": "Interaction",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 140,
      "Summary": "Function called as fcn(G, data) after set_time drew the graph (data: GraphTimeEventData); [] for none.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "function_handle",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "SelectionColor",
      "Defining": "GraphBase",
      "Group": "Interaction",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[1 176/255 0]",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 141,
      "Summary": "Color of the selection overlay (a color name, \"#RRGGBB\" or RGB; stored as RGB).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Selection",
      "Defining": "GraphBase",
      "Group": "Interaction",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(1, 0)",
      "Validation": {
        "Class": "string",
        "Size": "(1,:)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 144,
      "Summary": "Tags of the selected elements.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "h_controls",
      "Defining": "GraphBase",
      "Group": "Controls",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "gobjects(0)",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 148,
      "Summary": "Panel of controls of show_controls (a uipanel); empty when not shown.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.ui.container.Panel",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "ax",
      "Defining": "GraphBase",
      "Group": "Graphics",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "gobjects(0)",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 152,
      "Summary": "Axes of the graph, one per panel.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "matlab.graphics.axis.Axes",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_plt",
      "Defining": "GraphBase",
      "Group": "Graphics",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct.empty",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 153,
      "Summary": "Graphics objects of the graph, as a struct of handle arrays.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_pltPrevious",
      "Defining": "GraphBase",
      "Group": "Graphics",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct.empty",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 156,
      "Summary": "During create_scene of set_data: sct_plt of the drawing before (a subclass may reuse its objects); empty otherwise.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rv_t",
      "Defining": "GraphBase",
      "Group": "Time",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "0",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 159,
      "Summary": "Times of the samples (1 x n_t) [s], or the values of other samples (e.g. the steps of a continuation power flow).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "i_time",
      "Defining": "GraphBase",
      "Group": "Time",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "1",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 160,
      "Summary": "Index of the sample shown.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_sampleName",
      "Defining": "GraphBase",
      "Group": "Time",
      "GetAccess": "protected",
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
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 163,
      "Summary": "Name of the samples from the data (e.g. \"Step\"); \"\": times in seconds.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_sampleText",
      "Defining": "GraphBase",
      "Group": "Time",
      "GetAccess": "protected",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(1, 0)",
      "Validation": {
        "Class": "string",
        "Size": "(1,:)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 164,
      "Summary": "Text of each sample from the data (1 x n_t); empty: see sample_text.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_element",
      "Defining": "GraphBase",
      "Group": "Elements",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/GraphBase.m",
      "Line": 167,
      "Summary": "Elements of the graph: Tag, Kind and Index (position in the vector properties of its kind).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "GraphChart",
      "Defining": "GraphChart",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "sct_data",
        "opt"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "sct_data",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Data of the chart (see the class help)."
        },
        {
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes for a single panel; [] for a new figure."
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
          "Description": "The chart."
        }
      ],
      "Signature": "obj = GraphChart(sct_data, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/GraphChart.m",
      "Line": 127,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Check the data and draw the chart.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "has_playback",
      "Defining": "GraphChart",
      "Group": "has",
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
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The chart has samples to play."
        }
      ],
      "Signature": "l = has_playback(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/has_playback.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GraphBase",
      "Throws": [],
      "Summary": "Whether the chart changes with the time: it then gets the playback bar.",
      "Desc": "A chart of two or more samples changes with the time when it has a time panel (a\ncursor), a series shown by sample (iv_sample) or a panel with a title per sample.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "control_list",
      "Defining": "GraphChart",
      "Group": "control",
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
        "sct_ctl"
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
          "Name": "sct_ctl",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Controls of the panel, one row each."
        }
      ],
      "Signature": "sct_ctl = control_list(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/control_list.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GraphBase",
      "Throws": [],
      "Summary": "Controls of the panel of show_controls: none.",
      "Desc": "The appearance of a chart is per element (vector properties), and the time of a chart\nthat changes with it is in the playback bar (see has_playback), so the panel has no\ncontrols. See GraphBase.control_list for the fields.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "apply_selection",
      "Defining": "GraphChart",
      "Group": "apply",
      "Access": "protected",
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
      "Signature": "apply_selection(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/apply_selection.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GraphBase",
      "Throws": [],
      "Summary": "Draw the selection overlay: a wide line under a selected line, a ring on each marker of a selected marker set, an outline around a selected bar.",
      "Desc": "The overlay is drawn from the graphics shown, takes no clicks and is not in the legend.\nHidden elements get no overlay.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "style_properties",
      "Defining": "GraphChart",
      "Group": "style",
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
        "sct_map"
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
          "Name": "sct_map",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Kind -> option -> property name."
        }
      ],
      "Signature": "sct_map = style_properties(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/style_properties.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GraphBase",
      "Throws": [],
      "Summary": "Options of set_style for each kind of element and the vector property each one writes.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "element_table",
      "Defining": "GraphChart",
      "Group": "element",
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
        "tab"
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
          "Name": "tab",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag, Kind (\"line\", \"bar\" or \"marker\") and Index (row in the Series* vectors)."
        }
      ],
      "Signature": "tab = element_table(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/element_table.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GraphBase",
      "Throws": [],
      "Summary": "Elements of the chart: one row per line, bar and marker set, in the order of the series.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "apply_style",
      "Defining": "GraphChart",
      "Group": "apply",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "iv_element"
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
          "Name": "iv_element",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Rows of the elements in tab_element."
        }
      ],
      "Outputs": [],
      "Signature": "apply_style(obj, iv_element)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/apply_style.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GraphBase",
      "Throws": [],
      "Summary": "Set the appearance of the elements iv_element on their graphics objects and update the legends.",
      "Desc": "A line or marker set changes its line object; a bar changes its row of the CData of its\nbar series, and a hidden bar has a NaN height (it keeps its place). A NaN color is the\ncolor of the color order of the axes. The marker of a marker cursor takes the color and\nthe visibility of its element.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "update_scene",
      "Defining": "GraphChart",
      "Group": "update",
      "Access": "protected",
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
          "Description": ""
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
          "Description": "Index of the sample."
        }
      ],
      "Outputs": [],
      "Signature": "update_scene(obj, k)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/update_scene.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GraphBase",
      "Throws": [],
      "Summary": "Draw sample k: the series shown by sample, the titles per sample and the time cursor.",
      "Desc": "A series with iv_sample shows its rows of sample k; a panel with one title per sample\nshows title k. The other lines show every time and do not change. A line cursor moves\nto x = rv_t(k); a marker cursor (s_cursor \"marker\") moves the marker of each line and\nmarker set to its row k, (rv_x(k), rm_y(k, column)). The cursor appears at the first\nset_time: the drawing of build (and of set_data before any set_time) leaves it hidden.\nA chart without any of these has nothing to update.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "create_scene",
      "Defining": "GraphChart",
      "Group": "create",
      "Access": "protected",
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
      "Signature": "create_scene(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/create_scene.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GraphBase",
      "Throws": [],
      "Summary": "Draw every panel: the bars, the lines and marker sets, the reference lines and the time cursor (a line or markers).",
      "Desc": "Each panel is cleared and drawn again from the data; the appearance of the elements\ncomes from the vector properties (apply_style). The default color of an element (NaN\nrows of SeriesColor) follows the color order of its axes: by line or marker set within\nthe panel, and by bar series for the bars. A series with iv_sample and a panel with a\ntitle per sample show the rows and the title of the sample i_time.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "load_data",
      "Defining": "GraphChart",
      "Group": "load",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sct_data"
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
          "Name": "sct_data",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Data of the chart (see the class help)."
        }
      ],
      "Outputs": [],
      "Signature": "load_data(obj, sct_data)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/load_data.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "GraphBase",
      "Throws": [
        "GUILDA:GraphChart:FieldValue",
        "GUILDA:GraphChart:PanelCount",
        "GUILDA:GraphChart:GridChange",
        "GUILDA:GraphChart:FieldSize",
        "GUILDA:GraphChart:MissingField"
      ],
      "Summary": "Check the data of the chart, fill the optional fields and set the appearance of each element.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "refresh_legend",
      "Defining": "GraphChart",
      "Group": "refresh",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "iv_panel"
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
          "Name": "iv_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Panels whose legends are drawn again."
        }
      ],
      "Outputs": [],
      "Signature": "refresh_legend(obj, iv_panel)",
      "File": "_GUILDAsystem/_auxiliary/@GraphChart/refresh_legend.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the legend of each panel iv_panel again from the shown elements.",
      "Desc": "The entries are the bar series with a legend entry and the shown lines and marker sets\nwith a nonempty SeriesLabel, in the element order. A panel without entries, or with\ns_legendLocation \"none\", has no legend. The legend does not take objects drawn later\n(AutoUpdate off), such as the selection overlay.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "hide_controls",
      "Defining": "GraphBase",
      "Group": "hide",
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
      "Signature": "hide_controls(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/hide_controls.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Remove the panel of controls of show_controls.",
      "Desc": "The axes take back their place when the panel was put next to them. The graph does not\nchange. Nothing happens when no panel is shown.",
      "SeeAlso": [],
      "Examples": "```matlab\nG.show_controls();\nG.hide_controls();\n```",
      "Deprecated": ""
    },
    {
      "Name": "show_controls",
      "Defining": "GraphBase",
      "Group": "show",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
      ],
      "OutputNames": [
        "h_panel"
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
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container of the panel (figure, uifigure, uipanel, uitab, uigridlayout); [] next to the axes."
        },
        {
          "Name": "ChangedFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Function called as fcn(G, s_property, value) after a control set a property; [] for none. <@Type> function_handle"
        }
      ],
      "Outputs": [
        {
          "Name": "h_panel",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The panel of controls. <@Type> matlab.ui.container.Panel"
        }
      ],
      "Signature": "h_panel = show_controls(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/show_controls.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:NoAxes",
        "GUILDA:GraphBase:ChangedFcn",
        "GUILDA:GraphBase:ControlsParent",
        "GUILDA:GraphBase:ControlWidget",
        "GUILDA:GraphBase:ControlProperty",
        "GUILDA:GraphBase:ControlsPlace"
      ],
      "Summary": "Show a panel of controls that change what the graph shows.",
      "Desc": "The panel is made from the declaration control_list of the class: one control per\nproperty (a dropdown, checkbox, slider, spinner, a range of two spinners, with an Auto\ncheckbox when the range can be automatic, or a toggle button), under the headings of\ntheir groups. The time is not in the panel: the playback bar below the axes has it (see\nGraphBase). The controls only set the properties, so a change in the panel is the same\nas setting the property in code, and a change of the property in code (or by set_style,\nanother panel) is shown in the panel. A value the property refuses is reported (an\nalert in a visible figure, a warning otherwise) and the control goes back to the value\nof the property.\n\nParent empty puts the panel next to the axes, in the container of the axes (or of their\ntiled layout): the axes give up the right part of about 220 pixels (the share is kept\nwhen the figure is resized; the playback bar keeps the width of the axes). A container (figure, uifigure, uipanel, uitab or\nuigridlayout, e.g. a cell prepared by a GUI) gets the panel filling it. A panel shown\nbefore is replaced. The panel stays through set_data and is deleted with the axes;\nhide_controls removes it.\n\nChangedFcn is called as fcn(G, s_property, value) after a control set a property,\ne.g. to record the change as code.",
      "SeeAlso": [],
      "Examples": "```matlab\nG = res.plot_spring_model();\nG.show_controls();\nG.ShowLabel = false;                    % the checkbox follows\nh = G.show_controls(Parent=uipanel(uifigure), ...\n                    ChangedFcn=@(G, s, v) disp(\"G.\" + s + \" = \" + mat2str(v)));\n```",
      "Deprecated": ""
    },
    {
      "Name": "clear_selection",
      "Defining": "GraphBase",
      "Group": "clear",
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
      "Signature": "clear_selection(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/clear_selection.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Empty the selection and remove its overlay.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "```matlab\nG.clear_selection();\n```",
      "Deprecated": ""
    },
    {
      "Name": "select",
      "Defining": "GraphBase",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sr_tag"
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
          "Name": "sr_tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags to select (see tab_element)."
        }
      ],
      "Outputs": [],
      "Signature": "select(obj, sr_tag)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/select.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:UnknownTag"
      ],
      "Summary": "Add elements to the selection by tag and draw the selection overlay.",
      "Desc": "Every element with a selected tag is highlighted in SelectionColor (e.g. a bus and the\nlink of a component share the tag of the component). The overlay does not change the\nappearance set by set_style. Selecting a tag twice changes nothing; an unknown tag is\nan error.",
      "SeeAlso": [],
      "Examples": "```matlab\nG = net.plot_diagram();\nG.select([\"B001\", \"B002\"]);\nG.Selection             % [\"B001\", \"B002\"]\nG.clear_selection();\n```",
      "Deprecated": ""
    },
    {
      "Name": "reset_style",
      "Defining": "GraphBase",
      "Group": "reset",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sr_tag"
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
          "Name": "sr_tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "unique(obj.tab_element.Tag, \"stable\")'",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the elements; all by default."
        }
      ],
      "Outputs": [],
      "Signature": "reset_style(obj, sr_tag)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/reset_style.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:UnknownTag"
      ],
      "Summary": "Return the appearance of elements to the defaults of the data.",
      "Desc": "Every vector property that set_style writes (see style_properties of the subclass) gets\nback, for the elements with the given tags, the value it had when the element came with\nthe data. With no argument, all elements are reset. The selection is not changed.",
      "SeeAlso": [],
      "Examples": "```matlab\nG.set_style(\"B001\", Color=\"r\");\nG.reset_style(\"B001\");\nG.reset_style();          % every element\n```",
      "Deprecated": ""
    },
    {
      "Name": "unlink",
      "Defining": "GraphBase",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "G_other"
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
          "Name": "G_other",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "GraphBase",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Graph to unlink."
        }
      ],
      "Outputs": [],
      "Signature": "unlink(obj, G_other)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/unlink.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Remove the link between this graph and another one (both ways).",
      "Desc": "Unlinking a graph that is not linked changes nothing.",
      "SeeAlso": [],
      "Examples": "```matlab\nG1.unlink(G2);\n```",
      "Deprecated": ""
    },
    {
      "Name": "link",
      "Defining": "GraphBase",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "G_other"
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
          "Name": "G_other",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "GraphBase",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Graph to link."
        }
      ],
      "Outputs": [],
      "Signature": "link(obj, G_other)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/link.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Link another graph so that both follow set_time.",
      "Desc": "The link is symmetric: G1.link(G2) is the same as G2.link(G1), and set_time on either\nmoves both (each at the sample nearest to t of its own times). Linking a graph twice, or\nto itself, changes nothing. A deleted graph is dropped from the links. export_video\nrecords the figure of the graph it is called on: linked graphs in other figures move\nwhile the video is written but are not in it.",
      "SeeAlso": [],
      "Examples": "```matlab\nG1 = res.plot_spring_model();\nG2 = res.plot_diagram();\nG1.link(G2);\nG1.set_time(1.0);        % G2 shows t = 1.0 too\n```",
      "Deprecated": ""
    },
    {
      "Name": "export_video",
      "Defining": "GraphBase",
      "Group": "export",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_file",
        "opt"
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
          "Name": "s_file",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Path of the video file (.mp4)."
        },
        {
          "Name": "FrameRate",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "20",
          "Required": false,
          "Unit": "1/s",
          "Description": "Frames per second of the video."
        },
        {
          "Name": "TimeStep",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Time of the data between frames [s] (default 0.05), or the step of the sample values for samples named by the data (default: one frame per sample)."
        },
        {
          "Name": "HoldTime",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeNonnegative"
          ],
          "Default": "1",
          "Required": false,
          "Unit": "s",
          "Description": "Time the last frame is held."
        },
        {
          "Name": "UpdateFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Function called as UpdateFcn(t) at every frame; [] for none. <@Type> function_handle"
        },
        {
          "Name": "Capture",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Capture, [\"figure\", \"axes\"])"
          ],
          "Default": "\"figure\"",
          "Required": false,
          "Unit": "",
          "Description": "Part of the window recorded."
        }
      ],
      "Outputs": [],
      "Signature": "export_video(obj, s_file, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/export_video.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:OneSample"
      ],
      "Summary": "Write the animation to an MPEG-4 video file.",
      "Desc": "Frames are taken every TimeStep seconds of the data (the nearest sample each) and\nwritten at FrameRate frames per second; FrameRate x TimeStep = 1 is real time. When the\ndata names its samples (s_sampleName, e.g. steps) and TimeStep is not given, every sample\nis one frame. The last\nframe is held for HoldTime seconds. Capture \"figure\" records the whole figure (other\naxes moved by UpdateFcn included), \"axes\" only the axes of the graph (the first panel\nwhen it has several). The frames are padded to an even width and height, as H.264\nrequires. The linked graphs (see link) move with it, but only the figure of this graph\nis recorded: linked graphs in other figures are not in the video. A graph with one\nsample has nothing to record: it is an error. The playback bar is hidden while the video\nis written (its strip goes to the axes), so no frame shows it. Before each frame the graph is told the\ntime between frames (prepare_frame(1/FrameRate)), and after the last one NaN, so that a\ngraph that moves by real time follows the video instead of the clock.",
      "SeeAlso": [],
      "Examples": "```matlab\nG.export_video(\"swing.mp4\", FrameRate=20, TimeStep=0.05);\n```",
      "Deprecated": ""
    },
    {
      "Name": "pause",
      "Defining": "GraphBase",
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
      "Signature": "pause(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/pause.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Stop the playback of play (or of the Play button of the playback bar).",
      "Desc": "The timer is stopped and deleted and the sample shown stays. A blocking animate that\nruns stops at its next frame. Nothing happens when nothing plays.",
      "SeeAlso": [],
      "Examples": "```matlab\nG.play();\nG.pause();\n```",
      "Deprecated": ""
    },
    {
      "Name": "play",
      "Defining": "GraphBase",
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
      "Signature": "play(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/play.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:OneSample",
        "GUILDA:GraphBase:NoAxes"
      ],
      "Summary": "Start playing the samples without blocking, as the Play button of the playback bar.",
      "Desc": "A timer shows the samples from the one shown (from the first when the last is shown)\nat PlaySpeed times real time, and play returns at once; pause stops it, and so do\nclosing the figure and deleting the axes or the graph. The bar shows Pause meanwhile. A\nplay while a playback (play or animate) runs does nothing, and so does a play in matlab\n-batch or for a figure that is not visible (no timer is made). A graph with one sample\nhas nothing to play: it is an error. animate plays the same samples and blocks.",
      "SeeAlso": [],
      "Examples": "```matlab\nG = res.plot_diagram();\nG.PlaySpeed = 0.5;\nG.play();\nG.pause();\n```",
      "Deprecated": ""
    },
    {
      "Name": "animate",
      "Defining": "GraphBase",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt"
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
          "Name": "Speed",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Playback speed relative to real time (Inf: as fast as possible); default PlaySpeed."
        },
        {
          "Name": "TimeStep",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Time of the data between frames [s] (default 0.05), or the step of the sample values for samples named by the data (default: one frame per sample)."
        },
        {
          "Name": "UpdateFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Function called as UpdateFcn(t) at every frame; [] for none. <@Type> function_handle"
        }
      ],
      "Outputs": [],
      "Signature": "animate(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/animate.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:OneSample"
      ],
      "Summary": "Play the samples as an animation in the figure.",
      "Desc": "Frames are taken every TimeStep seconds of the data (the nearest sample each) and shown\nSpeed times faster than real time when the drawing keeps up (Speed not given: PlaySpeed).\nanimate blocks until the last frame; the Play button of the playback bar plays without\nblocking (see GraphBase). When the data names its\nsamples (s_sampleName, e.g. the steps of a continuation power flow) and TimeStep is not\ngiven, every sample is one frame (one sample value per second at Speed=1). UpdateFcn(t) is called at\nevery frame with the time of the sample, e.g. to move an xline in other axes. Closing\nthe figure stops the animation, and so does the Pause button of the playback bar (at the\nnext frame). While it plays, the button of the bar shows Pause, and a press of Play does\nnot start a second playback. A playback of the bar that runs is stopped first. The linked graphs (see link) move with it. A graph with\none sample has nothing to play: it is an error.",
      "SeeAlso": [],
      "Examples": "```matlab\nh = xline(ax_other, 0);\nG.animate(Speed=0.5, UpdateFcn=@(t) set(h, \"Value\", t));\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_layout",
      "Defining": "GraphBase",
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
        "sct_layout"
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
          "Name": "sct_layout",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Layout tables by kind (see PowerNetwork.get_layout)."
        }
      ],
      "Signature": "sct_layout = get_layout(obj)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/get_layout.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:PositionNotSupported"
      ],
      "Summary": "Return the drawn positions in the form of net.get_layout (only graphs with a free layout).",
      "Desc": "A graph with a free layout (GraphNetDiagram, GraphNetMap) overrides this method and\nreturns the positions it draws, so that net.set_layout(G.get_layout()) saves them in the\nmodel. In the other graphs the positions follow from the data, and this method raises\nan error.",
      "SeeAlso": [],
      "Examples": "```matlab\nG = net.plot_diagram();\nnet.set_layout(G.get_layout());\n```\n\nSee also PowerNetwork.get_layout, PowerNetwork.set_layout",
      "Deprecated": ""
    },
    {
      "Name": "set_position",
      "Defining": "GraphBase",
      "Group": "set",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sr_tag",
        "rm_xy"
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
          "Name": "sr_tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the elements."
        },
        {
          "Name": "rm_xy",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "New positions, one row (x, y) per tag."
        }
      ],
      "Outputs": [],
      "Signature": "set_position(obj, sr_tag, rm_xy)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/set_position.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:PositionNotSupported"
      ],
      "Summary": "Move elements of the drawing (only graphs with a free layout).",
      "Desc": "A graph with a free layout (GraphNetDiagram) overrides this method; it moves the\nelements in the drawing only, never in the model. In the other graphs the positions\nfollow from the data, and this method raises an error.",
      "SeeAlso": [],
      "Examples": "```matlab\nG = net.plot_diagram();\nG.set_position(\"B001\", [0.2, 0.8]);\n```",
      "Deprecated": ""
    },
    {
      "Name": "set_style",
      "Defining": "GraphBase",
      "Group": "set",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sr_tag",
        "opt"
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
          "Name": "sr_tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the elements (see tab_element)."
        },
        {
          "Name": "Color",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Color of the elements. <@Type> string|double"
        },
        {
          "Name": "Label",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Label of the elements: one, or one per tag."
        },
        {
          "Name": "Marker",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Marker of the elements."
        },
        {
          "Name": "MarkerSize",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Size of the markers: one, or one per tag."
        },
        {
          "Name": "LineWidth",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Width of the lines: one, or one per tag."
        },
        {
          "Name": "LineStyle",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Style of the lines."
        },
        {
          "Name": "Visible",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Show the elements."
        }
      ],
      "Outputs": [],
      "Signature": "set_style(obj, sr_tag, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/set_style.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:UnknownTag",
        "GUILDA:GraphBase:StyleValue",
        "GUILDA:GraphBase:StyleNotApplicable"
      ],
      "Summary": "Set the appearance of the elements with the given tags.",
      "Desc": "Each option writes the vector property of the kind of each element (see\nstyle_properties of the subclass and tab_element), so G.set_style(\"B001\", Color=\"r\")\nand setting the row of B001 in the color vector are the same; only the changed elements\nare drawn again. An element kind that has no such option is passed over when another\nelement with the same tag has it (e.g. the arrows that share the tag of their node); if\nnone of the elements of a tag has the option, it is an error that names the kinds and\ntheir options. An unknown tag is an error.\n\n- `Color`: a color name, \"#RRGGBB\" or an RGB triplet.\n- `Label`: one text, or one per tag.\n- `MarkerSize`, `LineWidth`: one value, or one per tag.\n- `Marker`, `LineStyle`, `Visible`: one value for all tags.",
      "SeeAlso": [],
      "Examples": "```matlab\nG = net.plot_spring_model();\nG.set_style([\"B001\", \"B002\"], Color=\"r\", MarkerSize=20);\nG.set_style(\"B003\", Label=\"load\", Visible=true);\nG.set_style([\"B001\", \"B002\", \"B003\"], MarkerSize=[10 15 20]);\n```",
      "Deprecated": ""
    },
    {
      "Name": "set_data",
      "Defining": "GraphBase",
      "Group": "set",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sct_data"
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
          "Name": "sct_data",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Data of the graph (see the constructor of the subclass)."
        }
      ],
      "Outputs": [],
      "Signature": "set_data(obj, sct_data)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/set_data.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Replace the data of the graph and draw it again.",
      "Desc": "sct_data has the same contract as the data of the constructor of the subclass. The\nappearance set by set_style or by the vector properties is kept for the elements that\nare still there (the same tag and kind); new elements get the defaults of the data. The\nsample shown is the one nearest to the time shown before. The selection keeps the tags\nthat are still there. The defaults of reset_style of an element that was there stay\nthose of the data it came with. The linked graphs do not move. The panel of\nshow_controls stays. The slider of the playback bar takes the new samples; the bar\nappears or goes when the number of samples crosses two.",
      "SeeAlso": [],
      "Examples": "```matlab\nG = res1.plot_spring_model();\nG.set_style(\"B001\", Color=\"r\");\nres2 = net.simulate(\"fault2\", Time=[0, 5]);\nsct  = res2.plot_spring_model(Parent=axes(figure(\"Visible\", \"off\"))).sct_data;\nG.set_data(sct);                      % B001 stays red\n```",
      "Deprecated": ""
    },
    {
      "Name": "set_time",
      "Defining": "GraphBase",
      "Group": "set",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "t"
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
          "Name": "t",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Time to show [s], or the value of a sample named by the data (e.g. a step)."
        }
      ],
      "Outputs": [],
      "Signature": "set_time(obj, t)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/set_time.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:NoAxes"
      ],
      "Summary": "Show the sample nearest to time t, in this graph and in the graphs linked to it.",
      "Desc": "t is a time in seconds, or for samples named by the data (s_sampleName, e.g. \"Step\") the\nvalue of a sample in the same units as rv_t (e.g. a step number).\n\nEach linked graph shows the sample nearest to t of its own times. The links are followed\nthrough (a graph linked to a linked graph moves too), and every graph is drawn once, so\nlinks in a ring do not loop. A linked graph whose axes were deleted is skipped. The\nplayback bar of every graph drawn shows its sample.\n\nAfter all of them are drawn, each graph drawn raises TimeChanged and calls its\nTimeChangedFcn as fcn(G, data), with data a GraphTimeEventData (Time and Index of the\nsample it shows), in the order they were drawn. While these callbacks run, the graphs\nof this set_time are fixed: a set_time called from a callback (on any graph) leaves them\nas they are and raises nothing on them, as the links draw each graph once, so a callback\nthat moves a linked graph does not loop. Other graphs move and raise TimeChanged as usual.",
      "SeeAlso": [],
      "Examples": "```matlab\nG = res.plot_spring_model();\nG.TimeChangedFcn = @(G, data) title(G.ax, \"sample \" + data.Index);\nG.set_time(1.2);\n```",
      "Deprecated": ""
    },
    {
      "Name": "sample_text",
      "Defining": "GraphBase",
      "Group": "sample",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "k",
        "s_format"
      ],
      "OutputNames": [
        "s"
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
          "Name": "k",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Index of the sample."
        },
        {
          "Name": "s_format",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Format of the time (sprintf), used when the data names no samples."
        }
      ],
      "Outputs": [
        {
          "Name": "s",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Text of the sample."
        }
      ],
      "Signature": "s = sample_text(obj, k, s_format)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/sample_text.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Text of sample k: the text of the data, else the sample name and value, else the time.",
      "Desc": "With sv_sampleText of the data, its entry k. Else, with a sample name (e.g. \"Step\"), the\nname and the value of the sample (\"Step 12\"). Else the time written by\nsprintf(s_format, rv_t(k)) (e.g. \"t = %.2f s\").",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "load_sample_label",
      "Defining": "GraphBase",
      "Group": "load",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sct_data"
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
          "Name": "sct_data",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Data of the graph (see the class help of the subclass)."
        }
      ],
      "Outputs": [],
      "Signature": "load_sample_label(obj, sct_data)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/load_sample_label.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:SampleLabel"
      ],
      "Summary": "Read the optional sample name and per-sample text of the data (after rv_t is set).",
      "Desc": "Called by load_data of a subclass once rv_t holds the samples of the new data. The\nfields of sct_data are\n\n- `s_sampleName` (optional, default \"\"): name of the samples, e.g. \"Step\" when the\n  samples are the steps of a continuation power flow; \"\" means time in seconds.\n- `sv_sampleText` (optional, 1 x n_t): the text shown for each sample, e.g.\n  \"Step 12 (λ = 0.734)\"; empty for the default text (see sample_text).\n\nWithout these fields the samples are times, as before.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "prepare_frame",
      "Defining": "GraphBase",
      "Group": "prepare",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "r_dt"
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
          "Name": "r_dt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time between frames, or NaN after the last frame."
        }
      ],
      "Outputs": [],
      "Signature": "prepare_frame(obj, r_dt)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/prepare_frame.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Prepare the next frame of export_video: nothing in the base class.",
      "Desc": "export_video calls it before each frame with the time between frames r_dt [s]\n(1/FrameRate), and once with NaN after the last frame (also when the export stops with\nan error). A subclass that moves something by real time (e.g. a flow animation driven\nby a timer) overrides it to advance by r_dt and to restore its state on NaN.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "click_element",
      "Defining": "GraphBase",
      "Group": "click",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "i_row"
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
          "Name": "i_row",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Row of the element in tab_element."
        }
      ],
      "Outputs": [],
      "Signature": "click_element(obj, i_row)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/click_element.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Report a click on an element: raise ElementClicked and call ElementClickedFcn.",
      "Desc": "The subclasses call it from the ButtonDownFcn (or another hit test) of the graphics\nobjects of each element, with the row of the element in tab_element.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "make_axes",
      "Defining": "GraphBase",
      "Group": "make",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "h_parent",
        "n_panel",
        "rv_grid"
      ],
      "OutputNames": [
        "hv_ax"
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
          "Name": "h_parent",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Container or axes; [] for a new figure."
        },
        {
          "Name": "n_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "1",
          "Required": false,
          "Unit": "",
          "Description": "Number of panels (axes)."
        },
        {
          "Name": "rv_grid",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "[n_panel 1]",
          "Required": false,
          "Unit": "",
          "Description": "Rows and columns of the tiled layout."
        }
      ],
      "Outputs": [
        {
          "Name": "hv_ax",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Axes of the panels. <@Type> matlab.graphics.axis.Axes"
        }
      ],
      "Signature": "hv_ax = make_axes(obj, h_parent, n_panel, rv_grid)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/make_axes.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:GraphBase:GridSize",
        "GUILDA:GraphBase:ParentNeedsContainer",
        "GUILDA:GraphBase:ParentType"
      ],
      "Summary": "Axes of the graph: n_panel new axes in a tiled layout in a container, or the axes given.",
      "Desc": "h_parent is\n\n- empty: a new figure;\n- a container (figure, uifigure, uipanel, uitab or uigridlayout): a new tiledlayout of\n  rv_grid(1) rows and rv_grid(2) columns (default n_panel x 1) is made in it, and the\n  n_panel axes fill its tiles row by row (tiles after the last panel stay empty). A\n  uigridlayout does not take a tiledlayout, so a borderless uipanel is put in its next\n  free cell first and the tiledlayout goes in it; to choose the cell, set Layout.Row and\n  Layout.Column of that panel (G.ax(1).Parent.Parent) afterwards. Other contents of the\n  container stay.\n- an axes or uiaxes (single-panel graphs only): the graph draws into it directly. A\n  graph with several panels stops with GUILDA:GraphBase:ParentNeedsContainer.\n\nbuild calls it with the panel count and the grid of the subclass. A grid with fewer tiles\nthan panels is an error (GUILDA:GraphBase:GridSize).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build",
      "Defining": "GraphBase",
      "Group": "Other",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "opt",
        "n_panel",
        "rv_grid"
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
          "Name": "opt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name-Value options of the constructor of the subclass."
        },
        {
          "Name": "n_panel",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "1",
          "Required": false,
          "Unit": "",
          "Description": "Number of panels of the graph."
        },
        {
          "Name": "rv_grid",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [
            "mustBeInteger",
            "mustBePositive"
          ],
          "Default": "[n_panel 1]",
          "Required": false,
          "Unit": "",
          "Description": "Rows and columns of the tiles (at least n_panel tiles)."
        }
      ],
      "Outputs": [],
      "Signature": "build(obj, opt, n_panel, rv_grid)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/build.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Set the axes and the options, draw the scene and show the first sample.",
      "Desc": "Called by the constructor of a subclass after load_data. The axes come from\nmake_axes(opt.Parent, n_panel, rv_grid): a container (figure, uifigure, uipanel, uitab,\nuigridlayout) gets a tiled layout of rv_grid (n_row x n_col, default one column) with\nn_panel axes filled row by row, an axes or uiaxes is used directly (single-panel graphs\nonly), and empty means a new figure. The appearance vectors at this\npoint are kept as the defaults of reset_style. The other fields of opt are copied to the\nproperties of the same name.\n\nThe graph lives as long as its axes: a listener on ax(1) holds it in a containers.Map\nand empties the map when the axes are destroyed. The graphics callbacks of the\nsubclasses hold the graph only by a matlab.lang.WeakReference (a strong reference in a\ncallback makes savefig recurse), so a graph whose output is not taken keeps working, and\ndeleting its figure frees it. The listener is not saved with the figure. A listener that\ncaptured the graph directly would not free it (graph -> axes -> listener -> graph).\n\nA graph with samples to play (has_playback) gets its playback bar (refresh_bar); the\ntimer of its playback is stopped and deleted when the graph is deleted.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "range_map",
      "Defining": "GraphBase",
      "Group": "range",
      "Access": "protected",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "rv_v",
        "rv_range",
        "rv_lim"
      ],
      "OutputNames": [
        "rv_w"
      ],
      "Arguments": [
        {
          "Name": "rv_v",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Values of the elements at the sample shown."
        },
        {
          "Name": "rv_range",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Range [a b] of the result."
        },
        {
          "Name": "rv_lim",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Scale [vmin vmax] over all samples ([NaN NaN]: none)."
        }
      ],
      "Outputs": [
        {
          "Name": "rv_w",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Mapped values, in [a b]."
        }
      ],
      "Signature": "rv_w = GraphBase.range_map(rv_v, rv_range, rv_lim)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/range_map.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Map values linearly from the scale [vmin vmax] onto the range [a b] (sizes and widths in pt).",
      "Desc": "rv_lim is the scale chosen by the caller (for example the smallest and largest finite\nvalue of the quantity over all its samples, or the smallest value and the 95th\npercentile), or [NaN NaN] when there is none. A value is mapped to\na + (b - a)*(v - vmin)/(vmax - vmin). With a [NaN NaN] scale every value gives (a + b)/2;\nwith a scale of one value (vmax - vmin <= 1e-12*max(|vmin|, |vmax|, 1)) every finite value\ngives (a + b)/2. A NaN value gives a. A value outside the scale is kept in [a b]. For\nexample, the values [0; 5; 10; NaN] with the range [1 4] and the scale [0 10] give\n[1; 2.5; 4; 1].",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "write_frame",
      "Defining": "GraphBase",
      "Group": "write",
      "Access": "protected",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "vw",
        "h_capture",
        "iv_size",
        "n_repeat"
      ],
      "OutputNames": [
        "iv_size"
      ],
      "Arguments": [
        {
          "Name": "vw",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "VideoWriter",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Open video."
        },
        {
          "Name": "h_capture",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Figure or axes to record."
        },
        {
          "Name": "iv_size",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "px",
          "Description": "Height and width of the frames; [] at the first frame."
        },
        {
          "Name": "n_repeat",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Number of times the frame is written."
        }
      ],
      "Outputs": [
        {
          "Name": "iv_size",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "px",
          "Description": "Height and width of the frames."
        }
      ],
      "Signature": "iv_size = GraphBase.write_frame(vw, h_capture, iv_size, n_repeat)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/write_frame.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Write the current picture of a figure or axes to an open video n_repeat times.",
      "Desc": "The size of the first frame, cut to even numbers, is kept for all frames: a frame is\ncut or padded with white to it.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "resolve_overlap",
      "Defining": "GraphBase",
      "Group": "resolve",
      "Access": "protected",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "hv_move",
        "hv_fix",
        "n_iter",
        "r_pad",
        "rm_box"
      ],
      "OutputNames": [
        "rm_box"
      ],
      "Arguments": [
        {
          "Name": "hv_move",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Text objects that may move."
        },
        {
          "Name": "hv_fix",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Text objects that stay."
        },
        {
          "Name": "n_iter",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Largest number of passes."
        },
        {
          "Name": "r_pad",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Gap added between the boxes."
        },
        {
          "Name": "rm_box",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,4)",
          "Class": "double",
          "Validators": [],
          "Default": "zeros(0, 4)",
          "Required": false,
          "Unit": "",
          "Description": "Boxes [x y w h] of [hv_move; hv_fix]; empty: measured."
        }
      ],
      "Outputs": [
        {
          "Name": "rm_box",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,4)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Boxes after the moves (NaN for the texts not shown)."
        }
      ],
      "Signature": "rm_box = GraphBase.resolve_overlap(hv_move, hv_fix, n_iter, r_pad, rm_box)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/resolve_overlap.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Push overlapping text objects apart vertically (2D).",
      "Desc": "The extents of the texts in hv_move are compared with each other and with those of\nhv_fix; overlapping texts of hv_move move up or down until no box overlaps or n_iter\npasses are done. The texts of hv_fix do not move. The boxes are measured once (a\nvertical move shifts a box by as much) and the texts are moved at the end. rm_box, when\ngiven, holds the boxes of [hv_move; hv_fix] instead of their measured Extent (a caller\nthat computed them for other limits: NaN rows are skipped); the boxes after the moves\nare returned.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "place_label",
      "Defining": "GraphBase",
      "Group": "place",
      "Access": "protected",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "h_text",
        "rv_start",
        "rv_direction",
        "r_length",
        "s_text",
        "r_value"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "h_text",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Text object."
        },
        {
          "Name": "rv_start",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Start point of the arrow, (x, y) or (x, y, z)."
        },
        {
          "Name": "rv_direction",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Unit vector towards the tip."
        },
        {
          "Name": "r_length",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Length of the arrow."
        },
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
          "Description": "Text of the label."
        },
        {
          "Name": "r_value",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Value shown; |value| < 5e-3 hides the label."
        }
      ],
      "Outputs": [],
      "Signature": "GraphBase.place_label(h_text, rv_start, rv_direction, r_length, s_text, r_value)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/place_label.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Put a value label just beyond the tip of an arrow; hide it when the value is about zero.",
      "Desc": "In 2D the alignment follows the direction so that the text stays clear of the arrow; in\n3D the text is centred.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_arrow",
      "Defining": "GraphBase",
      "Group": "set",
      "Access": "protected",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "hv_arrow",
        "rv_start",
        "rv_vector",
        "r_head"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "hv_arrow",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Line of the shaft and patch of the head."
        },
        {
          "Name": "rv_start",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Start point (x, y) or (x, y, z)."
        },
        {
          "Name": "rv_vector",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Arrow vector, the same size as rv_start."
        },
        {
          "Name": "r_head",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Length of the head."
        }
      ],
      "Outputs": [],
      "Signature": "GraphBase.set_arrow(hv_arrow, rv_start, rv_vector, r_head)",
      "File": "_GUILDAsystem/_auxiliary/@GraphBase/set_arrow.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Move an arrow (a line and a triangular head) from a start point along a vector.",
      "Desc": "Works in 2D and 3D (the size of rv_start). An arrow shorter than 1e-6 (or NaN) is hidden.\nThe head is r_head long, or 0.6 of the arrow for a short one.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    }
  ],
  "events": [
    "ElementClicked",
    "TimeChanged"
  ],
  "enumeration": [],
  "validation": {
    "Warnings": [],
    "Errors": []
  }
};
})(window);
