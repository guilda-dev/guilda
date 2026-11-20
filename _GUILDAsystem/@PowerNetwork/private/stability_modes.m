function sct_mode = stability_modes(net, rv_point, sv_owner)
% Modes of the linear model of the network at a point: the eigenvalues of get_sys(rv_point, Type="ODE").
%
% The modes of tools.linear_modes (shared with ResultLIN.get_mode) other than the zero
% eigenvalues (e.g. the reference angle): the finite eigenvalues of eig(A, E), one of each
% complex pair, with the damping ratio (NaN for a real mode), the frequency and the owner
% of the largest participation (sv_owner). Called by calculate_optimal_powerflow and
% stability_gradient.
    arguments (Input)
        net                     % The network (PowerNetwork); only get_sys is called.
        rv_point (:,1) double   % Point of get_sys (rows x, Vre, Vim, u, uc of the variable map).
        sv_owner (:,1) string   % Owner of each state (the x rows of the variable map).
    end
    arguments (Output)
        sct_mode  % lambda, zeta, frequency [Hz], l_osc, owner (one per mode), V (right eigenvectors, columns), n_zero.
    end
    sct_sys = net.get_sys(rv_point, Type="ODE", Format="struct");
    sct_all = tools.linear_modes(sct_sys.A, sct_sys.E, sv_owner);
    lv = ~sct_all.l_zero;
    sct_mode = struct("lambda", sct_all.lambda(lv), "zeta", sct_all.zeta(lv), "frequency", sct_all.frequency(lv), ...
        "l_osc", sct_all.l_osc(lv), "owner", sct_all.owner(lv), "V", sct_all.V(:, lv), "n_zero", sct_all.n_zero);
end
