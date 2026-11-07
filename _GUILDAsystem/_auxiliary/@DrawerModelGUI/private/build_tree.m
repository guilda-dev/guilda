function h_tree = build_tree(h_parent, drawer, a_target, sct_model)
% Tree of the parent, the model (selected) and its children, without Parameter containers.
%
% Selecting a node renders its model; the context menu opens it in a new window.
    arguments (Input)
        h_parent   % Grid layout that holds the tree.
        drawer     % DrawerModelGUI that renders the selected model.
        a_target   % Model shown.
        sct_model  % Parent and children of the model (from f_model).
    end
    arguments (Output)
        h_tree  % The uitree.
    end
    h_tree = uitree(h_parent, "SelectionChangedFcn", @(~, e) select_node(drawer, e));
    h_menu = uicontextmenu(ancestor(h_parent, "figure"));
    uimenu(h_menu, "Text", "Open in new window", "MenuSelectedFcn", @(~, e) open_node(e));
    h_tree.ContextMenu = h_menu;

    a_parent = sct_model.parent;
    if iscell(a_parent)
        a_parent = [a_parent{:}];
    end
    if isempty(a_parent)
        h_self = add_node(h_tree, a_target, h_menu);
    else
        h_up = add_node(h_tree, a_parent, h_menu);
        h_self = add_node(h_up, a_target, h_menu);
        expand(h_up)
    end
    h_self.Text = h_self.Text + "  ◀";
    a_children = sct_model.children;
    for k = 1:numel(a_children)
        if ~isa(a_children{k}, "Parameter")
            add_node(h_self, a_children{k}, h_menu);
        end
    end
    expand(h_self)
    h_tree.SelectedNodes = h_self;
end

function h_node = add_node(h_parent, a_model, h_menu)
    h_node = uitreenode(h_parent, "Text", string(a_model.s_tag) + "  (" + class(a_model) + ")", ...
        "NodeData", a_model, "ContextMenu", h_menu);
end

function select_node(drawer, e)
    if ~isempty(e.SelectedNodes) && e.SelectedNodes(1).NodeData ~= drawer.a_target
        drawer.render(e.SelectedNodes(1).NodeData);
    end
end

function open_node(e)
    h_node = e.ContextObject;
    if isa(h_node, "matlab.ui.container.TreeNode")
        h_node.NodeData.gui();
    end
end
