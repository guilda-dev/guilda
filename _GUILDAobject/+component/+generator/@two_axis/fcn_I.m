function I = fcn_I(obj,t,x,V,I,u,param,omega0) %#ok
% Calculate the current that the component injects into the bus.
%
% The current follows the convention of `c_Iequilibrium`: positive into the bus.
%
% Inputs:
% - `obj`: the model object.
% - `t` [s]: time.
% - `x`: state vector in the order of `sv_x`.
% - `V` [pu]: bus voltage as `[real; imag]`.
% - `I` [pu]: bus current as `[real; imag]`.
% - `u`: input vector in the order of `sv_u`.
% - `param`: dynamic parameters in the order of `sv_para`.
% - `omega0` [Hz]: network frequency (`r_Hz`).
%
% See also Jacobi_I
    arguments (Output)
        I % [pu] Complex current injected into the bus.
    end

    c_V = [1,1j]*V;
       
    Xdp  = param(4);
    Xqp  = param(6);
   
    delta = x(1);
    Eq    = x(3);
    Ed    = x(4);
    
    Vdq = exp(1j*delta) * conj(c_V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    Id  = 1/Xdp * (Eq-Vq); 
    Iq  = 1/Xqp  *(Vd-Ed);
    Idq = Iq + 1j*Id;

    I = exp(1j*delta) * conj(Idq);
end