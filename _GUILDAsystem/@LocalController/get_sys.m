function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
% Linearize the local controller alone.
%
% Linear model of the controller alone: inputs are the bus voltage [Vre; Vim] and the
% inputs sv_u, states are sv_x and outputs are sv_y (an output with the name of a state
% is labelled "Y_" + name). The point is x, V, u (default: the equilibrium).
% Component.get_sys connects it to the component. The model is not changed.
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
    end
    arguments (Output)
        sys   % State-space model of the controller with state, input and output names.
    end
    arguments (Output, Repeating)
        varargout   % sys.StateName, sys.InputName and sys.OutputName, kept for old calls.
    end

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

    varargout{1} = sys.StateName;
    varargout{2} = sys.InputName;
    varargout{3} = sys.OutputName;

end
