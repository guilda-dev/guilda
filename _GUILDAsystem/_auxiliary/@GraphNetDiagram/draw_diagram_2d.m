function draw_diagram_2d(obj, sct_g, fcn_click)
% Draw the diagram in 2D: one line object per element, flat symbols at the heights of sct_g.
%
% A branch and a link are polylines along their paths; a transformer (Style
% "transformer") adds two overlapping circles near its "from" end (radius
% min(0.06*d0, 0.2*length), centers 1.6 and 2.8 radii along the path); a bar bus is a line
% segment of its Length; a point bus and a component are a marker of their Shape ("none":
% a hidden marker). The labels lie next to their element, 0.05*d0 away: a point bus
% label above it, a horizontal bar label left of its left end, a vertical bar label above
% its top end, a component label right of it. They are made in the drawing order:
% branches, links, transformer circles, flow dots (two empty patches FlowBranch and
% FlowLink, filled by step_flow), components, buses (over a component placed next to
% them), bus labels (the axes draw in the order of the children). The component labels are made by reflect_node_label when
% LabelMode shows them (from CompLabelXYZ and CompLabelArgs), on top. NodeLabelXYZ keeps
% the places of the bus labels before fit_axes pushes overlapping ones apart. The colors,
% sizes and widths are set afterwards by apply_style.
%
% The single-line diagram of plot_single_line_diagram (l_singleLine) draws everything in
% black, its labels without a box in Helvetica, a generator (a class of component.generator) as a
% circle with one period of a sine inside (one line object, Tag "GeneratorGlyph", radius
% min(0.025*span, 0.8 times the first segment of its link); the link stops at the circle) and
% a load (a class of component.load) as a filled triangle marker pointing away from its
% bus along the first segment of its link.
    arguments (Input)
        obj
        sct_g (1,1) struct      % Geometry of diagram_geometry.
        fcn_click               % fcn_click(i_row): ButtonDownFcn of the element of row i_row of tab_element.
    end
    ax  = obj.ax;
    n_b = obj.n_bus;
    n_c = obj.n_component;
    n_e = obj.n_branch;
    d0  = sct_g.d0;
    rv_gray = [0.2 0.2 0.2];
    l_sld = obj.l_singleLine;
    if l_sld
        rv_gray = [0 0 0];
    end
    % Single-line diagram: kind of each component (generator glyph, load triangle) and the
    % first segment of its link (from the component towards the bus)
    lv_gen  = false(n_c, 1);
    lv_load = false(n_c, 1);
    rm_dir  = zeros(n_c, 2);
    rv_seg  = zeros(n_c, 1);
    if l_sld && n_c > 0
        lv_gen  = startsWith(obj.tab_component.class, "component.generator.");
        lv_load = startsWith(obj.tab_component.class, "component.load.");
        for c = 1:n_c
            p = sct_g.c_link{c};
            if size(p, 1) > 1
                rm_dir(c, :) = p(1, 1:2) - p(2, 1:2);
                rv_seg(c)    = norm(rm_dir(c, :));
            end
        end
    end
    rv_rg = min(0.025*sct_g.r_span, 0.8*rv_seg);    % radius of the generator circles
    rv_rg(~(rv_rg > 0)) = 0.025*sct_g.r_span;

    % Branches and links
    h_edge = gobjects(n_e, 1);
    for k = 1:n_e
        p = sct_g.c_branch{k};
        h_edge(k) = line(ax, p(:, 1), p(:, 2), p(:, 3), "Color", rv_gray, "LineWidth", 2.5, ...
            "UserData", struct("Type", "Branch", "Index", k), "ButtonDownFcn", fcn_click(n_b + n_c + k));
    end
    h_link = gobjects(n_c, 1);
    for c = 1:n_c
        p = sct_g.c_link{c};
        if lv_gen(c) && rv_seg(c) > rv_rg(c)       % the link stops at the circle of the generator
            p(1, 1:2) = p(1, 1:2) - rv_rg(c)*rm_dir(c, :)/rv_seg(c);
        end
        h_link(c) = line(ax, p(:, 1), p(:, 2), p(:, 3), "Color", rv_gray, "LineWidth", obj.LinkWidth, ...
            "UserData", struct("Type", "Link", "Index", c), "ButtonDownFcn", fcn_click(n_b + n_c + n_e + c));
    end

    % Transformer circles: points of both circles (NaN between) and their place along the path
    h_sym  = gobjects(n_e, 1);
    c_frac = cell(n_e, 1);
    rv_th  = linspace(0, 2*pi, 49);
    iv_tr = zeros(0, 1);
    if n_e > 0                                    % a network without branches has no graph columns
        iv_tr = find(obj.tab_branch.graph.Style == "transformer");
    end
    for k = iv_tr'
        p      = sct_g.c_branch{k};
        rv_f   = sct_g.c_branchFrac{k};
        r_len  = sum(vecnorm(diff(p(:, 1:2), 1, 1), 2, 2));
        if ~(r_len > 0)
            continue
        end
        r_rho = min(0.06*d0, 0.2*r_len);
        [rv_fu, iv_u] = unique(rv_f);
        rv_fc = [1.6, 2.8]*r_rho/r_len;               % centers along the path
        rm_c  = interp1(rv_fu, p(iv_u, 1:2), rv_fc(:));
        rv_x  = [rm_c(1, 1) + r_rho*cos(rv_th), NaN, rm_c(2, 1) + r_rho*cos(rv_th)];
        rv_y  = [rm_c(1, 2) + r_rho*sin(rv_th), NaN, rm_c(2, 2) + r_rho*sin(rv_th)];
        c_frac{k} = [repmat(rv_fc(1), 1, 49), NaN, repmat(rv_fc(2), 1, 49)];
        rv_z  = p(1, 3) + c_frac{k}*(p(end, 3) - p(1, 3));
        h_sym(k) = line(ax, rv_x, rv_y, rv_z, "Color", rv_gray, "LineWidth", 2.5, ...
            "UserData", struct("Type", "Branch", "Index", k), "ButtonDownFcn", fcn_click(n_b + n_c + k));
    end

    % Flow dots (step_flow): one patch for the branches, one for the links, one face per dot;
    % white with a thin dark edge (seen on dark and light lines and on the white background)
    c_flow = {"Faces", zeros(0, 3), "Vertices", zeros(0, 3), "FaceColor", [1 1 1], ...
              "EdgeColor", [0.25 0.25 0.25], "LineWidth", 0.5, "PickableParts", "none", "HitTest", "off", ...
              "UserData", struct("Type", "Flow", "Index", zeros(0, 1))};
    h_flowBranch = patch(ax, c_flow{:}, "Tag", "FlowBranch");
    h_flowLink   = patch(ax, c_flow{:}, "Tag", "FlowLink");

    % Components: a marker of its shape, filled with the default color of the shape (under the buses)
    rm_comp  = sct_g.rm_comp;
    h_comp   = gobjects(n_c, 1);
    rm_comp0 = repmat(0.15, n_c, 3);
    for c = 1:n_c
        s_shape = obj.tab_component.graph.Shape(c);
        c_arg = {"UserData", struct("Type", "Component", "Index", c), "ButtonDownFcn", fcn_click(n_b + c)};
        if l_sld
            rm_comp0(c, :) = 0;
        elseif s_shape == "circle"
            rm_comp0(c, :) = [0.611 0.466 0.125];
        elseif any(s_shape == ["^", "v", "<", ">"])
            rm_comp0(c, :) = [0.717 0.192 0.172];
        end
        if lv_gen(c)                               % circle and one period of a sine, one line
            r_g   = rv_rg(c);
            rv_s  = linspace(-1, 1, 25);
            rv_x  = rm_comp(c, 1) + [r_g*cos(rv_th), NaN, 0.7*r_g*rv_s];
            rv_y  = rm_comp(c, 2) + [r_g*sin(rv_th), NaN, 0.4*r_g*sin(pi*rv_s)];
            h_comp(c) = line(ax, rv_x, rv_y, rm_comp(c, 3) + zeros(size(rv_x)), "Color", rv_gray, ...
                "LineWidth", obj.LinkWidth, "Tag", "GeneratorGlyph", c_arg{:});
            continue
        end
        s_marker = marker_of(s_shape);
        if lv_load(c)                              % a triangle pointing away from the bus
            rv_d = rm_dir(c, :);
            sv_dir = ["<", ">", "v", "^"];          % -x, +x, -y, +y
            if rv_seg(c) == 0
                s_marker = "v";
            elseif abs(rv_d(1)) > abs(rv_d(2))
                s_marker = sv_dir(1 + (rv_d(1) > 0));
            else
                s_marker = sv_dir(3 + (rv_d(2) > 0));
            end
        end
        h_comp(c) = line(ax, rm_comp(c, 1), rm_comp(c, 2), rm_comp(c, 3), "LineStyle", "none", ...
            "Marker", s_marker, "MarkerSize", 6, "MarkerFaceColor", rm_comp0(c, :), ...
            "Color", rm_comp0(c, :), "Visible", s_shape ~= "none" || lv_load(c), c_arg{:});
    end

    % Buses: a bar is a segment, the other shapes a marker (over the components next to them)
    tab_g  = obj.tab_bus.graph;
    rm_bus = sct_g.rm_bus;
    h_node = gobjects(n_b, 1);
    lv_bar = false(n_b, 1);
    for i = 1:n_b
        s_shape = tab_g.Shape(i);
        c_arg = {"UserData", struct("Type", "Bus", "Index", i), "ButtonDownFcn", fcn_click(i), "Color", rv_gray};
        rv_c  = rm_bus(i, :);
        r_h   = tab_g.Length(i)/2;
        switch s_shape
            case "hbar"
                lv_bar(i) = true;
                h_node(i) = line(ax, rv_c(1) + [-r_h, r_h], rv_c([2 2]), rv_c([3 3]), "LineWidth", 3, c_arg{:});
            case "vbar"
                lv_bar(i) = true;
                h_node(i) = line(ax, rv_c([1 1]), rv_c(2) + [-r_h, r_h], rv_c([3 3]), "LineWidth", 3, c_arg{:});
            otherwise
                h_node(i) = line(ax, rv_c(1), rv_c(2), rv_c(3), "LineStyle", "none", "Marker", marker_of(s_shape), ...
                    "MarkerSize", 6, "MarkerFaceColor", rv_gray, "Visible", s_shape ~= "none", c_arg{:});
        end
    end

    % Labels
    c_text  = {"FontSize", obj.LabelFontSize, "BackgroundColor", [0.98 0.98 0.98], ...
               "EdgeColor", [0.75 0.75 0.75], "Margin", 1, "PickableParts", "none"};
    if l_sld                                       % plain text for a paper
        c_text(4:2:6) = {"none", "none"};
        c_text = [c_text, {"FontName", "Helvetica"}];
    end
    r_gap   = 0.05*d0;
    h_label = gobjects(n_b, 1);
    for i = 1:n_b
        r_h = tab_g.Length(i)/2;
        switch tab_g.Shape(i)
            case "hbar"
                rv_p = [rm_bus(i, 1) - r_h - r_gap, rm_bus(i, 2)];
                c_al = {"HorizontalAlignment", "right", "VerticalAlignment", "middle"};
            case "vbar"
                rv_p = [rm_bus(i, 1), rm_bus(i, 2) + r_h + r_gap];
                c_al = {"HorizontalAlignment", "center", "VerticalAlignment", "bottom"};
            otherwise
                rv_p = [rm_bus(i, 1), rm_bus(i, 2) + r_gap];
                c_al = {"HorizontalAlignment", "center", "VerticalAlignment", "bottom"};
        end
        h_label(i) = text(ax, rv_p(1), rv_p(2), rm_bus(i, 3), "", "Color", [0 0 0], ...
            "FontWeight", obj.LabelFontWeight, c_al{:}, c_text{:});
    end
    % Component labels: made by reflect_node_label when LabelMode shows them (a text object
    % costs time in a figure capture, e.g. of the Live Editor, even when hidden)
    rm_clabel = rm_comp + [r_gap, 0, 0];
    c_clabel  = [{"Color", [0 0 1], "FontWeight", "bold", "VerticalAlignment", "middle"}, c_text];

    obj.sct_plt = struct( ...
        "EdgeMain", h_edge, "EdgeArrow", gobjects(n_e, 1), "EdgeSymbol", h_sym, "SymbolFrac", {c_frac}, ...
        "NodeMain", h_node, "NodeLabel", h_label, "NodeBar", lv_bar, ...
        "NodeLabelXYZ", reshape([h_label.Position], 3, [])', ...
        "CompMain", h_comp, "CompEdge", h_link, "CompArrow", gobjects(n_c, 1), "CompLabel", gobjects(n_c, 1), ...
        "CompLabelXYZ", rm_clabel, "CompLabelArgs", {c_clabel}, ...
        "CompParentBus", obj.tab_component.bus, ...
        "XMain", rm_bus(:, 1), "YMain", rm_bus(:, 2), "ZMain", rm_bus(:, 3), "NodeRadius", 0, "D0", d0, ...
        "EdgePath", {sct_g.c_branch}, "CompPath", {sct_g.c_link}, ...
        "BranchWidth0", nan(n_e, 1), "BusSize0", nan(n_b, 1), "CompSize0", nan(n_c, 1), ...
        "BusColor0", repmat(rv_gray, n_b, 1), "CompColor0", rm_comp0, "Selection", gobjects(0, 1), ...
        "FlowBranch", h_flowBranch, "FlowLink", h_flowLink);
end


function s_marker = marker_of(s_shape)
% MATLAB marker of a Shape of a bus or a component ("circle": "o", "square" and others: "s").
    arguments (Input)
        s_shape (1,1) string  % Shape of the graph parameters.
    end
    arguments (Output)
        s_marker (1,1) string  % Marker.
    end
    switch s_shape
        case {"^", "v", "<", ">"}
            s_marker = s_shape;
        case {"circle", "none"}
            s_marker = "o";
        otherwise
            s_marker = "s";
    end
end
