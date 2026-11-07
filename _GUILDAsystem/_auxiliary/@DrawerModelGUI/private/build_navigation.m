function h_nav = build_navigation(h_parent, drawer, a_children)
% Child cards: the children of the model grouped by kind, without Parameter containers.
%
% The kinds come in the order Bus, Branch, Component, LocalController, GlobalController
% (then any other model), each under a label with its count (Tag "group"). A card (button,
% Tag "child") shows the kind, tag and class of a child in the color of its kind; a click
% renders it, and its context menu "Open in new window" opens it in a new uifigure. The
% area scrolls when the cards do not fit.
    arguments (Input)
        h_parent    % Grid layout that holds the cards.
        drawer      % DrawerModelGUI that renders the clicked model.
        a_children  % Children of the model shown. <@Type> cell
    end
    arguments (Output)
        h_nav  % Scrollable grid layout of the cards.
    end
    sct_color = gui_palette();
    sv_kind = ["Bus","Branch","Component","LocalController","GlobalController"];
    a_children = a_children(~cellfun(@(c) isa(c, "Parameter"), a_children));
    sv_child = repmat("Other", 1, numel(a_children));
    for s_kind = sv_kind
        sv_child(cellfun(@(c) isa(c, s_kind), a_children)) = s_kind;
    end
    sv_kind = [sv_kind, "Other"];
    sv_kind = sv_kind(ismember(sv_kind, sv_child));

    n_row = numel(sv_kind) + numel(a_children);
    h_nav = uigridlayout(h_parent, [max(n_row,1) 1], "Scrollable", "on", "Padding", [8 8 8 8], ...
        "RowSpacing", 4, "BackgroundColor", sct_color.rv_background);
    c_height = cell(1, max(n_row,1));
    h_menu = uicontextmenu(ancestor(h_parent, "figure"));
    uimenu(h_menu, "Text", "Open in new window", "MenuSelectedFcn", @(~, e) e.ContextObject.UserData.gui());
    i_row = 0;
    for s_kind = sv_kind
        a_group = a_children(sv_child == s_kind);
        i_row = i_row + 1;
        c_height{i_row} = "fit";
        uilabel(h_nav, "Text", s_kind + " (" + numel(a_group) + ")", "Tag", "group", "FontWeight", "bold", ...
            "FontColor", sct_color.rv_subtext, "BackgroundColor", sct_color.rv_background);
        for k = 1:numel(a_group)
            a_model = a_group{k};
            i_row = i_row + 1;
            c_height{i_row} = 40;
            uibutton(h_nav, "Text", [s_kind + "  " + string(a_model.s_tag); string(class(a_model))], ...
                "Tag", "child", "UserData", a_model, "HorizontalAlignment", "left", ...
                "FontColor", sct_color.rv_text, "BackgroundColor", sct_color.sct_kind.(s_kind), ...
                "ContextMenu", h_menu, "ButtonPushedFcn", @(~, ~) drawer.render(a_model));
        end
    end
    if n_row == 0
        c_height{1} = "fit";
        uilabel(h_nav, "Text", "No child models.", "FontColor", sct_color.rv_subtext, ...
            "BackgroundColor", sct_color.rv_background);
    end
    h_nav.RowHeight = c_height;
end
