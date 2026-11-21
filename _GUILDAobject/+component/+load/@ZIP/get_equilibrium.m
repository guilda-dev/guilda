function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Calculate the steady inputs of the load from the power flow.
%
% Called by `set_equilibrium` with the power-flow solution. The steady input is the power
% at 1 pu that gives `[r_P; r_Q]` at the power-flow voltage: `Pload = r_P/f_P(|c_V|)`,
% `Qload = r_Q/f_Q(|c_V|)`. A zero power (the trip of `simulate` passes 0) gives a zero
% input; a nonzero power with a zero factor (zero voltage, or zero coefficients) stops with
% GUILDA:Component:ZIPNoPower. The object is not changed.
%
% See also fcn_I
    arguments (Input)
        obj
        c_V                           % [pu] Complex bus voltage of the power-flow solution.
        % [pu] Complex current injected into the bus.
        c_I                           %#ok
        r_P = real( c_V*conj(c_I) );  % [pu] Active power injected into the bus.
        r_Q = imag( c_V*conj(c_I) );  % [pu] Reactive power injected into the bus.
    end
    arguments (Output)
        rv_Xequilibrium  % Equilibrium state in the order of `sv_x`.
        rv_Uequilibrium  % Steady input in the order of `sv_u`.
    end
    rr_param = obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)}.tab_parameter{:,obj.sv_para};
    rv_f  = zip_factor(abs(c_V), rr_param);
    rv_PQ = [r_P; r_Q];
    rv_Uequilibrium = zeros(2,1);
    for k = find(rv_PQ ~= 0).'
        if rv_f(k) == 0
            error(msg("GUILDA:Component:ZIPNoPower", char(obj.s_tag), char(obj.sv_u(k)), ...
                      char(string(rv_PQ(k))), char(string(abs(c_V)))))
        end
        rv_Uequilibrium(k) = rv_PQ(k)/rv_f(k);
    end
    rv_Xequilibrium = zeros(0,1);
end
