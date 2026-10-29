function [result, flag, output] = simulate(obj, time, varargin)
% <@Desc>
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
% <@Role> Analysis
% <@Summary> Time simulation; returns an odeSimulationResult.
% <@Signatures>
% [
%   "result = net.simulate(time)",
%   "result = net.simulate(time, ev1, ev2, ...)",
%   "[result, flag, output] = net.simulate(time, ev1, ..., Name, Value)"
% ]
% <@Parameters>
% [
%   {"Name": "time", "Type": "double vector", "Description": "Simulation time [t0, tend] [s].", "Required": true, "Default": "-"},
%   {"Name": "ev1, ev2, ...", "Type": "odeEventSet", "Description": "Events of the simulation. None for the response without disturbance.", "Required": false, "Default": "-"},
%   {"Name": "Solver", "Type": "string scalar", "Description": "Solver of the MATLAB ode object, e.g. \"ode15s\", \"ode23t\" (net.solver_ODE.Solver).", "Required": false, "Default": "net.solver_ODE.Solver"},
%   {"Name": "SolverOptions", "Type": "matlab.ode.Options", "Description": "Options of the solver, matching Solver (net.solver_ODE.SolverOptions).", "Required": false, "Default": "net.solver_ODE.SolverOptions"},
%   {"Name": "Tolerance", "Type": "double scalar", "Description": "Relative error tolerance (net.solver_ODE.RelativeTolerance).", "Required": false, "Default": "net.solver_ODE.RelativeTolerance"},
%   {"Name": "AbsoluteTolerance", "Type": "double scalar", "Description": "Absolute error tolerance (net.solver_ODE.AbsoluteTolerance).", "Required": false, "Default": "net.solver_ODE.AbsoluteTolerance"},
%   {"Name": "SeparateComplexParts", "Type": "on/off", "Description": "SeparateComplexParts of the ode object (net.solver_ODE.SeparateComplexParts).", "Required": false, "Default": "net.solver_ODE.SeparateComplexParts"},
%   {"Name": "TimeLimit", "Type": "double scalar", "Description": "Limit of the computation time [s] of each phase; Inf for no limit (net.solver_ODE.TimeLimit).", "Required": false, "Default": "net.solver_ODE.TimeLimit"},
%   {"Name": "Progress", "Type": "string scalar or logical", "Description": "\"dialog\", \"disp\" or \"none\"; true = \"dialog\", false = \"none\" (net.solver_ODE.Progress).", "Required": false, "Default": "net.solver_ODE.Progress"},
%   {"Name": "Verbose", "Type": "logical scalar", "Description": "Print the phases and the outcome (net.solver_ODE.Verbose).", "Required": false, "Default": "net.solver_ODE.Verbose"},
%   {"Name": "Plot", "Type": "logical scalar", "Description": "Call result.Plot after the simulation (net.solver_ODE.Plot).", "Required": false, "Default": "net.solver_ODE.Plot"},
%   {"Name": "Export", "Type": "logical scalar or string scalar", "Description": "Call result.Export after the simulation: true for the default file name, or the file name.", "Required": false, "Default": "false"}
% ]
% <@Returns>
% [
%   {"Name": "result", "Type": "odeSimulationResult", "Description": "Trajectories of the buses and components (result.odeResults)."},
%   {"Name": "flag", "Type": "double", "Description": "1 completed, 0 stopped by TimeLimit, -1 stopped by the solver."},
%   {"Name": "output", "Type": "struct", "Description": "Details: message, tEnd, phases, nPhases, nPhasesDone."}
% ]
% <@Examples>
% [
%   "```matlab\nnet.initialize();\nev = odeEventSet(\"fault\", net, \"TimeSpan\", [1,1.05], \"FaultBus\", \"B008\");\n[res, flag] = net.simulate([0,10], ev, Progress=\"none\", TimeLimit=Inf);\nres.odeResults.Bus(1).Component(1).X.omega    % frequency deviation of a generator\nres.Plot(Quantity=\"omega\");\n```"
% ]
    arguments
        obj
        time (:,1) double = []
    end
    arguments (Input, Repeating)
        varargin
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
