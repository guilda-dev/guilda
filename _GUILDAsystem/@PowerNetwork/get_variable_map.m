function [tab, c_idxBus, c_idxGC] = get_variable_map(obj)
% Return the variable map: the order of the state, voltage and input variables.
%
% Variable map of the network: the single definition of the order of the variables of
% the network model, used by net.linearize (LinearizationResult blocks and Point) and
% shared by other analyses. The order is
%   1. states x: for each bus in a_Bus, for each component in a_Component, the states
%      of the component and then of its local controllers (depth first: an AVR, then
%      the PSS attached under it); then the states of each global controller in
%      a_GlobalController
%   2. bus voltages: Vre, Vim of each bus in a_Bus (interleaved: B1 Vre, B1 Vim, B2 Vre, ...)
%   3. inputs u: for each bus, for each component, the inputs sv_u of the component
% The map of a bus or a component (bus.get_variable_map, comp.get_variable_map) is the
% restriction of this map to its rows, in the same relative order.
% Columns: Index (row number), Kind ("x" | "Vre" | "Vim" | "u"), Owner (tag of the
% component, controller or bus that owns the variable), Name (variable name, e.g.
% "delta"), Label (tagged name, equal to the StateName / InputName used by get_sys),
% Bus (tag of the bus the owner is attached to; "" for a global controller).
% A table is used so that the map prints as is and can be filtered with the usual
% table operations (tab(tab.Kind == "x", :)); the Label column is the key that links it
% to state-space models and results.
%
% <@Examples>
% ```matlab
% tab = net.get_variable_map();
% tab(tab.Kind == "x", ["Owner","Name"])
% x0 = net.linearize().rv_point;   % values in this order
% ```
%
% See also PowerNetwork.linearize, Bus.get_variable_map, Component.get_variable_map
    arguments (Output)
        tab        % One row per variable: Index, Kind, Owner, Name, Label, Bus.
        c_idxBus   % c_idxBus{i}: rows of tab that form a_Bus{i}.get_variable_map(), in its order.
        c_idxGC    % c_idxGC{k}: rows of tab with the states of a_GlobalController{k}.
    end
    a_bus = obj.a_Bus;
    a_gc  = obj.a_GlobalController;
    n_bus = numel(a_bus);

    c_tab = tools.cellfun(@(b) b.get_variable_map(), a_bus);
    c_x   = tools.cellfun(@(t) t(t.Kind == "x", 2:end), c_tab);
    c_V   = tools.cellfun(@(t) t(t.Kind == "Vre" | t.Kind == "Vim", 2:end), c_tab);
    c_u   = tools.cellfun(@(t) t(t.Kind == "u", 2:end), c_tab);
    c_gc  = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        gc = a_gc{k};
        sv_name = reshape(string(gc.sv_x), [], 1);
        n = numel(sv_name);
        sv_label = strings(0,1);
        if n > 0
            sv_label = reshape(string(gc.attach_tag(sv_name)), [], 1);
        end
        c_gc{k} = table(repmat("x",n,1), repmat(string(gc.str_tag),n,1), sv_name, sv_label, strings(n,1), ...
                        'VariableNames', ["Kind","Owner","Name","Label","Bus"]);
    end

    tab_0 = table(strings(0,1), strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
                  'VariableNames', ["Kind","Owner","Name","Label","Bus"]);
    tab = [vertcat(tab_0, c_x{:}); vertcat(tab_0, c_gc{:}); vertcat(tab_0, c_V{:}); vertcat(tab_0, c_u{:})];
    tab = [table((1:height(tab))', 'VariableNames', "Index"), tab];

    % rows of each bus (its x, its V, its u) and of each global controller
    n_x  = cellfun(@height, c_x);
    n_gc = cellfun(@height, c_gc);
    n_u  = cellfun(@height, c_u);
    n_xall = sum(n_x) + sum(n_gc);
    c_idxBus = cell(n_bus,1);
    for i = 1:n_bus
        iv_x = sum(n_x(1:i-1)) + (1:n_x(i));
        iv_V = n_xall + 2*(i-1) + (1:2);
        iv_u = n_xall + 2*n_bus + sum(n_u(1:i-1)) + (1:n_u(i));
        c_idxBus{i} = [iv_x, iv_V, iv_u]';
    end
    c_idxGC = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        c_idxGC{k} = (sum(n_x) + sum(n_gc(1:k-1)) + (1:n_gc(k)))';
    end
end
