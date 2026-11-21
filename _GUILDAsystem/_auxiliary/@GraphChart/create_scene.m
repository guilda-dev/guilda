function create_scene(obj)
% Draw every panel: the bars, the lines and marker sets, the reference lines and the time cursor (a line or markers).
%
% Each panel is cleared and drawn again from the data; the appearance of the elements
% comes from the vector properties (apply_style). The default color of an element (NaN
% rows of SeriesColor) follows the color order of its axes: by line or marker set within
% the panel, and by bar series for the bars. A series with iv_sample and a panel with a
% title per sample show the rows and the title of the sample i_time.
    arguments (Input)
        obj
    end
    d      = obj.sct_data;
    tab    = obj.tab_series;
    n_elem = height(tab);
    plt = struct("Element", gobjects(n_elem, 1), "Bar", gobjects(numel(d.sct_series), 1), ...
        "Cursor", gobjects(0, 1), "CursorMarker", gobjects(n_elem, 1), "RefLine", gobjects(0, 1), "Selection", gobjects(0, 1));
    obj.rm_colorAuto = zeros(n_elem, 3);
    wr = matlab.lang.WeakReference(obj);
    k_shown = min(obj.i_time, numel(d.rv_t));      % the rows of iv_sample and the title of the sample shown
    iv_seriesPanel = [d.sct_series.i_panel];
    sv_seriesType  = [strings(1, 0), d.sct_series.s_type];
    for i_panel = 1:numel(obj.ax)
        ax = obj.ax(i_panel);
        p  = d.sct_panel(i_panel);
        cla(ax);
        legend(ax, "off");
        set(ax, "XScale", p.s_xscale, "YScale", p.s_yscale, "XLimMode", "auto", "YLimMode", "auto", ...
            "XTickMode", "auto", "XTickLabelMode", "auto");
        hold(ax, "on");
        rm_order = ax.ColorOrder;
        n_order  = height(rm_order);

        % Bar series of the panel: one grouped bar chart
        iv_bar = find(iv_seriesPanel == i_panel & sv_seriesType == "bar");
        if ~isempty(iv_bar) && ~isempty(d.sct_series(iv_bar(1)).rv_x)
            hv_bar = bar(ax, d.sct_series(iv_bar(1)).rv_x, [d.sct_series(iv_bar).rm_y], "grouped", "FaceColor", "flat");
            for j = 1:numel(iv_bar)
                iv_row = find(tab.Series == iv_bar(j));
                h = hv_bar(j);
                set(h, "DisplayName", d.sct_series(iv_bar(j)).sv_legend(1), "ButtonDownFcn", ...
                    @(h, e) click_weak(wr, iv_row(find(abs(h.XEndPoints - e.IntersectionPoint(1)) == ...
                    min(abs(h.XEndPoints - e.IntersectionPoint(1))), 1))));
                plt.Bar(iv_bar(j)) = h;
                plt.Element(iv_row) = h;
                obj.rm_colorAuto(iv_row, :) = repmat(rm_order(mod(j - 1, n_order) + 1, :), numel(iv_row), 1);
            end
        end

        % Lines and marker sets, in the element order
        j_color = 0;
        for i_series = find(iv_seriesPanel == i_panel & sv_seriesType ~= "bar")
            s = d.sct_series(i_series);
            iv_row = find(tab.Series == i_series);
            for i_col = 1:numel(iv_row)
                i_row = iv_row(i_col);
                j_color = j_color + 1;
                lv_row = true(numel(s.rv_x), 1);
                if ~isempty(s.iv_sample)
                    lv_row = s.iv_sample == k_shown;
                end
                plt.Element(i_row) = line(ax, "XData", s.rv_x(lv_row), "YData", s.rm_y(lv_row, i_col), ...   % one object, also without data
                    "ButtonDownFcn", @(~, ~) click_weak(wr, i_row));
                obj.rm_colorAuto(i_row, :) = rm_order(mod(j_color - 1, n_order) + 1, :);
            end
        end

        % Reference lines and the time cursor (not in the legend, no clicks)
        for r = d.sct_refline([d.sct_refline.i_panel] == i_panel)
            if r.s_axis == "x"
                h = xline(ax, r.r_value, r.s_lineStyle, r.s_label);
            else
                h = yline(ax, r.r_value, r.s_lineStyle, r.s_label);
            end
            set(h, "Color", r.rv_color, "HandleVisibility", "off", "PickableParts", "none", "Tag", "RefLine");
            plt.RefLine(end+1, 1) = h;
        end
        if p.l_time && p.s_cursor == "marker"
            % One marker per line and marker set at its row of the sample (colored by apply_style)
            for i_row = find(tab.Panel == i_panel & tab.Kind ~= "bar")'
                s = d.sct_series(tab.Series(i_row));
                plt.CursorMarker(i_row) = line(ax, s.rv_x(1), s.rm_y(1, tab.Item(i_row)), "LineStyle", "none", ...
                    "Marker", "o", "MarkerSize", 8, "LineWidth", 1.5, "MarkerEdgeColor", [0.15 0.15 0.15], ...
                    "HandleVisibility", "off", "PickableParts", "none", "Visible", obj.l_cursor, "Tag", "TimeCursor");
            end
        elseif p.l_time
            plt.Cursor(end+1, 1) = xline(ax, d.rv_t(1), "-", "Color", [0.25 0.25 0.25], "LineWidth", 1, ...
                "HandleVisibility", "off", "PickableParts", "none", "Visible", obj.l_cursor, "Tag", "TimeCursor");
        end

        % Labels, ticks, limits and grid
        xlabel(ax, p.s_xlabel);
        ylabel(ax, p.s_ylabel);
        title(ax, p.s_title(min(k_shown, end)));
        if ~isempty(p.sv_x)
            set(ax, "XTick", 1:numel(p.sv_x), "XTickLabel", p.sv_x, "TickLabelInterpreter", "none");
            xlim(ax, [0.5, numel(p.sv_x) + 0.5]);
        end
        if ~isempty(p.rv_xlim)
            xlim(ax, p.rv_xlim);
        end
        if ~isempty(p.rv_ylim)
            ylim(ax, p.rv_ylim);
        end
        sv_onOff = ["off", "on"];
        grid(ax, sv_onOff(1 + p.l_grid));
        hold(ax, "off");
    end

    % Title of the chart: on the tiled layout, or on a single axes without a panel title
    h_layout = obj.ax(1).Parent;
    if isa(h_layout, "matlab.graphics.layout.TiledChartLayout")
        title(h_layout, d.s_title);
    elseif d.s_title ~= "" && all(d.sct_panel(1).s_title == "")
        title(obj.ax(1), d.s_title);
    end

    obj.sct_plt = plt;
    obj.l_firstDraw = ~obj.l_cursor;
    obj.apply_style((1:n_elem)');
end


function click_weak(wr, i_row)
% Click on the element i_row of the chart held by the weak reference wr (nothing once deleted).
    arguments (Input)
        wr                  % Weak reference to the chart. <@Type> matlab.lang.WeakReference
        i_row (1,1) double  % Row of the element in tab_element.
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        G.click_element(i_row);
    end
end
