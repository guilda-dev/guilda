function update_scene(obj, k)
% Draw sample k: turn the node phasors by the rotation reference and move the graphics objects.
%
% The title shows the time of the sample when the data has more than one sample (for
% samples named by the data, its text: see GraphBase.sample_text).
    arguments (Input)
        obj
        k (1,1) double  % Index of the sample.
    end
    rv_mean = obj.rv_angleMean;
    r_ref   = rv_mean(1) + (1 - obj.RotationScale) * (rv_mean(k) - rv_mean(1));
    obj.draw_sample(k, obj.sct_data.cm_V(:, k) * exp(-1j * r_ref));
    if numel(obj.rv_t) > 1
        title(obj.ax, obj.sample_text(k, "t = %.2f s"), "FontSize", 16, "FontWeight", "bold");
    end
end
