function l = has_playback(obj)
% Whether the chart changes with the time: it then gets the playback bar.
%
% A chart of two or more samples changes with the time when it has a time panel (a
% cursor), a series shown by sample (iv_sample) or a panel with a title per sample.
    arguments (Input)
        obj
    end
    arguments (Output)
        l (1,1) logical  % The chart has samples to play.
    end
    d = obj.sct_data;
    l = numel(obj.rv_t) >= 2 && (any([d.sct_panel.l_time]) ...
        || any(arrayfun(@(s) ~isempty(s.iv_sample), d.sct_series)) ...
        || any(arrayfun(@(p) numel(p.s_title) > 1, d.sct_panel)));
end
