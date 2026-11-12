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
        opt.LoadBus {mustBeText} % Tags of the buses whose loads are scaled by (1 + lambda); omitted: net.solver_CPF.LoadBus.
        opt.MaxIteration (1,1) double {mustBePositive, mustBeInteger} % Maximum number of predictor-corrector steps; omitted: GUILDA.setting.
        opt.Tolerance (1,1) double {mustBePositive} % Convergence tolerance of the corrector; omitted: GUILDA.setting.
        opt.StepSize (1,1) double {mustBePositive} % Step size of the predictor; omitted: GUILDA.setting.
        opt.ArcLength (1,1) double {mustBePositive} % Arc length of the corrector; omitted: GUILDA.setting.
        opt.InitialLambda (1,1) double % lambda at the starting point; omitted: GUILDA.setting.
        opt.UseInternalState (1,1) logical % Solve with the internal states of the generators; omitted: GUILDA.setting.
        opt.Verbose (1,1) logical % Print lambda at each step; omitted: GUILDA.setting.
        opt.Limits % Operating limits along the path: "Q", "V", "S", "all" or "none" (checked by SolverCPF.solve); omitted: GUILDA.setting.
        opt.PlotFcn % Live display during the calculation: "pvcurve", a function handle or "none" (checked by tools.check_plotfcn); omitted: GUILDA.setting.
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
    sct_options = solver_options(obj.solver_CPF, opt);

    [result, flag, output] = obj.solver_CPF.solve(obj, sct_options);

    if isstring(opt.Export)
        result.export(opt.Export);
    elseif opt.Export
        result.export();
    end
end


function sct = solver_options(solver, opt)
% Settings handed to the solver: the ContinuationPowerFlow section of GUILDA.setting and
% the condition LoadBus of the solver, with the options given in this call
    sct_cfg = GUILDA.config("ContinuationPowerFlow");
    sct = struct();
    for s_name = string(fieldnames(sct_cfg)).'
        sct.(s_name) = sct_cfg.(s_name).Value;
    end
    sct.LoadBus = solver.LoadBus;
    for s_name = string(fieldnames(opt)).'
        if s_name ~= "Export"
            sct.(s_name) = opt.(s_name);
        end
    end
    sct.LoadBus = reshape(string(sct.LoadBus), 1, []);
    if isstring(sct.Limits) || ischar(sct.Limits) || iscellstr(sct.Limits)
        sct.Limits = reshape(string(sct.Limits), 1, []);   % other values: SolverCPF.solve stops
    end
    sct.UseInternalState = logical(sct.UseInternalState);
    sct.Verbose = logical(sct.Verbose);
    sct.PlotFcn = tools.check_plotfcn(sct.PlotFcn, "calculate_continuation_powerflow", "pvcurve");
end

