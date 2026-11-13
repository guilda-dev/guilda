classdef SolverOPF < auxiliary
% Solver of the optimal power flow (net.calculate_optimal_powerflow).
%
% net.solver_OPF holds one. It stores no settings: the settings of each run are the
% OptimalPowerFlow section of GUILDA.setting (GUILDA.config("OptimalPowerFlow")), with the
% Name-Value options of the call applied to that call only (the arguments block of
% PowerNetwork.calculate_optimal_powerflow), which passes its options as they are;
% optimoption reads the settings without an option (<Solver><option>) from GUILDA.config.
% Cost, Constraint, DefaultCost and ReferenceBus are options of the call only. The solver
% keeps only the warm start.
% It never reads the network: net.calculate_optimal_powerflow (and net.build_opf_problem)
% collect the data of the buses, components and branches from tab_parameter as three
% tables (tags as row names), resolve ReferenceBus "auto" to a bus tag and pass the base
% (baseMVA, Hz). build_problem builds the optimization problem from these data; solve
% solves it and returns the solution, from which the caller builds the ResultOPF.
%
% - `Method`: "ELD" (economic load dispatch, branches ignored), "DC OPF" (DC approximation:
%   |V| = 1, no losses, b_ij = 1/(X*tap) as in MATPOWER) or "AC OPF" (AC power flow
%   equations).
% - `Solver` "auto" uses the solver that solve chooses for the problem: linprog, quadprog
%   or fmincon. Tolerance is the OptimalityTolerance of the solver; Verbose=true passes
%   Display="iter" to the solver, Verbose=false Display="none".
% - `PlotFcn` (live display, fmincon only): display keys of the PlotFcn option of fmincon,
%   key = name without "optimplot" ("fval", "constrviolation", "fvalconstr",
%   "firstorderopt", "stepsize", "funccount", "x"), or a function handle
%   stop = f(x, optimValues, state) passed to fmincon as it is. linprog and quadprog
%   ("ELD", "DC OPF") have no PlotFcn: a value other than "none" stops with
%   GUILDA:SolverOPF:PlotFcnUnsupported. result.plot_dispatch() draws the result.
% - `Cost` and `Constraint` are function handles @(v, p) applied to the whole network.
%   v holds the variables by tag: v.Component.(tag).P, .Q ("AC OPF");
%   v.Bus.(tag).Varg, .V ("AC OPF"); v.Branch.(tag).Pfrom, .Pto, .Vargfrom, .Vargto
%   (+ Qfrom, Qto, Ifrom_re, Ifrom_im, Ito_re, Ito_im, Vfrom, Vto in "AC OPF"; flows
%   into the branch). Bus and branch variables do not exist in "ELD". p holds p.Method
%   and p.base (baseMVA, Hz). Cost returns a scalar added to the objective; Constraint
%   returns struct(name1, constraint1, ...), and field <name> becomes
%   prob.Constraints.<name> and result.lambda.Constraints.<name>.
% - The "AC OPF" starts from the bus voltages of the last solved "AC OPF" when the call
%   option WarmStart of calculate_optimal_powerflow is true and it was solved for the same
%   bus tags (in the same order), and from the flat start otherwise: angle 0 and
%   magnitude 1, with the set V at PV and slack buses and the set angle at the slack bus.
%   "DC OPF" starts from the angles of the same start. net.reset_solver() discards the
%   kept voltages.
% - The problem is built at every call (no cache); net.build_opf_problem builds the same
%   problem without solving it.
% - A default limit of one object is removed by setting it to Inf (-Inf for a lower
%   bound) in its tab_parameter.operation: Vmin, Vmax (bus); Pmin, Pmax, Qmin, Qmax
%   (component); Pmax, Qmax, Vargmax, Imax, Smax (branch, where NaN also means none).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% result = net.calculate_optimal_powerflow(Method="DC OPF");            % this call only
% result = net.calculate_optimal_powerflow(Method="ELD", Verbose=true);
% result = net.calculate_optimal_powerflow(Method="DC OPF", ReferenceBus="none");   % no fixed angle
% ```
%
% See also ResultOPF, PowerNetwork.calculate_optimal_powerflow, PowerNetwork.build_opf_problem

    properties(Access=private) % Warm start
        rm_Vwarm (:,2) double = zeros(0,2)      % [rad, pu] Varg and V of the buses in the last solved "AC OPF"; empty when none.
        sv_warmBus (:,1) string = strings(0,1)  % Bus tags of rm_Vwarm (row names of the bus table it was solved for).
    end

    methods
        function obj = SolverOPF()
        % Create an OPF solver.
        %
        % A network creates its own (net.solver_OPF); net.reset_solver() replaces it with a
        % new one, which discards the warm start.
            arguments (Output)
                obj  % OPF solver.
            end
        end

        [prob, x0] = build_problem(obj, tab_bus, tab_component, tab_branch, sct_options)
        [sct_solution, flag, output] = solve(obj, tab_bus, tab_component, tab_branch, sct_options, sct_input)
    end

    methods(Hidden)
        [s_solver, c_nv] = optimoption(obj, prob, sct_options)
    end
end
