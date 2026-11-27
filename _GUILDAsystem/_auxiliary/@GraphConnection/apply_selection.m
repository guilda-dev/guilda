function apply_selection(obj)
% Draw the selection overlay: a thick frame around each selected block and a wide band along each selected arrow.
%
% The overlay takes no clicks and keeps the appearance of the elements.
    arguments (Input)
        obj
    end
    plt = obj.sct_plt;
    delete(plt.Selection(isgraphics(plt.Selection)));
    d    = obj.sct_data;
    ax   = obj.ax(1);
    rv_c = obj.SelectionColor;
    hv = gobjects(0, 1);
    for i = find(ismember(d.sv_blockTag, obj.Selection))'
        rv_xy = d.rm_blockXY(i, :);
        rv_h  = 0.5 * d.rm_blockSize(i, :) + 0.12;
        hv(end+1, 1) = patch(ax, rv_xy(1) + rv_h(1) * [-1 1 1 -1], rv_xy(2) + rv_h(2) * [-1 -1 1 1], rv_c, ...
            "FaceColor", "none", "EdgeColor", rv_c, "LineWidth", 3, "PickableParts", "none", "HitTest", "off", ...
            "HandleVisibility", "off", "Tag", "Selection"); %#ok<AGROW>
    end
    for i = find(ismember(d.sv_arrowTag, obj.Selection))'
        rm_p = d.c_arrowPath{i};
        hv(end+1, 1) = line(ax, rm_p(:, 1), rm_p(:, 2), "Color", [rv_c 0.5], "LineWidth", obj.ArrowLineWidth(i) + 5, ...
            "PickableParts", "none", "HitTest", "off", "HandleVisibility", "off", "Tag", "Selection"); %#ok<AGROW>
    end
    obj.sct_plt.Selection = hv;
end
