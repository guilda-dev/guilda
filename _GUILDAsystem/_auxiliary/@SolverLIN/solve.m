function [result, flag, output] = solve(obj, net, sct_options)
% Linearize the network with the given settings.
%
% Linearizes the network net at the point sct_options.Point and returns the unreduced DAE
% (the Jacobian blocks in the order of net.get_variable_map()) as a ResultLIN.
% The solver and the network are only read: nothing is written back into them.
% Called by net.linearize; calling it
% directly is for advanced use. Like net.linearize, it stops with the error
% GUILDA:SolverLIN:Stale when net.initialize() is needed. A Point with NaN or Inf stops
% with GUILDA:SolverLIN:PointNotFinite, and a
% model that is not finite at the point with GUILDA:SolverLIN:JacobianNotFinite.
%
% Point sets the variables only: the network is the one of the model, so a point inside a
% fault is combined with the admittance matrix without the fault. The call reports such a
% point (zero bus voltage) with an INFO message and in output.message; flag does not
% depend on it.
    arguments (Input)
        obj % Solver (net.solver_LIN).
        net % Initialized network.
        sct_options (1,1) struct = obj.get_options() % Effective settings (output of get_options).
    end
    arguments (Output)
        result % Jacobian blocks, variable map, point and settings.
        flag % True when the result is usable: all Jacobian entries are finite and Avv is invertible.
        output % message, s_issue ("", "NotFinite" or "SingularAvv"), l_equilibrium, n_x, n_v, n_u, rcond_Avv, sv_faultBus, s_layer ("PowerNetwork").
    end
    t0 = tic;
    a_bus = net.a_Bus;
    a_gc  = net.a_GlobalController;

    % Stale tags of the network, the components, their local controllers (depth first, as
    % a list) and the global controllers: net.initialize() is needed when any is not empty
    if ~isempty(net.sct_stale.input)   % edited inputs: initialize(Method="FixedInput")
        sv_in = unique(net.sct_stale.input, "stable");
        error(msg("GUILDA:SolverLIN:InputEdited", char(net.s_tag), char(join(sv_in(1:min(end,3)), "; "))))
    end
    sv    = [net.sct_stale.powerflow; net.sct_stale.odefcn];
    c_obj = tools.cellfun(@(b) b.a_Component, a_bus);
    c_obj = [vertcat(cell(0,1), c_obj{:}); a_gc];
    k = 1;
    while k <= numel(c_obj)
        sv = [sv; c_obj{k}.sct_stale.equilibrium; c_obj{k}.sct_stale.odefcn]; %#ok<AGROW>
        if ~isa(c_obj{k}, "GlobalController")
            c_obj = [c_obj; c_obj{k}.a_LocalController(:)]; %#ok<AGROW>
        end
        k = k + 1;
    end
    if ~isempty(sv)
        sv = unique(sv, "stable");
        s_reason = join(sv(1:min(end,3)), "; ");
        if numel(sv) > 3
            s_reason = s_reason + "; ...";
        end
        error(msg("GUILDA:SolverLIN:Stale", char(net.s_tag), char(s_reason)))
    end
    n_bus = numel(a_bus);
    v3_nonunit_range(sct_options, n_bus);        % COMPAT(v3)

    % The variables of the linearization: the leading rows x, Vre, Vim, u of the map (the
    % controller inputs uc are eliminated by the models of the layers)
    [tab_map, c_idxBus, c_idxGC] = net.get_variable_map();
    n_lin    = sum(ismember(tab_map.Kind, ["x","Vre","Vim","u"]));
    tab_map  = tab_map(1:n_lin,:);
    c_idxBus = cellfun(@(iv) iv(iv <= n_lin), c_idxBus, 'UniformOutput', false);
    c_idxGC  = cellfun(@(iv) iv(iv <= n_lin), c_idxGC, 'UniformOutput', false);
    [rv_point, l_eq] = SolverLIN.point_vector(net, sct_options.Point);
    lv_bad = ~isfinite(rv_point);
    if any(lv_bad)
        error(msg("GUILDA:SolverLIN:PointNotFinite", list_labels(tab_map.Label(lv_bad))))
    end

    % Global controller models at the point: their inputs are the bus voltages and outputs
    % or states of the components, and their outputs are named by the inputs they drive
    % (inputs of components, or of local controllers: sv_l)
    c_sysGC = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        if l_eq
            f_sys = @() a_gc{k}.get_sys("Format","struct");
        else
            f_sys = @() a_gc{k}.get_sys(rv_point(c_idxGC{k}), rv_point(tab_map.Kind == "Vre" | tab_map.Kind == "Vim"), ...
                                        gc_input(a_gc{k}, tab_map, rv_point), "Format","struct");
        end
        c_sysGC{k} = model_at_point(f_sys, "global controller " + a_gc{k}.s_tag);
    end
    sv_l = tools.vcellfun(@(S) reshape(string(S.OutputName), [], 1), c_sysGC);
    sv_l = unique(string(sv_l(~ismember(string(sv_l), tab_map.Label(tab_map.Kind == "u")))), "stable");

    % Bus models (V -> I) at the point. The network model has the bus voltages and the
    % component inputs (Kind "u" of the variable map) as inputs, and the currents as
    % outputs: the other inputs and outputs of the controllers in the bus models are left
    % out, except the inputs of local controllers that a global controller drives (c_sysL).
    c_sysBus = cell(n_bus,1);
    c_sysY   = cell(n_bus,1);
    c_sysL   = cell(n_bus,1);
    for i = 1:n_bus
        if l_eq
            f_sys = @() a_bus{i}.get_sys("port","V2I","Format","struct");
        else
            f_sys = @() a_bus{i}.get_sys("port","V2I","Point",rv_point(c_idxBus{i}),"Format","struct");
        end
        sys_i = model_at_point(f_sys, "bus " + a_bus{i}.s_tag);
        sv_u = tab_map.Label(tab_map.Kind == "u" & tab_map.Bus == string(a_bus{i}.s_tag));
        [~, iv_u] = ismember(sv_u, sys_i.InputName);
        c_sysBus{i} = channels(sys_i, 1:2, [1, 2, reshape(iv_u, 1, [])]);
        c_sysY{i}   = channels(sys_i, 3:numel(sys_i.OutputName), [1, 2, reshape(iv_u, 1, [])]);
        c_sysL{i}   = channels(sys_i, 1:numel(sys_i.OutputName), reshape(find(ismember(sys_i.InputName, sv_l)), 1, []));
    end

    cm_Y = net.get_admittance_matrix.Variables;
    cv_V = tools.vec2complex(rv_point(tab_map.Kind == "Vre" | tab_map.Kind == "Vim"));

    % Unreduced DAE in the order of the variable map:
    %   E dx/dt = Axx x + Axv v + Bx u,   0 = Avx x + Avv v + Bv u,
    %   v = [Vre1; Vim1; Vre2; ...], 0 = (Y v - I of the components) of each bus
    Axx = tools.dcellfun(@(S) S.A         , c_sysBus);
    Axv = tools.dcellfun(@(S) S.B(:,1:2)  , c_sysBus);
    Cix = tools.dcellfun(@(S) S.C         , c_sysBus);
    Div = tools.dcellfun(@(S) S.D(:,1:2)  , c_sysBus);
    Bxu = tools.dcellfun(@(S) S.B(:,3:end), c_sysBus);
    Diu = tools.dcellfun(@(S) S.D(:,3:end), c_sysBus);
    Ex  = tools.dcellfun(@(S) S.E         , c_sysBus);

    sv_x  = tools.cellfun(@(S) string(S.StateName), c_sysBus);
    sv_x  = vertcat(strings(0,1), sv_x{:});
    sv_u  = tab_map.Label(tab_map.Kind == "u");
    % The outputs of the bus models depend on the global controllers as the currents do
    Cyx = tools.dcellfun(@(S) S.C         , c_sysY);
    Dyv = tools.dcellfun(@(S) S.D(:,1:2)  , c_sysY);
    Dyu = tools.dcellfun(@(S) S.D(:,3:end), c_sysY);
    sv_v = tab_map.Label(tab_map.Kind == "Vre" | tab_map.Kind == "Vim");
    sv_yBus = tools.vcellfun(@(S) reshape(string(S.OutputName), [], 1), c_sysY);
    % Inputs of local controllers driven by global controllers: their columns in the states,
    % the currents and the outputs of the bus models (rows I of each bus, then its outputs)
    c_B  = tools.cellfun(@(S) S.B, c_sysL);
    c_Di = tools.cellfun(@(S) S.D(1:2,:), c_sysL);
    c_Dy = tools.cellfun(@(S) S.D(3:end,:), c_sysL);
    Bxl = blkdiag(zeros(0,0), c_B{:});
    Dl  = [blkdiag(zeros(0,0), c_Di{:}); blkdiag(zeros(0,0), c_Dy{:})];
    sv_lBus = tools.vcellfun(@(S) reshape(string(S.InputName), [], 1), c_sysL);
    n_i = size(Cix,1);
    sct_net = struct("Axx", Axx, "Axv", Axv, "Bxu", Bxu, "Bxl", Bxl, "C", [Cix; Cyx], "Dv", [Div; Dyv], ...
                     "Du", [Diu; Dyu], "Dl", Dl, "E", Ex, "sv_x", sv_x, "sv_v", sv_v, "sv_u", sv_u, ...
                     "sv_l", string(sv_lBus), "sv_y", string(sv_yBus), "Cy", Cyx, "Dyv", Dyv);
    [sct_net, sv_z] = add_global_controllers(c_sysGC, a_gc, sct_net);
    [Axx, Axv, Bxu, Ex] = deal(sct_net.Axx, sct_net.Axv, sct_net.Bxu, sct_net.E);
    Cyx = sct_net.C(n_i+1:end,:);
    Cix = sct_net.C(1:n_i,:);
    Dyv = sct_net.Dv(n_i+1:end,:);
    Div = sct_net.Dv(1:n_i,:);

    if ~isequal([sv_x; sv_z], tab_map.Label(tab_map.Kind == "x"))
        error(msg("GUILDA:SolverLIN:VariableMap"))
    end

    Ymat = tools.complex2matrix(cm_Y);
    sct_block = struct( ...
        "Axx", Axx, "Axv", Axv, "Bx", Bxu, ...
        "Avx", -Cix, "Avv", Ymat - Div, "Bv", -Diu, ...
        "E", Ex);
    sv_I = tools.cellfun(@(S) string(S.OutputName), c_sysBus);
    sv_y = tools.cellfun(@(S) string(S.OutputName), c_sysY);
    sct_output = struct( ...
        "Cx", Cyx, "Cv", Dyv, "Du", Dyu, ...
        "sv_name", vertcat(strings(0,1), sv_y{:}));
    sct_model = struct( ...
        "sct_output", sct_output, "sv_I", vertcat(sv_I{:}), ...
        "c_sysBus", {c_sysBus}, "c_sysY", {c_sysY}, "c_sysL", {c_sysL}, "c_sysGC", {c_sysGC}, "cm_Y", cm_Y, ...
        "lv_nonUnit", tools.vcellfun(@(b) isempty(b.a_Component), a_bus), ...
        "cv_V", cv_V);

    % An Avv below this reciprocal condition number has no usable inverse (the shipped
    % networks are at 1e-4 or above)
    r_rcondMin = 1e-14;
    output = struct();
    if l_eq
        output.message = "Linearized at the equilibrium.";
    else
        output.message = "Linearized at the given point.";
    end
    output.s_issue   = "";
    output.rcond_Avv = rcond(sct_block.Avv);
    if ~all(cellfun(@(M) all(isfinite(M(:))), struct2cell(sct_block)))
        output.s_issue = "NotFinite";
        output.message = output.message + " Some Jacobian entries are not finite.";
    elseif output.rcond_Avv < r_rcondMin
        output.s_issue = "SingularAvv";
        output.message = output.message + sprintf(" Avv is singular (rcond = %g): the current balance does not determine %s.", ...
            output.rcond_Avv, list_labels(singular_voltages(sct_block.Avv, tab_map)));
    end
    flag = output.s_issue == "";

    % A voltage below this is zero (a ground fault sets it to exactly 0)
    r_voltageMin  = 1e-8;
    output.sv_faultBus = reshape(string(tools.vcellfun(@(b) string(b.s_tag), a_bus)), [], 1);
    output.sv_faultBus = output.sv_faultBus(abs(cv_V) < r_voltageMin);
    if ~isempty(output.sv_faultBus)
        s_list  = char(list_labels(output.sv_faultBus));
        output.message = output.message + " " + msg("GUILDA:SolverLIN:GroundFault", s_list);
        show_msg("info", "GUILDA:SolverLIN:GroundFault", s_list)
    end
    output.l_equilibrium = l_eq;
    output.s_layer = "PowerNetwork";
    output.n_x = size(sct_block.Axx,1);
    output.n_v = size(sct_block.Avv,1);
    output.n_u = size(sct_block.Bx,2);

    result = ResultLIN(net, obj, sct_options, flag, output, t0, ...
                                 tab_map, rv_point, sct_block, sct_model);
