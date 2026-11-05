function [tab, c_idxBus, c_idxGC] = get_variable_map(obj, s_form)
% Return the variable map: the order of the state, voltage and input variables.
%
% Variable map of the network: the single definition of the order of the variables of
% the network model, used by net.linearize (ResultLIN blocks and Point) and
% shared by other analyses. The order is
%   1. states x: for each bus in a_Bus, for each component in a_Component, the states
%      of the component and then of its local controllers (depth first: the AVR or
%      "local" controller, the PSS attached under the AVR, then the governor, whatever
%      the order of attachment); then the states of each global controller in
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
% The table is made once, at the end: the bus and component methods return their rows
% with get_variable_map("rows"), the cell {sm_x; sm_V; sm_u} of string matrices with
% the columns Kind, Owner, Name, Label, Bus. Analyses that only need positions use it too.
%
% <@Examples>
% ```matlab
% tab = net.get_variable_map();
% tab(tab.Kind == "x", ["Owner","Name"])
% x0 = net.linearize().rv_point;   % values in this order
% ```
%
% See also PowerNetwork.linearize, Bus.get_variable_map, Component.get_variable_map
%
% <@Group> Called by analyses
    arguments
        obj
        s_form (1,1) string {mustBeMember(s_form, ["table","rows"])} = "table" % "rows" (internal): return the rows without the table.
    end
    arguments (Output)
        tab        % One row per variable: Index, Kind, Owner, Name, Label, Bus.
        c_idxBus   % c_idxBus{i}: rows of tab that form a_Bus{i}.get_variable_map(), in its order.
        c_idxGC    % c_idxGC{k}: rows of tab with the states of a_GlobalController{k}.
    end
    a_bus = obj.a_Bus;
    a_gc  = obj.a_GlobalController;
    n_bus = numel(a_bus);

    c_bus = tools.cellfun(@(b) b.get_variable_map("rows"), a_bus);
    c_x   = tools.cellfun(@(r) r{1}, c_bus);
    c_V   = tools.cellfun(@(r) r{2}, c_bus);
    c_u   = tools.cellfun(@(r) r{3}, c_bus);
    c_gc  = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        gc = a_gc{k};
        sv_name = reshape(string(gc.sv_x), [], 1);
        n = numel(sv_name);
        sv_label = strings(0,1);
        if n > 0
            sv_label = reshape(string(gc.attach_tag(sv_name)), [], 1);
        end
        c_gc{k} = [repmat("x",n,1), repmat(string(gc.s_tag),n,1), sv_name, sv_label, strings(n,1)];
    end
    c_rows = {vertcat(strings(0,5), c_x{:}, c_gc{:}); vertcat(strings(0,5), c_V{:}); vertcat(strings(0,5), c_u{:})};

    % rows of each bus (its x, its V, its u) and of each global controller
    n_x  = cellfun(@(m) size(m,1), c_x);
    n_gc = cellfun(@(m) size(m,1), c_gc);
    n_u  = cellfun(@(m) size(m,1), c_u);
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

    if s_form == "rows"
        tab = c_rows;
        return
    end
    sm  = vertcat(c_rows{:});
    tab = table((1:size(sm,1))', sm(:,1), sm(:,2), sm(:,3), sm(:,4), sm(:,5), ...
                'VariableNames', ["Index","Kind","Owner","Name","Label","Bus"]);
end
