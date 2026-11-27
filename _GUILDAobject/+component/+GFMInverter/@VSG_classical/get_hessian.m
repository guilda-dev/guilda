function sct_hessian = get_hessian(obj, x, V, u)
% Return the Hessian of the energy function of the inverter at a point (port "PI").
%
% See Component.get_hessian for the form dx/dt = -R (Hxx x + Hxv v), w_dev = Hvx x + Hvv v
% with v = [theta; V]. R is the one of the classical generator,
% ```math
% \tilde{R} = \begin{bmatrix} 0 & -1/M \\ 1 & D/(\omega_s M) \end{bmatrix}, \quad R = E^{-1}\tilde{R}
% ```
% with $\omega_s = 2\pi\omega_0$ and the mass matrix $E$ = fcn_Mass. The blocks are built
% from the exact Jacobians of the model at the point: $[H_{xx}\ H_{xv}] = -\tilde{R}^{-1}
% [\partial f/\partial x\ \partial f/\partial v]$ with $f$ = fcn_dx, and $[H_{vx}\ H_{vv}]$ is the
% Jacobian of $w_\mathrm{dev} = -[P; Q/V]$, with $P + jQ$ the power of the rotated current
% that enters the bus. The swing equation uses the virtual power $\tilde{P}$ of the classical
% current $I_0 = e^{-j\alpha} I$, so $[H_{xx}\ H_{xv}]$ is the one of the classical generator
% (component.generator.classical.get_hessian) at any `alpha`: $H_{xx}$ is symmetric. With
% `alpha = 0` all the blocks equal those of the classical generator, which are symmetric.
% With `alpha` ≠ 0 the bus sees the rotated power $P + jQ = e^{-j\alpha}(\tilde{P} + j\tilde{Q})$:
% $H_{vx}$, $H_{vv}$ are still the exact Jacobians, but $H_{vx} \ne H_{xv}^\top$ (the rotation
% makes lines with $R/X = \tan\alpha$ lossless in the energy function's rotated frame).
%
% See also Component.get_hessian, component.generator.classical.get_hessian, get_linear_matrix
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
    Rt = [0, -1/M; 1, p(2)/(ws*M)];

    % [Vre; Vim] with respect to [theta; |V|]
    c_V = [1,1j]*V;
    r_V = abs(c_V);
    T   = [-imag(c_V), real(c_V)/r_V; real(c_V), imag(c_V)/r_V];

    [Axx, Bxv] = obj.Jacobi_dx(0, x, V, u, p, f0);
    [Cix, Div] = obj.Jacobi_I(0, x, V, u, p, f0);
    c_I = obj.fcn_I(0, x, V, u, p, f0);
    rv_I = [real(c_I), imag(c_I)];
    Q    = imag(c_V*conj(c_I));

    % P = Vre*Ire + Vim*Iim, Q = Vim*Ire - Vre*Iim over [x; theta; |V|]
    dI = [Cix, Div*T];
    dV = [zeros(2, numel(x)), T];
    dP = rv_I*dV + V.'*dI;
    dQ = [-rv_I(2), rv_I(1)]*dV + [V(2), -V(1)]*dI;
    dw = -[dP; dQ/r_V];
    dw(2,end) = dw(2,end) + Q/r_V^2;

    H = [-Rt \ [Axx, Bxv*T]; dw];
    sct_hessian = obj.pack_hessian(H, obj.fcn_Mass(0, x, V, u, p, f0) \ Rt);
end
