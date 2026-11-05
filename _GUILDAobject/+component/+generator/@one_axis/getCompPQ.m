function PQ = getCompPQ(obj,x,V,u,para)
% Calculate the power that the generator injects into the bus.
%
% Used by the continuation power flow (`f_PQ2Bus`).
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

    V = V(1) * exp(1j*V(2));
    
    Xq = para(4);
    Xdp  = para(5);     

    % State
    delta = x(1);            
    Eq    = x(3);                            

    % dq-trans
    Vdq = exp(1j*delta) * conj(V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);

    % Current    
    Id = Vd/Xq;
    Iq = (Eq - Vq)/Xdp;
    PQ = [Vd*Id + Vq*Iq;
          Vq*Id - Vd*Iq];

end
