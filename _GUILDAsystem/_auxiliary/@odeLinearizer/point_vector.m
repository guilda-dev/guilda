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
% - `{sim, t}`: the values of the simulation result sim at time t (linear interpolation
%   between output times; at an event time, the value after the event).
%   A result class with a method rv = get_point(sim, t, tab_map), which returns
%   the values of the rows of tab_map, is read through that method; an
%   odeSimulationResult is read directly (see below).
%
% An odeSimulationResult does not store the states of local or global controllers, so a
% layer that has controllers stops with GUILDA:odeLinearizer:PointUnavailable.
% The model is not changed.
%
% Inputs:
% - `layer`: Analysed layer.
% - `Point`: Point option.
    arguments (Output)
        rv_point % Values in the order of layer.get_variable_map().
        l_equilibrium % True when Point is [] (the equilibrium).
    end
    odeLinearizer.check_point(Point);
    tab_map = layer.get_variable_map();
    n_var   = height(tab_map);
    l_equilibrium = isempty(Point) && ~iscell(Point);

    if l_equilibrium
        rv_point = assemble(layer, @equilibrium_comp, @equilibrium_bus, @equilibrium_gc);
    elseif isnumeric(Point)
        if numel(Point) ~= n_var
            error("GUILDA:odeLinearizer:PointSize", ...
                  "Point has %d values, but the variable map of '%s' has %d rows. " + ...
                  "Give the values in the order of %s.get_variable_map().", ...
                  numel(Point), string(layer.str_tag), n_var, lower(class_name(layer)))
        end
        rv_point = double(Point(:));
    else
        sim = Point{1};
        t   = Point{2};
        if ismethod(sim, "get_point")
            rv_point = sim.get_point(t, tab_map);
            rv_point = double(rv_point(:));
            if numel(rv_point) ~= n_var
                error("GUILDA:odeLinearizer:PointSize", ...
                      "%s.get_point returned %d values for %d rows of the variable map.", ...
                      class(sim), numel(rv_point), n_var)
            end
        elseif isa(sim, "odeSimulationResult")
            rv_point = assemble(layer, @(c) simulation_comp(c, sim, t), @(b) simulation_bus(b, sim, t), @simulation_gc);
        else
            error("GUILDA:odeLinearizer:PointType", ...
                  "Point={sim, t} needs a simulation result (odeSimulationResult), not a %s.", class(sim))
        end
    end
end


function rv = assemble(layer, f_comp, f_bus, f_gc)
% Vector of a layer from the vectors of its components (and global controllers)
    if isa(layer, "Component")
        rv = f_comp(layer);
    elseif isa(layer, "Bus")
        [tab, c_idx] = layer.get_variable_map();
        rv = zeros(height(tab),1);
        for j = 1:numel(c_idx)
            rv(c_idx{j}) = f_comp(layer.a_Component{j});
        end
        if isempty(c_idx)
            rv(tab.Kind == "Vre" | tab.Kind == "Vim") = f_bus(layer);
        end
    elseif isa(layer, "PowerNetwork")
        [tab, c_idxBus, c_idxGC] = layer.get_variable_map();
        rv = zeros(height(tab),1);
        for i = 1:numel(c_idxBus)
            rv(c_idxBus{i}) = assemble(layer.a_Bus{i}, f_comp, f_bus, f_gc);
        end
        for k = 1:numel(c_idxGC)
            rv(c_idxGC{k}) = f_gc(layer.a_GlobalController{k});
        end
    else
        error("GUILDA:odeLinearizer:PointLayer", ...
              "Point is defined for a PowerNetwork, Bus or Component, not a %s.", class(layer))
    end
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


% ---- odeSimulationResult ----
function rv = simulation_comp(comp, sim, t)
    if ~isempty(comp.a_LocalController)
        error("GUILDA:odeLinearizer:PointUnavailable", ...
              "odeSimulationResult does not store the states of the local controllers of '%s'. " + ...
              "Give Point as a vector in the order of get_variable_map().", string(comp.str_tag))
    end
    [i, j] = indices(comp.a_Bus, comp);
    s_comp = sim.odeResults.Bus(i).Component(j);
    rv = [value_at(sim, s_comp.X{:,:}, t).'; simulation_bus(comp.a_Bus, sim, t); value_at(sim, s_comp.U{:,:}, t).'];
end

function V = simulation_bus(bus, sim, t)
    i = indices(bus, []);
    V = value_at(sim, sim.odeResults.Bus(i).V{:,:}, t).';
end

function rv = simulation_gc(gc)
    error("GUILDA:odeLinearizer:PointUnavailable", ...
          "odeSimulationResult does not store the states of the global controller '%s'. " + ...
          "Give Point as a vector in the order of net.get_variable_map().", string(gc.str_tag))
    rv = []; %#ok<UNRCH>
end

function [i, j] = indices(bus, comp)
% Position of the bus in its network and of comp in the bus (the result is indexed so)
    net = bus.a_PowerNetwork;
    if isempty(net)
        error("GUILDA:odeLinearizer:PointUnavailable", ...
              "Bus '%s' is not in a network, so it cannot be found in the simulation result.", string(bus.str_tag))
    end
    i = find(cellfun(@(b) b == bus, net.a_Bus), 1);
    j = [];
    if ~isempty(comp)
        j = find(cellfun(@(c) c == comp, bus.a_Component), 1);
    end
end

function rv = value_at(sim, M, t)
% Row of M at time t (linear interpolation; at a repeated time, the last row)
    tv = sim.odeResults.t(:);
    if isempty(tv) || t < tv(1) || t > tv(end)
        error("GUILDA:odeLinearizer:PointTime", ...
              "t = %g is outside the simulated time [%g, %g].", t, tv(1), tv(end))
    end
    k = find(tv == t, 1, "last");
    if ~isempty(k)
        rv = M(k,:);
        return
    end
    k = find(tv < t, 1, "last");
    w = (t - tv(k)) / (tv(k+1) - tv(k));
    rv = (1-w) * M(k,:) + w * M(k+1,:);
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
