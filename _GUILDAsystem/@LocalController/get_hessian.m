function varargout = get_hessian(obj, x, V, I, u)
% Return the second derivatives of fcn_dx and fcn_y at a point.
%
% Second derivatives of the model equations at a point: the optional Hessian analysis
% of a local controller. It is available only for classes that define the static methods
% below (the same pattern as Jacobi_dx / Jacobi_Y); for any other class it stops with
% GUILDA:LocalController:HessianNotSupported, which names the class.
% No symbolic differentiation is used: each class supplies its own Hessian.
%
% Contract for a class that supports it (z = [x; V; I; u], n_z = n_x + 2 + 2 + n_u,
% V = [Vre; Vim] and I = [Ire; Iim] of the parent; the arguments are those of Jacobi_*):
%   H = Hessian_dx(t, x, V, I, u, param, omega0)   % n_x x n_z x n_z  (fcn_dx)
%   H = Hessian_Y( t, x, V, I, u, param, omega0)   % n_y x n_z x n_z  (fcn_y)
% H(k,:,:) is the Hessian of the k-th equation with respect to z (symmetric in its last
% two dimensions). A method may return [] for an all-zero Hessian. Hessian_dx is
% required; Hessian_Y is needed only when its output is requested.
%
% Outputs (`varargout`, in this order):
%
% - `H_dx` — Hessians of fcn_dx: n_x x n_z x n_z.
% - `H_Y` — Hessians of fcn_y: n_y x n_z x n_z.
%
% See also LocalController.get_sys
    arguments
        obj
        x (:,1) double = obj.rv_Xequilibrium   % States (default: the equilibrium).
        V (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]   % [pu] Voltage [Vre; Vim] of the parent.
        I (:,1) double = [real(obj.c_Iequilibrium); imag(obj.c_Iequilibrium)]   % [pu] Current [Ire; Iim] of the parent.
        u (:,1) double = obj.rv_Uequilibrium   % Inputs (default: the equilibrium).
    end
    if isempty(V)
        V = zeros(2,1);
    end
    c_method = {"Hessian_dx", numel(obj.sv_x); "Hessian_Y", numel(obj.sv_y)};
    param    = obj.tab_parameter.dynamics{:,obj.sv_para}.';
    varargout = hessians(obj, "LocalController", c_method(1:max(nargout,1),:), x, V, I, u, param);
end


function c_H = hessians(obj, str_layer, c_method, x, V, I, u, param)
    if isempty(I)
        I = zeros(2,1);
    end
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
