function [prob, x0] = build_problem(obj, tab_bus, tab_component, tab_branch, sct_options)
% Build the optimization problem of the optimal power flow from the data of a network.
%
% Builds the optimproblem for sct_options.Method from the tables of the buses, components
% and branches that net.calculate_optimal_powerflow and net.build_opf_problem collect
% from tab_parameter (rows named by tag; see those methods); no network object is read.
% Called by net.build_opf_problem and SolverOPF.solve.
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
% x0 starts from the bus voltages of the flat start, or of the last solved "AC OPF" when
% sct_options.WarmStart is true and it was solved for the same bus tags (see SolverOPF),
% and P0, Q0 of the components; the branch ends start at the flows of these voltages.
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
        obj                          % Solver (net.solver_OPF); its warm start is read.
        tab_bus       table          % Buses: Vmin, Vmax, Gshunt, Bshunt, Type, V, Varg; row names = bus tags.
        tab_component table          % Components: Bus, HP, fP, HQ, fQ, P0, Q0, Pmin, Pmax, Qmin, Qmax; row names = tags.
        tab_branch    table          % Branches: From, To, Y (2x2 pages), X, tap, phase, Pmax, Qmax, Vargmax, Imax, Smax; row names = tags.
        sct_options   (1,1) struct   % Settings: Method, Cost, Constraint, DefaultCost, ReferenceBus (bus tag or "none"), base (baseMVA, Hz); WarmStart (absent: false).
    end
    arguments (Output)
        prob % optimproblem; its Description shows the OPF data of the buses, components and branches.
        x0   % Initial point: struct of the values of every variable, by variable name.
    end
    s_method = sct_options.Method;

    prob = optimproblem("ObjectiveSense","minimize", ...
                        "Objective"     ,struct("GenCost",0), ...
                        "Description"   ,describe(tab_bus, tab_component, tab_branch, s_method));
    x0      = struct();
    const   = struct();
    sct_var = struct();   % every optimization variable, by variable name
    if s_method == "ELD"
        const.P = 0;
    end

    sv_bus  = string(tab_bus.Properties.RowNames);
    sv_at   = tab_component.Bus;
    rm_init = initial_voltage(obj, tab_bus, isfield(sct_options, "WarmStart") && sct_options.WarmStart);
    for i_bus = 1:numel(sv_bus)
        [x0, const, var] = build_bus(tab_bus(i_bus,:), x0, const, s_method, rm_init(i_bus,:));
        if ~isempty(var)
            sct_var.(sv_bus(i_bus)) = var;
        end
        for i_com = reshape(find(sv_at == sv_bus(i_bus)), 1, [])
            [prob, x0, const, var] = build_component(tab_component(i_com,:), prob, x0, const, s_method, sct_options.DefaultCost);
            sct_var.(string(tab_component.Properties.RowNames{i_com})) = var;
        end
    end

    if s_method ~= "ELD"
        prob = add_reference(tab_bus, prob, sct_var, sct_options.ReferenceBus);
    end

    for i_br = 1:height(tab_branch)
        [prob, x0, const, sct_var] = build_branch(tab_branch(i_br,:), prob, x0, const, sct_var, s_method);
    end

    sv_const = fieldnames(const);
    for i = 1:numel(sv_const)
        s_con = sv_const{i};
        prob.Constraints.("balanced"+s_con) = const.(s_con) == 0;
    end

    prob = apply(prob, sct_options, tab_bus, tab_component, tab_branch, sct_var);
end


function prob = add_reference(tab_bus, prob, sct_var, s_ref)
% Fix the angle of the reference bus to its power-flow Varg (0 if NaN): constraint VargRef.
% "none": no fixed angle; otherwise the bus with that tag ("auto" is resolved by the caller).
    if s_ref == "none"
        return
    end
    i_ref = find(string(tab_bus.Properties.RowNames) == s_ref, 1);
    if isempty(i_ref)
        error(msg("GUILDA:SolverOPF:UnknownReferenceBus", s_ref))
    end
    Varg_ref = tab_bus.Varg(i_ref);
    if isnan(Varg_ref); Varg_ref = 0; end
    Vref = sct_var.(s_ref);
    prob.Constraints.VargRef = Vref("Varg") == Varg_ref;
end


function s_text = describe(tab_bus, tab_component, tab_branch, s_method)
% Description of the problem: the OPF data of the buses, components and branches.
    tab_OPF.Bus       = tab_bus;
    tab_OPF.Component = tab_component;
    tab_OPF.Branch    = removevars(tab_branch, "Y");

    s_text = newline+"Optimal Power Flow ("+s_method+")"+newline ...
             + string(repmat('=',1,100))+newline+newline;
    for s_tag = ["Bus","Component","Branch"]
        s_text = s_text ...
                 + "<<"+s_tag+" OPF setting>>"+newline ...
                 + formattedDisplayText(tab_OPF.(s_tag))+newline+newline;
    end
    s_text = s_text + string(repmat('=',1,100))+newline;
end


function rm_init = initial_voltage(obj, tab_bus, l_warm)
% [Varg, V] of each bus: the kept "AC OPF" solution (l_warm, same bus tags in the same
% order), or the flat start (angle 0 and magnitude 1, the set V at PV and slack buses and
% the set angle at the slack bus)
    sv_bus = string(tab_bus.Properties.RowNames);
    if l_warm && ~isempty(obj.sv_warmBus) && isequal(obj.sv_warmBus, sv_bus(:))
        rm_init = obj.rm_Vwarm;
        return
    end
    n_bus    = height(tab_bus);
    rm_init  = [zeros(n_bus,1), ones(n_bus,1)];
    lv_set   = tab_bus.Type ~= "PQ";
    lv_slack = tab_bus.Type == "slack";
    rm_init(lv_set, 2)   = tab_bus.V(lv_set);
    rm_init(lv_slack, 1) = tab_bus.Varg(lv_slack);
end
