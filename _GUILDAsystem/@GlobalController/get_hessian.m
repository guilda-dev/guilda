function varargout = get_hessian(obj, x, V, I, u)
% <@Desc>
% Second derivatives of the model equations at a point: the optional Hessian analysis
% of a global controller. It is available only for classes that define the static
% methods below (the same pattern as Jacobi_dx / Jacobi_Y); for any other class it stops
% with GUILDA:GlobalController:HessianNotSupported, which names the class.
% No symbolic differentiation is used: each class supplies its own Hessian.
%
% Contract for a class that supports it (z = [x; V; I; u], n_z = n_x + 2 + 2 + n_u; a
% global controller has no V and I ports, which are zeros(2,1) as in get_sys; the
% arguments are those of Jacobi_*):
%   H = Hessian_dx(t, x, V, I, u, param, omega0)   % n_x x n_z x n_z  (fcn_dx)
%   H = Hessian_Y( t, x, V, I, u, param, omega0)   % n_y x n_z x n_z  (fcn_y)
% H(k,:,:) is the Hessian of the k-th equation with respect to z (symmetric in its last
% two dimensions). A method may return [] for an all-zero Hessian. Hessian_dx is
% required; Hessian_Y is needed only when its output is requested.
% <@Role> Static Analysis
% <@Summary> Second derivatives of fcn_dx, fcn_y (optional; per class).
% <@Signatures>
% [
%   "H_dx = gcon.get_hessian()",
%   "[H_dx, H_Y] = gcon.get_hessian(x, V, I, u)"
% ]
% <@Parameters>
% [
%   {"Name": "x", "Type": "double column", "Description": "States.", "Required": false, "Default": "gcon.rv_Xequilibrium"},
%   {"Name": "V", "Type": "double column", "Description": "Not a port: zeros(2,1).", "Required": false, "Default": "zeros(2,1)"},
%   {"Name": "I", "Type": "double column", "Description": "Not a port: zeros(2,1).", "Required": false, "Default": "zeros(2,1)"},
%   {"Name": "u", "Type": "double column", "Description": "Inputs (states of the controlled units).", "Required": false, "Default": "gcon.rv_Uequilibrium"}
% ]
% <@Returns>
% [
%   {"Name": "H_dx", "Type": "double", "Description": "Hessians of fcn_dx: n_x x n_z x n_z."},
%   {"Name": "H_Y", "Type": "double", "Description": "Hessians of fcn_y: n_y x n_z x n_z."}
% ]
    arguments
        obj
        x (:,1) double = obj.rv_Xequilibrium
        V (:,1) double = zeros(2,1)
        I (:,1) double = zeros(2,1)
        u (:,1) double = obj.rv_Uequilibrium
    end
    c_method = {"Hessian_dx", numel(obj.sv_x); "Hessian_Y", numel(obj.sv_y)};
    param    = obj.tab_parameter.dynamics{:,obj.sv_para};
    varargout = hessians(obj, "GlobalController", c_method(1:max(nargout,1),:), x, V, I, u, param);
end


function c_H = hessians(obj, str_layer, c_method, x, V, I, u, param)
    n_z = numel(x) + 2 + 2 + numel(u);
    c_H = cell(1, size(c_method,1));
    for k = 1:numel(c_H)
        [str_method, n_f] = c_method{k,:};
        if ~ismethod(obj, str_method)
            error("GUILDA:" + str_layer + ":HessianNotSupported", ...
                  "%s does not support Hessian computation: the class does not define the static method %s " + ...
                  "(see %s.get_hessian for the contract).", class(obj), str_method, str_layer)
        end
        H = obj.(str_method)(0, x, V, I, u, param, obj.r_Hz);
        if isempty(H)
            H = zeros(n_f, n_z, n_z);
        elseif numel(H) ~= n_f*n_z*n_z
            error("GUILDA:" + str_layer + ":HessianSize", ...
                  "%s.%s returned %d values; expected %d x %d x %d (equations x [x; V; I; u] x [x; V; I; u]).", ...
                  class(obj), str_method, numel(H), n_f, n_z, n_z)
        end
        c_H{k} = reshape(full(H), n_f, n_z, n_z);
    end
end
