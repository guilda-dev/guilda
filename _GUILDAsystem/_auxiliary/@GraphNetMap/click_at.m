function click_at(obj, rv_point)
% Hit test of a click on the graph plot: report the bus or branch under the point.
%
% A graph plot has one ButtonDownFcn for all its nodes and edges, so the element is found
% from the point of the click (IntersectionPoint) in pixels of the axes: the nearest bus
% whose marker (BusMarkerSize/2 + 4 px) contains it, else the nearest branch whose line,
% the straight segment between its buses (LineWidth/2 + 4 px), contains it. A click on
% neither does nothing.
    arguments (Input)
        obj
        rv_point (1,2) double  % Point of the click (x, y) in data units.
    end
    ax   = obj.ax;
    h    = obj.sct_plt.Graph;
    rv_p = getpixelposition(ax);
    rv_s = rv_p(3:4) ./ [diff(xlim(ax)), diff(ylim(ax))];          % [px] per data unit
    rm_n = [h.XData(:), h.YData(:)] .* rv_s;
    rv_q = rv_point .* rv_s;

    rv_d = vecnorm(rm_n - rv_q, 2, 2);
    rv_d(rv_d > obj.BusMarkerSize / 2 + 4) = Inf;
    [r_min, i_bus] = min(rv_d);
    if isfinite(r_min)
        obj.click_element(i_bus);
        return
    end

    im_end = obj.sct_data.im_end;
    if isempty(im_end)
        return
    end
    rm_a  = rm_n(im_end(:, 1), :);
    rm_ab = rm_n(im_end(:, 2), :) - rm_a;
    rv_t  = min(max(sum((rv_q - rm_a) .* rm_ab, 2) ./ max(sum(rm_ab.^2, 2), eps), 0), 1);
    rv_d  = vecnorm(rm_a + rv_t .* rm_ab - rv_q, 2, 2);
    rv_w  = obj.sct_plt.BranchWidth;              % drawn widths (apply_style)
    rv_d(rv_d > rv_w / 2 + 4) = Inf;
    [r_min, i_br] = min(rv_d);
    if isfinite(r_min)
        obj.click_element(numel(obj.sct_data.sv_bus) + i_br);
    end
end
