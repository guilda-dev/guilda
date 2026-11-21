function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
% Calculate the state derivative and the current constraint (v1 interface).
%
% `V` and `I` are the bus voltage and current as `[real; imag]` [pu]
% and `u` is the power `[P; Q]` [pu]. `dx` is empty; `constraint` is
% the difference between `I` and the current of the power `u`.
    arguments (Input)
        obj
        t  % [s] Time (unused).
        x  % State (empty, unused).
        V  % [pu] Bus voltage `[real; imag]`.
        I  % [pu] Bus current `[real; imag]`.
        u  % [pu] Power `[P; Q]`.
    end
    arguments (Output)
        dx          % State derivative (empty).
        constraint  % [pu] Difference between `I` and the current of the power `u`.
    end
    dx = zeros(0, 1);
    PQ = u(1) + 1j*u(2);
    V = V(1)+1j*V(2);
    I_ = PQ/V;
    constraint = I-[real(I_); -imag(I_)];
end
