function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Calculate the load current from the power flow.
%
% Called by `set_equilibrium` with the power-flow solution. The current
% `[r_P; r_Q]/|c_V|` is the steady input `[Ip; Iq]`, so the load injects the
% power-flow power at the power-flow voltage. A zero power (a tripped load) gives
% a zero current. The object is not changed.
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
    rv_Xequilibrium = zeros(0,1);
    if r_P == 0 && r_Q == 0
        rv_Uequilibrium = zeros(2,1);
    else
        rv_Uequilibrium = [r_P; r_Q]/abs(c_V);
    end
end
