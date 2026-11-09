function tab_PFcondition = get_pf_condition(obj)
% Return the power-flow condition of the bus.
%
% The bus type is "slack" for the slack bus, "PV" when the summed Q of its components
% is NaN and "PQ" otherwise. P and Q are the sums over the components.
%
% See also Bus.s_bustype, PowerNetwork.calculate_powerflow
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    arguments (Output)
        tab_PFcondition   % One-row table: Type, Varg, V, P, Q (NaN where the type does not set the value).
    end

    tab_V = obj.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", obj.a_Parameter)}.tab_parameter;
    a_com = obj.a_Component;
    if obj.l_isSlack
        Type     = "slack";
        rr_PFcondition = [tab_V.Varg,tab_V.V,nan(1,2)];
    else
        P = 0;
        Q = 0;
        for i = 1:numel(a_com)
            para_PQ = a_com{i}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", a_com{i}.a_Parameter)}.tab_parameter;
            P = P+para_PQ.P;
            Q = Q+para_PQ.Q;
        end
        if isnan(Q)
            Type     = "PV";
            rr_PFcondition = [ nan, tab_V.V, P, nan];
        else
            Type     = "PQ";
            rr_PFcondition = [ nan,     nan, P,   Q];
        end
    end
    tab_PFcondition = [table(Type), array2table(rr_PFcondition,"VariableNames",["Varg","V","P","Q"])];
    tab_PFcondition.Properties.RowNames = string(obj);
end
