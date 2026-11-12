function render(obj, a_target)
% Show a model: replace the GUI drawn in the container with that of a_target.
%
% An app that embeds the GUI calls it to switch the model; the breadcrumb and the child
% cards call it too. A deleted model shows a message instead.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% h = net.gui();
% h.render(net.a_Bus{2});
% ```
    arguments (Input)
        obj
        a_target (1,1) LayerPackage = obj.a_target  % Model to show (default: the one shown).
    end
    arguments (Output)
    end
    if ~isvalid(obj.h_container)
        return
    end
    % Only the grid drawn before is removed (an app may keep other components in the
    % container); the new grid takes its place in a uigridlayout container. The context
    % menu of the child cards belongs to the figure, so it is removed separately.
    h_old = obj.h_container.Children;
    h_old = h_old(arrayfun(@(c) isprop(c, "Tag") && c.Tag == "DrawerModelGUI", h_old));
    h_layout = [];
    if ~isempty(h_old)
        h_layout = h_old(1).Layout;
        h_card = findobj(h_old, "Type", "uibutton", "Tag", "child");
        if ~isempty(h_card)
            delete(unique([h_card.ContextMenu]))
        end
        delete(h_old)
    end
    obj.a_target = a_target;

    sct_color = gui_palette();
    h_grid = uigridlayout(obj.h_container, [2 2], "RowHeight", {"fit","1x"}, "ColumnWidth", {200,"1x"}, ...
        "Padding", [0 0 0 0], "RowSpacing", 0, "ColumnSpacing", 0, "Tag", "DrawerModelGUI", ...
        "BackgroundColor", sct_color.rv_background);
    if isa(h_layout, "matlab.ui.layout.GridLayoutOptions")
        h_grid.Layout = h_layout;
    end
    if ~isvalid(a_target)
        h_label = uilabel(h_grid, "Text", "The model has been deleted.", "FontWeight", "bold", ...
            "FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_background);
        h_label.Layout.Column = [1 2];
        return
    end
    if isa(obj.h_container, "matlab.ui.Figure")
        obj.h_container.Name = class(a_target) + " " + string(a_target.s_tag);
    end
    sct_model = obj.f_model(a_target);

    % Models from the root to a_target, through the parents
    a_chain = {a_target};
    a_parent = sct_model.parent;
    while true
        if iscell(a_parent)
            a_parent = [a_parent{:}];
        end
        if isempty(a_parent)
            break
        end
        a_chain = [{a_parent}, a_chain]; %#ok<AGROW>
        a_parent = obj.f_model(a_parent).parent;
    end

    h_header = build_header(h_grid, obj, a_chain);
    h_header.Layout.Row    = 1;
    h_header.Layout.Column = [1 2];
    h_tabs = uitabgroup(h_grid);
    h_tabs.Layout.Row = 2;
    % The child cards take the left column; a model without children leaves it to the tabs.
    a_children = sct_model.children;
    if any(~cellfun(@(c) isa(c, "Parameter"), a_children))
        h_nav = build_navigation(h_grid, obj, a_children);
        h_nav.Layout.Row    = 2;
        h_nav.Layout.Column = 1;
        h_tabs.Layout.Column = 2;
    else
        h_tabs.Layout.Column = [1 2];
    end
    % A Scenario has no parameters: only the pages of gui_content
    if isprop(a_target, "a_Parameter")
        build_parameter_tab(h_tabs, a_target, h_header);
    end
    for k = 1:numel(sct_model.pages)
        build_page(h_tabs, sct_model.pages(k));
    end
end
