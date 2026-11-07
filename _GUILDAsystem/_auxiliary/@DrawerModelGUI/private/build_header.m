function h_header = build_header(h_parent, a_target)
% Header: class and tag, and below them the stale state (label tagged "stale").
    arguments (Input)
        h_parent  % Grid layout that holds the header.
        a_target  % Model shown.
    end
    arguments (Output)
        h_header  % Grid layout of the header.
    end
    h_header = uigridlayout(h_parent, [2 1], "RowHeight", {"fit","fit"}, "Padding", [0 0 0 0], "RowSpacing", 2);
    uilabel(h_header, "Text", string(a_target.s_tag) + "   (" + class(a_target) + ")", ...
        "FontSize", 16, "FontWeight", "bold");
    h_stale = uilabel(h_header, "Tag", "stale", "WordWrap", "on");
    update_stale(h_stale, a_target);
end
