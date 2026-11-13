function [result, flag, output] = simulate(obj, s_scenario, opt)
% Simulate one scenario of the network over time and return a ResultODE (or a struct).
%
% Time simulation of the network from its equilibrium: the DAE of the buses, components
% and controllers is integrated over time, with the disturbances of the scenario
% s_scenario (Scenario: bus faults, unit trips, branch openings, state offsets, input
% changes). The scenario is chosen by its tag among the scenarios of the network
% (net.add_scenario); a tag that is not one stops with GUILDA:PowerNetwork:ScenarioNotFound,
% which lists the tags. A run without disturbance uses a scenario without disturbances.
%
% The time is the Time of the scenario ([0, 10] unless set), or the Time option of the
% call. The settings are the TimeSimulation section of GUILDA.setting; a Name-Value option
% of the call replaces one setting for this call only (the settings file and the scenario
% are not changed). A name that is not an option stops with the error of the MATLAB
% arguments block.
% It stops with an error naming the remedy when the network is not initialized or was
% edited after net.initialize. flag is 1 when the simulation reached the end time, 0 when
% it stopped by TimeLimit and -1 when the solver stopped early; then result holds the
% trajectories up to output.tEnd, and a warning GUILDA:PowerNetwork:SimulationIncomplete
% tells it, whether or not flag is requested. To write the result to a file, call
% result.export(...). The verdict is not computed here: call result.judge_out_of_step().
%
% With StopOnOutOfStep=true the run stops when the absolute rotor angle delta of a
% generator from that of the generator of the slack bus exceeds StopAngle [deg]: flag is
% 2, the trajectories end at that time (output.tEnd), output.outOfStep holds Time, Unit,
% Reference and Angle, and no warning is given (output.outOfStep is empty otherwise). A
% tripped generator is not compared, and while the reference is tripped the run does not
% stop. A network without such generators stops with GUILDA:PowerNetwork:StopNoRotorAngle.
% With SampleTime > 0 the times of the result are t0 + k*SampleTime and the start and end
% of each phase (a boundary appears twice), with the values of the solver at those times;
% the steps of the solver do not change (use MaxStep). NaN or 0 records the solver steps.
%
% With Format="struct", result is a struct that mirrors the model hierarchy, for repeated
% runs: result.t (the times, shared by every table), result.a_Bus{i}.V, .I, .P, .Q,
% result.a_Bus{i}.a_Component{j}.x, .u, .I (the current the component injects),
% .a_LocalController{k}.x, .u (nested as in the model), result.a_GlobalController{k}.x, .u
% (one column <input>_<unit tag> per controlled unit). Each is a table with one variable
% per name, without a Time column; each element has s_tag. The outputs y are not computed
% (use result.rm_output of a ResultODE).
%
% <@Examples>
% ```matlab
% net.initialize();
% sc = net.add_scenario("fault", Time=[0, 10]);
% sc.add_fault("B008", [1, 1.05]);
% [res, flag] = net.simulate("fault", Progress="none", TimeLimit=Inf);
% res.odeResults.Bus(1).Component(1).X.omega    % frequency deviation of a generator
% res.plot_trajectory(Quantity="omega");
% ```
%
% The time and the settings of one call:
%
% ```matlab
% res = net.simulate("fault", Time=[0, 20]);                   % sc.Time is not changed
% res = net.simulate("fault", Tolerance=1e-6, MaxStep=0.01);   % this call only
% res = net.simulate("fault", SampleTime=0.01);                % t = 0, 0.01, 0.02, ...
% [res, flag, output] = net.simulate("fault", StopOnOutOfStep=true, StopAngle=180);
% output.outOfStep                                             % when flag == 2
% GUILDA.setting("TimeSimulation", Tolerance=1e-6)             % every later run
% res.export("fault.csv");
% ```
%
% Repeated runs without a ResultODE:
%
% ```matlab
% sol = net.simulate("fault", Format="struct");
% plot(sol.t, sol.a_Bus{1}.a_Component{1}.x.omega)
% ```
%
% See also Scenario, ResultODE, SolverODE, PowerNetwork.add_scenario, PowerNetwork.initialize, GUILDA.setting
%
% <@Group> Simulation
    arguments (Input)
        obj
        s_scenario (1,1) string {mustBeScenarioOf(obj, s_scenario)}   % Tag of the scenario to run (net.add_scenario).
        opt.Time (1,2) double {mustBeSimulationTime}   % [s] Simulation time [t0, tend] of this call. Default: the Time of the scenario.
        opt.Solver (1,1) string {mustBeMember(opt.Solver, ["ode15s","ode23t"])}   % Solver of the MATLAB ode object. Default: GUILDA.setting.
        opt.Tolerance (1,1) double {mustBeInRange(opt.Tolerance, 1e-15, 1e-3)}   % Relative error tolerance. Default: GUILDA.setting.
        opt.AbsoluteTolerance (1,1) double {mustBeInRange(opt.AbsoluteTolerance, 1e-15, 1e-3)}   % Absolute error tolerance. Default: GUILDA.setting.
        opt.MaxStep (1,1) double {mustBePositiveOrNaN}   % [s] Largest step of the solver; NaN for the solver default. Default: GUILDA.setting.
        opt.InitialStep (1,1) double {mustBePositiveOrNaN}   % [s] First step of each phase; NaN for the solver default. Default: GUILDA.setting.
        opt.SeparateComplexParts (1,1) logical   % SeparateComplexParts of the ode object (true: "on", false: "off"). Default: GUILDA.setting.
        opt.SampleTime (1,1) double {mustBeNonnegativeOrNaN}   % [s] Interval of the recorded times from the start time (with the start and end of each phase); NaN or 0 for the solver steps. Default: GUILDA.setting.
        opt.StopOnOutOfStep (1,1) logical   % Stop the run when a rotor angle from the generator of the slack bus exceeds StopAngle (flag 2). Default: GUILDA.setting.
        opt.StopAngle (1,1) double {mustBePositive}   % [deg] Threshold of StopOnOutOfStep. Default: GUILDA.setting.
        opt.TimeLimit (1,1) double {mustBePositive}   % [s] Wall-clock limit of the whole run; Inf for none. Default: GUILDA.setting.
        opt.Progress {mustBeProgress}   % "dialog", "disp" or "none" (true: "dialog", false: "none"). Default: GUILDA.setting.
        opt.Verbose (1,1) logical   % Print the phases and the outcome. Default: GUILDA.setting.
        opt.PlotFcn {tools.check_plotfcn(opt.PlotFcn, "simulate")}   % Live display during the run: "none" (draw the result with result.plot_trajectory()). Default: GUILDA.setting.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct"])} = "GUILDAorigin"   % Form of the first output.
    end
    arguments (Output)
        result   % Trajectories: ResultODE (Format "GUILDAorigin"; result.odeResults) or a struct that mirrors the model hierarchy, with tables (Format "struct").
        flag     % 1 completed, 2 stopped by StopOnOutOfStep, 0 stopped by TimeLimit, -1 stopped by the solver.
        output   % Details: message, tEnd, phases, nPhases, nPhasesDone, isSparse, exception, outOfStep.
    end

    t0 = tic;
    sc = obj.a_Scenario{string(cellfun(@(s) s.s_tag, obj.a_Scenario, 'UniformOutput', false)) == s_scenario};
    time = sc.Time;
    if isfield(opt, "Time")
        time = opt.Time;
    end
    sct_options = simulate_options(rmfield(opt, intersect(["Time","Format"], string(fieldnames(opt)))));

    [sct_dae, sct_event, rv_x0, tab_phase] = obj.build_simulation_data(s_scenario, time);
    if sct_options.StopOnOutOfStep
        sct_dae.sct_stop = stop_condition(obj, sct_dae, sct_options.StopAngle);
    end
    if sct_options.Verbose
        print_phases(tab_phase);
    end
    [sct_sol, flag, output] = obj.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options);
    output.phases = tab_phase;
    output = orderfields(output, ["tEnd", "nPhases", "nPhasesDone", "phases", "isSparse", "exception", "outOfStep", "message"]);

    if opt.Format == "struct"
        result = struct_result(sct_sol, sct_dae, sct_event, tab_phase, s_scenario);
    else
        sct_network = struct(obj, false);
        i_slack = tools.slack_bus_index(obj);   % a slack bus the power flow selected is the slack bus of the snapshot (judge_out_of_step)
        if ~isempty(i_slack)
            sct_network.a_Bus{i_slack}.l_isSlack = true;
            sct_network.a_Bus{i_slack}.s_bustype = "slack";
        end
        result = ResultODE(sct_sol, sct_dae, sct_network, struct("solver", obj.solver_ODE, ...
                           "options", sct_options, "flag", flag, "output", output, "elapsed", t0));
    end

    if flag ~= 1 && flag ~= 2         % flag 2: the stop asked by StopOnOutOfStep
        show_msg("warning", "GUILDA:PowerNetwork:SimulationIncomplete", string(flag), output.message);
    end
