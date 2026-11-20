function sct_hessian = get_hessian(obj, x, V, u)
% Return the port-balance Jacobian of the load at a point (port "PI").
%
% See Component.get_hessian for the form w_dev = Hvv v with v = [theta; V] (no states).
% Derivation (not in the reference paper): the load injects $I = (I_p - jI_q) V/|V|$
% with [Ip, Iq] = u, so it supplies $P + jQ = V (I_p + jI_q)$ and
% ```math
% w_\mathrm{dev} = -\begin{bmatrix} P \\ Q/V \end{bmatrix} = -\begin{bmatrix} I_p V \\ I_q \end{bmatrix}, \quad
% H_{vv} = \frac{\partial w_\mathrm{dev}}{\partial (\theta, V)} = \begin{bmatrix} 0 & -I_p \\ 0 & 0 \end{bmatrix}
% ```
% The reactive part has the energy function $-I_q V$. The voltage-dependent active power
% has no energy function: Hvv is the Jacobian of the port balance, and its asymmetry
% $H_{vv}(1,2) - H_{vv}(2,1) = -I_p$ is the loss (zero for a purely reactive load, Ip = 0).
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
    sct_hessian = obj.pack_hessian([0, -u(1); 0, 0], zeros(0,0));
end
