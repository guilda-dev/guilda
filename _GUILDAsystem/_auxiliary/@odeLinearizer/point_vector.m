function [rv_point, l_equilibrium] = point_vector(layer, Point)
% Get the values of the variable map at the Point option.
%
% Returns the values of the variables of layer (a PowerNetwork, Bus or Component) at the
% point given by the Point option, as a column vector in the order of
% layer.get_variable_map().
%
% - `[]`: the equilibrium (states, inputs and bus voltages set by net.initialize);
%   l_equilibrium is true.
% - vector: used as it is; its length must be the height of the variable map.
% - `{sim, t}`: the values of the simulation result sim at time t, read through its method
%   rv = sim.get_point(t, tab_map), which returns the values of the rows of tab_map
%   (odeSimulationResult.get_point: linear interpolation between output times; at a phase
%   boundary, the value after the event).
% - `{sim, t, Side}`: the same, with sim.get_point(t, tab_map, Side=Side); Side "before"
%   takes the value before the event at a phase boundary.
%
% Point is a point of the variables, and the network stays the one of the model: at a time
% inside a fault of {sim, t} the states are those of the fault, but the admittance matrix
% does not include the fault. The model is not changed.
%
% Inputs:
% - `layer`: Analysed layer.
% - `Point`: Point option.
    arguments (Output)
        rv_point % Values in the order of layer.get_variable_map().
        l_equilibrium % True when Point is [] (the equilibrium).
    end
    odeLinearizer.check_point(Point);
    c_rows  = layer.get_variable_map("rows");
    n_var   = n_rows(c_rows);
    l_equilibrium = isempty(Point) && ~iscell(Point);

    if l_equilibrium
        rv_point = assemble(layer, @equilibrium_comp, @equilibrium_bus, @equilibrium_gc);
    elseif isnumeric(Point)
        if numel(Point) ~= n_var
            error(msg("GUILDA:odeLinearizer:PointSize", string(numel(Point)), string(layer.str_tag), string(n_var), lower(class_name(layer))))
        end
        rv_point = double(Point(:));
    else
        sim = Point{1};
        tab_map = layer.get_variable_map();
        t   = Point{2};
        if ~ismethod(sim, "get_point")
            error(msg("GUILDA:odeLinearizer:PointSimType", class(sim)))
        end
        if numel(Point) == 3
            rv_point = sim.get_point(t, tab_map, Side=Point{3});
        else
            rv_point = sim.get_point(t, tab_map);
        end
        rv_point = double(rv_point(:));
        if numel(rv_point) ~= n_var
            error(msg("GUILDA:odeLinearizer:PointSimSize", class(sim), string(numel(rv_point)), string(n_var)))
        end
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
            rv(c_idx{j}) = f_comp(layer.a_Component{j});
        end
        if isempty(c_idx)
            rv(size(c_rows{1},1) + (1:2)) = f_bus(layer);
        end
    elseif isa(layer, "PowerNetwork")
        [c_rows, c_idxBus, c_idxGC] = layer.get_variable_map("rows");
        rv = zeros(n_rows(c_rows),1);
        for i = 1:numel(c_idxBus)
            rv(c_idxBus{i}) = assemble(layer.a_Bus{i}, f_comp, f_bus, f_gc);
        end
        for k = 1:numel(c_idxGC)
            rv(c_idxGC{k}) = f_gc(layer.a_GlobalController{k});
        end
    else
        error(msg("GUILDA:odeLinearizer:PointLayer", class(layer)))
    end
end

function n = n_rows(c_rows)
    n = sum(cellfun(@(m) size(m,1), c_rows));
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
