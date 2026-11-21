function sct_hessian = get_hessian(obj, x, V, u)
% Return the port-balance Jacobian of the load at a point (port "PI").
%
% See Component.get_hessian for the form w_dev = Hvv v with v = [theta; V] (no states).
% Derivation (not in the reference paper): the load supplies $P = P_\mathrm{load} f_P(V)$,
% $Q = Q_\mathrm{load} f_Q(V)$ = [Pload, Qload] times the voltage factors of the class
% description, so
% ```math
% w_\mathrm{dev} = -\begin{bmatrix} P_\mathrm{load} f_P \\ Q_\mathrm{load} f_Q / V \end{bmatrix}, \quad
% H_{vv} = \begin{bmatrix} 0 & -P_\mathrm{load} f_P' \\ 0 & -Q_\mathrm{load} (f_Q' V - f_Q)/V^2 \end{bmatrix}
% ```
% The reactive part has an energy function (it depends on V only). The active part is
% lossy and has none unless it is constant power: Hvv is the Jacobian of the port balance,
% and its asymmetry $H_{vv}(1,2) = -P_\mathrm{load} f_P'$ is the loss. The form reduces to
% that of the power load (f = 1) and of the impedance load (f = V^2). Exact at any point on
% either side of VswitchP and VswitchI (at a threshold: the upper side). Hxx, Hxv, R are
% 0 x 0, 0 x 2, 0 x 0.
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
    rr_param = obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)}.tab_parameter{:,obj.sv_para};
    r_V = abs([1,1j]*V);
    [rv_f, rv_df] = zip_factor(r_V, rr_param);
    sct_hessian = obj.pack_hessian([0, -u(1)*rv_df(1); 0, -u(2)*(rv_df(2)*r_V - rv_f(2))/r_V^2], zeros(0,0));
end
