function apply_style(obj, iv_element)
% Draw the color, label, marker, size and visibility of nodes and springs again.
    arguments (Input)
        obj
        iv_element (:,1) double  % Rows of tab_element.
    end
    tab = obj.element_table();
    plt = obj.sct_plt;
    for r = iv_element'
        i = tab.Index(r);
        switch tab.Kind(r)
            case "node"
                rv_c  = obj.NodeColor(i, :);
                l_vis = obj.NodeVisible(i);
                set(plt.Node(i), "Marker", obj.NodeMarker(i), "MarkerSize", obj.NodeSize(i), ...
                    "MarkerFaceColor", rv_c, "Visible", l_vis);
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
end
