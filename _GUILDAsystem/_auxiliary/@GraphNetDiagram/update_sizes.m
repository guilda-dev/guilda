function iv_row = update_sizes(obj)
% Map the size quantities of the sample shown onto the ranges and return the rows that changed.
%
% The sizes of the buses and components (MarkerSizeRange) and the widths of the branches
% (BranchWidthRange) of the sample i_time, on the scales of all samples (update_scale),
% are stored in sct_plt (BusSize0, CompSize0, BranchWidth0). A finite row of
% BusMarkerSize, ComponentMarkerSize or BranchLineWidth takes their place when drawn
% (apply_style). The rows of tab_element whose value changed are returned; apply_style
% draws them.
    arguments (Input)
        obj
    end
    arguments (Output)
        iv_row (:,1) double  % Rows of tab_element with a new size or width.
    end
    sct_v = obj.size_values(obj.i_time);
    rv_b  = obj.range_map(sct_v.Bus,    obj.MarkerSizeRange,  obj.sct_scale.Bus);
    rv_c  = obj.range_map(sct_v.Comp,   obj.MarkerSizeRange,  obj.sct_scale.Comp);
    rv_e  = obj.range_map(sct_v.Branch, obj.BranchWidthRange, obj.sct_scale.Branch);
    plt   = obj.sct_plt;
    lv_b  = ~(plt.BusSize0 == rv_b);
    lv_c  = ~(plt.CompSize0 == rv_c);
    lv_e  = ~(plt.BranchWidth0 == rv_e);
    obj.sct_plt.BusSize0     = rv_b;
    obj.sct_plt.CompSize0    = rv_c;
    obj.sct_plt.BranchWidth0 = rv_e;
    n_b = obj.n_bus;
    n_c = obj.n_component;
    iv_row = [find(lv_b); n_b + find(lv_c); n_b + n_c + find(lv_e)];
end
