function [tab, c_idx] = get_variable_map(obj)
% <@Desc>
% Variable map of the bus: the rows of net.get_variable_map() that belong to it, in the
% same relative order. This order defines the Point vector of bus.get_sys(Point=...):
%   1. states x of each component in a_Component (with its local controllers)
%   2. Vre, Vim of the bus
%   3. inputs u of each component
% The columns are those of PowerNetwork.get_variable_map; Index counts from 1 here.
% <@Role> Static Analysis
% <@Summary> Variable map (order of the Point vector) of the bus.
% <@Signatures>
% [
%   "tab = bus.get_variable_map()",
%   "[tab, c_idx] = bus.get_variable_map()"
% ]
% <@Returns>
% [
%   {"Name": "tab", "Type": "table", "Description": "One row per variable: Index, Kind (\"x\" | \"Vre\" | \"Vim\" | \"u\"), Owner, Name, Label, Bus."},
%   {"Name": "c_idx", "Type": "cell column", "Description": "c_idx{j}: rows of tab that form a_Component{j}.get_variable_map(), in its order."}
% ]
    a_comp = obj.a_Component;
    n_comp = numel(a_comp);
    c_tab  = tools.cellfun(@(c) c.get_variable_map(), a_comp);

    c_x = tools.cellfun(@(t) t(t.Kind == "x", 2:end), c_tab);
    c_u = tools.cellfun(@(t) t(t.Kind == "u", 2:end), c_tab);
    sv_V = string(obj.attach_tag(["Vre";"Vim"]));
    sv_V = sv_V(:);
    tab_V = table(["Vre";"Vim"], repmat(string(obj.str_tag),2,1), ["Vre";"Vim"], sv_V, ...
                  repmat(string(obj.str_tag),2,1), 'VariableNames', ["Kind","Owner","Name","Label","Bus"]);

    tab = [vertcat(tab_V([],:), c_x{:}); tab_V; vertcat(tab_V([],:), c_u{:})];
    tab = [table((1:height(tab))', 'VariableNames', "Index"), tab];

    % rows of each component: its x, the bus V, its u
    n_x   = cellfun(@height, c_x);
    n_u   = cellfun(@height, c_u);
    n_xall = sum(n_x);
    c_idx = cell(n_comp,1);
    for j = 1:n_comp
        iv_x = sum(n_x(1:j-1)) + (1:n_x(j));
        iv_u = n_xall + 2 + sum(n_u(1:j-1)) + (1:n_u(j));
        c_idx{j} = [iv_x, n_xall + (1:2), iv_u]';
    end
end
