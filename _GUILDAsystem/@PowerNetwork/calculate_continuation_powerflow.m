function [result, flag, output] = calculate_continuation_powerflow(obj, varargin)
% Trace the PV curve by the continuation power flow and return a CPFResult.
%
% Traces the PV curve of the network by the continuation power flow: starting from the
% equilibrium of net.initialize, the loads of LoadBus are scaled by (1 + lambda) and the
% power flow solution is followed past the maximum loading point (the nose). The
% settings are the stored defaults of net.solver_CPF; Name-Value options override them
% for this call only (net.solver_CPF is not changed).
% Accepted options are the names in ContinuationPowerFlow.OptionMap plus Plot and Export;
% any other name stops with GUILDA:resolve_options:UnknownName.
% It stops with an error naming the remedy when the network is not initialized (or was
% edited after net.initialize) and when LoadBus is empty or names an unknown bus.
%
% Name-Value options:
%
% - `LoadBus` — Tags of the buses whose loads are scaled by (1 + lambda) (net.solver_CPF.LoadBus).
% - `MaxIteration` — Maximum number of predictor-corrector steps (net.solver_CPF.MaxIterations).
% - `Tolerance` — Convergence tolerance of the Newton-Raphson corrector (net.solver_CPF.Tolerance).
% - `StepSize` — Step size of the predictor (net.solver_CPF.StepSize).
% - `ArcLength` — Arc length of the corrector (net.solver_CPF.ArcLength).
% - `InitialLambda` — lambda at the starting point (net.solver_CPF.InitialLambda).
% - `UseInternalState` — Solve with the internal states of the generators (net.solver_CPF.UseInternalState).
% - `Verbose` — Print lambda at each step (net.solver_CPF.Verbose).
% - `Plot` — Call result.Plot after the calculation. Default: false.
% - `Export` — Call result.Export after the calculation: true for the default file name, or the file name. Default: false.
%
% <@Examples>
% ```matlab
% net.initialize();
% [res, flag] = net.calculate_continuation_powerflow(LoadBus=["B009","B010"]);
% res.r_lambdaMax          % maximum loading
% res.Plot();              % PV curves of the load buses
% ```
%
% See also CPFResult, ContinuationPowerFlow
    arguments (Output)
        result   % lambda and bus voltages along the path, and the nose point.
        flag     % True when the path passed the nose.
        output   % Details: message, iterations, correctorIterations.
    end

    [c_nv, opt] = take_call_options(varargin);
    s_options   = obj.solver_CPF.get_options(c_nv);

    [result, flag, output] = obj.solver_CPF.solve(obj, s_options);

    if opt.Plot
        result.Plot();
    end
    if isstring(opt.Export)
        result.Export(opt.Export);
    elseif opt.Export
        result.Export();
    end
end


function [c_nv, opt] = take_call_options(c_in)
% Separates the options of this call (Plot, Export) from the solver options
    c_nv = c_in;
    opt  = call_options();
    if mod(numel(c_in), 2) ~= 0
        return              % not Name-Value pairs: tools.resolve_options reports it
    end
    lv_call = false(size(c_in));
    for k = 1:2:numel(c_in)
        lv_call(k:k+1) = (ischar(c_in{k}) || isstring(c_in{k})) && any(strcmpi(c_in{k}, ["Plot","Export"]));
    end
    c_call = c_in(lv_call);
    c_nv   = c_in(~lv_call);
    opt    = call_options(c_call{:});
end

function opt = call_options(opt)
    arguments
        opt.Plot   (1,1) logical = false
        opt.Export {mustBeA(opt.Export, ["logical","string","char"])} = false
    end
    if ischar(opt.Export)
        opt.Export = string(opt.Export);
    end
    mustBeScalarOrEmpty(opt.Export);
end
