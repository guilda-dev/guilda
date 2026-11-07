function [sys, flag, output] = get_sys(obj, varargin)
% Linearize the network and return its linear model.
%
% Linear model of the network: a shortcut of net.linearize(Name, Value) followed by
% result.get_ss(). It takes the same options as net.linearize (Algorithm, Point,
% Coordinate, Plot), the options Input and Output of get_ss, and Format; Algorithm chooses
% the form of the model: "Kron" and "Feedback" eliminate the bus voltages, "DAE" keeps them
% (default net.solver_LIN.Algorithm, "Feedback"). Use net.linearize to keep the unreduced
% Jacobian blocks and the variable map.
%
% Format chooses the form of sys: "GUILDAorigin" (default) is the ResultLIN of the
% linearization, whose properties A, B, C, D, E, StateName, InputName and OutputName hold
% the model of Algorithm with the selected Input and Output (kept in result.options);
% "struct" is a struct with these eight fields; "ss" is a descriptor state-space model (dss)
% and needs the Control System Toolbox. None of them needs a toolbox to linearize.
% v3 returned [sys, lin] with lin a SolverLIN holding the network; the second
% output is now flag.
% When flag is false, this stops with the error of ResultLIN.get_ss, except "DAE"
% with a singular Avv, which returns the model and flag false; net.linearize returns the
% result, whose output.s_issue and output.message give the reason. A Point or a model that
% is not finite stops earlier, with the errors of net.linearize.
%
% Name-Value options:
%
% - `Algorithm` — Form of the model (see ResultLIN.get_ss). Default: net.solver_LIN.Algorithm.
% - `Point` — Point of the linearization (see net.linearize). Default: net.solver_LIN.Point.
% - `Coordinate` — Bus variables of "DAE" (see ResultLIN.get_ss). Default: net.solver_LIN.Coordinate.
% - `Plot` — Plot the eigenvalue map. Default: false.
% - `Input` — Inputs of the model: "u" or Labels (see ResultLIN.get_ss). Default: all inputs.
% - `Output` — Outputs of the model: "x", "V", "I", "y" or names (see ResultLIN.get_ss). Default: as in get_ss, so the outputs follow the states and "Kron" has no output names.
% - `Format` — Form of sys: "GUILDAorigin", "struct" or "ss". Default: "GUILDAorigin".
%
% <@Examples>
% ```matlab
% res = net.get_sys(Algorithm="Kron");
% eig(res.A, res.E)
% resV = net.get_sys(Algorithm="Kron", Output="V");   % resV.C gives the bus voltages
% sct = net.get_sys(Format="struct");
% sys = net.get_sys(Format="ss");                     % Control System Toolbox
% ```
%
% See also PowerNetwork.linearize, ResultLIN.get_ss
%
% <@Group> Linearization
    arguments (Input)
        obj
    end
    arguments (Input, Repeating)
        varargin   % Name-Value options.
    end
    arguments (Output)
        sys      % Linear model in the form of Format, with state, input and output names.
        flag     % True when the result is usable: all Jacobian entries are finite and Avv is invertible.
        output   % As net.linearize; output.result is the ResultLIN.
    end
    [c_nv, opt] = take_call_options(varargin);
    sct_options = obj.solver_LIN.get_options(c_nv);
    c_channel = cell(1,0);
    for str = ["Input","Output"]
        if isfield(opt, str)
            sct_options.(str) = opt.(str);
            c_channel = [c_channel, {str, opt.(str)}]; %#ok<AGROW>
        end
    end

    [result, flag, output] = obj.solver_LIN.solve(obj, sct_options);
    if opt.Plot
        result.Plot();
    end

    if opt.Format == "GUILDAorigin"
        sys = result;
        if isempty(result.StateName)
            result.get_ss(result.options.Algorithm, c_channel{:}, Format="struct");   % stops with the reason, if any
        end
    else
        sys = result.get_ss(result.options.Algorithm, c_channel{:}, Format=opt.Format);
    end
    output.result = result;
end


function [c_nv, opt] = take_call_options(c_in)
% Separates the options of this call (Input, Output, Format, Plot) from those of the solver
    c_nv = c_in;
    opt  = call_options();
    if mod(numel(c_in), 2) ~= 0
        return              % not Name-Value pairs: tools.resolve_options reports it
    end
    lv_call = false(size(c_in));
    for k = 1:2:numel(c_in)
        lv_call(k:k+1) = (ischar(c_in{k}) || isstring(c_in{k})) && any(strcmpi(c_in{k}, ["Input","Output","Format","Plot"]));
    end
    c_call = c_in(lv_call);
    c_nv   = c_in(~lv_call);
    opt    = call_options(c_call{:});
end

function opt = call_options(opt)
    arguments (Input)
        opt.Input (1,:) string
        opt.Output (1,:) string
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct","ss"])} = "GUILDAorigin"
        opt.Plot (1,1) logical = false
    end
end
