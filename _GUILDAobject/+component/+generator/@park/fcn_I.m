function I = fcn_I(obj, t, x, V, I, u, para, omega0) %#ok   
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
% - `para`: dynamic parameters in the order of `sv_para`.
% - `omega0` [Hz]: network frequency (`r_Hz`).
%
% See also Jacobi_I
    arguments (Output)
        I % [pu] Complex current injected into the bus.
    end

    V = [1,1j]*V;
    
    Xdp  = para(4);
    Xdpp = para(5);
    Xqp  = para(7);    
    Xqpp = para(8);
    Xls  = para(13);
    
    delta = x(1);
    Eq    = x(3);
    Ed    = x(4);
    psiq  = x(5);
    psid  = x(6);
    
    Vdq = exp(1j*delta) * conj(V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);
    
    % terminal_q = ( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls);
    % terminal_d = ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls);
    Id  = 1/Xdpp * (( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls) - Vq); 
    Iq  = 1/Xqpp * (Vd - ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls));
    Idq = Iq + 1j*Id;
    I   = exp(1j*delta) * conj(Idq);

end