function fit_axes(obj, s_mode)
% Fit the limits of the axes to the drawing and its labels; in 2D push overlapping labels apart.
%
% "fit" (default): the limits are the box of the drawing (DrawBox: bus centers and bar
% ends, components and the points of the branch and link paths) with a padding of 3% of
% its larger side (a side shorter than 2% of it is widened to that). In 2D the labels
% shown go back to their places (NodeLabelXYZ, CompLabelXYZ), the overlapping ones are
% moved apart vertically (GraphBase.resolve_overlap) and the limits grow to take in their
% boxes. Called by create_scene and when the labels change (LabelMode, LabelFontSize).
% "labels" (2D): the limits stay; the labels go back to their places and are moved apart
% again only.
%
% The boxes of the texts are measured in the current limits and pixel size of the axes,
% so in 2D a listener on the MarkedClean event of the axes (made here once per axes, held
% by a weak reference) compares, after each drawing of the axes, the limits and the pixel
% size of the axes with those of the last layout (sct_plt.LabelView).
% When they changed (a GUI sets the limits or resizes its panels, the figure is resized,
% a hidden tab is shown), the labels are laid out again: with "fit" while the limits are
% still the ones fit_axes set (sct_plt.FitLim), else with "labels". The check costs
% little, so it also runs after every frame of the flow animation; several changes before
% one drawing give one layout.
    arguments (Input)
        obj
        s_mode (1,1) string {mustBeMember(s_mode, ["fit", "labels"])} = "fit"  % "fit" or "labels".
    end
    ax  = obj.ax(1);
    l_busy = obj.l_labelBusy;
    obj.l_labelBusy = true;
    c_busy = onCleanup(@() set_busy(obj, l_busy));
    plt = obj.sct_plt;
    rm_box = plt.DrawBox;                         % [min; max] of x, y, z
    rv_span = rm_box(2, :) - rm_box(1, :);
    r_ref = max(rv_span(1:2));
    if ~(r_ref > eps)
        r_ref = 1;
    end
    l_fit = s_mode == "fit";
    if l_fit
        rv_c = mean(rm_box, 1);
        lv_thin = rv_span < 0.02*r_ref;
        rm_box(:, lv_thin) = rv_c(lv_thin) + [-1; 1]*0.01*r_ref;
        r_pad = 0.03*r_ref;
        rv_x = rm_box(:, 1)' + [-r_pad, r_pad];
        rv_y = rm_box(:, 2)' + [-r_pad, r_pad];
        xlim(ax, rv_x);
        ylim(ax, rv_y);
        r_zHalf = max(0.02*r_ref, 2*plt.NodeRadius);
        if rv_span(3) < 0.02*r_ref
            zlim(ax, rv_c(3) + [-1 1]*r_zHalf);
        else
            zlim(ax, [rm_box(1, 3) - r_zHalf, rm_box(2, 3) + r_zHalf]);
        end
    end
    if obj.Dimension ~= "2D"
        return
    end

    % Labels shown: back to their places, apart from each other (and inside the limits)
    hv_bus = plt.NodeLabel(:);
    hv_com = plt.CompLabel(:);
    lv_bus = isgraphics(hv_bus);
    lv_com = isgraphics(hv_com);
    for c_set = {hv_bus(lv_bus), plt.NodeLabelXYZ(lv_bus, :); hv_com(lv_com), plt.CompLabelXYZ(lv_com, :)}'
        if ~isempty(c_set{1})
            set(c_set{1}, {"Position"}, num2cell(c_set{2}, 2));
        end
    end
    hv = [hv_bus(lv_bus); hv_com(lv_com)];
    hv = hv(arrayfun(@(h) h.Visible == "on" && any(strlength(string(h.String)) > 0), hv));
    if ~l_fit && ~isempty(hv)
        GraphBase.resolve_overlap(hv, gobjects(0), 50, 0.002*r_ref);
    elseif ~isempty(hv)
        % The boxes are measured once (a get of Extent lays the texts out: slow in a
        % uifigure) and kept in pixels; for wider limits they are scaled by the data units
        % per pixel. Wider limits make a text longer in coordinates, so again until the
        % limits stay.
        rm_xy  = vertcat(hv.Position);
        rm_ext = get(hv, "Extent");                    % [x y w h] (a cell for two or more)
        if iscell(rm_ext)
            rm_ext = vertcat(rm_ext{:});
        end
        r_s0   = data_per_pixel(ax, rv_x, rv_y);
        rm_pix = [rm_ext(:, 1:2) - rm_xy(:, 1:2), rm_ext(:, 3:4)] / r_s0;   % box relative to its text, in pixels
        r_gap  = 0.01*r_ref;
        for i_pass = 1:3
            r_s = data_per_pixel(ax, rv_x, rv_y);
            if i_pass > 1
                set(hv, {"Position"}, num2cell(rm_xy, 2));
            end
            rm_box = GraphBase.resolve_overlap(hv, gobjects(0), 50, 0.002*r_ref, ...
                [rm_xy(:, 1:2) + rm_pix(:, 1:2)*r_s, rm_pix(:, 3:4)*r_s]);
            rv_x2 = [min(rv_x(1), min(rm_box(:, 1)) - r_gap), max(rv_x(2), max(rm_box(:, 1) + rm_box(:, 3)) + r_gap)];
            rv_y2 = [min(rv_y(1), min(rm_box(:, 2)) - r_gap), max(rv_y(2), max(rm_box(:, 2) + rm_box(:, 4)) + r_gap)];
            l_same = max(abs([rv_x2 - rv_x, rv_y2 - rv_y])) < 1e-3*r_ref;
            rv_x = rv_x2;
            rv_y = rv_y2;
            xlim(ax, rv_x);
            ylim(ax, rv_y);
            if l_same
                break
            end
        end
    end

    % The view of this layout, and the listener that lays the labels out again when it changes
    if l_fit
        obj.sct_plt.FitLim = [ax.XLim, ax.YLim];
    end
    obj.sct_plt.LabelView = label_view(ax);
    lis = obj.lis_labelAxes;
    if isempty(lis) || ~isvalid(lis) || lis.Source{1} ~= ax
        if ~isempty(lis) && isvalid(lis)
            delete(lis);
        end
        wr = matlab.lang.WeakReference(obj);
        obj.lis_labelAxes = listener(ax, "MarkedClean", @(~, ~) label_check(wr));
    end
