function apply_style(obj, iv_element)
% Set the appearance of the elements iv_element on their graphics objects and update the legends.
%
% A line or marker set changes its line object; a bar changes its row of the CData of its
% bar series, and a hidden bar has a NaN height (it keeps its place). A NaN color is the
% color of the color order of the axes. The marker of a marker cursor takes the color and
% the visibility of its element. The first data tip row of a line or marker set is its
% name: the legend entry (SeriesLabel), or the tag when the entry is "" (TeX characters
% escaped, as the X and Y rows are TeX like the axis labels).
    arguments (Input)
        obj
        iv_element (:,1) double  % Rows of the elements in tab_element.
    end
    tab = obj.tab_series;
    plt = obj.sct_plt;
    for i_row = iv_element'
        h = plt.Element(i_row);
        if ~isgraphics(h)
            continue
        end
        rv_color = obj.SeriesColor(i_row, :);
        if any(isnan(rv_color))
            rv_color = obj.rm_colorAuto(i_row, :);
        end
        if tab.Kind(i_row) ~= "bar"
            s_name = obj.SeriesLabel(i_row);
            if s_name == ""
                s_name = tab.Tag(i_row);
            end
            h.DataTipTemplate.DataTipRows(1).Label = regexprep(s_name, "([\\_^{}])", "\\$1");
        end
        switch tab.Kind(i_row)
            case "bar"
                k = tab.Item(i_row);
                r_y = obj.sct_data.sct_series(tab.Series(i_row)).rm_y(k);
                if ~obj.SeriesVisible(i_row)
                    r_y = NaN;
                end
                h.CData(k, :) = rv_color;
                h.YData(k)    = r_y;
            case "line"
                set(h, "Color", rv_color, "LineStyle", obj.SeriesLineStyle(i_row), ...
                    "LineWidth", obj.SeriesLineWidth(i_row), "Marker", obj.SeriesMarker(i_row), ...
                    "MarkerSize", obj.SeriesMarkerSize(i_row), "DisplayName", obj.SeriesLabel(i_row), ...
                    "Visible", obj.SeriesVisible(i_row));
            case "marker"
                set(h, "Color", rv_color, "LineStyle", "none", "Marker", obj.SeriesMarker(i_row), ...
                    "MarkerSize", obj.SeriesMarkerSize(i_row), "DisplayName", obj.SeriesLabel(i_row), ...
                    "Visible", obj.SeriesVisible(i_row));
        end
        h = plt.CursorMarker(i_row);
        if isgraphics(h)
            set(h, "MarkerFaceColor", rv_color, "Visible", obj.l_cursor && obj.SeriesVisible(i_row));
        end
    end
    obj.refresh_legend(unique(tab.Panel(iv_element)));
end
