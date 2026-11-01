function [tab, c_idx] = get_variable_map(obj, str_form)
% Return the variable map of the bus: the order of its Point vector.
%
% Variable map of the bus: the rows of net.get_variable_map() that belong to it, in the
% same relative order. This order defines the Point vector of bus.get_sys(Point=...):
%   1. states x of each component in a_Component (with its local controllers)
%   2. Vre, Vim of the bus
%   3. inputs u of each component
% The columns are those of PowerNetwork.get_variable_map; Index counts from 1 here.
% get_variable_map("rows") is the form used inside the map: see PowerNetwork.get_variable_map.
%
% See also PowerNetwork.get_variable_map, Bus.get_sys
    arguments
        obj
        str_form (1,1) string {mustBeMember(str_form, ["table","rows"])} = "table" % "rows" (internal): return the rows without the table.
    end
    arguments (Output)
        tab     % One row per variable: Index, Kind ("x" | "Vre" | "Vim" | "u"), Owner, Name, Label, Bus.
        c_idx   % c_idx{j}: rows of tab that form a_Component{j}.get_variable_map(), in its order.
    end
    a_comp = obj.a_Component;
    n_comp = numel(a_comp);
    c_comp = tools.cellfun(@(c) c.get_variable_map("rows"), a_comp);

    c_x  = tools.cellfun(@(r) r{1}, c_comp);
    c_u  = tools.cellfun(@(r) r{3}, c_comp);
    sv_V = string(obj.attach_tag(["Vre";"Vim"]));
    str_bus = string(obj.str_tag);
    sm_V = [["Vre";"Vim"], repmat(str_bus,2,1), ["Vre";"Vim"], sv_V(:), repmat(str_bus,2,1)];
    c_rows = {vertcat(strings(0,5), c_x{:}); sm_V; vertcat(strings(0,5), c_u{:})};

    % rows of each component: its x, the bus V, its u
    n_x   = cellfun(@(m) size(m,1), c_x);
    n_u   = cellfun(@(m) size(m,1), c_u);
    n_xall = sum(n_x);
    c_idx = cell(n_comp,1);
    for j = 1:n_comp
        iv_x = sum(n_x(1:j-1)) + (1:n_x(j));
        iv_u = n_xall + 2 + sum(n_u(1:j-1)) + (1:n_u(j));
        c_idx{j} = [iv_x, n_xall + (1:2), iv_u]';
    end

    if str_form == "rows"
        tab = c_rows;
        return
    end
    sm  = vertcat(c_rows{:});
    tab = table((1:size(sm,1))', sm(:,1), sm(:,2), sm(:,3), sm(:,4), sm(:,5), ...
                'VariableNames', ["Index","Kind","Owner","Name","Label","Bus"]);
end
