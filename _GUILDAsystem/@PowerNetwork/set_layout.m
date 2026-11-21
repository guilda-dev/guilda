function set_layout(obj, sct_layout, opt)
% Write a layout of the network diagrams into the graph parameters of the elements.
%
% sct_layout has the form of net.get_layout: the tables tab_bus, tab_branch and
% tab_component, each with the column Tag. Each row is written into the graph parameters
% of the element with that tag (a component by its full tag). Any part can be given: one
% or two of the tables, some of the rows, the column Tag and some of the graph columns;
% what is not given stays. The columns From, To and Bus of net.get_layout are read only
% and ignored.
%
% Every row is checked first, by the same rules as add_bus, add_branch and add_component
% (a bar needs a positive Length, a Path is "x y; x y", ...), and nothing is written when
% one value is wrong. A tag that is not in the network stops with
% GUILDA:PowerNetwork:LayoutUnknownTag; IgnoreUnknown=true skips such rows instead (to copy
% a layout to another network). A table or column that is not part of the layout stops
% with GUILDA:PowerNetwork:LayoutUnknownColumn. Each write is a graph edit of the element,
% which makes nothing stale.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% L = net.get_layout();
% L.tab_bus.Length(L.tab_bus.Shape == "hbar") = 0.12;
% net.set_layout(L);
%
% net2.set_layout(net.get_layout(), IgnoreUnknown=true);   % the same tags of another network
% net.set_layout(struct("tab_bus", table("B001", 0.3, 0.6, 'VariableNames', ["Tag", "X", "Y"])));
% ```
%
% See also PowerNetwork.get_layout, PowerNetwork.add_bus, PowerNetwork.add_branch, Bus.add_component
%
% <@Group> Model building
    arguments (Input)
        obj
        sct_layout        (1,1) struct           % Layout: some of the fields tab_bus, tab_branch, tab_component (tables with the column Tag).
        opt.IgnoreUnknown (1,1) logical = false  % Skip the rows whose tag is not in the network instead of stopping.
    end
    sv_field = ["tab_bus", "tab_branch", "tab_component"];
    sv_given = string(fieldnames(sct_layout)).';
    sv_bad   = setdiff(sv_given, sv_field, "stable");
    if ~isempty(sv_bad)
        error(msg("GUILDA:PowerNetwork:LayoutUnknownColumn", "sct_layout", char(strjoin(sv_bad, ", ")), char(strjoin(sv_field, ", "))))
    end
    c_comp = cellfun(@(b) b.a_Component(:), obj.a_Bus(:), 'UniformOutput', false);
    sct_elem = struct("tab_bus", {obj.a_Bus(:)}, "tab_branch", {obj.a_Branch(:)}, ...
                      "tab_component", {vertcat(cell(0, 1), c_comp{:})});
    sct_ref  = struct("tab_bus", strings(1, 0), "tab_branch", ["From", "To"], "tab_component", "Bus");

    % New graph tables of every element of the rows, all checked before any write
    c_para = cell(0, 1);
    c_new  = cell(0, 1);
    for s_field = sv_given
        tab   = sct_layout.(s_field);
        a_e   = sct_elem.(s_field);
        if ~istable(tab) || ~ismember("Tag", string(tab.Properties.VariableNames))
            error(msg("GUILDA:PowerNetwork:LayoutNoTag", char(s_field)))
        end
        sv_tag = reshape(string(cellfun(@(e) char(e.s_tag), a_e, 'UniformOutput', false)), [], 1);
        sv_col = setdiff(string(tab.Properties.VariableNames), ["Tag", sct_ref.(s_field)], "stable");
        for i_row = 1:height(tab)
            s_tag = string(tab.Tag(i_row));
            i_e   = find(sv_tag == s_tag, 1);
            if isempty(i_e)
                if opt.IgnoreUnknown
                    continue
                end
                error(msg("GUILDA:PowerNetwork:LayoutUnknownTag", char(s_field), char(s_tag), char(obj.s_tag)))
            end
            para  = a_e{i_e}.a_Parameter{cellfun(@(p) p.s_tag == "graph", a_e{i_e}.a_Parameter)};
            i_old = find(cellfun(@(p) p == para, c_para), 1);   % a tag given twice: the later row wins
            if isempty(i_old)
                tab_g = para.tab_parameter;
            else
                tab_g = c_new{i_old};
            end
            sv_known = string(tab_g.Properties.VariableNames);
            sv_bad   = setdiff(sv_col, sv_known, "stable");
            if ~isempty(sv_bad)
                error(msg("GUILDA:PowerNetwork:LayoutUnknownColumn", char(s_field), char(strjoin(sv_bad, ", ")), ...
                    char(strjoin(["Tag", sct_ref.(s_field), sv_known], ", "))))
            end
            for s_col = sv_col
                val = tab.(s_col)(i_row);
                if isstring(tab_g.(s_col))
                    val = string(val);
                    val(ismissing(val)) = "";                % an empty CSV cell (readtable)
                else
                    val = double(val);
                end
                tab_g.(s_col) = val;
            end
            para.f_validate(tab_g, s_tag);
            if isempty(i_old)
                c_para{end+1, 1} = para;                     %#ok<AGROW>
                c_new{end+1, 1}  = tab_g;                    %#ok<AGROW>
            else
                c_new{i_old} = tab_g;
            end
        end
    end

    % Write: each changed column is a graph edit of its element
    for i = 1:numel(c_para)
        c_para{i}.tab_parameter = c_new{i};
    end
end