end


function sct_options = simulate_options(sct_call)
% Settings of one run: the TimeSimulation section of GUILDA.setting, replaced by the options of the call
    arguments (Input)
        sct_call (1,1) struct   % Name-Value options given in the call (no Time).
    end
    arguments (Output)
        sct_options (1,1) struct   % One field per setting of the section.
    end
    sct_options = struct();
    sct_cfg = GUILDA.config("TimeSimulation");
    for s_name = string(fieldnames(sct_cfg)).'
        sct_options.(s_name) = sct_cfg.(s_name).Value;
    end
    if ~(isnumeric(sct_options.TimeLimit) && isscalar(sct_options.TimeLimit) && sct_options.TimeLimit > 0)
        sct_options.TimeLimit = Inf;      % 0, empty or invalid setting: no limit
    end
    for s_name = ["MaxStep", "InitialStep", "SampleTime"]
        v = sct_options.(s_name);
        if ~(isnumeric(v) && isscalar(v) && v > 0)
            sct_options.(s_name) = NaN;   % NaN, 0, empty or invalid setting: the solver default (steps)
        end
    end
    v = sct_options.StopAngle;
    if ~(isnumeric(v) && isscalar(v) && v > 0)
        sct_options.StopAngle = 360;      % empty or invalid setting
    end
    for s_name = string(fieldnames(sct_call)).'
        sct_options.(s_name) = sct_call.(s_name);      % this call only
    end
    sct_options.Solver   = string(sct_options.Solver);
    v = sct_options.Progress;      % true -> "dialog", false -> "none"
    if islogical(v) || isnumeric(v)
        if v
            sct_options.Progress = "dialog";
        else
            sct_options.Progress = "none";
        end
    else
        sct_options.Progress = string(v);
    end
    sct_options.Verbose  = logical(sct_options.Verbose);
    sct_options.SeparateComplexParts = logical(sct_options.SeparateComplexParts);
    sct_options.StopOnOutOfStep = logical(sct_options.StopOnOutOfStep);
    sct_options.PlotFcn  = tools.check_plotfcn(sct_options.PlotFcn, "simulate");
end
