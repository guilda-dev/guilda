function apply_style(obj, iv_element)
% Draw the color, label, marker, size and visibility of nodes and springs again.
%
% A node whose marker changes between a cone ("v") and a sphere needs a new surface: the
% scene is built again. A node whose size changes is moved again with the sample shown.
    arguments (Input)
        obj
        iv_element (:,1) double  % Rows of tab_element.
    end
    tab = obj.element_table();
    plt = obj.sct_plt;
    l_move = false;
    for r = iv_element'
        i = tab.Index(r);
        switch tab.Kind(r)
            case "node"
                h = plt.Node(i);
                if (h.UserData.Marker == "v") ~= (obj.NodeMarker(i) == "v")
                    obj.create_scene();
                    obj.update_scene(obj.i_time);
                    obj.apply_selection();
                    return
                end
                rv_c  = obj.NodeColor(i, :);
                l_vis = obj.NodeVisible(i);
                l_move = l_move || h.UserData.Size ~= obj.NodeSize(i);
                set(h, "FaceColor", rv_c, "Visible", l_vis, ...
                    "UserData", struct("Marker", obj.NodeMarker(i), "Size", obj.NodeSize(i)));
                set(plt.LabelNode(i), "String", obj.NodeLabel(i), "Color", 0.7*rv_c, ...
                    "Visible", l_vis && obj.ShowLabel);
                if isgraphics(plt.Circle(i))
                    set(plt.Circle(i), "Color", rv_c, "Visible", l_vis);
                end
            case "edge"
                set(plt.Spring(i), "Color", obj.EdgeColor(i, :), "LineWidth", obj.EdgeLineWidth(i), ...
                    "Visible", obj.EdgeVisible(i));
        end
    end
    if l_move
        obj.update_scene(obj.i_time);
        obj.apply_selection();
    end
end
