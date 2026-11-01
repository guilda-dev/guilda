function [sys, flag, output] = get_sys(obj, varargin)
% Linearize the network and return a state-space model.
%
% Linear model of the network as a state-space model: a shortcut of
% net.linearize(Name, Value) followed by result.get_ss(). It takes the same options as
% net.linearize (Algorithm, NonUnit, Point, Coordinate, Plot) and the options Input and Output
% of get_ss; Algorithm chooses the form of the model: "Kron" and "Feedback" eliminate the
% bus voltages, "DAE" keeps them (default net.solver_LIN.Algorithm, "Feedback"). Use
% net.linearize to keep the unreduced Jacobian blocks and the variable map.
% v3 returned [sys, lin] with lin an odeLinearizer holding the network; the second
% output is now flag.
% When flag is false, this stops with the error of LinearizationResult.get_ss, except "DAE"
% with a singular Avv, which returns the model and flag false; net.linearize returns the
% result, whose output.str_issue and output.message give the reason. A Point or a model that
% is not finite stops earlier, with the errors of net.linearize.
%
% Name-Value options:
%
% - `Algorithm` — Form of the model (see LinearizationResult.get_ss). Default: net.solver_LIN.Algorithm.
% - `NonUnit` — Indices of buses treated as non-unit buses by "Feedback". Default: net.solver_LIN.NonUnit.
% - `Point` — Point of the linearization (see net.linearize). Default: net.solver_LIN.Point.
% - `Coordinate` — Bus variables of "DAE" (see LinearizationResult.get_ss). Default: net.solver_LIN.Coordinate.
% - `Plot` — Plot the eigenvalue map. Default: false.
% - `Input` — Inputs of the model: "u" or Labels (see LinearizationResult.get_ss). Default: all inputs.
% - `Output` — Outputs of the model: "x", "V", "I", "y" or names (see LinearizationResult.get_ss). Default: as in get_ss, so the outputs follow the states and "Kron" has no output names.
%
% <@Examples>
% ```matlab
% sys = net.get_sys(Algorithm="Kron");
% eig(sys.A, sys.E)
% sysV = net.get_sys(Algorithm="Kron", Output="V");
% ```
%
% See also PowerNetwork.linearize, LinearizationResult.get_ss
    arguments (Output)
        sys      % Descriptor state-space model (dss) with state, input and output names.
        flag     % True when the result is usable: all Jacobian entries are finite and Avv is invertible.
        output   % As net.linearize; output.result is the LinearizationResult.
    end
    [c_nv, c_channel] = take_channel_options(varargin);
    [result, flag, output] = obj.linearize(c_nv{:});
    sys = result.get_ss(result.options.Algorithm, c_channel{:});
    output.result = result;
end


function [c_nv, c_channel] = take_channel_options(c_in)
% Separates the options of get_ss (Input, Output) from those of net.linearize
    c_nv      = c_in;
    c_channel = cell(1,0);
    if mod(numel(c_in), 2) ~= 0
        return              % not Name-Value pairs: tools.resolve_options reports it
    end
    lv_channel = false(size(c_in));
    for k = 1:2:numel(c_in)
        lv_channel(k:k+1) = (ischar(c_in{k}) || isstring(c_in{k})) && any(strcmpi(c_in{k}, ["Input","Output"]));
    end
    c_channel = c_in(lv_channel);
    c_nv      = c_in(~lv_channel);
end
