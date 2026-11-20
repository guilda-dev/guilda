function sct_map = style_properties(obj) %#ok<MANU>
% Options of set_style for each kind of element and the vector property each one writes.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_map (1,1) struct  % Kind -> option -> property name.
    end
    sct_sep = struct("Color", "SeparatorColor", "LineWidth", "SeparatorLineWidth");
    sct_map = struct("rowgroup", sct_sep, "colgroup", sct_sep);
end
