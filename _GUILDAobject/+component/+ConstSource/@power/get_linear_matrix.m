function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x, V)
% Return the matrices of the linearized model (v1 interface).
    arguments (Input)
        obj
        x = []  % State of the operating point (unused).
        V = []  % [pu] Bus voltage `[real; imag]` of the operating point; empty or omitted: `V_st`.
    end
    arguments (Output)
        A   % State matrix (empty).
        B   % Input matrix (0-by-2).
        C   % Output matrix (2-by-0).
        D   % Feedthrough from the power input `[P; Q]` to the current.
        BV  % State matrix for the bus voltage (0-by-2).
        DV  % Feedthrough from the bus voltage to the current.
        BI  % State matrix for the bus current (0-by-2).
        DI  % Feedthrough from the bus current (`-eye(2)`).
        R   % Empty.
        S   % Empty.
    end
    if nargin < 3
        [A, B, C, D, BV, DV, BI, DI, R, S] = obj.get_linear_matrix([], obj.V_st);
    else
        if isempty(V)
            V = obj.V_st;
        end

        den = (V'*V)^2;
        Vr = V(1);
        Vi = V(2);
        P = obj.PQ_st(1);
        Q = obj.PQ_st(2);

        A = [];
        B = zeros(0, 2);
        C = zeros(2, 0);
        D = [P*Vr Q*Vi; P*Vi -Q*Vr]/(V'*V);
        BV = zeros(0, 2);
        DV = [P, Q; -Q, P]*[(Vi^2-Vr^2)/den, -2*Vr*Vi/den; -2*Vr*Vi/den, (Vr^2-Vi^2)/den];
        R = [];%obj.R;
        S = [];%obj.S;
        BI = zeros(0, 2);
        DI = -eye(2);
    end
end