end


function sys = model_at_point(f_sys, s_owner)
% Model of a bus or global controller (struct); a non-finite matrix stops, saying whose it is
    sys = f_sys();
    for str = ["A","B","C","D","E"]
        if ~all(isfinite(sys.(str)(:)))
            error(msg("GUILDA:SolverLIN:JacobianNotFinite", s_owner))
        end
    end
end


function S = channels(S, iv_out, iv_in)
% Model with the outputs iv_out and the inputs iv_in of the model S (struct)
    S.B = S.B(:, iv_in);
    S.C = S.C(iv_out, :);
    S.D = S.D(iv_out, iv_in);
    S.InputName  = S.InputName(iv_in);
    S.OutputName = S.OutputName(iv_out);
end


function sv = singular_voltages(Avv, tab_map)
% Bus voltages in the null space of Avv
    [~, S, V] = svd(Avv);
    rv_s = diag(S);
    rv_w = vecnorm(V(:, rv_s <= max(rv_s(end), 1e-12*rv_s(1))), 2, 2);
    sv_v = tab_map.Label(tab_map.Kind == "Vre" | tab_map.Kind == "Vim");
    sv = sv_v(rv_w > 0.1*max(rv_w));
end


function str = list_labels(sv)
% Labels for a message, at most 8
    n = numel(sv);
    str = join(sv(1:min(n,8)), ", ");
    if n > 8
        str = str + sprintf(" and %d more", n-8);
    end
