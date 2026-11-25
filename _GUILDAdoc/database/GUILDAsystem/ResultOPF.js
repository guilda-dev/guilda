(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["ResultOPF"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "ResultOPF",
  "properties": [
    {
      "Name": "tab_bus",
      "Defining": "ResultOPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 79,
      "Summary": "Bus values of the solution, one row per bus; columns by method (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_cub",
      "Defining": "ResultOPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 80,
      "Summary": "Injection into the bus of each connection (components, then branch ends), in bus order (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "tab_branch",
      "Defining": "ResultOPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 81,
      "Summary": "Branch flows into the branch at each end, one row per branch; columns by method (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "r_cost",
      "Defining": "ResultOPF",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 82,
      "Summary": "Optimal value of the objective (total generation cost of tab_parameter.OPF).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "lambda",
      "Defining": "ResultOPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 83,
      "Summary": "Lagrange multipliers of the solution, by constraint and variable name (see the class help).",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "OPFprob",
      "Defining": "ResultOPF",
      "Group": "Result",
      "GetAccess": "public",
      "SetAccess": "private",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 84,
      "Summary": "Optimization problem that was solved; its Description shows the OPF settings of the run.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "optim.problemdef.OptimizationProblem (1x1 or empty)",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_iteration",
      "Defining": "ResultOPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 85,
      "Summary": "Iterations of fmincon: Iteration, Fval, ConstrViolation, X (see the class help); empty struct for linprog and quadprog.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_stability",
      "Defining": "ResultOPF",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 86,
      "Summary": "Stability-constrained OPF: tab_iteration and tab_mode (see the class help); empty struct without MinDampingRatio and MaxRealPart.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
      "Stale": "",
      "Deprecated": ""
    },
    {
      "Name": "sct_network",
      "Defining": "ResultOPF",
      "Group": "Data of the calculation",
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
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 89,
      "Summary": "Snapshot of the network at the calculation: struct(net, false), a nested struct without handles.",
      "Desc": "",
      "SeeAlso": [],
      "Type": "",
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
      "Name": "plot_iteration",
      "Defining": "ResultOPF",
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
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure."
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
          "Description": "The four panels of the iterations (GraphChart)."
        }
      ],
      "Signature": "G = plot_iteration(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/plot_iteration.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:ResultOPF:NoIteration"
      ],
      "Summary": "Draw the iterations of the AC optimal power flow as a chart of four panels.",
      "Desc": "Draws sct_iteration (recorded by fmincon at every \"AC OPF\" run) as one GraphChart with\nfour panels in a 2-by-2 grid against the iteration number, in rows: the objective (line\ntag \"Fval\"), the largest constraint violation on a log scale (tag \"ConstrViolation\"),\nP of each generator (a component whose P bounds differ; tags of the generators) and |V|\nof each bus (tags of the buses). The four panels are time panels whose times are the\niteration numbers (sct_iteration.Iteration): set_time(k) moves the cursor of every\npanel to iteration k, and the TimeChangedFcn of the chart writes the title \"OPF\niteration k (i of n)\" of the iteration shown (the last one at first). The chart has no\nplayback bar, as its time only moves the cursor (see GraphChart). A line is found by\nits tag in G.tab_element, and the first row of the data tip of a line is its name (the\ntag, e.g. the generator or bus). The chart is drawn in the container Parent. \"ELD\" and\n\"DC OPF\" (linprog, quadprog) record no iterations and stop with\nGUILDA:ResultOPF:NoIteration. It reads only the stored result.",
      "SeeAlso": [
        "ResultOPF.sct_iteration",
        "ResultOPF.plot_lmp",
        "ResultPF.plot_convergence",
        "GraphChart"
      ],
      "Examples": "```matlab\nres = network.IEEE14bus().calculate_optimal_powerflow(Method=\"AC OPF\");\nG = res.plot_iteration();\nG.set_time(3);                      % cursor and title at iteration 3\nG.tab_element                       % the lines: Fval, ConstrViolation, generators, buses\nG.set_style(\"B001\", LineWidth=3);   % pick out the |V| of bus B001\n```",
      "Deprecated": ""
    },
    {
      "Name": "plot_lmp",
      "Defining": "ResultOPF",
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
        }
      ],
      "Signature": "G = plot_lmp(obj, opt, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/plot_lmp.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Draw the locational marginal prices on the network diagram (GraphNetDiagram).",
      "Desc": "Each bus is colored by its LMP (get_lmp, cost per pu), with a color bar (ColorbarLabel\n\"LMP [cost/pu]\") and the title \"LMP of <network> (<Method>)\"; the color limits\nare the lowest and the highest LMP. The branches with a binding limit (the branch\nconstraints of disp_binding: Pmax, Qmax, Imax, Smax, VargMax) are selected, so they are\ndrawn in SelectionColor. The state of the diagram is the solution: the bus voltages\n(Vphasor in \"AC OPF\"; |V| = 1 and the angle Varg in \"DC OPF\"; V = 1 in \"ELD\", which has\nno angles) and the component powers of tab_cub. The branches and links keep a neutral\ncolor. The labels are LabelMode \"value\": each bus label shows its tag, ∠V, |V| and the\nline \"LMP [cost/pu]=<value>\", and each component label its tag, P and Q; the data\ntip of a bus shows the same LMP line. Works for \"ELD\", \"DC OPF\" and \"AC OPF\"; it reads\nonly the stored result. The other Name-Value options set the properties of the\nGraphNetDiagram (they override the color and label settings above, e.g. LabelMode=\"bus\"\nfor the bus tags only).",
      "SeeAlso": [
        "ResultOPF.get_lmp",
        "ResultOPF.disp_binding",
        "GraphNetDiagram"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.a_Branch{1}.tab_parameter.operation.Pmax = 1;\nres = net.calculate_optimal_powerflow(Method=\"DC OPF\");\nG = res.plot_lmp();\nG.Selection                 % the branches with a binding limit\nG.BusLabel(1)               % the tag, ∠V, |V| and \"LMP [cost/pu]=<the LMP>\" of the first bus\nG = res.plot_lmp(LabelMode=\"bus\");   % the bus tags only\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_lmp",
      "Defining": "ResultOPF",
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
          "Description": "Table: LMP, Energy, Congestion, Loss (cost per pu), one row per bus (row names = bus tags)."
        }
      ],
      "Signature": "tab = get_lmp(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/get_lmp.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the locational marginal price of every bus and its components.",
      "Desc": "The price LMP of bus i is the change of the optimal cost per unit of load at the bus,\n-lambda.Constraints.balancedP_<bus> (balancedP in \"ELD\"), in the unit of the multiplier:\ncost per pu of active power (the cost of tab_parameter.OPF per pu). It is split into\nthree components, LMP = Energy + Congestion + Loss:\n\n- `Energy`: the price at the reference bus (options.ReferenceBus of the run; the first\n  bus when it is \"none\"), the same at every bus.\n- `Loss`: -Energy * dPloss/dP_i, the price of the change of the losses when bus i injects\n  one more unit and the reference bus one less. dPloss/dP_i is the loss sensitivity at the\n  solution, from the Jacobian of the power flow equations (bus admittance matrix of the\n  branches cm_Y and bus shunts of sct_network; the angle of the reference bus fixed, the\n  reactive injections held). It is 0 at the reference bus, and 0 in \"DC OPF\" and \"ELD\",\n  which have no losses.\n- `Congestion`: the rest, LMP - Energy - Loss, from the binding limits (branches,\n  voltages). It is 0 at every bus without binding limits in \"DC OPF\".\n\nThe components depend on the choice of the reference bus; LMP does not. In \"ELD\" every\nbus has the same price. It reads only the stored result.",
      "SeeAlso": [
        "ResultOPF.disp_summary",
        "ResultOPF.disp_binding"
      ],
      "Examples": "```matlab\nres = network.IEEE14bus().calculate_optimal_powerflow(Method=\"AC OPF\");\ntab = res.get_lmp();\ntab{\"B014\", [\"LMP\",\"Energy\",\"Congestion\",\"Loss\"]}\n```",
      "Deprecated": ""
    },
    {
      "Name": "disp_binding",
      "Defining": "ResultOPF",
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
          "Name": "Kind",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,:)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Kind, [\"Bound\",\"Branch\",\"Other\"])"
          ],
          "Default": "[\"Bound\",\"Branch\",\"Other\"]",
          "Required": false,
          "Unit": "",
          "Description": "Kinds shown: bounds of the variables, branch limits, other inequalities."
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
      "Signature": "varargout = disp_binding(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/disp_binding.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Display the binding constraints of the optimal power flow solution.",
      "Desc": "Lists the constraints that hold with equality at the solution: the bounds of the\nvariables (e.g. Vmax of a bus, Pmax of a generator; a fixed value such as the P of a\nload is left out) and the inequalities of OPFprob (branch limits Pmax_, Qmax_, Imax_,\nSmax_, VargMax1_, VargMax2_, and those of Constraint). Columns: Constraint (the name;\n\"(k)\" for element k of a constraint with several), Object (the tag of the bus,\ncomponent, branch end \"<branch>_<bus>\" or branch), Value, Limit and Multiplier (the\nLagrange multiplier of lambda, cost per unit of the constraint). A constraint counts as\nbinding when its value is within 1e-4 * max(1, |Limit|) of its limit. The values of the\nbranch limits are physical (P, Q, |I|, |S| of the branch end; the angle difference From -\nTo), with the limits of tab_parameter.operation of the branch in sct_network; for a\nconstraint of Constraint, Value is the left-hand side minus the right-hand side (<= 0)\nand Limit is 0. The power balance equations always hold and are not listed. It reads\nonly the stored result. With one output it returns the text instead of displaying it.",
      "SeeAlso": [
        "ResultOPF.disp_summary",
        "ResultOPF.get_lmp"
      ],
      "Examples": "```matlab\nnet = network.IEEE14bus();\nnet.a_Branch{1}.tab_parameter.operation.Smax = 1;\nres = net.calculate_optimal_powerflow(Method=\"AC OPF\");\nres.disp_binding()\nres.disp_binding(Kind=\"Branch\")\n```",
      "Deprecated": ""
    },
    {
      "Name": "get_summary",
      "Defining": "ResultOPF",
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
        "sct"
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
          "Name": "sct",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Summary values (see the table of the help)."
        }
      ],
      "Signature": "sct = get_summary(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/get_summary.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Return the values that disp_summary shows, as a struct.",
      "Desc": "The fields hold the outcome of the calculation, the optimal cost, the sums of the bus\ninjections, the numbers of binding constraints, the range of the locational marginal\nprices (get_lmp) with their buses and, for a stability-constrained \"AC OPF\"\n(sct_stability), the stability at the solution. The buses with a positive P are the\ngeneration, those with a negative P the load: r_Pgeneration and r_Qgeneration are the\nsums of P and Q of the first, r_Pload and r_Qload the sums of -P and -Q of the second,\nand r_Ploss and r_Qloss the sums of P and Q of all buses (P losses are 0 in \"DC OPF\" and\n\"ELD\"). The Q fields are NaN in \"DC OPF\" and \"ELD\", which have no Q, and the stability\nfields NaN without sct_stability. Like disp_summary, it gives the values of the stored\nsolution also when the solver did not succeed (l_success false). It reads only the stored\nresult.\n\n| Field | Value |\n| --- | --- |\n| `s_network`, `s_Method`, `s_Solver` | Tag of the network; option Method of the run; the optimization solver (\"\" when not held) |\n| `l_success`, `r_flag` | Success (flag > 0) and the flag (double) |\n| `n_iteration`, `r_elapsed` | Iterations (NaN when not held), elapsed time [s] |\n| `r_cost` | Optimal cost (total generation cost of tab_parameter.OPF) |\n| `r_Pgeneration`, `r_Qgeneration` | [pu] Generation (buses with P > 0) |\n| `r_Pload`, `r_Qload` | [pu] Load (buses with P < 0), positive for a consumption |\n| `r_Ploss`, `r_Qloss` | [pu] Losses: sums of P and Q of all buses |\n| `n_binding`, `n_bindingBranch` | Numbers of binding constraints (disp_binding) and of the branch limits among them |\n| `r_LMPmin`, `s_LMPminBus`, `r_LMPmax`, `s_LMPmaxBus` | Smallest and largest LMP (cost per pu) and their buses |\n| `r_minDampingRatio`, `r_maxRealPart`, `n_outerIteration` | Stability: smallest damping ratio, largest real part [1/s] of the eigenvalues at the solution, outer iterations |",
      "SeeAlso": [
        "ResultOPF.disp_summary",
        "ResultOPF.get_lmp",
        "ResultOPF.disp_binding"
      ],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_optimal_powerflow(Method=\"AC OPF\");\nsct = res.get_summary();\nsct.r_cost                       % optimal cost\n[sct.r_LMPmax, sct.s_LMPmaxBus]  % highest nodal price and its bus\n```",
      "Deprecated": ""
    },
    {
      "Name": "disp_summary",
      "Defining": "ResultOPF",
      "Group": "disp",
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
          "Description": "Summary text when one output is requested; displayed otherwise."
        }
      ],
      "Signature": "varargout = disp_summary(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/disp_summary.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Display a summary of the optimal power flow result.",
      "Desc": "Shows a title line with the outcome (Method, solver, solved or not, flag) and one bullet\nper item: the calculation (iterations, elapsed time), the optimal cost, the generation\n(buses with a positive P), the load (buses with a negative P) and the losses (sums over\nall buses; 0 in \"DC OPF\" and \"ELD\"), each with P and, in \"AC OPF\", Q, the number of\nbinding constraints (see disp_binding; branch limits among them), the range of the\nlocational marginal prices (see get_lmp) with their buses, and for a stability-\nconstrained \"AC OPF\" (sct_stability) the smallest damping ratio and the largest real\npart of the eigenvalues at the solution with the number of outer iterations. The values\nare those of get_summary. It reads only the stored result. With one output it returns\nthe text instead of displaying it.",
      "SeeAlso": [
        "ResultOPF.get_summary",
        "ResultOPF.disp_binding",
        "ResultOPF.get_lmp",
        "ResultPF.disp_summary"
      ],
      "Examples": "```matlab\nres = network.IEEE14bus().calculate_optimal_powerflow(Method=\"DC OPF\");\nres.disp_summary()\ns = res.disp_summary();      % as text\n```",
      "Deprecated": ""
    },
    {
      "Name": "export",
      "Defining": "ResultOPF",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "filename",
        "opt"
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
          "Default": "string(datetime(\"now\",\"Format\",\"uuMMdd_HHmmss\")) + \"_OPF.csv\"",
          "Required": false,
          "Unit": "",
          "Description": "Output file; its extension selects the format."
        },
        {
          "Name": "Table",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "(1,1)",
          "Class": "string",
          "Validators": [
            "mustBeMember(opt.Table,[\"bus\",\"cub\",\"branch\"])"
          ],
          "Default": "\"bus\"",
          "Required": false,
          "Unit": "",
          "Description": "Table to write."
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
      "Signature": "s_file = export(obj, filename, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/export.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "ResultBase",
      "Throws": [
        "GUILDA:ResultOPF:ExportFormat"
      ],
      "Summary": "Write the bus, connection or branch table to a file.",
      "Desc": "Writes a table of the result to a CSV (.csv, .txt) or Excel (.xlsx, .xls) file, with\nthe row names in the first column and phasors as complex numbers: the bus table\n(tab_bus), or with Table=\"cub\" the connection table (tab_cub), or with Table=\"branch\"\nthe branch table (tab_branch). A relative filename is relative to the current folder.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "plot_dispatch",
      "Defining": "ResultOPF",
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
          "Name": "Parent",
          "Kind": "NameValue",
          "Struct": "opt",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure."
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
          "Description": "The chart (GraphChart): component power, then the voltage magnitude (AC OPF) and angle (DC/AC OPF)."
        }
      ],
      "Signature": "G = plot_dispatch(obj, Name=Value)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/plot_dispatch.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Plot the component outputs and the bus voltages.",
      "Desc": "Draws the solution as bar charts (GraphChart) in panels one above the other: the active\npower P [pu] of each component (and the reactive power Q for \"AC OPF\", grouped with P,\nwith a legend), then for \"AC OPF\" the bus voltage magnitude [pu], and for \"DC OPF\" and\n\"AC OPF\" the bus voltage angle [deg]. The bars are elements of the chart tagged by the\ncomponent or bus (P and Q of a component share its tag). The title shows the method,\nthe cost and \"not solved\" when the OPF failed. The only figure of the analysis:\ncalculate_optimal_powerflow draws none (its PlotFcn is a live display during the\ncalculation).",
      "SeeAlso": [
        "GraphChart",
        "ResultOPF.plot_lmp",
        "ResultOPF.plot_iteration"
      ],
      "Examples": "```matlab\nres = network.IEEE14bus().calculate_optimal_powerflow(Method=\"AC OPF\");\nG = res.plot_dispatch();\nG.set_style(\"B001SG1\", Color=\"r\");     % the P and Q bars of a component\n```",
      "Deprecated": ""
    },
    {
      "Name": "ResultOPF",
      "Defining": "ResultOPF",
      "Group": "Constructor",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": true,
      "InputNames": [
        "sct_network",
        "sct_solution",
        "sct_solver"
      ],
      "OutputNames": [
        "obj"
      ],
      "Arguments": [
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
          "Name": "sct_solution",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "struct()",
          "Required": false,
          "Unit": "",
          "Description": "Solution (output of SolverOPF.solve): tab_bus, tab_cub, tab_branch, r_cost, lambda, OPFprob, sct_iteration; absent fields keep their defaults."
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
          "Description": "Solver information: solver, options, flag, output, elapsed (s or a tic value); absent fields keep the defaults of ResultBase."
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
      "Signature": "obj = ResultOPF(sct_network, sct_solution, sct_solver)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/ResultOPF.m",
      "Line": 93,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create an optimal power flow result from data.",
      "Desc": "Stores the solution of an optimal power flow; no network object is read. The\nnetwork is known by the tag of its snapshot only (s_network).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "is_success",
      "Defining": "ResultOPF",
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
          "Description": "True when the problem was solved."
        }
      ],
      "Signature": "l = is_success(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/is_success.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "ResultBase",
      "Throws": [],
      "Summary": "Decide whether flag means success.",
      "Desc": "Success test behind l_success: the exitflag of solve (an\noptim.problemdef.ExitFlag or a number) is positive.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "binding_table",
      "Defining": "ResultOPF",
      "Group": "binding",
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
          "Description": "ResultOPF."
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
          "Description": "Table: Constraint, Object, Value, Limit, Multiplier; one row per binding constraint (element)."
        }
      ],
      "Signature": "tab = binding_table(obj)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/private/binding_table.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Binding constraints of the solution: the bounds of the variables and the inequalities of OPFprob that hold with equality.",
      "Desc": "A bound or an inequality g <= 0 (as evaluate gives it) is binding when its value is\nwithin 1e-4 * max(1, |limit|) of its limit. The value and the limit are physical for the\nGUILDA constraints: the variable and its bound (bounds \"<element>max\" / \"<element>min\",\ne.g. Vmax, Pmin); P or -P (Pmax_, two elements), Q or -Q (Qmax_), |I| (Imax_), |S|\n(Smax_) of the branch end; the angle difference From - To (VargMax1_, VargMax2_), the\nlimits from tab_parameter.operation of the branch in sct_network. For another\ninequality (e.g. from Constraint) the value is g and the limit 0. The point is the solution of the result tables, and the last\niteration of sct_iteration for other variables of a given Problem; an inequality that\ncannot be evaluated there is left out. Called by disp_binding and disp_summary.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "branch_ends",
      "Defining": "ResultOPF",
      "Group": "branch",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct_network"
      ],
      "OutputNames": [
        "im_end"
      ],
      "Arguments": [
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
          "Description": "Snapshot of the network (struct(net, false))."
        }
      ],
      "Outputs": [
        {
          "Name": "im_end",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,2)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Index of the From and To buses of each branch in sct_network.a_Bus."
        }
      ],
      "Signature": "im_end = branch_ends(sct_network)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/private/branch_ends.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "End buses of every branch of a network snapshot, as indices into its a_Bus.",
      "Desc": "A branch end of the snapshot is \"net.a_Bus{i}\" (text) or the struct of the bus. Called by\nget_lmp.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "diagram_state",
      "Defining": "ResultOPF",
      "Group": "diagram",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "cm_V",
        "cm_S"
      ],
      "OutputNames": [
        "sct_state",
        "sv_bus",
        "sv_comp"
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
          "Name": "cm_V",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Bus voltage phasors: one row per row of tab_bus, one column per sample."
        },
        {
          "Name": "cm_S",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "pu",
          "Description": "Injected powers P + jQ: one row per row of tab_cub, one column per sample."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_state",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "State of GraphNetDiagram: rv_t (1:n), cm_Vbus, cm_Icomp."
        },
        {
          "Name": "sv_bus",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Bus tags in the a_Bus order of sct_network."
        },
        {
          "Name": "sv_comp",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Component tags in the order of cm_Icomp."
        }
      ],
      "Signature": "[sct_state, sv_bus, sv_comp] = diagram_state(obj, cm_V, cm_S)",
      "File": "_GUILDAsystem/_auxiliary/@ResultOPF/private/diagram_state.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "State of GraphNetDiagram from bus voltages and component powers in the order of the result tables.",
      "Desc": "cm_V holds the bus voltage phasors in the rows of tab_bus and cm_S the injected powers\nP + jQ in the rows of tab_cub (the branch-end rows are not read), one column per sample.\nThe state follows the a_Bus and a_Component order of sct_network; the current of a\ncomponent is conj(S / V) at the voltage of its bus. Called by plot_lmp.",
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
      "SeeAlso": [
        "DrawerResultGUI",
        "HistoryGUILDA",
        "DrawerOptionDialog"
      ],
      "Examples": "```matlab\nres = network.IEEE9bus().calculate_powerflow();\nh = res.launch_gui();                        % new window\nfig = uifigure();\nh = res.launch_gui(uipanel(uigridlayout(fig, [1 1])));   % embedded in a panel\nhist = HistoryGUILDA();\nhist.run(\"Power flow\", \"Calculate\", \"net = network.IEEE9bus(); res_pf = net.calculate_powerflow();\");\nh = hist.get_variable(\"res_pf\").launch_gui(History=hist, Variable=\"res_pf\");\nhist.get_script()                            % the power flow and the actions of the GUI\n```",
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
