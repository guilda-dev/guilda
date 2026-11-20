function sct_hessian = get_hessian(obj, x, V, u)
% Return the Hessian of the energy function of the generator at a point (port "PI").
%
% See Component.get_hessian for the form dx/dt = -R (Hxx x + Hxv v), w_dev = Hvx x + Hvv v
% with v = [theta; V]. The energy function of the two-axis model (Nishino et al.,
% IEEJ B 2025, eq. (15)) is
% ```math
% U = \frac{\omega_s M \omega^2}{2} + \frac{E_q^2}{2(X_d - X_d')} + \frac{E_d^2}{2(X_q - X_q')}
%     + \frac{(E_q - V_q)^2}{2X_d'} + \frac{(V_d - E_d)^2}{2X_q'} - \frac{V_\mathrm{field} E_q}{X_d - X_d'}
% ```
% with $\omega_s = 2\pi\omega_0$, $V_q = V\cos(\delta-\theta)$, $V_d = V\sin(\delta-\theta)$ (the
% last term is linear and does not enter the Hessian). Then $\partial U/\partial\delta = P$,
% $\partial U/\partial\theta = -P$, $\partial U/\partial V = -Q/V$, and the state equation is
% $E\dot{x} = -\tilde{R}\nabla_x U + [0; P_\mathrm{mech}; 0; 0]$ with the mass matrix $E$ = fcn_Mass and
% ```math
% \tilde{R} = \mathrm{blkdiag}\left(\begin{bmatrix} 0 & -1/M \\ 1 & D/(\omega_s M) \end{bmatrix}, X_d - X_d', X_q - X_q'\right), \quad R = E^{-1}\tilde{R}
% ```
% The paper (eq. (29)) writes the field entries of R as $T'/(X - X')$; the model of this class
% gives $(X - X')/T'$. The Hessian is symmetric and exact at any point. It needs Xd_p < Xd
% and Xq_p < Xq: with an equal pair the form does not exist (GUILDA:Component:HessianNotSupported).
%
% See also Component.get_hessian, get_linear_matrix
    arguments (Input)
        obj
        x (:,1) double = obj.rv_Xequilibrium  % States (default: the equilibrium).
        V (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]  % [pu] Bus voltage [Vre; Vim] (default: the equilibrium).
        u (:,1) double = obj.rv_Uequilibrium  % Inputs (default: the equilibrium).
    end
    arguments (Output)
        sct_hessian struct  % Fields Hxx, Hxv, Hvx, Hvv, R, StateName, PortName (see Component.get_hessian).
    end
    p  = obj.tab_parameter.dynamics{1, obj.sv_para};
    f0 = obj.get_Hz();
    ws = 2*pi*f0;
    [M, D, Xd, Xdp, Xq, Xqp] = deal(p(1), p(2), p(3), p(4), p(5), p(6));
    if Xd == Xdp || Xq == Xqp
        error(msg("GUILDA:Component:HessianNotSupported", class(obj), "Xd_p equals Xd or Xq_p equals Xq, so Eq or Ed has no energy term"))
    end
    K  = diag([0, ws*M, 1/(Xd - Xdp), 1/(Xq - Xqp)]);
    H  = obj.energy_hessian_dq(x, V, [0 0 1 0], x(3), [0 0 0 1], x(4), Xdp, Xqp, K);
    R  = obj.fcn_Mass(0, x, V, u, p, f0) \ blkdiag([0, -1/M; 1, D/(ws*M)], Xd - Xdp, Xq - Xqp);
    sct_hessian = obj.pack_hessian(H, R);
end
