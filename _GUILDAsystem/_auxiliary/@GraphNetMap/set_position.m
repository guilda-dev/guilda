function set_position(obj, sr_tag, rm_xy)
% Move buses in the drawing (never in the model).
%
% The positions live in the map; those of the data, or of the "force" layout, are the
% defaults. The branches follow their buses. Only the node positions of the graph plot
% change: the map is not drawn again.
%
% <@Examples>
% ```matlab
% G = res.plot_network();
% G.set_position(["B001", "B002"], [0 1; 1 1]);
% ```
    arguments (Input)
        obj
        sr_tag (1,:) string                % Bus tags (see tab_element).
        rm_xy (:,2) double {mustBeFinite}  % New positions, one row (x, y) per tag.
    end
    if size(rm_xy, 1) ~= numel(sr_tag)
        error(msg("GUILDA:GraphNetMap:PositionSize", numel(sr_tag), size(rm_xy, 1)));
    end
    tab = obj.element_table();
    sv_bad = sr_tag(~ismember(sr_tag, tab.Tag));
    if ~isempty(sv_bad)
        error(msg("GUILDA:GraphBase:UnknownTag", join(sv_bad, ", "), class(obj)));
    end
    [l_bus, iv_bus] = ismember(sr_tag, obj.sct_data.sv_bus);
    if ~all(l_bus)
        error(msg("GUILDA:GraphNetMap:PositionKind", join(sr_tag(~l_bus), ", ")));
    end
    obj.sct_data.rm_xy(iv_bus, :) = rm_xy;
    if ~isempty(obj.sct_plt) && all(isgraphics(obj.ax)) && isgraphics(obj.sct_plt.Graph)
        set(obj.sct_plt.Graph, "XData", obj.sct_data.rm_xy(:, 1)', "YData", obj.sct_data.rm_xy(:, 2)');
        obj.apply_selection();
    end
end
