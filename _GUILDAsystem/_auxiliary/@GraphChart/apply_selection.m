function apply_selection(obj)
% Draw the selection overlay: a wide line under a selected line, a ring on each marker of a selected marker set, an outline around a selected bar.
%
% The overlay is drawn from the graphics shown, takes no clicks and is not in the legend.
% Hidden elements get no overlay.
    arguments (Input)
        obj
    end
    plt = obj.sct_plt;
    delete(plt.Selection(isgraphics(plt.Selection)));
    tab  = obj.tab_series;
    rv_c = obj.SelectionColor;
    c_off = {"PickableParts", "none", "HitTest", "off", "HandleVisibility", "off", "Tag", "Selection"};
    hv = gobjects(0, 1);
    for i_row = find(ismember(tab.Tag, obj.Selection) & obj.SeriesVisible)'
        h  = plt.Element(i_row);
        ax = obj.ax(tab.Panel(i_row));
        if ~isgraphics(h)
            continue
        end
        switch tab.Kind(i_row)
            case "line"
                hv(end+1, 1) = line(ax, h.XData, h.YData, "Color", rv_c, "LineWidth", h.LineWidth + 4, ...
                    "Marker", h.Marker, "MarkerSize", h.MarkerSize + 4, c_off{:}); %#ok<AGROW>
                uistack(hv(end), "bottom");
            case "marker"
                hv(end+1, 1) = line(ax, h.XData, h.YData, "LineStyle", "none", "Marker", "o", ...
                    "MarkerSize", h.MarkerSize + 8, "MarkerEdgeColor", rv_c, "LineWidth", 2, c_off{:}); %#ok<AGROW>
            case "bar"
                % Width of one bar: the distance between the groups or between the bars of a group
                iv_group = find([obj.sct_data.sct_series.i_panel] == tab.Panel(i_row) & ...
                    [strings(1, 0), obj.sct_data.sct_series.s_type] == "bar");
                hv_group = plt.Bar(iv_group);
                rv_xEnd = h.XEndPoints;
                if numel(hv_group) > 1
                    r_step = abs(hv_group(2).XEndPoints(1) - hv_group(1).XEndPoints(1));
                elseif numel(rv_xEnd) > 1
                    r_step = min(diff(sort(rv_xEnd)));
                else
                    r_step = 1;
                end
                k = tab.Item(i_row);
                r_x = rv_xEnd(k);
                r_w = r_step * h.BarWidth / 2;
                r_b = h.BaseValue;
                r_y = h.YData(k);
                hv(end+1, 1) = line(ax, r_x + r_w*[-1 1 1 -1 -1], [r_b r_b r_y r_y r_b], "Color", rv_c, ...
                    "LineWidth", 2.5, c_off{:}); %#ok<AGROW>
        end
    end
    obj.sct_plt.Selection = hv;
end
