function [result, flag, output] = simulate(obj, time, varargin)
% Simulate the network over time and return a ResultODE.
%
% Time simulation of the network from its equilibrium: the DAE of the buses, components
% and controllers is integrated over time, with the disturbances of the given scenarios
% (Scenario: bus faults, unit trips, branch openings, state offsets, input changes). The
% scenarios must belong to the network (net.add_scenario); their disturbances are combined.
% The settings are the stored defaults of net.solver_ODE, replaced by the stored Options of
% the scenarios, then by the Name-Value options of the call, for this call only
% (net.solver_ODE and the scenarios are not changed).
% Accepted options are the names in SolverODE.OptionMap plus Export; any other name
% stops with GUILDA:resolve_options:UnknownName.
% time is [t0, tend] with finite t0 < tend. Without it (net.simulate(sc, ...)) or with [],
% the Time of the scenarios is used, and when they have none the time span of the
% disturbances; any other value stops with GUILDA:PowerNetwork:SimulateTime. Scenarios with
% different Time, or with different values of one option in Options, stop with an error
% (GUILDA:PowerNetwork:ScenarioTimeConflict, ScenarioOptionConflict) unless the call gives
% the time or the option.
% It stops with an error naming the remedy when the network is not initialized or was
% edited after net.initialize. flag is 1 when the simulation reached the end time, 0 when
% it stopped by TimeLimit and -1 when the solver stopped early; then result holds the
% trajectories up to output.tEnd, and a warning GUILDA:PowerNetwork:SimulationIncomplete
% tells it, whether or not flag is requested.
%
% The scenarios (Scenario) come first in `varargin`; none gives the response without
% disturbance. The verdict of a scenario is not computed here: call sc.judge(result).
% Name-Value options:
%
% - `Solver` — Solver of the MATLAB ode object, e.g. "ode15s", "ode23t" (net.solver_ODE.Solver).
% - `SolverOptions` — Options of the solver, matching Solver (net.solver_ODE.SolverOptions).
% - `Tolerance` — Relative error tolerance (net.solver_ODE.RelativeTolerance).
% - `AbsoluteTolerance` — Absolute error tolerance (net.solver_ODE.AbsoluteTolerance).
% - `SeparateComplexParts` — SeparateComplexParts of the ode object (net.solver_ODE.SeparateComplexParts).
% - `TimeLimit` — Limit of the computation time [s] of the whole run; Inf for no limit (net.solver_ODE.TimeLimit).
% - `Progress` — "dialog", "disp" or "none"; true = "dialog", false = "none" (net.solver_ODE.Progress).
% - `Verbose` — Print the phases and the outcome (net.solver_ODE.Verbose).
% - `Plot` — Call result.Plot after the simulation (net.solver_ODE.Plot).
% - `Export` — Call result.Export after the simulation: true for the default file name, or the file name, whose extension is checked before the integration. Default: false.
%
% <@Examples>
% ```matlab
% net.initialize();
% sc = Scenario("fault");
% sc.add_fault("B008", [1, 1.05]);
% net.add_scenario(sc);
% [res, flag] = net.simulate([0,10], sc, Progress="none", TimeLimit=Inf);
% res.odeResults.Bus(1).Component(1).X.omega    % frequency deviation of a generator
% res.Plot(Quantity="omega");
% ```
%
% The stored time and options of a scenario:
%
% ```matlab
% sc.Time    = [0, 20];
% sc.Options = struct("Tolerance", 1e-6, "AbsoluteTolerance", 1e-6);
% res = net.simulate(sc);                   % [0, 20], Tolerance 1e-6
% res = net.simulate(sc, Tolerance=1e-5);   % the call option wins
% ```
%
% See also Scenario, ResultODE, SolverODE, PowerNetwork.add_scenario, PowerNetwork.initialize
%
% <@Group> Simulation
    arguments
        obj
        time = []   % [s] Simulation time [t0, tend], or [] for the Time of the scenarios (or the time span of the disturbances). May be left out.
    end
    arguments (Input, Repeating)
        varargin   % Scenarios (Scenario), then Name-Value options.
    end
    arguments (Output)
        result   % Trajectories of the buses and components (result.odeResults).
        flag     % 1 completed, 0 stopped by TimeLimit, -1 stopped by the solver.
        output   % Details: message, tEnd, phases, nPhases, nPhasesDone.
    end

    c_in = varargin;
    if isa(time, "Scenario")            % net.simulate(sc, ...): no time
        c_in = [{time}, c_in];
        time = [];
    end
    check_time(time);
    [c_events, c_nv] = split_events(c_in);
    c_nv = v3_simulate_args(c_nv);                            % COMPAT(v3)
    [time, c_nv] = scenario_settings(c_events, time, c_nv);
    [c_nv, opt] = take_call_options(c_nv);
    check_export(opt.Export);
    sct_options = obj.solver_ODE.get_options(c_nv);

    [result, flag, output] = obj.solver_ODE.solve(obj, time, c_events, sct_options);

    if flag ~= 1
        warning(msg("GUILDA:PowerNetwork:SimulationIncomplete", string(flag), output.message));
    end

    if sct_options.Plot
        result.Plot();
    end
    if isstring(opt.Export)
        result.Export(opt.Export);
    elseif opt.Export
        result.Export();
    end
