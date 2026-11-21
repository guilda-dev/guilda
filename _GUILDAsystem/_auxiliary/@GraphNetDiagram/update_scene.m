function update_scene(obj, k)
% Show sample k: compute its values and update the colors, labels, sizes, heights, arrows and flow.
%
% Nothing is drawn again in 2D: the heights (BusHeightMode other than "none") move the
% symbols (update_heights). In 3D the solids are drawn again when the heights follow the
% state. When the state has more than one sample and TitleFormat is not "", the title is
% sprintf(TitleFormat, t) with t the time of the sample, or for samples named by the data
% the text of the sample (GraphBase.sample_text). The flow dots (2D) take the
% speeds and directions of sample k and keep their phases (reflect_arrow_forward,
% update_flow); with heights, their paths follow first (flow_paths).
    arguments (Input)
        obj
        k (1,1) double  % Index of the sample.
    end
    obj.set_powerflow(obj.sct_state.cm_Vbus(:, k), obj.sct_state.cm_Icomp(:, k), obj.sct_state.cm_Ibranch(:, k));
    if obj.BusHeightMode ~= "none" && obj.Dimension == "3D"
        obj.create_scene();
    else
        obj.reflect_color_mode();
        obj.reflect_node_label();
        obj.apply_style(obj.update_sizes());
        if obj.BusHeightMode ~= "none"
            obj.update_heights();
            obj.flow_paths();
        end
        obj.reflect_arrow_forward();
    end
    if numel(obj.rv_t) > 1 && obj.TitleFormat ~= ""
        title(obj.ax, obj.sample_text(k, obj.TitleFormat));
    end
end
