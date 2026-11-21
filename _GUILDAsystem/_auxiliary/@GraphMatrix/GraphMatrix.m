classdef GraphMatrix < GraphBase
% Matrix whose rows and columns are named variables: the pattern, the magnitude or the values.
%
% The graph draws one matrix per sample (e.g. a Jacobian at several times) with the
% names of the variables as tick labels and thin separator lines between the groups of
% rows and of columns (e.g. the owner of each variable). It is built from data only.
%
% The data (constructor and set_data) is a struct with the fields:
%
% - `c_matrix` (1 x n_t cell): the matrix of each sample, n_row x n_col real (double or
%   logical, sparse allowed). Every sample has the same size.
% - `rv_t` (1 x n_t) [s]: the times of the samples, finite and nondecreasing. It may be
%   left out for one sample (t = 0).
% - `sv_rowName` (n_row), `sv_colName` (n_col): the names of the rows and columns.
% - `sv_rowGroup` (n_row), `sv_colGroup` (n_col): the group (owner tag) of each row and
%   column, nonempty. The rows of a group need not be next to each other.
% - `s_title`, `s_rowLabel`, `s_colLabel` (optional, default ""): the title and the
%   labels of the axes.
% - `l_frame` (optional, default false): a box around each block of a group that is
%   both a row group and a column group (the diagonal blocks of a square matrix).
% - `l_valueText` (optional, default false): the values of the sample shown are written
%   in their cells ("%.3g"; the entries above Tolerance, when there are at most 900).
% - `s_sampleName`, `sv_sampleText` (optional): the name of the samples (e.g. "Section")
%   and the text of each sample (1 x n_t), shown in the title and the playback bar
%   instead of the time (see GraphBase).
%
% Display:
%
% - `"pattern"` (default): a dot at every entry with |value| > Tolerance.
% - `"magnitude"`: an image colored by log10|value|, with a colorbar; the entries with
%   |value| <= Tolerance are blank.
% - `"value"`: an image of the signed values with a diverging colormap (blue negative,
%   red positive) and a colorbar; the entries with |value| <= Tolerance are blank.
%
% NaN entries are not drawn. `ColorLimits` sets the limits of the colorbar: of
% log10|value| for "magnitude" and of the value for "value". A NaN limit (default
% [NaN NaN]) is automatic: over the entries above Tolerance of all samples, [min max] of
% log10|value| for "magnitude" and [-m m] (m the largest |value|) for "value".
%
% The tick labels are the names. When they would overlap (e.g. 300 variables in a small
% axes), only every k-th name is shown, with k the smallest step that fits; the labels are
% chosen again when the figure is resized. A data tip on the matrix shows the row name,
% the column name, their groups and the value of the sample shown.
%
% Time: set_time(t) shows the sample nearest to t, and the title shows its time or its
% sample text (not for data of one sample at t = 0 without a text).
%
% Elements: one row per group of rows (Kind "rowgroup") and per group of columns (Kind
% "colgroup"), in the order of their first row or column; the Tag is the group. A group of
% rows has a horizontal line before each block of its rows (the first one on the edge of
% the axes), a group of columns a vertical line before each block of its columns.
% `select(tag)` highlights the rows and the columns of the group; a data tip on a
% separator line is a click on its group (ElementClicked). A click on the matrix (a dot,
% the image or the empty background) is a click on the group of the row clicked; the
% column is in G.ax.CurrentPoint. set_style options by kind:
%
% | Kind | Options |
% |---|---|
% | rowgroup | Color, LineWidth |
% | colgroup | Color, LineWidth |
%
% show_controls shows Display, ColorLimits (with an Auto checkbox; disabled for
% "pattern") and Tolerance; for two or more samples the time is in the playback bar below
% the axes (see GraphBase).
%
% Parent: a container gives a tiled layout with one axes; an axes or uiaxes is used
% directly (see GraphBase).
%
% <@Examples>
% ```matlab
% sct = struct();
% sct.rv_t        = [0 1];
% sct.c_matrix    = {sparse([1 2 0; 0 -3 4; 5 0 6]), sparse([1 0 0; 0 -2 4; 5 0 7])};
% sct.sv_rowName  = ["delta"; "omega"; "V"];
% sct.sv_colName  = ["delta"; "omega"; "V"];
% sct.sv_rowGroup = ["G1"; "G1"; "B1"];
% sct.sv_colGroup = ["G1"; "G1"; "B1"];
% G = GraphMatrix(sct, Display="value");
% G.set_style("G1", Color="r", LineWidth=2);   % the separators of G1 (rows and columns)
% G.select("B1");                              % highlight the rows and columns of B1
% G.set_time(1);                               % the second sample
% G.show_controls();
% ```
%
% See also GraphBase, GraphChart, GraphNetDiagram

    properties (SetObservable) % Appearance (controls of show_controls)
        Display (1,1) string {mustBeMember(Display, ["pattern","magnitude","value"])} = "pattern"  % What is drawn: "pattern", "magnitude" or "value" (see the class help).
        ColorLimits (1,2) double = [NaN NaN]                                                      % Limits of the colorbar (log10|value| for "magnitude"); NaN: automatic over all samples.
        Tolerance (1,1) double {mustBeNonnegative, mustBeFinite} = 0                              % Entries with |value| <= Tolerance are drawn as zero.
    end
    properties % Appearance of each element (one row per element, see tab_element)
        SeparatorColor (:,3) double = zeros(0, 3)                                                 % RGB color of the separator lines of each group.
        SeparatorLineWidth (:,1) double {mustBePositive} = zeros(0, 1)                            % [pt] Width of the separator lines of each group.
    end
    properties (Access = protected) % Data
        sct_data                                                                                  % Data of the graph with the optional fields filled, the element tags and kinds and the blocks of each group. <@Type> struct
    end
    properties (Access = private) % Drawing
        sct_limitAuto = struct.empty                                                              % Automatic color limits of all samples for one Tolerance (r_tol, rv_magnitude, rv_value).
    end

    methods
        function obj = GraphMatrix(sct_data, opt)
        % Check the data and draw the matrix.
            arguments (Input)
                sct_data (1,1) struct           % Data of the graph (see the class help).
                opt.Parent = []                 % Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes; [] for a new figure.
                opt.Display (1,1) string        % What is drawn: "pattern", "magnitude" or "value".
                opt.ColorLimits (1,2) double    % Limits of the colorbar; NaN: automatic.
                opt.Tolerance (1,1) double      % Entries with |value| <= Tolerance are drawn as zero.
            end
            arguments (Output)
                obj  % The graph.
            end
            obj.load_data(sct_data);
            obj.build(opt);
        end

        % Setters of the view: draw the sample shown again
        function set.Display(obj, val)
            arguments (Input)
                obj
                val  % "pattern", "magnitude" or "value".
            end
            obj.Display = val;
            redraw(obj);
        end
        function set.ColorLimits(obj, val)
            arguments (Input)
                obj
                val  % [min max]; NaN: automatic.
            end
            if all(isfinite(val)) && val(1) >= val(2)
                error(msg("GUILDA:GraphMatrix:StyleValue", "ColorLimits", "[min max] with min < max, or NaN for automatic limits"));
            end
            obj.ColorLimits = val;
            redraw(obj);
        end
        function set.Tolerance(obj, val)
            arguments (Input)
                obj
                val  % Tolerance (nonnegative).
            end
            obj.Tolerance = val;
            redraw(obj);
        end

        % Setters of the appearance of each element: draw the changed elements again
        function set.SeparatorColor(obj, val)
            arguments (Input)
                obj
                val  % One RGB row per element.
            end
            check_size(obj, val, "SeparatorColor");
            if ~all(val >= 0 & val <= 1, "all")
                error(msg("GUILDA:GraphMatrix:StyleValue", "SeparatorColor", "RGB values from 0 to 1"));
            end
            iv = changed_rows(obj.SeparatorColor, val);
            obj.SeparatorColor = val;
            restyle(obj, iv);
        end
        function set.SeparatorLineWidth(obj, val)
            arguments (Input)
                obj
                val  % One width per element.
            end
            check_size(obj, val, "SeparatorLineWidth");
            iv = changed_rows(obj.SeparatorLineWidth, val);
            obj.SeparatorLineWidth = val;
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
    end
