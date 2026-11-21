function update_scene(obj, k, cv_node)
% Move the springs, rods, nodes, arrows and labels to sample k.
    arguments (Input)
        obj
        k (1,1) double        % Index of the sample.
        cv_node (:,1) double  % [pu] Node phasors of the sample turned by the rotation reference.
    end
    d   = obj.sct_data;
    plt = obj.sct_plt;
    rv_r  = min(max(abs(cv_node), obj.RMin), obj.RMax);  % every node on the surface (|V| = 0 at its bottom)
    rv_th = angle(cv_node);
    rm_p  = [rv_r.*cos(rv_th), rv_r.*sin(rv_th), log(rv_r)];
    rm_box = [obj.RMax*[-1 1]; obj.RMax*[-1 1]; log([obj.RMin obj.RMax])];   % axes limits (rows x, y, z)

    % 3D coils: straight leads of 30 % at both ends, a helix of SpringAmplitude radius in between
    r_lead = 0.30;
    for e = 1:size(d.im_edge, 2)
        rv_p1 = rm_p(d.im_edge(1, e), :);
        rv_d  = rm_p(d.im_edge(2, e), :) - rv_p1;
        r_len = norm(rv_d);
        if r_len < 1e-9
            set(plt.Spring(e), "XData", rv_p1(1), "YData", rv_p1(2), "ZData", rv_p1(3));
            continue
        end
        rv_u = rv_d / r_len;
        rv_a = [0 0 1];
        if abs(dot(rv_a, rv_u)) > 0.9
            rv_a = [0 1 0];
        end
        rv_v = rv_a - dot(rv_a, rv_u)*rv_u;
        rv_v = rv_v / norm(rv_v);
        rv_w = cross(rv_u, rv_v);
        n_turns = max(2, round(obj.SpringTurns * r_len * (1 - 2*r_lead)));
        rv_s    = linspace(0, 1, 80*n_turns)';
        rv_c    = min(max((rv_s - r_lead) / (1 - 2*r_lead), 0), 1);
        rv_amp  = min(obj.SpringAmplitude, 0.06*r_len) * sin(pi*rv_c).^0.20;   % slightly thinner at the ends
        rv_ang  = 2*pi*n_turns*rv_c;
        rm_c    = rv_p1 + (r_len*rv_s)*rv_u + (rv_amp.*cos(rv_ang))*rv_v + (rv_amp.*sin(rv_ang))*rv_w;
        set(plt.Spring(e), "XData", rm_c(:, 1), "YData", rm_c(:, 2), "ZData", rm_c(:, 3));
    end

    % Rods from the z axis to the component nodes: tube and centre line
    r_rod = 0.005;
    rv_tc = linspace(0, 2*pi, 36)';
    for a = 1:numel(plt.Rod)
        rv_p = rm_p(plt.Rod(a).UserData, :);
        r_len = norm(rv_p(1:2));
        if r_len < 1e-9
            set(plt.Rod(a), "XData", nan(36, 2), "YData", nan(36, 2), "ZData", nan(36, 2));
        else
            rv_u  = [rv_p(1:2) / r_len, 0];
            rv_w  = cross(rv_u, [0 0 1]);
            rm_ring = r_rod * (cos(rv_tc)*[0 0 1] + sin(rv_tc)*rv_w);
            set(plt.Rod(a), "XData", rm_ring(:, 1) + [0 rv_p(1)], "YData", rm_ring(:, 2) + [0 rv_p(2)], ...
                            "ZData", rm_ring(:, 3) + [rv_p(3) rv_p(3)]);
        end
        set(plt.RodLine(a), "XData", [0 rv_p(1)], "YData", [0 rv_p(2)], "ZData", [rv_p(3) rv_p(3)]);
    end

    % Nodes (spheres or cones) and their tags above them
    for n = 1:numel(cv_node)
        r_rad = 0.004 * obj.NodeSize(n);
        if obj.NodeMarker(n) == "v"
            set(plt.Node(n), "XData", r_rad*plt.ConeX + rm_p(n, 1), "YData", r_rad*plt.ConeY + rm_p(n, 2), ...
                             "ZData", r_rad*plt.ConeZ + rm_p(n, 3));
        else
            set(plt.Node(n), "XData", r_rad*plt.SphereX + rm_p(n, 1), "YData", r_rad*plt.SphereY + rm_p(n, 2), ...
                             "ZData", r_rad*plt.SphereZ + rm_p(n, 3));
        end
        set(plt.LabelNode(n), "Position", rm_p(n, :) + [0 0 2.2*r_rad], "Visible", obj.ShowLabel && obj.NodeVisible(n));
    end

    % Arrows: P along the circle of constant |V|, Iq along the surface away from the axis
    for a = 1:numel(d.iv_arrow)
        n     = d.iv_arrow(a);
        rv_p  = rm_p(n, :);
        rv_eT = [-sin(rv_th(n)), cos(rv_th(n)), 0];
        rv_eR = [cos(rv_th(n)), sin(rv_th(n)), 1/rv_r(n)];
        rv_eR = rv_eR / norm(rv_eR);
        r_P   = d.rm_P(a, k);
        r_Iq  = d.rm_Iq(a, k);
        rv_dP = fit_arrow(rv_p, obj.ArrowScaleP * r_P * rv_eT, rm_box);
        rv_dQ = fit_arrow(rv_p, obj.ArrowScaleQ * r_Iq * rv_eR, rm_box);
        GraphBase.set_arrow(plt.ArrowP(a, :), rv_p, rv_dP, 0.04);
        GraphBase.set_arrow(plt.ArrowQ(a, :), rv_p, rv_dQ, 0.04);
        if obj.ShowValue
            GraphBase.place_label(plt.LabelP(a), rv_p, sign(r_P)*rv_eT, norm(rv_dP), sprintf("P = %.2f", r_P), r_P * (obj.ArrowScaleP ~= 0));   % no arrow, no value
            GraphBase.place_label(plt.LabelQ(a), rv_p, sign(r_Iq)*rv_eR, norm(rv_dQ), sprintf("Iq = %.2f", r_Iq), r_Iq * (obj.ArrowScaleQ ~= 0));
        else
            set([plt.LabelP(a), plt.LabelQ(a)], "String", "");
        end
    end
    % Nothing outside the axes: the parts that still stick out (the half of a node below the
    % bottom, a coil or an arrow head at a face) are pressed onto the faces of the box
    for h = [plt.Spring; plt.Rod; plt.RodLine; plt.Node; plt.ArrowP(:); plt.ArrowQ(:)]'
        set(h, "XData", clamp(h.XData, rm_box(1, :)'), "YData", clamp(h.YData, rm_box(2, :)'), ...
               "ZData", clamp(h.ZData, rm_box(3, :)'));
    end
    for h = [plt.LabelNode; plt.LabelP; plt.LabelQ]'
        h.Position = clamp(h.Position, rm_box');
    end
    plt.Legend.Visible = obj.ShowLegend;
end


function rv_d = fit_arrow(rv_p, rv_d, rm_box)
% Shorten an arrow so that its tip stays a head width inside the axes limits.
%
% The direction is kept; an arrow that fits is unchanged. NaN (no value) stays NaN.
    arguments (Input)
        rv_p (1,3) double    % Start point (a node inside the limits).
        rv_d (1,3) double    % Arrow vector.
        rm_box (3,2) double  % Axes limits, rows x, y, z.
    end
    arguments (Output)
        rv_d (1,3) double  % Arrow vector, shortened when its tip is outside.
    end
    r_inset = 0.025;                                       % half width of the head (0.6 x 0.04) and a little
    rv_lo = min(rm_box(:, 1)' + r_inset, rv_p);
    rv_hi = max(rm_box(:, 2)' - r_inset, rv_p);
    r_s = 1;
    for j = 1:3
        if rv_p(j) + rv_d(j) > rv_hi(j)
            r_s = min(r_s, (rv_hi(j) - rv_p(j)) / rv_d(j));
        elseif rv_p(j) + rv_d(j) < rv_lo(j)
            r_s = min(r_s, (rv_lo(j) - rv_p(j)) / rv_d(j));
        end
    end
    rv_d = r_s * rv_d;
end


function rm = clamp(rm, rm_lim)
% Limit each value to [low, high] of its column of rm_lim; NaN stays NaN.
    arguments (Input)
        rm double            % Coordinates.
        rm_lim (2,:) double  % Limits [low; high]: one column for all values, or a column per column of rm.
    end
    arguments (Output)
        rm double  % Coordinates inside the limits.
    end
    rm = min(max(rm, rm_lim(1, :), "includenan"), rm_lim(2, :), "includenan");
end
