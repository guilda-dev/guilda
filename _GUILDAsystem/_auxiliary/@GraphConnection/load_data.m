function load_data(obj, sct_data)
% Check the data of the diagram, lay out the blocks and the arrows and set the appearance of each element.
%
% Columns (left to right, the width of the blocks plus 1.6 apart; the buses 2.5 right of their components): the global controllers, the local controllers
% (the deepest held first), the components and the buses. Rows (1 unit apart, down):
% a tidy tree with the buses as roots; the blocks that hold none take one row each in
% the order of the data, and every other block is at the middle of the blocks it holds.
% A global controller is at the middle of the blocks its arrows join, at least one row
% from the global controller above it. Each arrow is a cubic curve with horizontal ends
% from the side of its source that faces the target to the facing side of the target; the
% ends at one side of a block are spread over its height in the order of the other ends.
    arguments (Input)
        obj
        sct_data (1,1) struct  % Data of the graph (see the class help).
    end
    sv_blockKinds = ["bus", "component", "localcontroller", "globalcontroller"];
    sv_arrowKinds = ["local", "global", "observe", "equilibrium"];

    % Fields: strings in columns, optional ones filled
    d = struct();
    for s_field = ["sv_blockTag", "sv_blockKind", "sv_blockParent", "sv_blockClass", ...
                   "sv_arrowSource", "sv_arrowTarget", "sv_arrowKind", "sv_arrowLabel"]
        if isfield(sct_data, s_field)
            sv = string(sct_data.(s_field));
            sv(ismissing(sv)) = "";
            d.(s_field) = reshape(sv, [], 1);
        elseif any(s_field == ["sv_blockClass", "sv_arrowLabel"])
            d.(s_field) = [];
        else
            error(msg("GUILDA:GraphBase:SampleLabel", s_field, "given (see the help of GraphConnection)"));
        end
    end
    n_b = numel(d.sv_blockTag);
    n_a = numel(d.sv_arrowSource);
    if isempty(d.sv_blockClass)
        d.sv_blockClass = strings(n_b, 1);
    end
    if isempty(d.sv_arrowLabel)
        d.sv_arrowLabel = strings(n_a, 1);
    end
    for s_field = ["sv_blockKind", "sv_blockParent", "sv_blockClass"]
        if numel(d.(s_field)) ~= n_b
            error(msg("GUILDA:GraphBase:SampleLabel", s_field, n_b + " texts (one per block)"));
        end
    end
    for s_field = ["sv_arrowTarget", "sv_arrowKind", "sv_arrowLabel"]
        if numel(d.(s_field)) ~= n_a
            error(msg("GUILDA:GraphBase:SampleLabel", s_field, n_a + " texts (one per arrow)"));
        end
    end
    if any(d.sv_blockTag == "") || numel(unique(d.sv_blockTag)) ~= n_b
        error(msg("GUILDA:GraphBase:SampleLabel", "sv_blockTag", "unique nonempty tags"));
    end
    if ~all(ismember(d.sv_blockKind, sv_blockKinds))
        error(msg("GUILDA:GraphBase:SampleLabel", "sv_blockKind", """" + join(sv_blockKinds, """, """) + """"));
    end
    if ~all(ismember(d.sv_arrowKind, sv_arrowKinds))
        error(msg("GUILDA:GraphBase:SampleLabel", "sv_arrowKind", """" + join(sv_arrowKinds, """, """) + """"));
    end
    l_eq = d.sv_arrowKind == "equilibrium";
    if ~all(ismember(d.sv_arrowTarget, d.sv_blockTag)) || ~all(ismember(d.sv_arrowSource(~l_eq), d.sv_blockTag)) ...
            || any(d.sv_arrowSource(l_eq) ~= "") || any(d.sv_arrowSource == d.sv_arrowTarget)
        error(msg("GUILDA:GraphBase:SampleLabel", "sv_arrowSource and sv_arrowTarget", ...
            "tags of two different blocks (the source """" for Kind ""equilibrium"")"));
    end

    % Holder of each block (0: none in the data) and depth below its bus
    [~, iv_parent] = ismember(d.sv_blockParent, d.sv_blockTag);
    iv_parent(d.sv_blockKind == "bus" | d.sv_blockKind == "globalcontroller") = 0;
    iv_depth = zeros(n_b, 1);                        % bus 0, component 1, controllers 2, 3, ...
    for i = 1:n_b
        j = i;
        n_up = 0;
        while iv_parent(j) > 0 && n_up <= n_b
            j = iv_parent(j);
            n_up = n_up + 1;
        end
        if n_up > n_b
            error(msg("GUILDA:GraphBase:SampleLabel", "sv_blockParent", "holders without a loop"));
        end
        iv_depth(i) = n_up + (d.sv_blockKind(j) == "component") + 2 * (d.sv_blockKind(j) == "localcontroller");   % a root that is not a bus keeps its level
    end
    l_lc = d.sv_blockKind == "localcontroller";
    n_lc = max([0; iv_depth(l_lc) - 1]);             % levels of local controllers
    sv_line = [d.sv_blockTag(d.sv_blockKind ~= "bus"); d.sv_blockClass(d.sv_blockKind ~= "bus")];
    r_w  = max([2.6; 0.14 * strlength(sv_line) + 0.4]);   % width of the blocks: their longest text
    r_dx = r_w + 1.6;                                % columns
    rv_x = zeros(n_b, 1);
    rv_x(d.sv_blockKind == "component") = (n_lc + 1) * r_dx;
    rv_x(d.sv_blockKind == "bus")       = (n_lc + 1) * r_dx + 2.5;
    rv_x(l_lc) = (n_lc + 2 - iv_depth(l_lc)) * r_dx;
    rv_x(d.sv_blockKind == "globalcontroller") = 0;

    % Rows: a tidy tree from the roots (the blocks without a holder, global controllers aside)
    rv_y = nan(n_b, 1);
    r_next = 1;
    l_gc = d.sv_blockKind == "globalcontroller";
    for i = find(iv_parent == 0 & ~l_gc)'
        [rv_y, r_next] = place_rows(i, iv_parent, rv_y, r_next);
    end
    iv_gc = find(l_gc);
    if ~isempty(iv_gc)
        rv_want = nan(numel(iv_gc), 1);
        for k = 1:numel(iv_gc)
            s_gc = d.sv_blockTag(iv_gc(k));
            sv_end = [d.sv_arrowTarget(d.sv_arrowSource == s_gc); d.sv_arrowSource(d.sv_arrowTarget == s_gc)];
            rv_end = rv_y(ismember(d.sv_blockTag, sv_end));
            rv_want(k) = mean(rv_end(~isnan(rv_end)));
        end
        rv_want(isnan(rv_want)) = r_next + (0:sum(isnan(rv_want)) - 1);
        [rv_want, iv_order] = sort(rv_want);
        for k = 2:numel(rv_want)
            rv_want(k) = max(rv_want(k), rv_want(k-1) + 1);
        end
        rv_y(iv_gc(iv_order)) = rv_want;
    end
    rm_xy = [rv_x, rv_y];

    % Size of each block: a bus is a narrow bar
    rm_size = repmat([r_w 0.72], n_b, 1);
    rm_size(d.sv_blockKind == "bus", :) = repmat([0.22 0.85], sum(d.sv_blockKind == "bus"), 1);

    % Ends of the arrows: the side of each block that faces the other end
    iv_src = zeros(n_a, 1);
    [~, iv_tgt] = ismember(d.sv_arrowTarget, d.sv_blockTag);
    [~, iv_src(~l_eq)] = ismember(d.sv_arrowSource(~l_eq), d.sv_blockTag);
    rm_tgtFar = rm_xy(iv_tgt, :) - [0.5 * rm_size(iv_tgt, 1) + 1.1, zeros(n_a, 1)];      % the stub of an equilibrium arrow
    rm_srcXY = rm_tgtFar;
    rm_srcXY(~l_eq, :) = rm_xy(iv_src(~l_eq), :);
    rv_dir = sign(rm_xy(iv_tgt, 1) - rm_srcXY(:, 1));                     % +1: the target is to the right
    rv_dir(rv_dir == 0) = 1;
    % per end: block, side (+1 right, -1 left), y of the other end
    iv_endBlock = [iv_src; iv_tgt];
    rv_endSide  = [rv_dir; -rv_dir];
    rv_endOther = [rm_xy(iv_tgt, 2); rm_srcXY(:, 2)];
    rv_endY     = nan(2 * n_a, 1);
    l_end = [~l_eq; true(n_a, 1)];
    for i = unique(iv_endBlock(l_end))'
        for s = [-1 1]
            iv_e = find(l_end & iv_endBlock == i & rv_endSide == s);
            if isempty(iv_e)
                continue
            end
            [~, iv_o] = sortrows([rv_endOther(iv_e), iv_e]);
            n = numel(iv_e);
            rv_endY(iv_e(iv_o)) = rm_xy(i, 2) + 0.8 * rm_size(i, 2) * ((1:n)' / (n + 1) - 0.5);
        end
    end
    rm_start = [rm_srcXY(:, 1), rv_endY(1:n_a)];
    rm_start(~l_eq, 1) = rm_start(~l_eq, 1) + rv_dir(~l_eq) .* 0.5 .* rm_size(iv_src(~l_eq), 1);
    rm_start(l_eq, 2) = rv_endY(n_a + find(l_eq));
    rm_end = [rm_xy(iv_tgt, 1) - rv_dir .* 0.5 .* rm_size(iv_tgt, 1), rv_endY(n_a + 1:end)];
    % Paths: a curve with horizontal ends; an arrow over more than one column goes through
    % the gap between the rows next to its target (a half row), along it, and curves in
    c_path  = cell(n_a, 1);
    rm_text = zeros(n_a, 2);
    r_gap = 0.5 * (r_dx - r_w);
    for k = 1:n_a
        p0 = rm_start(k, :);
        p3 = rm_end(k, :);
        if abs(p3(1) - p0(1)) > r_dx
            rv_ch = floor(p3(2)) + [0.5; -0.5];
            [~, j] = min(abs(rv_ch - p0(2)));
            r_ch = rv_ch(j) + 0.08 * rv_dir(k);                % the two directions side by side
            pa = [p0(1) + rv_dir(k) * r_gap, r_ch];
            pb = [p3(1) - rv_dir(k) * r_gap, r_ch];
            rm_in = curve(pb, p3, rv_dir(k));
            c_path{k} = [curve(p0, pa, rv_dir(k)); rm_in];
        else
            rm_in = curve(p0, p3, rv_dir(k));
            c_path{k} = rm_in;
        end
        rm_text(k, :) = rm_in(ceil(end / 2), :);
        if l_eq(k)                                      % the label of a stub at its free end
            rm_text(k, :) = p0;
        end
    end

    % Element tags of the arrows
    sv_srcTag = d.sv_arrowSource;
    sv_srcTag(l_eq) = "(equilibrium)";
    d.sv_arrowTag = sv_srcTag + "->" + d.sv_arrowTarget;
    d.rm_blockXY   = rm_xy;
    d.rm_blockSize = rm_size;
    d.c_arrowPath  = c_path;
    d.rm_arrowText = rm_text;
    d.s_title = "";
    if isfield(sct_data, "s_title") && ~isempty(sct_data.s_title)
        d.s_title = string(sct_data.s_title);
    end
    if ~(isscalar(d.s_title) && ~ismissing(d.s_title))
        error(msg("GUILDA:GraphBase:SampleLabel", "s_title", "one text"));
    end

    % Store the data, then the appearance (sct_plt is empty: the setters draw nothing)
    obj.sct_data = d;
    obj.rv_t   = 0;
    obj.i_time = 1;
    obj.load_sample_label(struct());
    rm_blockColor = [0.1 0.1 0.1; 0.25 0.25 0.25; [17 113 190] / 255; [221 84 0] / 255];   % by sv_blockKinds (gem colors)
    rm_arrowColor = [[17 113 190] / 255; [221 84 0] / 255; [59 170 50] / 255; 0.6 0.6 0.6];  % by sv_arrowKinds
    sv_arrowStyle = ["-"; "-"; "--"; ":"];
    [~, iv_bk] = ismember(d.sv_blockKind, sv_blockKinds);
    [~, iv_ak] = ismember(d.sv_arrowKind, sv_arrowKinds);
    obj.BlockColor     = rm_blockColor(iv_bk, :);
    obj.BlockLabel     = d.sv_blockTag;
    obj.BlockLineWidth = 1 + 0.5 * (d.sv_blockKind ~= "bus");
    obj.ArrowColor     = rm_arrowColor(iv_ak, :);
    obj.ArrowLabel     = d.sv_arrowLabel;
    obj.ArrowLineWidth = 1 + 0.3 * (d.sv_arrowKind == "global");
    obj.ArrowLineStyle = sv_arrowStyle(iv_ak);
end


function [rv_y, r_next] = place_rows(i, iv_parent, rv_y, r_next)
% Rows of block i and of the blocks it holds: a leaf takes the next row, a holder the middle of its blocks.
    arguments (Input)
        i (1,1) double              % Block.
        iv_parent (:,1) double      % Holder of each block (0: none).
        rv_y (:,1) double           % Rows so far (NaN: not placed).
        r_next (1,1) double         % Next free row.
    end
    arguments (Output)
        rv_y (:,1) double           % Rows with block i and its blocks placed.
        r_next (1,1) double         % Next free row.
    end
    iv_child = find(iv_parent == i);
    if isempty(iv_child)
        rv_y(i) = r_next;
        r_next = r_next + 1;
        return
    end
    for j = iv_child'
        [rv_y, r_next] = place_rows(j, iv_parent, rv_y, r_next);
    end
    rv_y(i) = (min(rv_y(iv_child)) + max(rv_y(iv_child))) / 2;
end


function rm_p = curve(p0, p3, r_dir)
% Points of a cubic curve from p0 to p3 with horizontal ends, heading in the direction r_dir (+1 right, -1 left).
    arguments (Input)
        p0 (1,2) double     % Start point.
        p3 (1,2) double     % End point.
        r_dir (1,1) double  % +1: to the right; -1: to the left.
    end
    arguments (Output)
        rm_p (:,2) double   % Points of the curve (21 x 2).
    end
    rv_s = linspace(0, 1, 21)';
    r_c = max(0.45 * abs(p3(1) - p0(1)), 0.4);
    p1 = p0 + [r_dir * r_c, 0];
    p2 = p3 - [r_dir * r_c, 0];
    rm_p = (1 - rv_s).^3 * p0 + 3 * (1 - rv_s).^2 .* rv_s * p1 + 3 * (1 - rv_s) .* rv_s.^2 * p2 + rv_s.^3 * p3;
end
