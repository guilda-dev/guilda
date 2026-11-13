function rm_PQ = distribute_power(bus, r_P, r_Q, s_rule, l_slack)
% Return P and Q of each component of a bus for the bus injection r_P + j r_Q.
%
% Each component starts from P, Q of its tab_parameter.powerflow. The slack bus gives the
% remaining P to its first component whose Q is NaN (its first component when none);
% when no Q is NaN, its first component also takes the remaining Q. The remaining Q goes to
% the components whose Q is NaN: all of it to a single one, else split by s_rule:
% "baseMVA" in proportion to operation.baseMVA, "Qmax" in proportion to the range
% operation.Qmax - Qmin, starting from Qmin ("baseMVA" when a Qmin or Qmax is infinite).
% The bus can also be a bus struct of a network snapshot (struct(net, false)), as
% ResultPF uses it. l_slack treats the bus as the slack bus (default: its l_isSlack), for
% a slack bus that net.get_pf_condition selected without writing l_isSlack.
%
% <@Examples>
% ```matlab
% bus   = network.IEEE9bus().a_Bus{1};
% rm_PQ = tools.distribute_power(bus, 0.7, 0.3, "baseMVA");
% ```
%
% See also Bus.set_equilibrium, ResultPF
    arguments (Input)
        bus                % Bus whose components get the powers (only read), or a bus of a network snapshot (struct(net, false)).
        r_P   (1,1) double % [pu] Active power injection of the bus.
        r_Q   (1,1) double % [pu] Reactive power injection of the bus.
        s_rule (1,1) string {mustBeMember(s_rule,["baseMVA","Qmax"])} = "baseMVA" % Split of the remaining Q among the components with Q = NaN.
        l_slack (1,1) logical = bus.l_isSlack % Give the remaining P (and Q) as at the slack bus.
    end
    arguments (Output)
        rm_PQ double       % [pu] [P Q] of each component, one row per component (bus.a_Component order); 0x2 without components.
    end
    a_Comp = bus.a_Component;
    n_Comp = numel(a_Comp);
    if n_Comp == 0
        rm_PQ = zeros(0,2);
        return
    end
    tab_PQ = tools.vcellfun(@(c) group(c, "powerflow"), a_Comp);
    rm_PQ  = [tab_PQ.P, tab_PQ.Q];

    % active power: the slack remainder
    if l_slack
        i_rest = find(isnan(rm_PQ(:,2)), 1);
        if isempty(i_rest)
            i_rest = 1;
        end
        lv_other = (1:n_Comp)' ~= i_rest;
        rm_PQ(i_rest,1) = r_P - sum(rm_PQ(lv_other,1));
    end

    % reactive power
    lv_Qnan = isnan(rm_PQ(:,2));
    if l_slack && ~any(lv_Qnan)
        rm_PQ(1,2) = r_Q - sum(rm_PQ(2:end,2));   % like P: the power flow ignores its setting
    end
    r_Qrest = r_Q - sum(rm_PQ(~lv_Qnan,2));
    if sum(lv_Qnan) == 1
        rm_PQ(lv_Qnan,2) = r_Qrest;
    elseif any(lv_Qnan)
        tab_O   = tools.vcellfun(@(c) group(c, "operation"), a_Comp);
        rv_Qmin = tab_O.Qmin(lv_Qnan);
        rv_Qmax = tab_O.Qmax(lv_Qnan);
        if s_rule == "Qmax" && ~any(isinf([rv_Qmin, rv_Qmax]), "all")
            r_Qminall = sum(rv_Qmin);
            r_Qmaxall = sum(rv_Qmax);
            rv_Qrate  = (rv_Qmax - rv_Qmin) / (r_Qmaxall - r_Qminall);
            rm_PQ(lv_Qnan,2) = rv_Qmin + rv_Qrate * (r_Qrest - r_Qminall);
        else
            rv_Qrate = tab_O.baseMVA(lv_Qnan);
            rm_PQ(lv_Qnan,2) = r_Qrest * rv_Qrate / sum(rv_Qrate);
        end
    end
end


function tab = group(obj, s_group)
% tab_parameter of the parameter group s_group of obj (a model or its struct snapshot)
    if isstruct(obj)
        tab = obj.tab_parameter.(s_group);
        return
    end
    tab = obj.a_Parameter{cellfun(@(p) p.s_tag==s_group, obj.a_Parameter)}.tab_parameter;
end
