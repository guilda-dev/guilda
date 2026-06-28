classdef power < component.load.abstract
    
    properties
        PQ_st
    end

    properties(Constant)
        key      = "load-power";
        str_x    = [];
        str_u    = ["Pload","Qload"];
        str_y    = [];
        str_para = [];
        Prefix = "LP";
    end

    methods(Access={?Bus})
        function obj = power(index, ~, varargin)
            obj@component.load.abstract("PQ"+index, varargin{:})
        end
    end

    methods        
        set_odefcn(obj,omega0)
    end
    
    methods
        [cv_Xequilibrium, cv_Uequilibrium]  = get_equilibrium(obj, c_V, c_I);    
    end

    methods
        dx = fcn_dx(obj, t, x, V, I, u, para);
        I  = fcn_I(obj, t, x, V, I, u, para);
        y  = fcn_Y(obj, t, x, V, I, u, para);
        M  = fcn_Mass(obj, t, x, V, I, u, para);
    end

    methods       
        function PQ = getCompPQ(obj,x,V,u,param) %#ok
            PQ = u;
        end        
    end
end
