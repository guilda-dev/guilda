function load_data(obj, sct_data)
% Check the data of the matrix, fill the optional fields, find the groups and set the appearance of each element.
%
% The elements are the groups of rows, then the groups of columns, each in the order of
% its first row or column. The blocks of a group are its runs of adjacent rows (columns),
% as [first last] rows.
    arguments (Input)
        obj
        sct_data (1,1) struct  % Data of the graph (see the class help).
    end
    % Matrices and times
    if ~isfield(sct_data, "c_matrix")
        error(msg("GUILDA:GraphMatrix:MissingField", "c_matrix"));
    end
    c_matrix = sct_data.c_matrix;
    if ~(iscell(c_matrix) && ~isempty(c_matrix))
        error(msg("GUILDA:GraphMatrix:FieldValue", "c_matrix", "a 1 x n_t cell of matrices (at least one sample)"));
    end
    c_matrix = reshape(c_matrix, 1, []);
    n_t = numel(c_matrix);
    if isfield(sct_data, "rv_t") && ~isempty(sct_data.rv_t)
        rv_t = sct_data.rv_t;
    elseif n_t == 1
        rv_t = 0;
    else
        error(msg("GUILDA:GraphMatrix:MissingField", "rv_t"));
    end
    if ~(isnumeric(rv_t) && isreal(rv_t) && isvector(rv_t) && all(isfinite(rv_t)) && all(diff(rv_t) >= 0))
        error(msg("GUILDA:GraphMatrix:FieldValue", "rv_t", "finite nondecreasing real times"));
    end
    if numel(rv_t) ~= n_t
        error(msg("GUILDA:GraphMatrix:FieldSize", "rv_t", "1x" + n_t + " (one time per matrix)", join(string(size(rv_t)), "x")));
    end

    % Names and groups of the rows and columns
    sct_name = struct();
    for s_field = ["sv_rowName", "sv_colName", "sv_rowGroup", "sv_colGroup"]
        if ~isfield(sct_data, s_field)
            error(msg("GUILDA:GraphMatrix:MissingField", s_field));
        end
        sv = string(sct_data.(s_field));
        sv(ismissing(sv)) = "";
        sct_name.(s_field) = reshape(sv, [], 1);
    end
    n_row = numel(sct_name.sv_rowName);
    n_col = numel(sct_name.sv_colName);
    for s_field = ["sv_rowGroup", "sv_colGroup"]
        n = n_row;
        if s_field == "sv_colGroup"
            n = n_col;
        end
        sv = sct_name.(s_field);
        if numel(sv) ~= n || any(sv == "")
            error(msg("GUILDA:GraphMatrix:FieldSize", s_field, n + "x1 nonempty group tags", numel(sv) + "x1"));
        end
    end
    for k = 1:n_t
        M = c_matrix{k};
        if ~((isnumeric(M) || islogical(M)) && isreal(M) && ismatrix(M))
            error(msg("GUILDA:GraphMatrix:FieldValue", "c_matrix{" + k + "}", "a real matrix"));
        end
        if ~isequal(size(M), [n_row n_col])
            error(msg("GUILDA:GraphMatrix:FieldSize", "c_matrix{" + k + "}", n_row + "x" + n_col + ...
                " (the names of the rows and columns)", join(string(size(M)), "x")));
        end
        c_matrix{k} = double(M);
    end

    % Elements: the groups of rows, then the groups of columns, with their blocks
    sv_tag  = strings(0, 1);
    sv_kind = strings(0, 1);
    c_block = cell(0, 1);
    for s_kind = ["rowgroup", "colgroup"]
        sv_group = sct_name.sv_rowGroup;
        if s_kind == "colgroup"
            sv_group = sct_name.sv_colGroup;
        end
        for s_tag = unique(sv_group, "stable")'
            l = sv_group == s_tag;
            sv_tag(end+1, 1)  = s_tag; %#ok<AGROW>
            sv_kind(end+1, 1) = s_kind; %#ok<AGROW>
            c_block{end+1, 1} = [find(l & [true; ~l(1:end-1)]), find(l & [~l(2:end); true])]; %#ok<AGROW>
        end
    end

    % Store the data, then the appearance (sct_plt is empty: the setters draw nothing)
    sct = sct_name;
    sct.rv_t     = reshape(double(rv_t), 1, []);
    sct.c_matrix = c_matrix;
    for s_field = ["s_title", "s_rowLabel", "s_colLabel"]
        s = "";
        if isfield(sct_data, s_field) && ~isempty(sct_data.(s_field))
            s = string(sct_data.(s_field));
        end
        if ~(isscalar(s) && ~ismissing(s))
            error(msg("GUILDA:GraphMatrix:FieldValue", s_field, "one text"));
        end
        sct.(s_field) = s;
    end
    s_pattern = "dot";
    if isfield(sct_data, "s_pattern") && ~isempty(sct_data.s_pattern)
        s_pattern = string(sct_data.s_pattern);
    end
    if ~(isscalar(s_pattern) && ismember(s_pattern, ["dot", "circle"]))
        error(msg("GUILDA:GraphMatrix:FieldValue", "s_pattern", """dot"" or ""circle"""));
    end
    sct.s_pattern = s_pattern;
    for s_field = ["l_frame", "l_valueText", "l_groupTicks", "l_cellGrid"]
        l = false;
        if isfield(sct_data, s_field) && ~isempty(sct_data.(s_field))
            l = sct_data.(s_field);
        end
        if ~((islogical(l) || isnumeric(l)) && isscalar(l))
            error(msg("GUILDA:GraphMatrix:FieldValue", s_field, "true or false"));
        end
        sct.(s_field) = logical(l);
    end
    sct.sv_tag  = sv_tag;
    sct.sv_kind = sv_kind;
    sct.c_block = c_block;
    obj.sct_data      = sct;
    obj.sct_limitAuto = struct.empty;
    obj.rv_t   = sct.rv_t;
    obj.i_time = 1;
    obj.load_sample_label(sct_data);
    n_elem = numel(sv_tag);
    obj.SeparatorColor     = repmat([0.6 0.6 0.6], n_elem, 1);
    obj.SeparatorLineWidth = repmat(0.5, n_elem, 1);
end
