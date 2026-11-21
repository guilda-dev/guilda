(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["MethodGradient"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "MethodGradient",
  "properties": [
    {
      "Name": "StepSize",
      "Defining": "MethodGradient",
      "Group": "Settings",
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
          "mustBePositive"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodGradient/MethodGradient.m",
      "Line": 22,
      "Summary": "Factor of the update x = x + StepSize*d(x).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Fcn",
      "Defining": "MethodBase",
      "Group": "Equation",
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
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 29,
      "Summary": "Function F of F(x) = 0.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "function_handle",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Jac",
      "Defining": "MethodBase",
      "Group": "Equation",
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
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 30,
      "Summary": "Jacobian of Fcn; [] for the numerical Jacobian (central differences with Increment).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "function_handle",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "InitVal",
      "Defining": "MethodBase",
      "Group": "Equation",
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
        "Class": "double",
        "Size": "(:,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 31,
      "Summary": "Initial value of x.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "ConvTol",
      "Defining": "MethodBase",
      "Group": "Settings",
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
        "Class": "double",
        "Size": "(1,1)",
        "Validators": [
          "mustBeNonnegative"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 35,
      "Summary": "Tolerance of the largest |F(x)| for convergence.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "MaxIter",
      "Defining": "MethodBase",
      "Group": "Settings",
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
        "Class": "double",
        "Size": "(1,1)",
        "Validators": [
          "mustBeNonnegative"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 36,
      "Summary": "Maximum number of iterations.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Display",
      "Defining": "MethodBase",
      "Group": "Settings",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "\"none\"",
      "Validation": {
        "Class": "string",
        "Size": "(1,1)",
        "Validators": [
          "mustBeMember(Display,[\"none\",\"iter\",\"iter-detailed\",\"final\",\"final-detailed\"])"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 37,
      "Summary": "\"iter\"/\"iter-detailed\" print each iteration; any value but \"none\" prints the final message.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "Increment",
      "Defining": "MethodBase",
      "Group": "Settings",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "1e-4",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": [
          "mustBePositive"
        ]
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 38,
      "Summary": "Step of the numerical Jacobian (x +- Increment).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_diverged",
      "Defining": "MethodBase",
      "Group": "Divergence",
      "GetAccess": "public",
      "SetAccess": "none",
      "Dependent": false,
      "Constant": true,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "1e10",
      "Validation": {
        "Class": "",
        "Size": "",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 42,
      "Summary": "Largest |F| [pu] above which the iteration is reported as diverged.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "f_iter",
      "Defining": "MethodBase",
      "Group": "Live display",
      "GetAccess": "MethodBase, PowerNetwork, SolverPF",
      "SetAccess": "MethodBase, PowerNetwork, SolverPF",
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
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/MethodBase.m",
      "Line": 46,
      "Summary": "Called at each iterate as stop = f_iter(x, k, state), state \"init\", \"iter\" or \"done\" (PlotFcn and Progress of SolverPF, Progress of net.calculate_fixed_input_powerflow); [] for none. A true stop ends solve with flag -1.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    }
  ],
  "methods": [
    {
      "Name": "solve",
      "Defining": "MethodGradient",
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
      "OutputNames": [
        "x",
        "flag",
        "output",
        "rm_history",
        "rv_step"
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
          "Name": "x",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Last iterate."
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
          "Description": "1: converged, 0: MaxIter reached, -2: diverged (non-finite d or r)."
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
          "Description": "Details: iterations, algorithm, residual (largest |r|), StepSize, message."
        },
        {
          "Name": "rm_history",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Recorded iterates (one column each)."
        },
        {
          "Name": "rv_step",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Iteration numbers of rm_history."
        }
      ],
      "Signature": "[x, flag, output, rm_history, rv_step] = solve(obj)",
      "File": "_GUILDAsystem/_auxiliary/@MethodGradient/solve.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "MethodBase",
      "Throws": [],
      "Summary": "Iterate x = x + StepSize*d(x) from InitVal until max|r(x)| <= ConvTol.",
      "Desc": "rm_history holds the iterates 0 to 999, every 1000th and the last; rv_step their\niteration numbers.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "MethodGradient",
      "Defining": "MethodGradient",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "opt"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
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
          "Description": ""
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
          "Description": "Gradient iteration."
        }
      ],
      "Signature": "obj = MethodGradient(opt)",
      "File": "_GUILDAsystem/_auxiliary/@MethodGradient/MethodGradient.m",
      "Line": 26,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a gradient iteration; the Name-Value options are the public properties",
      "Desc": "(defaults: ConvTol 1e-8, MaxIter 1e6). Fcn returns d or [d, r]; Jac is not used.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "print_iter",
      "Defining": "MethodBase",
      "Group": "print",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "s_algorithm",
        "k",
        "r_res",
        "s_extra"
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
          "Name": "s_algorithm",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name at the start of the line."
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
          "Description": "Iteration number."
        },
        {
          "Name": "r_res",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Largest |F| (mismatch) at the iterate."
        },
        {
          "Name": "s_extra",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Text appended to the line."
        }
      ],
      "Outputs": [],
      "Signature": "print_iter(obj, s_algorithm, k, r_res, s_extra)",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/print_iter.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Print one iteration line when Display is \"iter\" or \"iter-detailed\".",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "make_output",
      "Defining": "MethodBase",
      "Group": "make",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "flag",
        "n_iter",
        "r_res",
        "s_algorithm",
        "s_name",
        "s_fail",
        "s_hint"
      ],
      "OutputNames": [
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
          "Name": "flag",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "1 converged, 0 MaxIter reached, -2 diverged or no solution."
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
          "Description": "Number of iterations."
        },
        {
          "Name": "r_res",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Largest |F| at the last iterate."
        },
        {
          "Name": "s_algorithm",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Value of output.algorithm."
        },
        {
          "Name": "s_name",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name of the iteration in the message."
        },
        {
          "Name": "s_fail",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Message for flag -2."
        },
        {
          "Name": "s_hint",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "\"\"",
          "Required": false,
          "Unit": "",
          "Description": "Text after the MaxIter message, e.g. \"; a different StepSize may help\"."
        }
      ],
      "Outputs": [
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Fields iterations, algorithm, residual, message."
        }
      ],
      "Signature": "output = make_output(obj, flag, n_iter, r_res, s_algorithm, s_name, s_fail, s_hint)",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/make_output.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Build the output structure of solve and print its message unless Display is \"none\".",
      "Desc": "The message names s_name (\"Newton-Raphson iteration\", ...): converged (flag 1), MaxIter\nreached (flag 0, with n_iter as the limit, followed by s_hint), or s_fail (flag -2). For\nflag 0 and -2, a largest |F| that is not finite or above r_diverged gives \"The <s_name>\ndiverged\" instead (flag -2 keeps an s_fail that already says \"diverged\").",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "eval_jacobian",
      "Defining": "MethodBase",
      "Group": "eval",
      "Access": "protected",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "x"
      ],
      "OutputNames": [
        "J"
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
          "Name": "x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Point."
        }
      ],
      "Outputs": [
        {
          "Name": "J",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Jacobian (sparse when Jac returns a sparse matrix)."
        }
      ],
      "Signature": "J = eval_jacobian(obj, x)",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/eval_jacobian.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Jacobian of Fcn at x: Jac(x), or central differences with the step Increment without Jac.",
      "Desc": "Called at each iteration (hot path: class and size only).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_options",
      "Defining": "MethodBase",
      "Group": "set",
      "Access": "protected",
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
          "Name": "opt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Name-Value options, one field per public property."
        }
      ],
      "Outputs": [],
      "Signature": "set_options(obj, opt)",
      "File": "_GUILDAsystem/_auxiliary/@MethodBase/set_options.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Assign the Name-Value options of a constructor (one field per property) to obj.",
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
