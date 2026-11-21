(function (root) {
  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};
  root.GUILDA_DOC_CLASSES["SolverLIN"] = {
  "schema": {
    "name": "GUILDA class document",
    "version": 5
  },
  "ClassName": "SolverLIN",
  "properties": [],
  "methods": [
    {
      "Name": "solve",
      "Defining": "SolverLIN",
      "Group": "Other",
      "Access": "public",
      "Static": false,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "obj",
        "c_block",
        "tab",
        "tab_connection",
        "sct_port"
      ],
      "OutputNames": [
        "sct_sys",
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
          "Description": "Solver (net.solver_LIN, or a SolverLIN for the other layers)."
        },
        {
          "Name": "c_block",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "cell",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Blocks in the order of the variable map: struct A, B, C, D, E, StateName, InputName, OutputName (and Owner, the text of the error messages; s_tag, the owner of its terms; sct_hessian, the get_hessian blocks)."
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
          "Description": "Variable map of the layer (all rows)."
        },
        {
          "Name": "tab_connection",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "table",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Connection map of the layer."
        },
        {
          "Name": "sct_port",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(1,1)",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Port of the layer: sv_input, sv_output, sv_algebraic, cm_Y, tab_bus, tab_current (and tab_stamp: Owner, Bus, Y, the admittance stamps that sum to cm_Y; cv_V, the bus voltages of the point for sct_hessian)."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_sys",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Fields A, B, C, D, E, StateName, InputName, OutputName, n_v, sct_term (the terms of each element: sv_owner, A, B, C, D, E, Y), and sct_hessian (H, R, r_asymmetry) when the blocks carry it."
        },
        {
          "Name": "output",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "s_issue (\"\", \"NotFinite\", \"SingularAvv\"), rcond_Avv, n_x, n_v, n_u."
        }
      ],
      "Signature": "[sct_sys, output] = solve(obj, c_block, tab, tab_connection, sct_port)",
      "File": "_GUILDAsystem/_auxiliary/@SolverLIN/solve.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverLIN:JacobianNotFinite",
        "GUILDA:SolverLIN:VariableMap",
        "GUILDA:SolverLIN:AlgebraicLoop"
      ],
      "Summary": "Connect linear blocks along the variable map.",
      "Desc": "The numerical connector of the linearization: get_sys of every layer\n(PowerSystemModel.get_sys) collects the linear blocks of its model objects\n(Component.get_linear_matrix, LocalController.get_linear_matrix,\nGlobalController.get_linear_matrix) and builds its port from the variable map (the\ninputs, outputs and algebraic bus voltages of the layer), and this method connects them. It reads only its arguments: no network and no model object.\n\n- Each input of a block is the sum of its sources in tab_connection (the rows whose\n  TargetIndex is the row of tab with the Label of the input): an output of a block\n  (Kind \"y\" or \"yc\") or a state (Kind \"x\"). The rows \"equilibrium\" add nothing (the\n  values are deviations from the point). An input in sct_port.sv_input also adds the\n  external input of that name. A bus voltage input is the algebraic variable of the bus\n  when it is in sct_port.sv_algebraic, otherwise an external input.\n- The inputs and outputs of the blocks are eliminated: u_b = K y_b + Sx x + Sv v + P w\n  and y_b = C x + D u_b give (I - D K) y_b = ... An I - D K that is singular stops with\n  GUILDA:SolverLIN:AlgebraicLoop.\n- Each bus of sct_port.sv_algebraic adds the current balance 0 = Y v - sum(I), where\n  sum(I) are the outputs [Ire; Iim] of the blocks at that bus (sct_port.tab_current)\n  and Y = sct_port.cm_Y.\n- The outputs are sct_port.sv_output: outputs or states of the blocks, bus voltages,\n  or bus currents (Y v for an algebraic bus, otherwise the sum of the currents of its\n  blocks).\n\nsct_sys is the descriptor model E [dx; dv]/dt = A [x; v] + B w, y = C [x; v] + D w,\nwith the states x of the blocks in their order and the algebraic variables v\n(E = 0 on their rows).\n\nsct_sys.sct_term splits the model into the parts of its elements (the contributions,\nResultLIN.get_contribution): its fields A, B, C, D and E list the nonzero terms of each\nmatrix as rows [Row, Column, Owner, Value], Owner an index into sv_owner; Y lists the\nadmittance terms over v alone (the current outputs Y v). A term belongs to the owner of\nits equation row: a state row to the block of the state (s_tag of the block), including\nthe terms through its inputs; a current balance row to each block for its own current\nterms and to each admittance stamp of sct_port.tab_stamp (a branch, or the shunt of a\nbus) for its part of Y; an output row to the owner of the output (a bus for a voltage,\nthe stamps for a current Y v, the blocks for a sum of their currents). The terms of\neach matrix sum to it.\n\nEnergy-function form (get_sys with Form \"hessian\"): when every block carries the field\nsct_hessian (get_hessian of its object) and the port has algebraic voltages,\nsct_sys.sct_hessian holds H over [x; theta_1..n; V_1..n] (the buses in the order of\ntab_bus): the blocks Hxx, Hxv, Hvx, Hvv of each device placed at its states and bus,\nplus the exact Jacobian of w_net = [P; Q/V] of S = V conj(Y V) at sct_port.cv_V;\nR (block diagonal) and r_asymmetry, norm(Hb - Hb.')/norm(Hb) of the bus block Hb.\n\nA block that is not finite stops with\nGUILDA:SolverLIN:JacobianNotFinite (naming its owner), and a name of a block that is\nnot in tab with GUILDA:SolverLIN:VariableMap.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "SolverLIN",
      "Defining": "SolverLIN",
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
          "Description": "Linearization connector."
        }
      ],
      "Signature": "obj = SolverLIN()",
      "File": "_GUILDAsystem/_auxiliary/@SolverLIN/SolverLIN.m",
      "Line": 49,
      "ImplementedIn": "classdef",
      "Overrides": "",
      "Throws": [],
      "Summary": "Create a linearization connector.",
      "Desc": "A network creates its own (net.solver_LIN); net.reset_solver() replaces it with a\nnew one. It takes no arguments.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "reduce",
      "Defining": "SolverLIN",
      "Group": "Other",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": false,
      "IsConstructor": false,
      "InputNames": [
        "sct_dae",
        "iv_algebraic"
      ],
      "OutputNames": [
        "sct_ode"
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
          "Description": "DAE: fields A, B, C, D, E, StateName, InputName, OutputName."
        },
        {
          "Name": "iv_algebraic",
          "Kind": "Positional",
          "Struct": "",
          "Size": "(:,1)",
          "Class": "double",
          "Validators": [],
          "Default": "find(all(sct_dae.E == 0, 2) & all(sct_dae.E == 0, 1).')",
          "Required": false,
          "Unit": "",
          "Description": "Positions of the algebraic variables in StateName. Default: the rows and columns where E is zero."
        }
      ],
      "Outputs": [
        {
          "Name": "sct_ode",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "struct",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Reduced model: fields A, B, C, D, E, StateName, InputName, OutputName (string columns)."
        }
      ],
      "Signature": "sct_ode = SolverLIN.reduce(sct_dae, iv_algebraic)",
      "File": "_GUILDAsystem/_auxiliary/@SolverLIN/reduce.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverLIN:SingularAvv"
      ],
      "Summary": "Eliminate the algebraic variables of a linear DAE.",
      "Desc": "The DAE E dx/dt = A x + B u, y = C x + D u has dynamic variables d and algebraic\nvariables a (E is zero on their rows and columns). The algebraic equations\n0 = A_ad x_d + A_aa x_a + B_a u give x_a = -A_aa \\ (A_ad x_d + B_a u), and the reduced model is\n\n```\nE_dd dx_d/dt = (A_dd - A_da A_aa^-1 A_ad) x_d + (B_d - A_da A_aa^-1 B_a) u\n           y = (C_d  - C_a  A_aa^-1 A_ad) x_d + (D   - C_a  A_aa^-1 B_a) u\n```\n\nwith the names of the dynamic variables, the inputs and the outputs. For the network\n(get_sys with Type \"ODE\", ResultLIN.get_ss(\"ODE\")) the algebraic variables are the bus\nvoltages, and A_aa is the current balance with respect to them (Avv). A model without\nalgebraic variables is returned as it is. An A_aa with a reciprocal condition number\nbelow 1e-14 stops with GUILDA:SolverLIN:SingularAvv, naming the algebraic variables it\ndoes not determine.",
      "SeeAlso": [],
      "Examples": "```matlab\nres  = net.get_sys(Type=\"DAE\");\nsct  = res.get_ss(\"DAE\", Port=\"I\", Format=\"struct\");\nsODE = SolverLIN.reduce(sct);             % = res.get_ss(\"ODE\", Format=\"struct\")\n```\n\nSee also PowerSystemModel.get_sys, ResultLIN.get_ss",
      "Deprecated": ""
    },
    {
      "Name": "check_point",
      "Defining": "SolverLIN",
      "Group": "check",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "point"
      ],
      "OutputNames": [],
      "Arguments": [
        {
          "Name": "point",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Point to check."
        }
      ],
      "Outputs": [],
      "Signature": "SolverLIN.check_point(point)",
      "File": "_GUILDAsystem/_auxiliary/@SolverLIN/check_point.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverLIN:PointType"
      ],
      "Summary": "Check the form of the point of get_sys.",
      "Desc": "Checks the form of the point (the first argument of get_sys): [] (the equilibrium), a\nreal vector (values in the order of the variable map), a real matrix (one point per\ncolumn), or a cell {sim, rv_t} or {sim, rv_t, Side} (a simulation result, one or more\ntimes, and \"after\" | \"before\" for a phase boundary).\nThe length of a vector and the rows of a matrix are checked against the analysed layer\nby point_vector. Any other form stops with GUILDA:SolverLIN:PointType.",
      "SeeAlso": [],
      "Examples": "",
      "Deprecated": ""
    },
    {
      "Name": "point_vector",
      "Defining": "SolverLIN",
      "Group": "point",
      "Access": "public",
      "Static": true,
      "Abstract": false,
      "Sealed": false,
      "Hidden": true,
      "IsConstructor": false,
      "InputNames": [
        "layer",
        "point"
      ],
      "OutputNames": [
        "rm_point",
        "rv_t",
        "l_equilibrium"
      ],
      "Arguments": [
        {
          "Name": "layer",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Analysed layer (PowerNetwork, Bus, Component, LocalController or GlobalController)."
        },
        {
          "Name": "point",
          "Kind": "Positional",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": true,
          "Unit": "",
          "Description": "Point ([], a vector, a matrix, {sim, rv_t} or {sim, rv_t, Side})."
        }
      ],
      "Outputs": [
        {
          "Name": "rm_point",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Values of the variables of the linearization of the layer: one column per section."
        },
        {
          "Name": "rv_t",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "Time of each section (1 x n_t): the times of {sim, rv_t}, 1:n for a matrix, NaN otherwise."
        },
        {
          "Name": "l_equilibrium",
          "Kind": "Output",
          "Struct": "",
          "Size": "",
          "Class": "",
          "Validators": [],
          "Default": "",
          "Required": false,
          "Unit": "",
          "Description": "True when point is [] (the equilibrium)."
        }
      ],
      "Signature": "[rm_point, rv_t, l_equilibrium] = SolverLIN.point_vector(layer, point)",
      "File": "_GUILDAsystem/_auxiliary/@SolverLIN/point_vector.m",
      "Line": 1,
      "ImplementedIn": "file",
      "Overrides": "",
      "Throws": [
        "GUILDA:SolverLIN:PointLayer",
        "GUILDA:SolverLIN:PointSize",
        "GUILDA:SolverLIN:PointSimType",
        "GUILDA:SolverLIN:PointSimSize",
        "GUILDA:SolverLIN:PointNotFinite"
      ],
      "Summary": "Get the values of the variables of a layer at the points of get_sys.",
      "Desc": "Returns the values of the variables of layer at the point (the first argument of\nget_sys), one column per section (point), in the order of the leading rows of\nlayer.get_variable_map(): x, Vre, Vim, u, uc for a PowerNetwork, Bus or Component; x,\nVre, Vim, uc for a LocalController or GlobalController. Every value is used as given:\nthe inputs u of the components and uc of the controllers included, whether the\nconnection map drives them or holds them at a setpoint (e.g. Vref of an AVR).\n\nrv_t (1 x n_t) holds the time of each section: the times of `{sim, rv_t}`, 1:n for a\nmatrix of n columns, and NaN for the equilibrium or a vector (one section).\n\n- `[]`: the equilibrium, the column Equilibrium of these rows (states, inputs, controller\n  inputs and bus voltages set by net.initialize); l_equilibrium is true.\n- vector: used as it is; its length must be the number of these rows.\n- matrix: one point per column, each used as it is; its number of rows must be the\n  number of these rows.\n- `{sim, rv_t}`: for each time t of rv_t, the values of the simulation result sim at t, read through its method\n  rv = sim.get_point(t, tab_map), which returns the values of the rows of tab_map\n  (ResultODE.get_point: linear interpolation between output times; at a phase\n  boundary, the value after the event; the controller inputs uc included). Not for a controller (GUILDA:SolverLIN:PointLayer).\n- `{sim, rv_t, Side}`: the same, with sim.get_point(t, tab_map, Side=Side); Side \"before\"\n  takes the value before the event at a phase boundary.\n\nA value that is not finite stops with GUILDA:SolverLIN:PointNotFinite, naming the\nvariables. The point is a point of the variables, and the network stays the one of the\nmodel: at a time inside a fault of {sim, t} the states are those of the fault, but the\nadmittance matrix does not include the fault. The model is not changed.",
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
