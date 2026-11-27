function create_scene(obj)
% Draw the diagram: the lines from the components to their buses, the blocks with their texts, the arrows with their heads and labels, and the legend of the kinds of signal.
%
% The axes have equal units, rows going down and no ruler. The labels of the arrows sit at
% the middle of the curve into their targets (a stub: at its free end), over the blocks,
% and are pushed apart vertically where they overlap. Every
% block, arrow, head and label calls click_element with its row when clicked.
    arguments (Input)
        obj
    end
    d   = obj.sct_data;
    ax  = obj.ax(1);
    n_b = numel(d.sv_blockTag);
    n_a = numel(d.sv_arrowTag);
    cla(ax);
    hold(ax, "on");
    plt = struct("Block", gobjects(n_b, 1), "BlockText", gobjects(n_b, 1), "Arrow", gobjects(n_a, 1), ...
        "ArrowHead", gobjects(n_a, 1), "ArrowText", gobjects(n_a, 1), "Holder", gobjects(0, 1), ...
        "Legend", gobjects(0, 1), "Selection", gobjects(0, 1));
    wr = matlab.lang.WeakReference(obj);
    rm_xy   = d.rm_blockXY;
    rm_size = d.rm_blockSize;

    % A thin line from each component to its bus
    [~, iv_parent] = ismember(d.sv_blockParent, d.sv_blockTag);
    for i = find(d.sv_blockKind == "component" & iv_parent > 0)'
        j = iv_parent(i);
        plt.Holder(end+1, 1) = line(ax, [rm_xy(i, 1) + 0.5 * rm_size(i, 1), rm_xy(j, 1)], rm_xy([i j], 2)', ...
            "Color", [0.55 0.55 0.55], "LineWidth", 1, "HitTest", "off", "PickableParts", "none", "Tag", "Holder");
    end

    % Arrows: the curve and a head at the target
    r_head = 0.22;
    for k = 1:n_a
        rm_p = d.c_arrowPath{k};
        rv_tip = rm_p(end, :);
        rv_u = rv_tip - rm_p(end-3, :);
        rv_u = rv_u / max(norm(rv_u), 1e-9);
        rv_w = [-rv_u(2), rv_u(1)];
        rv_base = rv_tip - r_head * rv_u;
        l_shaft = vecnorm(rm_p - rv_tip, 2, 2) >= r_head;     % the shaft stops at the base of the head
        rm_shaft = [rm_p(l_shaft, :); rv_base];
        rm_tri = [rv_tip; rv_base + 0.45 * r_head * rv_w; rv_base - 0.45 * r_head * rv_w];
        i_row = n_b + k;
        fcn = @(~, ~) click_weak(wr, i_row);
        plt.Arrow(k) = line(ax, rm_shaft(:, 1), rm_shaft(:, 2), "ButtonDownFcn", fcn, "Tag", "Arrow");
        plt.ArrowHead(k) = patch(ax, rm_tri(:, 1), rm_tri(:, 2), "k", "ButtonDownFcn", fcn, "Tag", "ArrowHead");
    end

    % Blocks over the arrows: a rectangle and its text (a bus: a bar with the tag to its right)
    for i = 1:n_b
        rv_h = 0.5 * rm_size(i, :);
        fcn = @(~, ~) click_weak(wr, i);
        plt.Block(i) = patch(ax, rm_xy(i, 1) + rv_h(1) * [-1 1 1 -1], rm_xy(i, 2) + rv_h(2) * [-1 -1 1 1], "w", ...
            "ButtonDownFcn", fcn, "Tag", "Block");
        if d.sv_blockKind(i) == "bus"
            plt.BlockText(i) = text(ax, rm_xy(i, 1) + rv_h(1) + 0.12, rm_xy(i, 2), "", "FontSize", 8, ...
                "FontWeight", "bold", "Interpreter", "none", "HorizontalAlignment", "left", "ButtonDownFcn", fcn, "Tag", "BlockText");
        else
            plt.BlockText(i) = text(ax, rm_xy(i, 1), rm_xy(i, 2), "", "FontSize", 7.5, "Interpreter", "none", ...
                "HorizontalAlignment", "center", "VerticalAlignment", "middle", "ButtonDownFcn", fcn, "Tag", "BlockText");
        end
    end

    % Labels of the arrows over everything (the label of a stub ends at its free end)
    sv_align = ["center", "right"];
    for k = 1:n_a
        rv_mid = d.rm_arrowText(k, :);
        fcn = @(~, ~) click_weak(wr, n_b + k);
        plt.ArrowText(k) = text(ax, rv_mid(1), rv_mid(2), "", "FontSize", 7, "Interpreter", "none", ...
            "HorizontalAlignment", sv_align(1 + (d.sv_arrowKind(k) == "equilibrium")), "VerticalAlignment", "middle", ...
            "BackgroundColor", "w", "Margin", 0.5, "ButtonDownFcn", fcn, "Tag", "ArrowLabel");
    end

    % Axes: equal units, rows down, no ruler
    rm_lo = rm_xy - 0.5 * rm_size;
    rm_hi = rm_xy + 0.5 * rm_size;
    rm_all = [rm_lo; rm_hi; vertcat(d.c_arrowPath{:})];
    if isempty(rm_all)
        rm_all = [0 0; 1 1];
    end
    l_eq = d.sv_arrowKind == "equilibrium";                % room for the labels left of the stubs
    r_left = min(rm_all(:, 1)) - 0.4;
    if any(l_eq)
        r_left = min(r_left, min(d.rm_arrowText(l_eq, 1) - 0.13 * strlength(obj.ArrowLabel(l_eq))) - 0.2);
    end
    set(ax, "YDir", "reverse", "DataAspectRatio", [1 1 1], "Visible", "off", ...
        "XLim", [r_left, max(rm_all(:, 1)) + 1.8], "YLim", [min(rm_all(:, 2)) - 0.6, max(rm_all(:, 2)) + 0.6]);
    ax.Title.Visible = "on";
    set(ax, "ButtonDownFcn", []);

    % Legend of the kinds of signal drawn (lines without data)
    sv_kind = ["local", "global", "observe", "equilibrium"];
    for s_kind = sv_kind(ismember(sv_kind, d.sv_arrowKind))
        k = find(d.sv_arrowKind == s_kind, 1);
        plt.Legend(end+1, 1) = line(ax, NaN, NaN, "Color", obj.ArrowColor(k, :), "LineStyle", obj.ArrowLineStyle(k), ...
            "LineWidth", obj.ArrowLineWidth(k), "DisplayName", s_kind, "Tag", "LegendEntry");
    end
    hold(ax, "off");
    if isempty(plt.Legend)
        legend(ax, "off");
    else
        legend(ax, plt.Legend, "Location", "southoutside", "Orientation", "horizontal", "Box", "off", "AutoUpdate", "off");
    end

    obj.sct_plt = plt;
    obj.apply_style((1:n_b + n_a)');
    if n_a > 1
        obj.resolve_overlap(plt.ArrowText, plt.BlockText(d.sv_blockKind ~= "bus"), 30, 0.02);
    end
end


function click_weak(wr, i_row)
% Click on the element of row i_row of the graph held by wr.
    arguments (Input)
        wr                  % Weak reference to the graph. <@Type> matlab.lang.WeakReference
        i_row (1,1) double  % Row of the element in tab_element.
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        G.click_element(i_row);
    end
end
