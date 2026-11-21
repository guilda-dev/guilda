function update_heights(obj)
% Move the 2D symbols to the heights of the buses at the sample shown (no new graphics objects).
%
% The buses, components, links and labels take the height of their bus, the branches and
% the transformer circles the height along their paths (diagram_geometry). The paths in
% sct_plt (EdgePath, CompPath, ZMain) follow. The 3D drawing is drawn again instead.
    arguments (Input)
        obj
    end
    sct_g = obj.diagram_geometry();
    plt   = obj.sct_plt;
    rv_z  = sct_g.rm_bus(:, 3);
    rv_zc = sct_g.rm_comp(:, 3);
    set_z(plt.NodeMain, num2cell(rv_z));
    set_z(plt.CompMain, num2cell(rv_zc));
    set_z(plt.EdgeMain, cellfun(@(p) p(:, 3), sct_g.c_branch, "UniformOutput", false));
    set_z(plt.CompEdge, cellfun(@(p) p(:, 3), sct_g.c_link, "UniformOutput", false));
    for k = find(isgraphics(plt.EdgeSymbol))'
        p = sct_g.c_branch{k};
        rv_zs = p(1, 3) + plt.SymbolFrac{k}*(p(end, 3) - p(1, 3));
        plt.EdgeSymbol(k).ZData = reshape(rv_zs, 1, []);
    end
    move_label(plt.NodeLabel, rv_z);
    move_label(plt.CompLabel, rv_zc);
    obj.sct_plt.ZMain    = rv_z;
    obj.sct_plt.NodeLabelXYZ(:, 3) = rv_z;     % places of the labels (fit_axes, make_component_labels)
    obj.sct_plt.CompLabelXYZ(:, 3) = rv_zc;
    obj.sct_plt.EdgePath = sct_g.c_branch;
    obj.sct_plt.CompPath = sct_g.c_link;
end


function set_z(hv, c_z)
% Set the ZData of each line to its heights (a scalar is used for every point).
    arguments (Input)
        hv              % Lines, one per element.
        c_z (:,1) cell  % Heights of each element.
    end
    for i = 1:numel(hv)
        h = hv(i);
        if isgraphics(h)
            h.ZData = reshape(c_z{i}, 1, []) + zeros(1, numel(h.XData));
        end
    end
end


function move_label(hv, rv_z)
% Put each label at the height of its element.
    arguments (Input)
        hv                 % Labels, one per element.
        rv_z (:,1) double  % Heights.
    end
    for i = 1:numel(hv)
        if isgraphics(hv(i))
            hv(i).Position(3) = rv_z(i);
        end
    end
end
