function render(obj, a_target)
% Show a model: replace the GUI drawn in the container with that of a_target.
%
% An app that embeds the GUI calls it to switch the model; the tree and the action pages
% call it too. A deleted model shows a message instead.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% h = net.gui();
% h.render(net.a_Bus{2});
% ```
    arguments (Input)
        obj
        a_target (1,1) PowerSystemModel = obj.a_target  % Model to show (default: the one shown).
    end
    arguments (Output)
    end
    if ~isvalid(obj.h_container)
        return
    end
    % Only the grid drawn before is removed (an app may keep other components in the
    % container); the new grid takes its place in a uigridlayout container. The context
    % menu of the tree belongs to the figure, so it is removed separately.
    h_old = obj.h_container.Children;
    h_old = h_old(arrayfun(@(c) isprop(c, "Tag") && c.Tag == "DrawerModelGUI", h_old));
    h_layout = [];
    if ~isempty(h_old)
        h_layout = h_old(1).Layout;
        h_tree = findobj(h_old, "Type", "uitree");
        for k = 1:numel(h_tree)
            delete(h_tree(k).ContextMenu)
        end
        delete(h_old)
    end
    obj.a_target = a_target;

    h_grid = uigridlayout(obj.h_container, [2 2], "RowHeight", {"fit","1x"}, "ColumnWidth", {260,"1x"}, ...
        "Tag", "DrawerModelGUI");
    if isa(h_layout, "matlab.ui.layout.GridLayoutOptions")
        h_grid.Layout = h_layout;
    end
    if ~isvalid(a_target)
        h_label = uilabel(h_grid, "Text", "The model has been deleted.", "FontWeight", "bold");
        h_label.Layout.Column = [1 2];
        return
    end
    if isa(obj.h_container, "matlab.ui.Figure")
        obj.h_container.Name = class(a_target) + " " + string(a_target.s_tag);
    end
    sct_model = obj.f_model(a_target);

    h_header = build_header(h_grid, a_target);
    h_header.Layout.Row    = 1;
    h_header.Layout.Column = [1 2];
    h_tree = build_tree(h_grid, obj, a_target, sct_model);
    h_tree.Layout.Row    = 2;
    h_tree.Layout.Column = 1;
    h_tabs = uitabgroup(h_grid);
    h_tabs.Layout.Row    = 2;
    h_tabs.Layout.Column = 2;
    build_parameter_tab(h_tabs, a_target, h_header);
    for k = 1:numel(sct_model.pages)
        build_page(h_tabs, obj, sct_model.pages(k));
    end
end
