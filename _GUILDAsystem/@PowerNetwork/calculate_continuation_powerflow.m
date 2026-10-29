function [result, flag, output] = calculate_continuation_powerflow(obj, varargin)
% <@Desc>
% Traces the PV curve of the network by the continuation power flow: starting from the
% equilibrium of net.initialize, the loads of LoadBus are scaled by (1 + lambda) and the
% power flow solution is followed past the maximum loading point (the nose). The
% settings are the stored defaults of net.solver_CPF; Name-Value options override them
% for this call only (net.solver_CPF is not changed).
% Accepted options are the names in ContinuationPowerFlow.OptionMap plus Plot and Export;
% any other name stops with GUILDA:resolve_options:UnknownName.
% It stops with an error naming the remedy when the network is not initialized (or was
% edited after net.initialize) and when LoadBus is empty or names an unknown bus.
% <@Role> Analysis
% <@Summary> Continuation power flow (PV curve); returns a CPFResult.
% <@Signatures>
% [
%   "result = net.calculate_continuation_powerflow(LoadBus=sv_bus)",
%   "[result, flag, output] = net.calculate_continuation_powerflow(Name, Value)"
% ]
% <@Parameters>
% [
%   {"Name": "LoadBus", "Type": "string", "Description": "Tags of the buses whose loads are scaled by (1 + lambda) (net.solver_CPF.LoadBus).", "Required": false, "Default": "net.solver_CPF.LoadBus"},
%   {"Name": "MaxIteration", "Type": "integer scalar", "Description": "Maximum number of predictor-corrector steps (net.solver_CPF.MaxIterations).", "Required": false, "Default": "net.solver_CPF.MaxIterations"},
%   {"Name": "Tolerance", "Type": "double scalar", "Description": "Convergence tolerance of the Newton-Raphson corrector (net.solver_CPF.Tolerance).", "Required": false, "Default": "net.solver_CPF.Tolerance"},
%   {"Name": "StepSize", "Type": "double scalar", "Description": "Step size of the predictor (net.solver_CPF.StepSize).", "Required": false, "Default": "net.solver_CPF.StepSize"},
%   {"Name": "ArcLength", "Type": "double scalar", "Description": "Arc length of the corrector (net.solver_CPF.ArcLength).", "Required": false, "Default": "net.solver_CPF.ArcLength"},
%   {"Name": "InitialLambda", "Type": "double scalar", "Description": "lambda at the starting point (net.solver_CPF.InitialLambda).", "Required": false, "Default": "net.solver_CPF.InitialLambda"},
%   {"Name": "UseInternalState", "Type": "logical scalar", "Description": "Solve with the internal states of the generators (net.solver_CPF.UseInternalState).", "Required": false, "Default": "net.solver_CPF.UseInternalState"},
%   {"Name": "Verbose", "Type": "logical scalar", "Description": "Print lambda at each step (net.solver_CPF.Verbose).", "Required": false, "Default": "net.solver_CPF.Verbose"},
%   {"Name": "Plot", "Type": "logical scalar", "Description": "Call result.Plot after the calculation.", "Required": false, "Default": "false"},
%   {"Name": "Export", "Type": "logical scalar or string scalar", "Description": "Call result.Export after the calculation: true for the default file name, or the file name.", "Required": false, "Default": "false"}
% ]
% <@Returns>
% [
%   {"Name": "result", "Type": "CPFResult", "Description": "lambda and bus voltages along the path, and the nose point."},
%   {"Name": "flag", "Type": "logical", "Description": "True when the path passed the nose."},
%   {"Name": "output", "Type": "struct", "Description": "Details: message, iterations, correctorIterations."}
% ]
% <@Examples>
% [
%   "```matlab\nnet.initialize();\n[res, flag] = net.calculate_continuation_powerflow(LoadBus=[\"B009\",\"B010\"]);\nres.r_lambdaMax          % maximum loading\nres.Plot();              % PV curves of the load buses\n```"
% ]

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
