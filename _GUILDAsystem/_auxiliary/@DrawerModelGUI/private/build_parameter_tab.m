function h_tab = build_parameter_tab(h_tabs, a_target, h_header)
% Parameter tab: a note on the Docs, then one panel with an editable table per container of a_Parameter.
%
% Each table has one column per parameter; the columns fit their contents and the table
% scrolls sideways when they do not fit the tab. Its height holds the header, the rows (up
% to 8) and a horizontal scroll bar. An edited cell writes the whole table to
% tab_parameter of the container (edit_parameter).
    arguments (Input)
        h_tabs    % Tab group.
        a_target  % Model shown.
        h_header  % Header, whose stale label is updated after an edit.
    end
    arguments (Output)
        h_tab  % The Parameter tab.
    end
    sct_color = gui_palette();
    h_tab = uitab(h_tabs, "Title", "Parameter", "BackgroundColor", sct_color.rv_background, ...
        "ForegroundColor", sct_color.rv_text);
    a_para = a_target.a_Parameter;
    n_para = numel(a_para);
    h_grid = uigridlayout(h_tab, [n_para+1 1], "RowHeight", repmat({"fit"}, 1, n_para+1), ...
        "Padding", [8 8 8 8], "Scrollable", "on", "BackgroundColor", sct_color.rv_background);
    uilabel(h_grid, "Text", "See Docs for the meaning of each parameter and the model.", "Tag", "note", ...
        "FontAngle", "italic", "FontColor", sct_color.rv_subtext, "BackgroundColor", sct_color.rv_background);
    if n_para == 0
        h_grid.RowHeight{end+1} = "fit";
        uilabel(h_grid, "Text", "No parameters.", "FontColor", sct_color.rv_text, ...
            "BackgroundColor", sct_color.rv_background);
        return
    end
    h_stale = findobj(h_header, "Tag", "stale");
    for k = 1:n_para
        p = a_para{k};
        h_panel = uipanel(h_grid, "Title", string(p.s_tag), "FontWeight", "bold", ...
            "BackgroundColor", sct_color.rv_card, "ForegroundColor", sct_color.rv_text, ...
            "BorderColor", sct_color.rv_stripe);
        h_inner = uigridlayout(h_panel, [1 1], "Padding", [4 4 4 4], "BackgroundColor", sct_color.rv_card);
        tab = p.tab_parameter;
        h_table = uitable(h_inner, "Data", tab, "ColumnEditable", true, "Tag", string(p.s_tag), ...
            "ColumnWidth", "fit", "RowStriping", "on", ...
            "BackgroundColor", [sct_color.rv_card; sct_color.rv_stripe], "ForegroundColor", sct_color.rv_text, ...
            "CellEditCallback", @(src, ~) edit_parameter(src, p, a_target, h_stale));
        if ~isempty(tab.Properties.RowNames)
            h_table.RowName = tab.Properties.RowNames;
        end
        % Header and rows of about 24 px, and room for the horizontal scroll bar.
        h_inner.RowHeight = {30 + 24*min(max(height(tab),1), 8) + 18};
    end
end
