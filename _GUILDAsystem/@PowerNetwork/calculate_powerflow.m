function [tab_PFsol, flag, output] = calculate_powerflow(obj)

    lv_isSlack = tools.vcellfun(@(b) b.l_isSlack, obj.a_Bus);
    if ~any(lv_isSlack)
        try
            disp("INFO: Slack bus not found. Setting the first bus '"+string(obj.a_Bus{1})+"' as the slack bus.")
            obj.a_Bus{1}.l_isSlack = true;
        catch
            error("ERROR: Failed to set BUS001 as the slack bus."+newline+...
                  "       Please designate one Bus class as the slack bus from those that have at least one connected Component class."+newline+...
                  "       To specify the slack bus, set the 'l_isSlack' property of the designated Bus class to true.")
        end
    end

    tab_Ymat  = obj.get_admittance_matrix;
    tab_PFset = tools.vcellfun(@(b) b.get_pf_set, obj.a_Bus);
    str_Bus   = tab_PFset.Properties.RowNames;
    rm_Ymat   = tab_Ymat{str_Bus,str_Bus};

    [tab_PFsol,flag,output] = obj.solver_PF.solve( tab_PFset, rm_Ymat);
end