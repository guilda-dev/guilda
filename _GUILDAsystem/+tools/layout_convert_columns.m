function sv_file = layout_convert_columns(s_folder)
% Convert the graph columns of earlier versions in the CSV files of model folders.
%
% Run it once on a model folder (the layout of net.export: bus/, branch/, component/) or on
% a folder that holds model folders (each folder with bus/parameter.csv below it is one).
% PowerNetwork.import reads only the new columns and stops at the old ones. The files are
% rewritten in place; the other columns stay as written. A file without old columns is
% left unchanged, so a second run changes nothing.
%
% - bus/parameter.csv: Xaxis, Yaxis, Marker -> X, Y, Shape, Length. A bar "_L" becomes
%   Shape "hbar", Length L, X = Xaxis + L/2 (its center); "|L" becomes "vbar", Length L,
%   Y = Yaxis + L/2. "s" and "o" become "square" and "circle"; other markers stay.
% - branch*/parameter.csv: MidXaxis, MidYaxis, Marker -> Path ("x1 y1; x2 y2"),
%   FromOffset, ToOffset, Style ("line"; "transformer" for a marker with "oo"). An end at
%   a bar with bend points gets the offset that the earlier drawing used (the first or last
%   bend point pushed onto the bar, from the bar center); other ends get NaN.
% - component/<key>/main.csv: Xaxis, Yaxis, Marker, MidXaxis, MidYaxis -> DX, DY, Shape,
%   Path, Offset: the position and the bend points from the (new) center of the bus, and
%   for a bus that is a bar the offset of the earlier drawing (the last bend point, else the
%   component, pushed onto the bar).
%
% Bend points with different numbers of x and y values stop with
% GUILDA:layout_convert_columns:MidPoints before the file is written.
%
% <@Examples>
% ```matlab
% sv_file = tools.layout_convert_columns("path/to/my_network");   % the files it rewrote
% net = PowerNetwork.import("path/to/my_network");
% ```
%
% See also PowerNetwork.import, PowerNetwork.get_layout
    arguments (Input)
        s_folder (1,1) string  % Model folder, or a folder with model folders below it.
    end
    arguments (Output)
        sv_file (:,1) string  % Files that were rewritten.
    end
    sv_file = strings(0, 1);
    if isfile(fullfile(s_folder, "bus", "parameter.csv"))
        sv_model = s_folder;
    else
        sct_dir  = dir(fullfile(s_folder, "**", "bus", "parameter.csv"));
        sv_model = strings(0, 1);
        for k = 1:numel(sct_dir)
            sv_model(end+1, 1) = string(fileparts(sct_dir(k).folder)); %#ok<AGROW>
        end
    end
    if isempty(sv_model)
        error(msg("GUILDA:layout_convert_columns:NoModelFolder", char(s_folder)))
    end
    fmt     = @(x) compose("%.12g", x);   % 12 digits: no rounding noise of the sums (0.06, not 0.0599999999999999)
    unquote = @(sv) replace(regexprep(sv, '^"(.*)"$', '$1'), '""', '"');
    % Bend points of a cell "[0.23,0.36]" (empty: none), as the text of each number; a cell
    % with a value that is not a number (e.g. NaN) has none, as in the earlier drawing
    get_mid = @(s) reshape(string(regexp(erase(unquote(s), ["[", "]"]), '[^,;\s]+', 'match')), [], 1);
    no_nan  = @(sv) reshape(sv(1:end * all(isfinite(str2double(sv)))), [], 1);
    sv_oldBus = ["Xaxis", "Yaxis", "Marker"];

    for s_model = reshape(sv_model, 1, [])
        % Bus: centers, shapes and lengths (new columns, from the old ones when present)
        s_file = fullfile(s_model, "bus", "parameter.csv");
        [sv_head, sm_raw, l_eol] = read_text_csv(s_file);
        n_bus = size(sm_raw, 1);
        sv_val = @(s_col, s_def) column_text(sv_head, sm_raw, s_col, s_def, unquote);
        if any(ismember(sv_oldBus, sv_head))
            sv_x   = sv_val("Xaxis", "NaN");
            sv_y   = sv_val("Yaxis", "NaN");
            sv_mk  = sv_val("Marker", "s");
            sv_sh  = sv_mk;
            rv_len = nan(n_bus, 1);
            for i = 1:n_bus
                s_mk = sv_mk(i);
                if startsWith(s_mk, ["_", "|"])
                    rv_len(i) = str2double(extractAfter(s_mk, 1));
                    if ~(isfinite(rv_len(i)) && rv_len(i) > 0)
                        error(msg("GUILDA:layout_convert_columns:UnknownMarker", char(s_file), char(string(i)), char(s_mk)))
                    end
                    if startsWith(s_mk, "_")
                        sv_sh(i) = "hbar";
                        sv_x(i)  = fmt(str2double(sv_x(i)) + rv_len(i)/2);
                    else
                        sv_sh(i) = "vbar";
                        sv_y(i)  = fmt(str2double(sv_y(i)) + rv_len(i)/2);
                    end
                end
            end
            sv_sh = replace_marker(sv_sh);
            [sv_head, sm_raw] = replace_columns(sv_head, sm_raw, sv_oldBus, ["X", "Y", "Shape", "Length"], ...
                [sv_x, sv_y, sv_sh, fmt(rv_len)]);
            write_text_csv(s_file, sv_head, sm_raw, l_eol);
            sv_file(end+1, 1) = s_file; %#ok<AGROW>
        else
            sv_x   = sv_val("X", "NaN");
            sv_y   = sv_val("Y", "NaN");
            sv_sh  = sv_val("Shape", "square");
            rv_len = str2double(sv_val("Length", "NaN"));
        end
        rm_bus = [str2double(sv_x), str2double(sv_y)];

        % Branches: every branch*/parameter.csv of the model folder (e.g. branch_origin)
        sct_dir = dir(fullfile(s_model, "branch*", "parameter.csv"));
        for k = 1:numel(sct_dir)
            s_file = string(fullfile(sct_dir(k).folder, sct_dir(k).name));
            [sv_head, sm_raw, l_eol] = read_text_csv(s_file);
            if ~any(ismember(["MidXaxis", "MidYaxis", "Marker"], sv_head))
                continue
            end
            sv_valk = @(s_col, s_def) column_text(sv_head, sm_raw, s_col, s_def, unquote);
            sv_mx  = sv_valk("MidXaxis", "");
            sv_my  = sv_valk("MidYaxis", "");
            sv_mk  = sv_valk("Marker", "-");
            rv_from = str2double(sv_valk("From", "NaN"));
            rv_to   = str2double(sv_valk("To", "NaN"));
            n_bra  = size(sm_raw, 1);
            sm_new = strings(n_bra, 4);
            for i = 1:n_bra
                sv_px = no_nan(get_mid(sv_mx(i)));
                sv_py = no_nan(get_mid(sv_my(i)));
                if numel(sv_px) ~= numel(sv_py)
                    error(msg("GUILDA:layout_convert_columns:MidPoints", char(s_file), char(string(i)), ...
                        char(string(numel(sv_px))), char(string(numel(sv_py)))))
                end
                rm_p = [str2double(sv_px), str2double(sv_py)];
                r_from = NaN;
                r_to   = NaN;
                if ~isempty(rm_p)
                    i_f    = rv_from(i);
                    i_t    = rv_to(i);
                    r_from = bar_offset(rm_bus(i_f, :), sv_sh(i_f), rv_len(i_f), rm_p(1, :));
                    r_to   = bar_offset(rm_bus(i_t, :), sv_sh(i_t), rv_len(i_t), rm_p(end, :));
                end
                if contains(sv_mk(i), "oo")
                    s_style = "transformer";
                elseif ismember(sv_mk(i), ["-", ""])
                    s_style = "line";
                else
                    error(msg("GUILDA:layout_convert_columns:UnknownMarker", char(s_file), char(string(i)), char(sv_mk(i))))
                end
                sm_new(i, :) = [strjoin(sv_px + " " + sv_py, "; "), fmt(r_from), fmt(r_to), s_style];
            end
            [sv_head, sm_raw] = replace_columns(sv_head, sm_raw, ["MidXaxis", "MidYaxis", "Marker"], ...
                ["Path", "FromOffset", "ToOffset", "Style"], sm_new);
            write_text_csv(s_file, sv_head, sm_raw, l_eol);
            sv_file(end+1, 1) = s_file; %#ok<AGROW>
        end

        % Components: positions and bend points from the bus center
        sv_oldComp = ["Xaxis", "Yaxis", "Marker", "MidXaxis", "MidYaxis"];
        sct_dir = dir(fullfile(s_model, "component", "*", "main.csv"));
        for k = 1:numel(sct_dir)
            s_file = string(fullfile(sct_dir(k).folder, sct_dir(k).name));
            [sv_head, sm_raw, l_eol] = read_text_csv(s_file);
            if ~any(ismember(sv_oldComp, sv_head))
                continue
            end
            sv_valk = @(s_col, s_def) column_text(sv_head, sm_raw, s_col, s_def, unquote);
            rv_x   = str2double(sv_valk("Xaxis", "NaN"));
            rv_y   = str2double(sv_valk("Yaxis", "NaN"));
            sv_mk  = sv_valk("Marker", "o");
            sv_mx  = sv_valk("MidXaxis", "");
            sv_my  = sv_valk("MidYaxis", "");
            iv_bus = str2double(sv_valk("Bus", "NaN"));
            n_comp = size(sm_raw, 1);
            sm_new = strings(n_comp, 5);
            for i = 1:n_comp
                if startsWith(sv_mk(i), ["_", "|"])
                    error(msg("GUILDA:layout_convert_columns:UnknownMarker", char(s_file), char(string(i)), char(sv_mk(i))))
                end
                sv_px = no_nan(get_mid(sv_mx(i)));
                sv_py = no_nan(get_mid(sv_my(i)));
                if numel(sv_px) ~= numel(sv_py)
                    error(msg("GUILDA:layout_convert_columns:MidPoints", char(s_file), char(string(i)), ...
                        char(string(numel(sv_px))), char(string(numel(sv_py)))))
                end
                rm_p   = [str2double(sv_px), str2double(sv_py)];
                i_b    = iv_bus(i);
                rv_c   = rm_bus(i_b, :);
                rv_pos = [rv_x(i), rv_y(i)];
                rm_rel = rm_p - rv_c;
                if isempty(rm_p)
                    rv_end = rv_pos;
                else
                    rv_end = rm_p(end, :);
                end
                s_path = "";
                if ~isempty(rm_rel)
                    s_path = strjoin(fmt(rm_rel(:, 1)) + " " + fmt(rm_rel(:, 2)), "; ");
                end
                sm_new(i, :) = [fmt(rv_pos(1) - rv_c(1)), fmt(rv_pos(2) - rv_c(2)), replace_marker(sv_mk(i)), ...
                                s_path, fmt(bar_offset(rv_c, sv_sh(i_b), rv_len(i_b), rv_end))];
            end
            [sv_head, sm_raw] = replace_columns(sv_head, sm_raw, sv_oldComp, ["DX", "DY", "Shape", "Path", "Offset"], sm_new);
            write_text_csv(s_file, sv_head, sm_raw, l_eol);
            sv_file(end+1, 1) = s_file; %#ok<AGROW>
        end
    end
