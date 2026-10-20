function [flag,tab_PFsol,output] = initialize(obj, options)
% <@Desc>
% Initializes the steady-state operating point of the power network.
% Runs the selected power flow method and sets equilibrium values for all buses and components.
% <@Role>
% Steady State
% <@Abst>
% Executes power flow calculation or OPF, distributes results to bus/component equilibria.
% <@Signatures>
% [
%   "[flag, tab_PFsol, output] = net.initialize()",
%   "[flag, tab_PFsol, output] = net.initialize(methods=\"powerflow calculation\")"
% ]
% <@varargin>
% [
%   {
%     "Name": "methods",
%     "Type": "string scalar",
%     "Description": "Method to use for initialization: \"powerflow calculation\", \"optimal powerflow\", or \"calculate from Xequilibrium\".",
%     "Required": false,
%     "Default": "\"powerflow calculation\""
%   }
% ]
% <@varargout>
% [
%   {
%     "Name": "flag",
%     "Type": "logical",
%     "Description": "True if the initialization converged successfully."
%   },
%   {
%     "Name": "tab_PFsol",
%     "Type": "table",
%     "Description": "Power flow solution table with bus voltage, current, P, and Q."
%   },
%   {
%     "Name": "output",
%     "Type": "struct",
%     "Description": "Solver output information struct."
%   }
% ]
% <@Examples>
% [
%   "```matlab\n[flag, tab] = net.initialize();\n```",
%   "```matlab\n[flag, tab] = net.initialize(methods=\"optimal powerflow\");\n```"
% ]
    arguments
        obj
        options.methods (1,1) string {mustBeMember(options.methods,["powerflow calculation","optimal powerflow","calculate from Xequilibrium"])} = "powerflow calculation"
    end

    % Steady-State Power Flow Calculation
    switch options.methods
        case "powerflow calculation"
            [tab_PFsol, output, flag] = obj.calculate_powerflow;
        case "optimal powerflow"
            [tab_PFsol, output, flag] = optimize_powerflow(obj,"methods","AC OPF");
    end
    

    % distribute Qcomponent
    for i_bus = 1:numel(obj.a_Bus)
        rr_PFsol = tab_PFsol{i_bus,["Vphasor","Iphasor","P","Q"]};
        c_Vbus = rr_PFsol(1);
        c_Ibus = rr_PFsol(2);
        r_Pbus = rr_PFsol(3);
        r_Qbus = rr_PFsol(4);
        obj.a_Bus{i_bus}.set_equilibrium(c_Vbus,c_Ibus,r_Pbus,r_Qbus)
    end

    obj.str_methodPF = options.methods;
    obj.reset_odeset;
    obj.reset_edit()
end