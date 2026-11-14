function [prob, x0] = build_problem(obj, tab_bus, tab_component, tab_branch, sct_options)
% Build the optimization problem of the optimal power flow from the data of a network.
%
% Builds the optimproblem for sct_options.Method from the tables of the buses, components
% and branches that net.build_opf_problem collects from tab_parameter (rows named by tag;
% see that method); no network object and no state of the solver is read. Called by
% net.build_opf_problem, which net.calculate_optimal_powerflow calls.
%
% - Variables: one per bus (Varg, V), component (P, Q) and branch end
%   ("<branch>_<bus>": P, Q, Ireal, Iimag flowing into the bus), named by tag.
% - Bounds from the tables (tab_parameter.operation); an infinite bound (NaN for the
%   branch limits) adds no limit. The fixed P (Q) of a load is in its bounds.
% - Constraints: power balance balancedP_<bus> / balancedQ_<bus> (balancedP in "ELD"),
%   branch definitions defIre_, defIim_, defP_, defQ_ (<branch>_<bus>), limits Imax_,
%   Smax_, VargMax1_<branch>, VargMax2_<branch>, and VargRef (ReferenceBus).
% - Objective GenCost: HP*P^2 + fP*P + HQ*Q^2 + fQ*Q of every component (DefaultCost),
%   plus Cost(v, p).
% - Constraint(v, p) adds named constraints prob.Constraints.<name>.
% x0 is the flat start: the bus voltages angle 0 and magnitude 1, with the set V at PV and
% slack buses and the set angle at the slack bus, and P0, Q0 of the components; the branch
% ends start at the flows of these voltages. The warm start replaces the bus and branch
% values in SolverOPF.solve.
%
% <@Examples>
% ```matlab
% % the data as net.build_opf_problem collects them, e.g. one bus with one generator
% tab_bus = table(0.9, 1.1, 0, 0, "slack", 1, 0, 'VariableNames', ...
%     ["Vmin","Vmax","Gshunt","Bshunt","Type","V","Varg"], 'RowNames', "B1");
% tab_com = table("B1", 1, 1, 0, 0, 1, 0, 0, 2, -1, 1, 'VariableNames', ...
%     ["Bus","HP","fP","HQ","fQ","P0","Q0","Pmin","Pmax","Qmin","Qmax"], 'RowNames', "G1");
% tab_br  = table(strings(0,1), strings(0,1), complex(zeros(0,2,2)), zeros(0,1), zeros(0,1), ...
%     zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), 'VariableNames', ...
%     ["From","To","Y","X","tap","phase","Pmax","Qmax","Vargmax","Imax","Smax"]);
% sct = struct("Method","DC OPF", "Cost",[], "Constraint",[], "DefaultCost",true, ...
%     "ReferenceBus","B1", "base",struct("Hz",60,"baseMVA",100));
% [prob, x0] = SolverOPF().build_problem(tab_bus, tab_com, tab_br, sct);
% ```
%
% See also PowerNetwork.build_opf_problem, SolverOPF.solve
    arguments (Input)
        obj                          % Solver (net.solver_OPF); not read.
        tab_bus       table          % Buses: Vmin, Vmax, Gshunt, Bshunt, Type, V, Varg; row names = bus tags.
        tab_component table          % Components: Bus, HP, fP, HQ, fQ, P0, Q0, Pmin, Pmax, Qmin, Qmax; row names = tags.
        tab_branch    table          % Branches: From, To, Y (2x2 pages), X, tap, phase, Pmax, Qmax, Vargmax, Imax, Smax; row names = tags.
        sct_options   (1,1) struct   % Settings: Method, Cost, Constraint, DefaultCost, ReferenceBus (bus tag or "none"), base (baseMVA, Hz).
    end
    arguments (Output)
        prob % optimproblem; its Description shows the OPF data of the buses, components and branches.
        x0   % Initial point: struct of the values of every variable, by variable name.
    end
    s_method = sct_options.Method;
    sv_bus   = string(tab_bus.Properties.RowNames);

    % Description of the problem: the OPF data of the buses, components and branches
    s_rule = string(repmat('=',1,100));
    s_text = newline + "Optimal Power Flow (" + s_method + ")" + newline + s_rule + newline + newline ...
           + "<<Bus OPF setting>>"       + newline + formattedDisplayText(tab_bus)                    + newline + newline ...
           + "<<Component OPF setting>>" + newline + formattedDisplayText(tab_component)              + newline + newline ...
           + "<<Branch OPF setting>>"    + newline + formattedDisplayText(removevars(tab_branch, "Y")) + newline + newline ...
           + s_rule + newline;
    prob = optimproblem("ObjectiveSense","minimize", ...
                        "Objective"     ,struct("GenCost",0), ...
                        "Description"   ,s_text);
    x0      = struct();
    const   = struct();
    sct_var = struct();   % every optimization variable, by variable name
    if s_method == "ELD"
        const.P = 0;
    end

    % Flat start of the buses and branch ends: [Varg, V] = [0, 1], the set V at PV and
    % slack buses and the set angle at the slack bus
    n_bus    = height(tab_bus);
    rm_init  = [zeros(n_bus,1), ones(n_bus,1)];
    lv_set   = tab_bus.Type ~= "PQ";
    lv_slack = tab_bus.Type == "slack";
    rm_init(lv_set, 2)   = tab_bus.V(lv_set);
    rm_init(lv_slack, 1) = tab_bus.Varg(lv_slack);
    x0 = start_point(x0, sv_bus, rm_init, tab_branch, s_method);

    sv_at = tab_component.Bus;
    for i_bus = 1:numel(sv_bus)
        [const, var] = build_bus(tab_bus(i_bus,:), const, s_method);
        if ~isempty(var)
            sct_var.(sv_bus(i_bus)) = var;
        end
        for i_com = reshape(find(sv_at == sv_bus(i_bus)), 1, [])
            [prob, x0, const, var] = build_component(tab_component(i_com,:), prob, x0, const, s_method, sct_options.DefaultCost);
            sct_var.(string(tab_component.Properties.RowNames{i_com})) = var;
        end
    end

    % Reference angle (not in "ELD"): the angle of ReferenceBus is fixed to its power-flow
    % Varg (0 if NaN), constraint VargRef; "none" fixes no angle ("auto" is resolved by
    % the caller)
    s_ref = sct_options.ReferenceBus;
    if s_method ~= "ELD" && s_ref ~= "none"
        i_ref = find(sv_bus == s_ref, 1);
        if isempty(i_ref)
            error(msg("GUILDA:SolverOPF:UnknownReferenceBus", s_ref))
        end
        Varg_ref = tab_bus.Varg(i_ref);
        if isnan(Varg_ref); Varg_ref = 0; end
        Vref = sct_var.(s_ref);
        prob.Constraints.VargRef = Vref("Varg") == Varg_ref;
    end

    for i_br = 1:height(tab_branch)
        [prob, const, sct_var] = build_branch(tab_branch(i_br,:), prob, const, sct_var, s_method);
    end

    sv_const = fieldnames(const);
    for i = 1:numel(sv_const)
        s_con = sv_const{i};
        prob.Constraints.("balanced"+s_con) = const.(s_con) == 0;
    end

    prob = apply(prob, sct_options, tab_bus, tab_component, tab_branch, sct_var);
end
