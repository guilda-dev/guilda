function I = fcn_I(obj, t, x, V, u, param, omega0)
% Calculate the current that the component injects into the bus.
%
% The current follows the convention of `c_Iequilibrium`: positive into the bus. The power
% is `[Pload*f_P(|V|); Qload*f_Q(|V|)]` with the voltage factors of the class description.
% Below both thresholds the load is a constant impedance and the current is computed as
% such, so it is finite (0) at `V = 0`.
%
% See also Jacobi_I
    arguments (Input)
        obj
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        u      double        % Input vector in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        I  % [pu] Complex current injected into the bus.
    end
    Vi = [1,1j]*V;
    [rv_c, r_Vlow] = zip_admittance(param);
    if abs(Vi) < r_Vlow
        % constant impedance below both thresholds: conj(S/V) without the 0/0 at V = 0
        I = conj([1,1j]*(u(:).*rv_c))*Vi;
    else
        rv_f = zip_factor(abs(Vi), param);
        I = conj(([1,1j]*(u(:).*rv_f))/Vi);
    end
end
