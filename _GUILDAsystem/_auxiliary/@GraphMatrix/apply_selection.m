function apply_selection(obj)
% Draw the selection overlay: a translucent band over the rows of each selected group of rows and over the columns of each selected group of columns.
%
% The bands take no clicks and keep the appearance of the separators.
    arguments (Input)
        obj
    end
    plt = obj.sct_plt;
    delete(plt.Selection(isgraphics(plt.Selection)));
    d     = obj.sct_data;
    ax    = obj.ax(1);
    n_row = numel(d.sv_rowName);
    n_col = numel(d.sv_colName);
    rv_c  = obj.SelectionColor;
    hv = gobjects(0, 1);
    for i = find(ismember(d.sv_tag, obj.Selection))'
        rm_block = d.c_block{i};
        n_block  = height(rm_block);
        rv_lo = rm_block(:, 1)' - 0.5;
        rv_hi = rm_block(:, 2)' + 0.5;
        if d.sv_kind(i) == "rowgroup"
            rm_x = repmat([0.5; n_col + 0.5; n_col + 0.5; 0.5], 1, n_block);
            rm_y = [rv_lo; rv_lo; rv_hi; rv_hi];
        else
            rm_x = [rv_lo; rv_hi; rv_hi; rv_lo];
            rm_y = repmat([0.5; 0.5; n_row + 0.5; n_row + 0.5], 1, n_block);
        end
        hv(end+1, 1) = patch(ax, rm_x, rm_y, rv_c, "FaceAlpha", 0.25, "EdgeColor", rv_c, "LineWidth", 1.5, ...
            "PickableParts", "none", "HitTest", "off", "HandleVisibility", "off", "Tag", "Selection"); %#ok<AGROW>
    end
    obj.sct_plt.Selection = hv;
end
