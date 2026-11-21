function [x_st,u_st] = get_equilibrium(obj,c_V,c_I,r_P,r_Q) %#ok<INUSL>
% Return the steady power from the bus voltage and current.
%
% `c_V` and `c_I` are the complex bus voltage and current [pu], `r_P` and `r_Q` the
% injected power. The state equilibrium `x_st` is empty and the steady input `u_st` is
% the power `[P; Q]` [pu]. Nothing is stored: get_linear_matrix takes the power from its
% input u.
    arguments (Input)
        obj
        c_V                           % [pu] Complex bus voltage.
        c_I                           % [pu] Complex bus current.
        r_P = real( c_V*conj(c_I) );  % [pu] Active power injected into the bus.
        r_Q = imag( c_V*conj(c_I) );  % [pu] Reactive power injected into the bus.
    end
    arguments (Output)
        x_st  % Equilibrium state (empty).
        u_st  % [pu] Steady input, the power `[P; Q]`.
    end
    x_st = zeros(0, 1);
    u_st = [r_P; r_Q];
end
