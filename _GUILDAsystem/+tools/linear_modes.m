function sct_mode = linear_modes(A, E, sv_owner)
% Modes of a linear model E dx/dt = A x: eigenvalues, damping, participation and owner.
%
% The shared computation of ResultLIN.get_mode and of the stability-constrained OPF
% (PowerNetwork/private/stability_modes). The modes are the finite eigenvalues of
% eig(A, E) (a singular E, a DAE, gives infinite eigenvalues, which are left out), one of
% each complex pair (the one with Im > 0; real modes are those with Im >= -1e-6). A mode
% is a zero eigenvalue when |lambda| <= 1e-6*max(1, max|lambda|) (e.g. the reference
% angle), and oscillatory when |Im lambda| > 1e-6; its damping ratio is
% -Re lambda / |lambda| (NaN for a real mode) and its frequency |Im lambda| / (2 pi) [Hz].
% The participation of state k in mode i is |w_k (E v)_k| (left and right eigenvectors),
% summed by the owner of the state (sv_owner); the owner with the largest sum names the
% mode. rm_participation is that participation of each state normalized to sum 1 in
% each mode (a mode whose participation is all zero gives NaN).
    arguments (Input)
        A double                  % State matrix (n x n).
        E double                  % Mass matrix (n x n); singular for a DAE.
        sv_owner (:,1) string     % Owner of each state (n).
    end
    arguments (Output)
        sct_mode  % lambda, zeta, frequency [Hz], l_osc, l_zero, owner (one per mode), V (right eigenvectors, columns), rm_participation (states x modes), n_zero.
    end
    [rm_V, rm_D, rm_W] = eig(full(A), full(E));
    cv_lam = diag(rm_D);
    lv_fin = isfinite(cv_lam);
    lv_zero = lv_fin & abs(cv_lam) <= 1e-6*max([1; abs(cv_lam(lv_fin))]);
    iv = find(lv_fin & imag(cv_lam) >= -1e-6);    % real modes and Im > 0 of a pair

    rm_part = abs(rm_W(:, iv) .* (E * rm_V(:, iv)));
    [sv_own, ~, iv_own] = unique(sv_owner, "stable");
    rm_sum = zeros(numel(sv_own), numel(iv));
    for k = 1:numel(sv_own)
        rm_sum(k,:) = sum(rm_part(iv_own == k, :), 1);
    end
    [~, iv_max] = max(rm_sum, [], 1);
    cv_lam = cv_lam(iv);
    lv_osc = abs(imag(cv_lam)) > 1e-6;
    rv_zeta = nan(numel(iv), 1);
    rv_zeta(lv_osc) = -real(cv_lam(lv_osc)) ./ abs(cv_lam(lv_osc));
    sct_mode = struct("lambda", cv_lam, "zeta", rv_zeta, "frequency", abs(imag(cv_lam))/(2*pi), ...
        "l_osc", lv_osc, "l_zero", lv_zero(iv), "owner", reshape(sv_own(iv_max), [], 1), "V", rm_V(:, iv), ...
        "rm_participation", rm_part ./ sum(rm_part, 1), "n_zero", nnz(lv_zero));
end
