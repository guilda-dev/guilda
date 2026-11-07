function h_tab = build_page(h_tabs, drawer, sct_page)
% One tab of a page of gui_content, drawn by its s_type.
    arguments (Input)
        h_tabs    % Tab group.
        drawer    % DrawerModelGUI, which an "action" page renders again.
        sct_page  % Page: fields s_title, s_type, content, s_label.
    end
    arguments (Output)
        h_tab  % The tab.
    end
    h_tab  = uitab(h_tabs, "Title", string(sct_page.s_title), "Tag", string(sct_page.s_type));
    h_grid = uigridlayout(h_tab, [1 1]);
    switch string(sct_page.s_type)
        case "latex"
            uilabel(h_grid, "Text", string(sct_page.content), "Interpreter", "latex", ...
                "FontSize", 16, "HorizontalAlignment", "center", "WordWrap", "on");
        case "ascii"
            uitextarea(h_grid, "Value", string(sct_page.content), "Editable", "off", ...
                "FontName", get(groot, "FixedWidthFontName"));
        case "image"
            uiimage(h_grid, "ImageSource", string(sct_page.content), "ScaleMethod", "fit");
        case "table"
            uitable(h_grid, "Data", sct_page.content, "ColumnEditable", false);
        case "action"
            h_grid.RowHeight   = {"fit"};
            h_grid.ColumnWidth = {"fit"};
            uibutton(h_grid, "Text", string(sct_page.s_label), ...
                "ButtonPushedFcn", @(src, ~) run_action(src, drawer, sct_page.content));
        case "custom"
            sct_page.content(h_grid);
        otherwise
            uilabel(h_grid, "Text", "Unknown page type: " + string(sct_page.s_type));
    end
end

function run_action(h_button, drawer, f_action)
% Run the action, then draw the GUI again; an error shows an alert.
    try
        f_action();
    catch ME
        show_alert(h_button, ME.message, string(h_button.Text));
        return
    end
    drawer.render();
end
