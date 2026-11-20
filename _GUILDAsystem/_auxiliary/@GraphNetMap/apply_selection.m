function apply_selection(obj)
% Draw the selection overlay: rings around the selected buses, wide lines over the selected branches.
%
% The overlay is drawn over the graph plot at the drawn positions, takes no clicks and
% does not change the appearance of the elements. A branch is marked by the straight line
% between its buses (parallel branches, which the graph plot draws as curves, share it).
    arguments (Input)
        obj
    end
    plt = obj.sct_plt;
    delete(plt.Selection(isgraphics(plt.Selection)));
    h    = plt.Graph;
    rv_x = h.XData(:);
    rv_y = h.YData(:);
    tab  = obj.element_table();
    rv_c = obj.SelectionColor;
    im_end = obj.sct_data.im_end;
    rv_w   = obj.sct_plt.BranchWidth;              % drawn widths (apply_style)
    c_line = {"Color", rv_c, "MarkerEdgeColor", rv_c, "PickableParts", "none", "HitTest", "off", "Tag", "GraphNetMapSelection"};
    hv = gobjects(0, 1);
    for r = find(ismember(tab.Tag, obj.Selection))'
        i = tab.Index(r);
        if tab.Kind(r) == "bus"
            hv(end+1, 1) = line(obj.ax, rv_x(i), rv_y(i), "LineStyle", "none", "Marker", "o", ...
                "MarkerSize", 2.2 * obj.BusMarkerSize(i), "LineWidth", 2, c_line{:}); %#ok<AGROW>
        else
            hv(end+1, 1) = line(obj.ax, rv_x(im_end(i, :)), rv_y(im_end(i, :)), ...
                "LineWidth", rv_w(i) + 5, c_line{:}); %#ok<AGROW>
        end
    end
    obj.sct_plt.Selection = hv;
end
