function [result, flag, output] = calculate_powerflow(obj, opt)
% Calculate the power flow of the network.
%
% Calculates the power flow of the network and returns the solution in the form that
% Format chooses (default: a ResultPF). The settings are the
% PowerFlowCalculation section of GUILDA.setting; Name-Value options override them for
% this call only (the settings file is not changed). The network assembles the data of
% the calculation with net.get_pf_condition (the power flow conditions of the buses and the
% admittance matrix) and net.solver_PF solves it; the solver keeps the last converged
% solution for the next warm start. The network is not changed. When no slack bus is set,
% get_pf_condition makes a bus the slack bus of this calculation only (with an INFO
% message; l_isSlack is not written): the first bus that has a component with Q = NaN,
% otherwise the first bus that has a component. A network without buses stops with
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
%   - "GUILDAorigin": a ResultPF (bus table, branch flows, violated operating limits, iteration history, plot_voltage, the disp_* methods and export).
%   The other values build no ResultPF (nor the network snapshot it holds).
% - `Solver` — Algorithm: "newton", "gradient", "levenberg-marquardt", "fsolve" or "dynamic" (see SolverPF). Default: GUILDA.setting.
% - `Tolerance` — [pu] Largest P/Q mismatch of a converged solution, for every method. Default: GUILDA.setting (1e-8).
% - `MaxIteration` — Maximum number of iterations; NaN for the automatic value of the method (see SolverPF). Default: GUILDA.setting (NaN).
% - `Verbose` — Print the progress of each iteration. Default: GUILDA.setting (false).
% - `WarmStart` — true starts from the last converged solution kept by net.solver_PF when it was solved for the same bus tags; false from the flat start (see SolverPF). Default: GUILDA.setting (true).
% - `PlotFcn` — Live display during the calculation (every Solver): "residual" draws one bar per power equation (two per bus) with its |residual|, updated during the iterations; a function handle is called at every iterate as stop = f(x, optimValues, state) (x the complex bus voltages; optimValues.iteration, .fval = residuals, .residual = the largest, .time = virtual time for "dynamic"; state "init", "iter", "done"), and a true stop ends the calculation with flag -1; "none" draws nothing. The figure after the calculation: result.plot_voltage(). Default: GUILDA.setting ("none").
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% [res, flag] = net.calculate_powerflow();                    % ResultPF
% res.tab_bus            % Varg, V, P, Q, Vphasor, Iphasor of each bus
% res.tab_branch         % flows and losses of each branch
% res.plot_voltage();            % voltage profile
% res.export("pf.csv");  % bus table to a file
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
        opt.PlotFcn {tools.check_plotfcn(opt.PlotFcn, "calculate_powerflow", "residual")} = GUILDA.config("PowerFlowCalculation", "PlotFcn") % Live display during the calculation: "residual", a function handle or "none".
        opt.Format (1,1) string {mustBeMember(opt.Format, ["V","powerflow(mat)","powerflow(tab)","GUILDAorigin"])} = "GUILDAorigin" % Form of the first output.
    end
    arguments (Output)
        result   % Solution in the form of Format: a ResultPF (default), bus voltages, or an n-by-4 matrix or table of V, I, P, Q.
        flag     % 1 converged, 0 MaxIteration reached, -1 stopped by PlotFcn, -2 diverged or no solution (see SolverPF).
        output   % Solver details; output.message describes the outcome.
    end

    sct_options = solver_options(opt);

    sct_PFcondition = obj.get_pf_condition(Display=false);
    tab_PFcondition = sct_PFcondition.Bus;
    sv_bus = string(tab_PFcondition.Properties.RowNames);
    cm_Y   = sct_PFcondition.Y{sv_bus, sv_bus};

    t0 = tic;
    [cv_V, flag, output, cm_Vhistory, rv_step] = obj.solver_PF.solve(cm_Y, tab_PFcondition, sct_options);
    r_elapsed = toc(t0);
    notify_failure(flag, output, sct_options.WhenFailed);

    % V, I (complex phasors), P, Q (real injections, S = V.*conj(I)) of each bus; only
    % "powerflow(tab)" builds a table and only "GUILDAorigin" the ResultPF and its snapshot
    if opt.Format == "V"
        result = cv_V;
        return
    end
    cv_I  = cm_Y*cv_V;
    cv_S  = cv_V .* conj(cv_I);
    if opt.Format == "powerflow(mat)"
        result = [cv_V, cv_I, real(cv_S), imag(cv_S)];
        return
    end
    tab_pf = table(cv_V, cv_I, real(cv_S), imag(cv_S), 'VariableNames', ["V","I","P","Q"], 'RowNames', sv_bus);
    switch opt.Format
        case "powerflow(tab)"
            result = tab_pf;
        case "GUILDAorigin"
            sct_solver = struct("solver", string(class(obj.solver_PF)), "options", sct_options, ...
                "flag", flag, "output", output, "elapsed", r_elapsed, "cm_Vhistory", cm_Vhistory, ...
                "rv_step", rv_step, "tab_PFcondition", tab_PFcondition);
            sct_network = struct(obj, false);   % with the slack bus of the calculation
            i_slack = find(tab_PFcondition.Type == "slack", 1);
            sct_network.a_Bus{i_slack}.l_isSlack = true;
            sct_network.a_Bus{i_slack}.s_bustype = "slack";
            result = ResultPF(tab_pf, cm_Y, sct_network, sct_solver);
    end
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
