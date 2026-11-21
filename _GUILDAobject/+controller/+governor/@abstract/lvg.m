function [r_gate, l_ref] = lvg(r_e, r_Plimit)
% Low value gate: the smaller of the load setting signal r_e and the limiter.
% l_ref is true when r_e passes (also when they are equal).
    arguments (Input)
        r_e       (1,1) double  % Load setting signal.
        r_Plimit  (1,1) double  % Load limiter.
    end
    arguments (Output)
        r_gate  % Output of the gate: the smaller of r_e and r_Plimit.
        l_ref   % True when r_e passes.
    end
    l_ref = r_e <= r_Plimit;
    if l_ref
        r_gate = r_e;
    else
        r_gate = r_Plimit;
    end
end
