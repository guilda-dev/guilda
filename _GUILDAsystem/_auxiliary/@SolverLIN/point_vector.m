function [rm_point, rv_t, l_equilibrium] = point_vector(layer, point)
% Get the values of the variables of a layer at the points of get_sys.
%
% Returns the values of the variables of layer at the point (the first argument of
% get_sys), one column per section (point), in the order of the leading rows of
% layer.get_variable_map(): x, Vre, Vim, u, uc for a PowerNetwork, Bus or Component; x,
% Vre, Vim, uc for a LocalController or GlobalController. Every value is used as given:
% the inputs u of the components and uc of the controllers included, whether the
% connection map drives them or holds them at a setpoint (e.g. Vref of an AVR).
%
% rv_t (1 x n_t) holds the time of each section: the times of `{sim, rv_t}`, 1:n for a
% matrix of n columns, and NaN for the equilibrium or a vector (one section).
%
% - `[]`: the equilibrium, the column Equilibrium of these rows (states, inputs, controller
%   inputs and bus voltages set by net.initialize); l_equilibrium is true.
% - vector: used as it is; its length must be the number of these rows.
% - matrix: one point per column, each used as it is; its number of rows must be the
%   number of these rows.
% - `{sim, rv_t}`: for each time t of rv_t, the values of the simulation result sim at t, read through its method
%   rv = sim.get_point(t, tab_map), which returns the values of the rows of tab_map
%   (ResultODE.get_point: linear interpolation between output times; at a phase
%   boundary, the value after the event; the controller inputs uc included). Not for a controller (GUILDA:SolverLIN:PointLayer).
% - `{sim, rv_t, Side}`: the same, with sim.get_point(t, tab_map, Side=Side); Side "before"
%   takes the value before the event at a phase boundary.
%
% A value that is not finite stops with GUILDA:SolverLIN:PointNotFinite, naming the
% variables. The point is a point of the variables, and the network stays the one of the
% model: at a time inside a fault of {sim, t} the states are those of the fault, but the
% admittance matrix does not include the fault. The model is not changed.
    arguments (Input)
        layer  % Analysed layer (PowerNetwork, Bus, Component, LocalController or GlobalController).
        point  % Point ([], a vector, a matrix, {sim, rv_t} or {sim, rv_t, Side}).
    end
    arguments (Output)
        rm_point       % Values of the variables of the linearization of the layer: one column per section.
        rv_t           % Time of each section (1 x n_t): the times of {sim, rv_t}, 1:n for a matrix, NaN otherwise.
        l_equilibrium  % True when point is [] (the equilibrium).
    end
    SolverLIN.check_point(point);
    l_equilibrium = isempty(point) && ~iscell(point);
    l_con = isa(layer, "LocalController") || isa(layer, "GlobalController");
    if ~(l_con || isa(layer, "PowerNetwork") || isa(layer, "Bus") || isa(layer, "Component"))
        error(msg("GUILDA:SolverLIN:PointLayer", class(layer)))
    end
    tab = layer.get_variable_map();
    n_var = sum(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]));   % the leading rows
    tab = tab(1:n_var,:);
    if l_equilibrium
        rm_point = tab.Equilibrium;
        rv_t = NaN;
    elseif isnumeric(point)
        l_vector = isvector(point) && numel(point) == n_var;
        if ~l_vector && size(point,1) ~= n_var
            % the variable name of the layer in the message
            if isa(layer, "PowerNetwork")
                s_var = "net";
            elseif isa(layer, "Bus")
                s_var = "bus";
            elseif isa(layer, "Component")
                s_var = "comp";
            else
                s_var = "con";
            end
            n_given = numel(point);
            if ~isvector(point)
                n_given = size(point,1);
            end
            error(msg("GUILDA:SolverLIN:PointSize", string(n_given), string(layer.s_tag), string(n_var), s_var))
        end
        if l_vector
            rm_point = double(point(:));
            rv_t = NaN;
        else
            rm_point = double(point);
            rv_t = 1:size(point,2);
        end
    else
        if l_con
            error(msg("GUILDA:SolverLIN:PointLayer", class(layer)))
        end
        sim  = point{1};
        rv_t = reshape(double(point{2}), 1, []);
        if ~ismethod(sim, "get_point")
            error(msg("GUILDA:SolverLIN:PointSimType", class(sim)))
        end
        c_side = cell(1,0);
        if numel(point) == 3
            c_side = {"Side", point{3}};
        end
        rm_point = zeros(n_var, numel(rv_t));
        for k = 1:numel(rv_t)
            rv = double(reshape(sim.get_point(rv_t(k), tab, c_side{:}), [], 1));
            if numel(rv) ~= n_var
                error(msg("GUILDA:SolverLIN:PointSimSize", class(sim), string(numel(rv)), string(n_var)))
            end
            rm_point(:,k) = rv;
        end
    end
    lv_bad = any(~isfinite(rm_point), 2);
    if any(lv_bad)
        sv_bad = tab.Label(lv_bad);   % at most 8 in the message
        n_bad = numel(sv_bad);
        s_list = join(sv_bad(1:min(n_bad,8)), ", ");
        if n_bad > 8
            s_list = s_list + sprintf(" and %d more", n_bad-8);
        end
        error(msg("GUILDA:SolverLIN:PointNotFinite", s_list))
    end
end

