function refresh_legend(obj, iv_panel)
% Draw the legend of each panel iv_panel again from the shown elements.
%
% The entries are the bar series with a legend entry and the shown lines and marker sets
% with a nonempty SeriesLabel, in the element order. A panel without entries, or with
% s_legendLocation "none", has no legend. The legend does not take objects drawn later
% (AutoUpdate off), such as the selection overlay.
    arguments (Input)
        obj
        iv_panel (:,1) double  % Panels whose legends are drawn again.
    end
    tab = obj.tab_series;
    d   = obj.sct_data;
    for i_panel = iv_panel'
        ax = obj.ax(i_panel);
        s_location = d.sct_panel(i_panel).s_legendLocation;
        iv_bar = find([d.sct_series.i_panel] == i_panel & [strings(1, 0), d.sct_series.s_type] == "bar");
        iv_bar = iv_bar(arrayfun(@(i) d.sct_series(i).sv_legend(1) ~= "" && isgraphics(obj.sct_plt.Bar(i)), iv_bar));
        iv_row = find(tab.Panel == i_panel & tab.Kind ~= "bar" & obj.SeriesVisible & obj.SeriesLabel ~= "");
        hv = [obj.sct_plt.Bar(iv_bar); obj.sct_plt.Element(iv_row)];
        sv = [arrayfun(@(i) d.sct_series(i).sv_legend(1), iv_bar(:)); obj.SeriesLabel(iv_row)];
        if isempty(hv) || s_location == "none"
            legend(ax, "off");
        else
            legend(ax, hv, sv, "Location", s_location, "Interpreter", "none", "AutoUpdate", "off");
        end
    end
end
