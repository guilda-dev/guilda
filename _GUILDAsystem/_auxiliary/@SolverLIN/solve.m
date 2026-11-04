function [result, flag, output] = solve(obj, net, s_options)
% Linearize the network with the given settings.
%
% Linearizes the network net at the point s_options.Point and returns the unreduced DAE
% (the Jacobian blocks in the order of net.get_variable_map()) as a ResultLIN.
% The solver and the network are only read: nothing is written back into them.
% Called by net.linearize; calling it
% directly is for advanced use. Like net.linearize, it first builds out-of-date f_* handles
% and stops with the error GUILDA:PowerNetwork:EquilibriumStale when net.initialize()
% is needed. A Point with NaN or Inf stops with GUILDA:SolverLIN:PointNotFinite, and a
% model that is not finite at the point with GUILDA:SolverLIN:JacobianNotFinite.
%
% Point sets the variables only: the network is the one of the model, so a point inside a
% fault is combined with the admittance matrix without the fault. The call reports such a
% point (zero bus voltage) with an INFO message and in output.message, and a point that is
% not an equilibrium in output.message; result.rv_residual holds the residual. flag does
% not depend on them.
    arguments
        obj % Solver (net.solver_LIN).
        net % Initialized network.
        s_options (1,1) struct = obj.get_options() % Effective settings (output of get_options).
    end
    arguments (Output)
        result % Jacobian blocks, variable map, point and settings.
        flag % True when the result is usable: all Jacobian entries are finite and Avv is invertible.
        output % message, str_issue ("", "NotFinite" or "SingularAvv"), l_equilibrium, n_x, n_v, n_u, rcond_Avv, r_residual, sv_faultBus.
    end
    t0 = tic;
    net.require_equilibrium();    % build out-of-date f_*; error if net.initialize() is needed

    a_bus = net.a_Bus;
    a_gc  = net.a_GlobalController;
    n_bus = numel(a_bus);
    v3_nonunit_range(s_options, n_bus);        % COMPAT(v3)

    [tab_map, c_idxBus, c_idxGC] = net.get_variable_map();
    [rv_point, l_eq] = SolverLIN.point_vector(net, s_options.Point);
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
            f_sys = @() a_bus{i}.get_sys("port","V2I");
        else
            f_sys = @() a_bus{i}.get_sys("port","V2I","Point",rv_point(c_idxBus{i}));
        end
        sys_i = model_at_point(f_sys, "bus " + a_bus{i}.str_tag);
        sv_u = tab_map.Label(tab_map.Kind == "u" & tab_map.Bus == string(a_bus{i}.str_tag));
        [~, iv_u] = ismember(sv_u, string(sys_i.InputName));
        c_sysBus{i} = sys_i(1:2, [1, 2, reshape(iv_u, 1, [])]);
        c_sysY{i}   = sys_i(3:end, [1, 2, reshape(iv_u, 1, [])]);
    end
    c_sysGC = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        if l_eq
            f_sys = @() a_gc{k}.get_sys();
        else
            f_sys = @() a_gc{k}.get_sys(rv_point(c_idxGC{k}), zeros(2,1), zeros(2,1), ...
                                        gc_input(a_gc{k}, tab_map, rv_point));
        end
        c_sysGC{k} = model_at_point(f_sys, "global controller " + a_gc{k}.str_tag);
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

    str_x = tools.cellfun(@(S) string(S.StateName), c_sysBus);
    str_x = vertcat(strings(0,1), str_x{:});
    str_u = tab_map.Label(tab_map.Kind == "u");
    % The outputs of the bus models depend on the global controllers as the currents do
    Cyx = tools.dcellfun(@(S) S.C         , c_sysY);
    Dyu = tools.dcellfun(@(S) S.D(:,3:end), c_sysY);
    n_i = size(Cix,1);
    [Axx, Axv, Bxu, Cix, Ex, str_z] = add_global_controllers(c_sysGC, a_gc, str_x, str_u, Axx, Axv, Bxu, [Cix; Cyx], [Diu; Dyu], Ex);
    Cyx = Cix(n_i+1:end,:);
    Cix = Cix(1:n_i,:);

    if ~isequal([str_x; str_z], tab_map.Label(tab_map.Kind == "x"))
        error(msg("GUILDA:SolverLIN:VariableMap"))
    end

    Ymat = tools.complex2matrix(cm_Y);
    s_block = struct( ...
        "Axx", Axx, "Axv", Axv, "Bx", Bxu, ...
        "Avx", -Cix, "Avv", Ymat - Div, "Bv", -Diu, ...
        "E", Ex);
    sv_I = tools.cellfun(@(S) string(S.OutputName), c_sysBus);
    sv_y = tools.cellfun(@(S) string(S.OutputName), c_sysY);
    s_output = struct( ...
        "Cx", Cyx, "Cv", tools.dcellfun(@(S) S.D(:,1:2), c_sysY), "Du", Dyu, ...
        "sv_name", vertcat(strings(0,1), sv_y{:}));
    s_model = struct( ...
        "s_output", s_output, "sv_I", vertcat(sv_I{:}), ...
        "c_sysBus", {c_sysBus}, "c_sysGC", {c_sysGC}, "cm_Y", cm_Y, ...
        "lv_nonUnit", tools.vcellfun(@(b) isempty(b.a_Component), a_bus), ...
        "cv_V", cv_V);
    rv_residual = residual_at_point(a_bus, a_gc, tab_map, c_idxBus, c_idxGC, rv_point, Ymat);

    % An Avv below this reciprocal condition number has no usable inverse (the shipped
    % networks are at 1e-4 or above)
    r_rcondMin = 1e-14;
    output = struct();
    if l_eq
        output.message = "Linearized at the equilibrium.";
    else
        output.message = "Linearized at the given point.";
    end
    output.str_issue = "";
    output.rcond_Avv = rcond(s_block.Avv);
    if ~all(cellfun(@(M) all(isfinite(M(:))), struct2cell(s_block)))
        output.str_issue = "NotFinite";
        output.message = output.message + " Some Jacobian entries are not finite.";
    elseif output.rcond_Avv < r_rcondMin
        output.str_issue = "SingularAvv";
        output.message = output.message + sprintf(" Avv is singular (rcond = %g): the current balance does not determine %s.", ...
            output.rcond_Avv, list_labels(singular_voltages(s_block.Avv, tab_map)));
    end
    flag = output.str_issue == "";

    % A residual above this is not an equilibrium, and a voltage below this is zero (a
    % ground fault sets it to exactly 0; the shipped networks are at 1e-10 or below at
    % their equilibrium)
    r_residualMax = 1e-6;
    r_voltageMin  = 1e-8;
    [output.r_residual, i_max] = max(abs(rv_residual));
    if isempty(rv_residual)
        output.r_residual = 0;
    end
    output.sv_faultBus = reshape(string(tools.vcellfun(@(b) string(b.str_tag), a_bus)), [], 1);
    output.sv_faultBus = output.sv_faultBus(abs(cv_V) < r_voltageMin);
    if ~isempty(output.sv_faultBus)
        str_fault = sprintf("The voltage of %s is zero at the point, as in a ground fault: the admittance matrix does not include the fault, and get_ss(""DAE"") needs Coordinate=""Vre&Vim"" there.", ...
                            list_labels(output.sv_faultBus));
        output.message = output.message + " " + str_fault;
        disp("INFO: " + str_fault)
    end
    if ~l_eq && output.r_residual > r_residualMax
        sv_row = tab_map.Label(tab_map.Kind ~= "u");
        output.message = output.message + sprintf(" The point is not an equilibrium: the largest residual is %g at %s (result.rv_residual).", ...
                                                  output.r_residual, sv_row(i_max));
    end
    output.l_equilibrium = l_eq;
    output.n_x = size(s_block.Axx,1);
    output.n_v = size(s_block.Avv,1);
    output.n_u = size(s_block.Bx,2);

    result = ResultLIN(net, obj, s_options, flag, output, t0, ...
                                 tab_map, rv_point, s_block, s_model, rv_residual);