end


function check_export(export)
% A file name must have an extension that result.Export writes, known before the integration
    if ~isstring(export)
        return
    end
    [~, ~, str_ext] = fileparts(export);
    if ~isscalar(export) || ~ismember(lower(str_ext), [".csv", ".txt", ".xlsx", ".xls", ".mat"])
        error(msg("GUILDA:PowerNetwork:SimulateExport", char(str_ext)));
    end
end

function check_time(time)
% time must be [] or a real vector [t0, tend] with finite t0 < tend
    if ~isnumeric(time) || ~isreal(time)
        str_reason = "it is a non-real or non-numeric value of class " + class(time);
    elseif isempty(time)
        return
    elseif ~isvector(time) || numel(time) ~= 2
        str_reason = "it has the size " + join(string(size(time)), "x");
    elseif ~all(isfinite(time))
        str_reason = "it has a value that is not finite: " + mat2str(time);
    elseif time(1) >= time(2)
        str_reason = "t0 is not smaller than tend: " + mat2str(time);
    else
        return
    end
    error(msg("GUILDA:PowerNetwork:SimulateTime", str_reason));
end

function [time, c_nv] = scenario_settings(c_events, time, c_nv)
% Stored Time and Options of the scenarios; the call wins
    c_sc = c_events(cellfun(@(s) isscalar(s), c_events));
    if isempty(time)
        c_time = cellfun(@(s) s.Time, c_sc, 'UniformOutput', false);
        c_time = c_time(~cellfun(@isempty, c_time));
        if ~isempty(c_time)
            time = c_time{1};
            if ~all(cellfun(@(t) isequal(t, time), c_time))
                error(msg("GUILDA:PowerNetwork:ScenarioTimeConflict", ...
                          char(join(cellfun(@(s) s.str_tag, c_sc), ", ")), ...
                          char(join(cellfun(@(t) string(mat2str(t)), c_time), ", "))));
            end
        end
    end
    sv_call = strings(1,0);
    for k = 1:2:numel(c_nv)
        if (ischar(c_nv{k}) && isrow(c_nv{k})) || (isstring(c_nv{k}) && isscalar(c_nv{k}))
            sv_call(end+1) = lower(string(c_nv{k})); %#ok<AGROW>
        end
    end
    sct_stored = struct();     % lower-case name -> {Name, Value}
    for k = 1:numel(c_sc)
        sct_opt = c_sc{k}.Options;
        for str_name = string(fieldnames(sct_opt)).'
            str_key = lower(str_name);
            if ismember(str_key, sv_call)
                continue
            end
            if isfield(sct_stored, str_key) && ~isequal(sct_stored.(str_key){2}, sct_opt.(str_name))
                error(msg("GUILDA:PowerNetwork:ScenarioOptionConflict", char(str_name), ...
                          char(join(cellfun(@(s) s.str_tag, c_sc), ", "))));
            end
            sct_stored.(str_key) = {str_name, sct_opt.(str_name)};
        end
    end
    c_pair = struct2cell(sct_stored);
    c_pair = [c_pair{:}];
    c_nv = [c_pair, c_nv];
end

function [c_events, c_nv] = split_events(c_in)
% Leading Scenario arguments are the scenarios; the rest are Name-Value options
    n_evt = numel(c_in);
    for k = 1:numel(c_in)
        if ~isa(c_in{k}, "Scenario")
            n_evt = k - 1;
            break
        end
    end
    c_events = c_in(1:n_evt);
    c_nv     = c_in(n_evt+1:end);
    for k = 1:numel(c_nv)
        x = c_nv{k};
        l_name = mod(k, 2) == 1;
        if isa(x, "Scenario") || (l_name && ~((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))))
            error(msg("GUILDA:PowerNetwork:SimulateArguments", num2str(n_evt + k + 1), class(x)));
        end
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
    arguments
        opt.Export {mustBeA(opt.Export, ["logical","string","char"])} = false
    end
    if ischar(opt.Export)
        opt.Export = string(opt.Export);
    end
    mustBeScalarOrEmpty(opt.Export);
end