end


function sv = replace_marker(sv)
% Short marker names of earlier versions as the shape names ("s" -> "square", "o" -> "circle").
    arguments (Input)
        sv string  % Markers.
    end
    arguments (Output)
        sv string  % Shapes.
    end
    sv(sv == "s") = "square";
    sv(sv == "o") = "circle";
end


function r_off = bar_offset(rv_c, s_shape, r_len, rv_p)
% Offset on a bar of the earlier drawing: the point pushed onto the bar, from the bar center.
    arguments (Input)
        rv_c    (1,2) double  % Center of the bus.
        s_shape (1,1) string  % Shape of the bus.
        r_len   (1,1) double  % Length of the bar.
        rv_p    (1,2) double  % Point to push onto the bar (first or last bend point, or the component).
    end
    arguments (Output)
        r_off (1,1) double  % Offset (NaN: not a bar, or the point is NaN).
    end
    switch s_shape
        case "hbar"
            i_ax = 1;
        case "vbar"
            i_ax = 2;
        otherwise
            r_off = NaN;
            return
    end
    r_off = min(max(rv_p(i_ax), rv_c(i_ax) - r_len/2), rv_c(i_ax) + r_len/2) - rv_c(i_ax);
    if isnan(rv_p(i_ax)) || isnan(rv_c(i_ax))
        r_off = NaN;
    end
