function resolve_overlap(hv_move, hv_fix, n_iter, r_pad)
% Push overlapping text objects apart vertically (2D).
%
% The extents of the texts in hv_move are compared with each other and with those of
% hv_fix; overlapping texts of hv_move move up or down until no box overlaps or n_iter
% passes are done. The texts of hv_fix do not move.
    arguments (Input)
        hv_move             % Text objects that may move.
        hv_fix              % Text objects that stay.
        n_iter (1,1) double % Largest number of passes.
        r_pad (1,1) double  % Gap added between the boxes.
    end
    hv_all = [hv_move(:); hv_fix(:)];
    n_move = numel(hv_move);
    for i_iter = 1:n_iter
        rm_box = nan(numel(hv_all), 4);
        for k = 1:numel(hv_all)
            if strlength(string(hv_all(k).String)) > 0 && strcmp(hv_all(k).Visible, "on") && all(isfinite(hv_all(k).Position))
                rm_box(k, :) = hv_all(k).Extent;
            end
        end
        l_moved = false;
        for i = 1:n_move
            for j = 1:numel(hv_all)
                if i == j || any(isnan(rm_box(i, :))) || any(isnan(rm_box(j, :)))
                    continue
                end
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
                    hv_all(j).Position(2) = hv_all(j).Position(2) - r_sign * r_shift;
                    rm_box(j, 2) = rm_box(j, 2) - r_sign * r_shift;
                else
                    r_shift = r_oy + r_pad;
                end
                hv_all(i).Position(2) = hv_all(i).Position(2) + r_sign * r_shift;
                rm_box(i, 2) = rm_box(i, 2) + r_sign * r_shift;
                l_moved = true;
            end
        end
        if ~l_moved
            break
        end
    end
end
