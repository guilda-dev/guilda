function apply_style(obj, iv_element)
% Draw the colors, labels, sizes and widths of elements again.
%
% The color of an element is its fixed color (BusColor, ...) when that row is not NaN;
% otherwise the color of its color data (BusColorData, ...) on the colormap (NaN: gray);
% otherwise, when there is no color data for it, the color it was drawn with. A component
% whose color value is NaN (no value: "Loss", a tripped unit, a NaN row of "user") is
% black while a colormap is in use (ColorMode is not "none" and an element has a finite
% color value), else its class color; when that changes, every component is drawn again.
% The size of
% a bus or a component and the width of a branch is its finite row of BusMarkerSize,
% ComponentMarkerSize or BranchLineWidth [pt], else the value of its quantity in the
% range (update_sizes). In 2D a marker takes the size as MarkerSize and a bar half of it
% as LineWidth; a branch and its transformer circles take the width as LineWidth. In 3D
% the solids drawn are scaled (no new graphics objects). The colorbar is shown only while
% an element has a finite color value; its label is ColorbarLabel, or with "" the quantity
% of ColorMode ("|I| [pu]", "P [pu]", "Q [pu]", "Loss [pu]"; none for "user"; color_readout). The color
% limits in use (color_limits) are set to the axes first; when they changed (automatic
% limits follow the data and ColorMode), every element is drawn again. The flow dots (2D)
% take the new colors of the branches and links (step_flow).
    arguments (Input)
        obj
        iv_element (:,1) double  % Rows of tab_element.
    end
    tab = obj.element_table();
    plt = obj.sct_plt;
    ax  = obj.ax(1);
    rv_lim = obj.color_limits();
    if ~isequal(ax.CLim, rv_lim)           % new limits (automatic ones follow the data): every element
        clim(ax, rv_lim);
        iv_element = (1:height(tab))';
    end
    % Colormap in use: components without a value are black, else they keep their class colors
    l_map = obj.ColorMode ~= "none" && any(isfinite([obj.BusColorData; obj.ComponentColorData; obj.BranchColorData; obj.LinkColorData]));
    if ~isfield(plt, "CompColormap") || plt.CompColormap ~= l_map
        iv_element = union(iv_element, find(tab.Kind == "component"));
        obj.sct_plt.CompColormap = l_map;
    end
    l_2d = obj.Dimension == "2D";
    sv_kind = tab.Kind(iv_element);
    iv_idx  = tab.Index(iv_element);

    % Buses
    iv = iv_idx(sv_kind == "bus");
    if ~isempty(iv)
        rm_c = pick_colors(obj, obj.BusColor, obj.BusColorData, iv, plt.BusColor0);
        rv_s = pick_sizes(obj.BusMarkerSize, plt.BusSize0, iv);
        set_labels(plt.NodeLabel, obj.BusLabel, iv);
        if l_2d
            lv_bar = plt.NodeBar(iv);
            hv = plt.NodeMain(iv);
            set(hv(lv_bar), {"Color"}, num2cell(rm_c(lv_bar, :), 2), {"LineWidth"}, num2cell(rv_s(lv_bar)/2));
            set(hv(~lv_bar), {"Color"}, num2cell(rm_c(~lv_bar, :), 2), {"MarkerFaceColor"}, num2cell(rm_c(~lv_bar, :), 2), ...
                {"MarkerSize"}, num2cell(rv_s(~lv_bar)));
        else
            for j = 1:numel(iv)
                i = iv(j);
                set_graphics_color(plt.NodeMain(i), rm_c(j, :));
                r_scale = rv_s(j)/plt.BusRef;
                if r_scale ~= obj.sct_plt.BusScale(i)
                    scale_solid(plt.BusGeom{i}, r_scale);
                    obj.sct_plt.BusScale(i) = r_scale;
                end
            end
        end
    end

    % Components
    iv = iv_idx(sv_kind == "component");
    if ~isempty(iv)
        rm_nan = plt.CompColor0;
        if l_map
            rm_nan = zeros(size(rm_nan));
        end
        rm_c = pick_colors(obj, obj.ComponentColor, obj.ComponentColorData, iv, plt.CompColor0, rm_nan);
        rv_s = pick_sizes(obj.ComponentMarkerSize, plt.CompSize0, iv);
        set_labels(plt.CompLabel, obj.ComponentLabel, iv);
        if l_2d
            set(plt.CompMain(iv), {"Color"}, num2cell(0.6*rm_c, 2), {"MarkerFaceColor"}, num2cell(rm_c, 2), ...
                {"MarkerSize"}, num2cell(rv_s));
        else
            for j = 1:numel(iv)
                i = iv(j);
                set_graphics_color(plt.CompMain(i), rm_c(j, :));
                r_scale = rv_s(j)/plt.BusRef;
                if r_scale ~= obj.sct_plt.CompScale(i)
                    scale_solid(plt.CompGeom{i}, r_scale);
                    obj.sct_plt.CompScale(i) = r_scale;
                end
            end
        end
    end

    % Branches
    iv = iv_idx(sv_kind == "branch");
    if ~isempty(iv)
        rm_c = pick_colors(obj, obj.BranchColor, obj.BranchColorData, iv, repmat([0.2 0.2 0.2], obj.n_branch, 1));
        rv_w = pick_sizes(obj.BranchLineWidth, plt.BranchWidth0, iv);
        if l_2d
            c_c = num2cell(rm_c, 2);
            c_w = num2cell(rv_w);
            set(plt.EdgeMain(iv), {"Color"}, c_c, {"LineWidth"}, c_w);
            lv_sym = isgraphics(plt.EdgeSymbol(iv));
            set(plt.EdgeSymbol(iv(lv_sym)), {"Color"}, c_c(lv_sym), {"LineWidth"}, c_w(lv_sym));
        else
            for j = 1:numel(iv)
                i = iv(j);
                set_graphics_color(plt.EdgeMain(i), rm_c(j, :));
                set_graphics_color(plt.EdgeArrow(i), rm_c(j, :));
                r_scale = rv_w(j)/plt.EdgeRef;
                if r_scale ~= obj.sct_plt.EdgeScale(i)
                    scale_solid(plt.EdgeGeom{i}, r_scale);
                    obj.sct_plt.EdgeScale(i) = r_scale;
                end
            end
        end
    end

    % Links
    iv = iv_idx(sv_kind == "link");
    if ~isempty(iv)
        rm_c = pick_colors(obj, obj.LinkColor, obj.LinkColorData, iv, repmat([0.2 0.2 0.2], obj.n_component, 1));
        if l_2d
            set(plt.CompEdge(iv), {"Color"}, num2cell(rm_c, 2));
        else
            for j = 1:numel(iv)
                set_graphics_color(plt.CompEdge(iv(j)), rm_c(j, :));
                set_graphics_color(plt.CompArrow(iv(j)), rm_c(j, :));
            end
        end
    end

    % Flow dots (2D): the colors of their lines
    if l_2d && any(sv_kind == "branch" | sv_kind == "link")
        obj.step_flow(0);
    end

    % Colorbar: only with a color value; its label is ColorbarLabel, else that of ColorMode
    l_color = any(isfinite([obj.BusColorData; obj.ComponentColorData; obj.BranchColorData; obj.LinkColorData]));
    if l_color && isempty(ax.Colorbar)
        colorbar(ax);
    elseif ~l_color && ~isempty(ax.Colorbar)
        colorbar(ax, "off");
    end
    if l_color
        [~, ~, s_label] = obj.color_readout("bus", zeros(0, 1));
        if string(ax.Colorbar.Label.String) ~= s_label
            ax.Colorbar.Label.String = s_label;
        end
    end
