function [sys, flag, output] = get_sys(obj, varargin)
% Linearize the network and return the reduced state-space model.
%
% Linear model of the network as a state-space model: a shortcut of
% net.linearize(Name, Value) followed by result.get_ss(). It takes the same options as
% net.linearize (Algorithm, NonUnit, Point, Plot); Algorithm chooses the reduction
% (default net.solver_LIN.Algorithm, "Feedback"). Use net.linearize to keep the
% unreduced Jacobian blocks and the variable map.
% v3 returned [sys, lin] with lin an odeLinearizer holding the network; the second
% output is now flag.
%
% Name-Value options:
%
% - `Algorithm` — Reduction (see LinearizationResult.get_ss). Default: net.solver_LIN.Algorithm.
% - `NonUnit` — Indices of buses treated as non-unit buses by "Feedback". Default: net.solver_LIN.NonUnit.
% - `Point` — Point of the linearization (see net.linearize). Default: net.solver_LIN.Point.
% - `Plot` — Plot the eigenvalue map. Default: false.
%
% <@Examples>
% ```matlab
% sys = net.get_sys(Algorithm="Kron");
% eig(sys.A, sys.E)
% ```
%
% See also PowerNetwork.linearize, LinearizationResult.get_ss
    arguments (Output)
        sys      % Descriptor state-space model (dss) with state, input and output names.
        flag     % True when all Jacobian entries are finite.
        output   % As net.linearize; output.result is the LinearizationResult.
    end
    [result, flag, output] = obj.linearize(varargin{:});
    sys = result.get_ss(result.options.Algorithm);
    output.result = result;
end
