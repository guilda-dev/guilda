function [rv_point, l_equilibrium] = point_vector(layer, Point)
% <@Desc>
% Values of the variables of layer (a PowerNetwork, Bus or Component) at the point
% given by the Point option, as a column vector in the order of layer.get_variable_map().
%   []       : the equilibrium (states, inputs and bus voltages set by net.initialize);
%              l_equilibrium is true
%   vector   : used as it is; its length must be the height of the variable map
%   {sim, t} : the values of the simulation result sim at time t, read through its
%              method rv = sim.get_point(t, tab_map), which returns the values of the
%              rows of tab_map (odeSimulationResult.get_point: linear interpolation
%              between output times; at a phase boundary, the value after the event)
%   {sim, t, Side}: the same, with sim.get_point(t, tab_map, Side=Side); Side "before"
%              takes the value before the event at a phase boundary
% The model is not changed.
% <@Role> Static Analysis
% <@Summary> Values of the variable map at the Point option.
% <@Signatures>
% [
%   "[rv_point, l_equilibrium] = odeLinearizer.point_vector(layer, Point)"
% ]
% <@Parameters>
% [
%   {"Name": "layer", "Type": "PowerNetwork, Bus or Component", "Description": "Analysed layer.", "Required": true, "Default": "-"},
%   {"Name": "Point", "Type": "[] | double vector | cell {sim, t} or {sim, t, Side}", "Description": "Point option.", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "rv_point", "Type": "double column", "Description": "Values in the order of layer.get_variable_map()."},
%   {"Name": "l_equilibrium", "Type": "logical scalar", "Description": "True when Point is [] (the equilibrium)."}
% ]
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
        if ~ismethod(sim, "get_point")
            error("GUILDA:odeLinearizer:PointType", ...
                  "Point={sim, t} needs a simulation result with a get_point method (odeSimulationResult), not a %s.", class(sim))
        end
        if numel(Point) == 3
            rv_point = sim.get_point(t, tab_map, Side=Point{3});
        else
            rv_point = sim.get_point(t, tab_map);
        end
        rv_point = double(rv_point(:));
        if numel(rv_point) ~= n_var
            error("GUILDA:odeLinearizer:PointSize", ...
                  "%s.get_point returned %d values for %d rows of the variable map.", ...
                  class(sim), numel(rv_point), n_var)
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
