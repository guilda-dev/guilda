(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["branch.T"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "branch.T",
  "properties": [
    {
      "Name": "header",
      "Defining": "branch.T",
      "Group": "Identification",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"EL\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+branch/@T/T.m",
      "Line": 38,
      "Summary": "Tag prefix of this branch type (\"EL\" for lines).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "key",
      "Defining": "branch.T",
      "Group": "Identification",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"T\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAobject/+branch/@T/T.m",
      "Line": 39,
      "Summary": "Type name used by PowerNetwork.add_branch.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_PowerNetwork",
      "Defining": "Branch",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "PowerNetwork",
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
      "File": "_GUILDAsystem/@Branch/Branch.m",
      "Line": 72,
      "Summary": "PowerNetwork the branch belongs to (set by add_branch).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "PowerNetwork",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_Bus",
      "Defining": "Branch",
      "Group": "Layer Structure",
      "GetAccess": "public",
      "SetAccess": "PowerNetwork",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "cell(0,1)",
      "Validation": {
        "Class": "cell",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/@Branch/Branch.m",
      "Line": 73,
      "Summary": "End buses {from; to}: the row and column order of the admittance matrix.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "cell of Bus (2x1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "cv_Vequilibrium",
      "Defining": "Branch",
      "Group": "Parameter",
      "GetAccess": "public",
      "SetAccess": "public",
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
      "Unit": "pu",
      "File": "_GUILDAsystem/@Branch/Branch.m",
      "Line": 76,
      "Summary": "Voltage phasors of the end buses at the equilibrium.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "cv_Iequilibrium",
      "Defining": "Branch",
      "Group": "Parameter",
      "GetAccess": "public",
      "SetAccess": "public",
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
      "Unit": "pu",
      "File": "_GUILDAsystem/@Branch/Branch.m",
      "Line": 77,
      "Summary": "Currents into the branch at its ends at the equilibrium: get_admittance_matrix() * cv_Vequilibrium.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "parent",
      "Defining": "Branch",
      "Group": "Layer Structure",
      "GetAccess": "protected",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/@Branch/Branch.m",
      "Line": 81,
      "Summary": "Parent in the layer structure: the network.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "children",
      "Defining": "Branch",
      "Group": "Layer Structure",
      "GetAccess": "protected",
      "SetAccess": "protected",
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
      "File": "_GUILDAsystem/@Branch/Branch.m",
      "Line": 82,
      "Summary": "Children in the layer structure: the Parameter objects.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_parameter",
      "Defining": "PowerSystemModel",
      "Group": "Parameter",
      "GetAccess": "public",
      "SetAccess": "public",
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
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 18,
      "Summary": "Parameter table: the a_Parameter tables side by side; writing it writes the changed parameters.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_Parameter",
      "Defining": "PowerSystemModel",
      "Group": "Parameter",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "cell(0,1)",
      "Validation": {
        "Class": "cell",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 21,
      "Summary": "Parameter containers, one per column of tab_parameter (column name: the s_tag of the container).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "Parameter cell array (Nx1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_parameterCache",
      "Defining": "PowerSystemModel",
      "Group": "Parameter",
      "GetAccess": "LayerPackage",
      "SetAccess": "LayerPackage",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": true,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/PowerSystemModel.m",
      "Line": 24,
      "Summary": "tab_parameter built by its getter; [] when an edit (a store or a rename of a container, a new a_Parameter) made it out of date.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_stale",
      "Defining": "LayerPackage",
      "Group": "Stale state",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct()",
      "Validation": {
        "Class": "struct",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/LayerPackage.m",
      "Line": 67,
      "Summary": "Messages per stale tag of the class (string column each; empty: up to date). See the class help.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_notInitialized",
      "Defining": "LayerPackage",
      "Group": "Stale state",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"initialize has not been run\"",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/LayerPackage.m",
      "Line": 70,
      "Summary": "Initial message of every stale tag.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_tag",
      "Defining": "LayerPackage",
      "Group": "Tag",
      "GetAccess": "public",
      "SetAccess": "public",
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
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/LayerPackage.m",
      "Line": 75,
      "Summary": "User-defined tag of the layer: a valid variable name (isvarname), unique among its siblings (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "string",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "T",
      "Defining": "branch.T",
      "Group": "Constructor",
      "Access": "PowerNetwork",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "index",
        "opt"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "index",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Number part of the tag, e.g. \"001\"."
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
          "Description": "Branch settings of add_branch."
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
          "Description": "New branch object."
        }
      ],
      "Signature": "obj = branch.T(index, opt)",
      "File": "_GUILDAobject/+branch/@T/T.m",
      "Line": 43,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create the branch; called through `PowerNetwork.add_branch`.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "get_admittance_matrix",
      "Defining": "branch.T",
      "Group": "get",
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
        "Ymat"
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
          "Name": "Status",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Status, [\"close\",\"3LG\",\"6LG\",\"3open\",\"6open\"])"
          ],
          "Default": "\"close\"",
          "Required": false,
          "Unit": "",
          "Description": "State of the branch."
        },
        {
          "Name": "Point",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "NaN",
          "Required": false,
          "Unit": "",
          "Description": "Fault position from the from end (0) to the to end (1), 0 < Point < 1; used only by \"3LG\" and \"6LG\"."
        }
      ],
      "Outputs": [
        {
          "Name": "Ymat",
          "Kind": "Output",
          "Struct": "",
          "Size": "(2,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "2-by-2 complex admittance matrix (from, to)."
        }
      ],
      "Signature": "Ymat = get_admittance_matrix(obj, Name=Value)",
      "File": "_GUILDAobject/+branch/@T/get_admittance_matrix.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "Branch",
      "Throws": [
        "GUILDA:Branch:SingleCircuit",
        "GUILDA:Branch:InvalidPoint"
      ],
      "Summary": "Return the 2-by-2 admittance matrix of the line in a state.",
      "Desc": "Rows and columns are ordered (from bus, to bus). The midpoint node\nis eliminated (Kron reduction).\n\nStatus \"close\" (default) is the T circuit with Y = 2y (y = 1/(R+jX)) on each half and\nb = jC at the midpoint: [Y(Y+b), -Y^2; -Y^2, (Y+b)Y]/(2Y+b). With n circuits\n(tab_parameter.dynamics.circuit), \"6open\" is the zero matrix and \"3open\" (n-1)/n of the\nclosed matrix. A fault at Point = p (q = 1-p) splits the circuit into two T sections of\nlengths p and q (each with half of its series impedance on each side of its midpoint\nshunt), and grounding the fault point leaves each end with the section behind it\ngrounded: all circuits (\"6LG\") give diag(D(p), D(q)), D(l) = (2y/l)(2y/l + j*l*C)/(4y/l\n+ j*l*C), one circuit 1/n of it, added to the closed (n-1) circuits for \"3LG\". Point is\nused only by \"3LG\" and \"6LG\"; the other states ignore it.",
      "SeeAlso": [],
      "Examples": "```matlab\nY  = br.get_admittance_matrix();                          % closed\nYf = br.get_admittance_matrix(Status=\"6LG\", Point=0.5);   % all circuits grounded at the middle\n```\n\nSee also Branch, PowerNetwork.get_admittance_matrix",
      "Deprecated": ""
    },
    {
      "Name": "get_opf_condition",
      "Defining": "Branch",
      "Group": "OPF",
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
        "varargout"
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
          "Name": "Display",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Print the table."
        }
      ],
      "Outputs": [
        {
          "Name": "varargout",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "tab_branch: one-row table of the branch."
        }
      ],
      "Signature": "varargout = get_opf_condition(obj, Name=Value)",
      "File": "_GUILDAsystem/@Branch/get_opf_condition.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the optimal-power-flow condition of the branch.",
      "Desc": "The table holds exactly what net.calculate_optimal_powerflow and net.build_opf_problem\nuse for this branch (one row, row name = tag):\n\n- From, To: tags of the end buses (a_Bus{1}, a_Bus{2}).\n- Y: 2x2 admittance matrix [pu] of get_admittance_matrix (a 1x2x2 page).\n- X, tap, phase: tab_parameter.dynamics, for \"DC OPF\"; tap 1 and phase 0 when absent,\n  NaN or a zero tap.\n- Pmax, Qmax, Vargmax, Imax, Smax: tab_parameter.operation.\n\nWith Display=true (default) the table is printed under the heading \"Branch\", without\nthe column Y (the returned table keeps it); with no output nothing is returned.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.a_Branch{1}.get_opf_condition();                   % print the table\ntab_branch = net.a_Branch{1}.get_opf_condition(Display=false);\nY = squeeze(tab_branch.Y(1,:,:));                      % 2x2 admittance matrix\n```\n\nSee also PowerNetwork.get_opf_condition, Bus.get_opf_condition",
      "Deprecated": ""
    },
    {
      "Name": "struct",
      "Defining": "Branch",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "l_disp",
        "s_header",
        "sct_visited"
      ],
      "OutputNames": [
        "out",
        "sct_visited"
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
          "Name": "l_disp",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "true",
          "Required": false,
          "Unit": "",
          "Description": "Print the properties that cannot be read or copied."
        },
        {
          "Name": "s_header",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"net\"",
          "Required": false,
          "Unit": "",
          "Description": "Path of this layer in the struct, used for messages and repeated objects."
        },
        {
          "Name": "sct_visited",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "",
          "Validators": [
            "mustBeA(sct_visited,\"struct\")"
          ],
          "Default": "struct(\"a_obj\",{cell(0,1)}, \"sv_path\",strings(0,1))",
          "Required": false,
          "Unit": "",
          "Description": "Layers already stored (a_obj) and their paths (sv_path), used by the recursion."
        }
      ],
      "Outputs": [
        {
          "Name": "out",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Nested struct of the branch with the field cm_Y, or its path when stored before."
        },
        {
          "Name": "sct_visited",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Layers stored so far and their paths."
        }
      ],
      "Signature": "[out, sct_visited] = struct(obj, l_disp, s_header, sct_visited)",
      "File": "_GUILDAsystem/@Branch/struct.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Convert the branch to a nested struct, with its admittance matrix.",
      "Desc": "The struct of LayerPackage.struct with one more field, `cm_Y`: the 2x2 complex\nadmittance matrix of get_admittance_matrix, in the order of a_Bus (from, to). A network\nsnapshot (struct(net, false)) therefore holds the admittance of every branch, whatever\nits class, and ResultPF computes the branch flows from it. A branch reached a second\ntime is the path where it was first stored, as in LayerPackage.struct.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\ns   = struct(net.a_Branch{1});\ns.cm_Y                         % 2x2 complex admittance matrix [pu]\n```\n\nSee also LayerPackage.struct, Branch.get_admittance_matrix, ResultPF",
      "Deprecated": ""
    },
    {
      "Name": "initialize",
      "Defining": "Branch",
      "Group": "Called by analyses",
      "Access": "PowerNetwork",
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
      "Signature": "initialize(obj)",
      "File": "_GUILDAsystem/@Branch/initialize.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Nothing to bring up to date (PowerNetwork.initialize): a branch has no states and no",
      "Desc": "function handles, and its parameters enter the power flow.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "gui_content",
      "Defining": "Branch",
      "Group": "gui",
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
        "sct_page"
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
          "Name": "sct_page",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Pages: fields s_title, s_type and content."
        }
      ],
      "Signature": "sct_page = gui_content(obj)",
      "File": "_GUILDAsystem/@Branch/gui_content.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "LayerPackage",
      "Throws": [],
      "Summary": "Pages of the GUI of a branch: \"Equilibrium\", then the pages of PowerSystemModel.",
      "Desc": "\"Equilibrium\" (\"table\") has one row per end (from, to) and the columns Bus (tag of the\nend bus), V (`cv_Vequilibrium`) and I (`cv_Iequilibrium`). The table has no rows when\nthe branch has no end buses (removed from the network).",
      "SeeAlso": [
        "LayerPackage.launch_gui",
        "LayerPackage.gui_content"
      ],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "doc",
      "Defining": "PowerSystemModel",
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
          "Size": "(1,1)",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Model whose class page is opened."
        }
      ],
      "Outputs": [],
      "Signature": "doc(obj)",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/doc.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Open the class reference page of the model's class.",
      "Desc": "Opens the GUILDA class reference (English page) of class(obj) in the browser, as\nGUILDA.doc(\"class\", class(obj)). doc with a class name (doc PowerNetwork) is\nMATLAB's doc.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.doc()                          % page of the network class\nnet.a_Bus{1}.doc()                 % page of the class of the first bus\nnet.a_Bus{1}.a_Component{1}.doc()  % page of the class of its component\ndoc(net)                           % same as net.doc()\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_sys",
      "Defining": "PowerSystemModel",
      "Group": "Linearization",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "point",
        "opt"
      ],
      "OutputNames": [
        "sys",
        "flag",
        "output"
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
          "Name": "point",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Point: [] (the equilibrium), a vector in the order of get_variable_map(), a matrix (one point per column), {sim, rv_t} or {sim, rv_t, Side}."
        },
        {
          "Name": "Type",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Type, [\"ODE\",\"DAE\"])"
          ],
          "Default": "GUILDA.config(\"ApproximateLinearization\", \"Type\")",
          "Required": false,
          "Unit": "",
          "Description": "Model of the network: \"ODE\" (the bus voltages eliminated) or \"DAE\" (the connected model)."
        },
        {
          "Name": "Port",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Port, [\"PI\",\"PQ\",\"I\"])"
          ],
          "Default": "GUILDA.config(\"ApproximateLinearization\", \"Port\")",
          "Required": false,
          "Unit": "",
          "Description": "Bus port of \"DAE\" (v, w): \"PI\" ([theta,V], [P,Q/V]), \"PQ\" ([theta,rho], [P,Q]) or \"I\" ([Vre,Vim], [-Iim,Ire])."
        },
        {
          "Name": "PlotFcn",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "GUILDA.config(\"ApproximateLinearization\", \"PlotFcn\")",
          "Required": false,
          "Unit": "",
          "Description": "Live display: \"none\" (checked by tools.check_plotfcn; draw the eigenvalue map with result.plot_eigenvalue())."
        },
        {
          "Name": "Input",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Inputs of the model: \"u\" or Labels (see ResultLIN.get_ss). Default: all inputs."
        },
        {
          "Name": "Output",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Outputs of the model: \"x\", \"V\", \"I\", \"y\" or names (see ResultLIN.get_ss). Default: as in get_ss."
        },
        {
          "Name": "Format",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Format, [\"GUILDAorigin\",\"struct\",\"ss\"])"
          ],
          "Default": "\"GUILDAorigin\"",
          "Required": false,
          "Unit": "",
          "Description": "Form of sys: GUILDAorigin (a ResultLIN), struct or ss (dss)."
        },
        {
          "Name": "Form",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Form, [\"descriptor\",\"absorbed\",\"hessian\"])"
          ],
          "Default": "\"descriptor\"",
          "Required": false,
          "Unit": "",
          "Description": "View of A ... E: \"descriptor\" (E holds the time constants), \"absorbed\" (E^-1 in A and B) or \"hessian\" (the energy-function form; network, Port PI or PQ)."
        }
      ],
      "Outputs": [
        {
          "Name": "sys",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Linear model in the form of Format, with state, input and output names (1 x n_t struct or ss array for several sections)."
        },
        {
          "Name": "flag",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True when the result is usable: all entries are finite and Avv is invertible, in every section."
        },
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "message, s_issue (\"\", \"NotFinite\" or \"SingularAvv\"), l_equilibrium, n_x, n_v, n_u, rcond_Avv, sv_faultBus, s_layer; per section lv_flag, sv_issue, sv_message, rv_rcond_Avv; result (the ResultLIN)."
        }
      ],
      "Signature": "[sys, flag, output] = get_sys(obj, point, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/get_sys.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:PowerSystemModel:NoLinearModel",
        "GUILDA:PowerSystemModel:HessianNetworkOnly",
        "GUILDA:PowerSystemModel:HessianPort",
        "GUILDA:PowerSystemModel:InputEdited",
        "GUILDA:PowerSystemModel:Stale"
      ],
      "Summary": "Linearize the layer and return its linear model.",
      "Desc": "One method for every layer with a linear model: PowerNetwork, Bus, Component (with\nits local controllers), LocalController and GlobalController (Branch has none:\nGUILDA:PowerSystemModel:NoLinearModel). Each model object gives its own linear block\n(get_linear_matrix); get_sys takes the inputs and outputs of the layer (its port) from\nthe variable map, and SolverLIN.solve connects the blocks along it. The linearization needs no\ntoolbox, and the model is not changed.\n\n| Layer | Inputs | Outputs | Bus voltages |\n|---|---|---|---|\n| PowerNetwork | inputs u of the components | outputs y and yc | algebraic: 0 = Y v - I of the components, eliminated for Type \"ODE\" |\n| Bus, Component | V, u, uc | I, y, yc | inputs |\n| LocalController | V of its bus, its inputs | its outputs | inputs |\n| GlobalController | V of all buses, its inputs | its outputs | inputs |\n\nThe names are the Labels of the variable map of the layer (obj.get_variable_map); the\nstates follow its order. The current of a\ncomponent is the component tag with Ire, Iim; that of a bus the bus tag. An input is\nthe sum of its sources in the connection map plus the external input of that name.\n\npoint, the first argument, gives the point: [] (the equilibrium set by net.initialize,\nthe default), a vector of the variables of the layer in the order of the leading rows of\nobj.get_variable_map() (x, Vre, Vim, u, uc; for a controller x, Vre, Vim, uc), or\n{sim, t} (or {sim, t, \"before\"}) for the state of a simulation result at time t\n(PowerNetwork, Bus and Component).\nTime sections: {sim, rv_t} with several times, or a matrix with one point per column,\nlinearizes the layer at each of them; the result holds one section per time or column\n(ResultLIN.rv_t: the times, or 1:n for a matrix; ResultLIN.Index chooses the section),\nand flag is true only when every section is usable (output.lv_flag of each section). Every value of the point is used as given: the\ninputs u of the components and uc of the controllers, whether the connection map drives\nthem or holds them at a setpoint (Vref of an AVR, Pref of a governor). The outputs y and\nyc are evaluated at the point. The point sets the variables only: the\nadmittance matrix stays the one of the model, also inside a fault (reported with an\nINFO message and output.sv_faultBus).\n\nThe layer stops with GUILDA:PowerSystemModel:Stale when net.initialize() is needed: an\nedited dynamics always, an edited network, power flow or equilibrium when the point is the\nequilibrium; with GUILDA:PowerSystemModel:InputEdited when the inputs were edited.\nA point with NaN or Inf stops with GUILDA:SolverLIN:PointNotFinite, and a model that is\nnot finite at the point with GUILDA:SolverLIN:JacobianNotFinite.\n\nFormat chooses the form of sys: \"GUILDAorigin\" (default) is the ResultLIN of the\nlinearization, also when flag is false; its properties A, B, C, D, E, StateName,\nInputName and OutputName hold the model of its Type (the Type of the call) with the\nselected Input and Output. \"struct\" is a struct with these eight fields and \"ss\" a\ndescriptor state-space model (dss, Control System Toolbox): they stop with the error of\nResultLIN.get_ss when flag is false (except \"DAE\" with a singular Avv). With several\nsections, \"struct\" is a 1 x n_t struct array and \"ss\" an ss array (sys(:,:,k) is\nsection k). The ResultLIN of the network (Format \"GUILDAorigin\") keeps a snapshot of it,\nsct_network = struct(net, false).\n\nType chooses the model of the network: \"DAE\" is the connected model, with the bus\nvoltages as algebraic variables (E is singular on their rows), each bus written as the\nport of Port (see ResultLIN.get_ss); \"ODE\" is the model with the bus voltages eliminated (SolverLIN.reduce).\nThe result keeps the DAE, so res.Type switches between them later.\n\nForm chooses the view of A ... E (ResultLIN.Form): \"descriptor\" (default; E holds the\ntime constants), \"absorbed\" (E^-1 multiplied into the state rows) or \"hessian\", the\nenergy-function form of the network: get_sys calls get_hessian of every component, local\ncontroller and global controller at the point of each section, and SolverLIN.solve\nassembles E_h dz/dt = H z over z = [x; theta; V] with E_h = -blkdiag(inv(R), 0) and\nH = [Hxx Hxv; Hvx Hvv + Hvv_net] (see ResultLIN). A class without the form stops with\nits GUILDA:<layer>:HessianNotSupported (the Static AVR and governor have empty blocks).\n\"hessian\" needs the network (GUILDA:PowerSystemModel:HessianNetworkOnly) and Port \"PI\"\nor \"PQ\" (GUILDA:PowerSystemModel:HessianPort). The result keeps the descriptor DAE too.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = net.get_sys();                          % ResultLIN of the network (Type of GUILDA.setting)\neig(res.A, res.E)\nsct = net.get_sys(Type=\"DAE\", Format=\"struct\");\nresV = net.get_sys(Output=\"V\");               % bus voltages as outputs\nsys = net.a_Bus{1}.a_Component{1}.get_sys(Format=\"ss\");   % component, V to I\nres2 = net.get_sys({sim, 1.5});               % at a time of a simulation result\nres3 = net.get_sys(res.rv_point);             % at a vector in the order of net.get_variable_map()\nres4 = net.get_sys({sim, [0.5, 1, 2]});       % three time sections; res4.Index = 2 shows t = 1\nsct4 = net.get_sys({sim, [0.5, 1, 2]}, Format=\"struct\");   % 1 x 3 struct array\nresH = net.get_sys(Type=\"DAE\", Port=\"PI\", Form=\"hessian\");  % energy-function form\n```\n\nSee also ResultLIN, SolverLIN, PowerNetwork.get_variable_map",
      "Deprecated": ""
    },
    {
      "Name": "get_Hz",
      "Defining": "PowerSystemModel",
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
        "Hz"
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
          "Name": "Hz",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "Hz",
          "Description": "Nominal frequency."
        }
      ],
      "Signature": "Hz = get_Hz(obj)",
      "File": "_GUILDAsystem/_auxiliary/@PowerSystemModel/get_Hz.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Nominal frequency [Hz] of the network the model belongs to.",
      "Desc": "net.tab_parameter.base.Hz. This is the omega0 passed to the model functions (models multiply it by 2*pi).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "handle_edit",
      "Defining": "LayerPackage",
      "Group": "handle",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "a_layer",
        "tag",
        "log"
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
          "Description": "Layer on the path from the edited layer to the top."
        },
        {
          "Name": "a_layer",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Edited layer (the owner for a parameter edit)."
        },
        {
          "Name": "tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Kind of edit (see log_edit)."
        },
        {
          "Name": "log",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Message: tag of the edited layer, \": \", what was edited (see log_edit)."
        }
      ],
      "Outputs": [],
      "Signature": "handle_edit(obj, a_layer, tag, log)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/handle_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Hook for an edit of a_layer, called by log_edit on every layer from the edited",
      "Desc": "layer up to the top. Does nothing here; subclasses override it to append the message\nto their own stale tags (sct_stale).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "log_edit",
      "Defining": "LayerPackage",
      "Group": "log",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "log",
        "tag"
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
          "Description": "Edited layer (a Parameter container for a parameter edit)."
        },
        {
          "Name": "log",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "What was edited, with the values (e.g. \"edit D: 0.1 -> 0.2\")."
        },
        {
          "Name": "tag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Kind of edit: a parameter group (\"dynamics\", \"powerflow\", ...), \"Topology\", \"Slack\" or \"Tag\"."
        }
      ],
      "Outputs": [],
      "Signature": "log_edit(obj, log, tag)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/log_edit.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Report an edit of this layer to every layer up to the top.",
      "Desc": "Calls handle_edit(a_owner, tag, message) on the edited layer and on every layer\nabove it; a_owner is the edited layer (the owner for a Parameter container) and\nmessage is \"<tag of obj>: <log>\", or \"<container tag>/<owner tag>: <log>\" for a\nParameter container (e.g. \"dynamics/B001SG1: edit D: 2 -> 2.1\"). A generated tag\nalready contains the tags of the parents. Each layer appends the message to its own\nstale tags that the edit affects.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "launch_gui",
      "Defining": "LayerPackage",
      "Group": "launch",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "h_container",
        "opt"
      ],
      "OutputNames": [
        "h"
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
          "Name": "h_container",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container to fill: uifigure, uipanel, uitab or uigridlayout (default: a new uifigure)."
        },
        {
          "Name": "History",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "HistoryGUILDA",
          "Validators": [],
          "Default": "HistoryGUILDA(Echo=true)",
          "Required": false,
          "Unit": "",
          "Description": "Log that runs and records the actions; its root variable (net, bus, ...) is set when missing."
        }
      ],
      "Outputs": [
        {
          "Name": "h",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "DrawerModelGUI",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The GUI."
        }
      ],
      "Signature": "h = launch_gui(obj, h_container, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/launch_gui.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Show the model in a GUI: breadcrumb, class, tag, Docs button, stale state, child cards and tables.",
      "Desc": "With no container it opens a new uifigure; with a container (uifigure, uipanel, uitab or\nuigridlayout) it fills it, so that the GUI can be embedded in another app. The breadcrumb\nruns from the root to this model, and the cards show its children by kind; a click on\neither shows that model in the same container. The Docs button opens the reference page\nof the class. The add buttons and the Remove item of the card menus add and remove\nmodels (and the disturbances of a Scenario), and the parameter tables are editable; the\nabstract classes provide the other tables (gui_content), so a model class needs no GUI\ncode. A Scenario has no parameter tab, only its pages (Disturbances, Settings).\n\nEvery action runs as a line of MATLAB code in History (HistoryGUILDA.run), from the root\nvariable of the model tree (`net` for a network): the code is logged, and\n`h.history.get_script()` returns a script that repeats the actions. The default history\nprints each `>> code` in the Command Window. See DrawerModelGUI.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nh = net.a_Bus{1}.launch_gui();                % new window\nfig = uifigure();\np = uipanel(uigridlayout(fig, [1 1]));\nh = net.launch_gui(p);                        % embedded in a panel\nhist = HistoryGUILDA();\nh = net.launch_gui(History=hist);             % log the actions in hist\n```",
      "Deprecated": ""
    },
    {
      "Name": "disp_tree",
      "Defining": "LayerPackage",
      "Group": "disp",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sr_ignore"
      ],
      "OutputNames": [
        "varargout"
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
          "Description": "Root layer object."
        },
        {
          "Name": "sr_ignore",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "[\"Parameter\"]",
          "Required": false,
          "Unit": "",
          "Description": "Class names to ignore in output."
        }
      ],
      "Outputs": [
        {
          "Name": "varargout",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Hierarchy string (text) when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_tree(obj, sr_ignore)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/disp_tree.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Render the hierarchy tree with optional filtering.",
      "Desc": "Displays or returns a text tree of this layer and its descendants.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "string",
      "Defining": "LayerPackage",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "str"
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
          "Name": "str",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Tag string of the layer object."
        }
      ],
      "Signature": "str = string(obj)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/string.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Convert the layer object to a tag string.",
      "Desc": "Returns the tag string representation of this layer object.",
      "SeeAlso": [],
      "Examples": "```matlab\nstr = string(obj);\n```",
      "Deprecated": ""
    },
    {
      "Name": "table",
      "Defining": "LayerPackage",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
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
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Parameter table of the layer."
        }
      ],
      "Signature": "tab = table(obj)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/table.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Convert layer parameters into table format.",
      "Desc": "Returns the parameter table associated with this layer object.",
      "SeeAlso": [],
      "Examples": "```matlab\ntab = table(obj);\n```",
      "Deprecated": ""
    },
    {
      "Name": "attach_tag",
      "Defining": "LayerPackage",
      "Group": "attach",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sm_name_list"
      ],
      "OutputNames": [
        "out"
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
          "Description": "Target layer object."
        },
        {
          "Name": "sm_name_list",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Base names to be tagged."
        }
      ],
      "Outputs": [
        {
          "Name": "out",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Input names with layer tag suffix."
        }
      ],
      "Signature": "out = attach_tag(obj, sm_name_list)",
      "File": "_GUILDAsystem/_auxiliary/@LayerPackage/attach_tag.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Generate names with layer tag suffix.",
      "Desc": "Appends \"_\" and the tag of this layer to each input name. A generated tag already\ncontains the tags of the parents (B001SG1 on bus B001, B001SG1CA1 under it,\nPowerNetworkAGC1 on the network), which keeps the labels unique within a network.",
      "SeeAlso": [],
      "Examples": "```matlab\n>> net = network.Tutorial10bus();\n>> gen = net.a_Bus{1}.a_Component{1};\n>> gen.attach_tag([\"delta\", \"omega\"])\nans =\n    \"delta_B001SG1\"    \"omega_B001SG1\"\n```",
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
