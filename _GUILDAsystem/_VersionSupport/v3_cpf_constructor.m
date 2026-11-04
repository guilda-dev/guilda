function v3_cpf_constructor(c_args)
% Reject the v3 constructor arguments of SolverCPF.
%
% v3 compatibility hook of the SolverCPF constructor. In v3,
% ContinuationPowerFlow(net, Name, Value) built a solver that held the network and its
% result; in v4 the solver holds defaults only and is created as SolverCPF().
% Any argument stops with GUILDA:v3_cpf_constructor:ContinuationPowerFlowConstructor, which names
% net.calculate_continuation_powerflow and the wrapper Continuation_Power_Flow(net, opt).
%
% Name-Value options:
%
% - `c_args` — varargin of the constructor.
%
% See also SolverCPF
    if ~isempty(c_args)
        error(msg("GUILDA:v3_cpf_constructor:ContinuationPowerFlowConstructor"));
    end
end
