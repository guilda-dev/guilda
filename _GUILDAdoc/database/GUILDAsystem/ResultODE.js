(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["ResultODE"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "ResultODE",
  "properties": [
    {
      "Name": "rv_t",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,1)",
      "Validation": {
        "Class": "double",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "s",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 82,
      "Summary": "Output times, ascending; a phase boundary appears twice (end of one phase, start of the next).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_variable",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "table()",
      "Validation": {
        "Class": "table",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 83,
      "Summary": "Variable map at the time of the simulation: its rows are the columns of rm_variable.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table ((n_x + n_v + n_u + n_uc) x 8)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_variable",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,0)",
      "Validation": {
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 84,
      "Summary": "Trajectory of all variables: row k at rv_t(k), column m the variable tab_variable(m,:).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double (n_t x (n_x + n_v + n_u + n_uc))",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_I",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,0)",
      "Validation": {
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 85,
      "Summary": "Currents injected into the buses: Ireal, Iimag of each bus in the order of sv_bus.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double (n_t x 2 n_bus)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_Icomponent",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,0)",
      "Validation": {
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 86,
      "Summary": "Current each component injects into its bus (its f_I): Ireal, Iimag of each component in the order of sv_bus and c_component; NaN while it is tripped.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double (n_t x 2 n_component)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_output",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "table()",
      "Validation": {
        "Class": "table",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 87,
      "Summary": "Outputs y and yc of the variable map: its rows are the columns of rm_output; columns as tab_variable.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "table (n_out x 8)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "rm_output",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,0)",
      "Validation": {
        "Class": "double",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 88,
      "Summary": "Trajectory of the outputs: row k at rv_t(k), column m the output tab_output(m,:); NaN while the unit is tripped.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "double (n_t x n_out)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_bus",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(0,1)",
      "Validation": {
        "Class": "string",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 89,
      "Summary": "Bus tags, in the order of odeResults.Bus.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "c_component",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 90,
      "Summary": "Component tags of each bus, in the order of odeResults.Bus(i).Component.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_network",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct()",
      "Validation": {
        "Class": "struct",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 91,
      "Summary": "Snapshot of the network at the simulation: struct(net, false).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_branchY",
      "Defining": "ResultODE",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct(\"iv_Y\", zeros(0,1), \"c_Ybranch\", {cell(0,1)})",
      "Validation": {
        "Class": "struct",
        "Size": "",
        "Validators": []
      },
      "Unit": "pu",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 92,
      "Summary": "Branch admittances the run used: iv_Y (n_t x 1) is the position in c_Ybranch at each time of rv_t, c_Ybranch{k} the 2x2 matrix of each branch of sct_network.a_Branch in the k-th set of branch states (2 x 2 x n_branch; k = 1: all closed).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "odeResults",
      "Defining": "ResultODE",
      "Group": "Result",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 96,
      "Summary": "Trajectories per bus and component: a view of rv_t, rm_variable, rm_I, rm_Icomponent and rm_output (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct (1x1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "c_index",
      "Defining": "ResultODE",
      "Group": "Internal state",
      "GetAccess": "private",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 100,
      "Summary": "Columns for odeResults: c_index{i}.iv_V, .c_x{j}, .c_u{j} (rm_variable) and .c_y{j} (rm_output) of component j of bus i.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "cell of struct (n_bus x 1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_view",
      "Defining": "ResultODE",
      "Group": "Internal state",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct([])",
      "Validation": {
        "Class": "struct",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 101,
      "Summary": "odeResults, built on first access.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "struct (0x0 or 1x1)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "flag",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "false",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 39,
      "Summary": "Success or convergence flag (second output): logical, or a numeric exit flag positive on success.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "logical or double",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "output",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct()",
      "Validation": {
        "Class": "struct",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 40,
      "Summary": "Solver details, as returned by the analysis (third output).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "options",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "struct()",
      "Validation": {
        "Class": "struct",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 41,
      "Summary": "Effective settings: the section of GUILDA.setting of the analysis, with the Name-Value options of the call applied.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_solver",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 42,
      "Summary": "Class name of the solver object that ran the analysis.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_elapsed",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "NaN",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "s",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 43,
      "Summary": "Elapsed time of the analysis.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "s_network",
      "Defining": "ResultBase",
      "Group": "Result",
      "GetAccess": "public",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 44,
      "Summary": "Tag of the analysed network at the time of the analysis.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "a_PowerNetwork",
      "Defining": "ResultBase",
      "Group": "Network",
      "GetAccess": "public",
      "SetAccess": "protected",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "[]",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 47,
      "Summary": "Analysed network: a reference, not a copy (it may have been edited since).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "PowerNetwork (1x1 or empty)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "l_success",
      "Defining": "ResultBase",
      "Group": "Result",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/ResultBase.m",
      "Line": 50,
      "Summary": "True when the analysis succeeded (see is_success).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "logical",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "judge_out_of_step",
      "Defining": "ResultODE",
      "Group": "judge",
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
        "verdict"
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
          "Name": "Reference",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"slack\"",
          "Required": false,
          "Unit": "",
          "Description": "\"slack\", \"COI\", or the tag of a unit with delta."
        },
        {
          "Name": "Threshold",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBePositive"
          ],
          "Default": "360",
          "Required": false,
          "Unit": "deg",
          "Description": "Largest allowed absolute rotor angle relative to the reference."
        }
      ],
      "Outputs": [
        {
          "Name": "verdict",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Verdict (\"stable\" | \"out-of-step\" | \"incomplete\"), Time [s] (first time beyond Threshold, NaN when none), Units (tags of the units out of step), MaxAngle [deg] (largest absolute relative angle), Reference, Threshold."
        }
      ],
      "Signature": "verdict = judge_out_of_step(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/judge_out_of_step.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultODE:NoRotorAngle",
        "GUILDA:ResultODE:NoSlackGenerator",
        "GUILDA:ResultODE:UnknownReference"
      ],
      "Summary": "Judge the result by the rotor angles: out of step beyond a threshold from a reference.",
      "Desc": "The units judged are the components with the state\ndelta (synchronous generators). A unit is out of step when the absolute value of its\nrotor angle relative to the reference exceeds Threshold (360 degrees) at any time of the\nresult. The verdict is\n\n- \"out-of-step\" when a unit is out of step (also when the simulation stopped early after\n  that),\n- \"incomplete\" when no unit is out of step but the simulation did not reach its end\n  (result.flag ~= 1; also flag = 2, a run stopped by StopOnOutOfStep at an angle below\n  Threshold),\n- \"stable\" otherwise.\n\nA run stopped by StopOnOutOfStep (flag = 2) from the same reference at StopAngle >=\nThreshold is \"out-of-step\" for the unit of output.outOfStep at the time of the stop,\neven when the angle at the located stop is a rounding error below StopAngle.\n\nThe reference is the generator of the slack bus (Reference=\"slack\", the default; the\nfirst component with delta on the slack bus of the network snapshot sct_network), the\ncenter of inertia of all the units (Reference=\"COI\", weights the dynamics parameter M of\nthe snapshot), or a unit given by its tag. The states of a tripped unit are NaN while it\nis tripped and do not count; they are left out of the center of inertia at those times.\nOnly the result is read, so the judgment works after the network is edited or deleted.\nFor another criterion, write a function of the result: v = my_judge(result).",
      "SeeAlso": [],
      "Examples": "```matlab\nresult  = net.simulate(\"fault\");\nverdict = result.judge_out_of_step();\nverdict = result.judge_out_of_step(Reference=\"COI\", Threshold=180);\nverdict = result.judge_out_of_step(Reference=\"B003SG1\");\n```\n\nSee also ResultODE",
      "Deprecated": ""
    },
    {
      "Name": "export",
      "Defining": "ResultODE",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "filename"
      ],
      "OutputNames": [
        "s_file"
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
          "Name": "filename",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "string(datetime(\"now\",\"Format\",\"uuMMdd_HHmmss\")) + \"_simulation.csv\"",
          "Required": false,
          "Unit": "",
          "Description": "Output file; its extension selects the format."
        }
      ],
      "Outputs": [
        {
          "Name": "s_file",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Path of the written file."
        }
      ],
      "Signature": "s_file = export(obj, filename)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/export.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "ResultBase",
      "Throws": [
        "GUILDA:ResultODE:ExportFormat"
      ],
      "Summary": "Write the trajectories to a table file or a MAT-file.",
      "Desc": "Writes the trajectories to a file. The format follows the extension of filename:\n.csv, .txt, .xlsx, .xls write one table (column t, then <bus>_Vreal, <bus>_Vimag,\n<bus>_Ireal, <bus>_Iimag, <bus>_P, <bus>_Q of each bus, <component>_<name> of each\nstate and input and <component>_Ireal, <component>_Iimag of the current of each\ncomponent, one column per controller state named by the Label of tab_variable,\nand one column per output named by the Label of tab_output); .mat saves odeResults,\nrm_variable, tab_variable, rm_output, tab_output, options, flag and output, so the\ncontroller states and outputs (in rm_variable and rm_output only) are kept. A relative filename is\nrelative to the current folder.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "plot_diagram",
      "Defining": "ResultODE",
      "Group": "plot",
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
        "G",
        "G_chart"
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
          "Name": "opt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name-Value options; each sets the property of the same name of the GraphNetDiagram."
        },
        {
          "Name": "Trajectory",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"auto\"",
          "Required": false,
          "Unit": "",
          "Description": "Quantity of the side chart as Quantity of plot_trajectory; \"auto\": \"Vabs\" of all buses; \"none\": no side chart."
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
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "GraphNetDiagram object of the drawing."
        },
        {
          "Name": "G_chart",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The side chart of the trajectory (GraphChart) linked to G; [] without one."
        }
      ],
      "Signature": "[G, G_chart] = plot_diagram(obj, opt, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/plot_diagram.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultODE:NoDiagramData"
      ],
      "Summary": "Draw the time response as a network diagram (GraphNetDiagram; 2D, or Dimension=\"3D\") with every output time.",
      "Desc": "The diagram holds every output time rv_t; G.set_time(t) shows the sample nearest to t\n(the first one is shown at first). The bus voltages come from the variables Vre, Vim of\nthe buses (rm_variable) and the current of each component from rm_Icomponent, so the\ncolors, labels and arrows of the components and branches show the simulated values.\nThe current injection of a bus is the sum of the currents of its components: during a\nfault it does not hold the fault current. The branch flows use the admittance matrix\nof each branch in the branch states of the phase of each time (sct_branchY; a result\nbuilt without it: the closed matrices cm_Y of sct_network): an opened\nbranch (\"6open\") carries no current, a branch with one circuit open (\"3open\") the\ncurrent of the other circuits, and during a fault inside a branch the two ends carry\nthe currents of the faulted branch into the fault point (both ends feed it). At a phase\nboundary the end of one phase takes the states of that phase and the start of the\nnext those of the next. While a unit is tripped its current is\nNaN: its link is gray, its values are NaN and its bus counts its current as 0. A result\nwithout component currents (rm_Icomponent all NaN, e.g. a result built without them)\nstops with GUILDA:ResultODE:NoDiagramData. It reads only the stored result. The other\nName-Value options set the properties of the GraphNetDiagram.\n\nBeside the diagram, on its right, the side chart G_chart (GraphChart) draws a trajectory\nagainst time as plot_trajectory, with a cursor at the time shown: by default |V| of all\nbuses (\"Vabs\"); Trajectory names another quantity as Quantity of plot_trajectory\n(\"Vangle\", \"P\", \"Q\" or a state, input or output name such as \"omega\"). The container (a\nnew figure of 1400 x 600 px when Parent is empty; a uigridlayout gets a borderless\nuipanel first) holds two borderless panels: the diagram with its playback bar on the\nleft (60 %) and the chart on the right (40 %). The two are linked (G.link(G_chart)): the\nbar, G.set_time, G.play and G.animate move the cursor of the chart. The chart has no bar\nof its own (its time only moves the cursor). Trajectory=\"none\", or an axes or uiaxes as\nParent, draws the diagram alone, without a side chart (G_chart []).",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nsc = net.add_scenario(\"fault\");\nsc.add_fault(\"B007\", [1, 1.05]);\nres = net.simulate(\"fault\", Time=[0, 5]);\n[G, G_chart] = res.plot_diagram(ColorMode=\"P\", LabelMode=\"value\");   % |V| of the buses on the right\nG.set_time(1.02);       % during the fault; the cursor of G_chart moves too\nG = res.plot_diagram(Trajectory=\"none\");    % the diagram alone\n```\n\nSee also ResultODE.plot_trajectory, PowerNetwork.plot_diagram, ResultPF.plot_diagram, GraphNetDiagram, ResultODE.plot_spring_model",
      "Deprecated": ""
    },
    {
      "Name": "plot_spring_model",
      "Defining": "ResultODE",
      "Group": "plot",
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
        "G",
        "G_chart"
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
          "Name": "Dimension",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeMember(opt.Dimension, [2, 3])"
          ],
          "Default": "2",
          "Required": false,
          "Unit": "",
          "Description": "2: phasor plane (GraphSpring2D); 3: surface z = log|V| (GraphSpring3D)."
        },
        {
          "Name": "Trajectory",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"auto\"",
          "Required": false,
          "Unit": "",
          "Description": "Quantity of the side chart as Quantity of plot_trajectory; \"auto\": omega of the generators; \"none\": no side chart."
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
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The picture: a GraphSpring2D or GraphSpring3D object."
        },
        {
          "Name": "G_chart",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The side chart of the trajectory (GraphChart) linked to G; [] without one."
        }
      ],
      "Signature": "[G, G_chart] = plot_spring_model(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/plot_spring_model.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultODE:NoSpringData"
      ],
      "Summary": "Draw the time response as a spring-mass picture that can be animated.",
      "Desc": "The picture holds every output time rv_t: G.set_time(t) shows one time, G.animate()\nplays it and G.export_video(file) writes it as a video. The nodes are voltage phasors:\nevery bus, and the own node of each component whose class returns one from its Static\nget_spring_node (the internal voltage of a generator, joined to its bus by the machine\nreactance). The springs are the branches and these reactances. Arrow pairs show the\nactive power P and the reactive-current magnitude Iq: on each own node, and on each bus\nwith a component without an own node (the bus injection minus the currents of the own\nnodes, at the bus voltage). Marker, MarkerSize and Color of the graph parameters set the\nappearance. Dimension=2 draws the phasor plane (GraphSpring2D), Dimension=3 the surface\nz = log|V| (GraphSpring3D).\n\nBeside the picture, on its right, the side chart G_chart (GraphChart) draws a trajectory\nagainst time as plot_trajectory, with a cursor at the time shown: by default the omega\nof the generators (the components with the state omega); Trajectory names another\nquantity as Quantity of plot_trajectory (\"Vabs\", \"Vangle\", \"P\", \"Q\" or a state, input or\noutput name). The container (a new figure of 1400 x 600 px when Parent is empty; a\nuigridlayout gets a borderless uipanel first) holds two borderless panels: the picture\nwith its playback bar on the left (60 %) and the chart on the right (40 %). The two are\nlinked (G.link(G_chart)): the bar, G.set_time, G.play and G.animate move the cursor of the\nchart. The chart has no bar of its own (its time only moves the cursor). Trajectory=\"none\",\nor an axes or uiaxes as Parent, draws the picture alone, without a side chart (G_chart []).\n\nIt reads only the stored result: the trajectories of the states, inputs, bus voltages\nand bus currents, and the network snapshot sct_network (class and dynamic parameters of\neach component). While a unit is tripped its states are NaN: its own node, its spring\nand its arrows are not drawn at those times, and the arrow of its bus counts its current\nas 0. The dashed circle |E| of an own node is drawn when |E| stays constant over the\ntimes (e.g. a classical generator without AVR); it is hidden with its node while the unit\nis tripped.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nsc = net.add_scenario(\"fault\");\nsc.add_fault(\"B007\", [1, 1.05]);\nres = net.simulate(\"fault\", Time=[0, 5]);\n[G, G_chart] = res.plot_spring_model(Dimension=3);   % omega of the generators on the right\nG.animate(Speed=0.5);                                % the cursor of G_chart follows\nG.export_video(\"swing.mp4\");\nG = res.plot_spring_model(Trajectory=\"none\");        % the picture alone\n```\n\nSee also ResultODE.plot_trajectory, PowerNetwork.plot_spring_model, ResultPF.plot_spring_model, GraphSpring2D, GraphSpring3D, Component.get_spring_node",
      "Deprecated": ""
    },
    {
      "Name": "plot_pqv",
      "Defining": "ResultODE",
      "Group": "plot",
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
        "G"
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
          "Name": "Bus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"all\"",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the buses to draw; \"all\" for every bus."
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
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The chart (GraphChart), one 3D line per bus."
        }
      ],
      "Signature": "G = plot_pqv(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/plot_pqv.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultODE:NoDiagramData",
        "GUILDA:ResultODE:UnknownBus"
      ],
      "Summary": "Plot the P-Q-V trajectory of the buses in 3D: P, Q and |V| of each bus at every output time.",
      "Desc": "Draws one 3D line per bus through (P, Q, |V|) [pu] of its output times: P + jQ is the\ntotal power the bus injects into the network, S = V conj(sum of the currents of its\ncomponents), from the bus voltages (Vre, Vim of rm_variable) and rm_Icomponent; it\nequals V conj(Y V) of the bus (rm_I) within the tolerance of the solver, except at a\nfaulted bus during the fault (the fault current is not a component current). A\ntripped component (NaN current) counts as 0, and a bus without components has\nP = Q = 0. By default it draws every bus; Bus selects some (a tag that is not in sv_bus\nstops with GUILDA:ResultODE:UnknownBus). Drag the axes to turn the view.\n\nThe samples of the chart are the output times rv_t: G.set_time(t) puts a marker on each\nline at its point of the time nearest to t (none before the first set_time), and\nG.link(G2) keeps it in step with plot_diagram, plot_spring_model and plot_trajectory.\nA result without time points or component currents stops with\nGUILDA:ResultODE:NoDiagramData.\n\nIt returns the chart G (GraphChart, one 3D panel): one line per bus, tagged with the\nbus tag.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE9bus();\nsc = net.add_scenario(\"fault\");\nsc.add_fault(\"B007\", [1, 1.05]);\nres = net.simulate(\"fault\", Time=[0, 5]);\nG = res.plot_pqv(Bus=[\"B005\", \"B007\"]);\nG.set_time(1.02);       % markers during the fault\n```\n\nSee also ResultODE.plot_trajectory, ResultCPF.plot_pqv, GraphChart",
      "Deprecated": ""
    },
    {
      "Name": "plot_trajectory",
      "Defining": "ResultODE",
      "Group": "plot",
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
        "G"
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
          "Name": "Quantity",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"Vabs\"",
          "Required": false,
          "Unit": "",
          "Description": "\"Vabs\", \"Vangle\", \"P\", \"Q\", or a state, input or output name of the components."
        },
        {
          "Name": "Bus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"all\"",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the buses to draw (for a component quantity: the buses of the components); \"all\" for every bus."
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
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The chart (GraphChart), one line per bus or component."
        }
      ],
      "Signature": "G = plot_trajectory(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/plot_trajectory.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Plot a trajectory of the buses or components.",
      "Desc": "Draws a trajectory against time [s]: for the buses, the voltage magnitude (Vabs), the\nvoltage angle (Vangle) or the power P / Q injected by the components; for the\ncomponents, a state, an input or an output given by its name (e.g. omega, Pmech), with\none line per component of the selected buses that has it: the columns of\nget_trajectory(Quantity, Bus=Bus). By default it draws Vabs of every bus.\nThe only figure of the analysis: simulate draws none (its PlotFcn is a live display\nduring the simulation).\n\nIt returns the chart G (GraphChart): one line per bus, tagged with the bus tag, or per\ncomponent, tagged with the full component tag. The panel is a time panel: G.set_time(t)\ndraws a cursor at t, and G.link(G2) with the graph of plot_spring_model or plot_diagram\nof the same result moves the cursor with its animation.",
      "SeeAlso": [],
      "Examples": "```matlab\nG = res.plot_trajectory(Quantity=\"omega\");\nG.set_style(G.tab_element.Tag(1), Color=\"r\", LineWidth=2);\nS = res.plot_spring_model();\nG.link(S);\nS.animate();                 % the cursor of G follows\n```\n\nSee also ResultODE.get_trajectory, GraphChart, ResultODE.plot_spring_model, ResultODE.plot_diagram",
      "Deprecated": ""
    },
    {
      "Name": "get_trajectory",
      "Defining": "ResultODE",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "Quantity",
        "opt"
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
        },
        {
          "Name": "Quantity",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"Vabs\"",
          "Required": false,
          "Unit": "",
          "Description": "\"Vabs\", \"Vangle\", \"P\", \"Q\", or a state, input or output name of the components."
        },
        {
          "Name": "Bus",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"all\"",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the buses (for a component quantity: the buses of the components); \"all\" for every bus."
        },
        {
          "Name": "Owner",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [
            "mustBeText"
          ],
          "Default": "\"all\"",
          "Required": false,
          "Unit": "",
          "Description": "Tags of the owners to keep (buses or components); \"all\" for every owner."
        },
        {
          "Name": "Reference",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Reference, [\"none\",\"COI\"])"
          ],
          "Default": "\"none\"",
          "Required": false,
          "Unit": "",
          "Description": "\"none\": the values; \"COI\": relative to the center of inertia, with a column COI."
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
          "Description": "Column t [s], then one column per owner named by its tag (and COI with Reference=\"COI\")."
        }
      ],
      "Signature": "tab = get_trajectory(obj, Quantity, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/get_trajectory.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultODE:UnknownBus",
        "GUILDA:ResultODE:UnknownQuantity",
        "GUILDA:ResultODE:UnknownOwner",
        "GUILDA:ResultODE:NoCenterOfInertia"
      ],
      "Summary": "Get a trajectory of the buses or components as a table.",
      "Desc": "Returns the values of one quantity against time, one column per owner: for the buses,\nthe voltage magnitude (Vabs), the voltage angle (Vangle) or the power P / Q injected by\nthe components; for the components, a state, an input or an output given by its name\n(e.g. omega, delta, Vfield), with one column per component of the selected buses that\nhas it. plot_trajectory draws the same columns.\n\nThe result is a table (not a timetable: at a phase boundary the time appears twice, see\nResultODE) with the column t [s] first, then one column per owner named by its tag (the\nbus tag, or the full component tag), in the order of Bus and of the components of each\nbus. tab.Properties.Description names the quantity and VariableUnits holds the units.\n\n- Bus: the buses (for a component quantity, the buses of the components); \"all\" for\n  every bus.\n- Owner: the owners to keep, bus tags for a bus quantity or component tags for a\n  component quantity; \"all\" for every owner of the selected buses.\n- Reference=\"COI\": the values relative to the center of inertia (the mean weighted by\n  the dynamics parameter M of the network snapshot), and a last column COI with the\n  center itself (tab.B001 + tab.COI is the value of B001). The states and inputs of a\n  tripped unit are NaN while it is tripped: at those times the unit is left out of the\n  center (the weights of the other units are renormalized) and its own column stays\n  NaN. COI is NaN at a time when every unit is NaN. For delta and Vangle the center is that of the rotor angles delta of\n  all the components with delta, as in judge_out_of_step(Reference=\"COI\"), and Vangle\n  relative to it is wrapped to (-pi, pi]. For another component quantity it is the center\n  of that quantity over all the components that have it (each needs M). Vabs, P and Q\n  have no center. \"none\" (default) returns the values as simulated.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = net.simulate(\"fault\");\ntab = res.get_trajectory(\"omega\");                    % t, B001SG1, B002SG1, ...\nplot(tab.t, tab{:, 2:end});\ntab = res.get_trajectory(\"delta\", Reference=\"COI\");   % angles from the center of inertia, and COI\ntab = res.get_trajectory(\"Vabs\", Bus=[\"B004\", \"B005\"]);\ntab = res.get_trajectory(\"Vfield\", Owner=\"B001SG1\");\n```\n\nSee also ResultODE.plot_trajectory, ResultODE.judge_out_of_step, ResultODE.get_point",
      "Deprecated": ""
    },
    {
      "Name": "get_point",
      "Defining": "ResultODE",
      "Group": "get",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "t",
        "tab_map",
        "opt"
      ],
      "OutputNames": [
        "rv"
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
          "Name": "t",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [
            "mustBeReal"
          ],
          "Default": "",
          "Required": true,
          "Unit": "s",
          "Description": "Time within [rv_t(1), rv_t(end)]."
        },
        {
          "Name": "tab_map",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "obj.tab_variable",
          "Required": false,
          "Unit": "",
          "Description": "Rows to return (a variable map or a part of it)."
        },
        {
          "Name": "Side",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Side, [\"after\",\"before\"])"
          ],
          "Default": "\"after\"",
          "Required": false,
          "Unit": "",
          "Description": "Value at a phase boundary: after or before the event."
        }
      ],
      "Outputs": [
        {
          "Name": "rv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Values in the order of the rows of tab_map (column)."
        }
      ],
      "Signature": "rv = get_point(obj, t, tab_map, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/get_point.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultODE:PointTime"
      ],
      "Summary": "Get the values of the variable map at a time of the simulation.",
      "Desc": "Returns the values of the variables at time t, in the order of the rows of tab_map\n(by default the whole tab_variable, so rv is a point for net.get_sys(rv)).\ntab_map may be any part of tab_variable, e.g. the rows x, Vre, Vim, u, uc of the\nvariable map of a bus or component of the simulated network (bus.get_variable_map(),\ncomp.get_variable_map()); its rows are found by Kind, Owner, Name and Bus. The other\nrows of a variable map (the signals y, yc) are not in the result and stop with\nGUILDA:ResultODE:UnknownVariable.\n\nBetween two output times the values are interpolated linearly. At a phase boundary,\nwhere the time appears twice in rv_t, Side chooses the value: \"after\" (default) the\nstart of the later phase, i.e. the state after the event (an offset applied, a fault\ncleared), \"before\" the end of the earlier phase. At any other output time Side has no\neffect.",
      "SeeAlso": [],
      "Examples": "```matlab\nsc = net.add_scenario(\"fault\");  sc.add_fault(\"B008\", [1,1.05]);\nsim = net.simulate(\"fault\", Time=[0,5]);\nx  = sim.get_point(2);                    % rows x, Vre, Vim, u, uc of net.get_variable_map()\nx0 = sim.get_point(1.05, Side=\"before\");  % end of the fault\nres = net.get_sys({sim, 2});            % same point as net.get_sys(x)\n```\n\nSee also PowerNetwork.get_variable_map, SolverLIN",
      "Deprecated": ""
    },
    {
      "Name": "ResultODE",
      "Defining": "ResultODE",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "sct_sol",
        "sct_dae",
        "sct_network",
        "sct_solver"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "sct_sol",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Solver data: rv_t, rm_variable (variable rows of sct_dae.tab_variable: x, Vre, Vim, u, uc), rm_I, rm_Icomponent (NaN when missing), rv_phase (phase of each time), iv_Y (set of branch admittances of each time)."
        },
        {
          "Name": "sct_dae",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Data of the run: tab_variable (the variable map), the blocks c_comp, c_lc, c_gc (iv_x, iv_u, iv_y, i_bus, f_Y, s_tag), to recompute the outputs, and c_Ybranch (branch admittances of each set of branch states)."
        },
        {
          "Name": "sct_network",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Snapshot of the network: struct(net, false)."
        },
        {
          "Name": "sct_solver",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Solver information: solver, options, flag, output, elapsed (s or a tic value)."
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
          "Description": "The result object."
        }
      ],
      "Signature": "obj = ResultODE(sct_sol, sct_dae, sct_network, sct_solver)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/ResultODE.m",
      "Line": 105,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a time simulation result from data.",
      "Desc": "Takes the variables x, Vre, Vim, u, uc (the leading rows of the variable map) from\nthe trajectories of the solver and computes the outputs y, yc with the output\nfunctions of the blocks; no network object is read.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_view",
      "Defining": "ResultODE",
      "Group": "build",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj"
      ],
      "OutputNames": [
        "s"
      ],
      "Arguments": [],
      "Outputs": [],
      "Signature": "s = build_view(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/build_view.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "odeResults from rv_t, rm_variable, rm_I, rm_Icomponent and rm_output (same layout as before",
      "Desc": "the trajectory was stored in variable-map order, with the outputs Y and the current I of\neach component)",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "columns_of",
      "Defining": "ResultODE",
      "Group": "columns",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "tab_map"
      ],
      "OutputNames": [
        "iv"
      ],
      "Arguments": [],
      "Outputs": [],
      "Signature": "iv = columns_of(obj, tab_map)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/columns_of.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultODE:InvalidMap",
        "GUILDA:ResultODE:UnknownVariable"
      ],
      "Summary": "Columns of rm_variable for the rows of tab_map (matched by Kind, Owner, Name, Bus)",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "center_of_inertia",
      "Defining": "ResultODE",
      "Group": "center",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "m_value",
        "sv_unit",
        "s_errorId"
      ],
      "OutputNames": [
        "rv_center"
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
          "Description": "The result (ResultODE)."
        },
        {
          "Name": "m_value",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Values: one row per time, one column per unit."
        },
        {
          "Name": "sv_unit",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Component tags of the columns of m_value."
        },
        {
          "Name": "s_errorId",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Message id when a unit has no M (an id of msg with the unit tag as its argument)."
        }
      ],
      "Outputs": [
        {
          "Name": "rv_center",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Center of inertia at each time (NaN when every unit is NaN)."
        }
      ],
      "Signature": "rv_center = center_of_inertia(obj, m_value, sv_unit, s_errorId)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/private/center_of_inertia.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Center of inertia of a quantity of some units: the mean weighted by their inertia M.",
      "Desc": "The weight of a unit is the dynamics parameter M of the component in the network\nsnapshot sct_network. A unit whose value is NaN at a time (tripped) is left out of the\nmean at that time. Called by judge_out_of_step (rotor angles) and get_trajectory.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "draw_with_chart",
      "Defining": "ResultODE",
      "Group": "draw",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "h_parent",
        "s_trajectory",
        "s_default",
        "fcn_graph"
      ],
      "OutputNames": [
        "G",
        "G_chart"
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
          "Description": "The result. <@Type> ResultODE"
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
          "Description": "Parent of the method: a container, an axes or uiaxes, or [] for a new figure."
        },
        {
          "Name": "s_trajectory",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Quantity of the side chart (as plot_trajectory), \"auto\" or \"none\"."
        },
        {
          "Name": "s_default",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Quantity drawn for \"auto\"."
        },
        {
          "Name": "fcn_graph",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Draws the graph in a parent h as fcn_graph(h)."
        }
      ],
      "Outputs": [
        {
          "Name": "G",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The animated graph (GraphBase)."
        },
        {
          "Name": "G_chart",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The side chart (GraphChart), or [] without one."
        }
      ],
      "Signature": "[G, G_chart] = draw_with_chart(obj, h_parent, s_trajectory, s_default, fcn_graph)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/private/draw_with_chart.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the animated graph of plot_spring_model or plot_diagram, with the side chart of a trajectory on its right.",
      "Desc": "The graph is drawn by fcn_graph(h) in h. With a side chart, the container h_parent (a\nnew figure of 1400 x 600 px when it is empty; a uigridlayout gets a borderless uipanel\nfirst) holds two borderless panels side by side: the graph on the left (60 %, with its\nplayback bar) and the chart plot_trajectory(Quantity=s_trajectory) on the right (40 %,\nno bar: its time only moves the cursor). The two are linked, so the bar of the graph\nmoves the cursor of the chart. s_trajectory \"auto\" draws s_default; \"none\" and an axes\nor uiaxes h_parent draw the graph alone in h_parent (G_chart []). A drawing that fails\nremoves the panels (and the new figure) it made.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "output_trajectory",
      "Defining": "ResultODE",
      "Group": "output",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct_sol",
        "sct_dae"
      ],
      "OutputNames": [
        "rm_output"
      ],
      "Arguments": [
        {
          "Name": "sct_sol",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "rv_t, rm_variable (variable rows of the map), rv_phase."
        },
        {
          "Name": "sct_dae",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "tab_variable and the blocks c_comp, c_lc, c_gc."
        }
      ],
      "Outputs": [
        {
          "Name": "rm_output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Outputs: one row per time, one column per row y, yc of the map."
        }
      ],
      "Signature": "rm_output = output_trajectory(sct_sol, sct_dae)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/private/output_trajectory.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Outputs y, yc at each time of the trajectory, from the output functions of the blocks.",
      "Desc": "A component is evaluated as f_Y(t, x, V), a local controller as f_Y(t, x, V, u) and a\nglobal controller as f_Y(t, x, V_all, u), with t the time from the start of the phase\n(as the solver), V the voltage [Vre; Vim] of the bus of the block and V_all those of\nevery bus. The columns follow the rows y, yc of the variable map. The outputs of a\nblock whose states are NaN (a tripped unit) are NaN.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "simulator_columns",
      "Defining": "ResultODE",
      "Group": "simulator",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "tab",
        "tab_out",
        "sv_bus",
        "c_component"
      ],
      "OutputNames": [
        "c_index"
      ],
      "Arguments": [
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
          "Description": "Rows x, Vre, Vim, u, uc of the variable map (ResultODE.tab_variable)."
        },
        {
          "Name": "tab_out",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Rows y, yc of the variable map (ResultODE.tab_output)."
        },
        {
          "Name": "sv_bus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Bus tags (ResultODE.sv_bus)."
        },
        {
          "Name": "c_component",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "cell",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Component tags of each bus (ResultODE.c_component)."
        }
      ],
      "Outputs": [
        {
          "Name": "c_index",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "cell",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Struct per bus: iv_V, c_x, c_u, c_y."
        }
      ],
      "Signature": "c_index = simulator_columns(tab, tab_out, sv_bus, c_component)",
      "File": "_GUILDAsystem/_auxiliary/@ResultODE/private/simulator_columns.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "c_index{i}: columns for the view odeResults of bus i: its voltage, and the component's",
      "Desc": "own states, inputs (columns of rm_variable, rows of tab) and outputs (columns of\nrm_output, rows of tab_out); the states of its controllers are not included.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "launch_gui",
      "Defining": "ResultBase",
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
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Log that runs and records the actions (default: a new HistoryGUILDA(Echo=true))."
        },
        {
          "Name": "Variable",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeValidVariableName"
          ],
          "Default": "\"res\"",
          "Required": false,
          "Unit": "",
          "Description": "Name of the result in the workspace of History."
        }
      ],
      "Outputs": [
        {
          "Name": "h",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "DrawerResultGUI",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "The GUI."
        }
      ],
      "Signature": "h = launch_gui(obj, h_container, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/launch_gui.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultBase:OtherVariable"
      ],
      "Summary": "Show the result in a GUI: header, the plot_, disp_, get_ and export methods as buttons, and a view area.",
      "Desc": "With no container it opens a new uifigure; with a container (uifigure, uipanel, uitab or\nuigridlayout) it fills it, so that the GUI can be embedded in another app. The buttons\nare the methods of the result in functionSignatures.json, grouped as Plot, Display, Get\nand Export, so a result class needs no GUI code. A method with options asks for them in\na dialog (DrawerOptionDialog.ask); plots are drawn in the plot panel, and the text of\ndisp_* and the values of get_* are shown in the text area. See DrawerResultGUI.\n\nEvery action runs as a line of MATLAB code in History (HistoryGUILDA.run) on the result\nvariable Variable of its workspace (set to this result when the workspace has no such\nvariable): the code is logged, and `h.history.get_script()` returns a script that repeats\nthe actions, drawing the plots in new figures. The default history prints each `>> code`\nin the Command Window; its script needs the result in the workspace as Variable.",
      "SeeAlso": [],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nh = res.launch_gui();                        % new window\nfig = uifigure();\nh = res.launch_gui(uipanel(uigridlayout(fig, [1 1])));   % embedded in a panel\nhist = HistoryGUILDA();\nhist.run(\"Power flow\", \"Calculate\", \"net = network.IEEE9bus(); res_pf = net.calculate_powerflow();\");\nh = hist.get_variable(\"res_pf\").launch_gui(History=hist, Variable=\"res_pf\");\nhist.get_script()                            % the power flow and the actions of the GUI\n```\n\nSee also DrawerResultGUI, HistoryGUILDA, DrawerOptionDialog",
      "Deprecated": ""
    },
    {
      "Name": "error_unsupported",
      "Defining": "ResultBase",
      "Group": "error",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_method"
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
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name of the unsupported method (\"export\")."
        }
      ],
      "Outputs": [],
      "Signature": "error_unsupported(obj, s_method)",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/error_unsupported.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultBase:Unsupported"
      ],
      "Summary": "Error for an unsupported method of the contract (export).",
      "Desc": "Stops with GUILDA:ResultBase:Unsupported for a method of the export\ncontract that this result class does not provide.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "is_success",
      "Defining": "ResultBase",
      "Group": "is",
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
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True when the analysis succeeded."
        }
      ],
      "Signature": "l = is_success(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultBase/is_success.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Decide whether flag means success.",
      "Desc": "Success test behind l_success: a logical flag as it is, a numeric flag when\npositive (as for exitflag of fsolve or fmincon). Override it when an analysis\nuses another convention.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "doc",
      "Defining": "auxiliary",
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
          "Description": "Object whose class page is opened."
        }
      ],
      "Outputs": [],
      "Signature": "doc(obj)",
      "File": "_GUILDAsystem/_auxiliary/@auxiliary/doc.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Open the class reference page of the object's class.",
      "Desc": "Opens the GUILDA class reference (English page) of class(obj) in the browser, as\nGUILDA.doc(\"class\", class(obj)). doc with a class name (doc ResultPF) is MATLAB's\ndoc.",
      "SeeAlso": [],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nres = net.calculate_powerflow();\nres.doc()                       % page of ResultPF\ndoc(res)                        % same as res.doc()\nsc = net.add_scenario(\"CASE1\");\nsc.doc()                        % page of Scenario\n```",
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
