function set_equilibrium(obj, c_V, c_I, r_P, r_Q, opt)
% Set the bus voltage and distribute P and Q of the equilibrium to the components.
%
% Called by PowerNetwork.initialize. The slack bus gives the remaining P to its first
% component whose Q is NaN; Q goes to the components whose Q is NaN, split by
% `QdistributionRule`. A slack bus without such components gives both to its first component.
% With `rm_PQ` the components take the given powers instead, and r_P and r_Q are not used.
%
% <@Group> Called by analyses
    arguments (Input)
        obj 
        c_V   % [pu] Bus voltage phasor.
        c_I   % [pu] Bus current injection phasor.
        r_P = real( c_V*conj(c_I) );   % [pu] Active power injection.
        r_Q = imag( c_V*conj(c_I) );   % [pu] Reactive power injection.
        opt.QdistributionRule (1,1) string {mustBeMember(opt.QdistributionRule,["baseMVA","Qmax"])} = "baseMVA";   % Split of Q: "baseMVA" (by rating) or "Qmax" (by the Q range).
        opt.rm_PQ double = [];   % [pu] [P Q] of each component, one row per component (e.g. the OPF solution). Default [] distributes r_P and r_Q from para_powerflow.
    end
    
    % The bus owns V. Its current is the sum of the component currents
    % (Dependent), so c_I is only used for the default r_P and r_Q.
    obj.c_Vequilibrium = c_V;

    a_Comp = obj.a_Component;
    n_Comp = numel(a_Comp);
    if isempty(opt.rm_PQ)
        tab_PQcomp = distribute_power(obj, r_P, r_Q, opt.QdistributionRule);
    else
        tab_PQcomp = array2table(opt.rm_PQ,"VariableNames",["P","Q"]);
    end

    % @Component set_equilibrium
    for i = 1:n_Comp
        rr_PQi = tab_PQcomp{i,["P","Q"]};
        r_Pi   = rr_PQi(1);
        r_Qi   = rr_PQi(2);
        c_Ii   = conj( rr_PQi*[1;1j] / c_V );
        a_Comp{i}.set_equilibrium(c_V,c_Ii,r_Pi,r_Qi);
    end
end


function tab_PQcomp = distribute_power(obj, r_P, r_Q, str_rule)
% P and Q of each component: para_powerflow, the slack remainder and the split of NaN Q
    a_Comp = obj.a_Component;
    n_Comp = numel(a_Comp);
    if isempty(a_Comp)
        tab_PQcomp = array2table(zeros(0,2),"VariableNames",["P","Q"]);
    else
        tab_PQcomp = tools.vcellfun(@(c) c.para_powerflow.tab_parameter, a_Comp);
    end

    % distrubute active power(P)
    if obj.l_isSlack && n_Comp > 0
        i_rest = find(isnan(tab_PQcomp.Q), 1);
        if isempty(i_rest)
            i_rest = 1;
        end
        lv_other = (1:n_Comp)' ~= i_rest;
        tab_PQcomp{i_rest,"P"} = r_P - sum(tab_PQcomp{lv_other,"P"});
    end

    % distribute reactive power(Q)
    lv_Qnan  = isnan(tab_PQcomp.Q);
    if obj.l_isSlack && n_Comp > 0 && ~any(lv_Qnan)
        tab_PQcomp{1,"Q"} = r_Q - sum(tab_PQcomp{2:end,"Q"});   % like P: the power flow ignores its setting
    end
    r_Qrest  = r_Q - sum(tab_PQcomp{~lv_Qnan,"Q"});
    if any(lv_Qnan)
        if sum(lv_Qnan) == 1
            tab_PQcomp{lv_Qnan,"Q"} = r_Qrest;
        else 
            tab_Ocomp = tools.vcellfun(@(c) c.para_operation.tab_parameter, a_Comp);
                rv_Qmin = tab_Ocomp{lv_Qnan,"Qmin"};
                rv_Qmax = tab_Ocomp{lv_Qnan,"Qmax"};
            if str_rule=="Qmax" && ~any( isinf([rv_Qmin,rv_Qmax]), "all")
                r_Qminall = sum(rv_Qmin);
                r_Qmaxall = sum(rv_Qmax); 
                rv_Qrate  = (rv_Qmax-rv_Qmin)/(r_Qmaxall-r_Qminall);
                tab_PQcomp{lv_Qnan,"Q"} = rv_Qmin + rv_Qrate * (r_Qrest-r_Qminall);
            else
                rv_Qrate = tab_Ocomp{lv_Qnan,"baseMVA"};
                tab_PQcomp{lv_Qnan,"Q"} = r_Qrest * rv_Qrate/sum(rv_Qrate);
            end
        end
    end
end
