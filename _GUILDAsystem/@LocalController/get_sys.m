function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
% Linearize the local controller alone.
%
% Linear model of the controller alone: inputs are the bus voltage [Vre; Vim] and the
% inputs sv_u, states are sv_x and outputs are sv_y (an output with the name of a state
% is labelled "Y_" + name). The point is x, V, u (default: the equilibrium).
% Component.get_sys connects it to the component. The model is not changed.
%
% Format chooses the form of the model: "ResultLIN" (default) returns a ResultLIN whose
% properties A, B, C, D, E, StateName, InputName and OutputName hold the model
% (E dx/dt = A x + B u, y = C x + D u), with rv_point = [x; V; u] and the Jacobian
% blocks rm_Axx, rm_Axv, rm_Bx and rm_E in the order of the model (tab_variable is
% empty); "struct" returns a struct with the same eight fields; "ss" returns a
% descriptor state-space model (dss) and needs the Control System Toolbox.
%
% A controller on a network stops with the error GUILDA:LocalController:Stale
% when net.initialize() is needed (a stale tag of the network or the controller); a controller without a network builds its stale
% handles first.
%
% See also Component.get_sys
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        x        (:,1) double  = obj.rv_Xequilibrium   % States (default: the equilibrium).
        V        (:,1) double  = [real(obj.c_Vequilibrium);imag(obj.c_Vequilibrium)]   % [pu] Voltage [Vre; Vim] of the parent.
        I        (:,1) double  = [real(obj.c_Iequilibrium);imag(obj.c_Iequilibrium)]   % [pu] Current [Ire; Iim] of the parent (unused; not a port).
        u        (:,1) double  = obj.rv_Uequilibrium   % Inputs (default: the equilibrium).
        opt.full (1,1) logical = false     % Also output the states.
        opt.tag  (1,1) logical = true   % Name the states, inputs and outputs with the controller tag.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["ResultLIN","struct","ss"])} = "ResultLIN"   % Form of the model: ResultLIN, struct or ss (dss; needs the Control System Toolbox).
    end
    arguments (Output)
        sys   % Linear model of the controller in the form of Format, with state, input and output names.
    end
    arguments (Output, Repeating)
        varargout   % StateName, InputName and OutputName (cellstr), kept for old calls.
    end
    t0 = tic;

    owner = obj.a_Component;
    while isa(owner, "LocalController")   % a controller may be attached under another one
        owner = owner.a_Component;
    end
    if ~isempty(owner) && ~isempty(owner.a_Bus) && ~isempty(owner.a_Bus.a_PowerNetwork)
        net = owner.a_Bus.a_PowerNetwork;
        sv  = [net.sct_stale.powerflow; net.sct_stale.odefcn; obj.sct_stale.equilibrium; obj.sct_stale.odefcn];
        if ~isempty(sv)
            sv = unique(sv, "stable");
            s_reason = join(sv(1:min(end,3)), "; ");
            if numel(sv) > 3
                s_reason = s_reason + "; ...";
            end
            error(msg("GUILDA:LocalController:Stale", char(obj.s_tag), char(s_reason), "get_sys"))
        end
    elseif ~isempty(obj.sct_stale.odefcn) || ~isequal(obj.r_odefcnHz, obj.get_Hz())
        obj.build_odefcn();    % no network to initialize: the handles are built here
    end

    sys = obj.get_sys_alone(x, V, I, u, "full", opt.full, "tag", opt.tag);

    varargout{1} = cellstr(sys.StateName);
    varargout{2} = cellstr(sys.InputName);
    varargout{3} = cellstr(sys.OutputName);

    if opt.Format ~= "struct"
        sct_block = struct("Axx", sys.A, "Axv", sys.B(:,1:2), "Bx", sys.B(:,3:end), "E", sys.E);
        l_eq = isequal(x, reshape(obj.rv_Xequilibrium, [], 1)) && isequal(u, reshape(obj.rv_Uequilibrium, [], 1)) ...
               && isequal(V, [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]);
        sct_output = struct("message", "Linearized the local controller " + obj.s_tag + ".", ...
                            "s_issue", "", "l_equilibrium", l_eq, "s_layer", "LocalController");
        sys = ResultLIN(net_of(owner), "", struct(), true, sct_output, t0, ...
                        table(), [x; V; u], sct_block, struct("sct_sys", sys), zeros(0,1));
        if opt.Format == "ss"
            sys = sys.get_ss(Format="ss");
        end
    end
end


function net = net_of(owner)
% Network of the component that the controller belongs to, or []
    net = [];
    if ~isempty(owner) && ~isempty(owner.a_Bus)
        net = owner.a_Bus.a_PowerNetwork;
    end
end
