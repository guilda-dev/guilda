function sct_map = style_properties(obj) %#ok<MANU>
% Options of set_style for each kind of element and the vector property each one writes.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_map (1,1) struct  % Kind -> option -> property name.
    end
    sct_block = struct("Color", "BlockColor", "Label", "BlockLabel", "LineWidth", "BlockLineWidth");
    sct_arrow = struct("Color", "ArrowColor", "Label", "ArrowLabel", "LineWidth", "ArrowLineWidth", "LineStyle", "ArrowLineStyle");
    sct_map = struct("bus", sct_block, "component", sct_block, "localcontroller", sct_block, ...
        "globalcontroller", sct_block, "local", sct_arrow, "global", sct_arrow, "observe", sct_arrow, ...
        "equilibrium", sct_arrow);
end
