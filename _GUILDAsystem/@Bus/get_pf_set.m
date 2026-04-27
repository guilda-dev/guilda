function tab_PFset = get_pf_set(obj)
% <@Desc>
% Returns the power flow settings for this bus (bus type, voltage, and P/Q values).
% <@Role>
% Power Flow
% <@Abst>
% Determines bus type (slack/PV/PQ) and collects power flow settings from the bus and its components.
% <@Signatures>
% [
%   "tab_PFset = bus.get_pf_set()"
% ]
% <@varargout>
% [
%   {
%     "Name": "tab_PFset",
%     "Type": "table",
%     "Description": "Table with columns Type, Varg, V, P, Q for the bus power flow settings."
%   }
% ]
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
