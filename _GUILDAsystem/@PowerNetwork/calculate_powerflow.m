function [tab_PFsol, flag, output] = calculate_powerflow(obj,mode,opt)
% <@Desc>
% Runs the power flow calculation for the network and returns bus voltage and current solutions.
% <@Role>
% Power Flow
% <@Abst>
% Solves the power flow equations using either the algebraic or dynamic method.
% <@Signatures>
% [
%   "[tab_PFsol, flag, output] = net.calculate_powerflow()",
%   "[tab_PFsol, flag, output] = net.calculate_powerflow(\"algebraic\")",
%   "[tab_PFsol, flag, output] = net.calculate_powerflow(\"dynamic\")"
% ]
% <@varargin>
% [
%   {
%     "Name": "mode",
%     "Type": "string scalar",
%     "Description": "Solution method: \"algebraic\" (Newton-Raphson) or \"dynamic\" (transient simulation).",
%     "Required": false,
%     "Default": "\"algebraic\""
%   }
% ]
% <@varargout>
% [
%   {
%     "Name": "tab_PFsol",
%     "Type": "table",
%     "Description": "Power flow solution table with Vphasor, Iphasor, P, Q for each bus."
%   },
%   {
%     "Name": "flag",
%     "Type": "logical",
%     "Description": "True if the power flow converged successfully."
%   },
%   {
%     "Name": "output",
%     "Type": "struct",
%     "Description": "Solver output information struct."
%   }
% ]
% <@Examples>
% [
%   "```matlab\n[tab, flag] = net.calculate_powerflow();\n```"
% ]
    arguments
        obj
        mode    (1,1) string {mustBeMember(mode,["algebraic","dynamic"])} = "algebraic"
        opt.export  (1,1) logical = mode=="dynamic";
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