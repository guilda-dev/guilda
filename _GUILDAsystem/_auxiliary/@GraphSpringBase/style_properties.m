function sct_map = style_properties(obj) %#ok<MANU>
% Options of set_style for each kind of element and the vector property each one writes.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_map (1,1) struct  % Kind -> option -> property name.
    end
    sct_map = struct( ...
        "node",  struct("Color", "NodeColor", "Label", "NodeLabel", "Marker", "NodeMarker", ...
                        "MarkerSize", "NodeSize", "Visible", "NodeVisible"), ...
        "edge",  struct("Color", "EdgeColor", "LineWidth", "EdgeLineWidth", "Visible", "EdgeVisible"), ...
        "arrow", struct());
end
