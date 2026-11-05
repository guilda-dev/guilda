function matrix = matrix_polar_transform(equilibrium, is_reverse)
% Compute the matrix that converts (real, imag) deviations to (arg, abs) deviations.
%
% Linearized at the complex values, one 2x2 block per value (block-diagonal).
    arguments (Input)
        equilibrium        % Complex values at which to linearize.
        is_reverse = false % true: convert (arg, abs) deviations to (real, imag) instead.
    end
    arguments (Output)
        matrix             % Block-diagonal transformation matrix, one 2x2 block per value.
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