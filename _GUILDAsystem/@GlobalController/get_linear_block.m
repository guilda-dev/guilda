function sct_block = get_linear_block(obj, x, V, u)
% Get the linear block of the global controller at a point.
%
% Returns the linear model of the controller at the states x, the voltages
% V = [Vre1; Vim1; Vre2; ...] of all buses of the network (in the order of a_Bus) and
% the inputs u (sv_u of each controlled unit, unit by unit), as a struct with the fields
% A, B, C, D, E (E dx/dt = A x + B [V; u], y = C x + D [V; u]) and StateName,
% InputName, OutputName (string columns). The names are the Labels of the variable map of
% the network (net.get_variable_map): the inputs are the voltages of the buses and the
% inputs (rows "uc", one set per unit), the states are the states and the outputs are the
% outputs (rows "yc", one set per unit). Where each input is read and which inputs each
% output drives is in the connection map; get_sys connects the blocks by it
% (SolverLIN.solve).
%
% A controlled unit without the outputs or states sv_u, or an output sv_y that drives no
% input of the unit or its local controllers, stops with the error
% GUILDA:GlobalController:GlobalControllerPort. The Jacobians are those of the simulation
% (f_JacobiDx, f_JacobiY); a model that returns [] for a block gives zeros, and an empty
% mass matrix is the identity. The model is not changed.
%
% See also PowerSystemModel.get_sys, PowerNetwork.get_variable_map
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        x (:,1) double   % States of the controller.
        V (:,1) double   % [pu] Voltages of all buses [Vre1; Vim1; ...].
        u (:,1) double   % Inputs of the controller (sv_u of each unit).
    end
    arguments (Output)
        sct_block struct   % Fields A, B, C, D, E, StateName, InputName, OutputName.
    end
    net = obj.a_PowerNetwork;
    a_unit = obj.controlledUnits;
    n_u = numel(obj.sv_u);
    n_o = numel(obj.sv_y);

    % Every input reads its unit, and every output drives an input (the connection map)
    k_gc = find(cellfun(@(g) g == obj, net.a_GlobalController), 1);
    [tab, ~, c_idxGC, tab_c] = net.get_variable_map();
    iv_gc = c_idxGC{k_gc};
    iv_uc = iv_gc(tab.Kind(iv_gc) == "uc");
    iv_yc = iv_gc(tab.Kind(iv_gc) == "yc");
    lv_in  = obj.iv_obsY > 0 | obj.iv_obsX > 0;
    lv_out = ismember(iv_yc, tab_c.SourceIndex(tab_c.Kind == "global"));
    for k = 1:numel(a_unit)
        if ~all(lv_in((k-1)*n_u + (1:n_u))) || ~all(lv_out((k-1)*n_o + (1:n_o)))
            s = a_unit{k};
            error(msg("GUILDA:GlobalController:GlobalControllerPort", obj.s_tag, join(obj.sv_u, " "), join(obj.sv_y, " "), s.s_tag, class(s), join([s.sv_y(:); s.sv_x(:)], " "), join(s.sv_u, " ")))
        end
    end

    % Same Jacobian contract as SolverODE: f_JacobiDx/Y(t,x,V,u)
    nx = numel(x);
    nv = numel(V);
    nu = numel(u);
    ny = numel(a_unit)*n_o;
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

    sv_V = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
    sct_block = struct("A", A, "B", [Bv, Bu], "C", C, "D", [Dv, Du], "E", E, ...
                       "StateName", tab.Label(iv_gc(tab.Kind(iv_gc) == "x")), ...
                       "InputName", [sv_V; tab.Label(iv_uc)], ...
                       "OutputName", tab.Label(iv_yc));
end
