function apply_selection(obj)
% Draw the selection overlay: a ring around each selected node and a wide line under each selected spring.
%
% The overlay is drawn from the positions shown and takes no clicks; the arrows (which
% share the tag of their node) have no overlay of their own.
    arguments (Input)
        obj
    end
    plt = obj.sct_plt;
    if isfield(plt, "Selection")
        delete(plt.Selection(isgraphics(plt.Selection)));
    end
    hv = gobjects(0, 1);
    tab = obj.element_table();
    rv_c = obj.SelectionColor;
    for r = find(ismember(tab.Tag, obj.Selection))'
        i = tab.Index(r);
        switch tab.Kind(r)
            case "node"
                h = plt.Node(i);
                rv_p = [mid(h.XData), mid(h.YData), mid(h.ZData)];
                hv(end+1, 1) = line(obj.ax, rv_p(1), rv_p(2), rv_p(3), "LineStyle", "none", ...
                    "Marker", "o", "MarkerSize", obj.NodeSize(i) + 10, "MarkerEdgeColor", rv_c, ...
                    "LineWidth", 3, "PickableParts", "none", "HitTest", "off"); %#ok<AGROW>
            case "edge"
                h = plt.Spring(i);
                rv_z = h.ZData;
                if isempty(rv_z)
                    rv_z = zeros(size(h.XData));
                end
                hv(end+1, 1) = line(obj.ax, h.XData, h.YData, rv_z, "Color", rv_c, ...
                    "LineWidth", obj.EdgeLineWidth(i) + 4, "PickableParts", "none", "HitTest", "off"); %#ok<AGROW>
                uistack(hv(end), "bottom");
        end
    end
    obj.sct_plt.Selection = hv;
end


function r = mid(x)
% Middle of the range of the coordinates of a graphics object (0 for none).
    arguments (Input)
        x double  % Coordinates.
    end
    arguments (Output)
        r (1,1) double  % Middle of their range.
    end
    if isempty(x)
        r = 0;
    else
        r = (min(x(:)) + max(x(:))) / 2;
    end
end
