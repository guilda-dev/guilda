function h_header = build_header(h_parent, drawer, a_chain)
% Header band: breadcrumb, then tag, class, Docs button and stale state, over a lime line.
%
% - Breadcrumb (Tag "breadcrumb"): the models from the root to the one shown, joined by "›".
%   Each of them but the last is a link that renders its model.
% - Docs (Tag "docs"): opens the reference page of the class, GUILDA.doc("class", class).
% - Stale state (Tag "stale"): see update_stale.
    arguments (Input)
        h_parent  % Grid layout that holds the header.
        drawer    % DrawerModelGUI that renders a model of the breadcrumb.
        a_chain   % Models from the root to the one shown. <@Type> cell
    end
    arguments (Output)
        h_header  % Grid layout of the header.
    end
    sct_color = gui_palette();
    a_target  = a_chain{end};
    h_header = uigridlayout(h_parent, [2 1], "RowHeight", {"fit", 3}, "Padding", [0 0 0 0], ...
        "RowSpacing", 0, "BackgroundColor", sct_color.rv_lime);
    h_band = uigridlayout(h_header, [2 1], "RowHeight", {"fit","fit"}, "Padding", [10 6 10 6], ...
        "RowSpacing", 2, "BackgroundColor", sct_color.rv_blue);

    % Breadcrumb
    n_chain = numel(a_chain);
    h_crumb = uigridlayout(h_band, [1 2*n_chain], "ColumnWidth", [repmat({"fit"}, 1, 2*n_chain-1), {"1x"}], ...
        "Padding", [0 0 0 0], "ColumnSpacing", 4, "BackgroundColor", sct_color.rv_blue);
    for k = 1:n_chain
        a_model = a_chain{k};
        s_text  = string(a_model.s_tag);
        if k < n_chain
            uihyperlink(h_crumb, "Text", s_text, "Tag", "breadcrumb", "UserData", a_model, ...
                "Tooltip", class(a_model), "FontColor", sct_color.rv_header_text, ...
                "VisitedColor", sct_color.rv_header_text, "BackgroundColor", sct_color.rv_blue, ...
                "HyperlinkClickedFcn", @(~, ~) drawer.render(a_model));
            uilabel(h_crumb, "Text", "›", "FontColor", sct_color.rv_header_subtext, ...
                "BackgroundColor", sct_color.rv_blue);
        else
            uilabel(h_crumb, "Text", s_text, "Tag", "breadcrumb", "UserData", a_model, ...
                "Tooltip", class(a_model), "FontWeight", "bold", "FontColor", sct_color.rv_header_text, ...
                "BackgroundColor", sct_color.rv_blue);
        end
    end

    % Tag, class, Docs and the stale state
    s_class = string(class(a_target));
    h_info = uigridlayout(h_band, [1 4], "ColumnWidth", {"fit","fit","fit","1x"}, "Padding", [0 0 0 0], ...
        "ColumnSpacing", 10, "BackgroundColor", sct_color.rv_blue);
    uilabel(h_info, "Text", string(a_target.s_tag), "FontSize", 16, "FontWeight", "bold", ...
        "FontColor", sct_color.rv_header_text, "BackgroundColor", sct_color.rv_blue);
    uilabel(h_info, "Text", s_class, "FontColor", sct_color.rv_header_subtext, ...
        "BackgroundColor", sct_color.rv_blue);
    uibutton(h_info, "Text", "Docs", "Tag", "docs", "Tooltip", "Open the reference page of " + s_class, ...
        "FontWeight", "bold", "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_card, ...
        "ButtonPushedFcn", @(~, ~) GUILDA.doc("class", s_class));
    h_stale = uilabel(h_info, "Tag", "stale", "WordWrap", "on");
    update_stale(h_stale, a_target);
end
