function sys = get_ss(obj, Type, opt)
% Get the linear model of a Type (ODE / DAE).
%
% Returns the linear model of the result (E dx/dt = A x + B u, y = C x + D u). Format
% chooses its form: "ss" (default) is a descriptor state-space model (dss) with
% StateName, InputName and OutputName and needs the Control System Toolbox; "struct" is
% a struct with the fields A, B, C, D, E, StateName, InputName, OutputName (string
% columns) and needs no toolbox. For the network, "ODE" and "DAE" put the states of the
% global controllers first, then the components. Use StateName to find a state.
%
% - "DAE": the connected model of the result: the bus voltages are algebraic variables
%   (E is zero on their rows and columns), and their equations are the current balance
%   of each bus. Port chooses how each bus is written as a port, the bus variables v
%   (columns) and the balance w (rows): "PI" v = [theta, V], w = [P, Q/V]; "PQ"
%   v = [theta, rho] (rho = log V), w = [P, Q]; "I" v = [Vre, Vim], w = [-Iim, Ire]. The
%   states are named theta, V, rho, Vre, Vim + bus number. Outputs: the dynamic states.
% - "ODE": the DAE with the bus voltages eliminated (SolverLIN.reduce). States: the
%   dynamic states. Inputs: the inputs u. Outputs: the states, in their order, without
%   output names. Port does not apply.
%
% Input and Output select the channels of the model; without them the channels are the
% ones above. The states and their order do not change. Output takes these kinds and
% names, in any mix, and the outputs follow the given order (a repeated one is kept once):
%
% - "x": all states of the model, in the order of sys.StateName (for "DAE", the dynamic
%   states).
% - "V": the bus voltages Vre, Vim of each bus (also in "DAE", whatever the Port).
% - "I": the currents Ire, Iim that the components inject at each bus (Y v).
% - "y": the outputs of the components and of the local and global controllers (rows y
%   and yc of the variable map). An output with the name of a state of its owner is
%   "Y_" + name.
% - a name: Label of net.get_variable_map() for x, V and y, or a name of the kind "I" as
%   in the OutputName of that kind.
%
% Input takes "u" (all inputs) or Labels of the inputs, and the inputs follow the given
% order. An unknown name stops with GUILDA:ResultLIN:UnknownInput; an unknown Output name
% stops with GUILDA:ResultLIN:UnknownOutput.
%
% For a result of comp.get_sys, bus.get_sys, con.get_sys or gc.get_sys, get_ss returns the
% port model (voltages in, currents and outputs out); Input and Output take names of its
% inputs and outputs, and Type and Port do not apply.
%
% Index chooses the section (default res.Index; see ResultLIN), and Time, when given, the
% section whose time rv_t is nearest to it.
%
% Form chooses the view (default res.Form; see ResultLIN): "descriptor", "absorbed"
% (E^-1 in the state rows; every result) or "hessian" (the energy-function form of a
% result of net.get_sys(Form="hessian"), Port "PI" or "PQ" for "DAE"; "ODE" eliminates its
% bus variables, E = -inv(R)). "hessian" stops with GUILDA:ResultLIN:NoHessianForm
% without the form, GUILDA:ResultLIN:HessianPort with Port "I" and
% GUILDA:ResultLIN:NetworkOnly for a port model; "absorbed" with
% GUILDA:ResultLIN:SingularE when the time constants of the states are not invertible.
%
% A section that is not usable (output.sv_issue of the section) stops with an error that repeats the message of the section (output.sv_message):
% GUILDA:ResultLIN:NotFinite for every Type, and GUILDA:ResultLIN:SingularAvv for "ODE",
% which eliminates the bus voltages. "DAE" keeps them and still works.
%
% On a contribution result (sv_target nonempty, see get_contribution) the numbers are of
% the part alone and have no meaning for the whole system.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% sysO = res.get_ss("ODE");                     % ss (Control System Toolbox)
% sysD = res.get_ss("DAE");
% eig(sysO.A, sysO.E)
% sysV = res.get_ss("ODE", Output="V");         % bus voltages as outputs
% sct  = res.get_ss("ODE", Format="struct");    % matrices and names, no toolbox
% sct3 = res.get_ss(Index=3, Format="struct");  % section 3 of a result with time sections
% sctA = res.get_ss("ODE", Form="absorbed", Format="struct");   % E = I
% ```
%
% See also PowerSystemModel.get_sys, SolverLIN.reduce, ResultLIN.Type, ResultLIN.plot_eigenvalue
    arguments (Input)
        obj
        Type (1,1) string {mustBeMember(Type, ["ODE","DAE"])} = obj.Type  % Model: "ODE" (the bus voltages eliminated) or "DAE" (the connected model); the Type of the result when omitted.
        opt.Port (1,1) string {mustBeMember(opt.Port, ["PI","PQ","I"])} = default_port(obj)  % Bus port of "DAE" (v, w): "PI" ([theta,V], [P,Q/V]), "PQ" ([theta,rho], [P,Q]) or "I" ([Vre,Vim], [-Iim,Ire]); options.Port of the result when omitted.
        opt.Input (1,:) string   % Inputs of the model: "u" or Labels. Default: all inputs.
        opt.Output (1,:) string  % Outputs of the model: "x", "V", "I", "y" or names. Default: as described for each algorithm.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["ss","struct"])} = "ss"  % Form of the model: "ss" (dss; needs the Control System Toolbox) or "struct" (A, B, C, D, E and names).
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section of the model (1 ... numel(rv_t)); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}  % [s] Time: the section whose rv_t is nearest; overrides Index.
        opt.Form (1,1) string {mustBeMember(opt.Form, ["descriptor","absorbed","hessian"])} = obj.Form  % View: "descriptor", "absorbed" (E^-1 in the dynamic rows) or "hessian" (energy-function form); res.Form when omitted.
    end
    arguments (Output)
        sys  % Linear model in the form of Format, with StateName, InputName and OutputName.
    end
    if Type == "ODE" && ~isempty(obj.sv_target)
        error(msg("GUILDA:ResultLIN:ContributionDAE", join(obj.sv_target, ", ")))
    end
    % The section
    k = opt.Index;
    if isfield(opt, "Time")
        [~, k] = min(abs(obj.rv_t - opt.Time));
    end
    n_t = numel(obj.c_section);
    if k > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    S = obj.c_section{k};
    s_issue   = obj.output.sv_issue(k);
    s_message = obj.output.sv_message(k);
    sys = to_format(section_model(obj, S, s_issue, s_message, Type, opt), opt.Format);
end


function sys = to_format(sct_sys, s_format)
% The model as a struct or as a dss with the names
    sys = sct_sys;
    if s_format == "ss"
        tools.require_toolbox("control", "ResultLIN.get_ss(Format=""ss"")");
        sys = dss(sct_sys.A, sct_sys.B, sct_sys.C, sct_sys.D, sct_sys.E);
        sys.StateName  = cellstr(sct_sys.StateName);
        sys.InputName  = cellstr(sct_sys.InputName);
        sys.OutputName = cellstr(sct_sys.OutputName);
    end
end
