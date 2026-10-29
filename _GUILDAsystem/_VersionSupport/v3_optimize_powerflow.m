function c_old = v3_optimize_powerflow(result, flag, output)
% <@Desc>
% Old (v3) outputs of PowerNetwork.optimize_powerflow, made from the v4 outputs:
%   [powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob]
% optimize_powerflow returns them through legacy_output when called with 6 outputs
% (GUILDA:Deprecated:OptimizePowerflowTuple).
% <@Role> Compatibility
% <@Summary> Convert an OPFResult into the old output tuple of optimize_powerflow.
% <@Signatures>
% [
%   "c_old = v3_optimize_powerflow(result, flag, output)"
% ]
% <@Parameters>
% [
%   {"Name": "result", "Type": "OPFResult", "Description": "Result of optimize_powerflow.", "Required": true, "Default": "-"},
%   {"Name": "flag", "Type": "optim.problemdef.ExitFlag", "Description": "exitflag of solve.", "Required": true, "Default": "-"},
%   {"Name": "output", "Type": "struct", "Description": "Solver details.", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "c_old", "Type": "cell row", "Description": "{powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob}"}
% ]
    c_old = {result.tab_bus, result.tab_cub, flag, output, result.lambda, result.OPFprob};
end