end


function label_check(wr)
% After a drawing of the axes: lay the labels out again when the limits or the pixel size changed.
    arguments (Input)
        wr  % Weak reference to the diagram. <@Type> matlab.lang.WeakReference
    end
    G = wr.Handle;
    if isempty(G) || ~isvalid(G) || G.l_labelBusy || G.l_drawing || validate(G) ...
            || G.Dimension ~= "2D" || ~isfield(G.sct_plt, "LabelView")
        return
    end
    ax = G.ax(1);
    if isequal(label_view(ax), G.sct_plt.LabelView)
        return
    end
    try
        if isequal([ax.XLim, ax.YLim], G.sct_plt.FitLim)
            G.fit_axes("fit");               % the limits are still ours: fit them to the new size
        else
            G.fit_axes("labels");            % limits set from outside (a GUI, zoom): they stay
        end
    catch err
        show_msg("warning", "GUILDA:GraphNetDiagram:LabelLayout", err.message);
    end
end


function rv = label_view(ax)
% Limits and pixel size of the axes, which the boxes of the labels depend on.
    arguments (Input)
        ax  % The axes. <@Type> matlab.graphics.axis.Axes
    end
    arguments (Output)
        rv (1,6) double  % [XLim, YLim, width, height] (pixels).
    end
    rv_p = getpixelposition(ax);
    rv = [ax.XLim, ax.YLim, round(rv_p(3:4))];
end


function set_busy(obj, l_busy)
% Give back the state of l_labelBusy (onCleanup of fit_axes).
    arguments (Input)
        obj
        l_busy (1,1) logical  % State before fit_axes.
    end
    if isvalid(obj)
        obj.l_labelBusy = l_busy;
    end
end


function r = data_per_pixel(ax, rv_x, rv_y)
% Data units per pixel of 2D axes with equal data aspect and limits rv_x, rv_y (the plot box fits the axes).
    arguments (Input)
        ax                 % The axes. <@Type> matlab.graphics.axis.Axes
        rv_x (1,2) double  % x limits.
        rv_y (1,2) double  % y limits.
    end
    arguments (Output)
        r (1,1) double  % Data units per pixel.
    end
    rv_p = getpixelposition(ax);
    r = max(diff(rv_x)/max(rv_p(3), 1), diff(rv_y)/max(rv_p(4), 1));
end

