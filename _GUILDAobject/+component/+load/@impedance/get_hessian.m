function sct_hessian = get_hessian(obj, x, V, u)
% Return the port-balance Jacobian of the load at a point (port "PI").
%
% See Component.get_hessian for the form w_dev = Hvv v with v = [theta; V] (no states).
% Derivation (not in the reference paper): the load draws $I = -V/Z$ with $Z = R + jX$
% = [R, X], so it supplies $P + jQ = -V^2 (G + jB)$ with $G = R/|Z|^2$, $B = X/|Z|^2$, and
% ```math
% w_\mathrm{dev} = -\begin{bmatrix} P \\ Q/V \end{bmatrix} = \begin{bmatrix} G V^2 \\ B V \end{bmatrix}, \quad
% H_{vv} = \frac{\partial w_\mathrm{dev}}{\partial (\theta, V)} = \begin{bmatrix} 0 & 2GV \\ 0 & B \end{bmatrix}
% ```
% The reactive part has the energy function $B V^2/2$. The conductance is lossy and has no
% energy function: Hvv is the Jacobian of the port balance, and its asymmetry
% $H_{vv}(1,2) - H_{vv}(2,1) = 2GV$ is the loss (zero for a purely reactive load, R = 0).
% Exact at any point. Hxx, Hxv, R are 0 x 0, 0 x 2, 0 x 0.
%
% See also Component.get_hessian, get_linear_matrix
    arguments (Input)
        obj
        x (:,1) double = obj.rv_Xequilibrium  % States (none).
        V (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]  % [pu] Bus voltage [Vre; Vim] (default: the equilibrium).
        u (:,1) double = obj.rv_Uequilibrium  % Inputs (default: the equilibrium).
    end
    arguments (Output)
        sct_hessian struct  % Fields Hxx, Hxv, Hvx, Hvv, R, StateName, PortName (see Component.get_hessian).
    end
    r_V  = abs([1,1j]*V);
    r_Z2 = u(1)^2 + u(2)^2;
    sct_hessian = obj.pack_hessian([0, 2*u(1)/r_Z2*r_V; 0, u(2)/r_Z2], zeros(0,0));
end
