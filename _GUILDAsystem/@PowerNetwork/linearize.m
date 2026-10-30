function [result, flag, output] = linearize(obj, varargin)
% <@Desc>
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
% <@Role> Static Analysis
% <@Summary> Linearize the network; returns a LinearizationResult.
% <@Signatures>
% [
%   "result = net.linearize()",
%   "[result, flag, output] = net.linearize(Name, Value)"
% ]
% <@Parameters>
% [
%   {"Name": "Algorithm", "Type": "\"Kron\" | \"Feedback\" | \"DAE\"", "Description": "Default reduction of result.get_ss() (net.solver_LIN.Algorithm).", "Required": false, "Default": "net.solver_LIN.Algorithm"},
%   {"Name": "NonUnit", "Type": "double row", "Description": "Indices of buses treated as non-unit buses by \"Feedback\" (net.solver_LIN.NonUnit).", "Required": false, "Default": "net.solver_LIN.NonUnit"},
%   {"Name": "Point", "Type": "[] | double vector | cell {sim, t} or {sim, t, Side}", "Description": "Point of the linearization: [] for the equilibrium, the values in the order of net.get_variable_map(), or {sim, t} for the state of a simulation result at time t (sim.get_point(t); {sim, t, \"before\"} at a phase boundary takes the value before the event) (net.solver_LIN.Point).", "Required": false, "Default": "net.solver_LIN.Point"},
%   {"Name": "Plot", "Type": "logical scalar", "Description": "Call result.Plot (eigenvalue map) after the linearization.", "Required": false, "Default": "false"}
% ]
% <@Returns>
% [
%   {"Name": "result", "Type": "LinearizationResult", "Description": "Jacobian blocks, variable map, point and settings."},
%   {"Name": "flag", "Type": "logical", "Description": "True when all Jacobian entries are finite."},
%   {"Name": "output", "Type": "struct", "Description": "output.message describes the outcome; l_equilibrium, n_x, n_v, n_u, rcond_Avv."}
% ]
% <@Examples>
% [
%   "```matlab\nres = net.linearize();\nsys = res.get_ss(\"Kron\");\ntab = res.tab_variable;           % order of res.rm_Axx, res.rm_Axv, ...\nx = res.rv_point;  x(1) = x(1) + 0.1;\nres2 = net.linearize(Point=x);      % at a perturbed state\nres3 = net.linearize(Point={sim, 1.5});\n```"
% ]
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
