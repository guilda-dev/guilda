function M = fcn_Mass(obj, t, x, V, I, u, para, omega0) %#ok
% Return the mass matrix of the state equation.
%
% The state equation is `M*dx/dt = fcn_dx(...)`.
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
% See also fcn_dx
    arguments (Output)
        M % Mass matrix of the state equation.
    end
    
    M    = para(1);
    Tdp  = para(9);
    Tdpp = para(10);
    Tqp  = para(11);    
    Tqpp = para(12);

    M = diag( [1,M,Tdp,Tqp,Tqpp,Tdpp] );
end