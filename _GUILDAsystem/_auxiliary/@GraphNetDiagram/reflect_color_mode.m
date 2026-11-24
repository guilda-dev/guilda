function reflect_color_mode(obj)
% Color the elements by BusColorMode and ColorMode at the sample shown (color_values).
%
% With BusColorMode "V" or "angle" the buses take the values of that quantity and the
% branches, links and components none (NaN): the bus quantity takes the colorbar. Else
% ColorMode colors the branches, links and components: a component takes the value of
% its link (NaN with "Loss"). "none" clears them (the components keep their class
% colors). "user" applies the color values that are set (BusColorData,
% ComponentColorData, BranchColorData, LinkColorData) again.
    arguments (Input)
        obj
    end
    color_mode = obj.ColorMode;
    n_edge   = obj.n_branch;
    n_comp   = obj.n_component;

    if obj.BusColorMode ~= "none"
        [~, ~, rv_bus] = obj.color_values(obj.i_time);
        obj.BusColorData       = reshape(rv_bus, obj.n_bus, 1);
        obj.BranchColorData    = nan(n_edge, 1);
        obj.LinkColorData      = nan(n_comp, 1);
        obj.ComponentColorData = nan(n_comp, 1);
        return
    end

    if color_mode == "user"
        obj.BusColorData       = obj.BusColorData;
        obj.ComponentColorData = obj.ComponentColorData;
        obj.BranchColorData    = obj.BranchColorData;
        obj.LinkColorData      = obj.LinkColorData;
        return
    end

    if color_mode == "none"
        obj.BranchColorData = nan(n_edge, 1);
        obj.LinkColorData = nan(n_comp, 1);
        obj.ComponentColorData = nan(n_comp, 1);
        return
    end

    [rv_main, rv_comp] = obj.color_values(obj.i_time);
    obj.BranchColorData = reshape(rv_main, n_edge, 1);
    obj.LinkColorData   = reshape(rv_comp, n_comp, 1);
    obj.ComponentColorData = reshape(rv_comp, n_comp, 1);
end
