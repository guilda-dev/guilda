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

    [tab_map, c_idxBus, c_idxGC] = net.get_variable_map();
    [rv_point, l_eq] = SolverLIN.point_vector(net, sct_options.Point);
    lv_bad = ~isfinite(rv_point);
    if any(lv_bad)
        error(msg("GUILDA:SolverLIN:PointNotFinite", list_labels(tab_map.Label(lv_bad))))
    end

    % Bus models (V -> I) and global controller models at the point. The network model
    % has the bus voltages and the component inputs (Kind "u" of the variable map) as
    % inputs, and the currents as outputs: the inputs and outputs of the controllers in
    % the bus models are left out.
    c_sysBus = cell(n_bus,1);
    c_sysY   = cell(n_bus,1);
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
    end
    c_sysGC = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        if l_eq
            f_sys = @() a_gc{k}.get_sys("Format","struct");
        else
            f_sys = @() a_gc{k}.get_sys(rv_point(c_idxGC{k}), zeros(2,1), zeros(2,1), ...
                                        gc_input(a_gc{k}, tab_map, rv_point), "Format","struct");
        end
        c_sysGC{k} = model_at_point(f_sys, "global controller " + a_gc{k}.s_tag);
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
    Dyu = tools.dcellfun(@(S) S.D(:,3:end), c_sysY);
    n_i = size(Cix,1);
    [Axx, Axv, Bxu, Cix, Ex, sv_z] = add_global_controllers(c_sysGC, a_gc, sv_x, sv_u, Axx, Axv, Bxu, [Cix; Cyx], [Diu; Dyu], Ex);
    Cyx = Cix(n_i+1:end,:);
    Cix = Cix(1:n_i,:);

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
        "Cx", Cyx, "Cv", tools.dcellfun(@(S) S.D(:,1:2), c_sysY), "Du", Dyu, ...
        "sv_name", vertcat(strings(0,1), sv_y{:}));
    sct_model = struct( ...
        "sct_output", sct_output, "sv_I", vertcat(sv_I{:}), ...
        "c_sysBus", {c_sysBus}, "c_sysGC", {c_sysGC}, "cm_Y", cm_Y, ...
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
        s_fault = sprintf("The voltage of %s is zero at the point, as in a ground fault: the admittance matrix does not include the fault, and get_ss(""DAE"") needs Coordinate=""Vre&Vim"" there.", ...
                            list_labels(output.sv_faultBus));
        output.message = output.message + " " + s_fault;
        disp("INFO: " + s_fault)
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
% Inputs of a global controller at the point: the states of its controlled units
    a_unit = gc.controlledUnits;
    c_u = cell(numel(a_unit),1);
    for idx = 1:numel(a_unit)
        unit = a_unit{idx};
        sv_label = string(unit.attach_tag(unit.sv_x(unit.sv_x == gc.sv_u)));
        [~, iv] = ismember(sv_label(:), tab_map.Label);
        c_u{idx} = rv_point(iv);
    end
    u = vertcat(zeros(0,1), c_u{:});
end


function [Axx, Bxv, Bxu, Cix, E, sv_z] = add_global_controllers(c_sysGC, a_GC, sv_x, sv_u, Axx, Bxv, Bxu, Cix, Diu, E)
% Adds the global controllers to the linear model of the components
%
%   E dx/dt = Axx x + Bxv v + Bxu u,   i = Cix x + ... + Diu u
%   x: component states (names sv_x), u: component inputs (names sv_u)
%
% Global controller k:  E_k dz_k/dt = A_k z_k + B_k w_k,  y_k = C_k z_k + D_k w_k
%   its inputs w_k are component states (InputName in sv_x): w_k = S_k x
%   its outputs y_k add to component inputs (OutputName in sv_u): u <- u + T_k y_k
%
% The states z of all controllers are put after x, in the order of a_GlobalController
% (the order of the variable map). The returned matrices are for [x; z]; Bxu keeps the
% external input u. sv_z: names of z.
    sv_z = string.empty(0,1);
    if isempty(c_sysGC)
        return
    end
    nx = size(Axx,1);
    nv = size(Bxv,2);
    nu = size(Bxu,2);

    Az    = cell(numel(c_sysGC),1);
    Bzx   = cell(numel(c_sysGC),1);
    Cuz   = cell(1,numel(c_sysGC));
    Ez    = cell(numel(c_sysGC),1);
    sv_z  = cell(numel(c_sysGC),1);  % cell while collecting
    Dux   = zeros(nu,nx);
    for k = 1:numel(c_sysGC)
        sysGC = c_sysGC{k};
        [lv_w, iw] = ismember(string(sysGC.InputName),  sv_x);
        [lv_y, iy] = ismember(string(sysGC.OutputName), sv_u);
        if ~all(lv_w) || ~all(lv_y)
            error(msg("GUILDA:SolverLIN:GlobalControllerPort", a_GC{k}.s_tag))
        end
        S = zeros(numel(iw), nx);  S(sub2ind(size(S), 1:numel(iw), iw(:)')) = 1;
        T = zeros(nu, numel(iy));  T(sub2ind(size(T), iy(:)', 1:numel(iy))) = 1;
        Az{k}    = sysGC.A;
        Bzx{k}   = sysGC.B * S;
        Cuz{k}   = T * sysGC.C;
        Dux      = Dux + T * sysGC.D * S;
        Ez{k}    = sysGC.E;
        sv_z{k} = string(sysGC.StateName);
    end
    Az    = blkdiag(Az{:});
    Bzx   = vertcat(Bzx{:});
    Cuz   = horzcat(Cuz{:});
    sv_z  = [string.empty(0,1); vertcat(sv_z{:})];
    nz    = size(Az,1);

    Axx = [Axx + Bxu*Dux, Bxu*Cuz; Bzx, Az];
    Bxv = [Bxv; zeros(nz,nv)];
    Bxu = [Bxu; zeros(nz,nu)];
    Cix = [Cix + Diu*Dux, Diu*Cuz];
    E   = blkdiag(E, Ez{:});
end
