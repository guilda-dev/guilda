function h_tab = build_parameter_tab(h_tabs, a_target, h_header)
% Parameter tab: one panel with an editable table per container of a_Parameter.
%
% An edited cell writes the whole table to tab_parameter of the container (edit_parameter).
    arguments (Input)
        h_tabs    % Tab group.
        a_target  % Model shown.
        h_header  % Header, whose stale label is updated after an edit.
    end
    arguments (Output)
        h_tab  % The Parameter tab.
    end
    h_tab = uitab(h_tabs, "Title", "Parameter");
    a_para = a_target.a_Parameter;
    n_para = numel(a_para);
    h_grid = uigridlayout(h_tab, [max(n_para,1) 1], "RowHeight", repmat({"fit"}, 1, max(n_para,1)), ...
        "Scrollable", "on");
    if n_para == 0
        uilabel(h_grid, "Text", "No parameters.");
        return
    end
    h_stale = findobj(h_header, "Tag", "stale");
    for k = 1:n_para
        p = a_para{k};
        h_panel = uipanel(h_grid, "Title", string(p.s_tag), "FontWeight", "bold");
        h_inner = uigridlayout(h_panel, [1 1], "Padding", [4 4 4 4]);
        tab = p.tab_parameter;
        h_table = uitable(h_inner, "Data", tab, "ColumnEditable", true, "Tag", string(p.s_tag), ...
            "CellEditCallback", @(src, ~) edit_parameter(src, p, a_target, h_stale));
        if ~isempty(tab.Properties.RowNames)
            h_table.RowName = tab.Properties.RowNames;
        end
        % Rows of about 24 px under the header: a few rows fit without a scroll bar.
        h_inner.RowHeight = {min(34 + 24*height(tab), 240)};
    end
end
