function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
% Linearize the global controller.
%
% The inputs are the outputs of the controlled units and the outputs are the
% controller outputs that feed them; the V and I ports are not used.
%
% A controller on a network stops with the error GUILDA:GlobalController:Stale
% when net.initialize() is needed (a stale tag of the network or the controller); a controller without a network builds its stale
% handles first.
% A controlled unit without the states sv_u or the inputs sv_y stops with the
% error GUILDA:GlobalController:GlobalControllerPort.
%
% See also GlobalController.get_hessian, PowerNetwork.get_sys
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        x        (:,1) double  = obj.rv_Xequilibrium   % States (default: the equilibrium).
        V        (:,1) double  = zeros(2,1)   % Not a port: zeros(2,1).
        I        (:,1) double  = zeros(2,1)   % Not a port: zeros(2,1).
        u        (:,1) double  = obj.rv_Uequilibrium   % Inputs (default: the equilibrium).
        opt.full (1,1) logical = false  % Ignored; kept for old calls.
    end
    arguments (Output)
        sys   % Descriptor state-space model (dss) with state, input and output names.
    end
    arguments (Output, Repeating)
        varargout   % sys.StateName, sys.InputName and sys.OutputName, as on the other layers.
    end

    a_Comp = obj.controlledUnits;
    for k = 1:numel(a_Comp)
        s = a_Comp{k};
        if ~all(ismember(obj.sv_u, s.sv_x)) || ~all(ismember(obj.sv_y, s.sv_u))
            error(msg("GUILDA:GlobalController:GlobalControllerPort", obj.s_tag, join(obj.sv_u, " "), join(obj.sv_y, " "), s.s_tag, class(s), join(s.sv_x, " "), join(s.sv_u, " ")))
        end
    end

    if ~isempty(obj.a_PowerNetwork)
        net = obj.a_PowerNetwork;
        sv  = [net.sct_stale.powerflow; net.sct_stale.odefcn; obj.sct_stale.equilibrium; obj.sct_stale.odefcn];
        if ~isempty(sv)
            sv = unique(sv, "stable");
            s_reason = join(sv(1:min(end,3)), "; ");
            if numel(sv) > 3
                s_reason = s_reason + "; ...";
            end
            error(msg("GUILDA:GlobalController:Stale", char(obj.s_tag), char(s_reason)))
        end
    elseif ~isempty(obj.sct_stale.odefcn) || ~isequal(obj.r_odefcnHz, obj.get_Hz())
        obj.build_odefcn();    % no network to initialize: the handles are built here
    end

    % Same Jacobian contract as SolverODE: f_JacobiDx/Y(t,x,V,I,u).
    % A global controller has no V port, so only the u columns are used.
    nx = numel(x);
    nu = numel(u);
    [Axx,~,~,Bxu] = obj.f_JacobiDx(0,x,V,I,u);
    [Cyx,~,~,Dyu] = obj.f_JacobiY( 0,x,V,I,u);
    ny = size(Cyx,1);

    A = reshape(Axx,nx,nx);
    B = reshape(Bxu,nx,nu);
    C = reshape(Cyx,ny,nx);
    D = reshape(Dyu,ny,nu);

    E = obj.f_Mass(0,x,V,I,u);

    sys = dss(A,B,C,D,E);

    xNames = obj.attach_tag(obj.sv_x);
    uNames = cellfun(@(s) s.attach_tag(obj.sv_u), a_Comp);
    yNames = cellfun(@(s) s.attach_tag(obj.sv_y), a_Comp);

    sys.StateName  = xNames;
    sys.InputName  = uNames;
    sys.OutputName = yNames;

    varargout{1} = sys.StateName;
    varargout{2} = sys.InputName;
    varargout{3} = sys.OutputName;
end
