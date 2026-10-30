function y = fcn_Y(obj, t, x, V, I, u, param, omega0) %#ok
% Calculate the output passed to local controllers.
%
% Local controllers read the output by the names in `sv_y`.
% This model has no output: `y` is empty.
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
% See also Jacobi_Y
    arguments (Output)
        y % Output vector in the order of `sv_y`.
    end
    y = [];
end