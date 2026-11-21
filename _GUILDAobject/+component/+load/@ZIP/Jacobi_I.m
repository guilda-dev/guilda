function [Cix,Div,Diu] = Jacobi_I(t,x,V,u,param,omega0)
% Calculate the Jacobians of the bus current.
%
% Analytic derivatives of `fcn_I`, with the current split as `[real; imag]`. With
% $a = P_\mathrm{load} f_P/|V|^2$ and $b = Q_\mathrm{load} f_Q/|V|^2$ the current is
% $I = [a V_\mathrm{re} + b V_\mathrm{im};\ a V_\mathrm{im} - b V_\mathrm{re}]$. On each side
% of `VswitchP` and `VswitchI` the derivatives are exact; at a threshold they are those of
% the upper side. Below both thresholds the load is a constant impedance and the derivatives
% are those of `I = conj(u.*c)*V`, finite at `V = 0`.
%
% See also fcn_I
    arguments (Input)
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        u      double        % Input vector in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        Cix  % Jacobian of the bus current `[real; imag]` with respect to `x`.
        Div  % Jacobian of the bus current `[real; imag]` with respect to `V` `[real; imag]`.
        Diu  % Jacobian of the bus current `[real; imag]` with respect to `u`.
    end
    Cix = zeros(2,0);
    Vre  = V(1);
    Vim  = V(2);
    Vabs = sqrt(Vre^2 + Vim^2);
    [rv_c, r_Vlow] = zip_admittance(param);
    if Vabs < r_Vlow
        % constant impedance below both thresholds (finite at V = 0): I = conj(u.*c)*V
        a = u(1)*rv_c(1);  b = u(2)*rv_c(2);
        Div = [a, b; -b, a];
        Diu = [Vre*rv_c(1),  Vim*rv_c(2);
               Vim*rv_c(1), -Vre*rv_c(2)];
        return
    end
    [rv_f, rv_df] = zip_factor(Vabs, param);

    % a, b and their derivatives with respect to |V|
    rv_ab  = u(:).*rv_f/Vabs^2;
    rv_dab = u(:).*(rv_df*Vabs - 2*rv_f)/Vabs^3;
    a = rv_ab(1);   b = rv_ab(2);
    da = rv_dab(1); db = rv_dab(2);

    Div = [a, b; -b, a] + [Vre*da + Vim*db; Vim*da - Vre*db]*[Vre, Vim]/Vabs;
    Diu = [Vre*rv_f(1),  Vim*rv_f(2);
           Vim*rv_f(1), -Vre*rv_f(2)]/Vabs^2;
end
