function [sys, varargout] = get_sys(obj, x, V, u, opt)
% Linearize the global controller.
%
% Linear model of the controller alone: the inputs are the voltages of all buses
% [Vre; Vim] of each bus in the order of a_Bus (labelled as in net.get_variable_map())
% and the inputs u, and the outputs are the outputs y, one row for each input they drive.
% An input that reads an output of a unit is labelled as that output in the model of the
% unit (Component.get_sys: "Y_" + name when the unit has a state of that name), an input
% that reads a state as the state. An output that goes to local controllers of the unit has
% one row for each of their inputs (labelled with the controller tag), otherwise one row
% labelled as the input of the unit.
%
% A controller on a network stops with the error GUILDA:GlobalController:Stale
% when net.initialize() is needed (a stale tag of the network or the controller); a controller without a network builds its stale
% handles first.
% A controlled unit without the outputs or states sv_u, or an output sv_y that drives no
% input of the unit or its local controllers, stops with the error
% GUILDA:GlobalController:GlobalControllerPort.
%
% Format chooses the form of the model: "GUILDAorigin" (default) returns a ResultLIN whose
% properties A, B, C, D, E, StateName, InputName and OutputName hold the model
% (E dx/dt = A x + B [V; u], y = C x + D [V; u]), with rv_point = [x; V; u] and the Jacobian
% blocks rm_Axx, rm_Axv, rm_Bx and rm_E in the order of the model (tab_variable is empty);
% "struct" returns a struct with the same eight fields; "ss" returns a descriptor
% state-space model (dss) and needs the Control System Toolbox.
%
% See also GlobalController.get_hessian, PowerNetwork.get_sys
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        x        (:,1) double  = obj.rv_Xequilibrium   % States (default: the equilibrium).
        V        (:,1) double  = tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], obj.controlledUnits{1}.a_Bus.a_PowerNetwork.a_Bus)   % [pu] Voltages of all buses [Vre1; Vim1; ...] (default: the equilibrium).
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

    % Names of the inputs and of the outputs, one row for each input they drive (the
    % routing of SolverODE.get_units)
    a_Comp = obj.controlledUnits;
    n_u = numel(obj.sv_u);
    uNames = strings(0,1);
    yNames = strings(0,1);
    iv_row = zeros(0,1);
    for k = 1:numel(a_Comp)
        s = a_Comp{k};
        c_LC = cell(0,1);                       % its local controllers, depth first
        c_todo = s.a_LocalController(:);
        while ~isempty(c_todo)
            c_LC = [c_LC; c_todo(1)]; %#ok<AGROW>
            c_todo = [c_todo{1}.a_LocalController(:); c_todo(2:end)];
        end
        iv_k = (k-1)*n_u + (1:n_u)';
        sv_name = obj.sv_u(:);
        lv_Y = obj.iv_obsY(iv_k) > 0;
        sv_name(lv_Y & ismember(sv_name, s.sv_x)) = "Y_" + sv_name(lv_Y & ismember(sv_name, s.sv_x));
        lv_missing = ~(lv_Y | obj.iv_obsX(iv_k) > 0);
        for m = 1:numel(obj.sv_y)
            lv_LC = cellfun(@(c) any(c.sv_u == obj.sv_y(m)), c_LC);
            if any(lv_LC)
                sv_to = reshape(string(cellfun(@(c) c.attach_tag(obj.sv_y(m)), c_LC(lv_LC))), [], 1);
            elseif any(s.sv_u == obj.sv_y(m))
                sv_to = string(s.attach_tag(obj.sv_y(m)));
            else
                lv_missing(end+1) = true; %#ok<AGROW>
                sv_to = strings(0,1);
            end
            yNames = [yNames; sv_to];                                            %#ok<AGROW>
            iv_row = [iv_row; repmat((k-1)*numel(obj.sv_y) + m, numel(sv_to), 1)]; %#ok<AGROW>
        end
        if any(lv_missing)
            error(msg("GUILDA:GlobalController:GlobalControllerPort", obj.s_tag, join(obj.sv_u, " "), join(obj.sv_y, " "), s.s_tag, class(s), join([s.sv_y(:); s.sv_x(:)], " "), join(s.sv_u, " ")))
        end
        uNames = [uNames; reshape(string(s.attach_tag(sv_name)), [], 1)]; %#ok<AGROW>
    end
    net_units = a_Comp{1}.a_Bus.a_PowerNetwork;
    vNames = tools.vcellfun(@(b) reshape(string(b.attach_tag(["Vre";"Vim"])), [], 1), net_units.a_Bus);

    if ~isempty(obj.a_PowerNetwork)
        net = obj.a_PowerNetwork;
        if ~isempty(net.sct_stale.input)   % edited inputs: initialize(Method="FixedInput")
            sv_in = unique(net.sct_stale.input, "stable");
            error(msg("GUILDA:GlobalController:InputEdited", char(net.s_tag), char(join(sv_in(1:min(end,3)), "; "))))
        end
        sv  = [net.sct_stale.powerflow; net.sct_stale.odefcn; obj.sct_stale.equilibrium; obj.sct_stale.odefcn];
        if ~isempty(sv)
            sv = unique(sv, "stable");
            s_reason = join(sv(1:min(end,3)), "; ");
            if numel(sv) > 3
                s_reason = s_reason + "; ...";
            end
            error(msg("GUILDA:GlobalController:Stale", char(obj.s_tag), char(s_reason)))
        end
    else
        obj.set_odefcn();    % no network to initialize: stale handles are rebuilt here
    end

    % Same Jacobian contract as SolverODE: f_JacobiDx/Y(t,x,V,u); a model may return []
    % for an all-zero block
    nx = numel(x);
    nv = numel(V);
    nu = numel(u);
    ny = numel(a_Comp)*numel(obj.sv_y);
    [Axx,Bxv,Bxu] = obj.f_JacobiDx(0,x,V,u);
    [Cyx,Dyv,Dyu] = obj.f_JacobiY( 0,x,V,u);
    c_blk = {Axx,nx,nx; Bxv,nx,nv; Bxu,nx,nu; Cyx,ny,nx; Dyv,ny,nv; Dyu,ny,nu};
    for m = 1:size(c_blk,1)
        if isempty(c_blk{m,1})
            c_blk{m,1} = zeros(c_blk{m,2}, c_blk{m,3});
        end
        c_blk{m,1} = full(reshape(c_blk{m,1}, c_blk{m,2}, c_blk{m,3}));
    end
    [A, Bv, Bu, C, Dv, Du] = c_blk{:,1};

    E = full(obj.f_Mass(0,x,V,u));
    if isempty(E)
        E = eye(nx);
    end

    xNames = obj.attach_tag(obj.sv_x);

    sys = struct("A", A, "B", [Bv, Bu], "C", C(iv_row,:), "D", [Dv(iv_row,:), Du(iv_row,:)], "E", E, ...
                 "StateName", reshape(string(xNames), [], 1), ...
                 "InputName", [vNames; uNames], ...
                 "OutputName", yNames);

    varargout{1} = cellstr(sys.StateName);
    varargout{2} = cellstr(sys.InputName);
    varargout{3} = cellstr(sys.OutputName);

    if opt.Format ~= "struct"
        sct_block = struct("Axx", A, "Axv", Bv, "Bx", Bu, "E", E);
        l_eq = isequal(x, reshape(obj.rv_Xequilibrium, [], 1)) && isequal(u, reshape(obj.rv_Uequilibrium, [], 1)) ...
               && isequal(V, tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], net_units.a_Bus));
        sct_output = struct("message", "Linearized the global controller " + obj.s_tag + ".", ...
                            "s_issue", "", "l_equilibrium", l_eq, "s_layer", "GlobalController");
        sys = ResultLIN(obj.a_PowerNetwork, "", struct(), true, sct_output, t0, ...
                        table(), [x; V; u], sct_block, struct("sct_sys", sys));
        if opt.Format == "ss"
            sys = sys.get_ss(Format="ss");
        end
    end
end
