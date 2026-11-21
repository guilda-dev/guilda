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

    % Polar grid: circles every 0.5 pu and radii every 30 degrees. The radius labels lie on the
    % 165 degree ray, between the angle labels and on the side where the nodes seldom are.
    % Layers: grid at z = -2, tick labels at z = -1, data at z = 0, so that a tick label never
    % covers a node or a spring and no grid line cuts through a label
    rv_grid = [0.85 0.85 0.85];
    rv_th   = linspace(0, 2*pi, 361);
    rv_radius = 0.5:0.5:obj.RMax;
    plt.TickRadius = gobjects(numel(rv_radius), 1);
    for i = 1:numel(rv_radius)
        r = rv_radius(i);
        plot3(ax, r*cos(rv_th), r*sin(rv_th), -2*ones(size(rv_th)), "-", "Color", rv_grid);
        plt.TickRadius(i) = text(ax, (r + 0.06)*cosd(165), (r + 0.06)*sind(165), -1, sprintf("%.1f", r), ...
            "FontSize", 9, "HorizontalAlignment", "center", "UserData", true);
    end
    rv_deg = 0:30:330;
    plt.TickAngle = gobjects(numel(rv_deg), 1);
    for i = 1:numel(rv_deg)
        r_deg = rv_deg(i);
        plot3(ax, [0 obj.RMax*cosd(r_deg)], [0 obj.RMax*sind(r_deg)], [-2 -2], "-", "Color", rv_grid);
        plt.TickAngle(i) = text(ax, 0.62*cosd(r_deg), 0.62*sind(r_deg), -1, sprintf("%d°", r_deg), ...
            "FontSize", 9, "HorizontalAlignment", "center", "UserData", true);
    end
    % Dashed circles of constant |E|
    n_node    = numel(d.sv_node);
    iv_circle = find(~isnan(d.rv_circle))';
    plt.Circle = gobjects(n_node, 1);
    for i = iv_circle
        plt.Circle(i) = plot(ax, d.rv_circle(i)*cos(rv_th), d.rv_circle(i)*sin(rv_th), "--", "Color", obj.NodeColor(i, :), "LineWidth", 0.8);
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
        plt.Spring(e) = plot(ax, nan, nan, "-", "Color", obj.EdgeColor(e, :), "LineWidth", obj.EdgeLineWidth(e), "Tag", d.sv_edge(e));
    end
    plt.Node = gobjects(n_node, 1);
    for n = 1:n_node
        plt.Node(n) = plot(ax, nan, nan, "LineStyle", "none", "Marker", obj.NodeMarker(n), "MarkerSize", obj.NodeSize(n), ...
            "MarkerFaceColor", obj.NodeColor(n, :), "MarkerEdgeColor", "k", "Tag", d.sv_node(n));
    end
    plt.LabelNode = gobjects(n_node, 1);
    for n = 1:n_node
        plt.LabelNode(n) = text(ax, nan, nan, obj.NodeLabel(n), "FontSize", 11, "FontWeight", "bold", ...
            "Color", 0.7*obj.NodeColor(n, :), "HorizontalAlignment", "center", "Interpreter", "none");
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
    % Clicks on the nodes and springs (rows of tab_element: nodes, then springs), weakly (savefig; build keeps the graph)
    wr = matlab.lang.WeakReference(obj);
    for n = 1:n_node
        set(plt.Node(n), "ButtonDownFcn", @(~, ~) click_weak(wr, n));
    end
    for e = 1:n_edge
        set(plt.Spring(e), "ButtonDownFcn", @(~, ~) click_weak(wr, n_node + e));
    end
    % Tick labels thinned out so that none overlaps another or the data, again whenever the axes
    % are drawn at a new size, with new limits, with a new font size or at a new sample
    % (draw_sample clears the key)
    hv_data = [plt.Node; plt.Spring; plt.ArrowP(:); plt.ArrowQ(:)];
    if obj.ShowTickLabel
        plt.TickListener = listener(ax, "MarkedClean", @(~, ~) fit_ticks(ax, plt.TickAngle, plt.TickRadius, hv_data));
    else
        set([plt.TickAngle; plt.TickRadius], "Visible", "off");   % ShowTickLabel = false: no labels to choose
        plt.TickListener = [];
    end
    obj.sct_plt = plt;
    obj.apply_style((1:n_node + n_edge)');        % visibility of the nodes and springs
end


function fit_ticks(ax, hv_angle, hv_radius, hv_data)
% Show the most tick labels of the polar grid that overlap neither each other nor the data.
%
% Angle labels come first: every 30, 60 or 90 degrees, the first step whose neighbouring labels
% do not overlap (none when even 90 degrees overlap). Radius labels follow from the outermost:
% each is shown when it overlaps no shown angle label and no shown radius label. Then each
% label whose box touches a node marker, a spring or an arrow of the sample is hidden (the
% spacing does not depend on the data, so only those labels come and go during an animation).
% A label whose Visible was changed by the user (it differs from what this function or
% create_scene set last, kept in its UserData) stays as the user set it: hidden labels are
% left out, shown ones are kept. The choice is made again only when the pixel size, the
% limits or the font sizes change, or after draw_sample cleared the key (kept in the
% application data of the axes), since setting Visible draws the axes again.
    arguments (Input)
        ax                 % Axes of the picture.
        hv_angle (:,1)     % Text of the angle labels at 0, 30, ..., 330 degrees.
        hv_radius (:,1)    % Text of the radius labels, from the innermost.
        hv_data (:,1)      % Lines and patches of the data: nodes, springs and arrows.
    end
    hv = [hv_angle; hv_radius];
    if ~all(isgraphics(hv)) || ~isgraphics(ax)
        return
    end
    rv_px  = getpixelposition(ax);
    rv_key = [rv_px(3:4), ax.XLim, ax.YLim, [hv.FontSize]];
    if isequal(getappdata(ax, "GraphSpring2D_TickKey"), rv_key)
        return
    end
    setappdata(ax, "GraphSpring2D_TickKey", rv_key);
    % Labels the user turned on or off keep that state
    lv_vis  = strcmp({hv.Visible}, "on")';
    lv_user = arrayfun(@(h, l) ~(islogical(h.UserData) && isscalar(h.UserData) && h.UserData == l), hv, lv_vis);
    n_a  = numel(hv_angle);
    lu_a = lv_user(1:n_a);
    lu_r = lv_user(n_a+1:end);
    rm_a = vertcat(hv_angle.Extent);
    rm_r = vertcat(hv_radius.Extent);
    lv_a = lu_a & lv_vis(1:n_a);
    for n_step = [1 2 3]
        lv_try = lv_a;
        lv_try(1:n_step:n_a) = true;
        lv_try(lu_a) = lv_a(lu_a);
        iv = find(lv_try);
        if numel(iv) <= 1 || ~any(overlap(rm_a(iv, :), rm_a(circshift(iv, -1), :)))
            lv_a = lv_try;
            break
        end
    end
    n_r  = size(rm_r, 1);
    lv_r = lu_r & lv_vis(n_a+1:end);
    for i = n_r:-1:1
        if lu_r(i)
            continue
        end
        rm_shown = [rm_a(lv_a, :); rm_r(lv_r, :)];
        lv_r(i)  = ~any(overlap(repmat(rm_r(i, :), size(rm_shown, 1), 1), rm_shown));
    end
    % Labels on the data: the points of the visible springs and arrows (shafts filled in) and
    % the node markers as squares of their size
    lv = [lv_a; lv_r];
    rm_box = [rm_a; rm_r];
    r_unit = max(diff(ax.XLim) / rv_px(3), diff(ax.YLim) / rv_px(4)) ...
             * get(groot, "ScreenPixelsPerInch") / 72;   % data units per point (equal axes)
    rm_pt  = zeros(0, 2);
    rv_pad = zeros(0, 1);
    for h = hv_data(isgraphics(hv_data))'
        if h.Visible == "off"
            continue
        end
        rv_x = h.XData(:);
        rv_y = h.YData(:);
        r_pad = 0;
        if isa(h, "matlab.graphics.chart.primitive.Line") && h.Marker ~= "none"
            r_pad = h.MarkerSize / 2 * r_unit;
        elseif numel(rv_x) == 2                          % arrow shaft: points along it
            rv_s = linspace(0, 1, 20)';
            rv_x = rv_x(1) + rv_s*(rv_x(2) - rv_x(1));
            rv_y = rv_y(1) + rv_s*(rv_y(2) - rv_y(1));
        end
        lv_ok  = isfinite(rv_x) & isfinite(rv_y);
        rm_pt  = [rm_pt; rv_x(lv_ok), rv_y(lv_ok)];   %#ok<AGROW>
        rv_pad = [rv_pad; repmat(r_pad, nnz(lv_ok), 1)]; %#ok<AGROW>
    end
    for i = find(lv & ~lv_user)'
        rv_b = rm_box(i, :);
        if any(rm_pt(:, 1) + rv_pad > rv_b(1) & rm_pt(:, 1) - rv_pad < rv_b(1) + rv_b(3) & ...
               rm_pt(:, 2) + rv_pad > rv_b(2) & rm_pt(:, 2) - rv_pad < rv_b(2) + rv_b(4))
            lv(i) = false;
        end
    end
    set_visible(hv, lv, lv_user);
end


function lv = overlap(rm_a, rm_b)
% True for each row pair whose rectangles [left bottom width height] overlap.
    arguments (Input)
        rm_a (:,4) double  % Rectangles.
        rm_b (:,4) double  % Rectangles, the same number of rows.
    end
    arguments (Output)
        lv (:,1) logical  % Overlap of each row pair.
    end
    lv = rm_a(:, 1) < rm_b(:, 1) + rm_b(:, 3) & rm_b(:, 1) < rm_a(:, 1) + rm_a(:, 3) & ...
         rm_a(:, 2) < rm_b(:, 2) + rm_b(:, 4) & rm_b(:, 2) < rm_a(:, 2) + rm_a(:, 4);
end


function set_visible(hv, lv, lv_user)
% Set Visible of each text not owned by the user, only where it changes (a set draws the axes
% again), and keep the value set in its UserData.
    arguments (Input)
        hv (:,1)               % Texts.
        lv (:,1) logical       % Visible of each text.
        lv_user (:,1) logical  % Texts whose Visible the user set (left alone).
    end
    for i = find(~lv_user)'
        if strcmp(hv(i).Visible, "on") ~= lv(i)
            hv(i).Visible = lv(i);
        end
        hv(i).UserData = lv(i);
    end
end


function click_weak(wr, i_row)
% Click on the element i_row of the graph held by the weak reference wr (nothing once deleted).
    arguments (Input)
        wr                  % Weak reference to the graph. <@Type> matlab.lang.WeakReference
        i_row (1,1) double  % Row of the element in tab_element.
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        G.click_element(i_row);
    end
end
