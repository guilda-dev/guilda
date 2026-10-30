function obj = Continuation_Power_Flow(net,opt)
% Run the v3 continuation power flow through a ContinuationPowerFlowV3 object.
%
% v3 entry point of the continuation power flow (deprecated: warns
% GUILDA:Deprecated:ContinuationPowerFlowFunction). Returns a ContinuationPowerFlowV3
% object that keeps the v3 usage:
%   cpf = Continuation_Power_Flow(net, struct("CPFBus", sv_bus));
%   [sol, sol_pred] = cpf.solve;      % runs net.calculate_continuation_powerflow
%   cpf.CPF_Result.x_sol              % full variable vector, lambda in the last row
%
% <@Deprecated>
% Use net.calculate_continuation_powerflow(LoadBus=sv_bus) instead.
%
% See also PowerNetwork.calculate_continuation_powerflow, ContinuationPowerFlowV3
    arguments
        net   % Network to analyse.
        opt (1,1) struct = struct()   % v3 options: CPFBus, CPFInitLam, CPFMaxIter, CPFStepSize, CPFArcL, CPFUseInternal.
    end
    arguments (Output)
        obj   % ContinuationPowerFlowV3 object with the v3 properties, solve and CPF_Result.
    end
    Deprecated("ContinuationPowerFlowFunction");
    c_opt = namedargs2cell(opt);
    obj = ContinuationPowerFlowV3(net, c_opt{:});
end
