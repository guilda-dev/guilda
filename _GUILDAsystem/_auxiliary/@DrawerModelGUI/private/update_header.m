function update_header(m_ui, drawer, a_chain)
% Write the header of the model shown: breadcrumb, then tag, class, Docs button and stale state.
%
% - Breadcrumb (Tag "breadcrumb"): the models from the root to the one shown, joined by "›".
%   Each of them but the last is a link that renders its model. The links are kept between
%   renders; the ones not needed are hidden in columns of width 0, without the Tag.
% - Docs (Tag "docs"): opens the reference page of the class, GUILDA.doc("class", class).
% - Stale state (Tag "stale"): see update_stale.
% A property is written only when its value changes, which spares the drawing of the figure.
    arguments (Input)
        m_ui      % Components of the GUI (build_frame). <@Type> containers.Map
        drawer    % DrawerModelGUI that renders a model of the breadcrumb.
        a_chain   % Models from the root to the one shown. <@Type> cell
    end
    arguments (Output)
    end
    sct_color = tools.gui_palette();
    a_target  = a_chain{end};

    % Breadcrumb: the links first (columns 1, 3, ...), then the label of the model shown
    n_link = numel(a_chain) - 1;
    h_crumb = m_ui("crumb");
    hm_link = m_ui("crumb_links");
    for k = size(hm_link, 1)+1:n_link
        hm_link(k, 1) = uihyperlink(h_crumb, "Text", "", "Tag", "breadcrumb", "FontColor", sct_color.rv_header_text, ...
            "VisitedColor", sct_color.rv_header_text, "BackgroundColor", sct_color.rv_blue);
        hm_link(k, 2) = uilabel(h_crumb, "Text", "›", "FontColor", sct_color.rv_header_subtext, ...
            "BackgroundColor", sct_color.rv_blue);
        hm_link(k, 1).Layout.Row = 1;
        hm_link(k, 2).Layout.Row = 1;
        m_ui("crumb_links") = hm_link;
    end
    n_all = size(hm_link, 1);
    c_width = [repmat({"fit"}, 1, 2*n_link + 1), repmat({0}, 1, 2*(n_all - n_link)), {"1x"}];
    if ~isequal(h_crumb.ColumnWidth, c_width) || numel(h_crumb.RowHeight) ~= 1
        set(h_crumb, "ColumnWidth", c_width, "RowHeight", {"fit"});
    end
    for k = 1:n_all
        l_show = k <= n_link;
        i_col = 2*k - 1 + double(~l_show);    % a hidden link goes after the label
        if l_show
            a_model = a_chain{k};
            set_changed(hm_link(k, 1), "Text", string(a_model.s_tag), "Tag", "breadcrumb", "Visible", "on", ...
                "Tooltip", class(a_model));
            hm_link(k, 1).UserData = a_model;
            hm_link(k, 1).HyperlinkClickedFcn = @(~, ~) drawer.render(a_model);
            set_changed(hm_link(k, 2), "Visible", "on");
        else
            set_changed(hm_link(k, 1), "Tag", "", "Visible", "off");
            hm_link(k, 1).UserData = [];
            set_changed(hm_link(k, 2), "Visible", "off");
        end
        if hm_link(k, 1).Layout.Column ~= i_col
            hm_link(k, 1).Layout.Column = i_col;
            hm_link(k, 2).Layout.Column = i_col + 1;
        end
    end
    h_last = m_ui("crumb_last");
    set_changed(h_last, "Text", string(a_target.s_tag), "Tooltip", class(a_target));
    h_last.UserData = a_target;
    if h_last.Layout.Column ~= 2*n_link + 1
        h_last.Layout.Column = 2*n_link + 1;
    end

    % Tag, class, Docs and the stale state
    s_class = string(class(a_target));
    set_changed(m_ui("tag"), "Text", string(a_target.s_tag));
    set_changed(m_ui("class"), "Text", s_class);
    h_docs = m_ui("docs");
    set_changed(h_docs, "Tooltip", "Open the reference page of " + s_class);
    h_docs.ButtonPushedFcn = @(~, ~) GUILDA.doc("class", s_class);
    update_stale(m_ui("stale"), a_target);
end
