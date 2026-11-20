function rm_box = resolve_overlap(hv_move, hv_fix, n_iter, r_pad, rm_box)
% Push overlapping text objects apart vertically (2D).
%
% The extents of the texts in hv_move are compared with each other and with those of
% hv_fix; overlapping texts of hv_move move up or down until no box overlaps or n_iter
% passes are done. The texts of hv_fix do not move. The boxes are measured once (a
% vertical move shifts a box by as much) and the texts are moved at the end. rm_box, when
% given, holds the boxes of [hv_move; hv_fix] instead of their measured Extent (a caller
% that computed them for other limits: NaN rows are skipped); the boxes after the moves
% are returned.
    arguments (Input)
        hv_move              % Text objects that may move.
        hv_fix               % Text objects that stay.
        n_iter (1,1) double  % Largest number of passes.
        r_pad (1,1) double   % Gap added between the boxes.
        rm_box (:,4) double = zeros(0, 4)  % Boxes [x y w h] of [hv_move; hv_fix]; empty: measured.
    end
    arguments (Output)
        rm_box (:,4) double  % Boxes after the moves (NaN for the texts not shown).
    end
    hv_all = [hv_move(:); hv_fix(:)];
    n_move = numel(hv_move);
    % The boxes are measured once: a vertical move shifts a box by the same amount
    % (one get for all the texts: much faster than one Extent per text)
    if isempty(rm_box)
        rm_box = nan(numel(hv_all), 4);
        lv_box = arrayfun(@(h) any(strlength(string(h.String)) > 0) && strcmp(h.Visible, "on") && all(isfinite(h.Position)), hv_all);
        if any(lv_box)
            x = get(hv_all(lv_box), "Extent");    % a cell for two texts or more
            if iscell(x)
                x = vertcat(x{:});
            end
            rm_box(lv_box, :) = x;
        end
    end
    rv_y0 = rm_box(:, 2);
    for i_iter = 1:n_iter
        l_moved = false;
        for i = 1:n_move
            if any(isnan(rm_box(i, :)))
                continue
            end
            % The boxes that overlap box i now (a box overlapped after a move: next pass)
            lv_o = min(rm_box(i,1) + rm_box(i,3), rm_box(:,1) + rm_box(:,3)) - max(rm_box(i,1), rm_box(:,1)) > 0 ...
                 & min(rm_box(i,2) + rm_box(i,4), rm_box(:,2) + rm_box(:,4)) - max(rm_box(i,2), rm_box(:,2)) > 0;
            lv_o(i) = false;
            lv_o = lv_o & ~any(isnan(rm_box), 2);   % min and max skip NaN: a text without a box overlaps nothing
            for j = find(lv_o)'
                r_ox = min(rm_box(i,1) + rm_box(i,3), rm_box(j,1) + rm_box(j,3)) - max(rm_box(i,1), rm_box(j,1));
                r_oy = min(rm_box(i,2) + rm_box(i,4), rm_box(j,2) + rm_box(j,4)) - max(rm_box(i,2), rm_box(j,2));
                if r_ox <= 0 || r_oy <= 0
                    continue
                end
                r_sign = sign((rm_box(i,2) + rm_box(i,4)/2) - (rm_box(j,2) + rm_box(j,4)/2));
                if r_sign == 0
                    r_sign = 1;
                end
                if j <= n_move
                    r_shift = r_oy/2 + r_pad;
                    rm_box(j, 2) = rm_box(j, 2) - r_sign * r_shift;
                else
                    r_shift = r_oy + r_pad;
                end
                rm_box(i, 2) = rm_box(i, 2) + r_sign * r_shift;
                l_moved = true;
            end
        end
        if ~l_moved
            break
        end
    end
    for k = find(rm_box(1:n_move, 2) ~= rv_y0(1:n_move))'
        hv_all(k).Position(2) = hv_all(k).Position(2) + rm_box(k, 2) - rv_y0(k);
    end
end
