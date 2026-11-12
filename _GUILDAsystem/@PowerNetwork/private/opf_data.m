function [tab_bus, tab_component, tab_branch, sct_base, s_refBus] = opf_data(net, s_ref)
% Collect the data of the optimal power flow from tab_parameter of the network.
%
% Used by calculate_optimal_powerflow and build_opf_problem: SolverOPF builds the problem
% from these tables only and never reads the network. Every table has the tags as row
% names, in the order of net.a_Bus (components bus by bus) and net.a_Branch.
%
% - tab_bus: Vmin, Vmax (operation), Gshunt, Bshunt (dynamics), Type ("slack", "PV" or
%   "PQ", Bus.get_pf_condition), V, Varg (powerflow: the set values of the start and of
%   the reference angle).
% - tab_component: Bus (tag of its bus), HP, fP, HQ, fQ, P0, Q0 (OPF), Pmin, Pmax, Qmin,
%   Qmax (operation). A load whose Pmin/Pmax (Qmin/Qmax) are both infinite keeps its P
%   (Q) of tab_parameter.powerflow: both bounds and the start are set to it here.
% - tab_branch: From, To (bus tags: a_Bus{1}, a_Bus{2}), Y (2x2 admittance matrix
%   [pu], one page per row), X, tap, phase (dynamics, for "DC OPF"; tap 1 and phase 0
%   when absent, NaN or a zero tap), Pmax, Qmax, Vargmax, Imax, Smax (operation).
% - sct_base: the base parameters of the network (baseMVA, Hz), p.base of Cost and
%   Constraint.
% - s_refBus: the ReferenceBus option s_ref, with "auto" resolved to the tag of the bus of
%   tools.slack_bus_index (else the first bus); a tag or "none" is returned as it is.
    arguments (Input)
        net                     % Network; only read.
        s_ref (1,1) string = "auto" % ReferenceBus option.
    end
    arguments (Output)
        tab_bus table           % Data of the buses.
        tab_component table     % Data of the components.
        tab_branch table        % Data of the branches.
        sct_base struct         % baseMVA, Hz of the network.
        s_refBus (1,1) string   % Tag of the reference bus, or "none" (unknown tags are checked by SolverOPF).
    end
    a_Bus  = reshape(net.a_Bus, [], 1);
    sv_bus = reshape(string(a_Bus), [], 1);

    % buses
    n_bus  = numel(a_Bus);
    rm_bus = nan(n_bus, 6);
    sv_type = strings(n_bus, 1);
    for i = 1:n_bus
        bus = a_Bus{i};
        ope = group(bus, "operation");
        dyn = group(bus, "dynamics");
        pf  = group(bus, "powerflow");
        rm_bus(i,:) = [ope.Vmin, ope.Vmax, dyn.Gshunt, dyn.Bshunt, pf.V, pf.Varg];
        sv_type(i)  = bus.get_pf_condition().Type;
    end
    tab_bus = [array2table(rm_bus(:,1:4), "VariableNames", ["Vmin","Vmax","Gshunt","Bshunt"]), ...
               table(sv_type, 'VariableNames', "Type"), ...
               array2table(rm_bus(:,5:6), "VariableNames", ["V","Varg"])];
    tab_bus.Properties.RowNames = sv_bus;

    % components, bus by bus
    a_Com   = cell(0,1);
    sv_at   = strings(0,1);
    for i = 1:n_bus
        a_c   = reshape(a_Bus{i}.a_Component, [], 1);
        a_Com = [a_Com; a_c];                                   %#ok<AGROW>
        sv_at = [sv_at; repmat(sv_bus(i), numel(a_c), 1)];      %#ok<AGROW>
    end
    n_com  = numel(a_Com);
    rm_com = nan(n_com, 10);
    for k = 1:n_com
        com = a_Com{k};
        opf = group(com, "OPF");
        ope = group(com, "operation");
        lb  = [ope.Pmin; ope.Qmin];
        ub  = [ope.Pmax; ope.Qmax];
        PQ0 = [opf.P0; opf.Q0];
        if isa(com, "component.load.abstract")
            pf = group(com, "powerflow");
            PQ = [pf.P; pf.Q];
            lv_fix = ~isnan(PQ) & isinf(lb) & isinf(ub);
            lb(lv_fix)  = PQ(lv_fix);
            ub(lv_fix)  = PQ(lv_fix);
            PQ0(lv_fix) = PQ(lv_fix);
        end
        rm_com(k,:) = [opf.HP, opf.fP, opf.HQ, opf.fQ, PQ0(1), PQ0(2), lb(1), ub(1), lb(2), ub(2)];
    end
    tab_component = [table(sv_at, 'VariableNames', "Bus"), ...
                     array2table(rm_com, "VariableNames", ["HP","fP","HQ","fQ","P0","Q0","Pmin","Pmax","Qmin","Qmax"])];
    tab_component.Properties.RowNames = reshape(string(a_Com), [], 1);

    % branches
    a_Branch = reshape(net.a_Branch, [], 1);
    n_br   = numel(a_Branch);
    sm_end = strings(n_br, 2);
    am_Y   = complex(zeros(n_br, 2, 2));
    rm_br  = nan(n_br, 8);
    for k = 1:n_br
        br  = a_Branch{k};
        sm_end(k,:) = reshape(string(br.a_Bus), 1, 2);
        am_Y(k,:,:) = reshape(br.get_admittance_matrix, 1, 2, 2);
        ope = group(br, "operation");
        rm_br(k,:)  = [dc_parameters(group(br, "dynamics")), ope.Pmax, ope.Qmax, ope.Vargmax, ope.Imax, ope.Smax];
    end
    tab_branch = [table(sm_end(:,1), sm_end(:,2), am_Y, 'VariableNames', ["From","To","Y"]), ...
                  array2table(rm_br, "VariableNames", ["X","tap","phase","Pmax","Qmax","Vargmax","Imax","Smax"])];
    tab_branch.Properties.RowNames = reshape(string(a_Branch), [], 1);

    sct_base = table2struct(group(net, "base"));
    s_refBus = reference_bus(net, sv_bus, s_ref);
end


function s_ref = reference_bus(net, sv_bus, s_ref)
% "auto": the bus of tools.slack_bus_index, else the first bus ("none" without buses)
    if s_ref ~= "auto"
        return
    end
    i_ref = tools.slack_bus_index(net);
    if isempty(i_ref)
        i_ref = 1;
    end
    if isempty(sv_bus)
        s_ref = "none";
    else
        s_ref = sv_bus(i_ref);
    end
end


function rv = dc_parameters(para)
% [X, tap, phase] as in MATPOWER: tap = 1 for lines (or NaN, 0), phase = 0 for lines (or NaN)
    s = table2struct(para);
    rv = [NaN, 1, 0];
    if isfield(s, "X")
        rv(1) = s.X;
    end
    if isfield(s, "tap") && ~isnan(s.tap) && s.tap ~= 0
        rv(2) = s.tap;
    end
    if isfield(s, "phase") && ~isnan(s.phase)
        rv(3) = s.phase;
    end
end


function tab = group(obj, s_group)
% tab_parameter of one group (container) of obj
    tab = obj.a_Parameter{cellfun(@(p) p.s_tag==s_group, obj.a_Parameter)}.tab_parameter;
end
