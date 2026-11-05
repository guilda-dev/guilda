function PQ = getCompPQ(obj,x,V,u,para)
% Calculate the power that the generator injects into the bus.
%
% Used by the continuation power flow (`f_PQ2Bus`).
%
% This implementation reads `V` as `[real; imag]`, unlike the other generator models.
%
% See also fcn_I
    arguments (Input)
        obj
        x    double  % State vector in the order of `sv_x`.
        V    double  % Bus voltage as `[abs; angle]` in [pu] and [rad].
        u    double  % Input vector in the order of `sv_u`.
        para double  % Dynamic parameters in the order of `sv_para`.
    end
    arguments (Output)
        PQ % [pu] Active and reactive power `[P; Q]` injected into the bus.
    end

    c_V = [1,1j]*V;

    Xdp  = para(4);
    Xqp  = para(6);
   
    delta = x(1);
    Eq    = x(3);
    Ed    = x(4);
    
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    Id  = 1/Xdp * (Eq-Vq); 
    Iq  = 1/Xqp  *(Vd-Ed);          
            
    PQ = [Vd*Id + Vq*Iq;
          Vq*Id - Vd*Iq];
               
end
