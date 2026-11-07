classdef (Sealed = true) SolverODE < auxiliary
% Solver of the time simulation (net.simulate).
%
% net.solver_ODE holds one; its properties are the stored defaults of net.simulate and are
% kept between runs. Name-Value options of a call override them for that call only (see
% OptionMap and get_options). The solver holds settings only: the network, the event time
% table and the trajectories of a run are local to solve, and the result is returned as a
% ResultODE. The DAE of the network is integrated phase by phase: a phase is a
% time interval in which the set of active disturbances (Scenario) does not change. Each
% phase is solved with the MATLAB ode object (Solver, SolverOptions, RelativeTolerance,
% AbsoluteTolerance).
%
% - The tolerances are the RelativeTolerance and AbsoluteTolerance of ode (RelTol and AbsTol
%   of odeset).
% - The Name-Value option Progress also accepts true ("dialog") and false ("none").
% - `TimeLimit` is checked at each solver step. When it is exceeded, the simulation stops
%   at the time reached, and the result has flag = 0 ("stopped by TimeLimit").
% - `OptionMap` is the input of tools.resolve_options. Solver, Tolerance, TimeLimit,
%   Progress, Verbose and Plot are common names; Tolerance is the relative tolerance.
%   AbsoluteTolerance, SolverOptions and SeparateComplexParts keep the names of the MATLAB
%   ode object.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% net.solver_ODE.TimeLimit = 60;          % stored default, kept between runs
% sc = Scenario("fault");
% sc.add_fault("B008", [1, 1.05]);
% net.add_scenario(sc);
% result = net.simulate([0, 10], sc, Solver="ode23t", Progress="none");  % this call only
% ```
%
% See also ResultODE, Scenario, PowerNetwork.simulate

    properties (Access=public) % Settings
        Solver matlab.ode.SolverID = "ode15s"                                                                          % Solver of the MATLAB ode object; the DAE needs a solver for DAEs (ode15s, ode23t).
        SolverOptions matlab.ode.Options = matlab.ode.options.ODE15s                                                   % Options of the solver (SolverOptions of ode), e.g. MaxStep; its class must match Solver.
        RelativeTolerance (1,1) double {mustBePositive, mustBeBetween(RelativeTolerance,1e-15,1e-3, "closed")} = 1e-4  % Relative error tolerance of the integration (Name-Value option Tolerance).
        AbsoluteTolerance (1,1) double {mustBePositive, mustBeBetween(AbsoluteTolerance,1e-15,1e-3, "closed")} = 1e-6  % Absolute error tolerance of the integration (Name-Value option AbsoluteTolerance).
        SeparateComplexParts matlab.lang.OnOffSwitchState = "off"                                                      % SeparateComplexParts property of the ode object.
        Progress (1,1) string {mustBeMember(Progress,["none","disp","dialog"])} = "dialog"                             % Progress display: "dialog" (a waitbar), "disp" (a text bar) or "none".
        TimeLimit (1,1) double {mustBePositive} = Inf                                                                  % [s] Limit of the wall-clock time of the whole run (Inf: none; see the class help).
        Verbose (1,1) logical = false                                                                                  % Print the phases before the integration and the outcome (output.message) after it.
        Plot (1,1) logical = false                                                                                     % Call result.Plot() after each simulation.
    end

    properties (Constant) % Settings
        OptionMap = struct( ...
            "Solver",               "Solver", ...
            "SolverOptions",        "SolverOptions", ...
            "Tolerance",            "RelativeTolerance", ...
            "AbsoluteTolerance",    "AbsoluteTolerance", ...
            "SeparateComplexParts", "SeparateComplexParts", ...
            "TimeLimit",            "TimeLimit", ...
            "Progress",             {{"Progress", @(v) SolverODE.progress_mode(v)}}, ...
            "Verbose",              "Verbose", ...
            "Plot",                 "Plot")                                                                            % Name-Value options of net.simulate and the property each one sets (see the class help). <@Type> struct
    end

    properties (Dependent, Hidden) % Compatibility
        Reporter                                                                                                       % COMPAT(v3) old name of Progress (v3_ode_reporter)
    end

    properties (SetAccess=private, Hidden) % Version
        Ver (1,1) double = 2.0                                                                                         % Version of this class.
    end

    methods
        function obj = SolverODE()
        % Create a time simulation solver with the defaults of GUILDA.config("TimeSimulation").
        %
        % A network creates its own (net.solver_ODE); net.reset_solver() replaces it with a
        % new one.
            arguments (Output)
                obj  % Time simulation solver with the configured defaults.
            end
            sct = GUILDA.config("TimeSimulation");
            obj.AbsoluteTolerance   = sct.AbsoluteTolerance.Value;
            obj.RelativeTolerance   = sct.RelativeTolerance.Value;
            obj.SeparateComplexParts= sct.SeparateComplexParts.Value;
            obj.Progress            = sct.Progress.Value;
            val = sct.TimeLimit.Value;
            if isnumeric(val) && val>0
                obj.TimeLimit = val;
            else
                obj.TimeLimit = inf;
            end
        end

        function v = get.Reporter(obj), v = obj.Progress; end                              % COMPAT(v3)
        function set.Reporter(obj, v), obj.Progress = v3_ode_reporter(v); end               % COMPAT(v3)

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
        c_unit = get_units(net)
        restore_working_data(net)
        set_gc_connect(net, sv_trip)
        odeX = getODEFunction(ctx, t, x, RM, EM, lg)
        odeJac = getODEJacobian(ctx, t, x, RM, EM, lg)
        [x0, M0] = getNextPhase(ctx, x0, M0, RM, EM)
    end
end
