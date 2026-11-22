classdef GraphChart < GraphBase
% Chart of analysis results: panels of lines, bars and marker sets.
%
% A chart has one or more panels (axes, one above the other, or in a grid: rv_grid) and a
% list of series. A series is drawn in one panel: a set of lines, a set of bars or a set
% of markers. Every line, every bar and every marker set is an element of tab_element
% with its own tag, so set_style, the vector properties, select and the clicks work on
% each of them. On the panels marked as time panels, set_time(t) draws a vertical cursor
% at t (none before the first set_time), so that a chart linked to a GraphSpring2D or
% GraphNetDiagram follows its animation. A time panel whose x is not the time (e.g. a PV
% curve against lambda, one point per step) takes a marker cursor instead (s_cursor
% "marker"): set_time puts a marker on each line and marker set at its point of the
% sample. A chart without time panels ignores set_time (TimeChanged still fires, e.g. to
% write a title per time; see GraphBase), unless a series is shown by sample (iv_sample)
% or a panel has a title per sample. A 3D panel (l_3d) draws lines and marker sets in x,
% y and z (e.g. P, Q and |V| per bus), and its time cursor is the marker cursor.
%
% The data (constructor and set_data) is a struct with the fields:
%
% - `sct_panel` (1 x n_panel struct, optional; one panel when missing): per panel
%   - `s_title`, `s_xlabel`, `s_ylabel`, `s_zlabel`: title and axis labels ("" none;
%     s_zlabel for a 3D panel); s_title may also be one title per sample (1 x n_t), shown
%     with the sample;
%   - `rv_xlim`, `rv_ylim`, `rv_zlim`: axis limits ([] automatic, from the data in x, y and
%     z);
%   - `s_xscale`, `s_yscale`: "linear" (default) or "log";
%   - `l_time`: true for a time panel (default false);
%   - `l_3d`: true for a 3D panel (default false): its series are lines and marker sets
%     with rm_z, drawn in view(3); no bars and no reference lines. Drag the axes (or use
%     the rotate button of the axes toolbar) to turn it; clicks on the lines still raise
%     ElementClicked. A new drawing (set_data) keeps the view the user turned it to;
%   - `s_cursor`: cursor of a time panel, "line" (default of a 2D panel; a vertical line
%     at x = t) or "marker" (a marker in the color of the element at (rv_x(k), rm_y(k,
%     column)), or (rv_x(k), rm_y(k, column), rm_z(k, column)) in a 3D panel, of each line
%     and marker set of the panel, for sample k; their rm_y must have one row per sample
%     of rv_t). A 3D time panel takes "marker" only (its default there; "line" is an
%     error, GUILDA:GraphChart:Panel3D);
%   - `l_grid`: grid lines (default true);
%   - `s_legendLocation`: location of the legend (default "best"); "none" hides it.
% - `sct_series` (1 x n_series struct): per series
%   - `i_panel`: panel of the series (default 1);
%   - `s_type`: "line" (default), "bar" or "marker";
%   - `rv_x` (n_x): x values, or `sv_x` (n_x): category names (drawn at x = 1..n_x with
%     these tick labels; all series of a panel with categories must have the same ones).
%     Default x = 1..n_x;
%   - `rm_y` (n_x x n_col): y values, one column per line or marker set (e.g. time x
%     lines); a bar series has one column, one bar per row. NaN leaves a gap;
%   - `rm_z` (n_x x n_col, optional, default []): z values of a line or marker series of a
%     3D panel, the size of rm_y; required in a 3D panel and an error in a 2D panel
%     (GUILDA:GraphChart:Panel3D);
%   - `sv_tag`: tags of the elements, one per column (line, marker) or per bar (bar;
%     default sv_x);
%   - `sv_legend`: legend entries, one per column (line, marker; default sv_tag; ""
%     leaves the element out of the legend), or one for a bar series (default "": none);
%   - `rm_color`: initial colors (1 x 3 for all, or one row per element; a color name or
%     "#RRGGBB" for all); NaN rows (default) use the color order of the axes;
%   - `r_lineWidth` (default 1), `s_lineStyle` (default "-"), `s_marker` (default "none"
%     for a line, "o" for a marker set), `r_markerSize` (default 6): initial values;
%   - `iv_sample` (n_x, optional, lines and marker sets): the sample (index in rv_t) of
%     each row. The series then shows only the rows of the sample shown, e.g. the
%     eigenvalues of one section of ResultLIN.plot_eigenvalue; set_time(t) changes them
%     (in a 3D panel too).
% - `sct_refline` (struct array, optional): reference lines, e.g. a limit value. Per line
%   `i_panel` (default 1), `s_axis` ("x" a vertical line, "y" a horizontal line; default
%   "y"), `r_value`, `s_label` (default ""), `rv_color` (default [0.85 0.33 0.10]) and
%   `s_lineStyle` (default "--"). They are part of the fixed drawing, not elements.
% - `rv_t` (1 x n_t) [s] (optional, default 0): the times that set_time chooses from (or
%   the values of other samples, e.g. steps, with s_sampleName).
% - `s_sampleName`, `sv_sampleText` (optional): the name of the samples (e.g. "Step") and
%   the text of each sample (1 x n_t), shown in the playback bar instead of the time (see
%   GraphBase).
% - `s_title` (optional): title of the whole chart, on the tiled layout (with an axes as
%   Parent, on the axes when its panel has no title).
% - `rv_grid` (1 x 2, optional, default [n_panel 1]): rows and columns of the tiled layout,
%   [n_row n_col] with at least n_panel tiles. The panels fill the tiles row by row (in a
%   2 x 2 grid, panel 2 is at the top right); the tiles after the last panel stay empty.
%
% The bar series of a panel are drawn as one grouped bar chart. set_data takes the same
% struct with the same number of panels and the same rv_grid (the axes are made once);
% it keeps the appearance of the elements by tag and kind.
%
% Elements: one row per line ("line"), per bar ("bar") and per marker set ("marker"), in
% the order of the series and of their columns (bars). Index is the row of the element
% in the vector properties, which hold one row per element in this order. set_style
% options by kind:
%
% | Kind | Options |
% |---|---|
% | line | Color, Label, LineWidth, LineStyle, Marker, MarkerSize, Visible |
% | marker | Color, Label, Marker, MarkerSize, Visible |
% | bar | Color, Visible |
%
% Label is the legend entry ("" leaves it out). A hidden bar keeps its place in the
% group. The rows of a kind that has no such option are kept but not used. Changing a
% vector property changes the existing graphics objects only. A click on a line, a marker
% set or a bar raises ElementClicked; a selected line or marker set gets a wide line or
% ring under it, a selected bar an outline, in SelectionColor.
%
% The playback bar below the axes (see GraphBase) is shown when the drawing of the chart
% changes with the time: two or more samples and a series with iv_sample or a title per
% sample (has_playback). A chart whose time only moves a cursor (a time panel, e.g.
% ResultODE.plot_trajectory) has no bar: set_time, animate, export_video, link and the bar
% of a linked graph move its cursor.
% show_controls has no controls: the appearance is per element.
%
% Parent: a container gives a tiled layout of rv_grid with one axes per panel; a
% single-panel chart also draws in an axes or uiaxes (see GraphBase).
%
% <@Examples>
% ```matlab
% sct = struct();
% sct.rv_t = 0:0.01:2;
% sct.sct_panel  = struct("s_xlabel", "t [s]", "s_ylabel", "y", "l_time", true);
% sct.sct_series = struct("rv_x", sct.rv_t, "rm_y", [sin(sct.rv_t); cos(sct.rv_t)].', ...
%                         "sv_tag", ["s"; "c"]);
% G = GraphChart(sct);
% G.set_style("s", Color="r", LineWidth=2);   % the same as G.SeriesColor(1, :) = [1 0 0] ...
% G.set_time(1.0);                           % cursor at t = 1
% ```
%
% A 3D panel: lines in (x, y, z), e.g. (P, Q, |V|) of buses (rv_x is per series: one series
% per bus when their P differ), with a marker at the point of each sample.
%
% ```matlab
% rv_t = 0:0.1:1;
% sct = struct("rv_t", rv_t);
% sct.sct_panel  = struct("s_xlabel", "P [pu]", "s_ylabel", "Q [pu]", "s_zlabel", "|V| [pu]", ...
%                         "l_3d", true, "l_time", true);       % s_cursor "marker" by default
% sct.sct_series = struct("rv_x", rv_t, "rm_y", [0.3*rv_t; 0.1*rv_t].', ...
%                         "rm_z", [1 - 0.2*rv_t.^2; 1 - 0.1*rv_t.^2].', "sv_tag", ["B1"; "B2"]);
% G = GraphChart(sct);
% G.set_time(0.5);                           % markers at (rv_x(6), rm_y(6, :), rm_z(6, :))
% ```
%
% See also GraphBase, ResultODE.plot_trajectory

    properties % Appearance of each element (one row per element, see tab_element)
        SeriesColor (:,3) double = zeros(0, 3)                        % RGB color of each element; NaN rows: the color order of the axes.
        SeriesLabel (:,1) string = strings(0, 1)                      % Legend entry of each line and marker set ("": none).
        SeriesLineWidth (:,1) double {mustBePositive} = zeros(0, 1)   % Width of each line.
        SeriesMarker (:,1) string = strings(0, 1)                     % Marker of each line and marker set.
        SeriesMarkerSize (:,1) double {mustBePositive} = zeros(0, 1)  % Marker size of each line and marker set.
        SeriesLineStyle (:,1) string = strings(0, 1)                  % Line style of each line.
        SeriesVisible (:,1) logical = false(0, 1)                     % Show each element.
    end
    properties (Access = protected) % Data
        sct_data                                                      % Data of the chart with the optional fields filled (see the class help). <@Type> struct
        tab_series                                                    % Element rows: Tag, Kind, Series (index in sct_series), Item (column or bar), Panel.
    end
    properties (Access = private) % Drawing
        rm_colorAuto = zeros(0, 3)                                    % Color of each element from the color order of the axes (for NaN rows).
        l_cursor (1,1) logical = false                                % The time cursor is shown (set_time was called).
        l_firstDraw (1,1) logical = true                              % The next update_scene follows create_scene in build or set_data.
    end

    methods
        function obj = GraphChart(sct_data, opt)
        % Check the data and draw the chart.
            arguments (Input)
                sct_data (1,1) struct  % Data of the chart (see the class help).
                opt.Parent = []        % Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes for a single panel; [] for a new figure.
            end
            arguments (Output)
                obj  % The chart.
            end
            obj.load_data(sct_data);
            obj.build(opt, numel(obj.sct_data.sct_panel), obj.sct_data.rv_grid);
        end

        % Setters of the appearance of each element: draw the changed elements again
        function set.SeriesColor(obj, val)
            check_size(obj, val, "SeriesColor");
            if ~all(isnan(val) | (val >= 0 & val <= 1), "all")
                error(msg("GUILDA:GraphChart:StyleValue", "SeriesColor", "RGB values from 0 to 1 or NaN rows"));
            end
            iv = changed_rows(obj.SeriesColor, val);
            obj.SeriesColor = val;
            restyle(obj, iv);
        end
        function set.SeriesLabel(obj, val)
            check_size(obj, val, "SeriesLabel");
            iv = changed_rows(obj.SeriesLabel, val);
            obj.SeriesLabel = val;
            restyle(obj, iv);
        end
        function set.SeriesLineWidth(obj, val)
            check_size(obj, val, "SeriesLineWidth");
            iv = changed_rows(obj.SeriesLineWidth, val);
            obj.SeriesLineWidth = val;
            restyle(obj, iv);
        end
        function set.SeriesMarker(obj, val)
            check_size(obj, val, "SeriesMarker");
            iv = changed_rows(obj.SeriesMarker, val);
            obj.SeriesMarker = val;
            restyle(obj, iv);
        end
        function set.SeriesMarkerSize(obj, val)
            check_size(obj, val, "SeriesMarkerSize");
            iv = changed_rows(obj.SeriesMarkerSize, val);
            obj.SeriesMarkerSize = val;
            restyle(obj, iv);
        end
        function set.SeriesLineStyle(obj, val)
            check_size(obj, val, "SeriesLineStyle");
            iv = changed_rows(obj.SeriesLineStyle, val);
            obj.SeriesLineStyle = val;
            restyle(obj, iv);
        end
        function set.SeriesVisible(obj, val)
            check_size(obj, val, "SeriesVisible");
            iv = changed_rows(obj.SeriesVisible, val);
            obj.SeriesVisible = val;
            restyle(obj, iv);
        end
    end

    methods (Access = protected)
        load_data(obj, sct_data)
        create_scene(obj)
        update_scene(obj, k)
        apply_style(obj, iv_element)
        tab = element_table(obj)
        sct_map = style_properties(obj)
        apply_selection(obj)
        sct_ctl = control_list(obj)
        l = has_playback(obj)
    end

    methods (Access = private)
        refresh_legend(obj, iv_panel)
    end
