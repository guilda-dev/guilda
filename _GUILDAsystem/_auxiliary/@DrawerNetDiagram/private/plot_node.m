function [h,s] = plot_node(ax, center_xyz, marker, radius, color, nodedata)
    x0 = center_xyz(1);
    y0 = center_xyz(2);
    z0 = center_xyz(3);

    [shape, scale] = parse_node_marker(marker);

    switch shape
        case "s"
            h = draw_cuboid(ax, x0, y0, z0, radius, color);
            s = get_lim_patch(h);
        case "|"
            h = draw_cuboid_vertical(ax, x0, y0, z0, radius, color, scale);
            s = get_lim_patch(h);
        case "_"
            h = draw_cuboid_horizontal(ax, x0, y0, z0, radius, color, scale);
            s = get_lim_patch(h);
        case "o"
            h = draw_sphere(ax, x0, y0, z0, radius*2, [0.6110 0.4660 0.1250]);
            s = get_lim_surf(h);
        case "^"
            h = draw_cone(ax, x0, y0, z0-radius, radius*2, [0.7170 0.1920 0.1720], pi/2);
            s = get_lim_patch(h);
        case "v"
            h = draw_cone(ax, x0, y0, z0-radius, radius*2, [0.7170 0.1920 0.1720], -pi/2);
            s = get_lim_patch(h);
        case ">"
            h = draw_cone(ax, x0, y0, z0-radius, radius*2, [0.7170 0.1920 0.1720], 0);
            s = get_lim_patch(h);
        case "<"
            h = draw_cone(ax, x0, y0, z0-radius, radius*2, [0.7170 0.1920 0.1720], pi);
            s = get_lim_patch(h);
        otherwise
            h = draw_cuboid(ax, x0, y0, z0, radius, color);
            s = get_lim_patch(h);
    end
    h.UserData = nodedata;
end

function s = get_lim_surf(h)
    s.min = [min(h.XData), min(h.YData), min(h.ZData)];
    s.max = [max(h.XData), max(h.YData), max(h.ZData)];
end
function s = get_lim_patch(h)
    xyz = h.Vertices;
    s.min = min(xyz);
    s.max = max(xyz);
end

function [shape, scale] = parse_node_marker(marker)
    marker = string(marker);
    marker = strtrim(marker);
    scale = 1;

    switch marker
        case {"s", "o", "v", "^", "<", ">"}
            shape = marker;
            return
    end

    if startsWith(marker, "_")
        shape = "_";
        scale = parse_marker_scale(extractAfter(marker, 1), 1);
    elseif startsWith(marker, "|")
        shape = "|";
        scale = parse_marker_scale(extractAfter(marker, 1), 1);
    else
        shape = "o";
    end
end

function scale = parse_marker_scale(text, default_scale)
    text = strtrim(string(text));
    if strlength(text) == 0
        scale = default_scale;
        return
    end

    scale = str2double(text);
    if ~isfinite(scale) || scale <= 0
        scale = default_scale;
    end
end