end


function rm_c = pick_colors(obj, rm_fixed, rv_data, iv, rm_default, rm_nan)
% Fixed color, else color of the color value (NaN: rm_nan), else the default color of elements iv.
    arguments (Input)
        obj                      % The diagram.
        rm_fixed (:,3) double    % Fixed colors of the kind (NaN rows: none).
        rv_data (:,1) double     % Color values of the kind.
        iv (:,1) double          % Indices of the elements.
        rm_default (:,3) double  % Colors they were drawn with, one per element of the kind.
        rm_nan (:,3) double = zeros(0, 3)  % Colors of a NaN value, one per element of the kind (empty: gray of color_of_values).
    end
    arguments (Output)
        rm_c (:,3) double  % RGB color of each element of iv.
    end
    rm_c = rm_default(iv, :);
    lv_data = iv <= numel(rv_data);
    if any(lv_data)
        rm_c(lv_data, :) = obj.color_of_values(rv_data(iv(lv_data)));
        if ~isempty(rm_nan)
            lv_nan = lv_data;
            lv_nan(lv_data) = isnan(rv_data(iv(lv_data)));
            rm_c(lv_nan, :) = rm_nan(iv(lv_nan), :);
        end
    end
    lv_fix = iv <= size(rm_fixed, 1);
    lv_fix(lv_fix) = all(isfinite(rm_fixed(iv(lv_fix), :)), 2);
    rm_c(lv_fix, :) = rm_fixed(iv(lv_fix), :);
end


function rv_s = pick_sizes(rv_set, rv_range, iv)
% Size set for each element of iv (finite rows), else its size in the range.
    arguments (Input)
        rv_set (:,1) double    % Sizes set (BusMarkerSize, ...; NaN rows: none).
        rv_range (:,1) double  % Sizes of the range at the sample shown.
        iv (:,1) double        % Indices of the elements.
    end
    arguments (Output)
        rv_s (:,1) double  % Size of each element of iv [pt].
    end
    rv_s = rv_range(iv);
    lv = iv <= numel(rv_set);
    lv(lv) = isfinite(rv_set(iv(lv)));
    rv_s(lv) = rv_set(iv(lv));
end


function set_labels(h_label, sv_label, iv)
% Put the labels of elements iv into their text objects.
    arguments (Input)
        h_label                % Text objects of the kind.
        sv_label (:,1) string  % Labels of the kind.
        iv (:,1) double        % Indices of the elements.
    end
    iv = iv(iv <= numel(h_label) & iv <= numel(sv_label));
    iv = iv(isgraphics(h_label(iv)));
    if ~isempty(iv)
        set(h_label(iv), {"String"}, cellstr(sv_label(iv)));
    end
end


function scale_solid(sct_geom, r_scale)
% Move the points of the drawn solids of an element to the scale r_scale (see geometry_record of draw_graph_network).
    arguments (Input)
        sct_geom (1,:) struct    % Geometry records of the solids.
        r_scale (1,1) double     % Scale.
    end
    for g = sct_geom
        if ~isgraphics(g.h)
            continue
        end
        r_rad = 1;
        if g.l_radial
            r_rad = r_scale;
        end
        r_ax = min(g.rv_len(1), g.rv_len(2)*r_scale) / g.rv_len(3);
        rm_p = g.A + g.Prad*r_rad + g.Pax*r_ax;
        if g.l_surf
            set(g.h, "XData", reshape(rm_p(:, 1), g.sz), "YData", reshape(rm_p(:, 2), g.sz), "ZData", reshape(rm_p(:, 3), g.sz));
        else
            g.h.Vertices = rm_p;
        end
    end
end
