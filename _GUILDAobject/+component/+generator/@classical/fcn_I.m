function I = fcn_I(obj, t, x, V, I ,u, param, omega0) %#ok
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