end


function sys = model_at_point(f_sys, str_owner)
% Model of a bus or global controller; dss stops on a non-finite matrix, so say whose it is
    try
        sys = f_sys();
    catch ME
        if startsWith(ME.identifier, "Control:ltiobject")
            error(msg("GUILDA:SolverLIN:JacobianNotFinite", str_owner))
        end
        rethrow(ME)
    end
end


function rv_residual = residual_at_point(a_bus, a_gc, tab_map, c_idxBus, c_idxGC, rv_point, Ymat)
% Right-hand sides of the DAE at the point: the state equations, then Y v - I of each bus
    lv_x = tab_map.Kind == "x";
    lv_v = tab_map.Kind == "Vre" | tab_map.Kind == "Vim";
    rv_f = zeros(height(tab_map),1);
    rv_I = zeros(nnz(lv_v),1);
    for i = 1:numel(a_bus)
        [~, c_idxC] = a_bus{i}.get_variable_map();
        for j = 1:numel(c_idxC)
            iv_c = c_idxBus{i}(c_idxC{j});
            [rv_dx, rv_Ic] = a_bus{i}.a_Component{j}.point_residual(rv_point(iv_c));
            rv_f(iv_c(lv_x(iv_c))) = rv_dx;
            rv_I(2*i-1:2*i) = rv_I(2*i-1:2*i) + rv_Ic;
        end
    end
    for k = 1:numel(a_gc)
        rv_f(c_idxGC{k}) = a_gc{k}.f_dx(0, rv_point(c_idxGC{k}), zeros(2,1), zeros(2,1), gc_input(a_gc{k}, tab_map, rv_point));
    end
    rv_residual = [rv_f(lv_x); Ymat*rv_point(lv_v) - rv_I];
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


