function rm_color = color_of_values(obj, rv_value)
% Colors of color values on the colormap and the color limits in use (color_limits; NaN: gray).
    arguments (Input)
        obj
        rv_value (:,1) double  % Color values.
    end
    arguments (Output)
        rm_color (:,3) double  % RGB color of each value.
    end
    rm_color = ones(numel(rv_value), 3) * 0.2;
    lv_isval = ~isnan(rv_value);
    rm_color(lv_isval,:) = map_values_to_colors(obj.Colormap, obj.color_limits(), rv_value(lv_isval), sum(lv_isval));
end

function rm_color = map_values_to_colors(rm_color, rr_clim, rv_value, n_target)
    if n_target <= 0
        rm_color = zeros(0, 3);
        return
    end

    if isempty(rv_value)
        rv_value = zeros(n_target, 1);
    else
        rv_value = real(rv_value(:));
    end

    if isscalar(rv_value) && n_target > 1
        rv_value = repmat(rv_value, n_target, 1);
    elseif numel(rv_value) < n_target
        rv_value(end+1:n_target, 1) = rv_value(end);
    elseif numel(rv_value) > n_target
        rv_value = rv_value(1:n_target);
    end

    if isempty(rm_color)
        rm_color = repmat([0 0 0], n_target, 1);
        return
    end

    rr_clim = double(rr_clim(:).');
    if numel(rr_clim) ~= 2 || any(~isfinite(rr_clim))
        error(msg("GUILDA:GraphNetDiagram:InvalidColorLimits"));
    end

    if rr_clim(2) <= rr_clim(1)
        idx = ones(n_target, 1);
    else
        rv_value = min(max(rv_value, rr_clim(1)), rr_clim(2));
        rv_value = (rv_value - rr_clim(1)) ./ (rr_clim(2) - rr_clim(1));
        idx = round(rv_value * (size(rm_color, 1)-1) + 1);
    end

    idx = min(max(idx, 1), size(rm_color, 1));
    rm_color = rm_color(idx, :);
end