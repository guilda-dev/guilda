function  I = fcn_I(obj,t,x,V,I,u,param,omega0) %#ok
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
    V = [1,1j]*V;
    Z = [1,1j]*u;
    I = -V/Z;
end