end


function check_size(obj, val, s_prop)
% Stop when a vector property does not have one row per element.
    arguments (Input)
        obj                  % The chart.
        val                  % New value of the property.
        s_prop (1,1) string  % Name of the property.
    end
    if isempty(obj.tab_series)
        return
    end
    n = height(obj.tab_series);
    if size(val, 1) ~= n
        error(msg("GUILDA:GraphChart:StyleSize", s_prop, n, size(val, 1)));
    end
end


function iv = changed_rows(v_old, v_new)
% Rows of v_new that differ from v_old (all rows when the sizes differ).
    arguments (Input)
        v_old  % Old value.
        v_new  % New value.
    end
    arguments (Output)
        iv (:,1) double  % Changed rows.
    end
    n = size(v_new, 1);
    if size(v_old, 1) ~= n
        iv = (1:n)';
        return
    end
    iv = find(~arrayfun(@(i) isequaln(v_old(i, :), v_new(i, :)), (1:n)'));
end


function restyle(obj, iv_element)
% Draw the appearance of the elements iv_element again once the chart exists.
    arguments (Input)
        obj                      % The chart.
        iv_element (:,1) double  % Rows of the elements.
    end
    if isempty(iv_element) || isempty(obj.sct_plt) || ~all(isgraphics(obj.ax))
        return
    end
    obj.apply_style(iv_element);
end
