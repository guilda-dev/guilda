function sct_hessian = get_hessian(obj, x, V, u)
% Return the Hessian of the energy function of the generator at a point (port "PI").
%
% See Component.get_hessian for the form dx/dt = -R (Hxx x + Hxv v), w_dev = Hvx x + Hvv v
% with v = [theta; V]. The energy function of the classical model (the VSG model of
% Nishino et al., IEEJ B 2025, eq. (17)) is
% ```math
% U = \frac{\omega_s M \omega^2}{2} + \frac{(V_\mathrm{field} - V_q)^2}{2X_d} + \frac{V_d^2}{2X_q}
% ```
% with $\omega_s = 2\pi\omega_0$, $V_q = V\cos(\delta-\theta)$, $V_d = V\sin(\delta-\theta)$ and
% $V_\mathrm{field}$ the input at the point. Then $\partial U/\partial\delta = P$,
% $\partial U/\partial\theta = -P$ and $\partial U/\partial V = -Q/V$, and the state equation
% is $E\dot{x} = -\tilde{R}\nabla_x U + [0; P_\mathrm{mech}]$ with the mass matrix $E$ = fcn_Mass and
% ```math
% \tilde{R} = \begin{bmatrix} 0 & -1/M \\ 1 & D/(\omega_s M) \end{bmatrix}, \quad R = E^{-1}\tilde{R}
% ```
% (det R = 1/M^2). The Hessian is symmetric and exact at any point.
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
    M  = p(1);
    K  = diag([0, ws*M]);
    H  = obj.energy_hessian_dq(x, V, [0 0], u(2), [0 0], 0, p(3), p(4), K);
    R  = obj.fcn_Mass(0, x, V, u, p, f0) \ [0, -1/M; 1, p(2)/(ws*M)];
    sct_hessian = obj.pack_hessian(H, R);
end
