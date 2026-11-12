function [rv_point, l_equilibrium] = point_vector(layer, Point)
% Get the values of the variables of a layer at the Point option.
%
% Returns the values of the variables of layer at the point given by the Point option, as a
% column vector in the order of the variables of its linearization: the rows x, Vre, Vim,
% u of layer.get_variable_map() (its leading rows) for a PowerNetwork, Bus or Component;
% the states, the voltages (of the bus of its component, or of all buses) and the inputs
% (rows "uc") for a LocalController or GlobalController.
%
% - `[]`: the equilibrium (states, inputs and bus voltages set by net.initialize);
%   l_equilibrium is true.
% - vector: used as it is; its length must be the number of these variables.
% - `{sim, t}`: the values of the simulation result sim at time t, read through its method
%   rv = sim.get_point(t, tab_map), which returns the values of the rows of tab_map
%   (ResultODE.get_point: linear interpolation between output times; at a phase
%   boundary, the value after the event). Not for a controller (GUILDA:SolverLIN:PointLayer).
% - `{sim, t, Side}`: the same, with sim.get_point(t, tab_map, Side=Side); Side "before"
%   takes the value before the event at a phase boundary.
%
% A value that is not finite stops with GUILDA:SolverLIN:PointNotFinite, naming the
% variables. Point is a point of the variables, and the network stays the one of the
% model: at a time inside a fault of {sim, t} the states are those of the fault, but the
% admittance matrix does not include the fault. The model is not changed.
    arguments (Input)
        layer          % Analysed layer (PowerNetwork, Bus, Component, LocalController or GlobalController).
        Point          % Point option ([], a vector, {sim, t} or {sim, t, Side}).
    end
    arguments (Output)
        rv_point       % Values of the variables of the linearization of the layer.
        l_equilibrium  % True when Point is [] (the equilibrium).
    end
    SolverLIN.check_point(Point);
    l_equilibrium = isempty(Point) && ~iscell(Point);
    if isa(layer, "LocalController") || isa(layer, "GlobalController")
        [rv_point, sv_label] = controller_point(layer, Point, l_equilibrium);
    else
        if ~(isa(layer, "PowerNetwork") || isa(layer, "Bus") || isa(layer, "Component"))
            error(msg("GUILDA:SolverLIN:PointLayer", class(layer)))
        end
        c_rows  = layer.get_variable_map("rows");
        n_var   = n_rows(c_rows);
        sv_label = [c_rows{1}(:,4); c_rows{2}(:,4); c_rows{3}(:,4)];
        if l_equilibrium
            rv_point = assemble(layer, @equilibrium_comp, @equilibrium_bus, @equilibrium_gc);
        elseif isnumeric(Point)
            if numel(Point) ~= n_var
                error(msg("GUILDA:SolverLIN:PointSize", string(numel(Point)), string(layer.s_tag), string(n_var), lower(class_name(layer))))
            end
            rv_point = double(Point(:));
        else
            sim = Point{1};
            tab_map = layer.get_variable_map();
            tab_map = tab_map(1:n_var,:);
            t   = Point{2};
            if ~ismethod(sim, "get_point")
                error(msg("GUILDA:SolverLIN:PointSimType", class(sim)))
            end
            if numel(Point) == 3
                rv_point = sim.get_point(t, tab_map, Side=Point{3});
            else
                rv_point = sim.get_point(t, tab_map);
            end
            rv_point = double(rv_point(:));
            if numel(rv_point) ~= n_var
                error(msg("GUILDA:SolverLIN:PointSimSize", class(sim), string(numel(rv_point)), string(n_var)))
            end
        end
    end
    lv_bad = ~isfinite(rv_point);
    if any(lv_bad)
        error(msg("GUILDA:SolverLIN:PointNotFinite", list_labels(sv_label(lv_bad))))
    end
end


