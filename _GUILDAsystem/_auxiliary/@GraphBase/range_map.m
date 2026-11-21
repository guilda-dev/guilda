function rv_w = range_map(rv_v, rv_range, rv_lim)
% Map values linearly from the scale [vmin vmax] onto the range [a b] (sizes and widths in pt).
%
% rv_lim is the scale chosen by the caller (for example the smallest and largest finite
% value of the quantity over all its samples, or the smallest value and the 95th
% percentile), or [NaN NaN] when there is none. A value is mapped to
% a + (b - a)*(v - vmin)/(vmax - vmin). With a [NaN NaN] scale every value gives (a + b)/2;
% with a scale of one value (vmax - vmin <= 1e-12*max(|vmin|, |vmax|, 1)) every finite value
% gives (a + b)/2. A NaN value gives a. A value outside the scale is kept in [a b]. For
% example, the values [0; 5; 10; NaN] with the range [1 4] and the scale [0 10] give
% [1; 2.5; 4; 1].
    arguments (Input)
        rv_v (:,1) double      % Values of the elements at the sample shown.
        rv_range (1,2) double  % Range [a b] of the result.
        rv_lim (1,2) double    % Scale [vmin vmax] over all samples ([NaN NaN]: none).
    end
    arguments (Output)
        rv_w (:,1) double  % Mapped values, in [a b].
    end
    r_a   = rv_range(1);
    r_b   = rv_range(2);
    r_mid = (r_a + r_b)/2;
    if any(isnan(rv_lim))
        rv_w = repmat(r_mid, numel(rv_v), 1);
        return
    end
    r_den = rv_lim(2) - rv_lim(1);
    if r_den <= 1e-12*max([abs(rv_lim), 1])
        rv_w = repmat(r_mid, numel(rv_v), 1);
    else
        rv_w = r_a + (r_b - r_a)*min(max((rv_v - rv_lim(1))/r_den, 0), 1);
    end
    rv_w(isnan(rv_v)) = r_a;
end
