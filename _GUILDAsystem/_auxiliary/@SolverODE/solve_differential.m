function g = solve_differential(f, dMd, lv_dif, lv_eqD)
% Rows of f (a vector or a Jacobian) for the identity mass matrix (see set_equations)
    arguments (Input)
        f       (:,:) double         % Right-hand side or Jacobian.
        dMd     (1,1) decomposition  % Decomposition of the differential block of the mass matrix.
        lv_dif  (:,1) logical        % True for the differential variables.
        lv_eqD  (:,1) logical        % True for the differential equations.
    end
    arguments (Output)
        g  (:,:) double  % Rows of f for the identity mass matrix.
    end
    g = f;
    g(lv_dif,:)  = dMd \ f(lv_eqD,:);
    g(~lv_dif,:) = f(~lv_eqD,:);
end
