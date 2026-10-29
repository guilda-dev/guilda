function v3_cpf_constructor(c_args)
% <@Desc>
% v3 compatibility hook of the ContinuationPowerFlow constructor. In v3,
% ContinuationPowerFlow(net, Name, Value) built a solver that held the network and its
% result; in v4 the solver holds defaults only and is created as ContinuationPowerFlow().
% Any argument stops with GUILDA:Deprecated:ContinuationPowerFlowConstructor, which names
% net.calculate_continuation_powerflow and the wrapper Continuation_Power_Flow(net, opt).
% <@Role> Compatibility
% <@Summary> Reject the v3 constructor arguments of ContinuationPowerFlow.
% <@Signatures>
% [
%   "v3_cpf_constructor(c_args)"
% ]
% <@Parameters>
% [
%   {"Name": "c_args", "Type": "cell row", "Description": "varargin of the constructor.", "Required": true, "Default": "-"}
% ]
    if ~isempty(c_args)
        error('GUILDA:Deprecated:ContinuationPowerFlowConstructor', '%s', ...
              Deprecated("ContinuationPowerFlowConstructor"));
    end
end
