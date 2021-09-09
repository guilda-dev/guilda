classdef component < handle
    
    properties
        get_dx_con_func
    end
    
    properties(Abstract, SetAccess = private)
        x_equilibrium
    end
    
    methods(Abstract)
        set_equilibrium(Veq, Ieq)
        nu = get_nu(varargin)
        [dx, constraint] = get_dx_constraint(t, x, V, I, u);
    end
    
    methods
        function nx = get_nx(obj)
           nx = numel(obj.x_equilibrium); 
        end
    end
end

