(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["SolverPF"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "SolverPF",
  "properties": [
    {
      "Name": "cv_Vwarm",
      "Defining": "SolverPF",
      "Group": "Warm start",
      "GetAccess": "private",
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
      "Unit": "pu",
      "File": "_GUILDAsystem/_auxiliary/@SolverPF/SolverPF.m",
      "Line": 99,
      "Summary": "Last converged bus voltages; empty when none.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_warmBus",
      "Defining": "SolverPF",
      "Group": "Warm start",
      "GetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@SolverPF/SolverPF.m",
      "Line": 100,
      "Summary": "Bus tags of cv_Vwarm (row names of the tab_PFcondition it was solved for).",
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
      "Defining": "SolverPF",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "cm_Y",
        "tab_PFcondition",
        "sct_options"
      ],
      "OutputNames": [
        "cv_V",
        "flag",
        "output",
        "cm_Vhistory",
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
          "Description": "Solver (net.solver_PF)."
        },
        {
          "Name": "cm_Y",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus admittance matrix (rows and columns in tab_PFcondition order)."
        },
        {
          "Name": "tab_PFcondition",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Power flow conditions, one row per bus: Type, Varg, V, P, Q (Bus.get_pf_condition), optional V0 [pu] and Varg0 [rad] (initial voltage, both or neither); row names = bus tags."
        },
        {
          "Name": "sct_options",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Options of the call (PowerNetwork.calculate_powerflow): Solver, Tolerance, MaxIteration, Verbose, WarmStart, PlotFcn, Progress (a mode or a ProgressGUILDA to use; \"none\" when the field is absent)."
        }
      ],
      "Outputs": [
        {
          "Name": "cv_V",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Complex bus voltages of the solution (tab_PFcondition order)."
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
          "Description": "1 converged, 0 MaxIteration reached, -1 stopped by PlotFcn, -2 diverged or no solution (see SolverPF)."
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
          "Description": "Solver details; output.message describes the outcome."
        },
        {
          "Name": "cm_Vhistory",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Bus voltages at each iteration, or ODE step (\"dynamic\"), one column each."
        },
        {
          "Name": "rv_step",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Iteration numbers, or virtual times (\"dynamic\"), of cm_Vhistory."
        }
      ],
      "Signature": "[cv_V, flag, output, cm_Vhistory, rv_step] = solve(obj, cm_Y, tab_PFcondition, sct_options)",
      "File": "_GUILDAsystem/_auxiliary/@SolverPF/solve.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverPF:InvalidInitialVoltage"
      ],
      "Summary": "Solve the power equations of the given admittance matrix and power flow conditions.",
      "Desc": "Builds the power equations (private power_equation) from cm_Y and tab_PFcondition at\nevery call and runs the Method class of sct_options.Solver (see SolverPF). It reads no\nnetwork, bus, branch or component: net.calculate_powerflow assembles the inputs and\nbuilds the outputs it returns. The solver keeps only the last converged solution and the\nbus tags it belongs to, as the warm start of the next call with the same bus tags; a run\nfrom it that ends with flag 0 or -2 is solved once more from the flat start. The\noptional columns V0 and Varg0 of tab_PFcondition give the initial voltage of the call,\nbefore WarmStart and the flat start.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "SolverPF",
      "Defining": "SolverPF",
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
          "Description": "Power flow solver."
        }
      ],
      "Signature": "obj = SolverPF()",
      "File": "_GUILDAsystem/_auxiliary/@SolverPF/SolverPF.m",
      "Line": 104,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a power flow solver.",
      "Desc": "A network creates its own (net.solver_PF); net.reset_solver() replaces it with a\nnew one, which discards the warm start solution.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "live_residual",
      "Defining": "SolverPF",
      "Group": "live",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "PlotFcn",
        "s_solver",
        "f_res",
        "tab",
        "r_tol"
      ],
      "OutputNames": [
        "f_iter"
      ],
      "Arguments": [
        {
          "Name": "PlotFcn",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Display keys (\"residual\") or a function handle (output of tools.check_plotfcn)."
        },
        {
          "Name": "s_solver",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Solver of the power flow."
        },
        {
          "Name": "f_res",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Residual F of the real form of the voltages (power_equation)."
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
          "Description": "Power flow conditions of the buses (RowNames: bus tags)."
        },
        {
          "Name": "r_tol",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Tolerance, drawn as a line."
        }
      ],
      "Outputs": [
        {
          "Name": "f_iter",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "stop = f_iter(x, k, state)."
        }
      ],
      "Signature": "f_iter = live_residual(PlotFcn, s_solver, f_res, tab, r_tol)",
      "File": "_GUILDAsystem/_auxiliary/@SolverPF/private/live_residual.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Live display of the power flow (PlotFcn) as the f_iter of a Method class.",
      "Desc": "f_iter(x, k, state) takes the iterate x of the method (the real form [Vre; Vim; ...] of\n\"newton\", \"levenberg-marquardt\" and \"fsolve\", [theta; V] of \"gradient\", the state\n[theta; omega; V; u] of \"dynamic\"), the iteration k (the virtual time for \"dynamic\") and\nstate \"init\", \"iter\" or \"done\", and returns stop.\n\n- \"residual\": one bar per power equation (two per bus, in the order of f_res: P, or\n  the angle at the slack bus; Q, or |V| at PV and slack buses), with the height |F| of\n  the equation at the iterate (log scale from a decade below the smallest nonzero\n  residual and Tolerance to a decade above the largest; an exact zero has no bar;\n  Tolerance as a dashed line; the legend above the axes). One figure (Tag\n  \"GUILDA:PlotFcn:residual\") is reused; it is redrawn at most every\n  0.2 s and at the end (so that drawing does not slow the iteration down).\n- A function handle is called at every iterate as stop = PlotFcn(x, optimValues, state)\n  with x the complex bus voltages and optimValues.iteration, .fval (F of the iterate),\n  .residual (largest |F|) and, for \"dynamic\", .time (virtual time; .iteration counts\n  the ODE steps).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "power_equation",
      "Defining": "SolverPF",
      "Group": "power",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "cm_Y",
        "tab_PFcondition"
      ],
      "OutputNames": [
        "f_res",
        "f_jac",
        "f_grad"
      ],
      "Arguments": [
        {
          "Name": "cm_Y",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus admittance matrix (complex, in the bus order of tab_PFcondition)."
        },
        {
          "Name": "tab_PFcondition",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Power flow conditions of the buses (rows of get_pf_condition)."
        }
      ],
      "Outputs": [
        {
          "Name": "f_res",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Residual F(x) (2*n_bus x 1)."
        },
        {
          "Name": "f_jac",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Jacobian dF/dx (sparse, 2*n_bus x 2*n_bus)."
        },
        {
          "Name": "f_grad",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "d, r",
          "Description": "= f_grad(xp) of \"gradient\"."
        }
      ],
      "Signature": "[f_res, f_jac, f_grad] = power_equation(cm_Y, tab_PFcondition)",
      "File": "_GUILDAsystem/_auxiliary/@SolverPF/private/power_equation.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Power equations of the buses and their Jacobian, shared by the power flow methods.",
      "Desc": "The unknowns x are the bus voltages in real form [Vre_1; Vim_1; Vre_2; Vim_2; ...].\nEach bus gives two residuals (calculated - specified), in the order of x:\nPQ bus [P; Q], PV bus [P; |V|], slack bus [angle [rad]; |V|]. P and Q are the injected\npowers [pu] computed from x with cm_Y.\nFor \"gradient\", f_grad works on the polar form xp = [theta; V] (n_bus each) and returns\nthe step direction d = [dP; dQ./V] and the mismatch r = [dP; dQ] (dP = P_set - P is 0\nat the slack bus, dQ is 0 at the slack and PV buses); d and r are NaN when a V <= 0.",
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
