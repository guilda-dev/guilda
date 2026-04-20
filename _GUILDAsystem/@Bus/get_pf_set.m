function tab_PFset = get_pf_set(obj)
% get the settings for power-flow calculations

    tab_V = obj.para_powerflow;
    a_com = obj.a_Component;
    if obj.l_isSlack
        Type     = "slack";
        rr_PFset = [tab_V.Varg,tab_V.V,nan(1,2)];
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
            rr_PFset = [ nan, tab_V.V, P, nan];
        else
            Type     = "PQ";
            rr_PFset = [ nan,     nan, P,   Q];
        end
    end
    tab_PFset = [table(Type), array2table(rr_PFset,"VariableNames",["Varg","V","P","Q"])];
    tab_PFset.Properties.RowNames = string(obj);
end
