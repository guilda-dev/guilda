function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Calculate the steady power of the load from the power flow.
%
% Called by `set_equilibrium` with the power-flow solution. The power `[r_P; r_Q]`
% is the steady input `[Pload; Qload]`. The object is not changed.
%
% See also fcn_I
    arguments (Input)
        obj 
        % [pu] Complex bus voltage of the power-flow solution.
        c_V %#ok
        % [pu] Complex current injected into the bus.
        c_I %#ok
        r_P = real( c_V*conj(c_I) ); % [pu] Active power injected into the bus.
        r_Q = imag( c_V*conj(c_I) ); % [pu] Reactive power injected into the bus.
    end
    arguments (Output)
        rv_Xequilibrium % Equilibrium state in the order of `sv_x`.
        rv_Uequilibrium % Steady input in the order of `sv_u`.
    end
    rv_Xequilibrium = zeros(0,1);
    rv_Uequilibrium = [r_P; r_Q];
end