function [sys, varargout] = get_sys(obj, x, V, u, opt)
% Linearize the global controller.
%
% Linear model of the controller alone: the inputs are the voltages of all buses
% [Vre; Vim] of each bus in the order of a_Bus (labelled as in net.get_variable_map())
% and the inputs u, and the outputs are the outputs y, one row for each input they drive.
% The names come from the connection map of the network (net.get_variable_map): an input
% is labelled as the output or state of the unit it observes (Component.get_sys: "Y_" +
% name for an output with the name of a state), and an output has one row for each input
% it drives (a "global" connection), labelled as that input (of a local controller or of
% the unit).
%
% The controller stops with the error GUILDA:GlobalController:Stale when net.initialize()
% is needed (a stale tag of the network or the controller).
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
        V        (:,1) double  = tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], obj.a_PowerNetwork.a_Bus)   % [pu] Voltages of all buses [Vre1; Vim1; ...] (default: the equilibrium).
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
    % connection map of the network)
    a_Comp = obj.controlledUnits;
    n_u = numel(obj.sv_u);
    n_o = numel(obj.sv_y);
    net = obj.a_PowerNetwork;
    lv_in  = obj.iv_obsY > 0 | obj.iv_obsX > 0;
    k_gc = find(cellfun(@(g) g == obj, net.a_GlobalController), 1);
    [tab, ~, c_idxGC, tab_c] = net.get_variable_map();
    iv_gc = c_idxGC{k_gc};
    iv_uc = iv_gc(tab.Kind(iv_gc) == "uc");
    iv_yc = iv_gc(tab.Kind(iv_gc) == "yc");
    [lv_obs, iv_c] = ismember(iv_uc, tab_c.TargetIndex(tab_c.Kind == "observe"));
    sv_src = tab_c.Source(tab_c.Kind == "observe");
    uNames = tab.Label(iv_uc);
    uNames(lv_obs) = sv_src(iv_c(lv_obs));
    tab_g  = tab_c(tab_c.Kind == "global" & ismember(tab_c.SourceIndex, iv_yc), :);
    [~, iv_ord] = sort(tab_g.SourceIndex);       % by output (stable: targets in map order)
    tab_g  = tab_g(iv_ord, :);
    yNames = tab_g.Target;
    iv_row = tab_g.SourceIndex - iv_yc(1) + 1;
    lv_out = ismember(iv_yc, tab_g.SourceIndex);
    for k = 1:numel(a_Comp)
        if ~all(lv_in((k-1)*n_u + (1:n_u))) || ~all(lv_out((k-1)*n_o + (1:n_o)))
            s = a_Comp{k};
            error(msg("GUILDA:GlobalController:GlobalControllerPort", obj.s_tag, join(obj.sv_u, " "), join(obj.sv_y, " "), s.s_tag, class(s), join([s.sv_y(:); s.sv_x(:)], " "), join(s.sv_u, " ")))
        end
    end
    vNames = tools.vcellfun(@(b) reshape(string(b.attach_tag(["Vre";"Vim"])), [], 1), net.a_Bus);

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
               && isequal(V, tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], net.a_Bus));
        sct_output = struct("message", "Linearized the global controller " + obj.s_tag + ".", ...
                            "s_issue", "", "l_equilibrium", l_eq, "s_layer", "GlobalController");
        sys = ResultLIN(obj.a_PowerNetwork, "", struct(), true, sct_output, t0, ...
                        table(), [x; V; u], sct_block, struct("sct_sys", sys));
        if opt.Format == "ss"
            sys = sys.get_ss(Format="ss");
        end
    end
end
