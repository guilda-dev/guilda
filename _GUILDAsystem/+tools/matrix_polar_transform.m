% 実部虚部表現から極座標表現への変換行列を求める
% (real, imag) -> (arg, abs)
function matrix = matrix_polar_transform(equilibrium)
    r = real(equilibrium);
    i = imag(equilibrium);
    abs2 = r.^2 + i.^2;
    if numel(equilibrium)==1
        matrix = [-i/abs2, r/abs2; r/sqrt(abs2), i/sqrt(abs2)];
    else
        matrix = tools.darrayfun(@(r, i, abs2) [-i/abs2, r/abs2; r/sqrt(abs2), i/sqrt(abs2)], r, i, abs2);
    end
end