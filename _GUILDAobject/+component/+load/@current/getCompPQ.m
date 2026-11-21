function PQ = getCompPQ(obj,x,V,u,param)
% Return the power that the load injects into the bus.
%
% Used by the continuation power flow (`f_PQ2Bus`). The power is
% `|V|*[Ip; Iq]`; `x` and `param` are not used.
%
% See also fcn_I
    arguments (Input)
        obj
        x     double  % States (unused).
        V     double  % Bus voltage as `[abs; angle]` in [pu] and [rad].
        u     double  % [pu] Input `[Ip; Iq]`.
        param double  % Dynamic parameters (unused).
    end
    arguments (Output)
        PQ  % [pu] Active and reactive power `[P; Q]` injected into the bus.
    end
    PQ = V(1)*u;
end
