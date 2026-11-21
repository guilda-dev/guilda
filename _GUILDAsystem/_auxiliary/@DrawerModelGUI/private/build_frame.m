function build_frame(h_container, m_ui)
% Build the components that every render keeps: the grid, the header, the left column with the child table, and the body.
%
% The grid drawn before in the container is removed first (clear_gui); a uigridlayout
% container keeps its cell for the new grid. The handles go into m_ui by name:
%
% - grid: the grid of the GUI (Tag "DrawerModelGUI"), header on top, left column and body below.
% - crumb, crumb_links, crumb_last: the breadcrumb grid, its links with their "›" ([link, sep]
%   per row, made by update_header as needed) and the label of the model shown.
% - tag, class, docs, stale: the second row of the header.
% - left: the left column (add buttons over the child table); add:<key> the grid of the add
%   buttons of one kind of model (made by render as needed).
% - nav, kind, search, menu, open, remove: the drop-down, the search field, the context menu
%   of the child tables and its items (Remove and the callbacks are made by
%   update_navigation); child_tables, children: the tables of the children, one per set of
%   columns, and the one shown (made by update_navigation).
% - body: the uihtml of the Parameter tab and the pages (model_body.html; render writes its
%   Data, body_data).
% - spare: every part that a render may detach from the grid and attach again, removed with
%   the grid by clear_gui.
    arguments (Input)
        h_container  % Container of the GUI.
        m_ui         % Components kept between renders (the drawer's, emptied here). <@Type> containers.Map
    end
    arguments (Output)
    end
    h_layout = clear_gui(h_container, m_ui);
    sct_color = tools.gui_palette();
    h_grid = uigridlayout(h_container, [2 2], "RowHeight", {"fit","1x"}, "ColumnWidth", {300,"1x"}, ...
        "Padding", [0 0 0 0], "RowSpacing", 0, "ColumnSpacing", 0, "Tag", "DrawerModelGUI", ...
        "BackgroundColor", sct_color.rv_background);
    if isa(h_layout, "matlab.ui.layout.GridLayoutOptions")
        h_grid.Layout = h_layout;
    end
    m_ui("grid") = h_grid;

    % Header: the blue band over a lime line
    h_header = uigridlayout(h_grid, [2 1], "RowHeight", {"fit", 3}, "Padding", [0 0 0 0], ...
        "RowSpacing", 0, "BackgroundColor", sct_color.rv_lime);
    h_header.Layout.Row    = 1;
    h_header.Layout.Column = [1 2];
    h_band = uigridlayout(h_header, [2 1], "RowHeight", {"fit","fit"}, "Padding", [10 6 10 6], ...
        "RowSpacing", 2, "BackgroundColor", sct_color.rv_blue);
    h_crumb = uigridlayout(h_band, [1 2], "ColumnWidth", {"fit", "1x"}, ...
        "Padding", [0 0 0 0], "ColumnSpacing", 4, "BackgroundColor", sct_color.rv_blue);
    m_ui("crumb") = h_crumb;
    m_ui("crumb_links") = gobjects(0, 2);
    m_ui("crumb_last") = uilabel(h_crumb, "Text", "", "Tag", "breadcrumb", "FontWeight", "bold", ...
        "FontColor", sct_color.rv_header_text, "BackgroundColor", sct_color.rv_blue);
    h_info = uigridlayout(h_band, [1 4], "ColumnWidth", {"fit","fit","fit","1x"}, "Padding", [0 0 0 0], ...
        "ColumnSpacing", 10, "BackgroundColor", sct_color.rv_blue);
    m_ui("tag") = uilabel(h_info, "Text", "", "FontSize", 16, "FontWeight", "bold", ...
        "FontColor", sct_color.rv_header_text, "BackgroundColor", sct_color.rv_blue);
    m_ui("class") = uilabel(h_info, "Text", "", "FontColor", sct_color.rv_header_subtext, ...
        "BackgroundColor", sct_color.rv_blue);
    m_ui("docs") = uibutton(h_info, "Text", "Docs", "Tag", "docs", "FontWeight", "bold", ...
        "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_card);
    m_ui("stale") = uilabel(h_info, "Tag", "stale", "WordWrap", "on", "Text", "");

    % Left column: add buttons over the child table
    h_left = uigridlayout(h_grid, [2 1], "RowHeight", {"fit", "1x"}, "Padding", 0, "RowSpacing", 0, ...
        "BackgroundColor", sct_color.rv_background);
    h_left.Layout.Row    = 2;
    h_left.Layout.Column = 1;
    m_ui("left") = h_left;
    h_nav = uigridlayout(h_left, [2 2], "RowHeight", {"fit", "1x"}, "ColumnWidth", {"1x", "1x"}, ...
        "Padding", [8 8 8 8], "RowSpacing", 4, "ColumnSpacing", 4, "BackgroundColor", sct_color.rv_background);
    h_nav.Layout.Row = 2;
    m_ui("nav") = h_nav;
    m_ui("kind") = uidropdown(h_nav, "Items", {''}, "Tag", "kind", ...
        "FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_card, ...
        "Tooltip", "Kind of the child models shown in the table");
    m_ui("search") = uieditfield(h_nav, "text", "Tag", "search", "Placeholder", "Search", ...
        "FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_card, ...
        "Tooltip", "Keep the rows that contain this text (any column)");
    h_menu = uicontextmenu(ancestor(h_container, "figure"));
    m_ui("menu") = h_menu;
    m_ui("open") = uimenu(h_menu, "Text", "Open in new window");
    m_ui("child_tables") = struct("s_key", {}, "table", {});

    % Body: the Parameter tab and the pages, drawn by model_body.html from its Data (body_data)
    h_body = uihtml(h_grid, "HTMLSource", fullfile(fileparts(mfilename("fullpath")), "model_body.html"), ...
        "Tag", "body");
    h_body.Layout.Row = 2;
    h_body.Layout.Column = 2;
    m_ui("body") = h_body;
    m_ui("spare") = [h_left; h_nav; h_menu];
end
