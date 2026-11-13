function [result, flag, output] = calculate_optimal_powerflow(obj, opt)
% Calculate the optimal power flow of the network and return a ResultOPF.
%
% Calculates the optimal power flow of the network: the operating point that minimizes
% the generation cost (tab_parameter.OPF of the components) under the constraints in
% tab_parameter.operation of the buses, components and branches. The settings are the
% OptimalPowerFlow section of GUILDA.setting; Name-Value options override them for this
% call only (the settings file is not changed). Cost, Constraint, DefaultCost and
% ReferenceBus are options of the call only. The network is not changed.
% The cost of each component is HP*P^2 + fP*P + HQ*Q^2 + fQ*Q (tab_parameter.OPF; Q terms
% in "AC OPF" only); the default cost of a load is 0. A load keeps the P and Q of
% tab_parameter.powerflow while its Pmin/Pmax (Qmin/Qmax) are infinite; with finite
% bounds it is dispatched within them. A default limit of one object is removed by setting
% it to Inf (-Inf for a lower bound) in its tab_parameter.operation: Vmin, Vmax (bus);
% Pmin, Pmax, Qmin, Qmax (component); Pmax, Qmax, Vargmax, Imax, Smax (branch, where NaN
% also means none). User costs and constraints over the whole network are the options
% Cost and Constraint; a problem from net.build_opf_problem, modified by the user, is
% solved with Problem. The columns startup and shutdown of tab_parameter.OPF
% are reserved: unit commitment is not part of the problem. "DC OPF" uses |V| = 1 and
% the MATPOWER branch susceptance b = 1/(X*tap) (tap ratio and phase shift at the from
% end). The angle of the ReferenceBus is fixed to its tab_parameter.powerflow Varg;
% l_isSlack is not set. The solver starts from the bus voltages of the last solved
% "AC OPF" of the network (WarmStart) or of the flat start (see SolverOPF), and P0, Q0 of
% the components; branch current and power limits are applied as |I|^2 <= Imax^2 and
% P^2 + Q^2 <= Smax^2 at both ends. Options not listed below stop with the MATLAB error
% of an unknown name. The result is written to a file with result.export.
% The network assembles the data of the problem (the tables of net.get_opf_condition,
% the base and the reference bus) and net.solver_OPF builds
% and solves it from these data only; the ResultOPF is built from a snapshot of the
% network (struct(net, false)) and the solution. res.options holds the Name-Value options
% of the run (Problem and InitialPoint excepted), with ReferenceBus as the bus tag ("auto"
% resolved) and base (baseMVA, Hz); the settings without an option (the algorithm and
% the step tolerances of each solver, <Solver><option>) are read by SolverOPF from
% GUILDA.setting.
%
% Name-Value options:
%
% - `Method` — Formulation: "ELD" (economic load dispatch, branches ignored), "DC OPF" (DC approximation) or "AC OPF" (AC power flow equations). Default: GUILDA.setting ("AC OPF").
% - `Solver` — Optimization solver; "auto" lets solve choose. Default: GUILDA.setting ("auto").
% - `Tolerance` — OptimalityTolerance of the solver; NaN = solver default. Default: GUILDA.setting (NaN).
% - `MaxIteration` — MaxIterations of the solver; NaN = solver default. Default: GUILDA.setting (NaN).
% - `Verbose` — Print the progress of the solver (Display "iter"; false: "none"). Default: GUILDA.setting (false).
% - `Cost` — Function handle @(v, p) returning a scalar added to the objective; [] = none. v holds the variables by tag: v.Component.(tag).P/.Q, v.Bus.(tag).Varg/.V, v.Branch.(tag).Pfrom/.Pto/...; p holds p.Method and p.base (see SolverOPF). Default: [].
% - `Constraint` — Function handle @(v, p) returning struct(name1, constraint1, ...); field <name> becomes prob.Constraints.<name> and result.lambda.Constraints.<name>; [] = none. Default: [].
% - `DefaultCost` — false leaves out the costs HP, fP, HQ, fQ of tab_parameter.OPF of all components. Default: true.
% - `ReferenceBus` — Bus with a fixed angle: "auto" (bus of tools.slack_bus_index, else the first bus), a bus tag, or "none". Default: "auto".
% - `Problem` — optimproblem to solve instead of building one, e.g. from net.build_opf_problem with the same Method, modified by the user; Cost, Constraint, DefaultCost and ReferenceBus are not applied to it. Default: none.
% - `InitialPoint` — Initial point (struct of values by variable name). Default: the x0 of net.build_opf_problem for the same Method; give it when Problem has added variables.
% - `WarmStart` — true starts "AC OPF" from the bus voltages of the last solved "AC OPF" of this network (kept by net.solver_OPF); false from the flat start (see SolverOPF). Default: GUILDA.setting (false).
% - `PlotFcn` — Live display during the calculation, fmincon only ("AC OPF"): keys of the plot functions of fmincon, key k for optimplot<k> ("fval", "constrviolation", "fvalconstr", "firstorderopt", "stepsize", "funccount", "x"), or a function handle stop = f(x, optimValues, state) passed to fmincon as it is; "none" draws nothing. With linprog or quadprog ("ELD", "DC OPF") a value other than "none" stops with GUILDA:SolverOPF:PlotFcnUnsupported. The figure after the calculation: result.plot_dispatch(). Default: GUILDA.setting ("none").
%
% <@Examples>
% ```matlab
% [res, flag] = net.calculate_optimal_powerflow();            % AC OPF (GUILDA.setting)
% res.tab_bus                                         % Varg, V, P, Q, Vphasor, Iphasor of each bus
% res.r_cost                                          % optimal cost
% res = net.calculate_optimal_powerflow(Method="ELD", Verbose=false);
% res.plot_dispatch();
% res.export("opf.csv");                              % bus table to a file
% % Spinning reserve of two generators; its price is the dual of the named constraint
% res = net.calculate_optimal_powerflow(Method="DC OPF", Constraint=@(v, p) struct("Reserve", ...
%           (2 - v.Component.B001SG1.P) + (2 - v.Component.B002SG1.P) >= 0.5));
% res.lambda.Constraints.Reserve
% % Solve a modified problem
% [prob, x0] = net.build_opf_problem(Method="DC OPF");
% prob.Constraints.Cap = prob.Variables.B001SG1 <= 0.4;
% res = net.calculate_optimal_powerflow(Method="DC OPF", Problem=prob, InitialPoint=x0);
% ```
%
% See also ResultOPF, SolverOPF, PowerNetwork.build_opf_problem
%
% <@Group> OPF
    arguments (Input)
        obj
        opt.Method (1,1) string {mustBeMember(opt.Method, ["ELD","DC OPF","AC OPF"])} = GUILDA.config("OptimalPowerFlow", "Method") % Formulation.
        opt.Solver (1,1) string {mustBeMember(opt.Solver, ["auto","linprog","quadprog","fmincon"])} = GUILDA.config("OptimalPowerFlow", "Solver") % Optimization solver.
        opt.Tolerance (1,1) double {mustBePositiveOrNaN} = GUILDA.config("OptimalPowerFlow", "Tolerance") % OptimalityTolerance of the solver; NaN for its default.
        opt.MaxIteration (1,1) double {mustBePositiveIntegerOrNaN} = GUILDA.config("OptimalPowerFlow", "MaxIteration") % MaxIterations of the solver; NaN for its default.
        opt.Verbose (1,1) logical = GUILDA.config("OptimalPowerFlow", "Verbose") % Print the progress of the solver.
        opt.WarmStart (1,1) logical = GUILDA.config("OptimalPowerFlow", "WarmStart") % Start "AC OPF" from the last solved "AC OPF" of this network.
        opt.PlotFcn = GUILDA.config("OptimalPowerFlow", "PlotFcn") % Live display during the calculation (fmincon only; checked by tools.check_plotfcn).
        opt.Cost {mustBeHandleOrEmpty} = [] % User cost @(v, p) added to the objective; [] for none.
        opt.Constraint {mustBeHandleOrEmpty} = [] % User constraints @(v, p) returning struct(name, constraint, ...); [] for none.
        opt.DefaultCost (1,1) logical = true % Add the cost of tab_parameter.OPF of every component.
        opt.ReferenceBus (1,1) string = "auto" % Bus with a fixed angle: "auto", a bus tag or "none".
        opt.Problem (1,1) optim.problemdef.OptimizationProblem % Problem to solve instead of building one.
        opt.InitialPoint (1,1) struct % Initial point by variable name.
    end
    arguments (Output)
        result   % Bus values, connection injections, branch flows, cost and Lagrange multipliers (ResultOPF).
        flag     % exitflag of solve (positive = solved).
        output   % Solver details; output.message describes the outcome.
    end

    % The options of the call (with the defaults of GUILDA.setting) go to the solver as they
    % are; the problem and initial point given by the user go apart from them
    sct_input = rmfield(opt, setdiff(fieldnames(opt), ["Problem","InitialPoint"]));
    opt = rmfield(opt, fieldnames(sct_input));
    opt.PlotFcn = tools.check_plotfcn(opt.PlotFcn, "calculate_optimal_powerflow", ...
        ["fval","constrviolation","fvalconstr","firstorderopt","stepsize","funccount","x"]);

    % Data of the problem: the tables of the network, its base (p.base of Cost and
    % Constraint) and the reference bus ("auto": the slack bus, else the first bus)
    sct_OPF = obj.get_opf_condition(Display=false);
    opt.base = table2struct(obj.tab_parameter.base);
    if opt.ReferenceBus == "auto"
        i_ref = tools.slack_bus_index(obj);
        if isempty(i_ref); i_ref = 1; end
        if isempty(obj.a_Bus)
            opt.ReferenceBus = "none";
        else
            opt.ReferenceBus = string(obj.a_Bus{i_ref});
        end
    end

    t0 = tic;
    [sct_solution, flag, output] = obj.solver_OPF.solve(sct_OPF.Bus, sct_OPF.Component, sct_OPF.Branch, opt, sct_input);
    sct_solver = struct("solver", string(class(obj.solver_OPF)), "options", opt, ...
        "flag", flag, "output", output, "elapsed", toc(t0));
    result = ResultOPF(struct(obj, false), sct_solution, sct_solver);
end
