function [rm_gZeta, rm_gRe] = stability_gradient(net, sct_ctx, rv_u, sct_mode, iv_mode, rv_h)
% Sensitivities of the damping ratio and of the real part of some modes to the set points, by forward differences.
%
% For each set point j, the point with rv_u(j) + rv_h(j) (stability_point) gives the modes
% (stability_modes); each mode iv_mode of sct_mode (the modes at rv_u) is the mode of the
% largest MAC |v_a' v_b|^2 / (|v_a|^2 |v_b|^2) of the right eigenvectors, at least 0.8. When a
% mode is not found, the step is halved once; a mode still not found has NaN in that column.
% The rows are the modes iv_mode, the columns the set points. This is the only place of
% the sensitivities of the stability-constrained OPF: an analytical sensitivity can
% replace it with the same inputs and outputs. Called by calculate_optimal_powerflow.
    arguments (Input)
        net                    % The network (PowerNetwork); only get_sys is called.
        sct_ctx (1,1) struct   % Data of the stability-constrained OPF (see calculate_optimal_powerflow).
        rv_u (:,1) double      % [pu] Set points of the linearization point (order of sct_ctx.tab_u).
        sct_mode (1,1) struct  % Modes at rv_u (stability_modes).
        iv_mode (:,1) double   % Modes whose sensitivities are needed (indices into sct_mode).
        rv_h (:,1) double      % [pu] Step of each set point.
    end
    arguments (Output)
        rm_gZeta double  % d zeta / d u (NaN for a real mode or a mode not found).
        rm_gRe   double  % d Re lambda / d u (NaN for a mode not found).
    end
    n_u = numel(rv_u);
    [rm_gZeta, rm_gRe] = deal(nan(numel(iv_mode), n_u));
    rm_Vbase = sct_mode.V(:, iv_mode);
    for j = 1:n_u
        h = rv_h(j);
        for i_try = 1:2
            rv_uj = rv_u;
            rv_uj(j) = rv_uj(j) + h;
            sct_j = stability_modes(net, stability_point(sct_ctx, rv_uj, sct_ctx.tab_u.Name(j) + " + " + h), sct_ctx.sv_owner);
            rm_mac = abs(rm_Vbase' * sct_j.V).^2 ./ (vecnorm(rm_Vbase).^2.' * vecnorm(sct_j.V).^2);
            [rv_mac, iv_match] = max(rm_mac, [], 2);
            lv_ok = rv_mac >= 0.8;
            if all(lv_ok) || i_try == 2
                break
            end
            h = h/2;
        end
        rm_gZeta(lv_ok, j) = (sct_j.zeta(iv_match(lv_ok)) - sct_mode.zeta(iv_mode(lv_ok))) / h;
        rm_gRe(lv_ok, j)   = (real(sct_j.lambda(iv_match(lv_ok))) - real(sct_mode.lambda(iv_mode(lv_ok)))) / h;
    end
end
