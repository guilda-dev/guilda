function I = fcn_I(obj, t, x, V, I ,u, param, omega0) %#ok
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
    
    Xd = param(3);
    Xq = param(4);
        
    delta = x(1);
    
    Vfd   = u(2);
    
    Vdq = exp(1j*delta) * conj([1,1j]*V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    Id  = (Vfd-Vq)/Xd;
    Iq  = Vd/Xq;
    Idq = Iq + 1j*Id;

    I   = exp(1j*delta) * conj(Idq);
end