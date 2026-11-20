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
        "Colorbar", gobjects(1), "Selection", gobjects(0, 1), "Listener", event.listener.empty);
    plt.Image = image(ax, "XData", [1 max(n_col, 1)], "YData", [1 max(n_row, 1)], "CData", NaN, ...
        "CDataMapping", "scaled", "AlphaData", 0, "Visible", "off");
    r_size = max(4, min(15, 1500 / max([n_row, n_col, 1])));     % dots shrink with the size of the matrix
    plt.Pattern = line(ax, NaN, NaN, "LineStyle", "none", "Marker", ".", "MarkerSize", r_size, ...
        "Color", [0 0.25 0.6], "Visible", "off");

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
    set_ticks(ax, d.sv_rowName, d.sv_colName);
    fig = ancestor(ax, "figure");
    try                                 % the tick labels follow the size of the axes
        plt.Listener = listener(fig, "SizeChanged", @(~, ~) set_ticks(ax, d.sv_rowName, d.sv_colName));
    catch
    end

    % Data tips: names and value; separators are clicks on their group
    wr  = matlab.lang.WeakReference(obj);
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
        if hObj == plt.Image || hObj == plt.Pattern
            i = min(max(round(rv_p(2)), 1), numel(d.sv_rowName));
            j = min(max(round(rv_p(1)), 1), numel(d.sv_colName));
            v = full(d.c_matrix{G.i_time}(i, j));
            txt = {char("Row: " + d.sv_rowName(i) + " (" + d.sv_rowGroup(i) + ")"), ...
                   char("Column: " + d.sv_colName(j) + " (" + d.sv_colGroup(j) + ")"), ...
                   sprintf('Value: %.6g', v)};
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
