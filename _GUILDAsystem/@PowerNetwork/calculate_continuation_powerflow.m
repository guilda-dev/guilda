function [result, flag, output] = calculate_continuation_powerflow(obj, opt)
% Trace the PV curve by the continuation power flow and return a ResultCPF.
%
% Traces the PV curve of the network by the continuation power flow: starting from the
% equilibrium of net.initialize, the loads of LoadBus are scaled by (1 + lambda) and the
% power flow solution is followed past the maximum loading point (the nose). The
% settings are the ContinuationPowerFlow section of GUILDA.setting, and the condition
% LoadBus is kept by net.solver_CPF; Name-Value options override them for this call only
% (neither net.solver_CPF nor the settings file is changed).
% Options not listed below stop with the MATLAB error of an unknown name.
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
% - `PlotFcn` — Live display during the calculation: "pvcurve" draws |V| of every bus against lambda and extends the lines at each step; a function handle is called at the starting point and each step as stop = f(x, optimValues, state) (x the complex bus voltages; optimValues.iteration, .lambda, .correctorIterations; state "init", "iter", "done"), and a true stop ends the path there; "none" draws nothing. The PV curves after the calculation: result.plot_pvcurve(). Default: GUILDA.setting ("none").
% - `Export` — Call result.export after the calculation: true for the default file name, or the file name. Default: false.
%
% <@Examples>
% ```matlab
% net.initialize();
% [res, flag] = net.calculate_continuation_powerflow(LoadBus=["B009","B010"]);
% res.r_lambdaMax          % maximum loading
% res.plot_pvcurve();              % PV curves of the load buses
% ```
%
% See also ResultCPF, SolverCPF
%
% <@Group> CPF
    arguments (Input)
        obj
        opt.LoadBus {mustBeText} = obj.solver_CPF.LoadBus % Tags of the buses whose loads are scaled by (1 + lambda).
        opt.MaxIteration (1,1) double {mustBePositive, mustBeInteger} = GUILDA.config("ContinuationPowerFlow", "MaxIteration") % Maximum number of predictor-corrector steps.
        opt.Tolerance (1,1) double {mustBePositive} = GUILDA.config("ContinuationPowerFlow", "Tolerance") % Convergence tolerance of the corrector.
        opt.StepSize (1,1) double {mustBePositive} = GUILDA.config("ContinuationPowerFlow", "StepSize") % Step size of the predictor.
        opt.ArcLength (1,1) double {mustBePositive} = GUILDA.config("ContinuationPowerFlow", "ArcLength") % Arc length of the corrector.
        opt.InitialLambda (1,1) double = GUILDA.config("ContinuationPowerFlow", "InitialLambda") % lambda at the starting point.
        opt.UseInternalState (1,1) logical = GUILDA.config("ContinuationPowerFlow", "UseInternalState") % Solve with the internal states of the generators.
        opt.Verbose (1,1) logical = GUILDA.config("ContinuationPowerFlow", "Verbose") % Print lambda at each step.
        opt.Limits = GUILDA.config("ContinuationPowerFlow", "Limits") % Operating limits along the path: "Q", "V", "S", "all" or "none" (checked by SolverCPF.solve).
        opt.PlotFcn = GUILDA.config("ContinuationPowerFlow", "PlotFcn") % Live display during the calculation: "pvcurve", a function handle or "none" (checked by tools.check_plotfcn).
        opt.Export {mustBeA(opt.Export, ["logical","string","char"])} = false % Call result.export after the calculation: true or a file name.
    end
    arguments (Output)
        result   % lambda and bus voltages along the path, and the nose point.
        flag     % True when the path passed the nose.
        output   % Details: message, iterations, correctorIterations.
    end

    if ischar(opt.Export)
        opt.Export = string(opt.Export);
    end
    mustBeScalarOrEmpty(opt.Export);
    % The options of the call (with the defaults of GUILDA.setting and net.solver_CPF) go to
    % the solver as they are; text as a string row
    sct_options = rmfield(opt, "Export");
    sct_options.LoadBus = reshape(string(opt.LoadBus), 1, []);
    if isstring(opt.Limits) || ischar(opt.Limits) || iscellstr(opt.Limits)
        sct_options.Limits = reshape(string(opt.Limits), 1, []);   % other values: SolverCPF.solve stops
    end
    sct_options.PlotFcn = tools.check_plotfcn(opt.PlotFcn, "calculate_continuation_powerflow", "pvcurve");

    [result, flag, output] = obj.solver_CPF.solve(obj, sct_options);

    if isstring(opt.Export)
        result.export(opt.Export);
    elseif opt.Export
        result.export();
    end
end

