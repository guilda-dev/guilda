function load_data(obj, sct_data)
% Check the data of the map (see the class help), store it and set the appearance defaults.
%
% Buses without a position (NaN rows of rm_xy) take the position drawn before for the same
% tag, when the map had earlier data; the others are placed by tools.layout_place_buses
% (with rv_length and c_path when given). The buses with a position never move. The size
% of the flow of a branch is the larger |P| (|Q|) of its two ends (NaN for Arrow "none");
% apply_style maps it onto BranchWidthRange.
    arguments (Input)
        obj
        sct_data (1,1) struct  % Data of the map (see the class help).
    end
    sv_field = ["sv_bus", "rm_xy", "cv_V", "sv_branch", "im_end", "rm_P", "rm_Q", "s_color", "s_arrow"];
    sv_miss  = sv_field(~isfield(sct_data, sv_field));
    if ~isempty(sv_miss)
        error(msg("GUILDA:GraphNetMap:MissingField", join(sv_miss, ", ")));
    end
    sv_bus = string(sct_data.sv_bus(:));
    sv_br  = string(sct_data.sv_branch(:));
    n_bus  = numel(sv_bus);
    n_br   = numel(sv_br);
    sct_size = struct("rm_xy", [n_bus 2], "cv_V", [n_bus 1], "im_end", [n_br 2], "rm_P", [n_br 2], "rm_Q", [n_br 2]);
    for s_f = string(fieldnames(sct_size))'
        x = sct_data.(s_f);
        if ~isnumeric(x) || ~isequal(size(x), sct_size.(s_f))
            error(msg("GUILDA:GraphNetMap:DataSize", s_f, join(string(sct_size.(s_f)), "x"), join(string(size(x)), "x")));
        end
    end
    im_end = double(sct_data.im_end);
    if ~all(ismember(im_end(:), 1:n_bus))
        error(msg("GUILDA:GraphNetMap:DataValue", "im_end", "rows of sv_bus (1 to " + n_bus + ")"));
    end
    s_color = string(sct_data.s_color);
    s_arrow = string(sct_data.s_arrow);
    if ~(isscalar(s_color) && any(s_color == ["V", "angle"]))
        error(msg("GUILDA:GraphNetMap:DataValue", "s_color", """V"" or ""angle"""));
    end
    if ~(isscalar(s_arrow) && any(s_arrow == ["P", "Q", "none"]))
        error(msg("GUILDA:GraphNetMap:DataValue", "s_arrow", """P"", ""Q"" or ""none"""));
    end

    % Buses without a position keep the one drawn before (same tag), else are placed
    rm_xy = double(sct_data.rm_xy);
    l_nan = any(isnan(rm_xy), 2);
    if any(l_nan) && isstruct(obj.sct_data)
        [l_old, i_old] = ismember(sv_bus, obj.sct_data.sv_bus);
        l_fill = l_nan & l_old;
        rm_xy(l_fill, :) = obj.sct_data.rm_xy(i_old(l_fill), :);
    end
    rv_len = [];
    c_path = {};
    if isfield(sct_data, "rv_length")
        rv_len = double(sct_data.rv_length(:));
    end
    if isfield(sct_data, "c_path")
        c_path = sct_data.c_path(:);
    end
    rm_xy = tools.layout_place_buses(rm_xy, im_end, Length=rv_len, Path=c_path);

    switch s_arrow
        case "P"; rm_flow = double(sct_data.rm_P);
        case "Q"; rm_flow = double(sct_data.rm_Q);
        otherwise; rm_flow = zeros(n_br, 2);
    end
    rv_mag = max(abs(rm_flow), [], 2);
    if s_arrow == "none"
        rv_mag = nan(n_br, 1);
    end

    obj.sct_data = struct("sv_bus", sv_bus, "rm_xy", rm_xy, "cv_V", double(sct_data.cv_V), ...
        "sv_branch", sv_br, "im_end", im_end, "rm_P", double(sct_data.rm_P), "rm_Q", double(sct_data.rm_Q), ...
        "s_color", s_color, "s_arrow", s_arrow, "rm_flow", rm_flow, "rv_flowMag", rv_mag);
    obj.rv_t   = 0;
    obj.i_time = 1;

    % Defaults of the appearance
    obj.BusColor        = nan(n_bus, 3);
    obj.BusLabel        = sv_bus;
    obj.BusMarkerSize   = 6 * ones(n_bus, 1);
    obj.BusMarker       = repmat("o", n_bus, 1);
    obj.BranchColor     = nan(n_br, 3);
    obj.BranchLineWidth = nan(n_br, 1);
    obj.BranchLineStyle = repmat("-", n_br, 1);
end