end


function sv = column_text(sv_head, sm_raw, s_col, s_def, unquote)
% Values of one column as text without quotes (s_def for a missing column or an empty cell).
    arguments (Input)
        sv_head (1,:) string  % Column names.
        sm_raw  string        % Cells as written (rows x columns).
        s_col   (1,1) string  % Column name.
        s_def   (1,1) string  % Value for a missing column or an empty cell.
        unquote               % Function that removes the CSV quotes.
    end
    arguments (Output)
        sv (:,1) string  % Values.
    end
    i_col = find(sv_head == s_col, 1);
    if isempty(i_col)
        sv = repmat(s_def, size(sm_raw, 1), 1);
        return
    end
    sv = strip(unquote(sm_raw(:, i_col)));
    sv(sv == "") = s_def;
end


function [sv_head, sm_raw, l_eol] = read_text_csv(s_file)
% Header and cells of a CSV file as written (quotes kept), for a rewrite that keeps them.
    arguments (Input)
        s_file (1,1) string  % CSV file.
    end
    arguments (Output)
        sv_head (1,:) string   % Column names.
        sm_raw  string         % Cells (rows x columns).
        l_eol   (1,1) logical  % The file ends with a line break.
    end
    s_text = string(fileread(s_file));
    l_eol  = endsWith(s_text, newline);
    sv_line = split(strip(replace(s_text, sprintf("\r\n"), newline), "right", newline), newline);
    n_row  = numel(sv_line) - 1;
    c_cell = cell(n_row + 1, 1);
    for i = 1:n_row + 1
        c_tok     = regexp(sv_line(i), '(?:^|,)("(?:[^"]|"")*"|[^,]*)', 'tokens');
        c_cell{i} = string([c_tok{:}]);
    end
    sv_head = c_cell{1};
    sm_raw  = strings(n_row, numel(sv_head));
    for i = 1:n_row
        if numel(c_cell{i + 1}) ~= numel(sv_head)
            error(msg("GUILDA:layout_convert_columns:FieldCount", char(s_file), char(string(i)), ...
                char(string(numel(c_cell{i + 1}))), char(string(numel(sv_head)))))
        end
        sm_raw(i, :) = c_cell{i + 1};
    end
