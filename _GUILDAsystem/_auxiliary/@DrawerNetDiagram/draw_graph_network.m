function draw_graph_network(obj)

    n_node   = obj.n_bus;
    rm_axis  = obj.tab_bus.graph{:, {'Xaxis', 'Yaxis'}}.';
    x_main   = rm_axis(1,:);
    y_main   = rm_axis(2,:);
    z_main   = get_node_height(obj, obj.NodeHeightMode).';
    
    label_bg     = [0.98 0.98 0.98];
    label_edge   = [0.75 0.75 0.75];
    label_margin = 1;

    n_edge  = size(obj.im_edge, 2);
    h_edge  = gobjects(n_edge, 1);
    h_arrow = gobjects(n_edge, 1);

    span_xy = max([max(x_main)-min(x_main), max(y_main)-min(y_main), eps]);
    node_radius = 0.016 * span_xy * (obj.MarkerSize/10);
    edge_base_radius = node_radius * 0.08;
    rv_edge_width = zeros(n_edge, 1);
    for i_edge = 1:n_edge
        pd = obj.tab_branch.dynamics(i_edge, :);
        if strcmp(obj.EdgeWidthMode, "SvdMaxYmat")
            rv_edge_width(i_edge) = pd.SvdMaxYmat;
            continue
        end
        y_series = 1/(pd.R + 1j*pd.X);
        Y = abs(y_series);
        G = abs(real(y_series));
        B = abs(imag(y_series));
        switch obj.EdgeWidthMode
            case "none"
                rv_edge_width(i_edge) = 3;
            case "G"
                rv_edge_width(i_edge) = G;
            case "B"
                rv_edge_width(i_edge) = B;
            case "Y"
                rv_edge_width(i_edge) = Y;
            otherwise
                rv_edge_width(i_edge) = 3;
        end
    end


    if isempty(obj.ax)||~isgraphics(obj.ax)
        obj.ax = axes('Parent', figure("Position", [100, 100, 800, 600]));
    end

    ax = obj.ax;
    cla(ax,"reset");
    hold(ax, 'on');

    % Bus Node Plot
    h_node  = gobjects(n_node, 1);
    h_label = gobjects(n_node, 1);
    sct_nodelim(n_node) = struct('min',[],'max',[]);
    node_data = struct("Type","Bus","Index",0);
    for i_node = 1:n_node
        marker = obj.tab_bus.graph.Marker(i_node);
        node_data.Index = i_node;
        [h_node(i_node),sct_nodelim(i_node)] = plot_node(ax, [x_main(i_node), y_main(i_node), z_main(i_node)], marker, node_radius, [1,1,1]*0.05, node_data);
        h_label(i_node) = text(ax, ...
            x_main(i_node) + node_radius*1.5, y_main(i_node) + node_radius*2, z_main(i_node) + node_radius*1.5, ...
            "", ...
            'FontSize',   obj.NodeFontSize, ...
            'FontWeight', obj.NodeFontWeight, ...
            'Color',      [0.85 0.65 0.13], ... % 黄土色
            'BackgroundColor', label_bg, ...
            'EdgeColor',  label_edge, ...
            'Margin',     label_margin);
    end

    % Branch Edge plot
    tab_branchgraph = obj.tab_branch.graph;
    edge_data = struct("Type","Branch","Index",0);
    for i_edge = 1:n_edge
        idx = obj.im_edge(:, i_edge);
        edge_radius = edge_base_radius * (obj.EdgeWidthOffset + obj.EdgeWidthSclae * rv_edge_width(i_edge));
        
        edge_para   = tab_branchgraph(i_edge,:);
        node_in1    = min( max( edge_para.BusFromPoint, 0),1);
        node_in2    = min( max( edge_para.BusToPoint,   0),1);
        from_max    = sct_nodelim(idx(1)).max;
        from_min    = sct_nodelim(idx(1)).min;
        to_max      = sct_nodelim(idx(2)).max;
        to_min      = sct_nodelim(idx(2)).min;
        p1 = from_min * (1-node_in1) + from_max * node_in1;
        p2 =   to_min * (1-node_in2) +   to_max * node_in2;
        edge_marker = edge_para.Marker;
        edge_MidX   = str2mat(edge_para.MidXaxis); 
        edge_MidY   = str2mat(edge_para.MidYaxis); 

        edge_data.Index = i_edge;
        [h_edge(i_edge), h_arrow(i_edge)] = plot_edge(ax, p1, p2, edge_radius, [0.20 0.20 0.20], edge_data, edge_marker, edge_MidX, edge_MidY);        
    end

    comp_handles = gobjects(0, 1);
    comp_labels  = gobjects(0, 1);
    comp_edges   = gobjects(0, 1);
    comp_arrows  = gobjects(0, 1);
    comp_parent  = zeros(0, 1);
    comp_xyz     = zeros(0, 3);

    node_data = struct("Type","Component","Index",0);
    for i_comp = 1:obj.n_component
        node_data.Index = i_comp;

        tab_compi   = obj.tab_component(i_comp, :);
        comp_marker = tab_compi.graph.Marker;
        i_compbus   = tab_compi.bus;
        comp_pos    = [tab_compi.graph.Xaxis, tab_compi.graph.Yaxis, z_main(i_compbus)];
        comp_xyz(end+1, :)   = comp_pos;
        comp_handles(i_comp) = plot_node(ax, comp_pos, comp_marker, node_radius*0.75, [0.15 0.15 0.15], node_data);

        node_in   = tab_compi.graph.BusPoint;
        p_bus     = sct_nodelim(i_compbus).min * (1-node_in) + sct_nodelim(i_compbus).max * node_in;
        edge_MidX = str2mat(tab_compi.graph.MidXaxis);
        edge_MidY = str2mat(tab_compi.graph.MidYaxis);
        comp_edge_radius = edge_base_radius * 3;

        [comp_edges(i_comp), comp_arrows(i_comp)] = plot_edge(ax, comp_pos, p_bus, comp_edge_radius, [0.20 0.20 0.20], node_data, "-", edge_MidX, edge_MidY);
        
        comp_labels(i_comp)  = text(ax, ...
            comp_pos(1) + node_radius*1.5, comp_pos(2) + node_radius*2, comp_pos(3) + node_radius*1.5, ...
            "", ...
            'FontSize', obj.NodeFontSize, ...
            'FontWeight', 'bold', ...
            'Color', [0 0 1], ... % 青
            'BackgroundColor', label_bg, ...
            'EdgeColor', label_edge, ...
            'Margin', label_margin);
        comp_parent(i_comp, 1) = tab_compi.bus;
    end

    obj.plt = struct(         ...
        'EdgeMain', h_edge,   ...
        'EdgeArrow', h_arrow, ...
        'NodeMain', h_node,   ...
        'NodeLabel', h_label, ...
        'CompMain', comp_handles, ...
        'CompEdge', comp_edges, ...
        'CompArrow', comp_arrows, ...
        'CompLabel', comp_labels,  ...
        'CompParentBus', comp_parent, ...
        'XMain', x_main(:),   ...
        'YMain', y_main(:),   ...
        'ZMain', z_main(:),   ...
        'NodeRadius', node_radius);

    % Ensure colors are applied even when topology is rebuilt directly.
    obj.reflect_color_mode();
    obj.reflect_node_label();

    fit_axes_to_content(ax, x_main, y_main, z_main, comp_xyz, node_radius);
    
    clim(    ax, obj.ColorLim);
    colormap(ax, obj.ColorMap);
    c = colorbar(ax, "westoutside");
    c.Position(3) = 0.005;
    ax.XColor  = "none";
    ax.YColor  = "none";
    ax.ZColor  = "none";
    grid(    ax, 'on');
    obj.GridWidth = obj.GridWidth;
    zticks(0)
    arrayfun(@(x) plot(x*[1,1],[0,0.005],'k-',"LineWidth",1), 0:0.1:1)
    arrayfun(@(y) plot([0,0.005],y*[1,1],'k-',"LineWidth",1), 0:0.1:1)
    arrayfun(@(x) plot(x*[1,1],[0.995,1],'k-',"LineWidth",1), 0:0.1:1)
    arrayfun(@(y) plot([0.995,1],y*[1,1],'k-',"LineWidth",1), 0:0.1:1)
    axis(    ax, 'vis3d');
    pbaspect(ax, 'auto');
    daspect( ax, [1 1 1]);
    view(    ax,  0, 90);
    light(   ax, 'Position', [ 1.0,  0.0, 1.0], 'Style', 'infinite', 'Color', [0.35 0.35 0.35]);
    light(   ax, 'Position', [-1.0,  0.0, 1.0], 'Style', 'infinite', 'Color', [0.35 0.35 0.35]);
    light(   ax, 'Position', [ 0.0,  1.0, 1.0], 'Style', 'infinite', 'Color', [0.35 0.35 0.35]);
    light(   ax, 'Position', [ 0.0, -1.0, 1.0], 'Style', 'infinite', 'Color', [0.35 0.35 0.35]);
    light(   ax, 'Position', [ 0.0,  0.0, 1.0], 'Style', 'infinite', 'Color', [0.20 0.20 0.20]);
    lighting(ax, 'gouraud');
    material(ax, 'shiny');
    hold(    ax, 'off');
    ax.Projection = 'perspective';

    fig = ancestor(ax, 'figure');
    dcm = datacursormode(fig);
    set(dcm, 'Enable', 'on', 'UpdateFcn', @(src, event) customhover(src, event, ax, obj));
