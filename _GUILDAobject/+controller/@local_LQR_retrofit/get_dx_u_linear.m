function [dx, u] = get_dx_u_linear(obj, t, x, X, Vcell, Icell, U)
% Return the state derivative and the input with the linearized polar transform.
% Same as get_dx_u with `is_linear = true`.
    arguments (Input)
        obj
        t      % [s] Time (unused).
        x      % Controller state.
        X      % Cell array with the generator state.
        Vcell  % [pu] Cell array with the terminal voltage `[real; imag]`.
        Icell  % [pu] Cell array with the terminal current (unused).
        U      % Global input (unused).
    end
    arguments (Output)
        dx  % Controller state derivative.
        u   % Cell array with the input to the generator.
    end
    [dx, u] = get_dx_u(obj, t, x, X, Vcell, Icell, U, true);
end
