function I = fcn_I(obj,t,x,V,I,u,param,omega0) %#ok
% Calculate the current that the component injects into the bus.
%
% The current follows the convention of `c_Iequilibrium`: positive into the bus.
%
% See also Jacobi_I
    arguments (Input)
        obj
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        I      double        % [pu] Bus current as `[real; imag]`.
        u      double        % Input vector in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
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