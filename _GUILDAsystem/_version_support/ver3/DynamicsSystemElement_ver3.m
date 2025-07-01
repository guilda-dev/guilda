classdef DynamicsSystemElement_ver3
    properties
    end
    methods
        function n = get_nx(obj); n = numel(obj.x_equilibrium); end
        function n = get_nu(obj); n = numel(obj.u_equilibrium); end
        function n = get_ny(obj); n = numel(obj.y_equilibrium); end
        function n = get_nv(obj); n = numel(obj.v_equilibrium); end
        function n = get_nw(obj); n = numel(obj.w_equilibrium); end
    end
end