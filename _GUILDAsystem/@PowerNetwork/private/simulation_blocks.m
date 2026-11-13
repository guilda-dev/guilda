function sct_dae = simulation_blocks(net)
% Blocks, maps, admittance and equilibrium of the network for SolverODE.solve.
%
% One block per component (a_Bus order, then a_Component order), per local controller
% (depth first, the order of the variable map) and per global controller. A block holds
% its rows in the variable map (iv_x, iv_u, iv_y), its position (i_bus, i_comp, iv_lc,
% i_parent) and its f_* function handles, which set_odefcn made as closures with the
% parameters bound by value. A generator also has f_reconnect, its state from the bus
% voltage when it reconnects after a trip (the only handle that calls a method of the
% model). Stops with GUILDA:PowerNetwork:GconNoTarget for an output of a global
% controller that drives no input.
    arguments (Input)
        net  % Network of the run (checked by check_simulation).
    end
    arguments (Output)
        sct_dae (1,1) struct  % tab_variable, tab_connection, cm_Y, im_branchBus, c_branchY, rv_equilibrium, rv_Iequilibrium, c_comp, c_lc, c_gc, sv_bus, sv_branch, sv_comp, sv_lc, sv_gc.
    end
    [tab, ~, ~, tab_c] = net.get_variable_map();
    a_bus = net.a_Bus;
    a_br  = net.a_Branch;
    a_gc  = net.a_GlobalController;
    n_bus = numel(a_bus);
    n_var = nnz(tab.Role == "variable");      % the variables are the leading rows

    sct_dae = struct();
    sct_dae.tab_variable   = tab;
    sct_dae.tab_connection = tab_c;

    % Admittance: all branches closed, and the matrix of each branch at its buses
    sct_dae.sv_bus    = string(a_bus(:));
    sct_dae.sv_branch = string(a_br(:));
    sct_dae.cm_Y      = net.get_admittance_matrix().Variables;
    sct_dae.im_branchBus = zeros(numel(a_br), 2);
    sct_dae.c_branchY    = cell(numel(a_br), 1);
    for k = 1:numel(a_br)
        [~, sct_dae.im_branchBus(k,:)] = ismember(string(a_br{k}.a_Bus), sct_dae.sv_bus);
        sct_dae.c_branchY{k} = a_br{k}.get_admittance_matrix();
    end

    % Equilibrium of the variable rows and of the bus currents
    rows = @(s_owner, s_kind) find(tab.Owner == s_owner & tab.Kind == s_kind);
    rv_eq = zeros(n_var, 1);
    rv_eq(ismember(tab.Kind, ["Vre","Vim"])) = tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], a_bus);
    sct_dae.rv_Iequilibrium = tools.vcellfun(@(b) [real(b.c_Iequilibrium); imag(b.c_Iequilibrium)], a_bus);
    if isempty(sct_dae.rv_Iequilibrium)
        sct_dae.rv_Iequilibrium = zeros(0,1);
    end

    % Components and their local controllers (depth first)
    sct_dae.c_comp = cell(0,1);
    sct_dae.c_lc   = cell(0,1);
    for i = 1:n_bus
        a_comp = a_bus{i}.a_Component;
        for j = 1:numel(a_comp)
            comp  = a_comp{j};
            s_tag = string(comp.s_tag);
            b = handles(comp);
            b.iv_x  = rows(s_tag, "x");
            b.iv_u  = rows(s_tag, "u");
            b.iv_y  = rows(s_tag, "y");
            b.i_bus = i;
            b.iv_lc = zeros(0,1);
            b.f_I       = comp.f_I;
            b.f_JacobiI = comp.f_JacobiI;
            b.f_reconnect = [];
            if isa(comp, 'component.generator.abstract')
                b.f_reconnect = @(V) comp.get_equilibrium(V, 0, 0, 0);
            end
            b.s_tag = s_tag;
            rv_eq(b.iv_x) = comp.rv_Xequilibrium;
            rv_eq(b.iv_u) = comp.rv_Uequilibrium;
            i_comp = numel(sct_dae.c_comp) + 1;

            [c_LC, iv_parent] = controllers(comp);
            n_lc0 = numel(sct_dae.c_lc);
            for k = 1:numel(c_LC)
                con  = c_LC{k};
                s_lc = string(con.s_tag);
                bl = handles(con);
                bl.iv_x   = rows(s_lc, "x");
                bl.iv_u   = rows(s_lc, "uc");
                bl.iv_y   = rows(s_lc, "yc");
                bl.i_bus  = i;
                bl.i_comp = i_comp;
                bl.i_parent = 0;
                if iv_parent(k) > 0
                    bl.i_parent = n_lc0 + iv_parent(k);
                end
                bl.s_tag  = s_lc;
                rv_eq(bl.iv_x) = con.rv_Xequilibrium;
                rv_eq(bl.iv_u) = con.rv_Uequilibrium;
                sct_dae.c_lc{end+1,1} = bl;
                b.iv_lc(end+1,1) = numel(sct_dae.c_lc);
            end
            sct_dae.c_comp{i_comp,1} = b;
        end
    end

    % Global controllers: all bus voltages
    sct_dae.c_gc = cell(numel(a_gc), 1);
    for k = 1:numel(a_gc)
        gc   = a_gc{k};
        s_gc = string(gc.s_tag);
        bg = handles(gc);
        bg.iv_x  = rows(s_gc, "x");
        bg.iv_u  = rows(s_gc, "uc");
        bg.iv_y  = rows(s_gc, "yc");
        bg.s_tag = s_gc;
        rv_eq(bg.iv_x) = gc.rv_Xequilibrium;
        rv_eq(bg.iv_u) = gc.rv_Uequilibrium;
        sct_dae.c_gc{k} = bg;

        % Each output must drive an input (a local controller with that input may have
        % been removed since add_global_controller)
        lv_out  = tab_c.Kind == "global" & ismember(tab_c.SourceIndex, bg.iv_y);
        iv_none = setdiff(bg.iv_y, tab_c.SourceIndex(lv_out));
        if ~isempty(iv_none)
            n_o  = numel(gc.sv_y);
            m    = iv_none(1) - min(bg.iv_y);       % 0-based row among its outputs
            unit = gc.controlledUnits{floor(m/n_o)+1};
            error(msg("GUILDA:PowerNetwork:GconNoTarget", char(s_gc), char(gc.sv_y(mod(m,n_o)+1)), char(unit.s_tag)))
        end
    end
    sct_dae.rv_equilibrium = rv_eq;
    sct_dae.sv_comp = string(cellfun(@(b) b.s_tag, sct_dae.c_comp, 'UniformOutput', false));
    sct_dae.sv_lc   = string(cellfun(@(b) b.s_tag, sct_dae.c_lc, 'UniformOutput', false));
    sct_dae.sv_gc   = string(cellfun(@(b) b.s_tag, sct_dae.c_gc, 'UniformOutput', false));
    for s_f = ["sv_comp", "sv_lc", "sv_gc"]
        sct_dae.(s_f) = reshape(sct_dae.(s_f), [], 1);
    end
