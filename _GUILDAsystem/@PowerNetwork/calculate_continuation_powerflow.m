function [result, flag, output] = calculate_continuation_powerflow(obj, varargin)
% Trace the PV curve by the continuation power flow and return a ResultCPF.
%
% Traces the PV curve of the network by the continuation power flow: starting from the
% equilibrium of net.initialize, the loads of LoadBus are scaled by (1 + lambda) and the
% power flow solution is followed past the maximum loading point (the nose). The
% settings are the ContinuationPowerFlow section of GUILDA.setting, and the condition
% LoadBus is kept by net.solver_CPF; Name-Value options override them for this call only
% (neither net.solver_CPF nor the settings file is changed).
% Accepted options are the names in SolverCPF.OptionMap plus Export;
% any other name stops with GUILDA:resolve_options:UnknownName.
% It stops with an error naming the remedy when the network is not initialized (or was
% edited after net.initialize) and when LoadBus is empty or names an unknown bus.
%
% Name-Value options:
%
% - `LoadBus` — Tags of the buses whose loads are scaled by (1 + lambda) (net.solver_CPF.LoadBus).
% - `MaxIteration` — Maximum number of predictor-corrector steps Default: GUILDA.setting (500).
% - `Tolerance` — Convergence tolerance of the Newton-Raphson corrector. Default: GUILDA.setting (1e-5).
% - `StepSize` — Step size of the predictor. Default: GUILDA.setting (0.5).
% - `ArcLength` — Arc length of the corrector. Default: GUILDA.setting (1e-3).
% - `InitialLambda` — lambda at the starting point. Default: GUILDA.setting (0).
% - `UseInternalState` — Solve with the internal states of the generators. Default: GUILDA.setting (false).
% - `Verbose` — Print lambda at each step. Default: GUILDA.setting (false).
% - `Limits` — Operating limits applied along the path: a subset of "Q" (PV to PQ at the Q limits of the generators), "V" (stop at Vmin/Vmax of a bus), "S" (stop at Smax of a branch), or "all" / "none". Default: GUILDA.setting ("none"). See ResultCPF.tab_switch and tab_stop.
% - `PlotFcn` — Live display during the calculation: "pvcurve" draws |V| of every bus against lambda and extends the lines at each step; a function handle is called at the starting point and each step as stop = f(x, optimValues, state) (x the complex bus voltages; optimValues.iteration, .lambda, .correctorIterations; state "init", "iter", "done"), and a true stop ends the path there; "none" draws nothing. The PV curves after the calculation: result.Plot(). Default: GUILDA.setting ("none").
% - `Export` — Call result.export after the calculation: true for the default file name, or the file name. Default: false.
%
% <@Examples>
% ```matlab
% net.initialize();
% [res, flag] = net.calculate_continuation_powerflow(LoadBus=["B009","B010"]);
% res.r_lambdaMax          % maximum loading
% res.Plot();              % PV curves of the load buses
% ```
%
% See also ResultCPF, SolverCPF
%
% <@Group> CPF
    arguments (Input)
        obj
    end
    arguments (Input, Repeating)
        varargin   % Name-Value options.
    end
    arguments (Output)
        result   % lambda and bus voltages along the path, and the nose point.
        flag     % True when the path passed the nose.
        output   % Details: message, iterations, correctorIterations.
    end

    [c_nv, opt] = take_call_options(varargin);
    sct_options = obj.solver_CPF.get_options(c_nv);

    [result, flag, output] = obj.solver_CPF.solve(obj, sct_options);

    if isstring(opt.Export)
        result.export(opt.Export);
    elseif opt.Export
        result.export();
    end
end


function [c_nv, opt] = take_call_options(c_in)
% Separates the option of this call (Export) from the solver options
    c_nv = c_in;
    opt  = call_options();
    if mod(numel(c_in), 2) ~= 0
        return              % not Name-Value pairs: tools.resolve_options reports it
    end
    lv_call = false(size(c_in));
    for k = 1:2:numel(c_in)
        lv_call(k:k+1) = (ischar(c_in{k}) || isstring(c_in{k})) && strcmpi(c_in{k}, "Export");
    end
    c_call = c_in(lv_call);
    c_nv   = c_in(~lv_call);
    opt    = call_options(c_call{:});
end

function opt = call_options(opt)
    arguments (Input)
        opt.Export {mustBeA(opt.Export, ["logical","string","char"])} = false
    end
    if ischar(opt.Export)
        opt.Export = string(opt.Export);
    end
    mustBeScalarOrEmpty(opt.Export);
end
