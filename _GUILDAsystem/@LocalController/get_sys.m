function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
% Linearize the local controller alone.
%
% Linear model of the controller alone: inputs are the bus voltage [Vre; Vim] and the
% inputs sv_u, states are sv_x and outputs are sv_y (an output with the name of a state
% is labelled "Y_" + name). The point is x, V, u (default: the equilibrium).
% Component.get_sys connects it to the component. The model is not changed.
%
% Format chooses the form of the model: "GUILDAorigin" (default) returns a ResultLIN whose
% properties A, B, C, D, E, StateName, InputName and OutputName hold the model
% (E dx/dt = A x + B u, y = C x + D u), with rv_point = [x; V; u] and the Jacobian
% blocks rm_Axx, rm_Axv, rm_Bx and rm_E in the order of the model (tab_variable is
% empty); "struct" returns a struct with the same eight fields; "ss" returns a
% descriptor state-space model (dss) and needs the Control System Toolbox.
%
% At the default point (x, V, I, u all omitted), a controller on a network stops with the
% error GUILDA:LocalController:Stale when net.initialize() is needed (a stale tag of the
% network or the controller). A call with x, V, I, u does not check the stale tags (as
% in Component.get_sys). A controller without a network builds its stale handles first.
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
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct","ss"])} = "GUILDAorigin"   % Form of the model: GUILDAorigin (a ResultLIN), struct or ss (dss; needs the Control System Toolbox).
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
    if nargin <= 1 && ~isempty(owner) && ~isempty(owner.a_Bus) && ~isempty(owner.a_Bus.a_PowerNetwork)
        % default point (nargin does not count the name-value arguments): check the stale tags
        net = owner.a_Bus.a_PowerNetwork;
        if ~isempty(net.sct_stale.input)   % edited inputs: initialize(Method="FixedInput")
            sv_in = unique(net.sct_stale.input, "stable");
            error(msg("GUILDA:LocalController:InputEdited", char(net.s_tag), char(join(sv_in(1:min(end,3)), "; "))))
        end
        sv  = [net.sct_stale.powerflow; net.sct_stale.odefcn; obj.sct_stale.equilibrium; obj.sct_stale.odefcn];
        if ~isempty(sv)
            sv = unique(sv, "stable");
            s_reason = join(sv(1:min(end,3)), "; ");
            if numel(sv) > 3
                s_reason = s_reason + "; ...";
            end
            error(msg("GUILDA:LocalController:Stale", char(obj.s_tag), char(s_reason), "get_sys"))
        end
    elseif isempty(owner) || isempty(owner.a_Bus) || isempty(owner.a_Bus.a_PowerNetwork)
        obj.set_odefcn();    % no network to initialize: stale handles are rebuilt here
    end

    sys = linearize_alone(obj, x, V, I, u, opt.full, opt.tag);

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
                        table(), [x; V; u], sct_block, struct("sct_sys", sys));
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


function sys = linearize_alone(obj, x, V, I, u, l_full, l_tag)
% Linear model of the controller at x, V, I, u: a struct with the fields A, B, C, D, E,
% StateName, InputName, OutputName (string columns), as get_sys with Format "struct".
    arguments (Input)
        obj
        x     (:,1) double    % States.
        V     (:,1) double    % [pu] Voltage [Vre; Vim] of the parent.
        I     (:,1) double    % [pu] Current [Ire; Iim] of the parent (unused; not a port).
        u     (:,1) double    % Inputs.
        l_full (1,1) logical  % Also output the states.
        l_tag  (1,1) logical  % Name the states, inputs and outputs with the controller tag.
    end
    arguments (Output)
        sys   % Struct A, B, C, D, E, StateName, InputName, OutputName of the controller.
    end
    % I is not a port of a controller (c_Iequilibrium is the parent's, [] without a parent)
    if isempty(I)
        I = zeros(2,1);
    end

    nx = numel(obj.sv_x);
    nu = numel(obj.sv_u);
    ny = numel(obj.sv_y);

    Mass = shape(obj.f_Mass(0,x,V,I,u), nx, nx);

    % Same Jacobian contract as SolverODE: f_JacobiDx/Y(t,x,V,I,u)
    [Axx,Bxv,~,Bxu] = obj.f_JacobiDx(0,x,V,I,u);
    [Cyx,Dyv,~,Dyu] = obj.f_JacobiY( 0,x,V,I,u);

    Axx = shape(Axx, nx, nx);  Bxv = shape(Bxv, nx, 2);  Bxu = shape(Bxu, nx, nu);
    Cyx = shape(Cyx, ny, nx);  Dyv = shape(Dyv, ny, 2);  Dyu = shape(Dyu, ny, nu);

    sv_xNames = {obj.sv_x; obj.attach_tag(obj.sv_x)};
    sv_uNames = {obj.sv_u; obj.attach_tag(obj.sv_u)};
    sv_yLabel = obj.sv_y;
    lv_yx     = ismember(sv_yLabel, obj.sv_x);
    sv_yLabel(lv_yx) = "Y_" + sv_yLabel(lv_yx);       % unique names (for tagged labels)
    sv_yNames = {obj.sv_y; obj.attach_tag(sv_yLabel)};

    Vport = {["Vre";"Vim"]; obj.attach_tag(["Vre";"Vim"])};

    OutputNames = {sv_yNames{l_tag+1}; [sv_xNames{l_tag+1};sv_yNames{l_tag+1}]};

    A = Axx;
    B = [Bxv, Bxu];

    C =[eye(l_full*nx,nx); Cyx];
    D =[zeros(l_full*nx,nu+2); [Dyv, Dyu]];

    sys = struct("A", A, "B", B, "C", C, "D", D, "E", Mass, ...
                 "StateName", reshape(string(sv_xNames{l_tag+1}), [], 1), ...
                 "InputName", reshape(string([Vport{l_tag+1}; sv_uNames{l_tag+1}]), [], 1), ...
                 "OutputName", reshape(string(OutputNames{l_full+1}), [], 1));

end


function M = shape(M,r,c)
    % Models may return [] for an empty or all-zero block
    if isempty(M)
        M = zeros(r,c);
    else
        M = reshape(full(M),r,c);
    end
end
