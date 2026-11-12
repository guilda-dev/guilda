function [result, flag, output] = calculate_powerflow(obj, opt)
% Calculate the power flow of the network and return a ResultPF.
%
% Calculates the power flow of the network. The settings are the PowerFlowCalculation
% section of GUILDA.setting; Name-Value options override them for this call only (the
% settings file is not changed). net.solver_PF keeps the solution for the next warm start
% and the cache of the equations. The network is not changed, except that a slack
% bus is selected when none is set (with an INFO message): the first bus that has a
% component with Q = NaN, otherwise the first bus that has a component
% (GUILDA:Bus:SlackWithoutQnan). A network without buses stops with
% GUILDA:PowerNetwork:NoBus, and a network whose buses have no components with
% GUILDA:PowerNetwork:NoSlackCandidate.
% Options not listed below stop with the MATLAB error of an unknown name.
%
% Name-Value options:
%
% - `Solver` — Algorithm: "newton", "gradient", "levenberg-marquardt", "fsolve" or "dynamic" (see SolverPF). Default: GUILDA.setting.
% - `Tolerance` — [pu] Largest P/Q mismatch of a converged solution, for every method. Default: GUILDA.setting (1e-8).
% - `MaxIteration` — Maximum number of iterations; NaN for the automatic value of the method (see SolverPF). Default: GUILDA.setting (NaN).
% - `Verbose` — Print the progress of each iteration. Default: GUILDA.setting (false).
% - `WarmStart` — true starts from the last converged solution of this network (kept by net.solver_PF); false from the flat start (see SolverPF). Default: GUILDA.setting (true).
% - `PlotFcn` — Live display during the calculation (every Solver): "residual" draws one bar per power equation (two per bus) with its |residual|, updated during the iterations; a function handle is called at every iterate as stop = f(x, optimValues, state) (x the complex bus voltages; optimValues.iteration, .fval = residuals, .residual = the largest, .time = virtual time for "dynamic"; state "init", "iter", "done"), and a true stop ends the calculation with flag -1; "none" draws nothing. The figure after the calculation: result.Plot(). Default: GUILDA.setting ("none").
% - `Export` — Call result.Export after the calculation: true for the default file name, or the file name. Default: false.
%
% <@Examples>
% ```matlab
% [res, flag] = net.calculate_powerflow();
% res.tab_bus            % Varg, V, P, Q, Vphasor, Iphasor of each bus
% res = net.calculate_powerflow(Solver="dynamic", Tolerance=1e-10);
% res.Plot();            % voltage profile
% ```
%
% See also ResultPF, SolverPF, PowerNetwork.initialize
%
% <@Group> Power flow
    arguments (Input)
        obj
        opt.Solver (1,1) string {mustBeMember(opt.Solver, ["newton","gradient","levenberg-marquardt","fsolve","dynamic"])} = GUILDA.config("PowerFlowCalculation", "Solver") % Algorithm (see SolverPF).
        opt.Tolerance (1,1) double {mustBePositive} = GUILDA.config("PowerFlowCalculation", "Tolerance") % [pu] Largest P/Q mismatch of a converged solution.
        opt.MaxIteration (1,1) double {mustBeIntegerOrNaN} = GUILDA.config("PowerFlowCalculation", "MaxIteration") % Maximum number of iterations; NaN for the automatic value.
        opt.Verbose (1,1) logical = GUILDA.config("PowerFlowCalculation", "Verbose") % Print the progress of each iteration.
        opt.WarmStart (1,1) logical = GUILDA.config("PowerFlowCalculation", "WarmStart") % Start from the last converged solution of this network.
        opt.PlotFcn {mustBePlotFcn} = GUILDA.config("PowerFlowCalculation", "PlotFcn") % Live display during the calculation: "residual", a function handle or "none".
        opt.Export {mustBeExport} = false % true for the default file name of result.Export, or the file name.
    end
    arguments (Output)
        result   % Bus voltages, injections and branch flows of the solution.
        flag     % 1 converged, 0 MaxIteration reached, -1 stopped by PlotFcn, -2 diverged or no solution (see SolverPF).
        output   % Solver details; output.message describes the outcome.
    end

    sct_options = solver_options(opt);

    lv_isSlack = tools.vcellfun(@(b) b.l_isSlack, obj.a_Bus);
    if ~any(lv_isSlack)
        bus = select_slack_bus(obj);
        show_msg("info", "GUILDA:PowerNetwork:SlackSelected", string(bus))
        bus.l_isSlack = true;
    end

    [result, flag, output] = obj.solver_PF.solve(obj, sct_options);

    if isstring(opt.Export) || ischar(opt.Export)
        result.Export(string(opt.Export));
    elseif opt.Export
        result.Export();
    end
end


function bus = select_slack_bus(obj)
% The bus of tools.slack_bus_index; stops when there is none
    if isempty(obj.a_Bus)
        error(msg("GUILDA:PowerNetwork:NoBus", string(obj)))
    end
    i_bus = tools.slack_bus_index(obj);
    if isempty(i_bus)
        error(msg("GUILDA:PowerNetwork:NoSlackCandidate", string(obj)))
    end
    bus = obj.a_Bus{i_bus};
end


function sct = solver_options(opt)
% Settings handed to the solver: the PowerFlowCalculation section of GUILDA.setting with
% the options of the call, and Display ("iter" for Verbose true, "none" for false)
    sct_cfg = GUILDA.config("PowerFlowCalculation");
    sct = struct();
    for s_name = string(fieldnames(sct_cfg)).'
        sct.(s_name) = sct_cfg.(s_name).Value;
    end
    for s_name = ["Solver","Tolerance","MaxIteration","Verbose","WarmStart"]
        sct.(s_name) = opt.(s_name);
    end
    sct.PlotFcn    = tools.check_plotfcn(opt.PlotFcn, "calculate_powerflow", "residual");
    sct.WhenFailed = string(sct.WhenFailed);
    sct.Display    = replace(string(sct.Verbose), ["true","false"], ["iter","none"]);
end


function mustBeIntegerOrNaN(r)
% NaN (the automatic value) or a nonnegative integer
    if ~isnan(r)
        mustBeNonnegative(r)
        mustBeInteger(r)
    end
end


function mustBePlotFcn(x)
% "none", "residual" or a function handle (tools.check_plotfcn)
    tools.check_plotfcn(x, "calculate_powerflow", "residual");
end


function mustBeExport(x)
% A logical scalar or one file name
    mustBeA(x, ["logical","string","char"])
    if ischar(x)
        x = string(x);
    end
    mustBeScalarOrEmpty(x)
end
