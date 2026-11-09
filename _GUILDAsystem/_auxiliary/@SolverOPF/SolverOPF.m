classdef SolverOPF < auxiliary
% Solver of the optimal power flow (net.optimize_powerflow).
%
% net.solver_OPF holds one; its properties are the stored defaults of
% net.optimize_powerflow and net.build_opf_problem and are kept between runs. Name-Value
% options of a call override them for that call only (see OptionMap and get_options).
% build_problem reads tab_parameter of the buses, components and branches and builds the
% optimization problem; solve solves it and returns a ResultOPF.
%
% - `Method`: "ELD" (economic load dispatch, branches ignored), "DC OPF" (DC approximation:
%   |V| = 1, no losses, b_ij = 1/(X*tap) as in MATPOWER) or "AC OPF" (AC power flow
%   equations).
% - `Solver` "auto" uses the solver that solve chooses for the problem: linprog, quadprog
%   or fmincon.
% - `OptionMap` is the input of tools.resolve_options. Only the common option names are
%   used. Tolerance sets OptimalityTolerance; Verbose=true sets Display="iter",
%   Verbose=false sets Display="none".
% - `Cost` and `Constraint` are function handles @(v, p) applied to the whole network.
%   v holds the variables by tag: v.Component.(tag).P, .Q ("AC OPF");
%   v.Bus.(tag).Varg, .V ("AC OPF"); v.Branch.(tag).Pfrom, .Pto, .Vargfrom, .Vargto
%   (+ Qfrom, Qto, Ifrom_re, Ifrom_im, Ito_re, Ito_im, Vfrom, Vto in "AC OPF"; flows
%   into the branch). Bus and branch variables do not exist in "ELD". p holds p.Method
%   and p.base (baseMVA, Hz). Cost returns a scalar added to the objective; Constraint
%   returns struct(name1, constraint1, ...), and field <name> becomes
%   prob.Constraints.<name> and result.lambda.Constraints.<name>.
% - The "AC OPF" starts from the bus voltages of the last solved "AC OPF" of the same
%   network when the call option WarmStart of optimize_powerflow is true (kept until
%   buses or branches are added, removed or replaced; buses are matched by object), and
%   from the flat start otherwise: angle 0 and magnitude 1, with the set V at PV and slack
%   buses and the set angle at the slack bus. "DC OPF" starts from the flat angles.
% - A default limit of one object is removed by setting it to Inf (-Inf for a lower
%   bound) in its tab_parameter.operation: Vmin, Vmax (bus); Pmin, Pmax, Qmin, Qmax
%   (component); Pmax, Qmax, Vargmax, Imax, Smax (branch, where NaN also means none).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.solver_OPF.Method = "DC OPF";              % stored default, kept between runs
% result = net.optimize_powerflow();             % uses "DC OPF"
% result = net.optimize_powerflow(Method="ELD", Verbose=true);   % this call only
% net.solver_OPF.ReferenceBus = "none";           % stored default: no fixed angle
% ```
%
% See also ResultOPF, PowerNetwork.optimize_powerflow, PowerNetwork.build_opf_problem

    properties(Access=public) % Settings
        Method (1,1) string {mustBeMember(Method,["ELD","DC OPF","AC OPF"])} = "AC OPF"                                                                         % Formulation of the problem: "ELD", "DC OPF" or "AC OPF" (see the class help).
        Solver (1,1) string {mustBeMember(Solver,["auto","linprog","quadprog","fmincon"])} = "auto"                                                             % Optimization solver; "auto" uses the one that solve (Optimization Toolbox) chooses.
        Algorithm_linprog (1,1) string = "dual-simplex-highs"                                                                                                   % Algorithm option of linprog.
        Algorithm_quadprog (1,1) string = "interior-point-convex"                                                                                               % Algorithm option of quadprog.
        Algorithm_fmincon (1,1) string = "interior-point"                                                                                                       % Algorithm option of fmincon.
        Display (1,1) string {mustBeMember(Display,["default","none","iter","iter-detailed","final","final-detailed","notify","notify-detailed"])} = "default"  % Display option of the solver; "default" keeps the default of the solver.
        MaxIteration (1,1) double = NaN                                                                                                                         % MaxIterations option of the solver; NaN keeps the default of the solver.
        OptimalityTolerance (1,1) double = NaN                                                                                                                  % OptimalityTolerance option of the solver; NaN keeps the default of the solver.
        StepTolerance (1,1) double = NaN                                                                                                                        % StepTolerance option of the solver; NaN keeps the default.
        MaxFunctionEvaluations (1,1) double = NaN                                                                                                               % MaxFunctionEvaluations option of the solver; NaN keeps the default.
        UseParallel (1,1) logical = false                                                                                                                       % UseParallel option of fmincon (other solvers ignore it).
        Cost {mustBeHandleOrEmpty(Cost)} = []                                                                                                                   % User cost @(v, p) added to the objective; [] for none (see the class help).
        Constraint {mustBeHandleOrEmpty(Constraint)} = []                                                                                                       % User constraints @(v, p) returning struct(name, constraint, ...); [] for none (see the class help).
        DefaultCost (1,1) logical = true                                                                                                                        % Add the cost HP*P^2 + fP*P + HQ*Q^2 + fQ*Q (tab_parameter.OPF) of every component.
        ReferenceBus (1,1) string = "auto"                                                                                                                      % Bus whose angle is fixed to its power-flow Varg: "auto" (bus of tools.slack_bus_index, else the first bus), a bus tag, or "none".
    end

    properties(Constant) % Settings
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Solver",       "Solver", ...
            "Tolerance",    "OptimalityTolerance", ...
            "MaxIteration", "MaxIteration", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}}, ...
            "Cost",         "Cost", ...
            "Constraint",   "Constraint", ...
            "DefaultCost",  "DefaultCost", ...
            "ReferenceBus", "ReferenceBus")                                                 % Name-Value options of net.optimize_powerflow (Method, Cost, Constraint, DefaultCost, ReferenceBus also of net.build_opf_problem) and the property each one sets (see the class help). <@Type> struct
    end

    properties(Access=private) % Warm start
        a_Bus (:,1) cell = cell(0,1)                                                                                                                            % Buses of the network of rm_Vwarm, in its bus order.
        n_revTopology (1,1) double = NaN                                                                                                                        % Topology revision of the network when rm_Vwarm was kept.
        rm_Vwarm (:,2) double = zeros(0,2)                                                                                                                      % [rad, pu] Varg and V of the buses in the last solved "AC OPF" (a_Bus order); empty when none.
    end

    methods
        function obj = SolverOPF()
        % Create an OPF solver with the defaults of GUILDA.config("OptimalPowerFlow").
        %
        % A network creates its own (net.solver_OPF); net.reset_solver() replaces it with a
        % new one.
            arguments (Output)
                obj  % OPF solver with the configured defaults.
            end
            sct = GUILDA.config("OptimalPowerFlow");
            obj.Method                 = sct.Method.Value;
            obj.Solver                 = sct.Solver.Value;
            obj.Algorithm_linprog      = sct.Algorithm_linprog.Value;
            obj.Algorithm_quadprog     = sct.Algorithm_quadprog.Value;
            obj.Algorithm_fmincon      = sct.Algorithm_fmincon.Value;
            obj.Display                = sct.Display.Value;
            obj.MaxIteration           = sct.MaxIteration.Value;
            obj.OptimalityTolerance    = sct.OptimalityTolerance.Value;
            obj.StepTolerance          = sct.StepTolerance.Value;
            obj.MaxFunctionEvaluations = sct.MaxFunctionEvaluations.Value;
            obj.UseParallel            = sct.UseParallel.Value;
        end

        sct_options = get_options(obj, nv)
        [prob, x0] = build_problem(obj, net, sct_options)
        [result,flag,output] = solve(obj, net, sct_options, sct_input)
    end

    methods(Hidden)
        [s_solver, c_nv] = optimoption(obj, prob, sct_options)
    end
end