end

function [xrange,yrange] = fit_axes_to_content(ax, x_main, y_main, z_main, comp_xyz, node_radius)
    pts = [x_main(:), y_main(:), z_main(:)];
    if ~isempty(comp_xyz)
        pts = [pts; comp_xyz];
    end
    pts = pts(all(isfinite(pts), 2), :);
    if isempty(pts)
        axis(ax, 'tight');
        return
    end

    minv = min(pts, [], 1);
    maxv = max(pts, [], 1);
    span = maxv - minv;

    xy_ref = max(span(1:2));
    if ~isfinite(xy_ref) || xy_ref < eps
        xy_ref = max(node_radius * 10, 1);
    end

    span(span < eps) = xy_ref * 0.02;
    pad = 0.05;
    offset = 0.05;

    xrange = [min(0,(minv(1) - pad * span(1) -offset)), max(1,(maxv(1) + pad * span(1) +offset))];
    yrange = [min(0,(minv(2) - pad * span(2) -offset)), max(1,(maxv(2) + pad * span(2) +offset))];
    xlim(ax, xrange);
    ylim(ax, yrange);

    z_half = max(xy_ref * 0.02, node_radius * 2);
    if span(3) < xy_ref * 0.02
        zc = (minv(3) + maxv(3)) / 2;
        % z_half = max(xy_ref * 0.02, node_radius * 2);
        zlim(ax, [zc - z_half, zc + z_half]);
    else
        zlim(ax, [minv(3)-z_half, maxv(3)+z_half]);
    end
