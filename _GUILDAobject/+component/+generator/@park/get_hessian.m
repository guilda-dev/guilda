function sct_hessian = get_hessian(obj, x, V, u)
% Return the Hessian of the energy function of the generator at a point (port "PI").
%
% See Component.get_hessian for the form dx/dt = -R (Hxx x + Hxv v), w_dev = Hvx x + Hvv v
% with v = [theta; V]. Derivation (not in the reference paper): with the subtransient
% voltages of the class description,
% $E_q'' = a_d E_q + b_d \psi_d$, $E_d'' = a_q E_d - b_q \psi_q$,
% $a = (X'' - X_{ls})/(X' - X_{ls})$, $b = (X' - X'')/(X' - X_{ls})$ ($a + b = 1$), and
% $c = (X' - X_{ls})^2/(X' - X'')$ for each axis, the energy function is
% ```math
% \begin{aligned}
% U ={}& \frac{\omega_s M \omega^2}{2} + \frac{E_q^2}{2(X_d - X_d')} + \frac{(E_q - \psi_d)^2}{2c_d}
%       + \frac{E_d^2}{2(X_q - X_q')} + \frac{(E_d + \psi_q)^2}{2c_q} \\
%     &+ \frac{(E_q'' - V_q)^2}{2X_d''} + \frac{(V_d - E_d'')^2}{2X_q''} - \frac{V_\mathrm{field} E_q}{X_d - X_d'}
% \end{aligned}
% ```
% with $\omega_s = 2\pi\omega_0$, $V_q = V\cos(\delta-\theta)$, $V_d = V\sin(\delta-\theta)$,
% $I_d = (E_q'' - V_q)/X_d''$ and $I_q = (V_d - E_d'')/X_q''$. Its gradient is
% $\partial U/\partial\delta = V_d I_d + V_q I_q = P$, $\partial U/\partial\theta = -P$,
% $\partial U/\partial V = -Q/V$, and
% ```math
% \begin{aligned}
% \partial U/\partial E_q &= E_q/(X_d - X_d') + (E_q - \psi_d)/c_d + a_d I_d - V_\mathrm{field}/(X_d - X_d') \\
% \partial U/\partial \psi_d &= -(E_q - \psi_d)/c_d + b_d I_d \\
% \partial U/\partial E_d &= E_d/(X_q - X_q') + (E_d + \psi_q)/c_q - a_q I_q \\
% \partial U/\partial \psi_q &= (E_d + \psi_q)/c_q + b_q I_q
% \end{aligned}
% ```
% Since $c\,b = X' - X_{ls}$ and $b/(X' - X_{ls}) = 1/c$, the right sides of the class
% equations are $-(X_d - X_d')\,\partial U/\partial E_q$, $-(X_q - X_q')\,\partial U/\partial E_d$,
% $-c_q\,\partial U/\partial\psi_q$ and $-c_d\,\partial U/\partial\psi_d$ (the $T''\dot\psi$ terms of the
% $E_q$, $E_d$ equations are the $(E - \psi)/c$ parts). So $E\dot{x} = -\tilde{R}\nabla_x U + [0; P_\mathrm{mech}; 0; 0; 0; 0]$
% with the mass matrix $E$ = fcn_Mass and
% ```math
% \tilde{R} = \mathrm{blkdiag}\left(\begin{bmatrix} 0 & -1/M \\ 1 & D/(\omega_s M) \end{bmatrix}, X_d - X_d', X_q - X_q', c_q, c_d\right), \quad R = E^{-1}\tilde{R}
% ```
% (states delta, omega, Eq, Ed, psiq, psid). The Hessian is symmetric and exact at any point.
% It needs Xd_p < Xd, Xq_p < Xq, Xd_pp < Xd_p and Xq_pp < Xq_p: with an equal pair (for
% example Xq_p = Xq, a machine without a q-axis transient circuit) a state is driven one way
% only and the form does not exist (GUILDA:Component:HessianNotSupported).
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
    [M, D, Xd, Xdp, Xdpp, Xq, Xqp, Xqpp, Xls] = deal(p(1), p(2), p(3), p(4), p(5), p(6), p(7), p(8), p(13));
    if Xd == Xdp || Xq == Xqp || Xdp == Xdpp || Xqp == Xqpp
        error(msg("GUILDA:Component:HessianNotSupported", class(obj), ...
                  "a transient reactance equals the synchronous or the subtransient one, so a flux state has no energy term"))
    end
    r_cd = (Xdp - Xls)^2/(Xdp - Xdpp);
    r_cq = (Xqp - Xls)^2/(Xqp - Xqpp);
    rv_aq = [0, 0, (Xdpp - Xls), 0, 0, (Xdp - Xdpp)]/(Xdp - Xls);    % Eq'' = rv_aq*x
    rv_ad = [0, 0, 0, (Xqpp - Xls), -(Xqp - Xqpp), 0]/(Xqp - Xls);   % Ed'' = rv_ad*x
    K = diag([0, ws*M, 1/(Xd - Xdp) + 1/r_cd, 1/(Xq - Xqp) + 1/r_cq, 1/r_cq, 1/r_cd]);
    K(3,6) = -1/r_cd;  K(6,3) = -1/r_cd;
    K(4,5) =  1/r_cq;  K(5,4) =  1/r_cq;
    H = obj.energy_hessian_dq(x, V, rv_aq, rv_aq*x, rv_ad, rv_ad*x, Xdpp, Xqpp, K);
    R = obj.fcn_Mass(0, x, V, u, p, f0) \ blkdiag([0, -1/M; 1, D/(ws*M)], Xd - Xdp, Xq - Xqp, r_cq, r_cd);
    sct_hessian = obj.pack_hessian(H, R);
end
