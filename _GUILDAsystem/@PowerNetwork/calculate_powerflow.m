function [result, flag, output] = calculate_powerflow(obj, opt)
% Calculate the power flow of the network.
%
% Calculates the power flow of the network and returns the solution in the form that
% Format chooses (default: a ResultPF). The settings are the
% PowerFlowCalculation section of GUILDA.setting; Name-Value options override them for
% this call only (the settings file is not changed). The network assembles the data of
% the calculation (the power flow conditions of the buses, Bus.get_pf_condition, and the
% admittance matrix) and net.solver_PF solves it; the solver keeps the last converged
% solution for the next warm start. The network is not changed, except that a slack bus
% is selected when none is set (with an INFO message): the first bus that has a
% component with Q = NaN, otherwise the first bus that has a component
% (GUILDA:Bus:SlackWithoutQnan). A network without buses stops with
% GUILDA:PowerNetwork:NoBus, and a network whose buses have no components with
% GUILDA:PowerNetwork:NoSlackCandidate. A calculation that does not converge gives the
% warning GUILDA:PowerNetwork:PowerflowNotConverged (WhenFailed of GUILDA.setting:
% "WARN", "ERROR", "DISP" or "NONE"). Options not listed below stop with the MATLAB
% error of an unknown name.
%
% Name-Value options:
%
% - `Format` — Form of the first output (flag and output stay the 2nd and 3rd outputs). Default: "GUILDAorigin".
%   - "V": complex bus voltages [pu], a column in net.a_Bus order.
%   - "powerflow(mat)": n-by-4 complex double, one row per bus (net.a_Bus order); columns V, I (complex phasors of the voltage and the current injection), P, Q (real injections into the network) [pu].
%   - "powerflow(tab)": the same as a table with the variables V, I, P, Q; row names = bus tags.
%   - "GUILDAorigin": a ResultPF (bus table, branch flows, violated operating limits, iteration history, Plot and Export).
%   The other values build no ResultPF (nor the network snapshot it holds).
% - `Solver` — Algorithm: "newton", "gradient", "levenberg-marquardt", "fsolve" or "dynamic" (see SolverPF). Default: GUILDA.setting.
% - `Tolerance` — [pu] Largest P/Q mismatch of a converged solution, for every method. Default: GUILDA.setting (1e-8).
% - `MaxIteration` — Maximum number of iterations; NaN for the automatic value of the method (see SolverPF). Default: GUILDA.setting (NaN).
% - `Verbose` — Print the progress of each iteration. Default: GUILDA.setting (false).
% - `WarmStart` — true starts from the last converged solution kept by net.solver_PF when it was solved for the same bus tags; false from the flat start (see SolverPF). Default: GUILDA.setting (true).
% - `PlotFcn` — Live display during the calculation (every Solver): "residual" draws one bar per power equation (two per bus) with its |residual|, updated during the iterations; a function handle is called at every iterate as stop = f(x, optimValues, state) (x the complex bus voltages; optimValues.iteration, .fval = residuals, .residual = the largest, .time = virtual time for "dynamic"; state "init", "iter", "done"), and a true stop ends the calculation with flag -1; "none" draws nothing. The figure after the calculation: result.Plot(). Default: GUILDA.setting ("none").
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% [res, flag] = net.calculate_powerflow();                    % ResultPF
% res.tab_bus            % Varg, V, P, Q, Vphasor, Iphasor of each bus
% res.tab_branch         % flows and losses of each branch
% res.Plot();            % voltage profile
% res.Export("pf.csv");  % bus table to a file
% V   = net.calculate_powerflow(Format="V", Solver="dynamic");   % complex bus voltages
% tab = net.calculate_powerflow(Format="powerflow(tab)");      % V, I, P, Q of each bus
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
        opt.Format (1,1) string {mustBeMember(opt.Format, ["V","powerflow(mat)","powerflow(tab)","GUILDAorigin"])} = "GUILDAorigin" % Form of the first output.
    end
    arguments (Output)
        result   % Solution in the form of Format: a ResultPF (default), bus voltages, or an n-by-4 matrix or table of V, I, P, Q.
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

    sv_bus = reshape(string(obj.a_Bus), [], 1);
    tab_PFcondition = tools.vcellfun(@(b) b.get_pf_condition, obj.a_Bus);
    tab_PFcondition.Properties.RowNames = sv_bus;
    tab_Y = obj.get_admittance_matrix;
    cm_Y  = tab_Y{sv_bus, sv_bus};

    t0 = tic;
    [cv_V, flag, output, cm_Vhistory, rv_step] = obj.solver_PF.solve(cm_Y, tab_PFcondition, sct_options);
    r_elapsed = toc(t0);
    notify_failure(flag, output, sct_options.WhenFailed);

    tab_pf = powerflow_table(sv_bus, cv_V, cm_Y*cv_V);
    sct_solver = struct("solver", string(class(obj.solver_PF)), "options", sct_options, ...
        "flag", flag, "output", output, "elapsed", r_elapsed, "cm_Vhistory", cm_Vhistory, ...
        "rv_step", rv_step, "tab_PFcondition", tab_PFcondition);
    result = format_powerflow(opt.Format, tab_pf, @() ResultPF(tab_pf, cm_Y, struct(obj, false), sct_solver));
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


function notify_failure(flag, output, s_when)
% The WhenFailed setting: a warning, an error or the message when the calculation failed
    if flag > 0
        return
    end
    switch s_when
        case "WARN" ; show_msg("warning", "GUILDA:PowerNetwork:PowerflowNotConverged", output.message)
        case "ERROR"; error(msg("GUILDA:PowerNetwork:PowerflowNotConverged", output.message))
        case "DISP" ; disp(output.message)
    end
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