end


function u = gc_input(gc, tab_map, rv_point)
% Inputs of a global controller at the point: the outputs (fcn_Y at the states and the bus
% voltage of the point) or the states of its controlled units
    a_unit = gc.controlledUnits;
    n_u = numel(gc.sv_u);
    u = zeros(numel(a_unit)*n_u, 1);
    for idx = 1:numel(a_unit)
        unit = a_unit{idx};
        x_unit = rv_point(tab_map.Kind == "x" & tab_map.Owner == string(unit.s_tag));
        iv_k = (idx-1)*n_u + (1:n_u)';
        lv_Y = gc.iv_obsY(iv_k) > 0;
        lv_X = gc.iv_obsX(iv_k) > 0;
        if any(lv_Y)
            s_bus = string(unit.a_Bus.s_tag);
            V_unit = rv_point((tab_map.Kind == "Vre" | tab_map.Kind == "Vim") & tab_map.Bus == s_bus);
            y_unit = unit.f_Y(0, x_unit, V_unit);
            u(iv_k(lv_Y)) = y_unit(gc.iv_obsY(iv_k(lv_Y)));
        end
        u(iv_k(lv_X)) = x_unit(gc.iv_obsX(iv_k(lv_X)));
    end
end


function [s, sv_z] = add_global_controllers(c_sysGC, a_GC, s)
% Adds the global controllers to the linear model of the components
%
%   E dx/dt = Axx x + Axv v + Bxu u + Bxl l,   w = C x + Dv v + Du u + Dl l
%   x: component states (sv_x), v: bus voltages (sv_v), u: component inputs (sv_u),
%   l: inputs of local controllers (sv_l, not inputs of the network model), w: the
%   currents and then the outputs (sv_y) of the bus models (Cy, Dyv: those outputs)
%
% Global controller k:  E_k dz_k/dt = A_k z_k + B_k [v; r_k],  y_k = C_k z_k + D_k [v; r_k]
%   its inputs r_k are component outputs (sv_y, no feedthrough: r = Cy x + Dyv v) or
%   component states (sv_x); its outputs y_k add to component inputs (sv_u) or drive
%   inputs of local controllers (sv_l): u <- u + T_k y_k, l = L_k y_k
%
% The states z of all controllers are put after x, in the order of a_GlobalController
% (the order of the variable map). The returned matrices are for [x; z]; Bxu keeps the
% external input u. sv_z: names of z.
    sv_z = string.empty(0,1);
    if isempty(c_sysGC)
        return
    end
    nx = size(s.Axx,1);
    nv = numel(s.sv_v);
    nu = numel(s.sv_u);
    nl = numel(s.sv_l);

    Az   = cell(numel(c_sysGC),1);
    Bzx  = cell(numel(c_sysGC),1);
    Bzv  = cell(numel(c_sysGC),1);
    Cuz  = cell(1,numel(c_sysGC));
    Clz  = cell(1,numel(c_sysGC));
    Ez   = cell(numel(c_sysGC),1);
    sv_z = cell(numel(c_sysGC),1);  % cell while collecting
    Dux  = zeros(nu,nx);  Duv = zeros(nu,nv);
    Dlx  = zeros(nl,nx);  Dlv = zeros(nl,nv);
    for k = 1:numel(c_sysGC)
        sysGC = c_sysGC{k};
        sv_in = string(sysGC.InputName);
        sv_out = string(sysGC.OutputName);
        % r_k = Wx x + Wv v: voltages, component outputs and states by label
        [lv_v, iv_v] = ismember(sv_in, s.sv_v);
        [lv_y, iv_y] = ismember(sv_in, s.sv_y);
        [lv_x, iv_x] = ismember(sv_in, s.sv_x);
        lv_x = lv_x & ~lv_v & ~lv_y;
        [lv_u, iu] = ismember(sv_out, s.sv_u);
        [lv_l, il] = ismember(sv_out, s.sv_l);
        if ~all(lv_v | lv_y | lv_x) || ~all(lv_u | lv_l)
            error(msg("GUILDA:SolverLIN:GlobalControllerPort", a_GC{k}.s_tag))
        end
        Wx = zeros(numel(sv_in), nx);  Wv = zeros(numel(sv_in), nv);
        Wv(sub2ind(size(Wv), find(lv_v), iv_v(lv_v))) = 1;
        Wx(lv_y,:) = s.Cy(iv_y(lv_y),:);
        Wv(lv_y,:) = s.Dyv(iv_y(lv_y),:);
        Wx(sub2ind(size(Wx), find(lv_x), iv_x(lv_x))) = 1;
        T = zeros(nu, numel(sv_out));  T(sub2ind(size(T), iu(lv_u), find(lv_u))) = 1;
        L = zeros(nl, numel(sv_out));  L(sub2ind(size(L), il(lv_l), find(lv_l))) = 1;
        Az{k}   = sysGC.A;
        Bzx{k}  = sysGC.B * Wx;
        Bzv{k}  = sysGC.B * Wv;
        Cuz{k}  = T * sysGC.C;
        Clz{k}  = L * sysGC.C;
        Dux = Dux + T * sysGC.D * Wx;   Duv = Duv + T * sysGC.D * Wv;
        Dlx = Dlx + L * sysGC.D * Wx;   Dlv = Dlv + L * sysGC.D * Wv;
        Ez{k}   = sysGC.E;
        sv_z{k} = string(sysGC.StateName);
    end
    Az   = blkdiag(Az{:});
    Bzx  = vertcat(Bzx{:});
    Bzv  = vertcat(Bzv{:});
    Cuz  = horzcat(Cuz{:});
    Clz  = horzcat(Clz{:});
    sv_z = [string.empty(0,1); vertcat(sv_z{:})];
    nz   = size(Az,1);

    % x' and w with u <- u + Dux x + Duv v + Cuz z and l = Dlx x + Dlv v + Clz z
    Kx = s.Bxu*Dux + s.Bxl*Dlx;  Kv = s.Bxu*Duv + s.Bxl*Dlv;  Kz = s.Bxu*Cuz + s.Bxl*Clz;
    Mx = s.Du*Dux  + s.Dl*Dlx;   Mv = s.Du*Duv  + s.Dl*Dlv;   Mz = s.Du*Cuz  + s.Dl*Clz;
    s.Axx = [s.Axx + Kx, Kz; Bzx, Az];
    s.Axv = [s.Axv + Kv; Bzv];
    s.Bxu = [s.Bxu; zeros(nz,nu)];
    s.C   = [s.C + Mx, Mz];
    s.Dv  = s.Dv + Mv;
    s.E   = blkdiag(s.E, Ez{:});
end
