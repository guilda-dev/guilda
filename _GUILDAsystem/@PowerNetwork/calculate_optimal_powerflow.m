function varargout = calculate_optimal_powerflow(obj, varargin)
% Calculate the optimal power flow of the network and return a ResultOPF.
%
% Calculates the optimal power flow of the network: the operating point that minimizes
% the generation cost (tab_parameter.OPF of the components) under the constraints in
% tab_parameter.operation of the buses, components and branches. The settings are the
% OptimalPowerFlow section of GUILDA.setting, and the conditions of the network (Cost,
% Constraint, DefaultCost, ReferenceBus) are kept by net.solver_OPF; Name-Value options
% override both for this call only (neither net.solver_OPF nor the settings file is
% changed). The network is not changed.
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
% l_isSlack is not set. The solver
% starts from the bus voltages of the last solved "AC OPF" of the network (WarmStart) or
% of the flat start (see SolverOPF), and P0, Q0 of the components; branch current and power limits are applied as |I|^2 <= Imax^2 and
% P^2 + Q^2 <= Smax^2 at both ends.
% Accepted options are the names in SolverOPF.OptionMap plus Export, Problem,
% InitialPoint and WarmStart;
% any other name stops with GUILDA:resolve_options:UnknownName.
%
% Name-Value options:
%
% - `Method` — Formulation: "ELD" (economic load dispatch, branches ignored), "DC OPF" (DC approximation) or "AC OPF" (AC power flow equations). Default: GUILDA.setting ("AC OPF").
% - `Solver` — Optimization solver; "auto" lets solve choose. Default: GUILDA.setting ("auto").
% - `Tolerance` — OptimalityTolerance of the solver; NaN = solver default. Default: GUILDA.setting (NaN).
% - `MaxIteration` — MaxIterations of the solver; NaN = solver default. Default: GUILDA.setting (NaN).
% - `Verbose` — Print the progress of the solver (Display "iter"; false: "none"). Default: GUILDA.setting (false).
% - `Cost` — Function handle @(v, p) returning a scalar added to the objective (net.solver_OPF.Cost; [] = none). v holds the variables by tag: v.Component.(tag).P/.Q, v.Bus.(tag).Varg/.V, v.Branch.(tag).Pfrom/.Pto/...; p holds p.Method and p.base (see SolverOPF).
% - `Constraint` — Function handle @(v, p) returning struct(name1, constraint1, ...); field <name> becomes prob.Constraints.<name> and result.lambda.Constraints.<name> (net.solver_OPF.Constraint; [] = none).
% - `DefaultCost` — false leaves out the costs HP, fP, HQ, fQ of tab_parameter.OPF of all components (net.solver_OPF.DefaultCost).
% - `ReferenceBus` — Bus with a fixed angle: "auto" (bus of tools.slack_bus_index, else the first bus), a bus tag, or "none" (net.solver_OPF.ReferenceBus).
% - `Problem` — optimproblem to solve instead of building one, e.g. from net.build_opf_problem with the same Method, modified by the user; Cost, Constraint, DefaultCost and ReferenceBus are not applied to it. Default: none.
% - `InitialPoint` — Initial point (struct of values by variable name). Default: the x0 of net.build_opf_problem for the same Method; give it when Problem has added variables.
% - `WarmStart` — true starts "AC OPF" from the bus voltages of the last solved "AC OPF" of this network (kept by net.solver_OPF); false from the flat start (see SolverOPF). Default: GUILDA.setting OptimalPowerFlow (false).
% - `PlotFcn` — Live display during the calculation, fmincon only ("AC OPF"): keys of the plot functions of fmincon, key k for optimplot<k> ("fval", "constrviolation", "fvalconstr", "firstorderopt", "stepsize", "funccount", "x"), or a function handle stop = f(x, optimValues, state) passed to fmincon as it is; "none" draws nothing. With linprog or quadprog ("ELD", "DC OPF") a value other than "none" stops with GUILDA:SolverOPF:PlotFcnUnsupported. The figure after the calculation: result.Plot(). Default: GUILDA.setting ("none").
% - `Export` — Call result.export after the calculation: true for the default file name, or the file name. Default: false.
%
% <@Examples>
% ```matlab
% [res, flag] = net.calculate_optimal_powerflow();            % AC OPF (GUILDA.setting)
% res.tab_bus                                         % Varg, V, P, Q, Vphasor, Iphasor of each bus
% res.r_cost                                          % optimal cost
% res = net.calculate_optimal_powerflow(Method="ELD", Verbose=false);
% res.Plot();
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
    end
    arguments (Input, Repeating)
        varargin   % Name-Value options.
    end
    arguments (Output, Repeating)
        varargout   % result (bus values, connection injections, branch flows, cost and Lagrange multipliers), flag (exitflag of solve, positive = solved), output (solver details; output.message describes the outcome).
    end

    varargin = v3_opf_args(varargin);                         % COMPAT(v3)
    [c_nv, opt] = take_call_options(varargin);
    sct_options = obj.solver_OPF.get_options(c_nv);

    sct_options.WarmStart = opt.WarmStart;
    sct_input = rmfield(opt, ["Export","WarmStart"]);
    [result, flag, output] = obj.solver_OPF.solve(obj, sct_options, sct_input);

    if isstring(opt.Export)
        result.export(opt.Export);
    elseif opt.Export
        result.export();
    end

    varargout = {result, flag, output};
    varargout = legacy_output(varargout, nargout, 6, @v3_optimize_powerflow, "OptimizePowerflowTuple"); % COMPAT(v3)
end


function [c_nv, opt] = take_call_options(c_in)
% Separates the options of this call (Export, Problem, InitialPoint, WarmStart) from the solver options
    c_nv = c_in;
    opt  = call_options();
    if mod(numel(c_in), 2) ~= 0
        return              % not Name-Value pairs: tools.resolve_options reports it
    end
    lv_call = false(size(c_in));
    for k = 1:2:numel(c_in)
        lv_call(k:k+1) = (ischar(c_in{k}) || isstring(c_in{k})) && any(strcmpi(c_in{k}, ["Export","Problem","InitialPoint","WarmStart"]));
    end
    c_call = c_in(lv_call);
    c_nv   = c_in(~lv_call);
    opt    = call_options(c_call{:});
end

function opt = call_options(opt)
    arguments (Input)
        opt.Export {mustBeA(opt.Export, ["logical","string","char"])} = false
        opt.Problem      (1,1) optim.problemdef.OptimizationProblem
        opt.InitialPoint (1,1) struct
        opt.WarmStart    (1,1) logical = GUILDA.config("OptimalPowerFlow", "WarmStart")
    end
    if ischar(opt.Export)
        opt.Export = string(opt.Export);
    end
    mustBeScalarOrEmpty(opt.Export);
end
