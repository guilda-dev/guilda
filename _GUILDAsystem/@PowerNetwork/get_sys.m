function [sys, flag, output] = get_sys(obj, varargin)
% <@Desc>
% Linear model of the network as a state-space model: a shortcut of
% net.linearize(Name, Value) followed by result.get_ss(). It takes the same options as
% net.linearize (Algorithm, NonUnit, Point, Plot); Algorithm chooses the reduction
% (default net.solver_LIN.Algorithm, "Feedback"). Use net.linearize to keep the
% unreduced Jacobian blocks and the variable map.
% v3 returned [sys, lin] with lin an odeLinearizer holding the network; the second
% output is now flag.
% <@Role> Static Analysis
% <@Summary> Linearize the network; returns the reduced state-space model.
% <@Signatures>
% [
%   "sys = net.get_sys()",
%   "[sys, flag, output] = net.get_sys(Name, Value)"
% ]
% <@Parameters>
% [
%   {"Name": "Algorithm", "Type": "\"Kron\" | \"Feedback\" | \"DAE\"", "Description": "Reduction (see LinearizationResult.get_ss).", "Required": false, "Default": "net.solver_LIN.Algorithm"},
%   {"Name": "NonUnit", "Type": "double row", "Description": "Indices of buses treated as non-unit buses by \"Feedback\".", "Required": false, "Default": "net.solver_LIN.NonUnit"},
%   {"Name": "Point", "Type": "[] | double vector | cell {sim, t}", "Description": "Point of the linearization (see net.linearize).", "Required": false, "Default": "net.solver_LIN.Point"},
%   {"Name": "Plot", "Type": "logical scalar", "Description": "Plot the eigenvalue map.", "Required": false, "Default": "false"}
% ]
% <@Returns>
% [
%   {"Name": "sys", "Type": "ss", "Description": "Descriptor state-space model (dss) with state, input and output names."},
%   {"Name": "flag", "Type": "logical", "Description": "True when all Jacobian entries are finite."},
%   {"Name": "output", "Type": "struct", "Description": "As net.linearize; output.result is the LinearizationResult."}
% ]
% <@Examples>
% [
%   "```matlab\nsys = net.get_sys(Algorithm=\"Kron\");\neig(sys.A, sys.E)\n```"
% ]
    [result, flag, output] = obj.linearize(varargin{:});
    sys = result.get_ss(result.options.Algorithm);
    output.result = result;
end
