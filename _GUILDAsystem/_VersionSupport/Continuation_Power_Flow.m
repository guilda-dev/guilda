function obj = Continuation_Power_Flow(net,opt)
% <@Desc>
% v3 entry point of the continuation power flow (deprecated: warns
% GUILDA:Deprecated:ContinuationPowerFlowFunction). Returns a ContinuationPowerFlowV3
% object that keeps the v3 usage:
%   cpf = Continuation_Power_Flow(net, struct("CPFBus", sv_bus));
%   [sol, sol_pred] = cpf.solve;      % runs net.calculate_continuation_powerflow
%   cpf.CPF_Result.x_sol              % full variable vector, lambda in the last row
% Use net.calculate_continuation_powerflow(LoadBus=sv_bus) instead.
% <@Role> Compatibility
% <@Summary> v3 wrapper of net.calculate_continuation_powerflow.
% <@Signatures>
% [
%   "cpf = Continuation_Power_Flow(net, opt)"
% ]
% <@Parameters>
% [
%   {"Name": "net", "Type": "PowerNetwork", "Description": "Network to analyse.", "Required": true, "Default": "-"},
%   {"Name": "opt", "Type": "struct", "Description": "v3 options: CPFBus, CPFInitLam, CPFMaxIter, CPFStepSize, CPFArcL, CPFUseInternal.", "Required": false, "Default": "struct()"}
% ]
% <@Returns>
% [
%   {"Name": "cpf", "Type": "ContinuationPowerFlowV3", "Description": "Object with the v3 properties, solve and CPF_Result."}
% ]
    arguments
        net
        opt (1,1) struct = struct()
    end
    Deprecated("ContinuationPowerFlowFunction");
    c_opt = namedargs2cell(opt);
    obj = ContinuationPowerFlowV3(net, c_opt{:});
end
