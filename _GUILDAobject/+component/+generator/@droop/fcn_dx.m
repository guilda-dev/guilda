function dx = fcn_dx(obj, t, x, V, I, u, param, omega0) %#ok
% Calculate the right side of the state equation.
%
% The state equation is `M*dx/dt = fcn_dx(...)`, with `M` from `fcn_Mass`.
% The class description gives the equations.
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
% See also fcn_Mass, Jacobi_dx
    arguments (Output)
        dx % Right side of the state equation in the order of `sv_x`.
    end
              
    Xd = param(2);
    Xq = param(3);    
        
    delta = x(1);    
    
    Pm    = u(1);
    Vfd   = u(2);

    Vdq = exp(1j*delta) * conj([1,1j]*V);
    Vd  = imag(Vdq);
    Vq  = real(Vdq);

    Id  = (Vfd-Vq)/Xd;
    Iq  = Vd/Xq;
    Pout = Vq*Iq + Vd*Id;
    
    ddelta = - Pout + Pm;
    
    dx  = ddelta;
end