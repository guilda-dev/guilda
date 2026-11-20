function sct_map = style_properties(obj) %#ok<MANU>
% Options of set_style for each kind of element and the vector property each one writes.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_map (1,1) struct  % Kind -> option -> property name.
    end
    sct_map = struct( ...
        "bus",       struct("Color", "BusColor", "Label", "BusLabel", "MarkerSize", "BusMarkerSize"), ...
        "component", struct("Color", "ComponentColor", "Label", "ComponentLabel", "MarkerSize", "ComponentMarkerSize"), ...
        "branch",    struct("Color", "BranchColor", "LineWidth", "BranchLineWidth"), ...
        "link",      struct("Color", "LinkColor"));
end
