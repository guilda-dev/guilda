function create_scene(obj)
% Draw the axes of the matrix: the image, the dots of the pattern, the separators, the ticks, the colorbar and the data tips.
%
% The image and the dots are made empty here and filled by update_scene for the sample
% and the Display shown. The rows go down (row 1 at the top). Each element has one line
% object with a segment before each of its blocks. The tick labels are chosen again when
% the figure is resized (a listener kept in sct_plt). The data tips of the figure show the
% names and the value; an UpdateFcn set before by another graph of the figure still
% serves its own objects; drawing again (set_data) does not wrap it twice, and the
% functions of deleted graphs are dropped.
    arguments (Input)
        obj
    end
    d     = obj.sct_data;
    ax    = obj.ax(1);
    n_row = numel(d.sv_rowName);
    n_col = numel(d.sv_colName);
    n_elem = numel(d.sv_tag);
    if ~isempty(obj.sct_pltPrevious) && isfield(obj.sct_pltPrevious, "Listener")
        delete(obj.sct_pltPrevious.Listener);
    end
    cla(ax);
    hold(ax, "on");
    plt = struct("Image", gobjects(1), "Pattern", gobjects(1), "Separator", gobjects(n_elem, 1), ...
        "Colorbar", gobjects(1), "Selection", gobjects(0, 1), "Listener", event.listener.empty, ...
        "Frame", gobjects(0, 1), "Text", gobjects(0, 1), "Zero", gobjects(1), "HitArea", gobjects(1), "Grid", gobjects(1));
    % A transparent image over every cell takes the clicks and data tips of the empty cells
    plt.HitArea = image(ax, "XData", [1 max(n_col, 1)], "YData", [1 max(n_row, 1)], "CData", ones(max(n_row, 1), max(n_col, 1)), ...
        "CDataMapping", "direct", "AlphaData", 0, "PickableParts", "all", "Tag", "HitArea");
    plt.Image = image(ax, "XData", [1 max(n_col, 1)], "YData", [1 max(n_row, 1)], "CData", NaN, ...
        "CDataMapping", "scaled", "AlphaData", 0, "Visible", "off");
    r_size = max(4, min(15, 1500 / max([n_row, n_col, 1])));     % dots shrink with the size of the matrix
    plt.Pattern = line(ax, NaN, NaN, "LineStyle", "none", "Marker", ".", "MarkerSize", r_size, ...
        "Color", [0 0.25 0.6], "Visible", "off");
    plt.Zero = line(ax, NaN, NaN, "LineStyle", "none", "Marker", "o", "Visible", "off", "Tag", "Zero");
    if d.s_pattern == "circle"     % nonzero: red filled circles; zero: hollow circles
        r_size = max(3, min(10, 600 / max([n_row, n_col, 1])));
        set(plt.Pattern, "Marker", "o", "MarkerSize", r_size, "Color", [0.75 0 0], "MarkerFaceColor", [0.85 0.1 0.1]);
        set(plt.Zero, "MarkerSize", r_size, "Color", [0.6 0.6 0.6], "MarkerFaceColor", "w");
    end
    if d.l_cellGrid                % a line around every cell
        rv_x = [reshape([repmat([0.5; n_col + 0.5], 1, n_row + 1); NaN(1, n_row + 1)], 1, []), ...
                reshape([(0.5:1:n_col + 0.5); (0.5:1:n_col + 0.5); NaN(1, n_col + 1)], 1, [])];
        rv_y = [reshape([(0.5:1:n_row + 0.5); (0.5:1:n_row + 0.5); NaN(1, n_row + 1)], 1, []), ...
                reshape([repmat([0.5; n_row + 0.5], 1, n_col + 1); NaN(1, n_col + 1)], 1, [])];
        plt.Grid = line(ax, rv_x, rv_y, "Color", [0.8 0.8 0.8], "LineWidth", 0.5, "HitTest", "off", ...
            "PickableParts", "none", "Tag", "CellGrid");
    end

    % Separators: a segment before each block of a group (the first one on the edge of the axes)
    for i = 1:n_elem
        rm_block = d.c_block{i};
        rv_at = rm_block(:, 1)' - 0.5;
        rv_a  = reshape([rv_at; rv_at; nan(size(rv_at))], 1, []);
        if d.sv_kind(i) == "rowgroup"
            rv_b = reshape(repmat([0.5; n_col + 0.5; NaN], 1, numel(rv_at)), 1, []);
            plt.Separator(i) = line(ax, rv_b, rv_a);
        else
            rv_b = reshape(repmat([0.5; n_row + 0.5; NaN], 1, numel(rv_at)), 1, []);
            plt.Separator(i) = line(ax, rv_a, rv_b);
        end
    end

    % Frames (l_frame): a box around each block of a group that is both a row and a column group
    if d.l_frame
        iv_row = find(d.sv_kind == "rowgroup");
        iv_col = find(d.sv_kind == "colgroup");
        for i = iv_row'
            j = iv_col(d.sv_tag(iv_col) == d.sv_tag(i));
            if isempty(j)
                continue
            end
            for rv_r = d.c_block{i}'
                for rv_c = d.c_block{j}'
                    rv_x = [rv_c(1) - 0.5, rv_c(2) + 0.5];
                    rv_y = [rv_r(1) - 0.5, rv_r(2) + 0.5];
                    plt.Frame(end+1, 1) = line(ax, rv_x([1 2 2 1 1]), rv_y([1 1 2 2 1]), "Color", [0.15 0.15 0.15], ...
                        "LineWidth", 1.2, "HitTest", "off", "PickableParts", "none", "Tag", "Frame");
                end
            end
        end
    end

    % Clicks on the matrix (a dot, the image or the background): the group of the row clicked
    wr = matlab.lang.WeakReference(obj);
    set([plt.HitArea, plt.Image, plt.Pattern, plt.Zero, ax], "ButtonDownFcn", @(~, ~) click_matrix(wr));

    % Axes, labels, ticks and colorbar
    set(ax, "YDir", "reverse", "XLim", [0.5, max(n_col, 1) + 0.5], "YLim", [0.5, max(n_row, 1) + 0.5], ...
        "TickLabelInterpreter", "none", "TickLength", [0 0], "Box", "on", "Layer", "top", ...
        "XTickLabelRotation", 90, "XGrid", "off", "YGrid", "off");
    if n_row > 0 && n_col > 0
        r_ratio = min(max(n_col / n_row, 1/3), 3);
        ax.PlotBoxAspectRatio = [r_ratio 1 1];
    end
    xlabel(ax, d.s_colLabel, "Interpreter", "none");
    ylabel(ax, d.s_rowLabel, "Interpreter", "none");
    hold(ax, "off");
    plt.Colorbar = colorbar(ax);
    if d.l_groupTicks              % one label per group, at the middle of each of its blocks
        set_group_ticks(ax, d);
    else
        set_ticks(ax, d.sv_rowName, d.sv_colName);
    end
    fig = ancestor(ax, "figure");
    try                                 % the tick labels follow the size of the axes
        if ~d.l_groupTicks
            plt.Listener = listener(fig, "SizeChanged", @(~, ~) set_ticks(ax, d.sv_rowName, d.sv_colName));
        end
    catch
    end

    % Data tips: names and value; separators are clicks on their group
    dcm = datacursormode(fig);
    fcn_prev = dcm.UpdateFcn;
    while isa(fcn_prev, "function_handle") && contains(func2str(fcn_prev), "hover_text(")
        sct_ws = functions(fcn_prev).workspace{1};
        G_prev = sct_ws.wr.Handle;
        if ~(isempty(G_prev) || ~isvalid(G_prev) || G_prev == obj)
            break
        end
        fcn_prev = sct_ws.fcn_prev;          % drop this graph drawn before (set_data) and deleted graphs
    end
    set(dcm, "Enable", "on", "UpdateFcn", @(src, event) hover_text(src, event, wr, fcn_prev));

    obj.sct_plt = plt;
    obj.apply_style((1:n_elem)');
end


function click_matrix(wr)
% Click on the matrix of the graph held by wr: the cell under CurrentPoint of the axes (click_cell).
    arguments (Input)
        wr  % Weak reference to the graph. <@Type> matlab.lang.WeakReference
    end
    G = wr.Handle;
    if isempty(G) || ~isvalid(G) || isempty(G.sct_plt)
        return
    end
    G.click_cell(G.ax(1).CurrentPoint(1, 1:2));
end


function set_group_ticks(ax, d)
% Tick labels of the groups: one at the middle of each block of a group of rows or columns.
    arguments (Input)
        ax          % Axes of the matrix.
        d struct    % Data of the graph (sv_tag, sv_kind, c_block).
    end
    rv_row = zeros(1, 0);  sv_row = strings(1, 0);
    rv_col = zeros(1, 0);  sv_col = strings(1, 0);
    for i = 1:numel(d.sv_tag)
        rv_mid = mean(d.c_block{i}, 2)';
        if d.sv_kind(i) == "rowgroup"
            rv_row = [rv_row, rv_mid];                                  %#ok<AGROW>
            sv_row = [sv_row, repmat(d.sv_tag(i), 1, numel(rv_mid))];   %#ok<AGROW>
        else
            rv_col = [rv_col, rv_mid];                                  %#ok<AGROW>
            sv_col = [sv_col, repmat(d.sv_tag(i), 1, numel(rv_mid))];   %#ok<AGROW>
        end
    end
    [rv_row, iv] = sort(rv_row);
    sv_row = sv_row(iv);
    [rv_col, iv] = sort(rv_col);
    sv_col = sv_col(iv);
    set(ax, "YTick", rv_row, "YTickLabel", sv_row, "XTick", rv_col, "XTickLabel", sv_col);
end


function set_ticks(ax, sv_rowName, sv_colName)
% Tick labels of the names, every k-th one when all of them would overlap in the axes.
    arguments (Input)
        ax                    % Axes of the matrix.
        sv_rowName (:,1) string  % Names of the rows.
        sv_colName (:,1) string  % Names of the columns.
    end
    if ~isgraphics(ax)
        return
    end
    try
        rv_px = getpixelposition(ax);
    catch
        rv_px = [0 0 400 400];
    end
    r_need = 1.4 * ax.FontSize;                        % [px] room of one label across its text
    n_row = numel(sv_rowName);
    n_col = numel(sv_colName);
    k_row = max(1, ceil(r_need * n_row / max(rv_px(4), 1)));
    k_col = max(1, ceil(r_need * n_col / max(rv_px(3), 1)));
    iv_row = 1:k_row:n_row;
    iv_col = 1:k_col:n_col;
    set(ax, "YTick", iv_row, "YTickLabel", sv_rowName(iv_row), "XTick", iv_col, "XTickLabel", sv_colName(iv_col));
end


function txt = hover_text(src, event_obj, wr, fcn_prev)
% Data tip text: the names, groups and value of an entry, or the group of a separator (also a click on it).
    arguments (Input)
        src        % Data cursor of the figure.
        event_obj  % Event data of the data tip (Target, Position).
        wr         % Weak reference to the graph. <@Type> matlab.lang.WeakReference
        fcn_prev   % UpdateFcn set before by another graph of the figure; [] for none.
    end
    arguments (Output)
        txt  % Data tip text.
    end
    G    = wr.Handle;
    hObj = event_obj.Target;
    rv_p = event_obj.Position;
    if ~isempty(G) && isvalid(G) && ~isempty(G.sct_plt) && isgraphics(hObj)
        plt = G.sct_plt;
        d   = G.sct_data;
        if any(hObj == [plt.Image, plt.Pattern, plt.Zero, plt.HitArea])
            i = min(max(round(rv_p(2)), 1), numel(d.sv_rowName));
            j = min(max(round(rv_p(1)), 1), numel(d.sv_colName));
            v = full(d.c_matrix{G.i_time}(i, j));
            txt = {char("Row: " + d.sv_rowName(i) + " (" + d.sv_rowGroup(i) + ")"), ...
                   char("Column: " + d.sv_colName(j) + " (" + d.sv_colGroup(j) + ")"), ...
                   sprintf('Value: %.6g', v)};
            G.click_cell([j i]);       % a data tip is the click of the data cursor mode
            return
        end
        i_row = find(plt.Separator == hObj, 1);
        if ~isempty(i_row)
            sv_kind = ["Row group: ", "Column group: "];
            txt = char(sv_kind(1 + (d.sv_kind(i_row) == "colgroup")) + d.sv_tag(i_row));
            G.click_element(i_row);    % a data tip is the click of the data cursor mode
            return
        end
    end
    if ~isempty(fcn_prev)
        txt = fcn_prev(src, event_obj);
    else
        txt = {sprintf('X: %.4g', rv_p(1)), sprintf('Y: %.4g', rv_p(2))};
    end
end
