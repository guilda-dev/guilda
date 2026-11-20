function PQ = getCompPQ(obj,x,V,u,param)
% Return the power that the inverter injects into the bus.
%
% Used by the continuation power flow (`f_PQ2Bus`). The power is
% the input `u = [Pref; Qref]`; `x`, `V` and `param` are not used.
%
% See also fcn_I
    arguments (Input)
        obj
        x     double  % States (unused).
        V     double  % Bus voltage (unused).
        u     double  % [pu] Input `[Pref; Qref]`.
        param double  % Dynamic parameters (unused).
    end
    arguments (Output)
        PQ  % [pu] Active and reactive power `[P; Q]` injected into the bus.
    end
    PQ = u;
end
