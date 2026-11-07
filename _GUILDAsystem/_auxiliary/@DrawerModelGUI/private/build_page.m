function h_tab = build_page(h_tabs, sct_page)
% One tab of a page of gui_content: a read-only table that fills the tab.
%
% The columns fit their contents; the table scrolls when it does not fit the tab.
    arguments (Input)
        h_tabs    % Tab group.
        sct_page  % Page: fields s_title, s_type ("table") and content.
    end
    arguments (Output)
        h_tab  % The tab.
    end
    sct_color = gui_palette();
    h_tab  = uitab(h_tabs, "Title", string(sct_page.s_title), "Tag", string(sct_page.s_type), ...
        "BackgroundColor", sct_color.rv_background, "ForegroundColor", sct_color.rv_text);
    h_grid = uigridlayout(h_tab, [1 1], "Padding", [8 8 8 8], "BackgroundColor", sct_color.rv_background);
    if string(sct_page.s_type) == "table"
        uitable(h_grid, "Data", sct_page.content, "ColumnEditable", false, "ColumnWidth", "fit", ...
            "RowStriping", "on", "BackgroundColor", [sct_color.rv_card; sct_color.rv_stripe], ...
            "ForegroundColor", sct_color.rv_text);
    else
        uilabel(h_grid, "Text", "Unknown page type: " + string(sct_page.s_type), ...
            "FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_background);
    end
end
