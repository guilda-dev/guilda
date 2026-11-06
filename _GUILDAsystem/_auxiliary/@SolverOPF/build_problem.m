function [prob, x0] = build_problem(obj, net, sct_options)
% Build the optimization problem of the optimal power flow of a network.
%
% Reads tab_parameter of the buses (operation, powerflow, dynamics), components
% (operation, OPF, powerflow) and branches (operation, dynamics) of net and builds the
% optimproblem for sct_options.Method; the network is only read. Called by
% net.build_opf_problem and SolverOPF.solve.
%
% - Variables: one per bus (Varg, V), component (P, Q) and branch end
%   ("<branch>_<bus>": P, Q, Ireal, Iimag flowing into the bus), named by tag.
% - Bounds from tab_parameter.operation; an infinite bound (NaN for the branch limits)
%   adds no limit. A load keeps the P (Q) of tab_parameter.powerflow while its
%   Pmin/Pmax (Qmin/Qmax) are both infinite.
% - Constraints: power balance balancedP_<bus> / balancedQ_<bus> (balancedP in "ELD"),
%   branch definitions defIre_, defIim_, defP_, defQ_ (<branch>_<bus>), limits Imax_,
%   Smax_, VargMax1_<branch>, VargMax2_<branch>, and VargRef (ReferenceBus).
% - Objective GenCost: HP*P^2 + fP*P + HQ*Q^2 + fQ*Q of every component (DefaultCost),
%   plus Cost(v, p).
% - Constraint(v, p) adds named constraints prob.Constraints.<name>.
% x0 starts from tab_parameter.powerflow Varg0, V0 of the buses and tab_parameter.OPF
% P0, Q0 of the components; the branch ends start at the flows of these voltages.
%
% <@Examples>
% ```matlab
% sct = net.solver_OPF.get_options({"Method", "DC OPF"});
% [prob, x0] = net.solver_OPF.build_problem(net, sct);
% ```
%
% See also PowerNetwork.build_opf_problem, SolverOPF.solve
    arguments (Input)
        obj                                          % Solver (net.solver_OPF).
        net                                          % Network whose problem is built; only read.
        sct_options (1,1) struct = obj.get_options() % Effective settings (output of get_options): Method, Cost, Constraint, DefaultCost, ReferenceBus.
    end
    arguments (Output)
        prob % optimproblem; its Description shows the OPF settings of the network.
        x0   % Initial point: struct of the values of every variable, by variable name.
    end
    s_method = sct_options.Method;

    prob = optimproblem("ObjectiveSense","minimize", ...
                        "Objective"     ,struct("GenCost",0), ...
                        "Description"   ,describe(net, s_method));
    x0      = struct();
    const   = struct();
    sct_var = struct();   % every optimization variable, by variable name
    if s_method == "ELD"
        const.P = 0;
    end

    a_Bus = net.a_Bus;
    for i_bus = 1:numel(a_Bus)
        bus = a_Bus{i_bus};
        [prob, x0, const, var] = build_bus(bus, prob, x0, const, s_method);
        if ~isempty(var)
            sct_var.(string(bus)) = var;
        end
        a_Com = bus.a_Component;
        for i_com = 1:numel(a_Com)
            [prob, x0, const, var] = build_component(a_Com{i_com}, prob, x0, const, s_method, sct_options.DefaultCost);
            sct_var.(string(a_Com{i_com})) = var;
        end
    end

    if s_method ~= "ELD"
        prob = add_reference(net, prob, sct_var, sct_options.ReferenceBus);
    end

    a_Branch = net.a_Branch;
    for i_br = 1:numel(a_Branch)
        [prob, x0, const, sct_var] = build_branch(a_Branch{i_br}, prob, x0, const, sct_var, s_method);
    end

    sv_const = fieldnames(const);
    for i = 1:numel(sv_const)
        s_con = sv_const{i};
        prob.Constraints.("balanced"+s_con) = const.(s_con) == 0;
    end

    prob = apply(net, prob, sct_options, sct_var);
end


function prob = add_reference(net, prob, sct_var, s_ref)
% Fix the angle of the reference bus to its power-flow Varg (0 if NaN): constraint VargRef.
% "auto": the bus of tools.slack_bus_index (the first bus if no bus has a component);
% "none": no fixed angle; otherwise the bus with that tag.
    a_Bus = net.a_Bus;
    switch s_ref
        case "none"
            return
        case "auto"
            i_ref = tools.slack_bus_index(net);
            if isempty(i_ref); i_ref = 1; end
        otherwise
            i_ref = find(string(a_Bus) == s_ref, 1);
            if isempty(i_ref)
                error(msg("GUILDA:SolverOPF:UnknownReferenceBus", s_ref))
            end
    end
    bus = a_Bus{i_ref};
    Varg_ref = bus.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", bus.a_Parameter)}.tab_parameter.Varg;
    if isnan(Varg_ref); Varg_ref = 0; end
    Vref = sct_var.(string(bus));
    prob.Constraints.VargRef = Vref("Varg") == Varg_ref;
end


function s_text = describe(net, s_method)
% Description of the problem: the OPF settings of the buses, components and branches.
    tab_OPF.Bus       = tools.vcellfun(@(b) b.tab_parameter, net.a_Bus);
    tab_OPF.Bus       = tab_OPF.Bus(:,["operation","powerflow"]);
    tab_OPF.Bus.Properties.RowNames = string(net.a_Bus);

    a_Com             = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
    tab_OPF.Component = tools.vcellfun(@(c) c.tab_parameter(:,["OPF","operation"]), a_Com);
    tab_OPF.Component.Properties.RowNames = string(a_Com);

    tab_OPF.Branch    = tools.vcellfun(@(b) b.tab_parameter, net.a_Branch);
    tab_OPF.Branch    = tab_OPF.Branch(:,"operation");
    tab_OPF.Branch.Properties.RowNames = string(net.a_Branch);

    s_text = newline+"Optimal Power Flow ("+s_method+")"+newline ...
             + string(repmat('=',1,100))+newline+newline;
    for s_tag = ["Bus","Component","Branch"]
        s_text = s_text ...
                 + "<<"+s_tag+" OPF setting>>"+newline ...
                 + formattedDisplayText(tab_OPF.(s_tag))+newline+newline;
    end
    s_text = s_text + "<<Network Topology>>"+newline ...
                    + net.disp_tree + newline ...
                    + string(repmat('=',1,100))+newline;
end
