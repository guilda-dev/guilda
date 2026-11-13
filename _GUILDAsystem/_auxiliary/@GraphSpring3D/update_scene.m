function update_scene(obj, k, cv_node)
% Move the springs, rods, nodes, arrows and labels to sample k.
    arguments (Input)
        obj
        k (1,1) double          % Index of the sample.
        cv_node (:,1) double    % [pu] Node phasors of the sample turned by the rotation reference.
    end
    d   = obj.sct_data;
    plt = obj.sct_plt;
    rv_r  = max(abs(cv_node), obj.RMin);            % no node below the bottom of the surface
    rv_th = angle(cv_node);
    rm_p  = [rv_r.*cos(rv_th), rv_r.*sin(rv_th), log(rv_r)];

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
        r_rad = 0.004 * d.rv_size(n);
        if d.sv_marker(n) == "v"
            set(plt.Node(n), "XData", r_rad*plt.ConeX + rm_p(n, 1), "YData", r_rad*plt.ConeY + rm_p(n, 2), ...
                             "ZData", r_rad*plt.ConeZ + rm_p(n, 3));
        else
            set(plt.Node(n), "XData", r_rad*plt.SphereX + rm_p(n, 1), "YData", r_rad*plt.SphereY + rm_p(n, 2), ...
                             "ZData", r_rad*plt.SphereZ + rm_p(n, 3));
        end
        set(plt.LabelNode(n), "Position", rm_p(n, :) + [0 0 2.2*r_rad], "Visible", obj.ShowLabel);
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
        rv_dP = obj.ArrowScaleP * r_P * rv_eT;
        rv_dQ = obj.ArrowScaleQ * r_Iq * rv_eR;
        GraphSpringBase.set_arrow(plt.ArrowP(a, :), rv_p, rv_dP, 0.04);
        GraphSpringBase.set_arrow(plt.ArrowQ(a, :), rv_p, rv_dQ, 0.04);
        if obj.ShowValue
            GraphSpringBase.place_label(plt.LabelP(a), rv_p, sign(r_P)*rv_eT, norm(rv_dP), sprintf("P = %.2f", r_P), r_P);
            GraphSpringBase.place_label(plt.LabelQ(a), rv_p, sign(r_Iq)*rv_eR, norm(rv_dQ), sprintf("Iq = %.2f", r_Iq), r_Iq);
        else
            set([plt.LabelP(a), plt.LabelQ(a)], "String", "");
        end
    end
    plt.Legend.Visible = obj.ShowLegend;
end
