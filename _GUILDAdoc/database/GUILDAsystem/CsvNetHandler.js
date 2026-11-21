(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["CsvNetHandler"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "CsvNetHandler",
  "properties": [],
  "methods": [
    {
      "Name": "export",
      "Defining": "CsvNetHandler",
      "Group": "Other",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "net",
        "ModelName",
        "opt"
      ],
      "OutputNames": [
        "path"
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
          "Description": "Network to write."
        },
        {
          "Name": "ModelName",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeValidVariableName"
          ],
          "Default": "\"PowerNetwork\"+string(datetime(\"now\",\"Format\",\"uuuuMMdd_HHmmss\"))",
          "Required": false,
          "Unit": "",
          "Description": "Class name of the model."
        },
        {
          "Name": "version",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "1",
          "Required": false,
          "Unit": "",
          "Description": "Constant ver of the class file."
        },
        {
          "Name": "savepath",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeFolder"
          ],
          "Default": "uigetdir(fullfile(GUILDA.pwd,\"_GUILDAexport\"), \"Select folder to save CSV folder\")",
          "Required": false,
          "Unit": "",
          "Description": "Parent folder of @ModelName."
        },
        {
          "Name": "Overwrite",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false",
          "Required": false,
          "Unit": "",
          "Description": "Replace an existing folder."
        }
      ],
      "Outputs": [
        {
          "Name": "path",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The written model folder."
        }
      ],
      "Signature": "path = CsvNetHandler.export(net, ModelName, Name=Value)",
      "File": "_GUILDAsystem/_VersionSupport/@CsvNetHandler/export.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Write a network to a CSV model folder (v3 wrapper of net.export).",
      "Desc": "v3 entry point of the CSV export (deprecated: warns GUILDA:Deprecated:CsvNetHandlerExport).\nWrites the folder <savepath>/@<ModelName> with the class file <ModelName>.m by\nnet.export(fullfile(savepath, \"@\"+ModelName), Overwrite=Overwrite). Without\nsavepath a folder dialog opens (as in v3); version is the constant ver of the class file.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": "Use net.export(fullfile(savepath, \"@\"+ModelName)) instead.\n\nSee also PowerNetwork.export"
    },
    {
      "Name": "import",
      "Defining": "CsvNetHandler",
      "Group": "Other",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "path",
        "net",
        "opt"
      ],
      "OutputNames": [
        "net"
      ],
      "Arguments": [
        {
          "Name": "path",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Model folder."
        },
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
          "Description": "Network to add the model to."
        },
        {
          "Name": "Initialize",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Run net.initialize() afterwards."
        }
      ],
      "Outputs": [
        {
          "Name": "net",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The built network."
        }
      ],
      "Signature": "net = CsvNetHandler.import(path, net, Name=Value)",
      "File": "_GUILDAsystem/_VersionSupport/@CsvNetHandler/import.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Build a network from a CSV model folder (v3 wrapper of PowerNetwork.import).",
      "Desc": "v3 entry point of the CSV import (deprecated: warns GUILDA:Deprecated:CsvNetHandlerImport).\nCalls PowerNetwork.import(path, Network=net, Initialize=opt.Initialize); without net\na new network is built.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": "Use PowerNetwork.import(path, Network=net) instead.\n\nSee also PowerNetwork.import"
    },
    {
      "Name": "CsvNetHandler",
      "Defining": "CsvNetHandler",
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
      "Signature": "obj = CsvNetHandler()",
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
