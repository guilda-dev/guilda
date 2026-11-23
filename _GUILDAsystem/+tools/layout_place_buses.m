function [rm_xy, d0] = layout_place_buses(rm_xy, im_edge, opt)
% Place the buses without a position near their neighbours; the buses with one never move.
%
% The rows of rm_xy with a NaN are the buses without a position. The others (the set P)
% keep their values exactly. The length scale d0 is the median distance between the
% centers of the branches whose two buses are in P (else 0.1 times the longer side of the
% bounding box of P, else 0.1). Then:
%
% 1. The buses connected to P are placed in breadth-first order from P (by the number of
%    steps from P, then by row): each at one of 8 points at 0.5*d0 around the mean of its
%    placed neighbours (k = 0..7, angle 2*pi*k/8, k = 0 to the right), the point farthest
%    from the placed buses (a bar as a segment) and the branch lines between placed buses
%    (with their Path); a tie takes the smallest k.
% 2. The buses not connected to P are put in a column right of the bounding box, from its
%    top: an isolated bus at one point each (d0 apart), a group of connected buses in its
%    breadth-first layers from its first bus (layers d0 apart to the right, the buses of a
%    layer d0 apart downward) with a gap of d0 after it.
% 3. The buses of step 1 only relax for up to Iteration steps under springs of length d0
%    to their neighbours and a repulsion (within d0/2) from the other buses and from the
%    branch lines that do not end at them. A step is StepSize times the force, at most
%    StepSize*d0 long; the relaxation stops when every step is below 1e-6*d0.
%
% When no bus has a position, every bus takes the "force" layout of MATLAB (a graph plot
% in a figure that is not shown; the layouts of the last graphs are kept, so drawing the
% same network again makes no figure) and d0 comes from that layout. No random number is used:
% the same input gives the same output. Parallel branches count once. GraphNetDiagram places
% the buses with this function; the positions stay in the graph.
%
% <@Examples>
% ```matlab
% rm_xy = [0 0; 1 0; NaN NaN];
% rm_xy = tools.layout_place_buses(rm_xy, [1 2; 2 3]);   % bus 3 near bus 2
% ```
%
% See also GraphNetDiagram, PowerNetwork.set_layout
    arguments (Input)
        rm_xy (:,2) double                 % Bus centers [x, y]; a row with a NaN: no position.
        im_edge (:,2) double               % Rows in rm_xy of the "from" and "to" buses of each branch.
        opt.Length (:,1) double = []       % Bar length of each bus: positive for a horizontal bar, negative for a vertical one, NaN for a point ([]: all points).
        opt.Path (:,1) cell = {}           % Bend points (m x 2) of each branch ({}: none).
        opt.Iteration (1,1) double {mustBeInteger, mustBeNonnegative} = 50  % Largest number of relaxation steps (step 3).
        opt.StepSize (1,1) double {mustBePositive} = 0.1                   % Step size of the relaxation (step 3).
    end
    arguments (Output)
        rm_xy (:,2) double  % Bus centers, all finite; the rows given are unchanged.
        d0 (1,1) double     % Length scale of the layout (see above).
    end
    persistent m_force                      % force layouts already made (see below)
    n_bus = size(rm_xy, 1);
    n_br  = size(im_edge, 1);
    rv_len = opt.Length;
    if isempty(rv_len)
        rv_len = nan(n_bus, 1);
    end
    c_path = opt.Path;
    if isempty(c_path)
        c_path = repmat({zeros(0, 2)}, n_br, 1);
    end
    lv_fix = all(isfinite(rm_xy), 2);

    % Neighbours (parallel branches and loops count once)
    im_pair = unique(sort(im_edge(im_edge(:, 1) ~= im_edge(:, 2), :), 2), "rows");
    a_nb = cell(n_bus, 1);
    for i = 1:n_bus
        a_nb{i} = sort([im_pair(im_pair(:, 1) == i, 2); im_pair(im_pair(:, 2) == i, 1)])';
    end

    if ~any(lv_fix)
        if n_bus > 0
            % A figure takes about 0.2 s (more for the first one of a session), and the
            % layout is deterministic: the positions of the last graphs (at most 20) are kept
            if isempty(m_force) || m_force.Count > 20
                m_force = containers.Map("KeyType", "char", "ValueType", "any");
            end
            s_key = sprintf("%d;", n_bus, im_pair');
            if isKey(m_force, s_key)
                rm_xy = m_force(s_key);
            else
                G      = graph(im_pair(:, 1), im_pair(:, 2), [], n_bus);
                fig    = figure("Visible", "off");
                h_temp = plot(axes(fig), G, "Layout", "force", "UseGravity", true, "Iterations", 100);
                rm_xy  = [h_temp.XData(:), h_temp.YData(:)];
                close(fig);
                m_force(s_key) = rm_xy;
            end
        end
        d0 = length_scale(rm_xy, true(n_bus, 1), im_pair);
        return
    end
    d0 = length_scale(rm_xy, lv_fix, im_pair);
    if all(lv_fix)
        return
    end

    % Step 1: breadth-first from P
    lv_placed = lv_fix;
    iv_order  = zeros(1, 0);
    iv_level  = find(lv_fix)';
    lv_seen   = lv_fix;
    while ~isempty(iv_level)
        iv_next = unique([a_nb{iv_level}]);
        iv_next = iv_next(~lv_seen(iv_next));
        lv_seen(iv_next) = true;
        iv_order = [iv_order, iv_next]; %#ok<AGROW>
        iv_level = iv_next;
    end
    rv_angle = 2*pi*(0:7)'/8;
    for i = iv_order
        iv_n = a_nb{i}(lv_placed(a_nb{i}));
        rv_c = mean(rm_xy(iv_n, :), 1);
        rm_cand = rv_c + 0.5*d0*[cos(rv_angle), sin(rv_angle)];
        [rm_a, rm_b] = obstacle_segments(rm_xy, rv_len, lv_placed, im_edge, c_path, true(n_br, 1));
        rv_dist = inf(8, 1);
        for k = 1:8
            rv_dist(k) = min([inf; segment_distance(rm_cand(k, :), rm_a, rm_b)]);
        end
        [~, k_best] = max(rv_dist);                        % the first of equal values: smallest k
        rm_xy(i, :) = rm_cand(k_best, :);
        lv_placed(i) = true;
    end
    lv_free = lv_placed & ~lv_fix;                          % F: moved in step 3

    % Step 2: buses not connected to P, in a column right of the bounding box
    iv_rest = find(~lv_placed)';
    if ~isempty(iv_rest)
        [rm_a, rm_b] = obstacle_segments(rm_xy, rv_len, lv_placed, zeros(0, 2), {}, false(0, 1));
        rm_end = [rm_a; rm_b];
        x_col  = max(rm_end(:, 1)) + d0;
        y      = max(rm_end(:, 2));
        while ~isempty(iv_rest)
            iv_layer = iv_rest(1);
            lv_in    = false(n_bus, 1);
            lv_in(iv_layer) = true;
            c_layer  = {};
            while ~isempty(iv_layer)
                c_layer{end+1} = iv_layer; %#ok<AGROW>
                iv_next = unique([a_nb{iv_layer}]);
                iv_layer = iv_next(~lv_in(iv_next));
                lv_in(iv_layer) = true;
            end
            for m = 1:numel(c_layer)
                iv = c_layer{m};
                rm_xy(iv, :) = [repmat(x_col + (m-1)*d0, numel(iv), 1), y - (0:numel(iv)-1)'*d0];
            end
            n_row = max(cellfun(@numel, c_layer));
            if numel(c_layer) == 1
                y = y - d0;                                    % an isolated bus
            else
                y = y - (n_row + 1)*d0;                        % a gap of d0 after a group
            end
            iv_rest = iv_rest(~lv_in(iv_rest));
        end
    end

    % Step 3: relax the buses of step 1 only
    iv_free = find(lv_free)';
    r = d0/2;
    for it = 1:opt.Iteration
        rm_step = zeros(numel(iv_free), 2);
        for m = 1:numel(iv_free)
            i    = iv_free(m);
            p    = rm_xy(i, :);
            rv_f = [0 0];
            for j = a_nb{i}                                    % springs
                rv_d = rm_xy(j, :) - p;
                rv_f = rv_f + (norm(rv_d) - d0) * unit(rv_d, i, d0);
            end
            lv_other = true(n_bus, 1);
            lv_other(i) = false;
            [rm_a, rm_b] = obstacle_segments(rm_xy, rv_len, lv_other, zeros(0, 2), {}, false(0, 1));
            for k = 1:size(rm_a, 1)                             % other buses
                rv_f = rv_f + repulsion(p, rm_a(k, :), rm_b(k, :), r, i, d0);
            end
            lv_line = ~any(im_edge == i, 2);
            for k = find(lv_line)'                              % lines not ending at i
                [rm_a, rm_b] = obstacle_segments(rm_xy, rv_len, false(n_bus, 1), im_edge, c_path, (1:n_br)' == k);
                if isempty(rm_a)
                    continue
                end
                [~, i_min] = min(segment_distance(p, rm_a, rm_b));
                rv_f = rv_f + repulsion(p, rm_a(i_min, :), rm_b(i_min, :), r, i, d0);
            end
            rv_step = opt.StepSize * rv_f;
            r_step  = norm(rv_step);
            if r_step > opt.StepSize * d0
                rv_step = rv_step * (opt.StepSize * d0 / r_step);
            end
            rm_step(m, :) = rv_step;
        end
        rm_xy(iv_free, :) = rm_xy(iv_free, :) + rm_step;
        if all(vecnorm(rm_step, 2, 2) < 1e-6 * d0)
            break
        end
    end
end


function d0 = length_scale(rm_xy, lv_fix, im_pair)
% Median length of the branches between buses of the set, else 0.1 times its box, else 0.1.
    arguments (Input)
        rm_xy (:,2) double       % Bus centers.
        lv_fix (:,1) logical     % Buses of the set.
        im_pair (:,2) double     % Branches (distinct pairs).
    end
    arguments (Output)
        d0 (1,1) double  % Length scale.
    end
    lv_br = lv_fix(im_pair(:, 1)) & lv_fix(im_pair(:, 2));
    rv_l  = vecnorm(rm_xy(im_pair(lv_br, 1), :) - rm_xy(im_pair(lv_br, 2), :), 2, 2);
    d0 = 0;
    if ~isempty(rv_l)
        d0 = median(rv_l);
    end
    if ~(d0 > 0) && any(lv_fix)
        d0 = 0.1 * max(max(rm_xy(lv_fix, :), [], 1) - min(rm_xy(lv_fix, :), [], 1));
    end
    if ~(d0 > 0)
        d0 = 0.1;
    end
end


function [rm_a, rm_b] = obstacle_segments(rm_xy, rv_len, lv_bus, im_edge, c_path, lv_branch)
% Segments of the buses lv_bus (a bar as its segment, a point as a zero segment) and of the branch lines lv_branch.
    arguments (Input)
        rm_xy (:,2) double        % Bus centers.
        rv_len (:,1) double       % Signed bar lengths (see Length).
        lv_bus (:,1) logical      % Buses to include.
        im_edge (:,2) double      % End buses of each branch.
        c_path (:,1) cell         % Bend points of each branch.
        lv_branch (:,1) logical   % Branches to include (their two buses must have positions).
    end
    arguments (Output)
        rm_a (:,2) double  % Start of each segment.
        rm_b (:,2) double  % End of each segment.
    end
    rm_c = rm_xy(lv_bus, :);
    rv_l = rv_len(lv_bus);
    rv_l(~isfinite(rv_l)) = 0;
    rm_h = [max(rv_l, 0), -min(rv_l, 0)] / 2;               % half length along x (hbar) or y (vbar)
    rm_a = rm_c - rm_h;
    rm_b = rm_c + rm_h;
    for k = find(lv_branch(:))'
        rm_p = [rm_xy(im_edge(k, 1), :); c_path{k}; rm_xy(im_edge(k, 2), :)];
        if any(isnan(rm_p(:)))
            continue
        end
        rm_a = [rm_a; rm_p(1:end-1, :)]; %#ok<AGROW>
        rm_b = [rm_b; rm_p(2:end, :)]; %#ok<AGROW>
    end
end


function rv_s = segment_distance(p, rm_a, rm_b)
% Distance from the point p to each segment [a, b] (empty for no segment).
    arguments (Input)
        p (1,2) double       % Point.
        rm_a (:,2) double    % Starts of the segments.
        rm_b (:,2) double    % Ends of the segments.
    end
    arguments (Output)
        rv_s (:,1) double  % Distance to each segment.
    end
    rm_d = rm_b - rm_a;
    rv_dd = sum(rm_d.^2, 2);
    rv_t = zeros(size(rv_dd));
    lv = rv_dd > 0;
    rv_t(lv) = min(max(sum((p - rm_a(lv, :)) .* rm_d(lv, :), 2) ./ rv_dd(lv), 0), 1);
    rv_s = vecnorm(p - (rm_a + rv_t .* rm_d), 2, 2);
end


function rv_f = repulsion(p, rv_a, rv_b, r, i, d0)
% Repulsion d0*(r - s)/r away from the nearest point of the segment [a, b] when its distance s is below r.
    arguments (Input)
        p (1,2) double     % Position of the bus.
        rv_a (1,2) double  % Start of the segment.
        rv_b (1,2) double  % End of the segment.
        r (1,1) double     % Range of the repulsion.
        i (1,1) double     % Row of the bus (direction when the points coincide).
        d0 (1,1) double    % Length scale.
    end
    arguments (Output)
        rv_f (1,2) double  % Force on the bus.
    end
    rv_d = rv_b - rv_a;
    t = 0;
    if any(rv_d)
        t = min(max(dot(p - rv_a, rv_d) / dot(rv_d, rv_d), 0), 1);
    end
    rv_away = p - (rv_a + t*rv_d);
    s = norm(rv_away);
    rv_f = [0 0];
    if s < r
        rv_f = d0 * (r - s)/r * unit(rv_away, i, d0);
    end
end


function rv_u = unit(rv_d, i, d0)
% Unit vector along rv_d; a fixed direction 2*pi*mod(i, 8)/8 when rv_d is shorter than 1e-12*d0.
    arguments (Input)
        rv_d (1,2) double  % Vector.
        i (1,1) double     % Row of the bus.
        d0 (1,1) double    % Length scale.
    end
    arguments (Output)
        rv_u (1,2) double  % Unit vector.
    end
    s = norm(rv_d);
    if s < 1e-12 * d0
        th   = 2*pi*mod(i, 8)/8;
        rv_u = [cos(th), sin(th)];
    else
        rv_u = rv_d / s;
    end
end
