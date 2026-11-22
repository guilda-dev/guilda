function l = has_playback(obj)
% Whether the drawing of the chart changes with the time: it then gets the playback bar.
%
% A chart of two or more samples gets the bar only when a sample changes what it draws:
% a series shown by sample (iv_sample, e.g. ResultLIN.plot_eigenvalue) or a panel with a
% title per sample. A chart whose time only moves a cursor (a time panel: a line or
% markers, e.g. ResultODE.plot_trajectory) has no bar; set_time, animate, export_video,
% the links and the bar of a linked graph still move its cursor.
    arguments (Input)
        obj
    end
    arguments (Output)
        l (1,1) logical  % The chart has samples to play.
    end
    d = obj.sct_data;
    l = numel(obj.rv_t) >= 2 && (any(arrayfun(@(s) ~isempty(s.iv_sample), d.sct_series)) ...
        || any(arrayfun(@(p) numel(p.s_title) > 1, d.sct_panel)));
end
