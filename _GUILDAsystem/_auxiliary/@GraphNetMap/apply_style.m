function apply_style(obj, iv_element)
% Set the node and edge properties of the graph plot from the appearance vectors.
%
% The properties of a graph plot hold one value per node or edge, so a changed bus sets
% the node properties and a changed branch the edge properties, each with one assignment.
% A NaN row of BusColor takes the color of the voltage on the colormap (NodeColor "flat"
% when every row is NaN); a NaN row of BranchColor the edge color of the graph plot, and of
% BranchLineWidth the width of the flow: its size mapped from the smallest to the largest
% flow onto BranchWidthRange (range_map; the middle of the range for no flow). The edges follow the order of the graph plot
% (sct_plt.EdgeBranch).
    arguments (Input)
        obj
        iv_element (:,1) double  % Rows of tab_element.
    end
    tab = obj.element_table();
    h   = obj.sct_plt.Graph;
    sv_kind = tab.Kind(iv_element);
    if any(sv_kind == "bus")
        rm_c = obj.BusColor;
        if all(isnan(rm_c(:)))
            h.NodeColor = "flat";
        else
            % NaN rows: the colormap color of the value (scaled as the axes do)
            cm = colormap(obj.ax);
            rv_lim = clim(obj.ax);
            n_c = size(cm, 1);
            iv_c = min(max(fix((h.NodeCData(:) - rv_lim(1)) / diff(rv_lim) * n_c) + 1, 1), n_c);
            l_nan = any(isnan(rm_c), 2);
            rm_c(l_nan, :) = cm(iv_c(l_nan), :);
            h.NodeColor = rm_c;
        end
        h.NodeLabel  = cellstr(obj.BusLabel);
        h.MarkerSize = obj.BusMarkerSize;
        h.Marker     = cellstr(obj.BusMarker);
    end
    iv_e = obj.sct_plt.EdgeBranch;
    if any(sv_kind == "branch") && ~isempty(iv_e)
        rm_c  = obj.BranchColor(iv_e, :);
        l_nan = any(isnan(rm_c), 2);
        rm_c(l_nan, :) = repmat(obj.sct_plt.EdgeColor0, nnz(l_nan), 1);
        h.EdgeColor = rm_c;
        rv_mag = obj.sct_data.rv_flowMag;
        rv_fin = rv_mag(isfinite(rv_mag));
        rv_lim = [NaN NaN];
        if ~isempty(rv_fin)
            rv_lim = [min(rv_fin), max(rv_fin)];
        end
        rv_flow = obj.range_map(rv_mag, obj.BranchWidthRange, rv_lim);
        rv_w  = obj.BranchLineWidth;
        l_nan = isnan(rv_w);
        rv_w(l_nan) = rv_flow(l_nan);
        obj.sct_plt.BranchWidth = rv_w;            % drawn width of each branch (selection, clicks)
        h.LineWidth = rv_w(iv_e);
        h.LineStyle = cellstr(obj.BranchLineStyle(iv_e));
    end
end
