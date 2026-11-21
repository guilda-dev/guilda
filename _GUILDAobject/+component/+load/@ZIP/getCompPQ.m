function PQ = getCompPQ(obj,x,V,u,param)
% Return the power that the load injects into the bus.
%
% Used by the continuation power flow (`f_PQ2Bus`). The power is
% `[Pload*f_P(|V|); Qload*f_Q(|V|)]` with the voltage factors of the class description.
%
% See also fcn_I
    arguments (Input)
        obj
        x     double  % States (unused).
        V     double  % Bus voltage as `[abs; angle]` in [pu] and [rad] (the angle is unused).
        u     double  % [pu] Input `[Pload; Qload]`.
        param double  % Dynamic parameters in the order of `sv_para`.
    end
    arguments (Output)
        PQ  % [pu] Active and reactive power `[P; Q]` injected into the bus.
    end
    PQ = u(:).*zip_factor(V(1), param);
end
