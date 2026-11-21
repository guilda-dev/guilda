function sct_hessian = get_hessian(obj, x, V, u)
% Return the Hessian of the energy function of the inverter at a point (port "PI").
%
% See Component.get_hessian for the form w_dev = Hvv v with v = [theta; V] (no states).
% The inverter supplies the constant power $P + jQ$ = [Pref, Qref] (positive for generation), and
% its energy function (the constant-power load of Nishino et al., IEEJ B 2025, eq. (19)) is
% $U = -P\theta - Q\log V$, so $w_\mathrm{dev} = \nabla_v U = -[P; Q/V]$ and
% ```math
% H_{vv} = \begin{bmatrix} 0 & 0 \\ 0 & Q/V^2 \end{bmatrix}
% ```
% (eq. (27)), symmetric and exact at any point. Hxx, Hxv, R are 0 x 0, 0 x 2, 0 x 0.
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
    r_V = abs([1,1j]*V);
    sct_hessian = obj.pack_hessian([0, 0; 0, u(2)/r_V^2], zeros(0,0));
end
