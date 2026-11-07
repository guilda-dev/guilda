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
% Format chooses the form of the model: "GUILDAorigin" (default) returns a ResultLIN whose
% properties A, B, C, D, E, StateName, InputName and OutputName hold the model
% (E dx/dt = A x + B u, y = C x + D u), with rv_point = [x; u] and the Jacobian blocks
% rm_Axx, rm_Bx and rm_E in the order of the model (tab_variable is empty); "struct"
% returns a struct with the same eight fields; "ss" returns a descriptor state-space
% model (dss) and needs the Control System Toolbox.
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
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct","ss"])} = "GUILDAorigin"   % Form of the model: GUILDAorigin (a ResultLIN), struct or ss (dss; needs the Control System Toolbox).
    end
    arguments (Output)
        sys   % Linear model in the form of Format, with state, input and output names.
    end
    arguments (Output, Repeating)
        varargout   % StateName, InputName and OutputName (cellstr), as on the other layers.
    end
    t0 = tic;

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

    A = full(reshape(Axx,nx,nx));
    B = full(reshape(Bxu,nx,nu));
    C = full(reshape(Cyx,ny,nx));
    D = full(reshape(Dyu,ny,nu));

    E = full(obj.f_Mass(0,x,V,I,u));
    if isempty(E)
        E = eye(nx);
    end

    xNames = obj.attach_tag(obj.sv_x);
    uNames = cellfun(@(s) s.attach_tag(obj.sv_u), a_Comp);
    yNames = cellfun(@(s) s.attach_tag(obj.sv_y), a_Comp);

    sys = struct("A", A, "B", B, "C", C, "D", D, "E", E, ...
                 "StateName", reshape(string(xNames), [], 1), ...
                 "InputName", reshape(string(uNames), [], 1), ...
                 "OutputName", reshape(string(yNames), [], 1));

    varargout{1} = cellstr(sys.StateName);
    varargout{2} = cellstr(sys.InputName);
    varargout{3} = cellstr(sys.OutputName);

    if opt.Format ~= "struct"
        sct_block = struct("Axx", A, "Bx", B, "E", E);
        l_eq = isequal(x, reshape(obj.rv_Xequilibrium, [], 1)) && isequal(u, reshape(obj.rv_Uequilibrium, [], 1));
        sct_output = struct("message", "Linearized the global controller " + obj.s_tag + ".", ...
                            "s_issue", "", "l_equilibrium", l_eq, "s_layer", "GlobalController");
        sys = ResultLIN(obj.a_PowerNetwork, "", struct(), true, sct_output, t0, ...
                        table(), [x; u], sct_block, struct("sct_sys", sys), zeros(0,1));
        if opt.Format == "ss"
            sys = sys.get_ss(Format="ss");
        end
    end
end
