function [result, flag, output] = linearize(obj, varargin)
% Linearize the network and return a LinearizationResult.
%
% Linearizes the network and returns the unreduced linear DAE (the Jacobian blocks in
% the order of net.get_variable_map()) as a LinearizationResult; result.get_ss(Algorithm)
% gives a reduced state-space model. The settings are the stored defaults of
% net.solver_LIN; Name-Value options override them for this call only (net.solver_LIN is
% not changed). Neither is the network: a Point away from the equilibrium is used only
% for this call, and NonUnit is not stored on the buses.
% The network must be initialized (net.initialize()); otherwise this stops with the
% error of check_edit that asks for it.
% Accepted options are the names in odeLinearizer.OptionMap plus Plot; any other name
% stops with GUILDA:resolve_options:UnknownName.
%
% Name-Value options:
%
% - `Algorithm` — Default reduction of result.get_ss() (net.solver_LIN.Algorithm).
% - `NonUnit` — Indices of buses treated as non-unit buses by "Feedback" (net.solver_LIN.NonUnit).
% - `Point` — Point of the linearization: [] for the equilibrium, the values in the order
%   of net.get_variable_map(), or {sim, t} for the state of a simulation result at time t
%   (sim.get_point(t); {sim, t, "before"} at a phase boundary takes the value before the
%   event) (net.solver_LIN.Point).
% - `Plot` — Call result.Plot (eigenvalue map) after the linearization. Default: false.
%
% <@Examples>
% ```matlab
% res = net.linearize();
% sys = res.get_ss("Kron");
% tab = res.tab_variable;           % order of res.rm_Axx, res.rm_Axv, ...
% x = res.rv_point;  x(1) = x(1) + 0.1;
% res2 = net.linearize(Point=x);      % at a perturbed state
% res3 = net.linearize(Point={sim, 1.5});
% ```
%
% See also PowerNetwork.get_sys, PowerNetwork.get_variable_map, LinearizationResult, odeLinearizer
    arguments (Output)
        result   % Jacobian blocks, variable map, point and settings.
        flag     % True when all Jacobian entries are finite.
        output   % output.message describes the outcome; l_equilibrium, n_x, n_v, n_u, rcond_Avv.
    end
    [c_nv, opt] = take_call_options(varargin);
    s_options   = obj.solver_LIN.get_options(c_nv);

    [result, flag, output] = obj.solver_LIN.solve(obj, s_options);

    if opt.Plot
        result.Plot();
    end
end


function [c_nv, opt] = take_call_options(c_in)
% Separates the options of this call (Plot) from the solver options
    c_nv = c_in;
    opt  = struct("Plot", false);
    if mod(numel(c_in), 2) ~= 0
        return              % not Name-Value pairs: tools.resolve_options reports it
    end
    lv_call = false(size(c_in));
    for k = 1:2:numel(c_in)
        lv_call(k:k+1) = (ischar(c_in{k}) || isstring(c_in{k})) && strcmpi(c_in{k}, "Plot");
    end
    c_call = c_in(lv_call);
    c_nv   = c_in(~lv_call);
    opt    = call_options(c_call{:});
end

function opt = call_options(opt)
    arguments
        opt.Plot (1,1) logical = false
    end
end
