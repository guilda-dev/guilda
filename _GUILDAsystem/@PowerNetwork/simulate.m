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
% call. The settings are the TimeSimulation section of GUILDA.setting, the defaults of the
% Name-Value options; an option given in the call replaces one setting for this call only
% (the settings file and the scenario are not changed). The options go to net.solver_ODE as
% they are (Progress true/false as "dialog"/"none"). A name that is not an option stops
% with the error of the MATLAB arguments block.
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
        s_scenario (1,1) string {simulateFcn_mustBeScenarioOf(obj, s_scenario)}   % Tag of the scenario to run (net.add_scenario).
        opt.Time (1,2) double {mustBeSimulationTime}   % [s] Simulation time [t0, tend] of this call. Default: the Time of the scenario.
        opt.Solver (1,1) string {mustBeMember(opt.Solver, ["ode15s","ode23t"])} = GUILDA.config("TimeSimulation", "Solver")   % Solver of the MATLAB ode object.
        opt.Tolerance (1,1) double {mustBeInRange(opt.Tolerance, 1e-15, 1e-3)} = GUILDA.config("TimeSimulation", "Tolerance")   % Relative error tolerance.
        opt.AbsoluteTolerance (1,1) double {mustBeInRange(opt.AbsoluteTolerance, 1e-15, 1e-3)} = GUILDA.config("TimeSimulation", "AbsoluteTolerance")   % Absolute error tolerance.
        opt.MaxStep (1,1) double {mustBePositiveOrNaN} = GUILDA.config("TimeSimulation", "MaxStep")   % [s] Largest step of the solver; NaN for the solver default.
        opt.InitialStep (1,1) double {mustBePositiveOrNaN} = GUILDA.config("TimeSimulation", "InitialStep")   % [s] First step of each phase; NaN for the solver default.
        opt.SeparateComplexParts (1,1) logical = GUILDA.config("TimeSimulation", "SeparateComplexParts")   % SeparateComplexParts of the ode object (true: "on", false: "off").
        opt.SampleTime (1,1) double {simulateFcn_mustBeNonnegativeOrNaN} = GUILDA.config("TimeSimulation", "SampleTime")   % [s] Interval of the recorded times from the start time (with the start and end of each phase); NaN or 0 for the solver steps.
        opt.StopOnOutOfStep (1,1) logical = GUILDA.config("TimeSimulation", "StopOnOutOfStep")   % Stop the run when a rotor angle from the generator of the slack bus exceeds StopAngle (flag 2).
        opt.StopAngle (1,1) double {mustBePositive} = GUILDA.config("TimeSimulation", "StopAngle")   % [deg] Threshold of StopOnOutOfStep.
        opt.TimeLimit (1,1) double {mustBePositive} = GUILDA.config("TimeSimulation", "TimeLimit")   % [s] Wall-clock limit of the whole run; Inf for none.
        opt.Progress {simulateFcn_mustBeProgress} = GUILDA.config("TimeSimulation", "Progress")   % "dialog", "disp" or "none" (true: "dialog", false: "none").
        opt.Verbose (1,1) logical = GUILDA.config("TimeSimulation", "Verbose")   % Print the phases and the outcome.
        opt.PlotFcn = GUILDA.config("TimeSimulation", "PlotFcn")   % Live display during the run: "none" (checked by tools.check_plotfcn; draw the result with result.plot_trajectory()).
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
    % The options of the call (with the defaults of GUILDA.setting) go to the solver as they
    % are; Progress true/false of the call as its mode, PlotFcn checked once
    sct_options = rmfield(opt, intersect(["Time","Format"], string(fieldnames(opt))));
    if islogical(opt.Progress) || isnumeric(opt.Progress)
        sv_mode = ["none", "dialog"];
        sct_options.Progress = sv_mode(1 + logical(opt.Progress));
    end
    sct_options.PlotFcn = tools.check_plotfcn(opt.PlotFcn, "simulate");

    [sct_dae, sct_event, rv_x0, tab_phase] = obj.build_simulation_data(s_scenario, time);
    if sct_options.StopOnOutOfStep
        sct_dae.sct_stop = simulateFcn_stop_condition(obj, sct_dae, sct_options.StopAngle);
    end
    if sct_options.Verbose
        simulateFcn_print_phases(tab_phase);
    end
    [sct_sol, flag, output] = obj.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options);
    output.phases = tab_phase;
    output = orderfields(output, ["tEnd", "nPhases", "nPhasesDone", "phases", "isSparse", "exception", "outOfStep", "message"]);

    if opt.Format == "struct"
        result = simulateFcn_struct_result(sct_sol, sct_dae, sct_event, tab_phase, s_scenario);
    else
        result = ResultODE(sct_sol, sct_dae, struct(obj, false), struct("solver", obj.solver_ODE, ...
                           "options", sct_options, "flag", flag, "output", output, "elapsed", t0));
    end

    if flag ~= 1 && flag ~= 2         % flag 2: the stop asked by StopOnOutOfStep
        show_msg("warning", "GUILDA:PowerNetwork:SimulationIncomplete", string(flag), output.message);
    end
end

