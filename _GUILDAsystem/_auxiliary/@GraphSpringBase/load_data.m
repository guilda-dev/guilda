function load_data(obj, sct_data)
% Check the data of the picture, fill the optional fields and set the appearance of each element.
    arguments (Input)
        obj
        sct_data (1,1) struct  % Data of the picture (see the class help).
    end
    sv_required = ["rv_t", "sv_node", "sv_kind", "cm_V", "im_edge"];
    for s_field = sv_required
        if ~isfield(sct_data, s_field)
            error(msg("GUILDA:GraphSpringBase:MissingField", s_field));
        end
    end
    rv_t = sct_data.rv_t;
    if ~(isnumeric(rv_t) && isreal(rv_t) && isvector(rv_t) && all(isfinite(rv_t)) && all(diff(rv_t) >= 0))
        error(msg("GUILDA:GraphSpringBase:FieldValue", "rv_t", "finite nondecreasing real times"));
    end
    sv_node = string(sct_data.sv_node(:));
    n_node  = numel(sv_node);
    n_t     = numel(rv_t);
    sv_kind = string(sct_data.sv_kind(:));
    if numel(sv_kind) ~= n_node
        error(msg("GUILDA:GraphSpringBase:FieldSize", "sv_kind", n_node + "x1", size_text(sct_data.sv_kind)));
    end
    if ~all(ismember(sv_kind, ["bus", "component"]))
        error(msg("GUILDA:GraphSpringBase:FieldValue", "sv_kind", """bus"" or ""component"""));
    end
    cm_V = sct_data.cm_V;
    if ~isnumeric(cm_V) || ~isequal(size(cm_V), [n_node, n_t])
        error(msg("GUILDA:GraphSpringBase:FieldSize", "cm_V", n_node + "x" + n_t, size_text(cm_V)));
    end
    im_edge = sct_data.im_edge;
    if isempty(im_edge)
        im_edge = zeros(2, 0);
    end
    if size(im_edge, 1) ~= 2
        error(msg("GUILDA:GraphSpringBase:FieldSize", "im_edge", "2xn_edge", size_text(im_edge)));
    end
    if ~is_index(im_edge, n_node)
        error(msg("GUILDA:GraphSpringBase:FieldValue", "im_edge", "node indices from 1 to " + n_node));
    end
    n_edge = size(im_edge, 2);

    % Optional fields: their size, then the defaults
    sct_default = struct( ...
        "sv_edge",   strings(n_edge, 1), ...
        "iv_arrow",  zeros(0, 1), ...
        "sv_marker", repmat("o", n_node, 1), ...
        "rv_size",   nan(n_node, 1), ...
        "sv_color",  strings(n_node, 1), ...
        "rv_circle", nan(n_node, 1));
    for s_field = string(fieldnames(sct_default))'
        if ~isfield(sct_data, s_field) || isempty(sct_data.(s_field))
            sct_data.(s_field) = sct_default.(s_field);
        end
        n_need = numel(sct_default.(s_field));
        if s_field ~= "iv_arrow" && numel(sct_data.(s_field)) ~= n_need
            error(msg("GUILDA:GraphSpringBase:FieldSize", s_field, n_need + "x1", size_text(sct_data.(s_field))));
        end
    end
    sv_edge = string(sct_data.sv_edge(:));
    sv_edge(ismissing(sv_edge) | sv_edge == "") = "E" + find(ismissing(sv_edge) | sv_edge == "");
    iv_arrow = sct_data.iv_arrow(:);
    if ~is_index(iv_arrow, n_node)
        error(msg("GUILDA:GraphSpringBase:FieldValue", "iv_arrow", "node indices from 1 to " + n_node));
    end
    n_arrow = numel(iv_arrow);
    for s_field = ["rm_P", "rm_Iq"]
        if ~isfield(sct_data, s_field) || n_arrow == 0 && isempty(sct_data.(s_field))
            sct_data.(s_field) = zeros(n_arrow, n_t);
        end
        if ~(isnumeric(sct_data.(s_field)) && isreal(sct_data.(s_field))) || ~isequal(size(sct_data.(s_field)), [n_arrow, n_t])
            error(msg("GUILDA:GraphSpringBase:FieldSize", s_field, "real " + n_arrow + "x" + n_t, size_text(sct_data.(s_field))));
        end
    end

    % Defaults by kind: bus small and black, component larger and blue
    l_bus   = sv_kind == "bus";
    rv_size = double(sct_data.rv_size(:));
    rv_size(isnan(rv_size) &  l_bus) = 5;
    rv_size(isnan(rv_size) & ~l_bus) = 15;
    sv_color = string(sct_data.sv_color(:));
    sv_color(ismissing(sv_color)) = "";
    rm_color = zeros(n_node, 3);
    rm_color(~l_bus, :) = repmat([0 0.447 0.741], nnz(~l_bus), 1);
    for i_node = find(sv_color ~= "")'
        try
            rm_color(i_node, :) = validatecolor(sv_color(i_node));
        catch
            error(msg("GUILDA:GraphSpringBase:FieldValue", "sv_color", "a color name or ""#RRGGBB"", not """ + sv_color(i_node) + """"));
        end
    end
    sv_marker = string(sct_data.sv_marker(:));
    sv_marker(ismissing(sv_marker) | sv_marker == "") = "o";

    sct_new = struct( ...
        "rv_t",      reshape(double(rv_t), 1, []), ...
        "sv_node",   sv_node, ...
        "sv_kind",   sv_kind, ...
        "cm_V",      double(cm_V), ...
        "im_edge",   double(im_edge), ...
        "sv_edge",   sv_edge, ...
        "iv_arrow",  double(iv_arrow), ...
        "rm_P",      double(sct_data.rm_P), ...
        "rm_Iq",     double(sct_data.rm_Iq), ...
        "rv_circle", double(sct_data.rv_circle(:)));
    if ~any(l_bus)
        l_bus(:) = true;
    end
    obj.sct_data     = sct_new;
    obj.rv_t         = sct_new.rv_t;
    obj.i_time       = 1;
    obj.load_sample_label(sct_data);
    obj.rv_angleMean = mean(unwrap(angle(sct_new.cm_V(l_bus, :)), [], 2), 1);

    % Appearance of each element from the data (the 3D springs are a little thicker)
    obj.NodeColor     = rm_color;
    obj.NodeLabel     = sv_node;
    obj.NodeSize      = rv_size;
    obj.NodeMarker    = sv_marker;
    obj.NodeVisible   = true(n_node, 1);
    obj.EdgeColor     = zeros(n_edge, 3);
    obj.EdgeLineWidth = repmat(0.8 + 0.2*isa(obj, "GraphSpring3D"), n_edge, 1);
    obj.EdgeVisible   = true(n_edge, 1);
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


function l = is_index(x, n)
% True when x holds only integer indices from 1 to n.
    arguments (Input)
        x               % Values to check.
        n (1,1) double  % Largest index.
    end
    arguments (Output)
        l (1,1) logical  % True for valid indices.
    end
    l = isnumeric(x) && all(x(:) == round(x(:))) && all(x(:) >= 1 & x(:) <= n);
end
