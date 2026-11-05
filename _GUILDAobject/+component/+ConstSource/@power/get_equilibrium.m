function [x_st,u_st] = get_equilibrium(obj,Veq,Ieq)
% Calculate the steady power from the bus voltage and current.
%
% `Veq` and `Ieq` are the complex bus voltage and current [pu]. The
% state equilibrium `x_st` is empty and the steady input `u_st` is
% the power `[P; Q]` [pu], also stored in `PQ_st`.
    arguments (Input)
        obj
        Veq  % [pu] Complex bus voltage.
        Ieq  % [pu] Complex bus current.
    end
    arguments (Output)
        x_st  % Equilibrium state (empty).
        u_st  % [pu] Steady input, the power `[P; Q]`.
    end
    PQ = Veq * conj(Ieq);
    obj.PQ_st = [real(PQ); imag(PQ)];
    x_st = zeros(0, 1);
    u_st = obj.PQ_st;
end
