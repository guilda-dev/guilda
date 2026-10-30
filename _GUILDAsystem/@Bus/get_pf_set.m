function tab_PFset = get_pf_set(obj)
% Return the power-flow settings of the bus.
%
% The bus type is "slack" for the slack bus, "PV" when the summed Q of its components
% is NaN and "PQ" otherwise. P and Q are the sums over the components.
%
% See also Bus.str_bustype, PowerNetwork.calculate_powerflow
    arguments (Output)
        tab_PFset   % One-row table: Type, Varg, V, P, Q, Varg0, V0 (NaN where the type does not set the value).
    end

    tab_V = obj.para_powerflow;
    a_com = obj.a_Component;
    if obj.l_isSlack
        Type     = "slack";
        rr_PFset = [tab_V.Varg,tab_V.V,nan(1,2),  tab_V.Varg, tab_V.V];
    else
        P = 0;
        Q = 0;
        for i = 1:numel(a_com)
            para_PQ = a_com{i}.para_powerflow;
            P = P+para_PQ.P;
            Q = Q+para_PQ.Q;
        end
        if isnan(Q)
            Type     = "PV";
            rr_PFset = [ nan, tab_V.V, P, nan, tab_V.Varg0, tab_V.V0];
        else
            Type     = "PQ";
            rr_PFset = [ nan,     nan, P,   Q, tab_V.Varg0, tab_V.V0];
        end
    end
    tab_PFset = [table(Type), array2table(rr_PFset,"VariableNames",["Varg","V","P","Q","Varg0","V0"])];
    tab_PFset.Properties.RowNames = string(obj);
end
