function set_graphics_color(h, color)
arguments (Input)
    h      % Graphics object to color; its children are colored too.
    color  % RGB color (invalid values give black).
end
if ~isgraphics(h)
    return
end

color = double(color(:).');
if numel(color) ~= 3 || any(~isfinite(color))
    color = [0 0 0];
end
color = min(max(color, 0), 1);

if isprop(h, 'Color')
    h.Color = color;
end
if isprop(h, 'FaceColor')
    h.FaceColor = color;
end
if isprop(h, 'EdgeColor')
    edge_val = h.EdgeColor;
    if ischar(edge_val) || isstring(edge_val)
        if ~strcmp(string(edge_val), "none")
            h.EdgeColor = color;
        end
    else
        h.EdgeColor = color;
    end
end
if strcmp(h.Type, 'hggroup')     % the primitives have no children to color
    a_child = allchild(h); % includes HandleVisibility='off' children
    for i = 1:numel(a_child)
        set_graphics_color(a_child(i), color);
    end
end
end
