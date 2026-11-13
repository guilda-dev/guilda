function [rv_point, l_equilibrium] = point_vector(layer, point)
% Get the values of the variables of a layer at the point of get_sys.
%
% Returns the values of the variables of layer at the point (the first argument of
% get_sys), as a column vector in the order of the leading rows of
% layer.get_variable_map(): x, Vre, Vim, u for a PowerNetwork, Bus or Component; x, Vre,
% Vim, uc for a LocalController or GlobalController.
%
% - `[]`: the equilibrium, the column Equilibrium of these rows (states, inputs and bus
%   voltages set by net.initialize); l_equilibrium is true.
% - vector: used as it is; its length must be the number of these rows.
% - `{sim, t}`: the values of the simulation result sim at time t, read through its method
%   rv = sim.get_point(t, tab_map), which returns the values of the rows of tab_map
%   (ResultODE.get_point: linear interpolation between output times; at a phase
%   boundary, the value after the event). Not for a controller (GUILDA:SolverLIN:PointLayer).
% - `{sim, t, Side}`: the same, with sim.get_point(t, tab_map, Side=Side); Side "before"
%   takes the value before the event at a phase boundary.
%
% A value that is not finite stops with GUILDA:SolverLIN:PointNotFinite, naming the
% variables. The point is a point of the variables, and the network stays the one of the
% model: at a time inside a fault of {sim, t} the states are those of the fault, but the
% admittance matrix does not include the fault. The model is not changed.
    arguments (Input)
        layer          % Analysed layer (PowerNetwork, Bus, Component, LocalController or GlobalController).
        point          % Point ([], a vector, {sim, t} or {sim, t, Side}).
    end
    arguments (Output)
        rv_point       % Values of the variables of the linearization of the layer.
        l_equilibrium  % True when point is [] (the equilibrium).
    end
    SolverLIN.check_point(point);
    l_equilibrium = isempty(point) && ~iscell(point);
    l_con = isa(layer, "LocalController") || isa(layer, "GlobalController");
    if ~(l_con || isa(layer, "PowerNetwork") || isa(layer, "Bus") || isa(layer, "Component"))
        error(msg("GUILDA:SolverLIN:PointLayer", class(layer)))
    end
    tab = layer.get_variable_map();
    if l_con
        sv_kind = ["x","Vre","Vim","uc"];
    else
        sv_kind = ["x","Vre","Vim","u"];
    end
    n_var = sum(ismember(tab.Kind, sv_kind));   % the leading rows
    tab = tab(1:n_var,:);
    if l_equilibrium
        rv_point = tab.Equilibrium;
    elseif isnumeric(point)
        if numel(point) ~= n_var
            error(msg("GUILDA:SolverLIN:PointSize", string(numel(point)), string(layer.s_tag), string(n_var), class_name(layer)))
        end
        rv_point = double(point(:));
    else
        if l_con
            error(msg("GUILDA:SolverLIN:PointLayer", class(layer)))
        end
        sim = point{1};
        t   = point{2};
        if ~ismethod(sim, "get_point")
            error(msg("GUILDA:SolverLIN:PointSimType", class(sim)))
        end
        if numel(point) == 3
            rv_point = sim.get_point(t, tab, Side=point{3});
        else
            rv_point = sim.get_point(t, tab);
        end
        rv_point = double(rv_point(:));
        if numel(rv_point) ~= n_var
            error(msg("GUILDA:SolverLIN:PointSimSize", class(sim), string(numel(rv_point)), string(n_var)))
        end
    end
    lv_bad = ~isfinite(rv_point);
    if any(lv_bad)
        error(msg("GUILDA:SolverLIN:PointNotFinite", list_labels(tab.Label(lv_bad))))
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

function str = class_name(layer)
% Variable name of the layer in the message
    if isa(layer, "PowerNetwork")
        str = "net";
    elseif isa(layer, "Bus")
        str = "bus";
    elseif isa(layer, "Component")
        str = "comp";
    else
        str = "con";
    end
end