end


function l = is_drawn(obj)
% The graph has its scene and its axes (the setters draw only then).
    arguments (Input)
        obj  % The graph.
    end
    arguments (Output)
        l (1,1) logical  % The scene exists.
    end
    l = ~isempty(obj.sct_plt) && ~isempty(obj.ax) && all(isgraphics(obj.ax));
end


function redraw(obj)
% Draw the sample shown again and the selection over it, once the graph exists.
    arguments (Input)
        obj  % The graph.
    end
    if is_drawn(obj)
        obj.update_scene(obj.i_time);
        obj.apply_selection();
    end
end


function check_size(obj, val, s_prop)
% Stop when a vector property does not have one row per element.
    arguments (Input)
        obj                  % The graph.
        val                  % New value of the property.
        s_prop (1,1) string  % Name of the property.
    end
    if isempty(obj.sct_data)
        return
    end
    n = numel(obj.sct_data.sv_tag);
    if size(val, 1) ~= n
        error(msg("GUILDA:GraphMatrix:StyleSize", s_prop, n, size(val, 1)));
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
% Draw the appearance of the elements iv_element again once the graph exists.
    arguments (Input)
        obj                      % The graph.
        iv_element (:,1) double  % Rows of the elements.
    end
    if ~isempty(iv_element) && is_drawn(obj)
        obj.apply_style(iv_element);
    end
end
