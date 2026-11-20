function [c_elem, sv_kind, sv_parent, sv_bus] = element_list(net)
% Elements of the network, one row each: buses, branches, components (bus by bus), local
% controllers (component by component, depth first), global controllers, scenarios.
%
% Shared by get_element, get_element_table, get_parameter and set_parameter.
    arguments (Input)
        net PowerNetwork  % Network whose elements are listed.
    end
    arguments (Output)
        c_elem    (:,1) cell    % Element objects.
        sv_kind   (:,1) string  % "bus", "branch", "component", "local", "global" or "scenario".
        sv_parent (:,1) string  % Tag of the parent element ("" under the network).
        sv_bus    (:,1) string  % Tag of the bus the element belongs to (a bus: itself; "" for the others).
    end
    a_bus  = net.a_Bus;
    c_comp = cell(0,1);   sv_compBus = strings(0,1);
    c_lc   = cell(0,1);   sv_lcBus   = strings(0,1);
    for i = 1:numel(a_bus)
        for j = 1:numel(a_bus{i}.a_Component)
            comp = a_bus{i}.a_Component{j};
            c_comp{end+1,1} = comp;                          %#ok<AGROW>
            c_k = all_controllers(comp);
            c_lc = [c_lc; c_k];                              %#ok<AGROW>
            sv_lcBus = [sv_lcBus; repmat(a_bus{i}.s_tag, numel(c_k), 1)]; %#ok<AGROW>
        end
        sv_compBus = [sv_compBus; repmat(a_bus{i}.s_tag, numel(a_bus{i}.a_Component), 1)]; %#ok<AGROW>
    end
    n = [numel(a_bus), numel(net.a_Branch), numel(c_comp), numel(c_lc), numel(net.a_GlobalController), numel(net.a_Scenario)];
    c_elem  = [a_bus; net.a_Branch; c_comp; c_lc; net.a_GlobalController; net.a_Scenario];
    sv_kind = repelem(["bus"; "branch"; "component"; "local"; "global"; "scenario"], n);
    sv_parent = [strings(n(1)+n(2),1); sv_compBus; ...
                 string(cellfun(@(c) c.a_Component.s_tag, c_lc, "UniformOutput", false)); strings(n(5)+n(6),1)];
    sv_bus  = [string(cellfun(@(b) b.s_tag, a_bus, "UniformOutput", false)); strings(n(2),1); sv_compBus; sv_lcBus; strings(n(5)+n(6),1)];
end
