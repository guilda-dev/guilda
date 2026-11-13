function create_scene(obj)
% Draw the polar grid and the |E| circles and create the graphics objects.
    arguments (Input)
        obj
    end
    ax = obj.ax;
    d  = obj.sct_data;
    if ~isempty(obj.sct_plt)
        legend(ax, "off");
    end
    cla(ax, "reset");
    hold(ax, "on");
    axis(ax, "equal");
    axis(ax, [-2.2 2.2 -1.65 1.65] * obj.RMax / 1.5);
    axis(ax, "off");

    % Polar grid: circles every 0.5 pu and radii every 30 degrees
    rv_grid = [0.85 0.85 0.85];
    rv_th   = linspace(0, 2*pi, 361);
    for r = 0.5:0.5:obj.RMax
        plot(ax, r*cos(rv_th), r*sin(rv_th), "-", "Color", rv_grid);
        text(ax, 0.02, r + 0.06, sprintf("%.1f", r), "FontSize", 9, "HorizontalAlignment", "center");
    end
    for r_deg = 0:30:330
        plot(ax, [0 obj.RMax*cosd(r_deg)], [0 obj.RMax*sind(r_deg)], "-", "Color", rv_grid);
        text(ax, 0.62*cosd(r_deg), 0.62*sind(r_deg), sprintf("%d°", r_deg), "FontSize", 9, "HorizontalAlignment", "center");
    end
    % Dashed circles of constant |E|
    iv_circle = find(~isnan(d.rv_circle))';
    for i = iv_circle
        plot(ax, d.rv_circle(i)*cos(rv_th), d.rv_circle(i)*sin(rv_th), "--", "Color", d.rm_color(i, :), "LineWidth", 0.8);
    end

    % Arrows: P (tangential) and Iq (radial); shaft line and head patch
    rv_colP = [1.00 0.60 0.60];
    rv_colQ = [0.78 0.62 0.95];
    n_arrow = numel(d.iv_arrow);
    plt.ArrowP = gobjects(n_arrow, 2);
    plt.ArrowQ = gobjects(n_arrow, 2);
    for a = 1:n_arrow
        plt.ArrowP(a, 1) = plot(ax, nan, nan, "-", "Color", rv_colP, "LineWidth", 4);
        plt.ArrowP(a, 2) = patch(ax, nan(1, 3), nan(1, 3), rv_colP, "EdgeColor", rv_colP, "LineWidth", 1);
        plt.ArrowQ(a, 1) = plot(ax, nan, nan, "-", "Color", rv_colQ, "LineWidth", 4);
        plt.ArrowQ(a, 2) = patch(ax, nan(1, 3), nan(1, 3), rv_colQ, "EdgeColor", rv_colQ, "LineWidth", 1);
    end
    n_edge = size(d.im_edge, 2);
    plt.Spring = gobjects(n_edge, 1);
    for e = 1:n_edge
        plt.Spring(e) = plot(ax, nan, nan, "k-", "LineWidth", 0.8, "Tag", d.sv_edge(e));
    end
    n_node = numel(d.sv_node);
    plt.Node = gobjects(n_node, 1);
    for n = 1:n_node
        plt.Node(n) = plot(ax, nan, nan, d.sv_marker(n), "MarkerSize", d.rv_size(n), ...
            "MarkerFaceColor", d.rm_color(n, :), "MarkerEdgeColor", "k", "Tag", d.sv_node(n));
    end
    plt.LabelNode = gobjects(n_node, 1);
    for n = 1:n_node
        plt.LabelNode(n) = text(ax, nan, nan, d.sv_node(n), "FontSize", 11, "FontWeight", "bold", ...
            "Color", 0.7*d.rm_color(n, :), "HorizontalAlignment", "center", "Interpreter", "none");
    end
    plt.LabelP = gobjects(n_arrow, 1);
    plt.LabelQ = gobjects(n_arrow, 1);
    for a = 1:n_arrow
        plt.LabelP(a) = text(ax, nan, nan, "", "FontSize", 8, "FontWeight", "bold", "Color", [0.80 0.20 0.20]);
        plt.LabelQ(a) = text(ax, nan, nan, "", "FontSize", 8, "FontWeight", "bold", "Color", [0.50 0.30 0.80]);
    end

    hv_legend = [plot(ax, nan, nan, "-", "Color", rv_colP, "LineWidth", 4)
                 plot(ax, nan, nan, "-", "Color", rv_colQ, "LineWidth", 4)];
    sv_legend = ["Active power P"; "Reactive current Iq"];
    if ~isempty(iv_circle)
        hv_legend(end+1) = plot(ax, nan, nan, "--", "Color", [0.5 0.5 0.5], "LineWidth", 0.8);
        sv_legend(end+1) = "Constant |E|";
    end
    plt.Legend = legend(ax, hv_legend, sv_legend, "Location", "southwest", "Box", "off", "AutoUpdate", "off");
    obj.sct_plt = plt;
end
