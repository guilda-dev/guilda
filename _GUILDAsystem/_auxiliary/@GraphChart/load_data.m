function load_data(obj, sct_data)
% Check the data of the chart, fill the optional fields and set the appearance of each element.
    arguments (Input)
        obj
        sct_data (1,1) struct  % Data of the chart (see the class help).
    end
    % Times and title of the chart
    rv_t = field_or(sct_data, "rv_t", 0);
    if isempty(rv_t)
        rv_t = 0;
    end
    if ~(isnumeric(rv_t) && isreal(rv_t) && isvector(rv_t) && all(isfinite(rv_t)) && all(diff(rv_t) >= 0))
        error(msg("GUILDA:GraphChart:FieldValue", "rv_t", "finite nondecreasing real times"));
    end
    s_title = string(field_or(sct_data, "s_title", ""));

    % Panels
    sct_in = field_or(sct_data, "sct_panel", struct());
    if isempty(sct_in)
        sct_in = struct();
    end
    if ~isstruct(sct_in)
        error(msg("GUILDA:GraphChart:FieldValue", "sct_panel", "a struct array"));
    end
    n_panel = numel(sct_in);
    if ~isempty(obj.ax) && numel(obj.ax) ~= n_panel
        error(msg("GUILDA:GraphChart:PanelCount", numel(obj.ax), n_panel));
    end
    rv_grid = field_or(sct_data, "rv_grid", [n_panel 1]);
    if ~(isnumeric(rv_grid) && isreal(rv_grid) && numel(rv_grid) == 2 && all(isfinite(rv_grid) & rv_grid >= 1 & rv_grid == round(rv_grid)) ...
            && prod(rv_grid) >= n_panel)
        error(msg("GUILDA:GraphChart:FieldValue", "rv_grid", "[n_row n_col], positive integers with at least " + n_panel + " tiles"));
    end
    rv_grid = double(rv_grid(:)');
    if ~isempty(obj.ax) && ~isequal(rv_grid, obj.sct_data.rv_grid)
        error(msg("GUILDA:GraphChart:GridChange", obj.sct_data.rv_grid(1), obj.sct_data.rv_grid(2), rv_grid(1), rv_grid(2)));
    end
    sct_panel = repmat(struct("s_title", "", "s_xlabel", "", "s_ylabel", "", "rv_xlim", [], "rv_ylim", [], ...
        "s_xscale", "linear", "s_yscale", "linear", "l_time", false, "l_grid", true, ...
        "s_legendLocation", "best", "s_cursor", "line", "sv_x", strings(0, 1)), 1, n_panel);
    for i = 1:n_panel
        p = sct_in(i);
        s_at = "sct_panel(" + i + ").";
        for s_field = ["s_title", "s_xlabel", "s_ylabel", "s_legendLocation"]
            sct_panel(i).(s_field) = string(field_or(p, s_field, sct_panel(i).(s_field)));
        end
        for s_field = ["s_xscale", "s_yscale"]
            s = string(field_or(p, s_field, "linear"));
            if ~any(s == ["linear", "log"])
                error(msg("GUILDA:GraphChart:FieldValue", s_at + s_field, """linear"" or ""log"""));
            end
            sct_panel(i).(s_field) = s;
        end
        for s_field = ["rv_xlim", "rv_ylim"]
            rv = field_or(p, s_field, []);
            if ~(isempty(rv) || isnumeric(rv) && numel(rv) == 2 && rv(1) < rv(2))
                error(msg("GUILDA:GraphChart:FieldValue", s_at + s_field, "[] or two increasing limits"));
            end
            sct_panel(i).(s_field) = double(rv(:)');
        end
        for s_field = ["l_time", "l_grid"]
            sct_panel(i).(s_field) = logical(field_or(p, s_field, sct_panel(i).(s_field)));
        end
        if ~any(numel(sct_panel(i).s_title) == [1, numel(rv_t)])
            error(msg("GUILDA:GraphChart:FieldSize", s_at + "s_title", "one title or one per sample (" + numel(rv_t) + ")", ...
                size_text(sct_panel(i).s_title)));
        end
        sct_panel(i).s_title = reshape(sct_panel(i).s_title, 1, []);
        s = string(field_or(p, "s_cursor", "line"));
        if ~(isscalar(s) && any(s == ["line", "marker"])) || (s == "marker" && ~sct_panel(i).l_time)
            error(msg("GUILDA:GraphChart:FieldValue", s_at + "s_cursor", """line"" or ""marker"" (""marker"" only on a time panel, l_time true)"));
        end
        sct_panel(i).s_cursor = s;
    end

    % Series and their elements
    sct_in = field_or(sct_data, "sct_series", struct.empty);
    if ~isstruct(sct_in)
        error(msg("GUILDA:GraphChart:FieldValue", "sct_series", "a struct array"));
    end
    n_series = numel(sct_in);
    sct_series = repmat(struct("i_panel", 1, "s_type", "line", "rv_x", [], "sv_x", strings(0, 1), ...
        "rm_y", [], "sv_tag", strings(0, 1), "sv_legend", strings(0, 1), "iv_sample", zeros(0, 1)), 1, n_series);
    c_tag = cell(n_series, 1);  c_kind = c_tag;  c_series = c_tag;  c_item = c_tag;  c_panel = c_tag;
    c_label = c_tag;  c_color = c_tag;  c_width = c_tag;  c_style = c_tag;  c_marker = c_tag;  c_size = c_tag;
    for i = 1:n_series
        p = sct_in(i);
        s_at = "sct_series(" + i + ").";
        i_panel = field_or(p, "i_panel", 1);
        if ~(isscalar(i_panel) && any(i_panel == 1:n_panel))
            error(msg("GUILDA:GraphChart:FieldValue", s_at + "i_panel", "a panel index from 1 to " + n_panel));
        end
        s_type = string(field_or(p, "s_type", "line"));
        if ~(isscalar(s_type) && any(s_type == ["line", "bar", "marker"]))
            error(msg("GUILDA:GraphChart:FieldValue", s_at + "s_type", """line"", ""bar"" or ""marker"""));
        end
        if ~isfield(p, "rm_y") || ~(isnumeric(p.rm_y) && isreal(p.rm_y) && ismatrix(p.rm_y))
            error(msg("GUILDA:GraphChart:MissingField", s_at + "rm_y"));
        end
        rm_y = double(p.rm_y);
        n_x  = size(rm_y, 1);
        sv_x = string(field_or(p, "sv_x", strings(0, 1)));
        sv_x = sv_x(:);
        rv_x = field_or(p, "rv_x", []);
        if ~isempty(sv_x)
            if numel(sv_x) ~= n_x
                error(msg("GUILDA:GraphChart:FieldSize", s_at + "sv_x", n_x + "x1", size_text(sv_x)));
            end
            sv_panel = sct_panel(i_panel).sv_x;
            if ~isempty(sv_panel) && ~isequal(sv_panel, sv_x)
                error(msg("GUILDA:GraphChart:FieldValue", s_at + "sv_x", "the categories of the other series of panel " + i_panel));
            end
            sct_panel(i_panel).sv_x = sv_x;
            rv_x = (1:n_x)';
        elseif isempty(rv_x)
            rv_x = (1:n_x)';
        end
        if ~(isnumeric(rv_x) && isreal(rv_x) && numel(rv_x) == n_x)
            error(msg("GUILDA:GraphChart:FieldSize", s_at + "rv_x", n_x + "x1", size_text(rv_x)));
        end
        rv_x = double(rv_x(:));
        iv_sample = field_or(p, "iv_sample", zeros(0, 1));
        if ~isempty(iv_sample)
            if s_type == "bar" || ~(isnumeric(iv_sample) && numel(iv_sample) == n_x ...
                    && all(iv_sample(:) == round(iv_sample(:)) & iv_sample(:) >= 1 & iv_sample(:) <= numel(rv_t)))
                error(msg("GUILDA:GraphChart:FieldValue", s_at + "iv_sample", ...
                    "the sample (1 to " + numel(rv_t) + ") of each of the " + n_x + " rows of a line or marker series"));
            end
        end
        iv_sample = double(iv_sample(:));

        if s_type == "bar"
            if width(rm_y) ~= 1
                error(msg("GUILDA:GraphChart:FieldSize", s_at + "rm_y", n_x + "x1 (one bar per row)", size_text(rm_y)));
            end
            n_elem  = n_x;
            sv_tag  = string(field_or(p, "sv_tag", sv_x));
            sv_leg  = string(field_or(p, "sv_legend", ""));
            n_leg   = 1;
            sv_lab  = sv_tag(:);
        else
            n_elem  = width(rm_y);
            if ~isfield(p, "sv_tag")
                error(msg("GUILDA:GraphChart:MissingField", s_at + "sv_tag"));
            end
            sv_tag  = string(p.sv_tag);
            sv_leg  = string(field_or(p, "sv_legend", sv_tag));
            n_leg   = n_elem;
        end
        sv_tag = sv_tag(:);
        if numel(sv_tag) ~= n_elem || any(ismissing(sv_tag) | sv_tag == "")
            error(msg("GUILDA:GraphChart:FieldSize", s_at + "sv_tag", n_elem + "x1 nonempty tags", size_text(sv_tag)));
        end
        if numel(sv_leg) ~= n_leg
            error(msg("GUILDA:GraphChart:FieldSize", s_at + "sv_legend", n_leg + "x1", size_text(sv_leg)));
        end
        sv_leg(ismissing(sv_leg)) = "";
        if s_type ~= "bar"
            sv_lab = sv_leg(:);
        end

        % Initial appearance of the elements of the series
        rm_color = field_or(p, "rm_color", []);
        if isempty(rm_color)
            rm_color = nan(1, 3);
        elseif isstring(rm_color) || ischar(rm_color)
            try
                rm_color = validatecolor(rm_color);
            catch
                error(msg("GUILDA:GraphChart:FieldValue", s_at + "rm_color", "a color name, ""#RRGGBB"" or RGB rows"));
            end
        end
        if ~(isnumeric(rm_color) && width(rm_color) == 3 && any(height(rm_color) == [1, n_elem]) ...
                && all(isnan(rm_color) | (rm_color >= 0 & rm_color <= 1), "all"))
            error(msg("GUILDA:GraphChart:FieldValue", s_at + "rm_color", "1x3 or " + n_elem + "x3 RGB values from 0 to 1 or NaN"));
        end
        s_markerDefault = "none";
        if s_type == "marker"
            s_markerDefault = "o";
        end
        r_width  = double(field_or(p, "r_lineWidth", 1));
        r_size   = double(field_or(p, "r_markerSize", 6));
        if ~(isscalar(r_width) && r_width > 0 && isscalar(r_size) && r_size > 0)
            error(msg("GUILDA:GraphChart:FieldValue", s_at + "r_lineWidth/r_markerSize", "positive scalars"));
        end
        c_tag{i}    = sv_tag;
        c_kind{i}   = repmat(s_type, n_elem, 1);
        c_series{i} = repmat(i, n_elem, 1);
        c_item{i}   = (1:n_elem)';
        c_panel{i}  = repmat(i_panel, n_elem, 1);
        c_label{i}  = sv_lab;
        c_color{i}  = double(rm_color) .* ones(n_elem, 1);
        c_width{i}  = repmat(r_width, n_elem, 1);
        c_style{i}  = repmat(string(field_or(p, "s_lineStyle", "-")), n_elem, 1);
        c_marker{i} = repmat(string(field_or(p, "s_marker", s_markerDefault)), n_elem, 1);
        c_size{i}   = repmat(r_size, n_elem, 1);
        sct_series(i) = struct("i_panel", i_panel, "s_type", s_type, "rv_x", rv_x, "sv_x", sv_x, ...
            "rm_y", rm_y, "sv_tag", sv_tag, "sv_legend", sv_leg(:), "iv_sample", iv_sample);
    end

    % A marker cursor puts a marker on each line and marker set at its row of the sample: one row per sample
    for i = 1:n_series
        if sct_panel(sct_series(i).i_panel).s_cursor == "marker" && sct_series(i).s_type ~= "bar" ...
                && (height(sct_series(i).rm_y) ~= numel(rv_t) || ~isempty(sct_series(i).iv_sample))
            error(msg("GUILDA:GraphChart:FieldSize", "sct_series(" + i + ").rm_y", ...
                numel(rv_t) + " rows (one per sample of rv_t, for the marker cursor of panel " + sct_series(i).i_panel + ")", ...
                size_text(sct_series(i).rm_y)));
        end
    end

    % The bar series of a panel are one grouped bar chart: the same x
    sv_type = [strings(1, 0), sct_series.s_type];
    for i_panel = 1:n_panel
        iv_bar = find([sct_series.i_panel] == i_panel & sv_type == "bar");
        for i = iv_bar(2:end)
            if ~isequal(sct_series(i).rv_x, sct_series(iv_bar(1)).rv_x)
                error(msg("GUILDA:GraphChart:FieldValue", "sct_series(" + i + ").rv_x", ...
                    "the x of the other bar series of panel " + i_panel + " (series " + iv_bar(1) + ")"));
            end
        end
    end

    % Reference lines
    sct_in = field_or(sct_data, "sct_refline", struct.empty);
    if ~isstruct(sct_in)
        error(msg("GUILDA:GraphChart:FieldValue", "sct_refline", "a struct array"));
    end
    sct_refline = repmat(struct("i_panel", 1, "s_axis", "y", "r_value", 0, "s_label", "", ...
        "rv_color", [0.85 0.33 0.10], "s_lineStyle", "--"), 1, numel(sct_in));
    for i = 1:numel(sct_in)
        p = sct_in(i);
        s_at = "sct_refline(" + i + ").";
        if ~isfield(p, "r_value") || ~(isnumeric(p.r_value) && isscalar(p.r_value) && isreal(p.r_value))
            error(msg("GUILDA:GraphChart:MissingField", s_at + "r_value"));
        end
        i_panel = field_or(p, "i_panel", 1);
        if ~(isscalar(i_panel) && any(i_panel == 1:n_panel))
            error(msg("GUILDA:GraphChart:FieldValue", s_at + "i_panel", "a panel index from 1 to " + n_panel));
        end
        s_axis = string(field_or(p, "s_axis", "y"));
        if ~(isscalar(s_axis) && any(s_axis == ["x", "y"]))
            error(msg("GUILDA:GraphChart:FieldValue", s_at + "s_axis", """x"" or ""y"""));
        end
        try
            rv_color = validatecolor(field_or(p, "rv_color", [0.85 0.33 0.10]));
        catch
            error(msg("GUILDA:GraphChart:FieldValue", s_at + "rv_color", "a color name, ""#RRGGBB"" or an RGB triplet"));
        end
        sct_refline(i) = struct("i_panel", i_panel, "s_axis", s_axis, "r_value", double(p.r_value), ...
            "s_label", string(field_or(p, "s_label", "")), "rv_color", rv_color, ...
            "s_lineStyle", string(field_or(p, "s_lineStyle", "--")));
    end

    % Store the data, then the appearance (sct_plt is empty: the setters draw nothing)
    Tag    = vertcat(strings(0, 1), c_tag{:});
    Kind   = vertcat(strings(0, 1), c_kind{:});
    Series = vertcat(zeros(0, 1), c_series{:});
    Item   = vertcat(zeros(0, 1), c_item{:});
    Panel  = vertcat(zeros(0, 1), c_panel{:});
    obj.sct_data = struct("rv_t", reshape(double(rv_t), 1, []), "s_title", s_title, "rv_grid", rv_grid, ...
        "sct_panel", sct_panel, "sct_series", sct_series, "sct_refline", sct_refline);
    obj.tab_series = table(Tag, Kind, Series, Item, Panel);
    obj.rv_t   = obj.sct_data.rv_t;
    obj.i_time = 1;
    obj.load_sample_label(sct_data);
    obj.SeriesColor      = vertcat(zeros(0, 3), c_color{:});
    obj.SeriesLabel      = vertcat(strings(0, 1), c_label{:});
    obj.SeriesLineWidth  = vertcat(zeros(0, 1), c_width{:});
    obj.SeriesMarker     = vertcat(strings(0, 1), c_marker{:});
    obj.SeriesMarkerSize = vertcat(zeros(0, 1), c_size{:});
    obj.SeriesLineStyle  = vertcat(strings(0, 1), c_style{:});
    obj.SeriesVisible    = true(height(obj.tab_series), 1);
end


function v = field_or(sct, s_field, v_default)
% The field of a struct, or a default when it is missing or empty.
    arguments (Input)
        sct (1,1) struct      % Struct to read.
        s_field (1,1) string  % Field name.
        v_default             % Value when the field is missing or empty.
    end
    arguments (Output)
        v  % The value.
    end
    v = v_default;
    if isfield(sct, s_field) && ~isempty(sct.(s_field))
        v = sct.(s_field);
    end
end


function s = size_text(x)
% Size of x as text, e.g. "3x2".
    arguments (Input)
        x  % Any value.
    end
    arguments (Output)
        s (1,1) string  % Its size.
    end
    s = join(string(size(x)), "x");
end
