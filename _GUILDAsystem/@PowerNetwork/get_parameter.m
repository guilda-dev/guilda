function tab = get_parameter(obj, Group, opt)
% Return one parameter group of many elements as a table: one row per element.
%
% Group is a parameter group of tab_parameter: "powerflow", "dynamics", "operation",
% "OPF", "graph" (buses, branches, components; "dynamics" also for the controllers). The
% rows are the elements of the network (buses, branches, components, local controllers,
% global controllers, in the order of net.get_element_table) that have the group with at
% least one parameter, filtered by Key, Class and Owner; the row names are their tags,
% the columns the parameters, with the values and classes of tab_parameter.(Group). A
% global controller whose group has one row per controlled unit gives one row per unit,
% named "<controller tag>/<unit tag>".
%
% When the selected elements have different parameters (e.g. the dynamics of two governor
% models, or of an AVR and its PSS), the table has the union of their columns, in the order
% in which they first appear, and a first column Key (string): the model key of the
% element of each row (its class for an element without a key). A row gets the missing
% value of the column for a parameter its element does not have: NaN (double), <missing>
% (string), false (logical). When all selected elements have the same parameters, there
% is no Key column. Elements whose group has no parameters (e.g. the dynamics of a
% constant-impedance load) are left out.
%
% The table is a copy: edit it and write it back with net.set_parameter(Group, tab), which
% skips the Key column and the filled values of the parameters an element does not have.
% The network is not changed.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus(LocalController=true);            % with the AVRs and PSSs
% net.get_parameter("dynamics", Key="gen-1axis")          % M, D, Xd, ... of the generators
% tab = net.get_parameter("powerflow", Class="component.load.abstract");
% tab.P = 1.5*tab.P;  tab.Q = 1.5*tab.Q;                    % all loads x1.5
% net.set_parameter("powerflow", tab);
% net.get_parameter("powerflow", Class="Bus")             % V, Varg of the buses
% net.get_parameter("dynamics", Owner="B001SG1")          % AVR and PSS: union of the columns, Key column
% ```
%
% See also PowerNetwork.set_parameter, PowerNetwork.get_element_table, Parameter
%
% <@Group> Queries and display
    arguments (Input)
        obj
        Group (1,1) string        % Parameter group, e.g. "powerflow", "dynamics", "operation", "OPF", "graph".
        opt.Key   (1,:) string = strings(1,0)  % Keep the elements of these model keys (e.g. "gen-1axis", "load-impedance"; none: all).
        opt.Class (1,:) string = strings(1,0)  % Keep the elements of these classes or their subclasses (isa, e.g. "Bus", "Component", "component.load.abstract"; none: all).
        opt.Owner (1,1) string = ""            % Keep the elements below the element with this tag ("": all).
    end
    arguments (Output)
        tab table  % One row per element (row names: tags), one column per parameter of the group.
    end
    [c_elem, sv_kind, sv_parent] = element_list(obj);
    lv = sv_kind ~= "scenario";
    c_elem = c_elem(lv);  sv_parent = sv_parent(lv);
    sv_tag = string(cellfun(@(e) e.s_tag, c_elem, "UniformOutput", false));
    lv_group = cellfun(@(e) any(cellfun(@(p) p.s_tag == Group, e.a_Parameter)), c_elem);
    if ~any(lv_group) && opt.Owner == ""
        c_all  = cellfun(@(e) cellfun(@(p) char(p.s_tag), e.a_Parameter(:).', "UniformOutput", false), c_elem, "UniformOutput", false);
        sv_all = unique(string([c_all{:}]), "stable");
        error(msg("GUILDA:PowerNetwork:ParameterGroupNotFound", char(Group), char(strjoin(sv_all, ", "))))
    end
    lv_keep = lv_group;
    if opt.Owner ~= ""
        lv_keep = lv_keep & elements_below(obj, sv_tag, sv_parent, opt.Owner);
    end
    if ~isempty(opt.Key)
        lv_keep = lv_keep & cellfun(@(e) isprop(e, "key") && ismember(string(e.key), opt.Key), c_elem);
    end
    if ~isempty(opt.Class)
        lv_keep = lv_keep & cellfun(@(e) any(arrayfun(@(s) isa(e, s), opt.Class)), c_elem);
    end
    c_tab = cell(numel(c_elem), 1);
    for i = find(lv_keep).'
        e = c_elem{i};
        tab_i = e.a_Parameter{cellfun(@(p) p.s_tag == Group, e.a_Parameter)}.tab_parameter;
        if width(tab_i) == 0
            lv_keep(i) = false;
            continue
        end
        if height(tab_i) == 1
            tab_i.Properties.RowNames = cellstr(sv_tag(i));
        else
            tab_i.Properties.RowNames = cellstr(sv_tag(i) + "/" + string(tab_i.Properties.RowNames));
        end
        c_tab{i} = tab_i;
    end
    if ~any(lv_keep)
        error(msg("GUILDA:PowerNetwork:ParameterNoElement", char(Group), char(obj.s_tag)))
    end
    c_tab = c_tab(lv_keep);
    c_col = cellfun(@(t) strjoin(string(t.Properties.VariableNames), ", "), c_tab);
    if isscalar(unique(c_col))
        tab = vertcat(c_tab{:});
        return
    end
    % Different parameters: the union of the columns, the missing ones filled by class, and
    % the key of the element of each row first
    c_name = cellfun(@(t) string(t.Properties.VariableNames), c_tab, "UniformOutput", false);
    sv_union = unique([c_name{:}], "stable");
    c_keep = c_elem(lv_keep);
    for k = 1:numel(c_tab)
        tab_k = c_tab{k};
        for s_col = setdiff(sv_union, c_name{k}, "stable")
            tab_t = c_tab{find(cellfun(@(sv) ismember(s_col, sv), c_name), 1)};
            v = tab_t.(s_col)(ones(height(tab_k), 1), :);
            if islogical(v)
                v(:) = false;
            else
                v(:) = missing;
            end
            tab_k.(s_col) = v;
        end
        e = c_keep{k};
        if isprop(e, "key")
            s_key = string(e.key);
        else
            s_key = string(class(e));
        end
        tab_k = addvars(tab_k(:, sv_union), repmat(s_key, height(tab_k), 1), Before=1, NewVariableNames="Key");
        c_tab{k} = tab_k;
    end
    tab = vertcat(c_tab{:});
end
