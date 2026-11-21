function set_arrow(hv_arrow, rv_start, rv_vector, r_head)
% Move an arrow (a line and a triangular head) from a start point along a vector.
%
% Works in 2D and 3D (the size of rv_start). An arrow shorter than 1e-6 (or NaN) is hidden.
% The head is r_head long, or 0.6 of the arrow for a short one.
    arguments (Input)
        hv_arrow (1,2)          % Line of the shaft and patch of the head.
        rv_start (1,:) double   % Start point (x, y) or (x, y, z).
        rv_vector (1,:) double  % Arrow vector, the same size as rv_start.
        r_head (1,1) double     % Length of the head.
    end
    r_len = norm(rv_vector);
    l_3d  = numel(rv_start) == 3;
    if ~(r_len >= 1e-6)
        rv_start  = nan(size(rv_start));
        rv_vector = zeros(size(rv_start));
    end
    rv_u = rv_vector / max(r_len, 1e-6);
    if l_3d
        rv_w = cross(rv_u, [0 0 1]);
        if norm(rv_w) < 1e-6
            rv_w = cross(rv_u, [1 0 0]);
        end
        rv_w = rv_w / norm(rv_w);
    else
        rv_w = [-rv_u(2), rv_u(1)];
    end
    r_hl    = min(r_head, 0.6 * r_len);
    rv_tip  = rv_start + rv_vector;
    rv_base = rv_tip - r_hl * rv_u;
    rm_tri  = [rv_tip; rv_base + 0.6 * r_hl * rv_w; rv_base - 0.6 * r_hl * rv_w];
    rm_line = [rv_start; rv_base];
    c_xyz   = {"XData", "YData", "ZData"};
    for i = 1:numel(rv_start)
        set(hv_arrow(1), c_xyz{i}, rm_line(:, i)');
        set(hv_arrow(2), c_xyz{i}, rm_tri(:, i));
    end
end