function [Axx, Bxv, Bxu, Cix, E, str_z] = add_global_controllers(c_sysGC, a_GC, str_x, str_u, Axx, Bxv, Bxu, Cix, Diu, E)
% Adds the global controllers to the linear model of the components
%
%   E dx/dt = Axx x + Bxv v + Bxu u,   i = Cix x + ... + Diu u
%   x: component states (names str_x), u: component inputs (names str_u)
%
% Global controller k:  E_k dz_k/dt = A_k z_k + B_k w_k,  y_k = C_k z_k + D_k w_k
%   its inputs w_k are component states (InputName in str_x): w_k = S_k x
%   its outputs y_k add to component inputs (OutputName in str_u): u <- u + T_k y_k
%
% The states z of all controllers are put after x, in the order of a_GlobalController
% (the order of the variable map). The returned matrices are for [x; z]; Bxu keeps the
% external input u. str_z: names of z.
    str_z = string.empty(0,1);
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
    str_z = cell(numel(c_sysGC),1);  %#ok (cell while collecting)
    Dux   = zeros(nu,nx);
    for k = 1:numel(c_sysGC)
        sysGC = c_sysGC{k};
        [lv_w, iw] = ismember(string(sysGC.InputName),  str_x);
        [lv_y, iy] = ismember(string(sysGC.OutputName), str_u);
        if ~all(lv_w) || ~all(lv_y)
            error(msg("GUILDA:SolverLIN:GlobalControllerPort", a_GC{k}.str_tag))
        end
        S = zeros(numel(iw), nx);  S(sub2ind(size(S), 1:numel(iw), iw(:)')) = 1;
        T = zeros(nu, numel(iy));  T(sub2ind(size(T), iy(:)', 1:numel(iy))) = 1;

        Az{k}    = sysGC.A;
        Bzx{k}   = sysGC.B * S;
        Cuz{k}   = T * sysGC.C;
        Dux      = Dux + T * sysGC.D * S;
        Ez{k}    = sysGC.E;
        str_z{k} = string(sysGC.StateName);
    end
    Az    = blkdiag(Az{:});
    Bzx   = vertcat(Bzx{:});
    Cuz   = horzcat(Cuz{:});
    str_z = [string.empty(0,1); vertcat(str_z{:})];
    nz    = size(Az,1);

    Axx = [Axx + Bxu*Dux, Bxu*Cuz; Bzx, Az];
    Bxv = [Bxv; zeros(nz,nv)];
    Bxu = [Bxu; zeros(nz,nu)];
    Cix = [Cix + Diu*Dux, Diu*Cuz];
    E   = blkdiag(E, Ez{:});
end