end


function b = handles(model)
% The f_* function handles common to the components and the controllers
    arguments (Input)
        model  % Component, LocalController or GlobalController (set_odefcn done).
    end
    arguments (Output)
        b (1,1) struct  % f_dx, f_Y, f_Mass, f_JacobiDx, f_JacobiY.
    end
    b = struct();
    b.f_dx       = model.f_dx;
    b.f_Y        = model.f_Y;
    b.f_Mass     = model.f_Mass;
    b.f_JacobiDx = model.f_JacobiDx;
    b.f_JacobiY  = model.f_JacobiY;
end

function [list, iv_parent] = controllers(parent)
% Local controllers of parent, depth first (the order of the variable map), with the
% position of the parent of each in the list (0: parent itself)
    arguments (Input)
        parent  % Component or local controller.
    end
    arguments (Output)
        list      (:,1) cell    % Its local controllers and theirs.
        iv_parent (:,1) double  % Position of the parent of each (0: parent).
    end
    list = cell(0,1);
    iv_parent = zeros(0,1);
    for k = 1:numel(parent.a_LocalController)
        con = parent.a_LocalController{k};
        list(end+1,1) = {con}; %#ok<AGROW>
        iv_parent(end+1,1) = 0; %#ok<AGROW>
        i_self = numel(list);
        [c_sub, iv_sub] = controllers(con);
        lv_top = iv_sub == 0;
        iv_sub(lv_top)  = i_self;
        iv_sub(~lv_top) = iv_sub(~lv_top) + i_self;
        list = [list; c_sub]; %#ok<AGROW>
        iv_parent = [iv_parent; iv_sub]; %#ok<AGROW>
    end
end
