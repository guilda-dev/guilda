function update_scene(obj, k)
% Draw sample k: the series shown by sample, the titles per sample and the time cursor.
%
% A series with iv_sample shows its rows of sample k; a panel with one title per sample
% shows title k. The other lines show every time and do not change. A line cursor moves
% to x = rv_t(k); a marker cursor (s_cursor "marker") moves the marker of each line and
% marker set to its row k, (rv_x(k), rm_y(k, column)). The cursor appears at the first
% set_time: the drawing of build (and of set_data before any set_time) leaves it hidden.
% A chart without any of these has nothing to update.
    arguments (Input)
        obj
        k (1,1) double  % Index of the sample.
    end
    d   = obj.sct_data;
    tab = obj.tab_series;
    for i_series = find(arrayfun(@(s) ~isempty(s.iv_sample), d.sct_series))
        s = d.sct_series(i_series);
        lv_row = s.iv_sample == k;
        iv_row = find(tab.Series == i_series);
        for i_col = 1:numel(iv_row)
            set(obj.sct_plt.Element(iv_row(i_col)), "XData", s.rv_x(lv_row), "YData", s.rm_y(lv_row, i_col));
        end
    end
    for i_panel = find(arrayfun(@(p) numel(p.s_title) > 1, d.sct_panel))
        title(obj.ax(i_panel), d.sct_panel(i_panel).s_title(k));
    end

    hv = obj.sct_plt.Cursor;
    iv_marker = find(isgraphics(obj.sct_plt.CursorMarker));
    if isempty(hv) && isempty(iv_marker)
        return
    end
    if obj.l_firstDraw
        obj.l_firstDraw = false;
    else
        obj.l_cursor = true;
    end
    set(hv, "Value", obj.rv_t(k), "Visible", obj.l_cursor);
    for i_row = iv_marker'
        s = d.sct_series(tab.Series(i_row));
        set(obj.sct_plt.CursorMarker(i_row), "XData", s.rv_x(k), "YData", s.rm_y(k, tab.Item(i_row)), ...
            "Visible", obj.l_cursor && obj.SeriesVisible(i_row));
    end
end
