function apply_selection(obj)
% Draw the selection overlay: rings over the selected buses and components and wide lines under the selected branches and links.
%
% The overlay takes no clicks and does not change the colors of the elements. A ring is
% an "o" marker of the size of the element + 8 pt; a wide line follows the drawn path of
% a branch or a link (its ends and bend points), 5 pt wider than it. In 2D the overlay
% lies at the heights of the symbols and is drawn first (under them); a selected bar is a
% segment 0.1*d0 longer at each end and 6 pt wider than the bar. In 3D it lies just
% above the solids.
    arguments (Input)
        obj
    end
    plt = obj.sct_plt;
    if isfield(plt, "Selection")
        delete(plt.Selection(isgraphics(plt.Selection)));
    end
    hv   = gobjects(0, 1);
    tab  = obj.element_table();
    rv_c = obj.SelectionColor;
    l_2d = obj.Dimension == "2D";
    r_up = 1.5 * plt.NodeRadius*(~l_2d);              % 3D: above the solids
    rm_bus  = [plt.XMain(:), plt.YMain(:), plt.ZMain(:) + r_up];
    rm_comp = zeros(0, 3);
    if obj.n_component > 0
        iv_bus  = obj.tab_component.bus;
        rm_comp = [obj.tab_component.graph{:, ["DX","DY"]} + rm_bus(iv_bus, 1:2), rm_bus(iv_bus, 3)];
    end
    c_line = {"PickableParts", "none", "HitTest", "off"};
    for r = find(ismember(tab.Tag, obj.Selection))'
        i = tab.Index(r);
        switch tab.Kind(r)
            case "bus"
                r_s = size_of(obj.BusMarkerSize, plt.BusSize0, i);
                if l_2d && plt.NodeBar(i)
                    h = plt.NodeMain(i);
                    rm_p = [h.XData(:), h.YData(:), h.ZData(:)];
                    rv_d = (rm_p(2, :) - rm_p(1, :))/max(norm(rm_p(2, :) - rm_p(1, :)), eps)*0.1*plt.D0;
                    rm_p = rm_p + [-rv_d; rv_d];
                    c_style = {"LineWidth", r_s/2 + 6};
                else
                    rm_p = rm_bus(i, :);
                    c_style = {"LineStyle", "none", "Marker", "o", "MarkerSize", r_s + 8, "LineWidth", 2};
                end
            case "component"
                r_s = size_of(obj.ComponentMarkerSize, plt.CompSize0, i);
                rm_p = rm_comp(i, :);
                c_style = {"LineStyle", "none", "Marker", "o", "MarkerSize", r_s + 8, "LineWidth", 2};
            case "branch"
                rm_p = plt.EdgePath{i} + [0 0 r_up];
                c_style = {"LineWidth", size_of(obj.BranchLineWidth, plt.BranchWidth0, i) + 5};
            case "link"
                rm_p = plt.CompPath{i} + [0 0 r_up];
                c_style = {"LineWidth", obj.LinkWidth + 5};
        end
        hv(end+1, 1) = line(obj.ax, rm_p(:, 1), rm_p(:, 2), rm_p(:, 3), "Color", rv_c, ...
            "MarkerEdgeColor", rv_c, c_style{:}, c_line{:}); %#ok<AGROW>
    end
    if l_2d && ~isempty(hv)
        uistack(hv, "bottom");                         % drawn first: under the symbols
    end
    obj.sct_plt.Selection = hv;
end


function r_s = size_of(rv_set, rv_range, i)
% Size of element i: its row of rv_set when finite, else its size in the range.
    arguments (Input)
        rv_set (:,1) double    % Sizes set (NaN rows: none).
        rv_range (:,1) double  % Sizes of the range at the sample shown.
        i (1,1) double         % Index of the element.
    end
    arguments (Output)
        r_s (1,1) double  % Size [pt].
    end
    r_s = rv_range(i);
    if i <= numel(rv_set) && isfinite(rv_set(i))
        r_s = rv_set(i);
    end
end
