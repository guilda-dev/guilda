function [tab_PFsol, flag, output] = calculate_powerflow(obj,mode,opt)
    arguments
        obj
        mode    (1,1) string {mustBeMember(mode,["algebraic","dynamic","geodetic"])} = "algebraic"
        opt.export  (1,1) logical = ismember(mode,["dynamic","geodetic"]);
        opt.filename(1,1) string  = string(datetime("now","Format","uuMMdd_HHmmss"))+"_PFcalculation.json"
    end

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

    opt = namedargs2cell(opt);
    [tab_PFsol,flag,output] = obj.solver_PF.solve(obj,mode,opt{:});
end