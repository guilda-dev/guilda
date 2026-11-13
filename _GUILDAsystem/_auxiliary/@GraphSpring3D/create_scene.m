function create_scene(obj)
% Draw the surface, floor grid, pillar, |E| circles and lights, fix the camera and create the graphics objects.
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
    r_zmin = log(obj.RMin);
    r_zmax = log(obj.RMax);
    rv_gray = [0.7 0.7 0.7];

    % Surface z = log r with contour circles of constant |V| and meridians every 30 degrees
    [R, TH] = meshgrid(linspace(obj.RMin, obj.RMax, 200), linspace(0, 2*pi, 200));
    surf(ax, R.*cos(TH), R.*sin(TH), log(R), "EdgeColor", "none", "FaceAlpha", obj.SurfaceAlpha, ...
        "FaceLighting", "gouraud", "BackFaceLighting", "lit", "AmbientStrength", 0.38, ...
        "DiffuseStrength", 0.70, "SpecularStrength", 0.75, "SpecularExponent", 14, ...
        "SpecularColorReflectance", 0.4);
    rv_th = linspace(0, 2*pi, 400)';
    for r_z = linspace(r_zmin, r_zmax, obj.ContourCount)
        plot3(ax, exp(r_z)*cos(rv_th), exp(r_z)*sin(rv_th), r_z*ones(size(rv_th)), "-", "LineWidth", 0.5, "Color", rv_gray);
    end
    rv_r = linspace(obj.RMin, obj.RMax, 120)';
    for r_deg = 0:30:330
        plot3(ax, rv_r*cosd(r_deg), rv_r*sind(r_deg), log(rv_r), "-", "LineWidth", 0.5, "Color", rv_gray);
    end
    % Polar grid on the floor (z of the bottom)
    rv_floor = [0.75 0.75 0.75];
    for r = 0.25:0.25:obj.RMax
        plot3(ax, r*cos(rv_th), r*sin(rv_th), r_zmin*ones(size(rv_th)), "-", "Color", rv_floor, "LineWidth", 0.5);
    end
    for r_deg = 0:30:330
        plot3(ax, [0 obj.RMax*cosd(r_deg)], [0 obj.RMax*sind(r_deg)], [r_zmin r_zmin], "-", "Color", rv_floor, "LineWidth", 0.5);
    end
    % Pillar on the z axis with black rims
    r_pillar = 0.02;
    [TH, Z]  = meshgrid(linspace(0, 2*pi, 72), [r_zmin r_zmax]);
    surf(ax, r_pillar*cos(TH), r_pillar*sin(TH), Z, "FaceColor", [0.6 0.6 0.6], "EdgeColor", "none", ...
        "FaceAlpha", 0.85, "FaceLighting", "gouraud", "AmbientStrength", 0.45, "SpecularStrength", 0.4);
    for r_z = [r_zmin r_zmax]
        plot3(ax, r_pillar*cos(TH(1, :)), r_pillar*sin(TH(1, :)), r_z*ones(1, 72), "k-", "LineWidth", 0.8);
    end

    box(ax, "off");
    grid(ax, "off");
    daspect(ax, [1 1 1]);
    xlim(ax, obj.RMax*[-1 1]);
    ylim(ax, obj.RMax*[-1 1]);
    zlim(ax, [r_zmin r_zmax]);
    % Fixed camera: the largest view angle over all azimuths keeps the size for any azimuth
    set(ax, "CameraTargetMode", "manual", "CameraTarget", [0 0 (r_zmin + r_zmax)/2]);
    r_va = 0;
    for r_az = 0:30:330
        view(ax, [r_az obj.View(2)]);
        set(ax, "CameraViewAngleMode", "auto");
        drawnow;
        r_va = max(r_va, camva(ax));
    end
    view(ax, obj.View);
    camva(ax, 1.02*r_va);
    xlabel(ax, "Vcos(θ)", "Interpreter", "none", "FontSize", 12);
    ylabel(ax, "Vsin(θ)", "Interpreter", "none", "FontSize", 12);
    zlabel(ax, "z = log|V|", "Interpreter", "none", "FontSize", 12);
    colormap(ax, parula);
    light("Parent", ax, "Position", [1 1 5], "Style", "infinite");
    light("Parent", ax, "Position", [-1.2 -0.6 1.5], "Style", "infinite", "Color", [0.30 0.30 0.35]);
    lighting(ax, "gouraud");

    % Dashed circles of constant |E| on the surface
    iv_circle = find(~isnan(d.rv_circle))';
    rv_tc = linspace(0, 2*pi, 361);
    for i = iv_circle
        r_c = max(d.rv_circle(i), obj.RMin);
        plot3(ax, r_c*cos(rv_tc), r_c*sin(rv_tc), log(r_c)*ones(size(rv_tc)), "--", "Color", d.rm_color(i, :), "LineWidth", 1.0);
    end

    % Springs, rods (axis to component nodes), nodes, arrows and labels
    n_edge = size(d.im_edge, 2);
    plt.Spring = gobjects(n_edge, 1);
    for e = 1:n_edge
        plt.Spring(e) = plot3(ax, nan, nan, nan, "k-", "LineWidth", 1.0, "Tag", d.sv_edge(e));
    end
    iv_rod = find(d.sv_kind == "component")';
    plt.Rod     = gobjects(numel(iv_rod), 1);
    plt.RodLine = gobjects(numel(iv_rod), 1);
    for a = 1:numel(iv_rod)
        plt.Rod(a) = surf(ax, nan(36, 2), nan(36, 2), nan(36, 2), "FaceColor", [0.40 0.40 0.40], ...
            "EdgeColor", "none", "FaceAlpha", 0.95, "FaceLighting", "gouraud", "AmbientStrength", 0.40, ...
            "DiffuseStrength", 0.80, "SpecularStrength", 0.45, "UserData", iv_rod(a));
        plt.RodLine(a) = plot3(ax, nan, nan, nan, "k-", "LineWidth", 1.6);
    end
    [plt.SphereX, plt.SphereY, plt.SphereZ] = sphere(40);
    rv_tn = linspace(0, 2*pi, 41);
    plt.ConeX = [0*rv_tn; cos(rv_tn); 0*rv_tn];                           % apex down, base up (marker "v")
    plt.ConeY = [0*rv_tn; sin(rv_tn); 0*rv_tn];
    plt.ConeZ = [-ones(size(rv_tn)); ones(size(rv_tn)); ones(size(rv_tn))];
    n_node = numel(d.sv_node);
    plt.Node = gobjects(n_node, 1);
    for n = 1:n_node
        if d.sv_marker(n) == "v"
            M0 = nan(size(plt.ConeX));
        else
            M0 = nan(size(plt.SphereX));
        end
        plt.Node(n) = surf(ax, M0, M0, M0, "FaceColor", d.rm_color(n, :), "EdgeColor", "none", ...
            "FaceAlpha", 0.65, "FaceLighting", "gouraud", "BackFaceLighting", "lit", ...
            "AmbientStrength", 0.35, "DiffuseStrength", 0.85, "SpecularStrength", 0.90, ...
            "SpecularExponent", 35, "Tag", d.sv_node(n));
    end
    rv_colP = [1.00 0.60 0.60];
    rv_colQ = [0.78 0.62 0.95];
    n_arrow = numel(d.iv_arrow);
    plt.ArrowP = gobjects(n_arrow, 2);
    plt.ArrowQ = gobjects(n_arrow, 2);
    for a = 1:n_arrow
        plt.ArrowP(a, 1) = plot3(ax, nan, nan, nan, "-", "Color", rv_colP, "LineWidth", 4);
        plt.ArrowP(a, 2) = patch(ax, nan(1, 3), nan(1, 3), nan(1, 3), rv_colP, "EdgeColor", rv_colP, "FaceLighting", "none");
        plt.ArrowQ(a, 1) = plot3(ax, nan, nan, nan, "-", "Color", rv_colQ, "LineWidth", 4);
        plt.ArrowQ(a, 2) = patch(ax, nan(1, 3), nan(1, 3), nan(1, 3), rv_colQ, "EdgeColor", rv_colQ, "FaceLighting", "none");
    end
    plt.LabelNode = gobjects(n_node, 1);
    for n = 1:n_node
        plt.LabelNode(n) = text(ax, nan, nan, nan, d.sv_node(n), "FontSize", 11, "FontWeight", "bold", ...
            "Color", 0.7*d.rm_color(n, :), "HorizontalAlignment", "center", "Interpreter", "none");
    end
    plt.LabelP = gobjects(n_arrow, 1);
    plt.LabelQ = gobjects(n_arrow, 1);
    for a = 1:n_arrow
        plt.LabelP(a) = text(ax, nan, nan, nan, "", "FontSize", 9, "FontWeight", "bold", "Color", [0.80 0.20 0.20], "Interpreter", "none");
        plt.LabelQ(a) = text(ax, nan, nan, nan, "", "FontSize", 9, "FontWeight", "bold", "Color", [0.50 0.30 0.80], "Interpreter", "none");
    end

    hv_legend = [plot3(ax, nan, nan, nan, "-", "Color", rv_colP, "LineWidth", 4)
                 plot3(ax, nan, nan, nan, "-", "Color", rv_colQ, "LineWidth", 4)];
    sv_legend = ["Active power P"; "Reactive current Iq"];
    if ~isempty(iv_circle)
        hv_legend(end+1) = plot3(ax, nan, nan, nan, "--", "Color", [0.5 0.5 0.5], "LineWidth", 1.0);
        sv_legend(end+1) = "Constant |E|";
    end
    plt.Legend = legend(ax, hv_legend, sv_legend, "Location", "east", "Box", "off", "AutoUpdate", "off", "Interpreter", "none");
    obj.sct_plt = plt;
end
