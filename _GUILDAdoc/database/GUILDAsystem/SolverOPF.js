(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["SolverOPF"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "SolverOPF",
  "properties": [
    {
      "Name": "rm_Vwarm",
      "Defining": "SolverOPF",
      "Group": "Warm start",
      "GetAccess": "private",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": false,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "zeros(0,2)",
      "Validation": {
        "Class": "double",
        "Size": "(:,2)",
        "Validators": []
      },
      "Unit": "rad, pu",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/SolverOPF.m",
      "Line": 71,
      "Summary": "Varg and V of the buses in the last solved \"AC OPF\"; empty when none.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sv_warmBus",
      "Defining": "SolverOPF",
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
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/SolverOPF.m",
      "Line": 72,
      "Summary": "Bus tags of rm_Vwarm (row names of the bus table it was solved for).",
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
      "Defining": "SolverOPF",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "prob",
        "x0",
        "tab_bus",
        "tab_component",
        "tab_branch",
        "sct_options"
      ],
      "OutputNames": [
        "sct_solution",
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
          "Description": "Solver (net.solver_OPF)."
        },
        {
          "Name": "prob",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "optimproblem to solve; it holds the variables of the problem built from the tables."
        },
        {
          "Name": "x0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Initial point: values by variable name."
        },
        {
          "Name": "tab_bus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Buses (see build_problem)."
        },
        {
          "Name": "tab_component",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Components (see build_problem)."
        },
        {
          "Name": "tab_branch",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Branches (see build_problem)."
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
          "Description": "Options of calculate_optimal_powerflow: Method, Solver, Tolerance, MaxIteration, Verbose, PlotFcn, WarmStart (see optimoption), Progress (a mode or a ProgressGUILDA to use; \"none\" when absent)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_solution",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "tab_bus, tab_cub, tab_branch, r_cost, lambda, OPFprob and sct_iteration (fmincon only; see ResultOPF)."
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
          "Description": "exitflag of solve (positive = solved)."
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
        }
      ],
      "Signature": "[sct_solution, flag, output] = solve(obj, prob, x0, tab_bus, tab_component, tab_branch, sct_options)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/solve.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverOPF:InvalidProblem"
      ],
      "Summary": "Solve an optimal power flow problem and return the solution.",
      "Desc": "Solves the problem prob (built by net.build_opf_problem, or given by the user) from the\ninitial point x0 with the solver options of sct_options, and returns the solution as a\nstruct; the problem is not built again and no network object is read. The tables of the\nbuses, components and branches (the data the problem was built from) give the rows of\nthe result tables; the flows of the branches are computed from the solved bus voltages.\nThe caller builds the ResultOPF. A problem without the variables of the buses and\ncomponents (or with other sizes) stops with GUILDA:SolverOPF:ProblemMismatch. With\nsct_options.WarmStart, the bus values of x0 are replaced by the bus voltages of the last\nsolved \"AC OPF\" when it was solved for the same bus tags (in the same order); the solver\nkeeps only these voltages, with their bus tags (see SolverOPF). Called by\nnet.calculate_optimal_powerflow; calling it directly is for advanced use. Without\nOptimization Toolbox it stops with GUILDA:require_toolbox:Unavailable before anything is\nsolved.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "disp_formulation",
      "Defining": "SolverOPF",
      "Group": "disp",
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
          "Name": "Method",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Method, [\"ELD\",\"DC OPF\",\"AC OPF\"])"
          ],
          "Default": "GUILDA.config(\"OptimalPowerFlow\", \"Method\")",
          "Required": false,
          "Unit": "",
          "Description": "Formulation shown."
        },
        {
          "Name": "Problem",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "optim.problemdef.OptimizationProblem",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Problem whose constraints are counted (built for the same Method)."
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
          "Description": "Text when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_formulation(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/disp_formulation.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Display the formulation of the optimal power flow: objective and constraints by Method.",
      "Desc": "Shows the general form that build_problem builds for Method: the variables, the\nobjective GenCost and each kind of constraint with its name in the problem (<bus>,\n<component>, <branch> and the branch end <branch>_<bus> stand for the tags). \"AC OPF\":\nmin sum of C_g(P_g, Q_g) subject to P_i(V, Varg) = sum of P_g and Q_i(V, Varg) = sum of\nQ_g at every bus (the injections of the components: generation positive, load\nnegative), the bounds of P_g, Q_g and V_i, the reference angle and the branch limits\nPmax, Qmax, Imax, Smax, Vargmax; \"DC OPF\" the same with |V| = 1, P only and the\nMATPOWER flows; \"ELD\" one balance of P. With Problem (e.g. prob of net.build_opf_problem)\neach line also shows how many constraints of that kind the problem has (bounds: the\nvariables with a finite bound), and the constraints of other names (Constraint, or added\nby the user) are counted on a last line. The solver is not read or changed. With one\noutput it returns the text instead of displaying it.",
      "SeeAlso": [
        "SolverOPF.build_problem",
        "PowerNetwork.build_opf_problem"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.solver_OPF.disp_formulation(Method=\"DC OPF\")\nprob = net.build_opf_problem(Method=\"AC OPF\");\nnet.solver_OPF.disp_formulation(Method=\"AC OPF\", Problem=prob)   % with the counts\n```",
      "Deprecated": ""
    },
    {
      "Name": "build_problem",
      "Defining": "SolverOPF",
      "Group": "build",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "tab_bus",
        "tab_component",
        "tab_branch",
        "sct_options"
      ],
      "OutputNames": [
        "prob",
        "x0"
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
          "Description": "Solver (net.solver_OPF); not read."
        },
        {
          "Name": "tab_bus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Buses: Vmin, Vmax, Gshunt, Bshunt, Type, V, Varg; row names = bus tags."
        },
        {
          "Name": "tab_component",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Components: Bus, HP, fP, HQ, fQ, c, P0, Q0, Pmin, Pmax, Qmin, Qmax; row names = tags."
        },
        {
          "Name": "tab_branch",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Branches: From, To, Y (2x2 pages), X, tap, phase, Pmax, Qmax, Vargmax, Imax, Smax; row names = tags."
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
          "Description": "Settings: Method, Cost, Constraint, DefaultCost, ReferenceBus (bus tag or \"none\"), base (baseMVA, Hz)."
        }
      ],
      "Outputs": [
        {
          "Name": "prob",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "optimproblem; its Description shows the OPF data of the buses, components and branches."
        },
        {
          "Name": "x0",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Initial point: struct of the values of every variable, by variable name."
        }
      ],
      "Signature": "[prob, x0] = build_problem(obj, tab_bus, tab_component, tab_branch, sct_options)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/build_problem.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverOPF:UnknownReferenceBus"
      ],
      "Summary": "Build the optimization problem of the optimal power flow from the data of a network.",
      "Desc": "Builds the optimproblem for sct_options.Method from the tables of the buses, components\nand branches that net.build_opf_problem collects from tab_parameter (rows named by tag;\nsee that method); no network object and no state of the solver is read. Called by\nnet.build_opf_problem, which net.calculate_optimal_powerflow calls.\n\n- Variables: one per bus ([Varg; V] in \"AC OPF\", Varg in \"DC OPF\", none in \"ELD\") and\n  per component ([P; Q] in \"AC OPF\", P otherwise), named by tag. Branches have no\n  variables: the flow at each end is an expression of the voltages of its end buses.\n- Bounds from the tables (tab_parameter.operation); an infinite bound (NaN for the\n  branch limits) adds no limit. The fixed P (Q) of a load is in its bounds.\n- Constraints: power balance balancedP_<bus> / balancedQ_<bus> (balancedP in \"ELD\"):\n  the injections of the components = the shunt and branch flows of the bus (P_i(V, Varg),\n  Q_i(V, Varg)); branch limits at each end <branch>_<bus>: Pmax_ ([P; -P] <= Pmax),\n  Qmax_, Imax_, Smax_ (\"AC OPF\"); VargMax1_<branch>, VargMax2_<branch>; and VargRef\n  (ReferenceBus).\n- Objective GenCost: HP*P^2 + fP*P + HQ*Q^2 + fQ*Q + c of every component (DefaultCost),\n  plus Cost(v, p).\n- Constraint(v, p) adds named constraints prob.Constraints.<name>.\nx0 is the flat start: the bus voltages angle 0 and magnitude 1, with the set V at PV and\nslack buses and the set angle at the slack bus, and P0, Q0 of the components. The warm\nstart replaces the bus values in SolverOPF.solve.",
      "SeeAlso": [
        "PowerNetwork.build_opf_problem",
        "SolverOPF.solve"
      ],
      "Examples": "```matlab\n% the data as net.build_opf_problem collects them, e.g. one bus with one generator\ntab_bus = table(0.9, 1.1, 0, 0, \"slack\", 1, 0, 'VariableNames', ...\n    [\"Vmin\",\"Vmax\",\"Gshunt\",\"Bshunt\",\"Type\",\"V\",\"Varg\"], 'RowNames', \"B1\");\ntab_com = table(\"B1\", 1, 1, 0, 0, 0, 1, 0, 0, 2, -1, 1, 'VariableNames', ...\n    [\"Bus\",\"HP\",\"fP\",\"HQ\",\"fQ\",\"c\",\"P0\",\"Q0\",\"Pmin\",\"Pmax\",\"Qmin\",\"Qmax\"], 'RowNames', \"G1\");\ntab_br  = table(strings(0,1), strings(0,1), complex(zeros(0,2,2)), zeros(0,1), zeros(0,1), ...\n    zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), 'VariableNames', ...\n    [\"From\",\"To\",\"Y\",\"X\",\"tap\",\"phase\",\"Pmax\",\"Qmax\",\"Vargmax\",\"Imax\",\"Smax\"]);\nsct = struct(\"Method\",\"DC OPF\", \"Cost\",[], \"Constraint\",[], \"DefaultCost\",true, ...\n    \"ReferenceBus\",\"B1\", \"base\",struct(\"Hz\",60,\"baseMVA\",100));\n[prob, x0] = SolverOPF().build_problem(tab_bus, tab_com, tab_br, sct);\n```",
      "Deprecated": ""
    },
    {
      "Name": "SolverOPF",
      "Defining": "SolverOPF",
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
          "Description": "OPF solver."
        }
      ],
      "Signature": "obj = SolverOPF()",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/SolverOPF.m",
      "Line": 76,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create an OPF solver.",
      "Desc": "A network creates its own (net.solver_OPF); net.reset_solver() replaces it with a\nnew one, which discards the warm start.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "optimoption",
      "Defining": "SolverOPF",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "prob",
        "sct_options"
      ],
      "OutputNames": [
        "s_solver",
        "c_nv"
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
          "Name": "prob",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Problem built by build_opf_problem."
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
          "Description": "Options of the call (calculate_optimal_powerflow): Solver, Verbose, PlotFcn, MaxIteration, Tolerance, Method."
        }
      ],
      "Outputs": [
        {
          "Name": "s_solver",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Solver that runs the problem (linprog, quadprog or fmincon)."
        },
        {
          "Name": "c_nv",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Name-Value arguments of solve: Solver and Options when needed."
        }
      ],
      "Signature": "[s_solver, c_nv] = optimoption(obj, prob, sct_options)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/optimoption.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverOPF:UnsupportedSolver",
        "GUILDA:SolverOPF:PlotFcnUnsupported"
      ],
      "Summary": "Get the solver name and the solve() options for the options of the call and the settings.",
      "Desc": "Returns the Name-Value arguments of solve (Optimization Toolbox) for the options of the\ncall and the settings. Display follows Verbose (\"iter\" or \"none\"); the other settings are\npassed only when they differ from the defaults of the solver (NaN: the default).\nMaxIteration and Tolerance (options of the call) go to every solver; a setting\n<Solver><option> of GUILDA.setting (LinprogAlgorithm, QuadprogStepTolerance,\nFminconUseParallel, ...), which has no Name-Value option, is read here from\nGUILDA.config and goes only to that solver. PlotFcn becomes the PlotFcn\noption of fmincon (keys k as optimplot<k>, a handle as it is); with linprog or quadprog,\na PlotFcn other than \"none\" stops with GUILDA:SolverOPF:PlotFcnUnsupported.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "apply",
      "Defining": "SolverOPF",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "prob",
        "sct_options",
        "tab_bus",
        "tab_component",
        "tab_branch",
        "sct_var"
      ],
      "OutputNames": [
        "prob"
      ],
      "Arguments": [
        {
          "Name": "prob",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Problem being built."
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
          "Description": "Options of the call: Method, Cost, Constraint, base."
        },
        {
          "Name": "tab_bus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Bus table of the problem."
        },
        {
          "Name": "tab_component",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Component table of the problem."
        },
        {
          "Name": "tab_branch",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Branch table of the problem."
        },
        {
          "Name": "sct_var",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Optimization variables by variable name."
        }
      ],
      "Outputs": [
        {
          "Name": "prob",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Problem with the terms added."
        }
      ],
      "Signature": "prob = apply(prob, sct_options, tab_bus, tab_component, tab_branch, sct_var)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/private/apply.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverOPF:InvalidCost",
        "GUILDA:SolverOPF:InvalidConstraint",
        "GUILDA:SolverOPF:InvalidConstraintField",
        "GUILDA:SolverOPF:DuplicateName",
        "GUILDA:SolverOPF:HandleError"
      ],
      "Summary": "Add the Cost and Constraint options to the OPF problem.",
      "Desc": "- Cost: Cost(v, p) is added to the objective GenCost.\n- Constraint: each field <name> of Constraint(v, p) becomes prob.Constraints.<name>;\n  its dual has the same label in result.lambda.Constraints. A name already in the\n  problem stops with an error.\nv is variables(tab_bus, tab_component, tab_branch, sct_var, Method); p holds p.Method\nand p.base (sct_options.base: baseMVA, Hz of the network).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "branch_flow",
      "Defining": "SolverOPF",
      "Group": "branch",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "row",
        "rv_V",
        "rv_Varg",
        "s_method"
      ],
      "OutputNames": [
        "rm_flow"
      ],
      "Arguments": [
        {
          "Name": "row",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Row of the branch table (From, To, Y, X, tap, phase, ...)."
        },
        {
          "Name": "rv_V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "V of the end buses (From, To); not read in \"DC OPF\"."
        },
        {
          "Name": "rv_Varg",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,2)",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "rad",
          "Description": "Varg of the end buses (From, To)."
        },
        {
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "\"DC OPF\" or \"AC OPF\"."
        }
      ],
      "Outputs": [
        {
          "Name": "rm_flow",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "4 x 2 (\"AC OPF\") or 1 x 2 (\"DC OPF\") flows into the end buses."
        }
      ],
      "Signature": "rm_flow = branch_flow(row, rv_V, rv_Varg, s_method)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/private/branch_flow.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Flows at the two ends of one branch, from the voltages of its end buses.",
      "Desc": "Each column is one end (1: bus From, 2: bus To) and holds the flow from the branch into\nthat bus. \"AC OPF\": rows P, Q, Ireal, Iimag, from I = -Y*V (Y the 2x2 admittance\nmatrix of the branch, with its tap and phase) and S = V*conj(I). \"DC OPF\": one row P,\nwith |V| = 1, no losses and the MATPOWER flow b*(θi - θj - phase) from bus i,\nb = 1/(X*tap) (tap ratio and phase shift at the From end). The voltages are numbers\n(the solution, in solve) or optimization expressions (the problem, in build_branch);\nthe result is of the same kind.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_branch",
      "Defining": "SolverOPF",
      "Group": "build",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "row",
        "prob",
        "const",
        "sct_var",
        "s_method"
      ],
      "OutputNames": [
        "prob",
        "const",
        "sct_var"
      ],
      "Arguments": [
        {
          "Name": "row",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Row of the branch table (From, To, Y, X, tap, phase, Pmax, ...); row name = tag."
        },
        {
          "Name": "prob",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Problem being built."
        },
        {
          "Name": "const",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Power-balance expressions, extended."
        },
        {
          "Name": "sct_var",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Variables by name (with the end buses), extended."
        },
        {
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "\"ELD\", \"DC OPF\" or \"AC OPF\"."
        }
      ],
      "Outputs": [
        {
          "Name": "prob",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Problem with the limits added."
        },
        {
          "Name": "const",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Extended power-balance expressions."
        },
        {
          "Name": "sct_var",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "With the flows of the two ends (struct of P, Q, Ireal, Iimag; P in \"DC OPF\") by end name."
        }
      ],
      "Signature": "[prob, const, sct_var] = build_branch(row, prob, const, sct_var, s_method)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/private/build_branch.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add the flows and limits of one branch to the OPF problem.",
      "Desc": "The flow at each end (\"<branch>_<bus>\", from the branch into that bus) is an expression\nof the voltages of the end buses (branch_flow), added to the power balance of the bus;\na branch has no variables. Limits at both ends: |P| <= Pmax and, in \"AC OPF\",\n|Q| <= Qmax, |I|^2 <= Imax^2, P^2 + Q^2 <= Smax^2; and |Varg_i - Varg_j| <= Vargmax.\nNaN or Inf adds no limit. \"DC OPF\" has P only (MATPOWER flow b*(θi - θj - phase),\nb = 1/(X*tap)). \"ELD\" ignores branches.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_bus",
      "Defining": "SolverOPF",
      "Group": "build",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "row",
        "const",
        "s_method"
      ],
      "OutputNames": [
        "const",
        "var"
      ],
      "Arguments": [
        {
          "Name": "row",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Row of the bus table (Vmin, Vmax, Gshunt, Bshunt, ...); row name = bus tag."
        },
        {
          "Name": "const",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Power-balance expressions by \"P_<bus>\" / \"Q_<bus>\", extended."
        },
        {
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "\"ELD\", \"DC OPF\" or \"AC OPF\"."
        }
      ],
      "Outputs": [
        {
          "Name": "const",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Extended power-balance expressions."
        },
        {
          "Name": "var",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Variable of the bus; [] in \"ELD\"."
        }
      ],
      "Signature": "[const, var] = build_bus(row, const, s_method)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/private/build_bus.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add the variables and shunt power of one bus to the OPF problem.",
      "Desc": "\"AC OPF\": variable <bus> = [Varg; V] with Vmin <= V <= Vmax (±Inf removes a bound) and\nthe shunt power -V^2*Gshunt, V^2*Bshunt in the balance.\n\"DC OPF\": variable <bus> = Varg and the shunt power -Gshunt (|V| = 1). \"ELD\": none.\nThe initial values are set by start_point.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_component",
      "Defining": "SolverOPF",
      "Group": "build",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "row",
        "prob",
        "x0",
        "const",
        "s_method",
        "l_defaultCost"
      ],
      "OutputNames": [
        "prob",
        "x0",
        "const",
        "var"
      ],
      "Arguments": [
        {
          "Name": "row",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Row of the component table (Bus, HP, fP, HQ, fQ, c, P0, Q0, Pmin, ...); row name = tag."
        },
        {
          "Name": "prob",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Problem being built."
        },
        {
          "Name": "x0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Initial values, extended."
        },
        {
          "Name": "const",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Power-balance expressions, extended."
        },
        {
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "\"ELD\", \"DC OPF\" or \"AC OPF\"."
        },
        {
          "Name": "l_defaultCost",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Add the cost of tab_parameter.OPF."
        }
      ],
      "Outputs": [
        {
          "Name": "prob",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Problem with the cost added."
        },
        {
          "Name": "x0",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Extended initial values."
        },
        {
          "Name": "const",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Extended power-balance expressions."
        },
        {
          "Name": "var",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Variable of the component."
        }
      ],
      "Signature": "[prob, x0, const, var] = build_component(row, prob, x0, const, s_method, l_defaultCost)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/private/build_component.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Add the power variable, bounds and cost of one component to the OPF problem.",
      "Desc": "Variable <component> = [P; Q] (\"AC OPF\") or P, bounded by Pmin/Pmax, Qmin/Qmax (±Inf\nremoves a bound) and added to the balance of its bus. The fixed P (Q) of a load is\nalready in its bounds and start (see PowerNetwork.calculate_optimal_powerflow).\nWith l_defaultCost the cost HP*P^2 + fP*P (+ HQ*Q^2 + fQ*Q in \"AC OPF\") + c is added\nto the objective (c, a constant, changes the cost but not the solution).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "start_point",
      "Defining": "SolverOPF",
      "Group": "start",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "x0",
        "sv_bus",
        "rm_V",
        "s_method"
      ],
      "OutputNames": [
        "x0"
      ],
      "Arguments": [
        {
          "Name": "x0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Initial values by variable name."
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
          "Description": "Bus tags (row names of the bus table)."
        },
        {
          "Name": "rm_V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "rad, pu",
          "Description": "Start Varg and V of each bus of sv_bus."
        },
        {
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "\"ELD\", \"DC OPF\" or \"AC OPF\"."
        }
      ],
      "Outputs": [
        {
          "Name": "x0",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Initial values with the bus values set."
        }
      ],
      "Signature": "x0 = start_point(x0, sv_bus, rm_V, s_method)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/private/start_point.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Set the bus values of the OPF initial point from bus voltages.",
      "Desc": "Sets x0.<bus> to the start voltage of each bus: [Varg; V] in \"AC OPF\", Varg in\n\"DC OPF\"; \"ELD\" has no bus variables. Called by build_problem (the flat start) and\nsolve (the warm start).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "variables",
      "Defining": "SolverOPF",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "tab_bus",
        "tab_component",
        "tab_branch",
        "sct_var",
        "s_method"
      ],
      "OutputNames": [
        "v"
      ],
      "Arguments": [
        {
          "Name": "tab_bus",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Bus table (row names = bus tags)."
        },
        {
          "Name": "tab_component",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Component table (row names = tags; Bus)."
        },
        {
          "Name": "tab_branch",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Branch table (row names = tags; From, To)."
        },
        {
          "Name": "sct_var",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Optimization variables by variable name and the flows of the branch ends (from build_problem)."
        },
        {
          "Name": "s_method",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "\"ELD\", \"DC OPF\" or \"AC OPF\"."
        }
      ],
      "Outputs": [
        {
          "Name": "v",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Variables by kind and tag (see above)."
        }
      ],
      "Signature": "v = variables(tab_bus, tab_component, tab_branch, sct_var, s_method)",
      "File": "_GUILDAsystem/_auxiliary/@SolverOPF/private/variables.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Collect the optimization variables that the Cost and Constraint handles receive (first argument v).",
      "Desc": "- v.Component.(tag): P (all methods), Q (\"AC OPF\").\n- v.Bus.(tag): Varg (\"DC OPF\", \"AC OPF\"), V (\"AC OPF\"); no fields in \"ELD\".\n- v.Branch.(tag): Pfrom, Pto, Vargfrom, Vargto (\"DC OPF\", \"AC OPF\"); Qfrom, Qto,\n  Ifrom_re, Ifrom_im, Ito_re, Ito_im, Vfrom, Vto (\"AC OPF\"); no fields in \"ELD\".\n  Flows go into the branch at each end (from = From, to = To of the branch table), with\n  the signs of ResultOPF.tab_branch.",
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