function [rv, sv_label] = controller_point(con, Point, l_equilibrium)
% Point of a controller: its states, the voltages, its inputs
    if isa(con, "LocalController")
        comp = con.a_Component;
        while isa(comp, "LocalController")
            comp = comp.a_Component;
        end
        a_bus = {comp.a_Bus};
    else
        a_bus = con.a_PowerNetwork.a_Bus;
    end
    sv_V = tools.vcellfun(@(b) reshape(string(b.attach_tag(["Vre";"Vim"])), [], 1), a_bus);
    sv_label = [label(con, con.sv_x); sv_V; label(con, con.sv_u)];
    if isa(con, "GlobalController")
        n_unit = numel(con.controlledUnits);
        sv_label = [label(con, con.sv_x); sv_V; label(con, reshape(reshape(string(con.sv_u), [], 1) + "_" ...
                    + reshape(string(tools.vcellfun(@(c) string(c.s_tag), con.controlledUnits)), 1, []), [], 1))];
        n_u = numel(con.sv_u)*n_unit;
    else
        n_u = numel(con.sv_u);
    end
    n_var = numel(con.sv_x) + numel(sv_V) + n_u;
    if l_equilibrium
        V  = tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], a_bus);
        rv = [reshape(con.rv_Xequilibrium, [], 1); V; reshape(con.rv_Uequilibrium, [], 1)];
    elseif isnumeric(Point)
        if numel(Point) ~= n_var
            error(msg("GUILDA:SolverLIN:PointSize", string(numel(Point)), string(con.s_tag), string(n_var), "con"))
        end
        rv = double(Point(:));
    else
        error(msg("GUILDA:SolverLIN:PointLayer", class(con)))
    end
end


function sv = label(o, sv_name)
    sv_name = reshape(string(sv_name), [], 1);
    if isempty(sv_name)
        sv = strings(0,1);
    else
        sv = reshape(string(o.attach_tag(sv_name)), [], 1);
    end
end


function str = list_labels(sv)
% Labels for a message, at most 8
    n = numel(sv);
    str = join(sv(1:min(n,8)), ", ");
    if n > 8
        str = str + sprintf(" and %d more", n-8);
    end
end


function rv = assemble(layer, f_comp, f_bus, f_gc)
% Vector of a layer from the vectors of its components (and global controllers)
    if isa(layer, "Component")
        rv = f_comp(layer);
    elseif isa(layer, "Bus")
        [c_rows, c_idx] = layer.get_variable_map("rows");
        rv = zeros(n_rows(c_rows),1);
        for j = 1:numel(c_idx)
            rv(lin(c_idx{j}, c_rows)) = f_comp(layer.a_Component{j});
        end
        if isempty(c_idx)
            rv(size(c_rows{1},1) + (1:2)) = f_bus(layer);
        end
    elseif isa(layer, "PowerNetwork")
        [c_rows, c_idxBus, c_idxGC] = layer.get_variable_map("rows");
        rv = zeros(n_rows(c_rows),1);
        for i = 1:numel(c_idxBus)
            rv(lin(c_idxBus{i}, c_rows)) = assemble(layer.a_Bus{i}, f_comp, f_bus, f_gc);
        end
        for k = 1:numel(c_idxGC)
            rv(lin(c_idxGC{k}, c_rows)) = f_gc(layer.a_GlobalController{k});
        end
    else
        error(msg("GUILDA:SolverLIN:PointLayer", class(layer)))
    end
end

function n = n_rows(c_rows)
    % Rows x, Vre, Vim, u (the first three cells of the rows form)
    n = sum(cellfun(@(m) size(m,1), c_rows(1:3)));
end

function iv = lin(iv, c_rows)
    % The rows of iv among the variables of the linearization (the leading rows)
    iv = iv(iv <= n_rows(c_rows));
end

% ---- equilibrium ----
function rv = equilibrium_comp(comp)
    a_LC = all_controllers(comp);
    c_x  = tools.cellfun(@(c) reshape(c.rv_Xequilibrium, [], 1), a_LC);
    V    = comp.c_Vequilibrium;
    rv   = [reshape(comp.rv_Xequilibrium, [], 1); vertcat(zeros(0,1), c_x{:}); ...
            real(V); imag(V); reshape(comp.rv_Uequilibrium, [], 1)];
end

function V = equilibrium_bus(bus)
    V = [real(bus.c_Vequilibrium); imag(bus.c_Vequilibrium)];
end

function rv = equilibrium_gc(gc)
    rv = reshape(gc.rv_Xequilibrium, [], 1);
end


function list = all_controllers(parent)
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end

function str = class_name(layer)
    if isa(layer, "PowerNetwork")
        str = "net";
    elseif isa(layer, "Bus")
        str = "bus";
    else
        str = "comp";
    end
end
