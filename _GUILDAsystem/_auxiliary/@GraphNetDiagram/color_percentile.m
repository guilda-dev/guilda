function r = color_percentile(rv_v, r_q)
% Percentile r_q (0..1) of finite values by the nearest rank: the ceil(r_q*n)-th smallest.
%
% Deterministic, without a toolbox. With fewer than 20 values the extreme is used instead
% (the largest for r_q >= 0.5, the smallest otherwise), as one value of a few is no outlier.
% No value gives NaN.
    arguments (Input)
        rv_v (:,1) double     % Finite values.
        r_q (1,1) double      % Fraction, e.g. 0.95.
    end
    arguments (Output)
        r (1,1) double  % Percentile.
    end
    n = numel(rv_v);
    if n == 0
        r = NaN;
        return
    end
    rv_s = sort(rv_v);
    if n < 20
        r = rv_s(end);
        if r_q < 0.5
            r = rv_s(1);
        end
        return
    end
    r = rv_s(min(n, max(1, ceil(r_q*n))));
end
