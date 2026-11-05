function PQ = getCompPQ(obj,x,V,u,param)
% Calculate the power that the generator injects into the bus.
%
% Used by the continuation power flow (`f_PQ2Bus`).
%
% See also fcn_I
    arguments (Input)
        obj
        x     double  % State vector in the order of `sv_x`.
        V     double  % Bus voltage as `[abs; angle]` in [pu] and [rad].
        u     double  % Input vector in the order of `sv_u`.
        param double  % Dynamic parameters in the order of `sv_para`.
    end
    arguments (Output)
        PQ % [pu] Active and reactive power `[P; Q]` injected into the bus.
    end
    delta = x(1);
    E     = u(2);
    Vabs  = V(1);            

    Xd = param(3);
    Xq = param(4);    

    phi = delta - V(2);

    PQ = [(E * Vabs / Xd) * sin(phi) + 0.5 * Vabs^2 * (1/Xq - 1/Xd) * sin(2*phi);            
          (E * Vabs / Xd) * cos(phi) - Vabs^2 * (cos(phi)^2 / Xd + sin(phi)^2 / Xq)];            
end