end


function rv_order = get_node_height(obj, mode)
    if nargin < 2 || isempty(mode)
        mode = obj.NodeHeightMode;
    end

    if mode == "none"
        rv_order = zeros(obj.n_bus, 1);
    else
        cv_Vst = obj.cv_Vbus;
        cv_Ist = obj.cv_Ibus;
        switch mode
            case "Vmag"
                rv_order = abs(cv_Vst);
            case "Varg"
                rv_order = angle(cv_Vst);
            case "Vsin"
                rv_order = imag(cv_Vst);
            case "P"
                rv_order = real(cv_Vst .* conj(cv_Ist));
            case "Q"
                rv_order = imag(cv_Vst .* conj(cv_Ist));
        end
    end

    rv_order = real(rv_order(:));
end


function out = str2mat(in)
    if isempty(in)
        out = [];
    else
        out = str2num(in); %#ok
        if isnan(out)
            out = [];
        end
    end
end


function txt = customhover(~, event_obj, ax, drawer)
    hObj = event_obj.Target;
    txt  = 'No Data...'; 
    if (hObj.Parent == ax || hObj.Parent.Parent==ax) && isprop(hObj, 'UserData')
        sct_ud = hObj.UserData;
        if isstruct(sct_ud) && all(isfield(sct_ud,["Type","Index"]))
            i = sct_ud.Index;
            switch sct_ud.Type
                case "Bus"
                    txt = drawer.hover_bus(i);
                case "Branch"
                    txt = drawer.hover_branch(i);
                case "Component"
                    txt = drawer.hover_component(i);
            end
        end
    end
end