end


function [sv_head, sm_raw] = replace_columns(sv_head, sm_raw, sv_old, sv_new, sm_new)
% Remove the old columns and put the new ones where the first old column was.
    arguments (Input)
        sv_head (1,:) string  % Column names.
        sm_raw  string        % Cells (rows x columns).
        sv_old  (1,:) string  % Old columns (the ones in the file are removed).
        sv_new  (1,:) string  % New columns.
        sm_new  string        % Cells of the new columns (rows x numel(sv_new)).
    end
    arguments (Output)
        sv_head (1,:) string  % Column names.
        sm_raw  string        % Cells.
    end
    lv_old = ismember(sv_head, sv_old);
    i_at   = find(lv_old, 1);
    n_keep = sum(~lv_old(1:i_at - 1));
    sv_head = sv_head(~lv_old);
    sm_raw  = sm_raw(:, ~lv_old);
    sv_head = [sv_head(1:n_keep), sv_new, sv_head(n_keep + 1:end)];
    sm_raw  = [sm_raw(:, 1:n_keep), reshape(sm_new, size(sm_raw, 1), []), sm_raw(:, n_keep + 1:end)];
end


function write_text_csv(s_file, sv_head, sm_raw, l_eol)
% Write the header and the cells as they are (a Path has no comma, so it needs no quotes).
    arguments (Input)
        s_file  (1,1) string   % CSV file.
        sv_head (1,:) string   % Column names.
        sm_raw  string         % Cells (rows x columns).
        l_eol   (1,1) logical  % End the file with a line break.
    end
    sv_line = [strjoin(sv_head, ","); join(sm_raw, ",", 2)];
    s_text  = strjoin(sv_line, newline);
    if l_eol
        s_text = s_text + newline;
    end
    fid = fopen(s_file, "w");
    fprintf(fid, "%s", s_text);
    fclose(fid);
end
