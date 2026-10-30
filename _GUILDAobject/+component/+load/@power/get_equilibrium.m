function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Calculate the steady power of the load from the power flow.
%
% Called by `set_equilibrium` with the power-flow solution. The power `[r_P; r_Q]`
% is stored in `PQ_st` and becomes the steady input `[Pload; Qload]`.
%
% See also fcn_I, PQ_st
    arguments
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
    obj.PQ_st       = [r_P;r_Q];
    rv_Xequilibrium = zeros(0,1);
    rv_Uequilibrium = obj.PQ_st;
end