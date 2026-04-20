function set_graphics_color(h, color)
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
if isprop(h, 'CData')
    cdata = h.CData;
    if ~isempty(cdata)
        sz = size(cdata);
        if numel(sz) >= 3 && sz(3) == 3
            h.CData = repmat(reshape(color, 1, 1, 3), sz(1), sz(2));
        end
    end
end

if isprop(h, 'Children')
    a_child = allchild(h); % includes HandleVisibility='off' children
    for i = 1:numel(a_child)
        set_graphics_color(a_child(i), color);
    end
end
end
