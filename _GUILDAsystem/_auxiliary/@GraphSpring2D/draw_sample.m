function update_scene(obj, k, cv_node)
% Move the springs, nodes, arrows and labels to sample k.
    arguments (Input)
        obj
        k (1,1) double        % Index of the sample.
        cv_node (:,1) double  % [pu] Node phasors of the sample turned by the rotation reference.
    end
    d   = obj.sct_data;
    plt = obj.sct_plt;
    rv_x  = real(cv_node);
    rv_y  = imag(cv_node);
    rv_th = angle(cv_node);

    % Coil springs: straight leads of 20 % at both ends, loops in between
    n_turns = obj.SpringTurns;
    rv_u    = linspace(0, 1, max(2, round(40*n_turns)))';
    rv_w    = 2*pi*n_turns*rv_u;
    for e = 1:size(d.im_edge, 2)
        rv_p1 = [rv_x(d.im_edge(1, e)), rv_y(d.im_edge(1, e))];
        rv_p2 = [rv_x(d.im_edge(2, e)), rv_y(d.im_edge(2, e))];
        r_len = norm(rv_p2 - rv_p1);
        if r_len < 1e-9
            set(plt.Spring(e), "XData", rv_p1(1), "YData", rv_p1(2));
            continue
        end
        rv_e   = (rv_p2 - rv_p1) / r_len;
        rv_n   = [-rv_e(2), rv_e(1)];
        r_amp  = min(obj.SpringAmplitude, 0.06*r_len);                            % fixed coil radius, smaller on short springs
        rv_s   = [0; 0.2*r_len + rv_u*0.6*r_len - 0.8*r_amp*sin(rv_w); r_len];   % along the spring (loops go back)
        rv_off = [0; r_amp*(1 - cos(rv_w)); 0];                                   % across the spring
        set(plt.Spring(e), "XData", rv_p1(1) + rv_s*rv_e(1) + rv_off*rv_n(1), ...
                           "YData", rv_p1(2) + rv_s*rv_e(2) + rv_off*rv_n(2));
    end

    % Nodes; component tags inside (towards the origin), bus tags outside
    for n = 1:numel(cv_node)
        set(plt.Node(n), "XData", rv_x(n), "YData", rv_y(n));
        r_off = 0.10 - 0.23*(d.sv_kind(n) == "component");
        set(plt.LabelNode(n), "Position", [rv_x(n) + r_off*cos(rv_th(n)), rv_y(n) + r_off*sin(rv_th(n)), 0], ...
            "Visible", obj.ShowLabel && obj.NodeVisible(n));
    end

    % |E| circles: shown with their node, hidden while it is disconnected (NaN phasor)
    for n = find(isgraphics(plt.Circle))'
        l_vis = obj.NodeVisible(n) && ~isnan(cv_node(n));
        if strcmp(plt.Circle(n).Visible, "on") ~= l_vis
            plt.Circle(n).Visible = l_vis;
        end
    end

    % Arrows: P along the tangent, Iq along the radius
    for a = 1:numel(d.iv_arrow)
        n      = d.iv_arrow(a);
        rv_p   = [rv_x(n), rv_y(n)];
        rv_e   = [cos(rv_th(n)), sin(rv_th(n))];
        rv_t   = [-rv_e(2), rv_e(1)];
        r_P    = d.rm_P(a, k);
        r_Iq   = d.rm_Iq(a, k);
        rv_dP  = obj.ArrowScaleP * r_P * rv_t;
        rv_dQ  = obj.ArrowScaleQ * r_Iq * rv_e;
        GraphBase.set_arrow(plt.ArrowP(a, :), rv_p, rv_dP, 0.04);
        GraphBase.set_arrow(plt.ArrowQ(a, :), rv_p, rv_dQ, 0.04);
        if obj.ShowValue
            GraphBase.place_label(plt.LabelP(a), rv_p, sign(r_P)*rv_t, norm(rv_dP), sprintf("P = %.2f", r_P), r_P * (obj.ArrowScaleP ~= 0));   % no arrow, no value
            GraphBase.place_label(plt.LabelQ(a), rv_p, sign(r_Iq)*rv_e, norm(rv_dQ), sprintf("Iq = %.2f", r_Iq), r_Iq * (obj.ArrowScaleQ ~= 0));
        else
            set([plt.LabelP(a), plt.LabelQ(a)], "String", "");
        end
    end
    if obj.ShowValue
        GraphBase.resolve_overlap([plt.LabelP; plt.LabelQ], plt.LabelNode, 40, 0.03);
    end
    plt.Legend.Visible = obj.ShowLegend;
    % Choose the tick labels again for the new positions (fit_ticks of create_scene)
    if isappdata(obj.ax, "GraphSpring2D_TickKey")
        rmappdata(obj.ax, "GraphSpring2D_TickKey");
    end
end
