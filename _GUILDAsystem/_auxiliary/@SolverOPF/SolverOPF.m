classdef SolverOPF < auxiliary
% Solver of the optimal power flow (net.optimize_powerflow).
%
% net.solver_OPF holds one. The settings are the OptimalPowerFlow section of GUILDA.setting
% (GUILDA.config("OptimalPowerFlow")); the solver keeps only the conditions of its network
% (Cost, Constraint, DefaultCost, ReferenceBus, kept between runs), the warm start and the
% cache. Name-Value options of a call override both for that call only (see OptionMap and
% get_options); neither the solver nor the settings file is changed.
% build_problem reads tab_parameter of the buses, components and branches and builds the
% optimization problem; solve solves it and returns a ResultOPF.
%
% - `Method`: "ELD" (economic load dispatch, branches ignored), "DC OPF" (DC approximation:
%   |V| = 1, no losses, b_ij = 1/(X*tap) as in MATPOWER) or "AC OPF" (AC power flow
%   equations).
% - `Solver` "auto" uses the solver that solve chooses for the problem: linprog, quadprog
%   or fmincon.
% - `OptionMap` is the input of tools.resolve_options. Only the common option names are
%   used. Tolerance is the OptimalityTolerance of the solver; Verbose=true sets
%   Display="iter", Verbose=false sets Display="none". PlotFcn (live display) is "none"
%   only (tools.check_plotfcn); result.Plot() draws the result.
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
%   buses and the set angle at the slack bus. "DC OPF" starts from the angles of the same
%   start.
% - solve keeps the problem it built and uses it again while the network (by object),
%   its OPF revision (every edit of the power flow, operation and OPF parameters, tags
%   and Hz), Method, Cost, Constraint (by function handle), DefaultCost, ReferenceBus,
%   the start and the bounds and types of the variables are unchanged.
%   net.build_opf_problem always builds a new problem.
% - A default limit of one object is removed by setting it to Inf (-Inf for a lower
%   bound) in its tab_parameter.operation: Vmin, Vmax (bus); Pmin, Pmax, Qmin, Qmax
%   (component); Pmax, Qmax, Vargmax, Imax, Smax (branch, where NaN also means none).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% result = net.optimize_powerflow(Method="DC OPF");            % this call only
% result = net.optimize_powerflow(Method="ELD", Verbose=true);
% net.solver_OPF.ReferenceBus = "none";           % condition of this network: no fixed angle
% ```
%
% See also ResultOPF, PowerNetwork.optimize_powerflow, PowerNetwork.build_opf_problem

    properties(Access=public) % Conditions
        Cost {mustBeHandleOrEmpty(Cost)} = []                    % User cost @(v, p) added to the objective; [] for none (see the class help).
        Constraint {mustBeHandleOrEmpty(Constraint)} = []        % User constraints @(v, p) returning struct(name, constraint, ...); [] for none (see the class help).
        DefaultCost (1,1) logical = true                         % Add the cost HP*P^2 + fP*P + HQ*Q^2 + fQ*Q (tab_parameter.OPF) of every component.
        ReferenceBus (1,1) string = "auto"                       % Bus whose angle is fixed to its power-flow Varg: "auto" (bus of tools.slack_bus_index, else the first bus), a bus tag, or "none".
    end

    properties(Constant) % Settings
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Solver",       "Solver", ...
            "Tolerance",    "Tolerance", ...
            "MaxIteration", "MaxIteration", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}}, ...
            "Cost",         "Cost", ...
            "Constraint",   "Constraint", ...
            "DefaultCost",  "DefaultCost", ...
            "ReferenceBus", "ReferenceBus", ...
            "PlotFcn",      "PlotFcn")                                                 % Name-Value options of net.optimize_powerflow (Method, Cost, Constraint, DefaultCost, ReferenceBus also of net.build_opf_problem) and the setting (GUILDA.setting key) or condition (property) each one sets (see the class help). <@Type> struct
    end

    properties(Access=private) % Warm start
        a_Bus (:,1) cell = cell(0,1)                                                                                                                            % Buses of the network of rm_Vwarm, in its bus order.
        n_revTopology (1,1) double = NaN                                                                                                                        % Topology revision of the network when rm_Vwarm was kept.
        rm_Vwarm (:,2) double = zeros(0,2)                                                                                                                      % [rad, pu] Varg and V of the buses in the last solved "AC OPF" (a_Bus order); empty when none.
    end

    properties(Access=private) % Cache
        sct_problem struct = struct([])                                                                                                                          % Problem built by the last solve: Network, Revision (n_revOPF), Key (settings and start), Problem, InitialPoint, Bounds (of the variables); empty when none.
    end

    methods
        function obj = SolverOPF()
        % Create an OPF solver with the default conditions (no Cost or Constraint).
        %
        % A network creates its own (net.solver_OPF); net.reset_solver() replaces it with a
        % new one. The settings are read from GUILDA.setting at each run (get_options).
            arguments (Output)
                obj  % OPF solver with the default conditions.
            end
        end

        sct_options = get_options(obj, nv)
        [prob, x0] = build_problem(obj, net, sct_options)
        [result,flag,output] = solve(obj, net, sct_options, sct_input)
    end

    methods(Hidden)
        [s_solver, c_nv] = optimoption(obj, prob, sct_options)
    end
end
