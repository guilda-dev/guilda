function [result, flag, output] = calculate_optimal_powerflow(obj, opt)
% Calculate the optimal power flow of the network and return a ResultOPF.
%
% Calculates the optimal power flow of the network: the operating point that minimizes
% the generation cost (tab_parameter.OPF of the components) under the constraints in
% tab_parameter.operation of the buses, components and branches. The settings are the
% OptimalPowerFlow section of GUILDA.setting; Name-Value options override them for this
% call only (the settings file is not changed). Cost, Constraint, DefaultCost and
% ReferenceBus are options of the call only. The network is not changed.
% The cost of each component is HP*P^2 + fP*P + HQ*Q^2 + fQ*Q + c (tab_parameter.OPF; Q
% terms in "AC OPF" only; the constant c adds to the cost without changing the solution); the default cost of a load is 0. A load keeps the P and Q of
% tab_parameter.powerflow while its Pmin/Pmax (Qmin/Qmax) are infinite; with finite
% bounds it is dispatched within them. A default limit of one object is removed by setting
% it to Inf (-Inf for a lower bound) in its tab_parameter.operation: Vmin, Vmax (bus);
% Pmin, Pmax, Qmin, Qmax (component); Pmax, Qmax, Vargmax, Imax, Smax (branch, where NaN
% also means none). User costs and constraints over the whole network are the options
% Cost and Constraint; a problem from net.build_opf_problem, modified by the user, is
% solved with Problem. The columns startup and shutdown of tab_parameter.OPF
% are reserved: unit commitment is not part of the problem. The variables are V and Varg of
% the buses and P and Q of the components: the power balance of each bus and the branch
% limits are written with the branch flows as expressions of V and Varg. "DC OPF" uses |V| = 1 and
% the MATPOWER branch susceptance b = 1/(X*tap) (tap ratio and phase shift at the from
% end). The angle of the ReferenceBus is fixed to its tab_parameter.powerflow Varg;
% l_isSlack is not set. The solver starts from the bus voltages of the last solved
% "AC OPF" of the network (WarmStart) or of the flat start (see SolverOPF), and P0, Q0 of
% the components; branch current and power limits are applied as |I|^2 <= Imax^2 and
% P^2 + Q^2 <= Smax^2 at both ends. Options not listed below stop with the MATLAB error
% of an unknown name. The result is written to a file with result.export.
% The calculation runs three stages: net.build_opf_problem builds the problem (it collects
% the tables of net.get_opf_condition, the base and the reference bus, and
% net.solver_OPF builds the problem from these data only); net.solver_OPF.solve solves
% the built problem, or the given Problem, without building it again; the ResultOPF is
% built from a snapshot of the network (struct(net, false)) and the solution. res.options holds the Name-Value options
% of the run (Problem and InitialPoint excepted), with ReferenceBus as the bus tag ("auto"
% resolved) and base (baseMVA, Hz); the settings without an option (the algorithm and
% the step tolerances of each solver, <Solver><option>) are read by SolverOPF from
% GUILDA.setting.
%
% Stability-constrained OPF ("AC OPF" only; MinDampingRatio or MaxRealPart not NaN): the
% small-signal limits of the dynamic model of the same network are added. Each outer
% iteration solves the OPF, builds the point of get_sys at its solution without writing the
% network (a power flow of the set points of the solution, then get_equilibrium of the
% components and controllers, which return values), and takes the eigenvalues of
% get_sys(point, Type="ODE"): the damping ratio of the oscillatory modes and the real part
% of the nonzero eigenvalues (the zero eigenvalues, e.g. the reference angle, are left out).
% When a limit is not met, the modes within StabilityBand of it get constraints linearized at
% the solution in the set points u (P of the generators whose P bounds differ, except at the
% slack bus of the power flow; V of the generator buses), by forward differences of u; they
% ask for the limit with StabilityMargin, replace those of the previous iteration, have a
% slack with a penalty in the objective (so that the OPF goes as far as it can when the
% limits cannot be met at once; the penalty is not in result.r_cost), and come with a trust
% region |u - u_k| <= StabilityStep, halved when the violation grows. The network must be
% initialized (get_sys stops with GUILDA:PowerSystemModel:Stale otherwise) and is not
% changed. It ends when the limits hold (the flag of the last OPF), or with flag 0 after
% StabilityMaxIteration outer iterations or when the trust region has shrunk to 1/64. When
% the OPF of an outer iteration after the first stops without a solution (flag <= 0, e.g.
% the MaxIteration of fmincon), its last iterate is not returned (it may break the power
% balance and cost less than the optimum): the result is the solution of the previous outer
% iteration, the flag is 0, tab_iteration ends with a row of the stopped OPF (Cost and the
% limits NaN, Flag its exit flag), and the warning GUILDA:PowerNetwork:StabilityOPFFailed
% tells it; when the first OPF stops, the result is that of the plain OPF. INFO
% messages (GUILDA.setting Message.ShowInfo) tell when the number of zero eigenvalues differs
% from the number of islands (GUILDA:PowerNetwork:StabilityZeroEigenvalues, e.g. a frequency
% mode without damping) and when modes cannot be followed at the points of the differences
% and get no constraint in that iteration (GUILDA:PowerNetwork:StabilityModeNotTracked).
% result.sct_stability holds the outer iterations and the modes of the last solution;
% GUILDA:PowerNetwork:StabilityNeedsACOPF stops "DC OPF" and "ELD", and
% GUILDA:PowerNetwork:StabilityPointFailed a point that cannot be built (the power flow of
% the set points, or a get_equilibrium that stops, e.g. at a limit of a controller).
%
% Name-Value options:
%
% - `Method` — Formulation: "ELD" (economic load dispatch, branches ignored), "DC OPF" (DC approximation) or "AC OPF" (AC power flow equations). Default: GUILDA.setting ("AC OPF").
% - `Solver` — Optimization solver; "auto" lets solve choose. Default: GUILDA.setting ("auto").
% - `Tolerance` — OptimalityTolerance of the solver; NaN = solver default. Default: GUILDA.setting (NaN).
% - `MaxIteration` — MaxIterations of the solver; NaN = solver default. Default: GUILDA.setting (NaN).
% - `Verbose` — Print the progress of the solver (Display "iter"; false: "none"). Default: GUILDA.setting (false).
% - `Progress` — Progress display: "dialog" (a dialog that opens when the calculation lasts 0.5 s or longer, showing the solver and, for fmincon, the iteration, the cost and the constraint violation; the outer iteration of the stability-constrained OPF; inside the GUILDA app a dialog of the app window), "disp" (one line per step in the Command Window) or "none"; true is "dialog" and false "none". Default: GUILDA.setting ("dialog").
% - `Cost` — Function handle @(v, p) returning a scalar added to the objective; [] = none. v holds the variables by tag: v.Component.(tag).P/.Q, v.Bus.(tag).Varg/.V, v.Branch.(tag).Pfrom/.Pto/...; p holds p.Method and p.base (see SolverOPF). Default: [].
% - `Constraint` — Function handle @(v, p) returning struct(name1, constraint1, ...); field <name> becomes prob.Constraints.<name> and result.lambda.Constraints.<name>; [] = none. Default: [].
% - `DefaultCost` — false leaves out the costs HP, fP, HQ, fQ, c of tab_parameter.OPF of all components. Default: true.
% - `ReferenceBus` — Bus with a fixed angle: "auto" (the slack bus if one is set, else the first bus; the OPF needs no slack bus), a bus tag, or "none". Default: "auto".
% - `Problem` — optimproblem to solve instead of building one, e.g. from net.build_opf_problem with the same Method, modified by the user; Cost, Constraint, DefaultCost and ReferenceBus are not applied to it. Default: none.
% - `InitialPoint` — Initial point (struct of values by variable name). Default: the x0 of net.build_opf_problem for the same Method; give it when Problem has added variables.
% - `WarmStart` — true starts "AC OPF" from the bus voltages of the last solved "AC OPF" of this network (kept by net.solver_OPF); false from the flat start (see SolverOPF). Default: GUILDA.setting (false).
% - `MinDampingRatio` — Lower limit of the damping ratio of the oscillatory modes at the solution (stability-constrained OPF); NaN = none. Default: GUILDA.setting (NaN).
% - `MaxRealPart` — [1/s] Upper limit of the real part of the nonzero eigenvalues at the solution; NaN = none. Default: GUILDA.setting (NaN).
% - `StabilityMaxIteration` — Largest number of outer iterations. Default: GUILDA.setting (10).
% - `StabilityStep` — [pu] Initial trust region [dP dV] of the set points; Inf = none for that kind. Default: GUILDA.setting ([0.1 0.02]).
% - `StabilityMargin` — Margin [damping ratio, real part 1/s] that the linearized constraints keep from the limits. Default: GUILDA.setting ([0.005 0.005]).
% - `StabilityBand` — Width [damping ratio, real part 1/s] of the band near a limit whose modes get constraints. Default: GUILDA.setting ([0.02 0.05]).
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
% % Stability-constrained OPF: the smallest damping ratio at the solution at least 0.048
% net = network.IEEE14bus();
% [res, flag] = net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=0.048);
% res.sct_stability.tab_iteration         % cost, damping ratio and real part of each outer iteration
% res.sct_stability.tab_mode              % modes of the solution
% ```
%
% See also ResultOPF, SolverOPF, PowerNetwork.build_opf_problem
%
% <@Group> OPF
    arguments (Input)
        obj
        opt.Method (1,1) string {mustBeMember(opt.Method, ["ELD","DC OPF","AC OPF"])} = GUILDA.config("OptimalPowerFlow", "Method")  % Formulation.
        opt.Solver (1,1) string {mustBeMember(opt.Solver, ["auto","linprog","quadprog","fmincon"])} = GUILDA.config("OptimalPowerFlow", "Solver")  % Optimization solver.
        opt.Tolerance (1,1) double {mustBePositiveOrNaN} = GUILDA.config("OptimalPowerFlow", "Tolerance")  % OptimalityTolerance of the solver; NaN for its default.
        opt.MaxIteration (1,1) double {mustBePositiveIntegerOrNaN} = GUILDA.config("OptimalPowerFlow", "MaxIteration")  % MaxIterations of the solver; NaN for its default.
        opt.Verbose (1,1) logical = GUILDA.config("OptimalPowerFlow", "Verbose")  % Print the progress of the solver.
        opt.WarmStart (1,1) logical = GUILDA.config("OptimalPowerFlow", "WarmStart")  % Start "AC OPF" from the last solved "AC OPF" of this network.
        opt.PlotFcn = GUILDA.config("OptimalPowerFlow", "PlotFcn")  % Live display during the calculation (fmincon only; checked by tools.check_plotfcn).
        opt.Progress {mustBeProgress} = GUILDA.config("OptimalPowerFlow", "Progress")  % "dialog", "disp" or "none" (true: "dialog", false: "none").
        opt.Cost {mustBeHandleOrEmpty} = []                         % User cost @(v, p) added to the objective; [] for none.
        opt.Constraint {mustBeHandleOrEmpty} = []                   % User constraints @(v, p) returning struct(name, constraint, ...); [] for none.
        opt.DefaultCost (1,1) logical = true                        % Add the cost of tab_parameter.OPF of every component.
        opt.ReferenceBus (1,1) string = "auto"                      % Bus with a fixed angle: "auto", a bus tag or "none".
        opt.Problem (1,1) optim.problemdef.OptimizationProblem      % Problem to solve instead of building one. Default: the problem built from the network (build_opf_problem).
        opt.InitialPoint (1,1) struct                               % Initial point by variable name. Default: the x0 of build_opf_problem.
        opt.MinDampingRatio (1,1) double {mustBeDampingRatioOrNaN} = GUILDA.config("OptimalPowerFlow", "MinDampingRatio")  % Lower limit of the damping ratio of the oscillatory modes; NaN for none.
        opt.MaxRealPart (1,1) double {mustBeFiniteOrNaN} = GUILDA.config("OptimalPowerFlow", "MaxRealPart")  % [1/s] Upper limit of the real part of the nonzero eigenvalues; NaN for none.
        opt.StabilityMaxIteration (1,1) double {mustBeInteger, mustBePositive} = GUILDA.config("OptimalPowerFlow", "StabilityMaxIteration")  % Largest number of outer iterations.
        opt.StabilityStep (1,2) double {mustBePositive} = GUILDA.config("OptimalPowerFlow", "StabilityStep")  % [pu] Initial trust region [dP dV]; Inf for none.
        opt.StabilityMargin (1,2) double {mustBeNonnegative, mustBeFinite} = GUILDA.config("OptimalPowerFlow", "StabilityMargin")  % Margin [damping ratio, real part] of the linearized constraints.
        opt.StabilityBand (1,2) double {mustBeNonnegative, mustBeFinite} = GUILDA.config("OptimalPowerFlow", "StabilityBand")  % Band [damping ratio, real part] of the critical modes.
    end
    arguments (Output)
        result  % Bus values, connection injections, branch flows, cost and Lagrange multipliers (ResultOPF).
        flag    % exitflag of solve (positive = solved).
        output  % Solver details; output.message describes the outcome.
    end

    % The options of the call (with the defaults of GUILDA.setting) go to the solver as they
    % are; the problem and initial point given by the user go apart from them
    sct_input = rmfield(opt, setdiff(fieldnames(opt), ["Problem","InitialPoint"]));
    opt = rmfield(opt, fieldnames(sct_input));
    opt.PlotFcn = tools.check_plotfcn(opt.PlotFcn, "calculate_optimal_powerflow", ...
        ["fval","constrviolation","fvalconstr","firstorderopt","stepsize","funccount","x"]);
    l_stability = ~isnan(opt.MinDampingRatio) || ~isnan(opt.MaxRealPart);
    if l_stability && opt.Method ~= "AC OPF"
        error(msg("GUILDA:PowerNetwork:StabilityNeedsACOPF", opt.Method))
    end
    t0 = tic;
    % The progress display starts before the problem is built and goes to the solver; it
    % closes at the end of the calculation or on an error
    prog   = ProgressGUILDA(opt.Progress, "Optimal power flow");
    c_prog = onCleanup(@() delete(prog));
    prog.update("Optimal power flow (" + opt.Method + "): building the problem...");

    % 1. Build the problem; a given Problem is solved as it is, and the problem built
    % without the user terms gives its initial point and data
    c_user = {"Cost", opt.Cost, "Constraint", opt.Constraint};
    if isfield(sct_input, "Problem"); c_user = {}; end
    [prob, x0, sct_data] = obj.build_opf_problem(c_user{:}, Method=opt.Method, ...
        DefaultCost=opt.DefaultCost, ReferenceBus=opt.ReferenceBus);
    if isfield(sct_input, "Problem"); prob = sct_input.Problem; end
    opt.base = sct_data.base;
    opt.ReferenceBus = sct_data.ReferenceBus;

    % 2. Solve it. A given InitialPoint is used as it is, without the warm start
    sct_solve = opt;
    sct_solve.Progress = prog;
    if isfield(sct_input, "InitialPoint")
        x0 = sct_input.InitialPoint;
        sct_solve.WarmStart = false;
    end
    if ~l_stability
        [sct_solution, flag, output] = obj.solver_OPF.solve(prob, x0, sct_data.Bus, sct_data.Component, sct_data.Branch, sct_solve);
    else
        % 2'. Stability-constrained OPF: outer iterations of the OPF with the stability
        % constraints linearized at the last solution (see notes/opf-requirements.md). The
        % network is not written: the points of get_sys come from stability_point.
        %
        % The data that stay through the iterations (sct_ctx): the power flow table of the
        % buses with the slack bus at the reference bus (the slack bus of the network when the
        % reference bus has no generator), the admittance matrix, the snapshot buses (their
        % component set points take the OPF solution), the set points u (P of the generators
        % whose P bounds differ, not at the slack bus; V of the PV and slack buses), the
        % models and their rows in the variable map, and the power flow options
        sv_bus = reshape(string(obj.a_Bus), [], 1);
        tab_pf = tools.vcellfun(@(b) b.get_pf_condition, obj.a_Bus);
        tab_pf.Properties.RowNames = sv_bus;
        i_slack = find(sv_bus == opt.ReferenceBus & tab_pf.Type ~= "PQ", 1);
        if isempty(i_slack)
            i_slack = find(tab_pf.Type == "slack", 1);
        end
        if isempty(i_slack)
            error(msg("GUILDA:PowerNetwork:StabilityPointFailed", "of the OPF solution", "no bus with a generator can be the slack bus of the power flow"))
        end
        tab_pf.Type(tab_pf.Type == "slack") = "PV";
        tab_pf.Type(i_slack) = "slack";
        sct_net = struct(obj, false);
        a_bus = reshape(sct_net.a_Bus, [], 1);
        tab_map = obj.get_variable_map();
        f_rows = @(s_kind, s_owner) tab_map.Index(tab_map.Kind == s_kind & tab_map.Owner == s_owner);
        c_unit = cell(numel(a_bus), 1);
        tab_u = table(strings(0,1), strings(0,1), zeros(0,1), zeros(0,1), 'VariableNames', ["Kind","Name","Bus","Component"]);
        for i = 1:numel(a_bus)
            a_bus{i}.l_isSlack = i == i_slack;
            a_comp = obj.a_Bus{i}.a_Component;
            c_unit{i} = cell(numel(a_comp), 1);
            for j = 1:numel(a_comp)
                s_c = string(a_comp{j}.s_tag);
                c_unit{i}{j} = {a_comp{j}, f_rows("x", s_c), f_rows("u", s_c)};   % the component, then its local controllers
                for o = reshape(all_controllers(a_comp{j}), 1, [])
                    c_unit{i}{j}(end+1,:) = {o{1}, f_rows("x", string(o{1}.s_tag)), f_rows("uc", string(o{1}.s_tag))};
                end
                var = prob.Variables.(s_c);
                if i ~= i_slack && isa(a_comp{j}, "component.generator.abstract") && var.LowerBound(1) ~= var.UpperBound(1)
                    tab_u(end+1,:) = {"P", s_c, i, j}; %#ok<AGROW>
                end
            end
        end
        for i = reshape(find(tab_pf.Type ~= "PQ"), 1, [])
            tab_u(end+1,:) = {"V", sv_bus(i), i, 0}; %#ok<AGROW>
        end
        sct_pf = GUILDA.config("PowerFlowCalculation");
        sct_pf = struct("Solver", sct_pf.Solver.Value, "Tolerance", sct_pf.Tolerance.Value, ...
            "MaxIteration", sct_pf.MaxIteration.Value, "Verbose", false, "WarmStart", false, "PlotFcn", "none", "Progress", "none");
        c_gc = cell(0, 3);
        for g = reshape(obj.a_GlobalController, 1, [])
            c_gc(end+1,:) = {g{1}, f_rows("x", string(g{1}.s_tag)), f_rows("uc", string(g{1}.s_tag))}; %#ok<AGROW>
        end
        sct_ctx = struct("tab_pf", tab_pf, "cm_Y", obj.get_admittance_matrix.Variables, "a_bus", {a_bus}, ...
            "tab_u", tab_u, "c_unit", {c_unit}, "c_gc", {c_gc}, "sct_pf", sct_pf, ...
            "n_point", nnz(ismember(tab_map.Kind, ["x","Vre","Vim","u","uc"])), ...
            "iv_Vre", arrayfun(@(s) tab_map.Index(tab_map.Kind == "Vre" & tab_map.Bus == s), sv_bus), ...
            "iv_Vim", arrayfun(@(s) tab_map.Index(tab_map.Kind == "Vim" & tab_map.Bus == s), sv_bus), ...
            "sv_owner", tab_map.Owner(tab_map.Kind == "x"));
        % the islands of the network (one zero eigenvalue each is expected: the reference angle)
        im_edge = zeros(numel(obj.a_Branch), 2);
        for k = 1:numel(obj.a_Branch)
            [~, im_edge(k,:)] = ismember(string(obj.a_Branch{k}.a_Bus), sv_bus);
        end
        n_island = max([0, conncomp(graph(im_edge(:,1), im_edge(:,2), [], numel(sv_bus)))]);
        l_infoZero = false;
        % the set points as OPF expressions, the steps of the differences and the trust region
        c_var = cell(height(tab_u), 1);
        for k = 1:height(tab_u)
            c_var{k} = prob.Variables.(tab_u.Name(k))(1 + (tab_u.Kind(k) == "V"));   % [P; Q] of a component, [Varg; V] of a bus
        end
        ex_u  = vertcat(c_var{:});
        rv_h    = 1e-3*(tab_u.Kind == "P") + 1e-4*(tab_u.Kind == "V");
        rv_step = opt.StabilityStep(1 + (tab_u.Kind == "V")).';
        r_min   = opt.MinDampingRatio;
        r_max   = opt.MaxRealPart;
        prob0   = prob;
        r_viol  = Inf;
        tab_it  = table();
        tab_mode = table();
        sct_solve.Progress = "none";     % the outer iterations are shown instead
        for it = 1:opt.StabilityMaxIteration
            prog.update(sprintf("Stability-constrained OPF: outer iteration %d of %d", it, opt.StabilityMaxIteration));
            % the OPF with the cuts of the last iteration (their penalty r_w*sum(slack) is
            % taken out of the cost of the result)
            [sct_solution, flag, output] = obj.solver_OPF.solve(prob, x0, sct_data.Bus, sct_data.Component, sct_data.Branch, sct_solve);
            if isfield(x0, "StabilitySlack")
                sct_solution.r_cost = sct_solution.r_cost - r_w*sum(sct_solution.sct_iteration.X.StabilitySlack(:, end));
            end
            if ~(flag > 0)
                output.message = string(output.message) + sprintf(" (outer iteration %d of the stability-constrained OPF)", it);
                if it > 1
                    % the OPF with the cuts stopped: its last iterate is no solution (it may
                    % break the power balance and cost less than the optimum), so the result is
                    % the solution of the previous outer iteration, with flag 0
                    tab_it = [tab_it; table(it, NaN, NaN, NaN, "", tab_it.Step(end,:), double(flag), ...
                        'VariableNames', tab_it.Properties.VariableNames)]; %#ok<AGROW>
                    show_msg("warning", "GUILDA:PowerNetwork:StabilityOPFFailed", string(it), string(double(flag)), ...
                        string(it - 1), sprintf("%.6g", sct_last.r_cost), sprintf("%.4g", tab_it.MinDampingRatio(end-1)), sprintf("%.4g", tab_it.MaxRealPart(end-1)))
                    output.message = output.message + sprintf(" The result is the solution of outer iteration %d (cost %.6g), which does not meet the stability limits: minimum damping ratio %.4g (limit %g), largest real part %.4g 1/s (limit %g).", ...
                        it - 1, sct_last.r_cost, tab_it.MinDampingRatio(end-1), r_min, tab_it.MaxRealPart(end-1), r_max);
                    sct_solution = sct_last;
                    flag = 0;
                end
                break
            end
            sct_last = sct_solution;

            % the point of the solution: the set points u_k, the powers of the components
            % and the start of the power flow from the solution
            cv_V = sct_solution.tab_bus{sv_bus, "Vphasor"};
            tab_cub = sct_solution.tab_cub;
            sct_ctx.tab_pf.V0    = abs(cv_V);
            sct_ctx.tab_pf.Varg0 = angle(cv_V);
            sct_ctx.tab_pf{i_slack, ["Varg","V"]} = [angle(cv_V(i_slack)), abs(cv_V(i_slack))];
            for i = 1:numel(a_bus)
                for j = 1:numel(a_bus{i}.a_Component)
                    pf = sct_ctx.a_bus{i}.a_Component{j}.tab_parameter.powerflow;
                    s_c = string(obj.a_Bus{i}.a_Component{j}.s_tag);
                    pf.P = tab_cub{s_c, "P"};
                    if ~isnan(a_bus{i}.a_Component{j}.tab_parameter.powerflow.Q)
                        pf.Q = tab_cub{s_c, "Q"};
                    end
                    sct_ctx.a_bus{i}.a_Component{j}.tab_parameter.powerflow = pf;
                end
                rm_PQ = [zeros(0, 2); cell2mat(cellfun(@(c) [c.tab_parameter.powerflow.P, c.tab_parameter.powerflow.Q], sct_ctx.a_bus{i}.a_Component(:), "UniformOutput", false))];
                if sct_ctx.tab_pf.Type(i) ~= "slack"
                    sct_ctx.tab_pf.P(i) = sum(rm_PQ(:,1));
                end
                if sct_ctx.tab_pf.Type(i) == "PQ"
                    sct_ctx.tab_pf.Q(i) = sum(rm_PQ(:,2));
                end
            end
            rv_u = zeros(height(tab_u), 1);
            lv_P = tab_u.Kind == "P";
            rv_u(lv_P)  = tab_cub{tab_u.Name(lv_P), "P"};
            rv_u(~lv_P) = abs(cv_V(tab_u.Bus(~lv_P)));
            sct_mode = stability_modes(obj, stability_point(sct_ctx, rv_u, "of the OPF solution"), sct_ctx.sv_owner);
            if sct_mode.n_zero ~= n_island && ~l_infoZero     % once a call
                show_msg("info", "GUILDA:PowerNetwork:StabilityZeroEigenvalues", string(sct_mode.n_zero), string(n_island), string(it))
                l_infoZero = true;
            end

            % the limits at this solution; the critical modes are those within the band
            r_zeta = min([sct_mode.zeta(sct_mode.l_osc); Inf]);
            r_re   = max([real(sct_mode.lambda); -Inf]);
            lv_cZ  = sct_mode.l_osc & sct_mode.zeta < r_min + opt.StabilityBand(1);
            lv_cR  = real(sct_mode.lambda) > r_max - opt.StabilityBand(2);
            % listed by the limit they are near: the damping ratio from the smallest, then
            % the real part (modes not near the damping limit) from the largest
            iv_cZ = find(lv_cZ);
            iv_cR = find(lv_cR & ~lv_cZ);
            [~, iv_o] = sort(sct_mode.zeta(iv_cZ), "ascend");
            [~, iv_r] = sort(real(sct_mode.lambda(iv_cR)), "descend");
            iv_list = [iv_cZ(iv_o); iv_cR(iv_r)];
            sv_crit = sct_mode.owner(iv_list) + compose(" %.3g Hz", sct_mode.frequency(iv_list));
            r_violPrev = r_viol;
            r_viol = max([r_min - r_zeta, r_re - r_max, 0], [], "omitnan");
            if it > 1 && r_viol > r_violPrev
                rv_step = rv_step / 2;
            end
            s_crit = strjoin([sv_crit; strings(0,1)], ", ");
            tab_it = [tab_it; table(it, sct_solution.r_cost, r_zeta, r_re, s_crit, ...
                [min([rv_step(lv_P); Inf]), min([rv_step(~lv_P); Inf])], double(flag), ...
                'VariableNames', ["Iteration","Cost","MinDampingRatio","MaxRealPart","CriticalMode","Step","Flag"])]; %#ok<AGROW>
            tab_mode = table(sct_mode.lambda, sct_mode.frequency, sct_mode.zeta, sct_mode.owner, ...
                'VariableNames', ["Eigenvalue","Frequency","DampingRatio","Owner"]);
            if r_viol <= 0
                output.message = string(output.message) + sprintf(" The stability limits hold after %d outer iterations (minimum damping ratio %.4g, largest real part %.4g 1/s).", it, r_zeta, r_re);
                break
            end
            if it == opt.StabilityMaxIteration || any(rv_step < opt.StabilityStep(1 + ~lv_P).' / 64)
                flag = 0;
                output.message = string(output.message) + sprintf(" The stability limits are not met after %d outer iterations: minimum damping ratio %.4g (limit %g), largest real part %.4g 1/s (limit %g); critical modes: %s.", ...
                    it, r_zeta, r_min, r_re, r_max, s_crit);
                break
            end

            % the next problem: the cuts of the critical modes at u_k (replacing the previous
            % ones), each with a slack s >= 0 so that the problem keeps a solution when the
            % cuts of several modes and the power flow cannot be met together (the penalty
            % r_w*s, r_w = 1e3*max(1, |cost of the first OPF - the sum of the constant costs c
            % (DefaultCost)|) per unit of zeta or of 1/s, makes the OPF go as far as it can; c
            % changes no solution and is left out of the scale), and the trust region around u_k
            iv_crit = find(lv_cZ | lv_cR);
            [rm_gZ, rm_gR] = stability_gradient(obj, sct_ctx, rv_u, sct_mode, iv_crit, rv_h);
            lv_dZ = lv_cZ(iv_crit) & all(isfinite(rm_gZ), 2);
            lv_dR = lv_cR(iv_crit) & all(isfinite(rm_gR), 2);
            lv_lost = (lv_cZ(iv_crit) & ~lv_dZ) | (lv_cR(iv_crit) & ~lv_dR);   % modes not found at a point of the differences
            if any(lv_lost)
                cv_lost = sct_mode.lambda(iv_crit(lv_lost));
                show_msg("info", "GUILDA:PowerNetwork:StabilityModeNotTracked", string(it), join(compose("%s %.3g Hz (%.4g%+.4gi)", ...
                    sct_mode.owner(iv_crit(lv_lost)), sct_mode.frequency(iv_crit(lv_lost)), real(cv_lost), imag(cv_lost)), ", "))
            end
            rv_z  = sct_mode.zeta(iv_crit);
            rv_r  = real(sct_mode.lambda(iv_crit));
            r_goalZ = r_min + opt.StabilityMargin(1);
            r_goalR = r_max - opt.StabilityMargin(2);
            if it == 1
                r_w = 1e3*max(1, abs(sct_solution.r_cost - opt.DefaultCost*sum(sct_data.Component.c)));
            end
            x0 = structfun(@(x) x(:, end), sct_solution.sct_iteration.X, "UniformOutput", false);
            x0 = rmfield(x0, intersect(fieldnames(x0), "StabilitySlack"));
            sct_cons = prob0.Constraints;
            ex_obj   = prob0.Objective;      % one objective (GenCost of the built problem), a labelled struct or an expression
            n_cut    = nnz(lv_dZ) + nnz(lv_dR);
            if n_cut > 0
                v_slack = optimvar("StabilitySlack", n_cut, 1, "LowerBound", 0);
                if any(lv_dZ)
                    sct_cons.StabilityDamping = rv_z(lv_dZ) + rm_gZ(lv_dZ,:)*(ex_u - rv_u) + v_slack(1:nnz(lv_dZ)) >= r_goalZ;
                end
                if any(lv_dR)
                    sct_cons.StabilityRealPart = rv_r(lv_dR) + rm_gR(lv_dR,:)*(ex_u - rv_u) - v_slack(nnz(lv_dZ)+1:end) <= r_goalR;
                end
                if isstruct(ex_obj)
                    sv_f = string(fieldnames(ex_obj));
                    ex_obj.(sv_f(1)) = ex_obj.(sv_f(1)) + r_w*sum(v_slack);
                else
                    ex_obj = ex_obj + r_w*sum(v_slack);
                end
                x0.StabilitySlack = max(0, [r_goalZ - rv_z(lv_dZ); rv_r(lv_dR) - r_goalR]);   % the slacks that u_k needs
            end
            for k = reshape(find(isfinite(rv_step)), 1, [])
                sct_cons.("StabilityStep_" + tab_u.Name(k)) = [ex_u(k) - rv_u(k) <= rv_step(k); rv_u(k) - ex_u(k) <= rv_step(k)];
            end
            prob = optimproblem("Objective", ex_obj, "Constraints", sct_cons, "Description", prob0.Description);
            sct_solve.WarmStart = false;
        end
        sct_solution.sct_stability = struct("tab_iteration", tab_it, "tab_mode", tab_mode);
    end

    delete(c_prog);

    % 3. Build the result from a snapshot of the network and the solution
    sct_solver = struct("solver", string(class(obj.solver_OPF)), "options", opt, ...
        "flag", flag, "output", output, "elapsed", toc(t0));
    result = ResultOPF(struct(obj, false), sct_solution, sct_solver);
end
