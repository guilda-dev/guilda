% 実部虚部表現から極座標表現への変換行列を求める
% (real, imag) -> (arg, abs)
% is_reverse=true : (arg, abs) -> (real, imag)
function matrix = matrix_polar_transform(equilibrium, is_reverse)
    if nargin<2
        is_reverse = false;
    end

    r = real(equilibrium);
    i = imag(equilibrium);
    abs2 = r.^2 + i.^2;

    if is_reverse
        matrix = tools.darrayfun(@(r, i, abs2) [-i, r/sqrt(abs2); r, i/sqrt(abs2)], r, i, abs2);
    else
        matrix = tools.darrayfun(@(r, i, abs2) [-i/abs2, r/abs2; r/sqrt(abs2), i/sqrt(abs2)], r, i, abs2);
    end
end