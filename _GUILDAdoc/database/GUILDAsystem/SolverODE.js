(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["SolverODE"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "SolverODE",
  "properties": [
    {
      "Name": "Ver",
      "Defining": "SolverODE",
      "Group": "Version",
      "GetAccess": "public",
      "SetAccess": "private",
      "Dependent": false,
      "Constant": false,
      "Abstract": false,
      "Hidden": true,
      "Transient": false,
      "HasDefault": true,
      "DefaultCode": "2.0",
      "Validation": {
        "Class": "double",
        "Size": "(1,1)",
        "Validators": []
      },
      "Unit": "",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/SolverODE.m",
      "Line": 36,
      "Summary": "Version of this class.",
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
      "Defining": "SolverODE",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "sct_dae",
        "sct_event",
        "rv_x0",
        "sct_options"
      ],
      "OutputNames": [
        "sct_sol",
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
          "Description": "Solver (net.solver_ODE)."
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
          "Description": "Blocks, maps, admittance and equilibrium of the network (build_simulation_data)."
        },
        {
          "Name": "sct_event",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "One element per phase, the disturbances as positions (build_simulation_data)."
        },
        {
          "Name": "rv_x0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Initial value of the variable rows of sct_dae.tab_variable."
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
          "Description": "Name-Value options of net.simulate (defaults from GUILDA.setting; Progress as its mode or a ProgressGUILDA to use, PlotFcn checked)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_sol",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Raw trajectories: rv_t, rm_variable, rm_I, rm_Icomponent, rv_phase, iv_Y."
        },
        {
          "Name": "flag",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "1 completed, 2 stopped by the stop condition (sct_dae.sct_stop), 0 stopped by TimeLimit, -1 stopped by the solver."
        },
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
          "Description": "Details: message, tEnd, nPhases, nPhasesDone, isSparse (false when the run fell back to dense matrices), exception (MException of a phase that could not be solved, with the original as cause; otherwise empty), outOfStep (Time, Unit, Reference, Angle of the stop; empty struct otherwise)."
        }
      ],
      "Signature": "[sct_sol, flag, output] = solve(obj, sct_dae, sct_event, rv_x0, sct_options)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/solve.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverODE:PhaseFailed",
        "GUILDA:SolverODE:InitialConditionFailed"
      ],
      "Summary": "Integrate the network DAE of the data of a run with the given settings.",
      "Desc": "The data comes from net.build_simulation_data: the blocks (rows in the variable map and\nfunction handles), the maps, the admittance, the equilibrium (sct_dae), the phases with\nthe disturbances as positions (sct_event) and the initial value (rv_x0). solve reads\nonly these and the settings sct_options: no network, bus, branch, component,\ncontroller or scenario. In each phase a tripped unit is masked (its states and inputs\nare left out, a component injects no current, a controller gives no output), an input\nwhose source is tripped takes its equilibrium value (build_index), a faulted bus holds\nV = 0, and the admittance matrix is the one of the branch states of the phase\n(sct_dae.c_Y{i_Y}). Called by net.simulate; calling it directly is for advanced use:\n\n  [sct_dae, sct_event, rv_x0] = net.build_simulation_data(tag, time);\n  [sct_sol, flag, output] = net.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options);\n\nsct_sol holds the raw trajectories: rv_t (the times; a phase boundary appears twice),\nrm_variable (the variable rows x, Vre, Vim, u, uc of sct_dae.tab_variable; the states and\ninputs of a tripped unit are NaN), rm_I (Ire, Iim of each bus), rm_Icomponent (Ire, Iim of each\ncomponent in the order of sct_dae.c_comp, its f_I at each time; NaN while it is tripped),\nrv_phase (the phase of each time) and iv_Y (the position in sct_dae.c_Y of the\nadmittance of each time: the branch states it used).\nThe times are the steps of the solver, or with sct_options.SampleTime > 0 the times\nt0 + k*SampleTime with the start and end of each phase. With SampleTime the solver takes\nthe same steps over each phase and the values at those times come from its interpolant\n(solutionFcn); a phase that stops early ends at the time it stopped. solutionFcn calls\nno OutputFcn, so the progress display does not move during a phase (TimeLimit is\nchecked by the event function, odeProg.Events). When sct_dae.sct_stop is not empty\n(net.simulate with StopOnOutOfStep), the run stops when |x(iv_angle) - x(i_ref)| of a\ncomponent that is not tripped exceeds sct_stop.r_limit, unless the reference is\ntripped: flag is 2 and output.outOfStep holds Time, Unit, Reference and Angle [deg]\n(empty otherwise).\nflag is 1 when the simulation reached the end time, 0 when it stopped because the\nrun exceeded TimeLimit, and -1 when the solver stopped before the end time or could\nnot solve a phase (output.message has the reason; output.exception has the error\nwhen there was one). In the last two cases sct_sol holds the trajectories up to\nthe time reached (output.tEnd), with no time points when the first phase could not\nbe solved. An error of other code during a phase, such as a model, stops with an error\n(GUILDA:SolverODE:PhaseFailed, the original as cause).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "SolverODE",
      "Defining": "SolverODE",
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
          "Description": "Time simulation solver."
        }
      ],
      "Signature": "obj = SolverODE()",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/SolverODE.m",
      "Line": 40,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a time simulation solver (the settings are read at each run).",
      "Desc": "A network creates its own (net.solver_ODE); net.reset_solver() replaces it with a\nnew one.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "getNextPhase",
      "Defining": "SolverODE",
      "Group": "Other",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "ctx",
        "x0",
        "M0",
        "RM",
        "EM"
      ],
      "OutputNames": [
        "x0",
        "M0"
      ],
      "Arguments": [
        {
          "Name": "ctx",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Context of the run."
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
          "Description": "Reduced state vector at the end of the phase."
        },
        {
          "Name": "M0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Reduced mass matrix of the phase."
        },
        {
          "Name": "RM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Reduction matrix of the phase."
        },
        {
          "Name": "EM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Expansion matrix of the phase."
        }
      ],
      "Outputs": [
        {
          "Name": "x0",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Full state vector at the start of the next phase."
        },
        {
          "Name": "M0",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Full mass matrix at the start of the next phase."
        }
      ],
      "Signature": "[x0, M0] = SolverODE.getNextPhase(ctx, x0, M0, RM, EM)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/getNextPhase.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Initial value and mass matrix of the next phase from the end of the current one.",
      "Desc": "A bus faulted in the phase just solved restarts from its equilibrium voltage and current\n(the faults are those of ctx). A tripped unit stays tripped to the end of the run, so its\nentries (zero after the expansion) are left out of every later phase.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "getODEJacobian",
      "Defining": "SolverODE",
      "Group": "Other",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "ctx",
        "t",
        "x",
        "RM",
        "EM",
        "lg"
      ],
      "OutputNames": [
        "odeJac"
      ],
      "Arguments": [
        {
          "Name": "ctx",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Context of the run."
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
          "Unit": "s",
          "Description": "Time from the start of the phase."
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
          "Description": "Reduced state vector."
        },
        {
          "Name": "RM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Reduction matrix of the phase."
        },
        {
          "Name": "EM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Expansion matrix of the phase."
        },
        {
          "Name": "lg",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True for the entries of the full state vector that are solved."
        }
      ],
      "Outputs": [
        {
          "Name": "odeJac",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Jacobian of the reduced DAE (sparse when ctx.l_sparse)."
        }
      ],
      "Signature": "odeJac = SolverODE.getODEJacobian(ctx, t, x, RM, EM, lg)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/getODEJacobian.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Method for obtaining the Jacobian of the DAE system under analysis.",
      "Desc": "Same blocks as getODEFunction: for each component [Axx, Bxv, Bxu] in its state rows and\n-[Cix, Div, Diu] in the rows of its bus, for each controller [Axx, Bxv, Bxu]; the\nJacobian Js of the signals ([Cyx, Dyv] of a component, [Cyx, Dyv, Dyu] of a controller)\nenters the input rows as I - S_var - S_sig*Js; then the current balance of the buses.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "getODEFunction",
      "Defining": "SolverODE",
      "Group": "Other",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "ctx",
        "t",
        "x",
        "RM",
        "EM",
        "lg"
      ],
      "OutputNames": [
        "odeX"
      ],
      "Arguments": [
        {
          "Name": "ctx",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Context of the run."
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
          "Unit": "s",
          "Description": "Time from the start of the phase."
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
          "Description": "Reduced state vector."
        },
        {
          "Name": "RM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Reduction matrix of the phase."
        },
        {
          "Name": "EM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Expansion matrix of the phase."
        },
        {
          "Name": "lg",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True for the entries of the full state vector that are solved."
        }
      ],
      "Outputs": [
        {
          "Name": "odeX",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Right-hand side of the reduced DAE."
        }
      ],
      "Signature": "odeX = SolverODE.getODEFunction(ctx, t, x, RM, EM, lg)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/getODEFunction.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Method for retrieving the DAE system to be analyzed.",
      "Desc": "z = [x; V; I; u; uc] in the order of the variable map (build_index). Each block (component,\nlocal controller, global controller) is evaluated from its own states, bus voltage(s) and\ninputs: its state derivatives, the current of a component, and its outputs into the signal\nvector s (only the outputs of the components that a connection reads). The inputs are\ngiven by the connection map: u - (e + input events + S_sig*s + S_var*z) = 0. Last, the\ncurrent balance of the buses.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "use_dense",
      "Defining": "SolverODE",
      "Group": "use",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "ctx",
        "o",
        "x0",
        "RM",
        "EM",
        "lg",
        "l_verbose",
        "Mass"
      ],
      "OutputNames": [
        "ctx",
        "o"
      ],
      "Arguments": [
        {
          "Name": "ctx",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Context of the run."
        },
        {
          "Name": "o",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "MATLAB ode object of the run."
        },
        {
          "Name": "x0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Initial value of the phase."
        },
        {
          "Name": "RM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Reduction matrix of the phase."
        },
        {
          "Name": "EM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Expansion matrix of the phase."
        },
        {
          "Name": "lg",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True for the entries of the full state vector that are solved."
        },
        {
          "Name": "l_verbose",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True to print a message."
        },
        {
          "Name": "Mass",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Mass matrix of the phase."
        }
      ],
      "Outputs": [
        {
          "Name": "ctx",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Context with dense matrices."
        },
        {
          "Name": "o",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "ode object with dense equations."
        }
      ],
      "Signature": "[ctx, o] = SolverODE.use_dense(ctx, o, x0, RM, EM, lg, l_verbose, Mass)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/use_dense.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Solve the current phase again and the next phases with dense matrices.",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "is_numerical_failure",
      "Defining": "SolverODE",
      "Group": "is",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "me",
        "o"
      ],
      "OutputNames": [
        "l"
      ],
      "Arguments": [
        {
          "Name": "me",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "MException",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Error of the solver."
        },
        {
          "Name": "o",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "MATLAB ode object of the phase."
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
          "Description": "True when the solver gave up on the phase."
        }
      ],
      "Signature": "l = SolverODE.is_numerical_failure(me, o)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/is_numerical_failure.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "The errors with which the solver gives up on a phase. ode.solve rethrows the errors",
      "Desc": "of the right-hand side without its stack, so only the identifier tells them from\nthe errors of input functions and models: any other identifier is not one of these.\nThe mass matrix error is checked against the phase, as an input function may\ncall an ode solver of its own.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "is_false_index_error",
      "Defining": "SolverODE",
      "Group": "is",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "ctx",
        "me"
      ],
      "OutputNames": [
        "l"
      ],
      "Arguments": [
        {
          "Name": "ctx",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Context of the run."
        },
        {
          "Name": "me",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "MException",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Error of the solver."
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
          "Description": "True when the error is a false index error of the sparse matrices."
        }
      ],
      "Signature": "l = SolverODE.is_false_index_error(ctx, me)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/is_false_index_error.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "With sparse matrices, the index check of the solver can fail for a DAE of index 1:",
      "Desc": "condest of the sparse algebraic block can be far above the true condition number\n(daeic12 tests eps*nnz(J)*condest(J) > 1). A DAE of a higher index fails with\ndense matrices too, and that error is reported.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "solve_differential",
      "Defining": "SolverODE",
      "Group": "solve",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "f",
        "dMd",
        "lv_dif",
        "lv_eqD"
      ],
      "OutputNames": [
        "g"
      ],
      "Arguments": [
        {
          "Name": "f",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Right-hand side or Jacobian."
        },
        {
          "Name": "dMd",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "decomposition",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Decomposition of the differential block of the mass matrix."
        },
        {
          "Name": "lv_dif",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True for the differential variables."
        },
        {
          "Name": "lv_eqD",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True for the differential equations."
        }
      ],
      "Outputs": [
        {
          "Name": "g",
          "Kind": "Output",
          "Struct": "",
          "Size": "(:,:)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Rows of f for the identity mass matrix."
        }
      ],
      "Signature": "g = SolverODE.solve_differential(f, dMd, lv_dif, lv_eqD)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/solve_differential.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Rows of f (a vector or a Jacobian) for the identity mass matrix (see set_equations)",
      "Desc": "",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_equations",
      "Defining": "SolverODE",
      "Group": "set",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "o",
        "ctx",
        "RM",
        "EM",
        "lg",
        "Mass"
      ],
      "OutputNames": [
        "o"
      ],
      "Arguments": [
        {
          "Name": "o",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "MATLAB ode object of the run."
        },
        {
          "Name": "ctx",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Context of the run."
        },
        {
          "Name": "RM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Reduction matrix of the phase."
        },
        {
          "Name": "EM",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Expansion matrix of the phase."
        },
        {
          "Name": "lg",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True for the entries of the full state vector that are solved."
        },
        {
          "Name": "Mass",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Mass matrix of the phase."
        }
      ],
      "Outputs": [
        {
          "Name": "o",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "ode object with MassMatrix, ODEFcn and Jacobian set."
        }
      ],
      "Signature": "o = SolverODE.set_equations(o, ctx, RM, EM, lg, Mass)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/set_equations.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "The mass matrix, right-hand side and Jacobian of a phase. They hold a copy of ctx.",
      "Desc": "A mass matrix that is not diagonal (e.g. of a controller) is made the identity on the\ndifferential variables, by solving the differential equations with its block:\nM*x' = f becomes x'(d) = M(rd,d) \\ f(rd), 0 = f(ra). The solutions are the same, and\nfor a diagonal mass matrix the consistency step of the solver changes only the\nalgebraic variables, while for a sparse one that is not diagonal it moves all of\nthem (see CalculateInitialCondition).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "set_admittance",
      "Defining": "SolverODE",
      "Group": "set",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "ctx",
        "i_Y",
        "l_force"
      ],
      "OutputNames": [
        "ctx"
      ],
      "Arguments": [
        {
          "Name": "ctx",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Context of the run (c_Y, i_Y)."
        },
        {
          "Name": "i_Y",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "double",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Position of the matrix of the phase in ctx.c_Y."
        },
        {
          "Name": "l_force",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "True to rebuild even when i_Y is unchanged."
        }
      ],
      "Outputs": [
        {
          "Name": "ctx",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Context with Ymat, absYmat and i_Y updated."
        }
      ],
      "Signature": "ctx = SolverODE.set_admittance(ctx, i_Y, l_force)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/set_admittance.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "ctx.Ymat (real 2n x 2n, I = Y*V) and ctx.absYmat from the admittance matrix c_Y{i_Y} of",
      "Desc": "the run (build_simulation_data made one per set of branch states). Rebuilt only when\ni_Y changes.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "phase_result",
      "Defining": "SolverODE",
      "Group": "phase",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "ctx",
        "ph",
        "sct_sol"
      ],
      "OutputNames": [
        "sct_out"
      ],
      "Arguments": [
        {
          "Name": "ctx",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Context of the run (Ymat of the phase)."
        },
        {
          "Name": "ph",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Data of the phase (an element of sct_event)."
        },
        {
          "Name": "sct_sol",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Solution of the phase (fields Time and Solution, full state vector)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_out",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Trajectory of the phase (fields t, x (all variable rows of the map), i, ic (Ire, Iim of each component in the order of ctx.c_comp))."
        }
      ],
      "Signature": "sct_out = SolverODE.phase_result(ctx, ph, sct_sol)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/phase_result.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "Trajectory of one phase: the variables x, V, u, uc in the order of the variable map, the",
      "Desc": "bus currents and the current of each component; the states and inputs of the tripped\ncomponents, local controllers and global controllers are NaN. The current of a component is its f_I\nat each output time (t from the start of the phase, as the solver), NaN while it is\ntripped; it is evaluated here, over the output times, and not in the right-hand side.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "initial_condition",
      "Defining": "SolverODE",
      "Group": "initial",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "ctx",
        "ph",
        "x0",
        "M0"
      ],
      "OutputNames": [
        "EM",
        "RM",
        "lv_FBorTC",
        "x0",
        "M0"
      ],
      "Arguments": [
        {
          "Name": "ctx",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Context of the run (build_index and the state of the phase)."
        },
        {
          "Name": "ph",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Data of the phase (an element of sct_event)."
        },
        {
          "Name": "x0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Initial value at the end of the last phase, or [] for the first phase."
        },
        {
          "Name": "M0",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Mass matrix at the end of the last phase, or [] for the first phase."
        }
      ],
      "Outputs": [
        {
          "Name": "EM",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Expansion matrix from the reduced to the full state vector."
        },
        {
          "Name": "RM",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Reduction matrix from the full to the reduced state vector."
        },
        {
          "Name": "lv_FBorTC",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True for the entries of the faulted buses and tripped units."
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
          "Description": "Initial value of the reduced state vector."
        },
        {
          "Name": "M0",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Mass matrix of the reduced state vector."
        }
      ],
      "Signature": "[EM, RM, lv_FBorTC, x0, M0] = SolverODE.initial_condition(ctx, ph, x0, M0)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/initial_condition.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [],
      "Summary": "The reduction of the DAE vector for a phase (without the elements of the faulted buses",
      "Desc": "and of the tripped components, local controllers and global controllers) and the initial value and mass matrix of the phase. x0 and M0 are\nthose at the end of the last phase ([] for the first one: x0 is then the initial value\nof the run, ctx.rv_x0, which holds the offsets and inputs of the first phase). The state\noffsets of the disturbances starting in a later phase are added to the states.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "build_index",
      "Defining": "SolverODE",
      "Group": "build",
      "Access": "private",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct_dae"
      ],
      "OutputNames": [
        "sct"
      ],
      "Arguments": [
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
          "Description": "Data of the run (PowerNetwork.build_simulation_data)."
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
          "Description": "Index data of the run (the context ctx of solve)."
        }
      ],
      "Signature": "sct = SolverODE.build_index(sct_dae)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/build_index.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverODE:MassNotConstant"
      ],
      "Summary": "Positions of a run in the DAE vector and what each evaluation reads, from the data of the run.",
      "Desc": "The DAE vector of the simulation is z = [x; V; I; u; uc]: the variable rows of\nsct_dae.tab_variable in its order (x, Vre/Vim, u, uc), with the bus currents I (Ire, Iim\nof each bus, not in the map) after the voltages. The outputs y and yc are not variables:\neach evaluation computes them into the signal vector s (the rows y, yc of the map). The\ninputs are given by the connection map: res = z_in - (e + S_sig*s + S_var*z), where e\nholds the equilibrium of the inputs without another source. For each connection the\nblock of its source is kept (sct_conn), so that set_phase in solve leaves out the\nconnections of a tripped source: an input whose main source (\"observe\" or \"local\") is\ntripped takes its equilibrium, as an input without a source. Only the data is read: the\nblocks give their rows in the map and their function handles. The mass matrix of each\nblock is f_Mass([],[],[],[]); one that is not a constant matrix of its size stops with\nGUILDA:SolverODE:MassNotConstant. Called by solve.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "CalculateInitialCondition",
      "Defining": "SolverODE",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "o",
        "options"
      ],
      "OutputNames": [
        "x0",
        "xp0",
        "l_failed",
        "s_why",
        "me_why"
      ],
      "Arguments": [
        {
          "Name": "o",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "MATLAB ode object of the phase (InitialValue, MassMatrix, ODEFcn, Jacobian)."
        },
        {
          "Name": "options",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "odeset options (RelTol, AbsTol)."
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
          "Description": "Consistent initial value, or empty when l_failed."
        },
        {
          "Name": "xp0",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Consistent initial slope, or empty when l_failed."
        },
        {
          "Name": "l_failed",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "logical",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True when no algebraic variables satisfy the equations (x0, xp0 are empty)."
        },
        {
          "Name": "s_why",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Reason of the failure (\"\" otherwise)."
        },
        {
          "Name": "me_why",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Error when l_failed ([] otherwise)."
        }
      ],
      "Signature": "[x0, xp0, l_failed, s_why, me_why] = CalculateInitialCondition(o, options)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/private/CalculateInitialCondition.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverODE:AlgebraicNotSolved"
      ],
      "Summary": "Consistent initial condition of a phase, for the ode object o.",
      "Desc": "The differential states (the variables that the mass matrix multiplies) keep the values\nof o.InitialValue exactly: they are continuous at an event, and an offset event has already\nbeen added to them. Only the algebraic variables are solved, from the algebraic equations\n(the zero rows of the mass matrix) for the network of the phase, by Newton's method with the\nanalytic Jacobian and the values of o.InitialValue as the start. xp0 is the slope of both.\ndecic and the consistency step of the solver are not used: they may move the differential\nstates (decic when it cannot keep them, the solver for a sparse mass matrix that is not\ndiagonal).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "makeODE",
      "Defining": "SolverODE",
      "Group": "Other",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct_options"
      ],
      "OutputNames": [
        "o"
      ],
      "Arguments": [
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
          "Description": "Name-Value options of net.simulate (defaults from GUILDA.setting)."
        }
      ],
      "Outputs": [
        {
          "Name": "o",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "MATLAB ode object with the settings."
        }
      ],
      "Signature": "o = makeODE(sct_options)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/private/makeODE.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "MATLAB ode object with the settings of sct_options: every public property of ode that is",
      "Desc": "a field of sct_options is set, in the property order of ode; then MaxStep and InitialStep\ngo into the SolverOptions of the Solver when they are not NaN (NaN: the solver default).",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "phase_points",
      "Defining": "SolverODE",
      "Group": "phase",
      "Access": "private",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "res",
        "f_sol",
        "tv"
      ],
      "OutputNames": [
        "sol"
      ],
      "Arguments": [
        {
          "Name": "res",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "ODEResults of solve or solutionFcn."
        },
        {
          "Name": "f_sol",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "",
          "Description": "Interpolant of the solution (solutionFcn); empty for the steps of the solver."
        },
        {
          "Name": "tv",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "[]",
          "Required": false,
          "Unit": "s",
          "Description": "Output times from the start of the phase (1 x n, increasing; with f_sol)."
        }
      ],
      "Outputs": [
        {
          "Name": "sol",
          "Kind": "Output",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Time (1 x n), Solution (n_x x n), EventIndex (indices of the events that occurred)."
        }
      ],
      "Signature": "sol = phase_points(res, f_sol, tv)",
      "File": "_GUILDAsystem/_auxiliary/@SolverODE/private/phase_points.m",
      "Line": 1,
      "ImplementedIn": "private",
      "Overrides": "",
      "Throws": [],
      "Summary": "Times and values of the solution of a phase, up to a terminal event.",
      "Desc": "Without f_sol, the steps of the solver (solve(o, t0, tf)): with a terminal event, the\nevent is the last step. With f_sol and tv (SampleTime), the solver takes its own steps\nover [0, tv(end)] (solutionFcn) and the values at the output times tv up to the time\nthe integration stopped come from its interpolant; a time that is a step of the solver\nkeeps the value of that step, and when the integration stopped before tv(end), that\ntime and value are appended, so that the last time is the time it stopped.",
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
