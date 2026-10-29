function [result, flag, output] = solve(obj, net, s_options)
% <@Desc>
% Linearizes the network net at the point s_options.Point and returns the unreduced DAE
% (the Jacobian blocks in the order of net.get_variable_map()) as a LinearizationResult.
% The solver and the network are only read: nothing is written back into them (the
% NonUnit choice is not stored on the buses). Called by net.linearize; calling it
% directly is for advanced use. Like net.linearize, it first rebuilds stale f_* handles
% and stops with the error GUILDA:PowerNetwork:EquilibriumStale when net.initialize()
% is needed.
% <@Role> Static Analysis
% <@Summary> Linearize the network with the given settings.
% <@Signatures>
% [
%   "[result, flag, output] = solve(obj, net)",
%   "[result, flag, output] = solve(obj, net, s_options)"
% ]
% <@Parameters>
% [
%   {"Name": "obj", "Type": "odeLinearizer", "Description": "Solver (net.solver_LIN).", "Required": true, "Default": "-"},
%   {"Name": "net", "Type": "PowerNetwork", "Description": "Initialized network.", "Required": true, "Default": "-"},
%   {"Name": "s_options", "Type": "struct", "Description": "Effective settings (output of get_options).", "Required": false, "Default": "obj.get_options()"}
% ]
% <@Returns>
% [
%   {"Name": "result", "Type": "LinearizationResult", "Description": "Jacobian blocks, variable map, point and settings."},
%   {"Name": "flag", "Type": "logical", "Description": "True when all Jacobian entries are finite."},
%   {"Name": "output", "Type": "struct", "Description": "message, l_equilibrium, n_x, n_v, n_u, rcond_Avv."}
% ]
    arguments
        obj
        net
        s_options (1,1) struct = obj.get_options()
    end
    t0 = tic;
    net.require_equilibrium();    % rebuild stale f_*; error if net.initialize() is needed

    a_bus = net.a_Bus;
    a_gc  = net.a_GlobalController;
    n_bus = numel(a_bus);
    if any(s_options.NonUnit > n_bus)
        error("GUILDA:odeLinearizer:NonUnit", ...
              "NonUnit = [%s] names a bus that does not exist; give indices of net.a_Bus (1 to %d).", ...
              num2str(s_options.NonUnit), n_bus)
    end

    [tab_map, c_idxBus, c_idxGC] = net.get_variable_map();
    [rv_point, l_eq] = odeLinearizer.point_vector(net, s_options.Point);

    % Bus models (V -> I) and global controller models at the point
    c_sysBus = cell(n_bus,1);
    for i = 1:n_bus
        if l_eq
            c_sysBus{i} = a_bus{i}.get_sys("port","V2I","full",false);
        else
            c_sysBus{i} = a_bus{i}.get_sys("port","V2I","full",false,"Point",rv_point(c_idxBus{i}));
        end
    end
    c_sysGC = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        if l_eq
            c_sysGC{k} = a_gc{k}.get_sys("full",true);
        else
            c_sysGC{k} = a_gc{k}.get_sys(rv_point(c_idxGC{k}), zeros(2,1), zeros(2,1), ...
                                         gc_input(a_gc{k}, tab_map, rv_point), "full",true);
        end
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
    [Axx, Axv, Bxu, Cix, Ex, str_z] = add_global_controllers(c_sysGC, a_gc, str_x, str_u, Axx, Axv, Bxu, Cix, Diu, Ex);

    if ~isequal([str_x; str_z], tab_map.Label(tab_map.Kind == "x"))
        error("GUILDA:odeLinearizer:VariableMap", ...
              "The states of the bus models do not follow net.get_variable_map(); report this as a bug.")
    end

    Ymat = tools.complex2matrix(cm_Y);
    s_block = struct( ...
        "Axx", Axx, "Axv", Axv, "Bx", Bxu, ...
        "Avx", -Cix, "Avv", Ymat - Div, "Bv", -Diu, ...
        "E", Ex);
    s_model = struct( ...
        "c_sysBus", {c_sysBus}, "c_sysGC", {c_sysGC}, "cm_Y", cm_Y, ...
        "lv_nonUnit", reshape(ismember(1:n_bus, s_options.NonUnit), [], 1) | ...
                      tools.vcellfun(@(b) isempty(b.a_Component), a_bus), ...
        "cv_V", cv_V);

    flag = all(cellfun(@(M) all(isfinite(M(:))), struct2cell(s_block)));
    output = struct();
    if l_eq
        output.message = "Linearized at the equilibrium.";
    else
        output.message = "Linearized at the given point.";
    end
    if ~flag
        output.message = output.message + " Some Jacobian entries are not finite.";
    end
    output.l_equilibrium = l_eq;
    output.n_x = size(s_block.Axx,1);
    output.n_v = size(s_block.Avv,1);
    output.n_u = size(s_block.Bx,2);
    output.rcond_Avv = rcond(s_block.Avv);

    result = LinearizationResult(net, obj, s_options, flag, output, t0, ...
                                 tab_map, rv_point, s_block, s_model);
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
            error("GUILDA:odeLinearizer:GlobalControllerPort", ...
                  "The ports of the global controller '%s' are not found in the linearized system.", a_GC{k}.str_tag)
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
