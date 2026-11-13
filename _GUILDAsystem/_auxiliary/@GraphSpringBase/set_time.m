function set_time(obj, t)
% Draw the sample nearest to time t.
%
% The title shows the time of the sample when the data has more than one sample.
    arguments (Input)
        obj
        t (1,1) double % [s] Time to show.
    end
    rv_t = obj.sct_data.rv_t;
    [~, k] = min(abs(rv_t - t));
    obj.i_time = k;
    rv_mean = obj.rv_angleMean;
    r_ref   = rv_mean(1) + (1 - obj.RotationScale) * (rv_mean(k) - rv_mean(1));
    obj.update_scene(k, obj.sct_data.cm_V(:, k) * exp(-1j * r_ref));
    if numel(rv_t) > 1
        title(obj.ax, sprintf("t = %.2f s", rv_t(k)), "FontSize", 16, "FontWeight", "bold");
    end
end
