function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Calculate the load impedance from the power flow.
%
% Called by `set_equilibrium` with the power-flow solution. The impedance
% `Z = -c_V/c_I` is the steady input `[R; X]`. The object is not changed.
%
% See also fcn_I
    arguments (Input)
        obj 
        c_V % [pu] Complex bus voltage of the power-flow solution.
        c_I % [pu] Complex current injected into the bus.
        % [pu] Active power injected into the bus.
        r_P = real(c_V*conj(c_I)) %#ok
        % [pu] Reactive power injected into the bus.
        r_Q = imag(c_V*conj(c_I)) %#ok
    end
    arguments (Output)
        rv_Xequilibrium % Equilibrium state in the order of `sv_x`.
        rv_Uequilibrium % Steady input in the order of `sv_u`.
    end
    
    c_Z = -c_V/c_I;
    rv_Xequilibrium = zeros(0,1);
    rv_Uequilibrium = [real(c_Z); imag(c_Z)];
end