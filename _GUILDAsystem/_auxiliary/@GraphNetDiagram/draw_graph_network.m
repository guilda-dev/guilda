function draw_graph_network(obj, sct_g, fcn_click)
% Draw the diagram in 3D: buses, components, branches and links as solids at the heights of sct_g.
%
% Sizes are in pt as in 2D, with 1 pt = span/400 in coordinates (u): the solids are drawn
% at the reference sizes (a bus of 6 pt: radius 0.5*6*u, a component 0.75 times that, a
% branch tube of 2.5 pt: radius 0.5*2.5*u, a link tube of LinkWidth) and apply_style
% scales them to the size of each element (BusScale, CompScale, EdgeScale). A bar is a
% box of its Length, as deep as the bus radius. The arrow cones of each branch and link
% (Tag "From" and "To") show the direction (BranchDirection, LinkDirection).
%
% With BusHeightMode other than "none", the heights are made readable (sct_plt.HeightGuide):
% a light floor with a grid (Tag "HeightFloor", "HeightGrid") below the lowest height of
% every sample and of the reference (by 15% of that range, at least 3% of span), the
% shadows of the bars, branches and links on it ("HeightShadow"), a vertical post from
% each bus center down to it ("HeightPost", one line for all buses), and the reference
% plane with its value ("HeightReference": |V| = 1 for "V", 0 for the other modes). The
% floor stays at one level for all samples, so a post compares across times. None of
% them is pickable (PickableParts "none": no click, no data tip).
    arguments (Input)
        obj
        sct_g (1,1) struct      % Geometry of diagram_geometry.
        fcn_click               % fcn_click(i_row): ButtonDownFcn of the element of row i_row of tab_element.
    end
    ax      = obj.ax;
    n_node  = obj.n_bus;
    n_edge  = obj.n_branch;
    rm_bus  = sct_g.rm_bus;
    u       = sct_g.r_span/400;                    % 1 pt in coordinates
    r_busRef  = 6;                                 % [pt] reference sizes of the drawn solids
    r_edgeRef = 2.5;
    node_radius = 0.5*r_busRef*u;

    label_bg     = [0.98 0.98 0.98];
    label_edge   = [0.75 0.75 0.75];
    label_margin = 1;

    % Bus Node Plot
    h_node  = gobjects(n_node, 1);
    h_label = gobjects(n_node, 1);
    c_busGeom = cell(n_node, 1);
    node_data = struct("Type","Bus","Index",0);
    for i_node = 1:n_node
        s_shape = obj.tab_bus.graph.Shape(i_node);
        node_data.Index = i_node;
        rv_center = rm_bus(i_node, :);
        h_node(i_node) = plot_node(ax, rv_center, s_shape, obj.tab_bus.graph.Length(i_node), node_radius, [1,1,1]*0.05, node_data);
        c_busGeom{i_node} = node_geometry(h_node(i_node), rv_center, s_shape);
        rv_label = rv_center;                          % a bar: its left (bottom) end
        k_bar = find(s_shape == ["hbar", "vbar"]);
        rv_label(k_bar) = rv_label(k_bar) - obj.tab_bus.graph.Length(i_node)/2;
        h_label(i_node) = text(ax, ...
            rv_label(1), rv_label(2) + node_radius/2, rv_label(3) + node_radius*1.5, ...
            "", ...
            'FontSize',   obj.LabelFontSize, ...
            'FontWeight', obj.LabelFontWeight, ...
            'Color',      [0,0,0], ... 
            'BackgroundColor', label_bg, ...
            'EdgeColor',  label_edge, ...
            'Margin',     label_margin,...
            'HorizontalAlignment','right');
    end

    % Branch Edge plot
    h_edge  = gobjects(n_edge, 1);
    h_arrow = gobjects(n_edge, 1);
    edge_data = struct("Type","Branch","Index",0);
    c_edgeGeom = cell(n_edge, 1);
    for i_edge = 1:n_edge
        path = sct_g.c_branch{i_edge};
        edge_data.Index = i_edge;
        [h_edge(i_edge), h_arrow(i_edge)] = plot_edge(ax, path, 0.5*r_edgeRef*u, [0.20 0.20 0.20], edge_data, obj.tab_branch.graph.Style(i_edge));

        % Geometry for the widths: the tube scales about its center line, the spheres
        % about their centers, the arrow cones about their tips (length kept within half
        % of the end segment, as plot_edge draws them)
        sct_geom = geometry_record(gobjects(0, 1), zeros(0, 3), [0 0 0], true, [Inf 1 1]);
        hv_part  = findall(h_edge(i_edge), "Type", "surface");
        rm_axis  = zeros(0, 3);
        for h = hv_part'
            if h.Tag == "tube"
                rm_x    = cat(3, h.XData, h.YData, h.ZData);
                rm_axis = squeeze(mean(rm_x(:, 1:end-1, :), 2));
                rm_axis = reshape(rm_axis, [], 3);
                sct_geom(end+1) = geometry_record(h, repmat(rm_axis, size(rm_x, 2), 1), [0 0 0], true, [Inf 1 1]); %#ok<AGROW>
            else
                rm_p = [h.XData(:), h.YData(:), h.ZData(:)];
                sct_geom(end+1) = geometry_record(h, (min(rm_p) + max(rm_p))/2, [0 0 0], true, [Inf 1 1]); %#ok<AGROW>
            end
        end
        if isgraphics(h_arrow(i_edge)) && size(rm_axis, 1) >= 2
            for h = reshape(allchild(h_arrow(i_edge)), 1, [])
                if h.Tag == "From"
                    c_cone = {1, norm(rm_axis(2, :) - rm_axis(1, :))};
                else
                    c_cone = {2, norm(rm_axis(end, :) - rm_axis(end-1, :))};
                end
                rm_x    = [h.XData(:), h.YData(:), h.ZData(:)];
                n_cc    = size(h.XData, 2);
                rv_tip  = rm_x(2, :);
                rv_base = mean(rm_x(1:2:2*(n_cc-1), :), 1);
                r_len   = norm(rv_tip - rv_base);
                r_cone  = norm(rm_x(1, :) - rv_base);
                sct_geom(end+1) = geometry_record(h, rv_tip, (rv_tip - rv_base)/max(r_len, eps), true, ...
                    [0.5*c_cone{2}, c_cone{1}*r_cone, max(r_len, eps)]); %#ok<AGROW>
            end
        end
        c_edgeGeom{i_edge} = sct_geom;
    end

    n_comp       = obj.n_component;
    comp_handles = gobjects(n_comp, 1);
    comp_labels  = gobjects(n_comp, 1);   % made by reflect_node_label when LabelMode shows them
    rm_clabel    = zeros(n_comp, 3);
    comp_edges   = gobjects(n_comp, 1);
    comp_arrows  = gobjects(n_comp, 1);
    c_compGeom   = cell(n_comp, 1);
    node_data = struct("Type","Component","Index",0);
    for i_comp = 1:n_comp
        node_data.Index = i_comp;
        s_shape  = obj.tab_component.graph.Shape(i_comp);
        comp_pos = sct_g.rm_comp(i_comp, :);
        comp_handles(i_comp) = plot_node(ax, comp_pos, s_shape, NaN, node_radius*0.75, [0.15 0.15 0.15], node_data);
        c_compGeom{i_comp}   = node_geometry(comp_handles(i_comp), comp_pos, s_shape);
        [comp_edges(i_comp), comp_arrows(i_comp)] = plot_edge(ax, sct_g.c_link{i_comp}, 0.5*obj.LinkWidth*u, [0.20 0.20 0.20], ...
            struct("Type", "Link", "Index", i_comp), "line");
        rm_clabel(i_comp, :) = comp_pos + node_radius*1.5;
    end

    % Height guide (BusHeightMode other than "none"): a floor below every bus over all
    % samples, a grid and the shadows of the buses, branches and links on it, a post from
    % each bus down to it, and the reference plane of the quantity (|V| = 1, else 0). One
    % line or patch each, not pickable (no clicks, no data tips).
    sct_guide = struct.empty;
    if ~isempty(sct_g.sct_height)
        sct_h   = sct_g.sct_height;
        r_ref   = sct_h.Ref;
        rv_lim  = sct_h.Ref + sct_h.Scale*(sct_h.Lim - sct_h.Ref);       % drawn heights of the values
        r_top   = rv_lim(2);
        r_floor = rv_lim(1) - max(0.15*diff(rv_lim), 0.03*sct_g.r_span);
        r_lift  = 2e-3*(r_top - r_floor);           % lines just above the floor (no z-fighting)

        % Box of the floor: the drawing with a margin of 2% of its larger side
        rv_half = obj.tab_bus.graph.Length/2;
        rv_half(~isfinite(rv_half)) = 0;
        rm_bar = [rv_half.*(obj.tab_bus.graph.Shape == "hbar"), rv_half.*(obj.tab_bus.graph.Shape == "vbar")];
        rm_xy  = [rm_bus(:, 1:2) - rm_bar; rm_bus(:, 1:2) + rm_bar; sct_g.rm_comp(:, 1:2); ...
                  vertcat(sct_g.c_branch{:}, zeros(0, 3)) * [1 0; 0 1; 0 0]; vertcat(sct_g.c_link{:}, zeros(0, 3)) * [1 0; 0 1; 0 0]];
        rm_xy  = rm_xy(all(isfinite(rm_xy), 2), :);
        r_pad  = 0.02*sct_g.r_span;
        rv_x   = [min(rm_xy(:, 1)) - r_pad, max(rm_xy(:, 1)) + r_pad];
        rv_y   = [min(rm_xy(:, 2)) - r_pad, max(rm_xy(:, 2)) + r_pad];
        rm_corner = [rv_x([1 2 2 1])', rv_y([1 1 2 2])'];

        c_guide = {"PickableParts", "none", "HitTest", "off", "HandleVisibility", "off"};
        h_floor = patch(ax, "XData", rm_corner(:, 1), "YData", rm_corner(:, 2), "ZData", repmat(r_floor, 4, 1), ...
            "FaceColor", [0.95 0.95 0.95], "EdgeColor", [0.75 0.75 0.75], "FaceLighting", "none", "Tag", "HeightFloor", c_guide{:});

        % Grid of about 10 lines along the larger side, at a 1-2-5 step
        rv_step = 10^floor(log10(sct_g.r_span/10))*[1 2 5 10];
        r_step  = rv_step(find(rv_step >= sct_g.r_span/10, 1));
        rv_gx  = (ceil(rv_x(1)/r_step):floor(rv_x(2)/r_step))*r_step;
        rv_gy  = (ceil(rv_y(1)/r_step):floor(rv_y(2)/r_step))*r_step;
        rm_grid = [reshape([rv_gx; rv_gx; nan(size(rv_gx))], [], 1), reshape(repmat([rv_y'; NaN], 1, numel(rv_gx)), [], 1); ...
                   reshape(repmat([rv_x'; NaN], 1, numel(rv_gy)), [], 1), reshape([rv_gy; rv_gy; nan(size(rv_gy))], [], 1)];
        h_grid = line(ax, rm_grid(:, 1), rm_grid(:, 2), repmat(r_floor + r_lift/2, size(rm_grid, 1), 1), ...
            "Color", [0.86 0.86 0.86], "LineWidth", 0.5, "Tag", "HeightGrid", c_guide{:});

        % Shadows of the bars, branches and links, and the posts of the buses
        lv_bar   = any(rm_bar ~= 0, 2);
        rm_bars  = reshape(permute(cat(3, rm_bus(lv_bar, 1:2) - rm_bar(lv_bar, :), rm_bus(lv_bar, 1:2) + rm_bar(lv_bar, :), ...
                   nan(sum(lv_bar), 2)), [3 1 2]), [], 2);
        c_shadow = cellfun(@(p) [p(:, 1:2); NaN NaN], [sct_g.c_branch; sct_g.c_link], "UniformOutput", false);
        rm_shadow = [rm_bars; vertcat(c_shadow{:}, zeros(0, 2))];
        h_shadow = line(ax, rm_shadow(:, 1), rm_shadow(:, 2), repmat(r_floor + r_lift, size(rm_shadow, 1), 1), ...
            "Color", [0.72 0.72 0.72], "LineWidth", 1, "Tag", "HeightShadow", c_guide{:});
        rm_post = reshape(permute(cat(3, rm_bus, [rm_bus(:, 1:2), repmat(r_floor, n_node, 1)], nan(n_node, 3)), [3 1 2]), [], 3);
        h_post = line(ax, rm_post(:, 1), rm_post(:, 2), rm_post(:, 3), ...
            "Color", [0.45 0.45 0.45], "LineWidth", 0.75, "Tag", "HeightPost", c_guide{:});

        % Reference plane and its value
        h_ref = patch(ax, "XData", rm_corner(:, 1), "YData", rm_corner(:, 2), "ZData", repmat(r_ref, 4, 1), ...
            "FaceColor", [0.30 0.55 0.85], "FaceAlpha", 0.10, "EdgeColor", [0.30 0.55 0.85], "EdgeAlpha", 0.6, ...
            "FaceLighting", "none", "Tag", "HeightReference", c_guide{:});
        sv_name = dictionary(["V", "angle", "Vimag", "P", "Q"], ["|V| [pu]", "∠V [rad]", "Im V [pu]", "P [pu]", "Q [pu]"]);
        s_name  = sv_name(obj.BusHeightMode);
        h_refText = text(ax, rv_x(2), rv_y(2), r_ref, " " + extractBefore(s_name, " [") + " = " + r_ref + " ", ...
            "Color", [0.20 0.40 0.70], "FontSize", max(obj.LabelFontSize - 1, 6), "VerticalAlignment", "bottom", ...
            "HorizontalAlignment", "right", "Tag", "HeightReference", c_guide{:});
        sct_guide = struct("Floor", h_floor, "Grid", h_grid, "Shadow", h_shadow, "Post", h_post, ...
            "Reference", h_ref, "ReferenceText", h_refText, "ZFloor", r_floor, "ZReference", r_ref, ...
            "ZTop", r_top, "Scale", sct_h.Scale, "Name", s_name);
    end

    obj.sct_plt = struct(         ...
        'EdgeMain', h_edge,   ...
        'EdgeArrow', h_arrow, ...
        'EdgeSymbol', gobjects(n_edge, 1), ...
        'NodeMain', h_node,   ...
        'NodeLabel', h_label, ...
        'NodeLabelXYZ', reshape([h_label.Position], 3, [])', ...
        'NodeBar', ismember(obj.tab_bus.graph.Shape, ["hbar", "vbar"]), ...
        'CompMain', comp_handles, ...
        'CompEdge', comp_edges, ...
        'CompArrow', comp_arrows, ...
        'CompLabel', comp_labels,  ...
        'CompLabelXYZ', rm_clabel, ...
        'CompLabelArgs', {{'FontWeight', 'bold', 'Color', [0 0 1], 'BackgroundColor', label_bg, ...
                           'EdgeColor', label_edge, 'Margin', label_margin}}, ...
        'CompParentBus', obj.tab_component.bus, ...
        'XMain', rm_bus(:, 1),   ...
        'YMain', rm_bus(:, 2),   ...
        'ZMain', rm_bus(:, 3),   ...
        'NodeRadius', node_radius, ...
        'D0', sct_g.d0, ...
        'BusGeom', {c_busGeom}, ...
        'CompGeom', {c_compGeom}, ...
        'EdgeGeom', {c_edgeGeom}, ...
        'EdgePath', {sct_g.c_branch}, ...
        'CompPath', {sct_g.c_link}, ...
        'BranchWidth0', nan(n_edge, 1), ...
        'BusSize0', nan(n_node, 1), ...
        'CompSize0', nan(n_comp, 1), ...
        'BusRef', r_busRef, ...
        'EdgeRef', r_edgeRef, ...
        'BusScale', ones(n_node, 1), ...
        'CompScale', ones(n_comp, 1), ...
        'EdgeScale', ones(n_edge, 1), ...
        'HeightGuide', {sct_guide}, ...
        'BusColor0', default_color(h_node, n_node), ...
        'CompColor0', default_color(comp_handles, n_comp), ...
        'Selection', gobjects(0, 1));

    % Clicks: every solid of an element reports its row of tab_element
    n_b = n_node;
    n_c = n_comp;
    c_row = {h_node, 0; comp_handles, n_b; h_edge, n_b + n_c; h_arrow, n_b + n_c; ...
             comp_edges, n_b + n_c + n_edge; comp_arrows, n_b + n_c + n_edge};
    for i_set = 1:size(c_row, 1)
        hv = c_row{i_set, 1};
        for i = 1:numel(hv)
            if isgraphics(hv(i))
                set(findall(hv(i)), "ButtonDownFcn", fcn_click(c_row{i_set, 2} + i));
            end
        end
    end
end

function sct_geom = node_geometry(h, rv_center, s_shape)
% Geometry of a bus or component solid for its marker size: it scales about its center; a
% bar ("hbar", "vbar") keeps its length and scales its height only.
    arguments (Input)
        h                       % Solid drawn by plot_node.
        rv_center (1,3) double  % Center of the solid.
        s_shape (1,1) string    % Shape of the element (graph parameter Shape).
    end
    arguments (Output)
        sct_geom (1,:) struct  % Geometry records (see geometry_record).
    end
    if any(s_shape == ["hbar", "vbar"])
        sct_geom = geometry_record(h, rv_center, [0 0 1], false, [Inf 1 1]);
    else
        sct_geom = geometry_record(h, rv_center, [0 0 0], true, [Inf 1 1]);
    end
end


function sct = geometry_record(hv, rm_anchor, rv_axis, l_radial, rv_len)
% Points of a drawn surface or patch split about its anchor, for scaling it later.
%
% A point p becomes A + Prad*fr + Pax*fa at the scale f, where Pax is the part of p - A
% along rv_axis and Prad the rest; fr is f (1 when l_radial is false) and fa is
% min(Lmax, Lfull*f)/L0 with rv_len = [Lmax, Lfull, L0].
    arguments (Input)
        hv                       % Surface or patch (none: an empty record).
        rm_anchor (:,3) double   % Anchor of each point, or one for all.
        rv_axis (1,3) double     % Unit axis of the axial part ([0 0 0]: none).
        l_radial (1,1) logical   % The part off the axis scales.
        rv_len (1,3) double      % [Lmax, Lfull, L0] of the axial scale.
    end
    arguments (Output)
        sct (1,:) struct  % Fields h, l_surf, sz (size of the data of a surface), A, Prad, Pax, l_radial, rv_len.
    end
    sct = struct("h", {}, "l_surf", {}, "sz", {}, "A", {}, "Prad", {}, "Pax", {}, "l_radial", {}, "rv_len", {});
    if isempty(hv) || ~isgraphics(hv) || ~(isprop(hv, "Vertices") || isprop(hv, "ZData"))
        return
    end
    l_surf = ~isprop(hv, "Vertices");
    sz     = [];
    if l_surf
        rm_p = [hv.XData(:), hv.YData(:), hv.ZData(:)];
        sz   = size(hv.XData);
    else
        rm_p = hv.Vertices;
        if size(rm_p, 2) < 3
            return
        end
    end
    rm_a   = rm_anchor .* ones(size(rm_p, 1), 1);
    rm_d   = rm_p - rm_a;
    rm_ax  = (rm_d * rv_axis') * rv_axis;
    sct(1) = struct("h", hv, "l_surf", l_surf, "sz", sz, "A", rm_a, "Prad", rm_d - rm_ax, "Pax", rm_ax, ...
                    "l_radial", l_radial, "rv_len", rv_len);
end


function rm_color = default_color(h_list, n)
% Face color of each drawn solid (its first colored child for a group), before any color is set.
    arguments (Input)
        h_list          % Graphics objects of the solids.
        n (1,1) double  % Number of solids.
    end
    arguments (Output)
        rm_color (:,3) double  % RGB color of each solid.
    end
    rm_color = repmat(0.2, n, 3);
    for i = 1:min(n, numel(h_list))
        h = h_list(i);
        if isgraphics(h) && ~isprop(h, 'FaceColor') && isprop(h, 'Children') && ~isempty(allchild(h))
            h = allchild(h);
            h = h(1);
        end
        if isgraphics(h) && isprop(h, 'FaceColor') && isnumeric(h.FaceColor) && numel(h.FaceColor) == 3
            rm_color(i, :) = h.FaceColor;
        end
    end
end
