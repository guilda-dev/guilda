(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["SolverCPF"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "SolverCPF",
  "properties": [
    {
      "Name": "LoadBus",
      "Defining": "SolverCPF",
      "Group": "Conditions",
      "GetAccess": "public",
      "SetAccess": "public",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "strings(1,0)",
      "Validation": {
        "Class": "string",
        "Size": "(1,:)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/SolverCPF.m",
      "Line": 62,
      "Summary": "Tags of the buses whose loads are scaled by (1 + lambda); must not be empty when solving.",
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
      "Defining": "SolverCPF",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "net",
        "sct_options"
      ],
      "OutputNames": [
        "result",
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
          "Description": "Solver (net.solver_CPF)."
        },
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Network initialized by net.initialize."
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
          "Description": "Name-Value options of net.calculate_continuation_powerflow (defaults from GUILDA.setting and LoadBus of the solver; Progress a mode or a ProgressGUILDA to use, \"none\" when absent)."
        }
      ],
      "Outputs": [
        {
          "Name": "result",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "lambda, bus voltages and operating points along the path, the nose point and the voltage stability information."
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
          "Description": "True when the path passed the nose (lambda reached its maximum and decreased) or stopped at a \"V\" or \"S\" limit after at least one step."
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
          "Description": "Details: message, iterations, correctorIterations."
        }
      ],
      "Signature": "[result, flag, output] = solve(obj, net, sct_options)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/solve.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverCPF:LimitsInternalState",
        "GUILDA:SolverCPF:InputEdited",
        "GUILDA:SolverCPF:NoEquilibrium",
        "GUILDA:SolverCPF:Stale",
        "GUILDA:SolverCPF:EmptyLoadBus",
        "GUILDA:SolverCPF:UnknownLoadBus",
        "GUILDA:SolverCPF:InvalidLimits"
      ],
      "Summary": "Trace the PV curve with the given settings.",
      "Desc": "Runs the continuation power flow of net with the options sct_options of the call and\nreturns the traced path as a ResultCPF, with the operating point and the smallest\nsingular value of the power flow Jacobian at each step (see ResultCPF). The solver is only read: nothing is written\nback into it. The CPF working data of the models (bus.iv_CPFV, comp.iv_CPFX,\ncomp.f_PQ2Bus) is rebuilt for this run. Called by net.calculate_continuation_powerflow;\ncalling it directly is for advanced use.\nIt stops with an error naming the remedy when the network has no equilibrium\n(run net.initialize), when the equilibrium is stale, or when LoadBus is empty or names\na bus that is not in the network. With options.Limits, the PV buses switched to PQ and\nthe limit that ended the path are in result.tab_switch and result.tab_stop.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "SolverCPF",
      "Defining": "SolverCPF",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "varargin"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
        {
          "Name": "varargin",
          "Kind": "Repeating",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Arguments of the removed v3 form (any of them stops with an error)."
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
          "Description": "CPF solver with an empty LoadBus."
        }
      ],
      "Signature": "obj = SolverCPF(varargin)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/SolverCPF.m",
      "Line": 66,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a CPF solver with no LoadBus (the settings are read at each run).",
      "Desc": "A network creates its own (net.solver_CPF); net.reset_solver() replaces it with a\nnew one. Any argument (the v3 form SolverCPF(net, Name, Value)) stops with\nGUILDA:v3_cpf_constructor:ContinuationPowerFlowConstructor.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_layout",
      "Defining": "SolverCPF",
      "Group": "build",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "net",
        "useInt",
        "lv_PQ"
      ],
      "OutputNames": [
        "w"
      ],
      "Arguments": [
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Network initialized by net.initialize."
        },
        {
          "Name": "useInt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True to solve with the internal states of the components."
        },
        {
          "Name": "lv_PQ",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "false(numel(net.a_Bus),1)",
          "Required": false,
          "Unit": "",
          "Description": "PV buses switched to PQ by Limits \"Q\" (rows of net.a_Bus; only without useInt)."
        }
      ],
      "Outputs": [
        {
          "Name": "w",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Variable layout (fields above)."
        }
      ],
      "Signature": "w = build_layout(net, useInt, lv_PQ)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/private/build_layout.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:build_layout:MissingGetCompPQ"
      ],
      "Summary": "Variable layout of the CPF equations for net (the PV buses of lv_PQ solved as PQ buses).",
      "Desc": "Writes the analysis working data on the models (bus.iv_CPFV, comp.iv_CPFX,\n  comp.f_PQ2Bus) and returns\n  w.rv_BusVi : rows of [|V|;angle V] of each bus in the full variable vector\n  w.rm_BusRM : selects the equations that are solved\n  w.rm_BusEM : maps the unknowns into the full variable vector\n  w.CONSTANT : fixed part of the full variable vector\n  w.InitVal  : unknowns at the equilibrium\n  w.c_lvFree : per bus, the components with Q = NaN in powerflow (the generators of a\n               PV bus, whose Q Limits \"Q\" bounds)\n  w.rv_Qfix  : per bus, the fixed Q of these components after a switch to PQ (NaN: none;\n               set by SolverCPF.solve, see pf_equation)",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "correct",
      "Defining": "SolverCPF",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "NRM",
        "f_PF",
        "f_Jac",
        "delta_s",
        "x_current",
        "x_pred"
      ],
      "OutputNames": [
        "x_correct",
        "x_current",
        "N"
      ],
      "Arguments": [
        {
          "Name": "NRM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "MethodNewtonRaphson",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Newton-Raphson solver of the corrector."
        },
        {
          "Name": "f_PF",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Power flow equations of the CPF (pf_equation)."
        },
        {
          "Name": "f_Jac",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Jacobian of f_PF."
        },
        {
          "Name": "delta_s",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Arc length of the corrector."
        },
        {
          "Name": "x_current",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Current point [unknowns; lambda]."
        },
        {
          "Name": "x_pred",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Predicted point (start of the iteration)."
        }
      ],
      "Outputs": [
        {
          "Name": "x_correct",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Corrected point."
        },
        {
          "Name": "x_current",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Point before the correction (the next x_past)."
        },
        {
          "Name": "N",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Number of Newton-Raphson steps."
        }
      ],
      "Signature": "[x_correct, x_current, N] = correct(NRM, f_PF, f_Jac, delta_s, x_current, x_pred)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/private/correct.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Corrector of the CPF: Newton-Raphson on the power flow equations plus the arc",
      "Desc": "length condition |x - x_current|^2 = delta_s, starting from x_pred. Reaching MaxIter\nwarns GUILDA:MethodNewtonRaphson:MaxIteration.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "correct_at",
      "Defining": "SolverCPF",
      "Group": "correct",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "NRM",
        "f_PF",
        "f_Jac",
        "x0",
        "x_center"
      ],
      "OutputNames": [
        "x",
        "N"
      ],
      "Arguments": [
        {
          "Name": "NRM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "MethodNewtonRaphson",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Newton-Raphson solver of the corrector."
        },
        {
          "Name": "f_PF",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Power flow equations of the CPF (pf_equation)."
        },
        {
          "Name": "f_Jac",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Jacobian of f_PF."
        },
        {
          "Name": "x0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Start point [unknowns; lambda] (interpolated crossing)."
        },
        {
          "Name": "x_center",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Last point of the path, or [] to fix lambda."
        }
      ],
      "Outputs": [
        {
          "Name": "x",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Corrected point."
        },
        {
          "Name": "N",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Number of Newton-Raphson steps."
        }
      ],
      "Signature": "[x, N] = correct_at(NRM, f_PF, f_Jac, x0, x_center)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/private/correct_at.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Corrector to the path point near x0, where the path meets an operating limit: at the",
      "Desc": "lambda of x0 when x_center is empty, otherwise on the sphere around x_center through x0\n(which also works at the nose). Reaching MaxIter warns GUILDA:MethodNewtonRaphson:MaxIteration.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "limit_set",
      "Defining": "SolverCPF",
      "Group": "limit",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "net",
        "sv_limits",
        "w",
        "sv_load"
      ],
      "OutputNames": [
        "lim"
      ],
      "Arguments": [
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Network of the CPF."
        },
        {
          "Name": "sv_limits",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Kinds of limits: members of \"Q\", \"V\", \"S\"."
        },
        {
          "Name": "w",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Variable layout (output of build_layout)."
        },
        {
          "Name": "sv_load",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the buses whose loads are scaled."
        }
      ],
      "Outputs": [
        {
          "Name": "lim",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "sv_kind, iv_object, sv_class, sv_object, sv_limit, rv_bound,"
        }
      ],
      "Signature": "lim = limit_set(net, sv_limits, w, sv_load)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/private/limit_set.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Operating limits that Limits applies along the CPF path, one row per finite limit.",
      "Desc": "- \"Q\": a PV bus (not the slack bus) with the sums of Qmin and Qmax over its generators\n  (w.c_lvFree), Class \"Bus\". The monitored value is the Q of these generators: the Q\n  injected into the network minus the Q of the other components of the bus.\n- \"V\": Vmin and Vmax of each bus, Class \"Bus\", on |V|.\n- \"S\": Smax of each branch, Class \"Branch\", on the larger |S| of its two ends.\nInf and NaN limits are none.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "limit_values",
      "Defining": "SolverCPF",
      "Group": "limit",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "lim",
        "w",
        "xf",
        "Ymat"
      ],
      "OutputNames": [
        "rv_g"
      ],
      "Arguments": [
        {
          "Name": "lim",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Monitored limits (output of limit_set)."
        },
        {
          "Name": "w",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Variable layout (output of build_layout)."
        },
        {
          "Name": "xf",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Full variable vector of the point, lambda in the last row."
        },
        {
          "Name": "Ymat",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus admittance matrix (complex)."
        }
      ],
      "Outputs": [
        {
          "Name": "rv_g",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Q of the generators, |V| or the larger |S| of a branch, per row."
        }
      ],
      "Signature": "rv_g = limit_values(lim, w, xf, Ymat)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/private/limit_values.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Values that the rows of lim (see limit_set) bound, at the full point xf = [variables; lambda].",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "live_pvcurve",
      "Defining": "SolverCPF",
      "Group": "live",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "PlotFcn",
        "sv_bus",
        "iv_V"
      ],
      "OutputNames": [
        "f_step"
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
          "Description": "Display keys (\"pvcurve\") or a function handle (output of tools.check_plotfcn)."
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
          "Description": "Bus tags, in the bus order of the path."
        },
        {
          "Name": "iv_V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Rows of |V| and angle V of each bus in the full point (w.rv_BusVi)."
        }
      ],
      "Outputs": [
        {
          "Name": "f_step",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "stop = f_step(xf, n_corr, k, state)."
        }
      ],
      "Signature": "f_step = live_pvcurve(PlotFcn, sv_bus, iv_V)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/private/live_pvcurve.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Live display of the continuation power flow (PlotFcn), called at each point of the path.",
      "Desc": "stop = f_step(xf, n_corr, k, state) takes the full point xf of the path ([|V|; angle V\nof each bus (and states); lambda], rows iv_V = w.rv_BusVi), the corrector iterations\nn_corr of the step, the step k (0 at the starting point) and state \"init\" (starting\npoint), \"iter\" (each step) or \"done\" (after the last step, xf the last point).\n\n- \"pvcurve\": |V| of every bus against lambda, one line per bus, extended at each step.\n  One figure (Tag \"GUILDA:PlotFcn:pvcurve\") is reused; it is redrawn at most every\n  0.2 s and at the end (so that drawing does not slow the trace down).\n- A function handle is called at every point as stop = PlotFcn(x, optimValues, state)\n  with x the complex bus voltages and optimValues.iteration (step), .lambda and\n  .correctorIterations (of the step; 0 at the starting point).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "operating_points",
      "Defining": "SolverCPF",
      "Group": "operating",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "net",
        "sct_network",
        "sv_load",
        "useInt",
        "cm_Vbus",
        "rm_x",
        "rv_lambda",
        "Ymat"
      ],
      "OutputNames": [
        "tab_variable",
        "rm_variable",
        "cm_Icomponent"
      ],
      "Arguments": [
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Analysed network (only read)."
        },
        {
          "Name": "sct_network",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Snapshot struct(net, false) (its buses for tools.distribute_power)."
        },
        {
          "Name": "sv_load",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the buses whose loads are scaled."
        },
        {
          "Name": "useInt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True when the CPF used the internal states of the components."
        },
        {
          "Name": "cm_Vbus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus voltages at each step (n_bus x n_step)."
        },
        {
          "Name": "rm_x",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Full variable vector at each step (rows of comp.iv_CPFX with useInt)."
        },
        {
          "Name": "rv_lambda",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "lambda at each step."
        },
        {
          "Name": "Ymat",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus admittance matrix (complex)."
        }
      ],
      "Outputs": [
        {
          "Name": "tab_variable",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Rows x, Vre, Vim, u, uc of net.get_variable_map()."
        },
        {
          "Name": "rm_variable",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Values: row k at step k, column m the row m of tab_variable."
        },
        {
          "Name": "cm_Icomponent",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "pu",
          "Description": "Current injected by each component (rows in network order) at each step."
        }
      ],
      "Signature": "[tab_variable, rm_variable, cm_Icomponent] = operating_points(net, sct_network, sv_load, useInt, cm_Vbus, rm_x, rv_lambda, Ymat)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/private/operating_points.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Operating point of every step of the CPF path, in the rows of net.get_variable_map().",
      "Desc": "At each step the bus injection V conj(Y V) is split to the components of the bus as\ninitialize splits a power flow solution (tools.distribute_power on the network snapshot):\neach component starts from the power it injects in the CPF equations (pf_equation: its\nequilibrium power, scaled by (1 + lambda) on the buses of sv_load) and the free parts go\nto the components of the bus with Q = NaN (and to the first such component of the slack\nbus for P), so a PV bus switched to PQ by Limits \"Q\" keeps its fixed Q. With useInt the\ncomponents inject their getCompPQ powers (all solved by the CPF), taken as they are.\nEach component then gets (x, u) from its own get_equilibrium(V, I, P, Q). With useInt, a\ncomponent with CPF states takes x from rm_x and u = rv_Uequilibrium, the input of the CPF\nequations, so that dx = 0 holds for the state equations the CPF solves (a component\nwithout states keeps the u of get_equilibrium, which carries its scaled power). Its local\ncontrollers get x and uc from their\nget_equilibrium(V, u, x) (get_equilibrium_at, x the state of the component at the step)\nin the order of Component.set_equilibrium (depth first); a\ncontroller input observed on the component (iv_obsX / iv_obsY) takes the value of the\ncomponent at the step. The states and inputs of the global controllers keep their\nequilibrium values. Only pure functions of the models are called: nothing is written.\nA model whose get_equilibrium stops at a step (e.g. a limit of its range) gives NaN for\nits values at that step.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "pf_equation",
      "Defining": "SolverCPF",
      "Group": "pf",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "net",
        "w",
        "sv_load",
        "useInt",
        "x",
        "Ymat"
      ],
      "OutputNames": [
        "func"
      ],
      "Arguments": [
        {
          "Name": "net",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Analysed network."
        },
        {
          "Name": "w",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Variable layout (output of build_layout)."
        },
        {
          "Name": "sv_load",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Tags of the buses whose loads are scaled."
        },
        {
          "Name": "useInt",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True to use the internal states of the components."
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
          "Description": "Point [unknowns; lambda]."
        },
        {
          "Name": "Ymat",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus admittance matrix (complex)."
        }
      ],
      "Outputs": [
        {
          "Name": "func",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Residuals of the solved equations."
        }
      ],
      "Signature": "func = pf_equation(net, w, sv_load, useInt, x, Ymat)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/private/pf_equation.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Power flow equations of the CPF at x = [unknowns; lambda] (layout w, see build_layout).",
      "Desc": "The loads of the buses sv_load (all loads when useInt) are scaled by (1 + lambda).\nOn a bus with w.rv_Qfix not NaN (switched to PQ by Limits \"Q\"), the components of\nw.c_lvFree inject Q = w.rv_Qfix in place of their own Q.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "predict",
      "Defining": "SolverCPF",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "f_Jac",
        "h",
        "x_current",
        "x_past",
        "t_old"
      ],
      "OutputNames": [
        "x_pred",
        "t_old"
      ],
      "Arguments": [
        {
          "Name": "f_Jac",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "function_handle",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Jacobian of the power flow equations of the CPF."
        },
        {
          "Name": "h",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Step size of the predictor."
        },
        {
          "Name": "x_current",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Current point [unknowns; lambda]."
        },
        {
          "Name": "x_past",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Previous point, or [] at the first step."
        },
        {
          "Name": "t_old",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Last tangent, or [] before the first one."
        }
      ],
      "Outputs": [
        {
          "Name": "x_pred",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Predicted point."
        },
        {
          "Name": "t_old",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Last tangent (updated at the first step)."
        }
      ],
      "Signature": "[x_pred, t_old] = predict(f_Jac, h, x_current, x_past, t_old)",
      "File": "_GUILDAsystem/_auxiliary/@SolverCPF/private/predict.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Predictor of the CPF: the tangent at the first step (x_past empty), the secant",
      "Desc": "from the previous step afterwards. t_old is the last tangent (orientation).",
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
