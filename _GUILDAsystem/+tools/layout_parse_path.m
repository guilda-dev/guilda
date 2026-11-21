function rm_xy = layout_parse_path(s_path, opt)
% Return the points of a Path text of the graph parameters as an n x 2 matrix.
%
% A Path is "x y; x y": the points are separated by ";", the two coordinates of a point
% by spaces. A text that is empty apart from spaces has no point (a 0 x 2 matrix). Any
% other text whose points are not two finite numbers each stops with
% GUILDA:layout_parse_path:InvalidPath. The model checks (Bus, Branch, Component and
% tools.layout_mustBePath) and the network diagrams use this function.
%
% <@Examples>
% ```matlab
% tools.layout_parse_path("0.23 0.5; 0.36 0.33")   % [0.23 0.5; 0.36 0.33]
% tools.layout_parse_path("")                      % zeros(0, 2)
% ```
%
% See also tools.layout_mustBePath, PowerNetwork.set_layout
    arguments (Input)
        s_path      (1,1) string       % Path text, e.g. "0.23 0.5; 0.36 0.33".
        opt.Context (1,1) string = ""  % Where the text comes from, put in front of the error message (e.g. "Branch001: ").
    end
    arguments (Output)
        rm_xy (:,2) double  % Points, one row per point: [x, y].
    end
    if ismissing(s_path) || strip(s_path) == ""
        rm_xy = zeros(0, 2);
        return
    end
    sv_point = strip(split(s_path, ";"));
    rm_xy    = nan(numel(sv_point), 2);
    for i = 1:numel(sv_point)
        sv_num = split(sv_point(i));
        sv_num = sv_num(sv_num ~= "");
        rv_xy  = str2double(sv_num);
        if numel(rv_xy) ~= 2 || ~all(isfinite(rv_xy))
            error(msg("GUILDA:layout_parse_path:InvalidPath", char(opt.Context), char(s_path), char(sv_point(i))))
        end
        rm_xy(i, :) = rv_xy;
    end
end
