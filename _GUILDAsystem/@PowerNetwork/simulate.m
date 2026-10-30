function [result, flag, output] = simulate(obj, time, varargin)
% Simulate the network over time and return an odeSimulationResult.
%
% Time simulation of the network from its equilibrium: the DAE of the buses, components
% and controllers is integrated over time, with the disturbances given as events
% (odeEventSet: bus faults, unit trips, state offsets, input changes). The settings are
% the stored defaults of net.solver_ODE; Name-Value options after the events override them
% for this call only (net.solver_ODE is not changed).
% Accepted options are the names in odeSimulator.OptionMap plus Export; any other name
% stops with GUILDA:resolve_options:UnknownName.
% It stops with an error naming the remedy when the network is not initialized or was
% edited after net.initialize. flag is 1 when the simulation reached the end time, 0 when
% it stopped by TimeLimit and -1 when the solver stopped early; then result holds the
% trajectories up to output.tEnd.
%
% The events (odeEventSet) come first in `varargin`; none gives the response without
% disturbance. Name-Value options:
%
% - `Solver` — Solver of the MATLAB ode object, e.g. "ode15s", "ode23t" (net.solver_ODE.Solver).
% - `SolverOptions` — Options of the solver, matching Solver (net.solver_ODE.SolverOptions).
% - `Tolerance` — Relative error tolerance (net.solver_ODE.RelativeTolerance).
% - `AbsoluteTolerance` — Absolute error tolerance (net.solver_ODE.AbsoluteTolerance).
% - `SeparateComplexParts` — SeparateComplexParts of the ode object (net.solver_ODE.SeparateComplexParts).
% - `TimeLimit` — Limit of the computation time [s] of each phase; Inf for no limit (net.solver_ODE.TimeLimit).
% - `Progress` — "dialog", "disp" or "none"; true = "dialog", false = "none" (net.solver_ODE.Progress).
% - `Verbose` — Print the phases and the outcome (net.solver_ODE.Verbose).
% - `Plot` — Call result.Plot after the simulation (net.solver_ODE.Plot).
% - `Export` — Call result.Export after the simulation: true for the default file name, or the file name. Default: false.
%
% <@Examples>
% ```matlab
% net.initialize();
% ev = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
% [res, flag] = net.simulate([0,10], ev, Progress="none", TimeLimit=Inf);
% res.odeResults.Bus(1).Component(1).X.omega    % frequency deviation of a generator
% res.Plot(Quantity="omega");
% ```
%
% See also odeEventSet, odeSimulationResult, odeSimulator, PowerNetwork.initialize
    arguments
        obj
        time (:,1) double = []   % [s] Simulation time [t0, tend].
    end
    arguments (Input, Repeating)
        varargin   % Events (odeEventSet), then Name-Value options.
    end
    arguments (Output)
        result   % Trajectories of the buses and components (result.odeResults).
        flag     % 1 completed, 0 stopped by TimeLimit, -1 stopped by the solver.
        output   % Details: message, tEnd, phases, nPhases, nPhasesDone.
    end

    [c_events, c_nv] = split_events(varargin);
    c_nv = v3_simulate_args(c_nv);                            % COMPAT(v3)
    [c_nv, opt] = take_call_options(c_nv);
    s_options   = obj.solver_ODE.get_options(c_nv);

    [result, flag, output] = obj.solver_ODE.solve(obj, time, c_events, s_options);

    if s_options.Plot
        result.Plot();
    end
    if isstring(opt.Export)
        result.Export(opt.Export);
    elseif opt.Export
        result.Export();
    end
end


function [c_events, c_nv] = split_events(c_in)
% Leading odeEventSet arguments are the events; the rest are Name-Value options
    n_evt = numel(c_in);
    for k = 1:numel(c_in)
        if ~isa(c_in{k}, "odeEventSet")
            n_evt = k - 1;
            break
        end
    end
    c_events = c_in(1:n_evt);
    c_nv     = c_in(n_evt+1:end);
    for k = 1:numel(c_nv)
        x = c_nv{k};
        l_name = mod(k, 2) == 1;
        if isa(x, "odeEventSet") || (l_name && ~((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))))
            error('GUILDA:PowerNetwork:SimulateArguments', '%s', ...
                  msg('GUILDA:PowerNetwork:SimulateArguments', num2str(n_evt + k + 1), class(x)));
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
