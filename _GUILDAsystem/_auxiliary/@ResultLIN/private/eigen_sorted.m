function [cv_lambda, cm_right, cm_left] = eigen_sorted(A, E)
% Finite generalized eigenvalues of (A, E) in the order of get_mode, each complex pair
% together (Im > 0 first), with the right eigenvectors (entry of largest magnitude 1, the
% cm_shape of get_mode) and the left eigenvectors (w' E v = 1 with that v)
%
% The eigenvalues come from the same eig call as tools.linear_modes, so the modes of
% get_mode are the rows of cv_lambda with Im >= -1e-6 and in the same order; the
% partner of a pair (Im lambda > 1e-6) follows it and is its conjugate, with the conjugate
% vectors (A and E are real).
    arguments (Input)
        A double  % State matrix (n x n).
        E double  % Mass matrix (n x n); singular for a DAE.
    end
    arguments (Output)
        cv_lambda (:,1) double  % Eigenvalues, sorted by the real part (largest first).
        cm_right  double        % Right eigenvectors (columns): A v = lambda E v.
        cm_left   double        % Left eigenvectors (columns): w' A = lambda w' E.
    end
    [rm_V, rm_D, rm_W] = eig(full(A), full(E));
    cv_lam = diag(rm_D);
    iv = find(isfinite(cv_lam) & imag(cv_lam) >= -1e-6);
    [~, iv_sort] = sort(real(cv_lam(iv)), "descend");
    iv = iv(iv_sort);
    lv_pair = imag(cv_lam(iv)) > 1e-6;

    % each mode, then the conjugate of a pair
    n_m = numel(iv) + nnz(lv_pair);
    iv_src  = zeros(n_m, 1);
    lv_conj = false(n_m, 1);
    i_pos = 0;
    for k = 1:numel(iv)
        i_pos = i_pos + 1;
        iv_src(i_pos) = iv(k);
        if lv_pair(k)
            i_pos = i_pos + 1;
            iv_src(i_pos) = iv(k);
            lv_conj(i_pos) = true;
        end
    end
    cv_lambda = cv_lam(iv_src);
    cv_lambda(lv_conj) = conj(cv_lambda(lv_conj));

    cm_right = rm_V(:, iv_src);
    [~, iv_max] = max(abs(cm_right), [], 1);
    cm_right = cm_right ./ cm_right(sub2ind(size(cm_right), iv_max, 1:n_m));
    cm_left = rm_W(:, iv_src);
    cm_left = cm_left ./ conj(sum(conj(cm_left) .* (E * cm_right), 1));
    cm_right(:, lv_conj) = conj(cm_right(:, lv_conj));
    cm_left(:, lv_conj)  = conj(cm_left(:, lv_conj));
end
