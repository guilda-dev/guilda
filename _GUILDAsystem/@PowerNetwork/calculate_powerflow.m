function [result, flag, output] = calculate_powerflow(obj, varargin)
% Calculate the power flow of the network and return a ResultPF.
%
% Calculates the power flow of the network. The settings are the stored defaults of
% net.solver_PF; Name-Value options override them for this call only (net.solver_PF is
% not changed). The network is not changed either, except that a slack bus is selected
% when none is set (with an INFO message): the first bus that has a component with
% Q = NaN, otherwise the first bus that has a component (GUILDA:Bus:SlackWithoutQnan).
% A network without buses stops with GUILDA:PowerNetwork:NoBus, and a network whose
% buses have no components with GUILDA:PowerNetwork:NoSlackCandidate.
% Accepted options are the names in SolverPF.OptionMap plus Plot and Export;
% any other name stops with GUILDA:resolve_options:UnknownName.
%
% Name-Value options:
%
% - `Method` — Calculation method (net.solver_PF.Method).
% - `Tolerance` — Convergence tolerance; 0 for the solver default (net.solver_PF.Tolerance).
% - `MaxIteration` — Maximum number of fsolve iterations; 0 for the fsolve default (net.solver_PF.MaxIterations).
% - `Verbose` — Print fsolve progress (sets Display to "iter" or "none"). Default: net.solver_PF.Display ~= "none".
% - `Plot` — Call result.Plot after the calculation. Default: false.
% - `Export` — Call result.Export after the calculation: true for the default file name, or the file name. Default: false.
%
% <@Examples>
% ```matlab
% [res, flag] = net.calculate_powerflow();
% res.tab_bus            % Varg, V, P, Q, Vphasor, Iphasor of each bus
% res = net.calculate_powerflow(Method="dynamic", Tolerance=1e-8, Plot=true);
% ```
%
% See also ResultPF, SolverPF, PowerNetwork.initialize
    arguments (Output)
        result   % Bus voltages, injections and branch flows of the solution.
        flag     % exitflag of fsolve ("algebraic", positive = converged) or convergence ("dynamic").
        output   % Solver details; output.message describes the outcome.
    end

    varargin = v3_powerflow_args(varargin);                   % COMPAT(v3)
    [c_nv, opt] = take_call_options(varargin);
    s_options   = obj.solver_PF.get_options(c_nv);

    lv_isSlack = tools.vcellfun(@(b) b.l_isSlack, obj.a_Bus);
    if ~any(lv_isSlack)
        bus = select_slack_bus(obj);
        disp("INFO: Slack bus not found. Setting the bus '"+string(bus)+"' as the slack bus.")
        bus.l_isSlack = true;
    end

    [result, flag, output] = obj.solver_PF.solve(obj, s_options);

    if opt.Plot
        result.Plot();
    end
    if isstring(opt.Export)
        result.Export(opt.Export);
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


function [c_nv, opt] = take_call_options(c_in)
% Separates the options of this call (Plot, Export) from the solver options
    c_nv = c_in;
    opt  = call_options();
    if mod(numel(c_in), 2) ~= 0
        return              % not Name-Value pairs: tools.resolve_options reports it
    end
    lv_call = false(size(c_in));
    for k = 1:2:numel(c_in)
        lv_call(k:k+1) = (ischar(c_in{k}) || isstring(c_in{k})) && any(strcmpi(c_in{k}, ["Plot","Export"]));
    end
    c_call = c_in(lv_call);
    c_nv   = c_in(~lv_call);
    opt    = call_options(c_call{:});
end

function opt = call_options(opt)
    arguments
        opt.Plot   (1,1) logical = false
        opt.Export {mustBeA(opt.Export, ["logical","string","char"])} = false
    end
    if ischar(opt.Export)
        opt.Export = string(opt.Export);
    end
    mustBeScalarOrEmpty(opt.Export);
end
