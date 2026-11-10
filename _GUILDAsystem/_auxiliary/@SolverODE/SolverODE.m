classdef SolverODE < auxiliary
% Solver of the time simulation (net.simulate).
%
% net.solver_ODE holds one. The settings are the TimeSimulation section of GUILDA.setting
% (GUILDA.config("TimeSimulation")); the Options of the scenarios and the Name-Value options
% of a call override them for that call only (see OptionMap and get_options); neither the
% solver nor the settings file is changed. The solver holds no settings: the network, the
% event time table and the trajectories of a run are local to solve, and the result is
% returned as a ResultODE. The DAE of the network is integrated phase by phase: a phase is a
% time interval in which the set of active disturbances (Scenario) does not change. Each
% phase is solved with the MATLAB ode object (Solver, SolverOptions, Tolerance,
% AbsoluteTolerance).
%
% - Tolerance and AbsoluteTolerance are the RelativeTolerance and AbsoluteTolerance of ode
%   (RelTol and AbsTol of odeset).
% - `SolverOptions` (a matlab.ode.Options object, e.g. MaxStep) is given only in a call or
%   in the Options of a scenario; by default the ode object uses the options of its Solver.
% - The Name-Value option Progress also accepts true ("dialog") and false ("none").
% - `TimeLimit` is checked at each solver step. When it is exceeded, the simulation stops
%   at the time reached, and the result has flag = 0 ("stopped by TimeLimit").
% - `OptionMap` is the input of tools.resolve_options. Solver, Tolerance, TimeLimit,
%   Progress, Verbose and PlotFcn are common names; Tolerance is the relative tolerance.
%   AbsoluteTolerance, SolverOptions and SeparateComplexParts keep the names of the MATLAB
%   ode object (SeparateComplexParts is logical and given to ode as "on" / "off"). Each
%   name except SolverOptions is also the key of the setting. PlotFcn
%   (live display) is "none" only (tools.check_plotfcn); result.Plot() draws the result.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% sc = Scenario("fault");
% sc.add_fault("B008", [1, 1.05]);
% net.add_scenario(sc);
% result = net.simulate([0, 10], sc, Solver="ode23t", Progress="none");  % this call only
% ```
%
% See also ResultODE, Scenario, PowerNetwork.simulate

    properties (Constant) % Settings
        OptionMap = struct( ...
            "Solver",               "Solver", ...
            "SolverOptions",        "SolverOptions", ...
            "Tolerance",            "Tolerance", ...
            "AbsoluteTolerance",    "AbsoluteTolerance", ...
            "SeparateComplexParts", "SeparateComplexParts", ...
            "TimeLimit",            "TimeLimit", ...
            "Progress",             {{"Progress", @(v) SolverODE.progress_mode(v)}}, ...
            "Verbose",              "Verbose", ...
            "PlotFcn",              "PlotFcn")                                                                         % Name-Value options of net.simulate and the setting (GUILDA.setting key; SolverOptions: call only) each one sets (see the class help). <@Type> struct
    end

    properties (SetAccess=private, Hidden) % Version
        Ver (1,1) double = 2.0                                                                                         % Version of this class.
    end

    methods
        function obj = SolverODE()
        % Create a time simulation solver (the settings are read at each run).
        %
        % A network creates its own (net.solver_ODE); net.reset_solver() replaces it with a
        % new one.
            arguments (Output)
                obj  % Time simulation solver.
            end
        end

        sct_options = get_options(obj, nv)
        [result, flag, output] = solve(obj, net, time, c_events, sct_options)
    end

    methods (Static, Hidden)
        str = progress_mode(val)
    end

    methods (Static, Access=private)
        initialize_index(net)
        set_offsets(net, ph)
        [EM, RM, lv_FBorTC, x0, M0] = initial_condition(net, ph, x0, M0)
        sct_out = phase_result(net, ph, sct_sol, Ymat)
        ctx = set_admittance(ctx, sv_open, l_force)
        o = set_equations(o, ctx, RM, EM, lg, Mass)
        g = solve_differential(f, dMd, lv_dif, lv_eqD)
        l = is_false_index_error(ctx, me)
        l = is_numerical_failure(me, o)
        [ctx, o] = use_dense(ctx, o, x0, RM, EM, lg, l_verbose, Mass)
        [c_unit, c_gc] = get_units(net)
        restore_working_data(net)
        set_gc_connect(net, sv_trip)
        odeX = getODEFunction(ctx, t, x, RM, EM, lg)
        odeJac = getODEJacobian(ctx, t, x, RM, EM, lg)
        [x0, M0] = getNextPhase(ctx, x0, M0, RM, EM)
    end
end
